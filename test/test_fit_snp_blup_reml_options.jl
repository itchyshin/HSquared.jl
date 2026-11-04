using Test
using Random
using LinearAlgebra
using HSquared

# Test-only coverage for the keywords of `fit_snp_blup_reml`:
# `allele_frequencies`, `ids`, and `target`.
@testset "fit_snp_blup_reml options" begin
    rng = MersenneTwister(20261020)
    n, m = 20, 6
    M = Float64.(rand(rng, 0:2, n, m))
    # keep every marker polymorphic so the default frequencies are usable
    M[1, :] .= 0.0
    M[2, :] .= 2.0
    X = ones(n, 1)
    y = M * randn(rng, m) .* 0.5 .+ randn(rng, n) .+ 3.0
    init = (sigma_a2 = 1.0, sigma_e2 = 1.0)

    s = fit_snp_blup_reml(y, X, M; initial = init)
    @test s.converged

    @testset "allele_frequencies" begin
        p_emp = vec(sum(M, dims = 1)) ./ (2n)
        s_same = fit_snp_blup_reml(y, X, M; initial = init, allele_frequencies = p_emp)
        @test s_same.k ≈ s.k
        @test s_same.gebv ≈ s.gebv atol = 1e-8
        @test s_same.sigma_g2 ≈ s.sigma_g2 rtol = 1e-8

        p_alt = fill(0.4, m)
        s_alt = fit_snp_blup_reml(y, X, M; initial = init, allele_frequencies = p_alt)
        @test s_alt.p == p_alt
        @test s_alt.k ≈ 2 * sum(p_alt .* (1 .- p_alt))
        @test !isapprox(s_alt.k, s.k; rtol = 1e-6)
        @test !isapprox(s_alt.gebv, s.gebv; atol = 1e-6)

        # matches the supplied-variance twin at the estimated variances
        sup = fit_snp_blup(y, X, M, s_alt.sigma_g2, s_alt.sigma_e2; allele_frequencies = p_alt)
        @test sup.gebv ≈ s_alt.gebv atol = 1e-8
        @test sup.marker_effects ≈ s_alt.marker_effects atol = 1e-8
        @test sup.k ≈ s_alt.k

        @test_throws ArgumentError fit_snp_blup_reml(y, X, M; allele_frequencies = fill(0.4, m - 1))
        @test_throws ArgumentError fit_snp_blup_reml(y, X, M; allele_frequencies = fill(1.5, m))
        @test_throws ArgumentError fit_snp_blup_reml(y, X, M; allele_frequencies = zeros(m))
    end

    @testset "k and per-marker variance" begin
        @test s.k ≈ 2 * sum(s.p .* (1 .- s.p))
        fit = fit_animal_model(
            animal_model_spec(y, X, centered_markers(M).W, Matrix{Float64}(I, m, m); method = :REML);
            target = :ai_reml, initial = init,
        )
        @test s.sigma_g2 / s.k ≈ fit.variance_components.sigma_a2 rtol = 1e-8
    end

    @testset "target" begin
        s_ai = fit_snp_blup_reml(y, X, M; initial = init, target = :ai_reml)
        s_sp = fit_snp_blup_reml(y, X, M; initial = init, target = :sparse_reml)
        @test s_ai.sigma_g2 ≈ s.sigma_g2 rtol = 1e-8
        # sparse_reml uses a different optimizer; the two agree only to optimizer tolerance
        # (observed gap ~1.6e-5 on sigma_g2), so use a relative 1e-3 rather than 1e-5.
        @test isapprox(s_sp.sigma_g2, s_ai.sigma_g2; rtol = 1e-3)
        @test isapprox(s_sp.sigma_e2, s_ai.sigma_e2; rtol = 1e-3)
        @test_throws ArgumentError fit_snp_blup_reml(y, X, M; target = :not_a_target)
    end

    @testset "ids" begin
        # ids index the random (marker) effects, so the length must equal the marker count
        s_ids = fit_snp_blup_reml(y, X, M; initial = init, ids = ["m$j" for j in 1:m])
        @test s_ids.gebv ≈ s.gebv atol = 1e-10
        @test_throws ArgumentError fit_snp_blup_reml(y, X, M; ids = 1:(m + 1))
        @test_throws ArgumentError fit_snp_blup_reml(y, X, M; ids = 1:(m - 1))
        @test_throws ArgumentError fit_snp_blup_reml(y, X, M; ids = 1:n)
    end

    @testset "centered_markers guards" begin
        Mmono = copy(M)
        Mmono[:, 3] .= 1.0  # monomorphic column with p = 0.5 is not rejected: only k == 0 is
        @test fit_snp_blup_reml(y, X, Mmono; initial = init) isa NamedTuple

        Mall = fill(2.0, n, m)  # every marker monomorphic -> k == 0
        @test_throws ArgumentError fit_snp_blup_reml(y, X, Mall)

        for bad in (NaN, Inf, -Inf, 2.5, -0.5)
            Mb = copy(M)
            Mb[4, 2] = bad
            @test_throws ArgumentError fit_snp_blup_reml(y, X, Mb)
        end
        @test_throws ArgumentError fit_snp_blup_reml(y, X, zeros(n, 0))
    end
end

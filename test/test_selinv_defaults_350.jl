# test_selinv_defaults_350.jl -- #350: sparse defaults for the post-fit summaries
#
# Finding (Szymon Drobniak, measured at q = 5,000 animals, one BLAS thread): the
# AI-REML fit takes 0.03 s, but the summaries the R bridge calls on every fit
# did not scale:
#   (a) `reliability` formed the dense `A = inv(Ainv)` only to read `diag(A)`
#       (5.8 s, 0.8 GB inside `result_payload`);
#   (b) `breeding_values_plot_data` went through `prediction_error_variance`
#       whose default was `method = :dense`, a dense (p+q)x(p+q) MME inverse
#       (11.4 s, 1.8 GB), although the `:selinv` Takahashi path already gave
#       the same PEV in 0.002 s / 10 MB.
#
# Pinned here: (i) parity -- at q = 1,000 the `:selinv` and `:dense` PEV agree
# on every diagonal entry to 1e-10, the sparse selected-inverse `diag(inv(Ainv))`
# used by `reliability` equals the old dense `diag(inv(Ainv))` AND `1 + F_i`
# (inbreeding) to 1e-10, and the new `reliability` equals the old dense formula
# to 1e-10; (ii) budget -- at q = 3,000, `result_payload` + `breeding_values_plot_data`
# together allocate under 100 MB and take under 1 s (warm).
#
# Fixture: half-sib pedigree (sires 5 %, dams 10 %, offspring 85 %), two records
# per animal, simulated WITH additive signal (founders a ~ N(0, sa2), offspring
# a = 0.5 (a_s + a_d) + N(0, 0.5 sa2), y = Z a + N(0, se2); sa2 = 0.04, se2 = 0.06)
# so AI-REML converges to an interior optimum on every Julia RNG stream. A pure-
# noise fixture (true sa2 = 0) sat on the boundary and failed `converged` on
# Julia >= 1.12, where `MersenneTwister` draws differ from 1.10. Fitted by
# `fit_ai_reml`, the bridge's fitter.

using HSquared
using LinearAlgebra
using SparseArrays
using Random
using Test

function _halfsib_pedigree_350(q::Int)
    nsire = round(Int, 0.05q)
    ndam = round(Int, 0.10q)
    noff = q - nsire - ndam
    ids = collect(1:q)
    sire = zeros(Int, q)
    dam = zeros(Int, q)
    for k in 1:noff
        i = nsire + ndam + k
        sire[i] = 1 + (k - 1) % nsire
        dam[i] = nsire + 1 + (k - 1) % ndam
    end
    return HSquared.normalize_pedigree(ids, sire, dam)
end

function _halfsib_fit_350(q::Int; seed::Integer = 350, sa2 = 0.04, se2 = 0.06)
    ped = _halfsib_pedigree_350(q)
    Ainv = HSquared.pedigree_inverse(ped)
    n = 2q
    rng = MersenneTwister(seed)
    a = zeros(q)
    for i in 1:q                                  # topological order: parents first
        s_i, d_i = ped.sire[i], ped.dam[i]
        if s_i == 0 && d_i == 0
            a[i] = sqrt(sa2) * randn(rng)
        else
            a[i] = 0.5 * (a[s_i] + a[d_i]) + sqrt(0.5 * sa2) * randn(rng)
        end
    end
    y = repeat(a, inner = 2) .+ sqrt(se2) .* randn(rng, n)
    X = ones(n, 1)
    Z = sparse(1:n, repeat(1:q, inner = 2), 1.0, n, q)
    spec = HSquared.animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    return ped, HSquared.fit_ai_reml(spec)
end

@testset "350 (i): selinv PEV/reliability parity with the dense oracle, q = 1,000" begin
    ped, fit = _halfsib_fit_350(1_000)
    @test fit.converged
    vc = fit.variance_components
    @test vc.sigma_a2 > 0 && vc.sigma_e2 > 0

    pev_dense = HSquared.prediction_error_variance(fit; method = :dense)
    pev_selinv = HSquared.prediction_error_variance(fit; method = :selinv)
    @test pev_selinv.ids == pev_dense.ids
    @test length(pev_selinv.values) == 1_000
    @test maximum(abs.(pev_selinv.values .- pev_dense.values)) <= 1e-10

    # The default is now the sparse path (was :dense).
    @test HSquared.prediction_error_variance(fit).values == pev_selinv.values

    # Animal self-relationship: old dense diag(inv(Ainv)) == 1 + F_i (pedigree
    # identity) == the sparse selected-inverse diagonal that reliability now uses.
    Ainv = fit.spec.Ainv
    diag_dense = diag(inv(Symmetric(Matrix{Float64}(Ainv))))
    @test maximum(abs.(diag_dense .- (1 .+ HSquared.inbreeding_coefficients(ped)))) <= 1e-10
    @test maximum(abs.(HSquared._relationship_diag(Ainv) .- diag_dense)) <= 1e-10

    # New reliability == the old implementation (dense inv(Ainv) denominator).
    rel_old = 1 .- pev_dense.values ./ (vc.sigma_a2 .* diag_dense)
    rel_new = HSquared.reliability(fit)
    @test rel_new.ids == pev_dense.ids
    @test maximum(abs.(rel_new.values .- rel_old)) <= 1e-10
    @test maximum(abs.(HSquared.reliability(fit; method = :dense).values .- rel_old)) <= 1e-10
    @test maximum(abs.(HSquared.reliability(fit; method = :selinv).values .- rel_old)) <= 1e-10

    # Inbred pedigree (full-sib and half-sib matings, F_i > 0): the 1 + F_i
    # identity and the sparse diagonal hold off the F = 0 special case too.
    ped8 = HSquared.normalize_pedigree(
        ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
    )
    Ainv8 = HSquared.pedigree_inverse(ped8)
    F8 = HSquared.inbreeding_coefficients(ped8)
    @test any(F8 .> 0)
    diag8_dense = diag(inv(Symmetric(Matrix{Float64}(Ainv8))))
    @test maximum(abs.(diag8_dense .- (1 .+ F8))) <= 1e-10
    @test maximum(abs.(HSquared._relationship_diag(Ainv8) .- diag8_dense)) <= 1e-10
end

@testset "350 (ii): result_payload + breeding_values_plot_data budget, q = 3,000" begin
    _, fit = _halfsib_fit_350(3_000)
    @test fit.converged

    both(f) = (HSquared.result_payload(f), HSquared.breeding_values_plot_data(f))
    both(fit)                                   # warm-up (JIT)
    GC.gc()
    bytes = @allocated both(fit)
    secs = @elapsed both(fit)
    @info "350 budget at q = 3,000" bytes_MB = bytes / 1e6 seconds = secs
    @test bytes < 100_000_000
    @test secs < 1.0

    payload, plot_data = both(fit)
    @test payload.prediction_error_variance.values ==
          HSquared.prediction_error_variance(fit; method = :selinv).values
    @test plot_data.pev == HSquared.prediction_error_variance(fit; method = :selinv).values
    @test payload.reliability.values == HSquared.reliability(fit; method = :selinv).values
end

@testset "350 (iii): :auto keeps the dense path for a dense genomic Ginv" begin
    # A dense `Ginv` in the `Ainv` slot must NOT be routed through the Takahashi
    # recursion (scalar Julia over a fully dense factor: measured 67x slower than
    # `inv` at q = 1,000). `:auto` resolves by storage; results agree either way.
    q = 300
    rng = MersenneTwister(3500)
    M = randn(rng, q, 2q)
    G = Symmetric(M * M' ./ (2q) + 0.05 * I(q))
    Ginv = Symmetric(Matrix(inv(G)))
    @test HSquared._resolve_pev_method(Ginv, :auto) === :dense
    @test HSquared._resolve_pev_method(sparse(Ginv), :auto) === :selinv
    @test HSquared._resolve_pev_method(Ginv, :selinv) === :selinv
    d_auto = HSquared._relationship_diag(Ginv)
    d_dense = HSquared._relationship_diag(Ginv, :dense)
    d_sel = HSquared._relationship_diag(sparse(Matrix(Ginv)), :selinv)
    @test d_auto == d_dense
    @test maximum(abs.(d_sel .- d_dense)) <= 1e-10 * maximum(abs.(d_dense))
    @test maximum(abs.(d_dense .- diag(G))) <= 1e-8 * maximum(abs.(diag(G)))
end

@testset "350 (iv): a numerically singular MME fails loudly, never quietly wrong" begin
    # Verifier finding on the first cut: with a rank-deficient X (duplicate column)
    # the dense oracle threw SingularException, while the sparse Cholesky accepted a
    # 4e-8 pivot and the Takahashi recursion returned PEV 0.08 where the truth is
    # 0.25. The selected-inverse path must refuse such a factor.
    ped = _halfsib_pedigree_350(100)
    Ainv = HSquared.pedigree_inverse(ped)
    q = size(Ainv, 1); n = 2q
    rng = MersenneTwister(3501)
    y = randn(rng, n)
    Xdup = hcat(ones(n), ones(n))                 # rank-deficient fixed effects
    Z = sparse(1:n, repeat(1:q, inner = 2), 1.0, n, q)
    spec = HSquared.animal_model_spec(y, Xdup, Z, Ainv; ids = ped.ids, method = :REML)
    @test_throws ArgumentError HSquared._selinv_mme_random_pev(spec, 1.2, 0.8)
    # and the same call on the full-rank design is fine
    spec_ok = HSquared.animal_model_spec(y, ones(n, 1), Z, Ainv; ids = ped.ids, method = :REML)
    pev_ok = HSquared._selinv_mme_random_pev(spec_ok, 1.2, 0.8)
    @test all(isfinite, pev_ok) && all(>(0), pev_ok)
end

@testset "350 (v): Int32-indexed sparse Ainv takes the selinv path" begin
    ped = _halfsib_pedigree_350(200)
    Ainv = HSquared.pedigree_inverse(ped)
    Ainv32 = SparseMatrixCSC{Float64, Int32}(Ainv)
    d64 = HSquared._relationship_diag(Ainv)
    d32 = HSquared._relationship_diag(Ainv32)
    @test d32 == d64
    @test HSquared._resolve_pev_method(Ainv32, :auto) === :selinv
end

@testset "350 (vi): the singularity guard is invariant to rescaling a column of X" begin
    # Review finding on #355: the first guard compared the smallest and largest
    # pivots of L, so a well-posed fit with one covariate stored at magnitude ~1e7
    # (a date coded as YYYYMMDD) was refused -- `result_payload` threw although the
    # dense PEV was unchanged to 10 significant figures. The relative-pivot test
    # (L_ii^2 / C_ii, i.e. 1 - R^2 of each equation on those eliminated before it)
    # must accept every rescaling of a full-rank design and refuse a duplicated
    # column at every scale.
    ped = _halfsib_pedigree_350(300)
    Ainv = HSquared.pedigree_inverse(ped)
    q = size(Ainv, 1); n = 2q
    rng = MersenneTwister(3506)
    y = randn(rng, n)
    w = 3.0 .+ 0.5 .* randn(rng, n)
    Z = sparse(1:n, repeat(1:q, inner = 2), 1.0, n, q)
    spec(X) = HSquared.animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
    pev_ref = HSquared._pev_values(spec(hcat(ones(n), w)), 1.2, 0.8, :dense)
    for scale in (1.0, 1e4, 1e7, 1e9)
        pev = HSquared._selinv_mme_random_pev(spec(hcat(ones(n), scale .* w)), 1.2, 0.8)
        @test maximum(abs.(pev .- pev_ref)) <= 1e-10
        @test_throws ArgumentError HSquared._selinv_mme_random_pev(
            spec(hcat(ones(n), scale .* w, scale .* w)), 1.2, 0.8)
    end
end

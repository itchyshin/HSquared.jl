# test_issue_420_spectral_greml.jl -- spectral REML for the single-genomic-effect model.
#
# y = Xb + g + e, g ~ N(0, Vg K): one eigen-decomposition makes every REML
# evaluation O(n p^2). The dense AI-REML route stays reachable with
# `solver = :dense_ai_reml` as the validation cross-check.

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

function _issue420_panel(n, m, seed; vg = 0.6, ve = 0.4)
    rng = MersenneTwister(seed)
    markers = Float64.(rand(rng, 0:2, n, m))
    G = genomic_relationship_matrix(markers)
    Q = genomic_relationship_inverse(G; ridge = 0.01)
    K = Matrix(G) + 0.01 * I
    X = hcat(ones(n), Float64.(rand(rng, Bool, n)))
    L = cholesky(Symmetric(K)).L
    y = X * [1.0, 0.5] .+ sqrt(vg) .* (L * randn(rng, n)) .+ sqrt(ve) .* randn(rng, n)
    return (y = y, X = X, Z = sparse(1.0I, n, n), Q = Q, ids = ["g$i" for i in 1:n])
end

@testset "issue 420: spectral genomic REML" begin
    d = _issue420_panel(500, 2000, 420)

    @testset "spectral equals dense AI-REML" begin
        dense = fit_gblup_reml(d.y, d.X, d.Z, d.Q; ids = d.ids, solver = :dense_ai_reml)
        HSquared._GENOMIC_EIGEN_CALLS[] = 0
        spectral = fit_gblup_reml(d.y, d.X, d.Z, d.Q; ids = d.ids)
        @test spectral isa HSquared.AnimalModelFit
        @test dense.optimizer_status != "boundary_lower"
        @test abs(spectral.likelihood.loglik - dense.likelihood.loglik) <= 1e-8
        @test isapprox(spectral.variance_components.sigma_a2,
                       dense.variance_components.sigma_a2; rtol = 1e-5)
        @test isapprox(spectral.variance_components.sigma_e2,
                       dense.variance_components.sigma_e2; rtol = 1e-5)
        @test spectral.converged
        @test spectral.optimizer_status == "spectral_converged"
        @test spectral.iterations >= 1
        @test spectral.likelihood.beta ≈ dense.likelihood.beta rtol = 1e-5
        # Runtime guard: at most three O(n^3) factorisations (we use one).
        @test 1 <= HSquared._GENOMIC_EIGEN_CALLS[] <= 3
    end

    @testset "dense route never calls the eigen helper" begin
        HSquared._GENOMIC_EIGEN_CALLS[] = 0
        fit_gblup_reml(d.y, d.X, d.Z, d.Q; ids = d.ids, solver = :dense_ai_reml)
        @test HSquared._GENOMIC_EIGEN_CALLS[] == 0
    end

    @testset "ineligible models fall back to dense AI-REML" begin
        small = _issue420_panel(40, 200, 7)
        # Non-identity Z (two records per animal on 20 animals): not a single-kernel marginal form.
        Z2 = sparse(vcat(1.0I(20), 1.0I(20)))
        Q20 = genomic_relationship_inverse(genomic_relationship_matrix(Float64.(rand(MersenneTwister(1), 0:2, 20, 100))); ridge = 0.01)
        HSquared._GENOMIC_EIGEN_CALLS[] = 0
        fit = fit_gblup_reml(small.y, small.X, Z2, Q20; ids = ["g$i" for i in 1:20])
        @test HSquared._GENOMIC_EIGEN_CALLS[] == 0
        @test fit isa HSquared.AnimalModelFit
        @test_throws ArgumentError fit_gblup_reml(d.y, d.X, d.Z, d.Q; solver = :nope)
        # Non-positive eigenvalue of the precision (indefinite): helper reports failure.
        @test HSquared._genomic_eigen(Matrix(Diagonal([1.0, -1.0, 2.0]))) === nothing
        @test HSquared._genomic_eigen(Matrix(Diagonal([1.0, NaN, 2.0]))) === nothing
    end

    @testset "boundary behaviour unchanged (Vg at 0 routes to dense)" begin
        small = _issue420_panel(60, 300, 11; vg = 1e-12, ve = 1.0)
        dense = fit_gblup_reml(small.y, small.X, small.Z, small.Q; ids = small.ids,
                               solver = :dense_ai_reml)
        auto = fit_gblup_reml(small.y, small.X, small.Z, small.Q; ids = small.ids)
        @test auto.optimizer_status != "spectral_converged"
        @test auto.variance_components == dense.variance_components
        @test auto.likelihood.loglik == dense.likelihood.loglik
        @test auto.optimizer_status == dense.optimizer_status
    end
end

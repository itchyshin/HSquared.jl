using Test
using LinearAlgebra
using SparseArrays
using HSquared

@testset "direct sparse REML validates relationship precision" begin
    n = 6
    y = [1.0, 2.2, 0.7, 3.1, 1.4, 2.6]
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    valid = sparse(1.0I, n, n)
    spec_for(Q) = animal_model_spec(y, X, Z, Q)

    asymmetric_dense = Matrix{Float64}(I, n, n)
    asymmetric_dense[1, 2] = 0.25
    asymmetric = sparse(asymmetric_dense)
    indefinite_dense = Matrix{Float64}(I, n, n)
    indefinite_dense[1, 1] = 1.0
    indefinite_dense[2, 2] = 1.0
    indefinite_dense[1, 2] = 2.0
    indefinite_dense[2, 1] = 2.0
    indefinite = sparse(indefinite_dense)
    singular = spdiagm(0 => [1.0, 1.0, 1.0, 1.0, 1.0, 0.0])
    nonfinite_dense = Matrix{Float64}(I, n, n)
    nonfinite_dense[1, 2] = Inf
    nonfinite_dense[2, 1] = Inf
    nonfinite = sparse(nonfinite_dense)

    @test size(spec_for(valid).Ainv) == (n, n)
    for Q in (asymmetric, indefinite, singular, nonfinite)
        spec = spec_for(Q)
        @test_throws ArgumentError sparse_reml_loglik(spec, 1.0, 1.0)
        @test_throws ArgumentError fit_ai_reml(spec; iterations = 1)
    end
end

@testset "direct sparse REML uses one canonical relationship precision" begin
    n = 6
    y = [1.0, 2.2, 0.7, 3.1, 1.4, 2.6]
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    exact = sparse(1.0I, n, n)
    roundoff_dense = Matrix{Float64}(I, n, n)
    roundoff_dense[1, 2] = eps(Float64)
    roundoff = sparse(roundoff_dense)
    averaged, _ = HSquared._validate_matrix_free_precision(roundoff, 1)

    stale_diag_spec = animal_model_spec(y, X, Z, roundoff;
        relationship_diag = fill(1.5, n))
    canonical_spec = animal_model_spec(y, X, Z, averaged)
    exact_spec = animal_model_spec(y, X, Z, exact)
    canonicalized, _ = HSquared._validated_sparse_relationship_spec(stale_diag_spec)

    likelihood_roundoff = sparse_reml_loglik(stale_diag_spec, 0.7, 0.6)
    likelihood_averaged = sparse_reml_loglik(canonical_spec, 0.7, 0.6)
    @test likelihood_roundoff.loglik ≈ likelihood_averaged.loglik rtol = 1e-12 atol = 1e-12
    @test likelihood_roundoff.beta ≈ likelihood_averaged.beta rtol = 1e-12 atol = 1e-12
    @test canonicalized.relationship_diag === nothing
    @test first(HSquared._validated_sparse_relationship_spec(exact_spec)) === exact_spec
end

@testset "sparse REML optimizers reject unusable iteration controls" begin
    n = 6
    y = [1.0, 2.2, 0.7, 3.1, 1.4, 2.6]
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    Ainv = sparse(1.0I, n, n)
    spec = animal_model_spec(y, X, Z, Ainv)

    for iterations in (0, -1)
        @test_throws ArgumentError fit_ai_reml(spec; iterations)
        @test_throws ArgumentError fit_sparse_reml(spec; iterations)
        @test_throws ArgumentError fit_multi_effect_mc_reml(y, X, [(Z, Ainv)];
            iterations, nprobe = 2)
        @test_throws ArgumentError fit_matrix_free_reml(spec; iterations, nprobe = 2)
    end
end

@testset "AI-REML rejects invalid numeric controls before fitting" begin
    n = 6
    y = [1.0, 2.2, 0.7, 3.1, 1.4, 2.6]
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    Ainv = sparse(1.0I, n, n)
    spec = animal_model_spec(y, X, Z, Ainv)

    @test_throws ArgumentError fit_ai_reml(spec; initial = (sigma_a2 = Inf, sigma_e2 = 1.0))
    @test_throws ArgumentError fit_ai_reml(spec; initial = (sigma_a2 = BigFloat("1e10000"), sigma_e2 = 1.0))
    @test_throws ArgumentError fit_ai_reml(spec; tol = Inf)
    @test_throws ArgumentError fit_ai_reml(spec; tol = 0.0)
    @test_throws ArgumentError fit_sparse_reml(spec; initial = (sigma_a2 = 1e-320, sigma_e2 = 1.0))
end

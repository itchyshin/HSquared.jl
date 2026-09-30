using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "Sparse REML rejects nonfinite variance inputs" begin
    n = 3
    spec = animal_model_spec(
        [0.5, -1.0, 2.0],
        zeros(n, 0),
        sparse(1.0I, n, n),
        sparse(1.0I, n, n);
        method = :REML,
    )

    @test isfinite(sparse_reml_loglik(spec, 1.0, 1.0).loglik)
    @test_throws ArgumentError sparse_reml_loglik(spec, Inf, 1.0)
    @test_throws ArgumentError sparse_reml_loglik(spec, 1.0, Inf)
    @test_throws ArgumentError sparse_reml_loglik(spec, NaN, 1.0)
    @test_throws ArgumentError sparse_reml_loglik(spec, 1.0, NaN)
    @test_throws ArgumentError fit_sparse_reml(
        spec;
        initial = (sigma_a2 = Inf, sigma_e2 = 1.0),
        iterations = 2,
    )
    @test_throws ArgumentError fit_sparse_reml(
        spec;
        initial = (sigma_a2 = 1.0, sigma_e2 = NaN),
        iterations = 2,
    )
end

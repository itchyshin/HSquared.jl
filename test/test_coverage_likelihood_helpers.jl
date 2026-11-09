# HJ1 — likelihood.jl ingress helpers and dense covariance bridge.

using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "likelihood helper contracts (HJ1)" begin
    y = [1.0, 2.0, 3.0]
    X = ones(3, 1)
    Z = sparse(1.0I, 3, 3)
    Q = spdiagm(0 => [1.0, 2.0, 4.0])
    spec = animal_model_spec(y, X, Z, Q; ids = ["a", "b", "c"])

    @testset "_likelihood_block_ids and effect IDs" begin
        @test HSquared._likelihood_effect_ids(["a", "b", "c"], 3, "ids") == ["a", "b", "c"]
        @test HSquared._likelihood_effect_ids(nothing, 3, "ids") == [1, 2, 3]
        @test_throws ArgumentError HSquared._likelihood_effect_ids(["a", "a", "c"], 3, "ids")
        @test_throws ArgumentError HSquared._likelihood_effect_ids(["a", "b"], 3, "ids")
        qs = [3, 2]
        @test length(HSquared._likelihood_block_ids([["a", "b", "c"], ["x", "y"]], qs)) == 2
        @test_throws ArgumentError HSquared._likelihood_block_ids([["a", "b", "c"]], qs)
    end

    @testset "_likelihood_design saturated REML guard" begin
        Xsat = ones(3, 3)
        @test_throws ArgumentError HSquared._likelihood_design(y, Xsat; method = :REML)
        yv, Xs = HSquared._likelihood_design(y, X; method = :ML)
        @test yv == Float64.(y)
        @test issparse(Xs)
    end

    @testset "_dense_relationship_covariance matches inv(Ainv)" begin
        Ainv = Matrix(Q)
        A = HSquared._dense_relationship_covariance(Ainv)
        @test A ≈ inv(Symmetric(Ainv))
        sparse_ll = gaussian_loglik(spec, 1.2, 0.8).loglik
        dense_spec, _ = HSquared._likelihood_validated_spec(spec)
        A2 = HSquared._dense_relationship_covariance(dense_spec.Ainv)
        direct = HSquared._gaussian_loglik_with_covariance(dense_spec, 1.2, 0.8, A2, :REML).loglik
        @test direct ≈ sparse_ll rtol = 1e-10
    end

    @testset "_likelihood_result_spec identity" begin
        validated, _ = HSquared._likelihood_validated_spec(spec)
        @test HSquared._likelihood_result_spec(spec, validated) === spec
        altered = animal_model_spec(validated.y, validated.X, validated.Z, validated.Ainv;
                                    method = :ML)
        @test HSquared._likelihood_result_spec(spec, altered) == altered
    end
end

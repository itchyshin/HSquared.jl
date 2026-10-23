using Test, LinearAlgebra, HSquared
const H = HSquared
@testset "non-Gaussian finite ingress" begin
    @testset "strict positive family fields before and after conversion" begin
        for constructor in (H.GaussianResponse, H.NegativeBinomialResponse, H.GammaResponse)
            for bad in (Inf, -Inf, NaN, 0.0, -1.0, BigFloat("1e400"), BigFloat("1e-400"))
                @test_throws ArgumentError constructor(bad)
            end
            for good in (1.0, 3, big"0.5", floatmin(Float64), nextfloat(0.0))
                f = constructor(good)
                @test isfinite(getfield(f, 1)) && getfield(f, 1) > 0
                @test getfield(f, 1) == Float64(good)
            end
        end
    end
    @testset "ordered thresholds retain ordering and finite conversion" begin
        for bad in ([NaN], [Inf], [-Inf], [0.0, Inf], [-Inf, 0.0],
                    [NaN, 0.0], Float64[], [1.0, 0.0], [0.0, 0.0],
                    [BigFloat("1e400")], [big"1.0", big"1.0" + big(2.0)^(-200)])
            @test_throws ArgumentError H.OrderedProbitResponse(bad)
        end
        for good in ([0.0], [-1.0, 0.0, 1.0], [big"-0.5", big"0.5"], [BigFloat("1e-400")])
            f = H.OrderedProbitResponse(good)
            @test f.thresholds == Float64.(good)
            @test all(isfinite, f.thresholds)
        end
    end
    @testset "finite response checks retain each family domain" begin
        cases = ((H.GaussianResponse(1.0), [-2.0, 0.5]),
                 (H.PoissonResponse(), [0.0, 2.0]),
                 (H.BernoulliResponse(), [0.0, 1.0]),
                 (H.BinomialResponse(3), [0.0, 3.0]),
                 (H.BinomialVectorResponse([2, 3]), [0.0, 3.0]),
                 (H.NegativeBinomialResponse(2.0), [0.0, 3.0]),
                 (H.BetaBinomialResponse(3, 0.2), [0.0, 3.0]),
                 (H.BernoulliProbitResponse(), [0.0, 1.0]),
                 (H.OrderedProbitResponse([0.0]), [1.0, 2.0]),
                 (H.GammaResponse(2.0), [0.5, 1.0]))
        for (family, y) in cases
            @test H._check_counts(family, y) === nothing
            for bad in (Inf, -Inf, NaN, Float64(BigFloat("1e400")))
                @test_throws ArgumentError H._check_counts(family, [y[1], bad])
            end
        end
        @test_throws ArgumentError H._check_counts(H.PoissonResponse(), [-1.0, 2.0])
        @test_throws ArgumentError H._check_counts(H.PoissonResponse(), [0.5, 2.0])
        @test_throws ArgumentError H._check_counts(H.BernoulliResponse(), [0.0, 2.0])
        @test_throws ArgumentError H._check_counts(H.BinomialResponse(3), [0.0, 4.0])
        @test_throws ArgumentError H._check_counts(H.BinomialVectorResponse([2, 3]), [0.0])
        @test_throws ArgumentError H._check_counts(H.OrderedProbitResponse([0.0]), [0.0, 2.0])
        @test_throws ArgumentError H._check_counts(H.GammaResponse(2.0), [0.0, 1.0])
        for bad in (0, -1)
            @test_throws ArgumentError H.BetaBinomialResponse(bad, 0.2)
        end
        for bad in (0.0, 1.0, Inf, NaN)
            @test_throws ArgumentError H.BetaBinomialResponse(3, bad)
        end
        @test H.BetaBinomialResponse(3, 0.2).rho == 0.2
    end

    # In a regressed ingress path, stop after the actual proper-integral guard;
    # this prevents the regression test from executing any statistical mode work.
    struct FiniteIngressGuardPassed <: Exception end
    function H._check_flat_effect_integral(f::H.ResponseFamily,
                                         y::AbstractVector{Float64}, X::AbstractMatrix{Float64})
        invoke(H._check_flat_effect_integral, Tuple{H.ResponseFamily, Any, Any}, f, y, X)
        throw(FiniteIngressGuardPassed())
    end
    probe_method = which(H._check_flat_effect_integral,
        Tuple{H.ResponseFamily, AbstractVector{Float64}, AbstractMatrix{Float64}})
    try
        @testset "kernel ingress rejects before mode work" begin
            X = zeros(2, 0)
            Ai = Matrix{Float64}(I, 2, 2)
            for family in (H.GaussianResponse(1.0), H.GammaResponse(1.0))
                @test_throws ArgumentError H.laplace_marginal_loglik([1.0, Inf], X, Ai, Ai, 1.0, family)
                @test_throws ArgumentError H.gllvm_laplace_marginal_loglik(reshape([1.0, Inf], 2, 1), Ai, ones(1, 1), family; X=X)
            end
            @test_throws ArgumentError H.variational_marginal_loglik([1.0, Inf], X, Ai, Ai, 1.0, H.GaussianResponse(1.0))
            @test_throws FiniteIngressGuardPassed H.laplace_marginal_loglik([1.0, 2.0], X, Ai, Ai, 1.0, H.GaussianResponse(1.0))
        end
    finally
        Base.delete_method(probe_method)
    end
    @test which(H._check_flat_effect_integral, Tuple{H.ResponseFamily, Vector{Float64}, Matrix{Float64}}) ===
          which(H._check_flat_effect_integral, Tuple{H.ResponseFamily, Any, Any})
end

using Test, LinearAlgebra, HSquared

# Extend only the guard dispatch in this test process. Run the actual implementation
# first, then stop after the expected number of guard calls, before any mode work.
struct FlatIntegralGuardPassed <: Exception end
const flat_guard_visits = Ref(0)
const flat_guard_visit_limit = Ref(1)
function HSquared._check_flat_effect_integral(family::HSquared.ResponseFamily,
                                             y::AbstractVector{Float64},
                                             X::AbstractMatrix{Float64})
    invoke(HSquared._check_flat_effect_integral,
           Tuple{HSquared.ResponseFamily, Any, Any}, family, y, X)
    flat_guard_visits[] += 1
    flat_guard_visits[] == flat_guard_visit_limit[] && throw(FlatIntegralGuardPassed())
    return nothing
end
function endpoint_probe(f; expected_visits=1)
    flat_guard_visits[] = 0
    flat_guard_visit_limit[] = expected_visits
    return f()
end
actual_guard(f, y, X) = invoke(HSquared._check_flat_effect_integral,
                             Tuple{HSquared.ResponseFamily, Any, Any}, f, y, X)

const flat_guard_probe_method = which(HSquared._check_flat_effect_integral,
    Tuple{HSquared.ResponseFamily, AbstractVector{Float64}, AbstractMatrix{Float64}})
try
@testset "flat integral omitted family endpoints" begin
    H = HSquared
    n = 2
    X = ones(n, 1)
    Xnone = zeros(n, 0)
    Z = Matrix{Float64}(I, n, n)
    L = ones(1, 1)
    omitted = ((H.NegativeBinomialResponse(2.0), zeros(n)),
               (H.BetaBinomialResponse(5, 0.2), zeros(n)),
               (H.BetaBinomialResponse(5, 0.2), fill(5.0, n)))

    @testset "actual helper guards" begin
        for (family, y) in omitted
            @test_throws ArgumentError actual_guard(family, y, X)
            @test_throws ArgumentError actual_guard(family, y, 2.0 .* X)
            @test actual_guard(family, y, Xnone) === nothing
        end
        for (family, y) in ((H.NegativeBinomialResponse(2.0), [0.0, 1.0]),
                            (H.BetaBinomialResponse(5, 0.2), [0.0, 5.0]),
                            (H.BetaBinomialResponse(5, 0.2), [1.0, 2.0]))
            @test actual_guard(family, y, X) === nothing
        end
        @test_throws ArgumentError actual_guard(H.PoissonResponse(), zeros(n), X)
        @test_throws ArgumentError actual_guard(H.BinomialResponse(5), fill(5.0, n), X)
    end

    @testset "scalar and GLLVM guard paths reject before mode work" begin
        for (family, y) in omitted
            @test_throws ArgumentError endpoint_probe(() -> H.laplace_marginal_loglik(
                y, X, Z, Z, 1.0, family; maxiter=1))
            @test_throws ArgumentError endpoint_probe(() -> H.gllvm_laplace_marginal_loglik(
                reshape(y, n, 1), Z, L, family; X=X, maxiter=0))
            @test_throws ArgumentError endpoint_probe(() -> H.gllvm_laplace_marginal_loglik(
                hcat([1.0, 2.0], y), Z, ones(2, 1),
                [H.GaussianResponse(1.0), family]; X=X, maxiter=0); expected_visits=2)
            @test_throws FlatIntegralGuardPassed endpoint_probe(() -> H.laplace_marginal_loglik(
                y, Xnone, Z, Z, 1.0, family; maxiter=1))
            @test_throws FlatIntegralGuardPassed endpoint_probe(() -> H.gllvm_laplace_marginal_loglik(
                reshape(y, n, 1), Z, L, family; X=Xnone, maxiter=0))
        end
        for (family, y) in ((H.NegativeBinomialResponse(2.0), [0.0, 1.0]),
                            (H.BetaBinomialResponse(5, 0.2), [0.0, 5.0]),
                            (H.BetaBinomialResponse(5, 0.2), [1.0, 2.0]))
            @test_throws FlatIntegralGuardPassed endpoint_probe(() -> H.laplace_marginal_loglik(
                y, X, Z, Z, 1.0, family; maxiter=1))
            @test_throws FlatIntegralGuardPassed endpoint_probe(() -> H.gllvm_laplace_marginal_loglik(
                reshape(y, n, 1), Z, L, family; X=X, maxiter=0))
        end
    end
end

finally
    Base.delete_method(flat_guard_probe_method)
end
@test which(HSquared._check_flat_effect_integral,
            Tuple{HSquared.ResponseFamily, Vector{Float64}, Matrix{Float64}}) ===
      which(HSquared._check_flat_effect_integral, Tuple{HSquared.ResponseFamily, Any, Any})

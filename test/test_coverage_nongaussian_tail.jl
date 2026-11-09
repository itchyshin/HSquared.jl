# HJ1 — nongaussian.jl kernel and family-resolution tail.

using HSquared
using Test

@testset "nongaussian tail kernels (HJ1)" begin
    H = HSquared
    @testset "_ordered_interval_prob branches" begin
        # Left tail: both bounds ≤ 0
        @test H._ordered_interval_prob(-2.0, -1.0) ≈
              exp(H._norm_logcdf(-1.0)) - exp(H._norm_logcdf(-2.0)) atol = 1e-12
        # Right tail: both bounds ≥ 0
        @test H._ordered_interval_prob(1.0, 2.0) ≈
              exp(H._norm_logcdf(-1.0)) - exp(H._norm_logcdf(-2.0)) atol = 1e-12
        # Straddle 0
        @test H._ordered_interval_prob(-0.5, 0.5) ≈
              exp(H._norm_logcdf(0.5)) - exp(H._norm_logcdf(-0.5)) atol = 1e-12
        @test H._ordered_interval_prob(0.0, 0.0) == 0.0
    end

    @testset "_resolve_single_family" begin
        @test H._resolve_single_family(:poisson, nothing) === H.PoissonResponse()
        @test H._resolve_single_family(:binomial, 5) === H.BinomialResponse(5)
        @test H._resolve_single_family(:binomial, [2, 3, 4]) isa H.BinomialVectorResponse
        bb = H._resolve_single_family(:beta_binomial, 8; rho = 0.2)
        @test bb isa H.BetaBinomialResponse && bb.n_trials == 8
        @test_throws ArgumentError H._resolve_single_family(:beta_binomial, 8)
        @test_throws ArgumentError H._resolve_single_family(:binomial, 1.5)
        @test_throws ArgumentError H._resolve_single_family(:nope, 1)
    end

    @testset "Beta-binomial score at a non-extreme count" begin
        f = H.BetaBinomialResponse(6, 0.3)
        η = 0.15
        y = 4.0
        h = 1e-5
        score = H._fam_score(f, y, η)
        ll_p = H._fam_loglik(f, y, η + h)
        ll_m = H._fam_loglik(f, y, η - h)
        @test score ≈ (ll_p - ll_m) / (2h) rtol = 5e-4
        @test H._fam_weight(f, y, η) > 0
        @test H._fam_observed_weight(f, y, η) != H._fam_weight(f, y, η)
    end
end

using Test
using LinearAlgebra
using HSquared

@testset "Variational inner covariance convergence is required" begin
    H = HSquared
    n = 4
    y = ones(n)
    X = ones(n, 1)
    Z = Matrix{Float64}(I, n, n)
    Ainv = Matrix{Float64}(I, n, n)

    # At eta = 0, one success from two binomial trials has exactly zero
    # expected score by logistic symmetry, even when the posterior variance is
    # still moving. Force one covariance update to distinguish stationarity
    # from convergence of the covariance fixed point.
    fit = H.variational_marginal_loglik(
        y,
        X,
        Z,
        Ainv,
        0.5,
        H.BinomialResponse(2);
        tol = 1e-12,
        maxiter = 1,
        covariance_maxiter = 1,
    )

    @test fit.gradient_norm <= 1e-12
    @test !fit.covariance_converged
    @test fit.covariance_iterations == 1
    @test fit.covariance_fixed_point_error > 1e-12
    @test !fit.converged
    @test isnan(fit.elbo)

    converged_fit = H.variational_marginal_loglik(
        y,
        X,
        Z,
        Ainv,
        0.5,
        H.BinomialResponse(2);
        tol = 1e-12,
        maxiter = 1,
    )
    @test converged_fit.covariance_converged
    @test converged_fit.converged
    @test isfinite(converged_fit.elbo)
    @test keys(converged_fit)[1:10] == (
        :elbo,
        :beta,
        :m,
        :S,
        :converged,
        :gradient_norm,
        :iterations,
        :covariance,
        :objective,
        :is_lower_bound,
    )

    diagonal_fit = H.variational_marginal_loglik(
        y,
        X,
        Z,
        Ainv,
        0.5,
        H.BinomialResponse(2);
        covariance = :diagonal,
        tol = 1e-12,
        maxiter = 1,
    )
    @test diagonal_fit.converged && diagonal_fit.covariance_converged
    @test diagonal_fit.elbo ≈ converged_fit.elbo atol = 1e-12
    @test_throws ArgumentError H.variational_marginal_loglik(
        y,
        X,
        Z,
        Ainv,
        0.5,
        H.BinomialResponse(2);
        covariance_maxiter = 0,
    )
end

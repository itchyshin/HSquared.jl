using Test
using LinearAlgebra
using HSquared

@testset "Wave 2 relationship precision contracts" begin
    H = HSquared
    Y = reshape([0.2, 0.6, 1.1, 1.5], 4, 1)
    y = vec(Y)
    X = ones(4, 1)
    Z = Matrix{Float64}(I, 4, 4)
    Phi = ones(4, 1)
    G0 = reshape([0.5], 1, 1)
    R0 = reshape([2.0], 1, 1)
    family = H.GaussianResponse(2.0)
    invalid = (
        [1.0 0 0 0; 4 1 0 0; 0 0 1 0; 0 0 0 1],
        Diagonal([-0.1, 1.0, 1.0, 1.0]),
        Diagonal([0.0, 1.0, 1.0, 1.0]),
        Diagonal([NaN, 1.0, 1.0, 1.0]),
        ones(4, 3),
    )
    for Ai in invalid
        @test_throws ArgumentError H.multivariate_mme(Y, X, Z, Ai, G0, R0)
        @test_throws ArgumentError H.fit_multivariate_reml(Y, X, Z, Ai)
        @test_throws ArgumentError H.fit_multivariate_repeatability_reml(Y, X, Z, Ai)
        @test_throws ArgumentError H._multivariate_reml_loglik(Y, X, Z, Ai, G0, R0)
        @test_throws ArgumentError H.random_regression_mme(y, X, Phi, Z, Ai, G0, 2.0)
        @test_throws ArgumentError H.fit_random_regression_reml(y, X, Phi, Z, Ai)
        @test_throws ArgumentError H.laplace_marginal_loglik(y, X, Z, Ai, 0.5, family)
        @test_throws ArgumentError H.variational_marginal_loglik(y, X, Z, Ai, 0.5, family)
        @test_throws ArgumentError H.fit_laplace_reml(y, X, Z, Ai)
        @test_throws ArgumentError H.gllvm_laplace_marginal_loglik(Y, Ai, G0, family; X = X)
        @test_throws ArgumentError H.fit_gllvm_laplace_reml(Y, Ai, family; rank = 1, X = X)
    end
    # An invalid prior can hide behind a positive-definite marginal covariance.
    # The relationship precision itself must be checked before any fit.
    indefinite = Matrix(Diagonal([1.0, -1.0, 1.0, 1.0]))
    @test isposdef(Symmetric(inv(indefinite) + 10.0I))
    @test_throws ArgumentError H._multivariate_reml_loglik(
        Y, X, Z, indefinite, reshape([1.0], 1, 1), reshape([10.0], 1, 1))
    @test_throws ArgumentError H.fit_multivariate_reml(Y, X, Z, indefinite)
    @test_throws ArgumentError H.laplace_marginal_loglik(y, X, Z, indefinite, 1.0, family)
    @test_throws ArgumentError H.fit_gllvm_laplace_reml(Y, indefinite, family; rank = 1, X = X)
    tiny = 1e-8 .* Matrix{Float64}(I, 4, 4)
    tiny[1, 2] = 1e-12
    @test_throws ArgumentError H.multivariate_mme(Y, X, Z, tiny, G0, R0)

    nonsymmetric_K = [1.0 0.0; 9.0 1.0]
    Phi2 = hcat(ones(4), [-1.0, -0.3, 0.3, 1.0])
    @test_throws ArgumentError H.random_regression_mme(y, X, Phi2, Z, Z, nonsymmetric_K, 2.0)
    @test_throws ArgumentError H.fit_random_regression_reml(y, X, Phi2, Z, Z;
        initial = (K_g = nonsymmetric_K, sigma_e2 = 2.0))
    @test_throws ArgumentError H.fit_random_regression_reml(y, X, Phi2, Z, Z;
        initial = (K_g = [1.0 2.0; 2.0 1.0], sigma_e2 = 2.0))

    # A tolerated asymmetry must be used consistently in quadratic and logdet terms.
    Ai = Matrix{Float64}(I, 4, 4)
    Ai[1, 2] = 0.1 + 1e-12
    Ai[2, 1] = 0.1 - 1e-12
    As = (Ai + Ai') / 2
    la = H.laplace_marginal_loglik(y, X, Z, Ai, 0.5, family)
    ls = H.laplace_marginal_loglik(y, X, Z, As, 0.5, family)
    @test la.loglik ≈ ls.loglik atol = 1e-10
    va = H.variational_marginal_loglik(y, X, Z, Ai, 0.5, family)
    vs = H.variational_marginal_loglik(y, X, Z, As, 0.5, family)
    @test va.elbo ≈ vs.elbo atol = 1e-10
    ga = H.gllvm_laplace_marginal_loglik(Y, Ai, G0, family; X = X)
    gs = H.gllvm_laplace_marginal_loglik(Y, As, G0, family; X = X)
    @test ga.loglik ≈ gs.loglik atol = 1e-10
    @test H.multivariate_mme(Y, X, Z, Ai, G0, R0).breeding_values.values ≈
          H.multivariate_mme(Y, X, Z, As, G0, R0).breeding_values.values atol = 1e-10
    @test H.random_regression_mme(y, X, Phi, Z, Ai, G0, 2.0).random_coefficients.values ≈
          H.random_regression_mme(y, X, Phi, Z, As, G0, 2.0).random_coefficients.values atol = 1e-10
    Knear = [1.0 0.2 + 1e-12; 0.2 - 1e-12 0.8]
    Ksym = (Knear + Knear') / 2
    @test H.random_regression_mme(y, X, Phi2, Z, As, Knear, 2.0).random_coefficients.values ≈
          H.random_regression_mme(y, X, Phi2, Z, As, Ksym, 2.0).random_coefficients.values atol = 1e-10

    # A rank-one latent covariance across two traits is singular by design.
    Y2 = hcat(y, y .+ 0.1)
    lowrank = H.gllvm_laplace_marginal_loglik(Y2, As, fill(0.5, 2, 1), family; X = X)
    @test isfinite(lowrank.loglik)
end

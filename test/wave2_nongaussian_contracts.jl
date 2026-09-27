using Test
using LinearAlgebra
using HSquared

@testset "Wave 2 non-Gaussian objective contracts" begin
    H = HSquared
    @testset "Beta-binomial observed joint curvature" begin
        family = H.BetaBinomialResponse(8, 0.25)
        y = [6.0, 2.0, 5.0, 3.0]
        X = ones(4, 1)
        Z = [1.0 0 0; 0 1 0; 0 0 1; 1 0 0]
        Ai = [1.5 -0.2 0.0; -0.2 1.2 -0.1; 0.0 -0.1 1.1]
        sa2 = 0.7
        fit = H.laplace_marginal_loglik(y, X, Z, Ai, sa2, family)
        @test fit.converged
        mode = vcat(fit.beta, fit.u)
        joint(v) = sum(H._fam_loglik(family, y[i], (X * v[1:1] + Z * v[2:end])[i]) for i in eachindex(y)) - dot(v[2:end], Ai * v[2:end]) / (2sa2)
        # Independent central-difference Hessian of the joint density, not of
        # the working weights used by Fisher scoring.
        h = 2e-4
        d = length(mode)
        observed = zeros(d, d)
        basis = Matrix{Float64}(I, d, d)
        for i in 1:d, j in 1:d
            ei = h .* basis[:, i]; ej = h .* basis[:, j]
            observed[i, j] = -(joint(mode + ei + ej) - joint(mode + ei - ej) -
                               joint(mode - ei + ej) + joint(mode - ei - ej)) / (4h^2)
        end
        @test isposdef(Symmetric(observed))
        expected = joint(mode) - size(Z, 2) / 2 * log(sa2) +
                   logdet(cholesky(Symmetric(Ai))) / 2 + size(X, 2) / 2 * log(2pi) -
                   logdet(cholesky(Symmetric(observed))) / 2
        @test fit.loglik ≈ expected atol = 2e-6
    end

    @testset "Improper intercept integrals fail; fixed beta remains valid" begin
        n = 4
        X = ones(n, 1)
        X0 = zeros(n, 0)
        Z = Matrix{Float64}(I, n, n)
        cases = ((H.PoissonResponse(), zeros(n)),
                 (H.BernoulliResponse(), zeros(n)),
                 (H.BernoulliResponse(), ones(n)),
                 (H.BinomialResponse(5), zeros(n)),
                 (H.BinomialResponse(5), fill(5.0, n)),
                 (H.BinomialVectorResponse([2, 3, 4, 5]), [2.0, 3.0, 4.0, 5.0]))
        for (family, y) in cases
            @test_throws ArgumentError H.laplace_marginal_loglik(y, X, Z, Z, 0.5, family)
            @test_throws ArgumentError H.variational_marginal_loglik(y, X, Z, Z, 0.5, family)
            lap = H.laplace_marginal_loglik(y, X0, Z, Z, 0.5, family)
            va = H.variational_marginal_loglik(y, X0, Z, Z, 0.5, family)
            @test lap.converged && isfinite(lap.loglik)
            @test va.converged && isfinite(va.elbo)
        end
        # Intercept is a column-space property, not a column-name convention.
        @test_throws ArgumentError H.laplace_marginal_loglik(zeros(n), fill(2.0, n, 1), Z, Z, 0.5, H.PoissonResponse())
    end

    @testset "VA objective labels and Gaussian reduction" begin
        y = [2.0, 3.0, 5.0]
        Z = Matrix{Float64}(I, 3, 3)
        X = ones(3, 1)
        X0 = zeros(3, 0)
        hybrid = H.variational_marginal_loglik(y, X, Z, Z, 0.4, H.PoissonResponse())
        bound = H.variational_marginal_loglik(y, X0, Z, Z, 0.4, H.PoissonResponse())
        @test hybrid.converged && bound.converged
        @test hasproperty(hybrid, :objective) && hybrid.objective === :variational_laplace
        @test hasproperty(hybrid, :is_lower_bound) && !hybrid.is_lower_bound
        @test hasproperty(bound, :objective) && bound.objective === :elbo
        @test hasproperty(bound, :is_lower_bound) && bound.is_lower_bound
        gf = H.GaussianResponse(0.8)
        gaussian = H.variational_marginal_loglik(y, X, Z, Z, 0.4, gf)
        exact = H.laplace_marginal_loglik(y, X, Z, Z, 0.4, gf)
        @test gaussian.converged && exact.converged
        @test gaussian.elbo ≈ exact.loglik atol = 1e-10
        @test hasproperty(gaussian, :objective) && gaussian.objective === :gaussian_reml
        @test hasproperty(gaussian, :is_lower_bound) && gaussian.is_lower_bound
    end
end

@testset "Wave 2 beta-binomial symbolic curvature" begin
    H = HSquared
    f = H.BetaBinomialResponse(20, 0.5)
    for y in (0.0, 5.0, 20.0), eta in (-3.0, 0.2, 3.0)
        h = 1e-5
        observed = -(H._fam_score(f, y, eta + h) - H._fam_score(f, y, eta - h)) / (2h)
        @test H._fam_observed_weight(f, y, eta) ≈ observed atol = 1e-7
    end
    @test H._fam_observed_weight(f, 0.0, 3.0) < 0
    @test H._fam_weight(f, 0.0, 3.0) > 0
end

@testset "Wave 2 GLLVM observed-curvature reduction" begin
    H = HSquared
    y = [6.0, 2.0, 5.0, 3.0]
    X = ones(4, 1)
    Z = Matrix{Float64}(I, 4, 4)
    Ai = [1.5 -0.2 0.0 0.0; -0.2 1.2 -0.1 0.0; 0.0 -0.1 1.1 -0.1; 0.0 0.0 -0.1 1.2]
    family = H.BetaBinomialResponse(8, 0.25)
    sa2 = 0.7
    single = H.laplace_marginal_loglik(y, X, Z, Ai, sa2, family)
    latent = H.gllvm_laplace_marginal_loglik(reshape(y, :, 1), Ai, fill(sqrt(sa2), 1, 1), family; X = X)
    @test single.converged && latent.converged
    @test latent.loglik ≈ single.loglik atol = 1e-9
end

@testset "Wave 2 GLLVM improper per-trait intercept integrals" begin
    H = HSquared
    n = 4
    Ai = Matrix{Float64}(I, n, n)
    L = reshape([0.6, 0.4], 2, 1)
    for (family, endpoint, valid) in ((H.PoissonResponse(), 0.0, [1.0, 2.0, 3.0, 1.0]),
                                     (H.BernoulliResponse(), 0.0, [1.0, 0.0, 1.0, 0.0]),
                                     (H.BernoulliResponse(), 1.0, [1.0, 0.0, 1.0, 0.0]),
                                     (H.BinomialResponse(5), 0.0, [1.0, 2.0, 3.0, 4.0]),
                                     (H.BinomialResponse(5), 5.0, [1.0, 2.0, 3.0, 4.0]))
        Y = hcat(valid, fill(endpoint, n))
        @test_throws ArgumentError H.gllvm_laplace_marginal_loglik(Y, Ai, L, family)
        @test_throws ArgumentError H.gllvm_laplace_marginal_loglik(Y, Ai, L, [family, family])
        fixed = H.gllvm_laplace_marginal_loglik(Y, Ai, L, family; X = zeros(n, 0))
        @test fixed.converged && isfinite(fixed.loglik)
    end
end

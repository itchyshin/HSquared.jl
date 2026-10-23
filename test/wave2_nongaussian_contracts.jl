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
                 (H.BernoulliProbitResponse(), zeros(n)),
                 (H.BernoulliProbitResponse(), ones(n)),
                 (H.OrderedProbitResponse([0.0]), ones(n)),
                 (H.OrderedProbitResponse([0.0]), fill(2.0, n)),
                 (H.OrderedProbitResponse([0.0, 1.0]), ones(n)),
                 (H.OrderedProbitResponse([0.0, 1.0]), fill(3.0, n)),
                 (H.BinomialResponse(5), zeros(n)),
                 (H.BinomialResponse(5), fill(5.0, n)),
                 (H.BinomialVectorResponse([2, 3, 4, 5]), [2.0, 3.0, 4.0, 5.0]))
        for (family, y) in cases
            @test_throws ArgumentError H.laplace_marginal_loglik(y, X, Z, Z, 0.5, family)
            lap = H.laplace_marginal_loglik(y, X0, Z, Z, 0.5, family)
            @test lap.converged && isfinite(lap.loglik)
            # Probit families have a Laplace implementation only; do not imply a VA route.
            (family isa H.BernoulliProbitResponse || family isa H.OrderedProbitResponse) && continue
            @test_throws ArgumentError H.variational_marginal_loglik(y, X, Z, Z, 0.5, family)
            va = H.variational_marginal_loglik(y, X0, Z, Z, 0.5, family)
            @test va.converged && isfinite(va.elbo)
        end
        # Intercept is a column-space property, not a column-name convention.
        @test_throws ArgumentError H.laplace_marginal_loglik(zeros(n), fill(2.0, n, 1), Z, Z, 0.5, H.PoissonResponse())
        @test_throws ArgumentError H.laplace_marginal_loglik(ones(n), fill(2.0, n, 1), Z, Z, 0.5, H.BernoulliProbitResponse())
        @test_throws ArgumentError H.laplace_marginal_loglik(ones(n), fill(2.0, n, 1), Z, Z, 0.5, H.OrderedProbitResponse([0.0]))
    end

    @testset "Large-count Poisson mode remains finite" begin
        nlarge = 1e9
        stirling = (nlarge + 0.5) * log(nlarge) - nlarge + 0.5 * log(2pi) + 1 / (12nlarge)
        @test HSquared._logfactorial(nlarge) ≈ stirling rtol = 1e-14

        # Compare the complete conditional log density to a high-precision
        # direct formula. Testing log-factorial alone misses cancellation in
        # y*η - exp(η) - log(y!).
        yhuge = 1e15
        ηhuge = log(yhuge)
        reference = setprecision(BigFloat, 256) do
            yb = BigFloat(yhuge)
            ηb = BigFloat(ηhuge)
            invy = inv(yb)
            logfactorial = (yb + BigFloat(0.5)) * log(yb) - yb +
                           BigFloat(0.5) * log(BigFloat(2) * big(pi)) +
                           invy / 12 - invy^3 / 360 + invy^5 / 1260
            yb * ηb - exp(ηb) - logfactorial
        end
        @test H._fam_loglik(H.PoissonResponse(), yhuge, ηhuge) ≈ Float64(reference) atol = 1e-10
        vhuge = 0.25
        expected_reference = setprecision(BigFloat, 256) do
            yb = BigFloat(yhuge)
            ηb = BigFloat(ηhuge)
            vb = BigFloat(vhuge)
            invy = inv(yb)
            logfactorial = (yb + BigFloat(0.5)) * log(yb) - yb +
                           BigFloat(0.5) * log(BigFloat(2) * big(pi)) +
                           invy / 12 - invy^3 / 360 + invy^5 / 1260
            yb * ηb - exp(ηb + vb / 2) - logfactorial
        end
        @test H._fam_expected_loglik(H.PoissonResponse(), yhuge, ηhuge, vhuge) ≈
              Float64(expected_reference) rtol = 2e-15
        @test H._fam_expected_loglik(H.PoissonResponse(), 0.0, -1000.0, 2000.0) ≈ -1.0
        @test H._fam_expected_loglik(H.PoissonResponse(), 3.0, -1000.0, 2000.0) ≈ -3001.0 - log(6.0)
        @test H._fam_expected_loglik(H.PoissonResponse(), 0.0, -700.0, 1420.0) ≈ -exp(10.0)
        @test H._fam_expected_loglik(H.PoissonResponse(), 0.0, 1000.0, 0.0) == -Inf

        huge_fit = H.laplace_marginal_loglik([yhuge], zeros(1, 0), ones(1, 1),
                                              ones(1, 1), 1.0, H.PoissonResponse())
        @test huge_fit.converged
        fit_reference = setprecision(BigFloat, 256) do
            yb = BigFloat(yhuge)
            ub = BigFloat(huge_fit.u[1])
            invy = inv(yb)
            logfactorial = (yb + BigFloat(0.5)) * log(yb) - yb +
                           BigFloat(0.5) * log(BigFloat(2) * big(pi)) +
                           invy / 12 - invy^3 / 360 + invy^5 / 1260
            conditional = yb * ub - exp(ub) - logfactorial
            conditional - ub^2 / 2 - BigFloat(0.5) * log(exp(ub) + 1)
        end
        @test huge_fit.loglik ≈ Float64(fit_reference) atol = 1e-9

        y = [999.0, 1000.0, 1001.0]
        X = ones(3, 1)
        Z = Matrix{Float64}(I, 3, 3)
        fit = H.laplace_marginal_loglik(y, X, Z, Z, 1.0, H.PoissonResponse())
        @test fit.converged
        @test isfinite(fit.loglik)
        @test fit.gradient_norm < 1e-8
        @test all(isfinite, fit.beta) && all(isfinite, fit.u)

        # Very large counts can produce overflowing Newton proposals; cover
        # both no-fixed-effect and sparse, strongly-associated designs.
        no_fixed = H.laplace_marginal_loglik(fill(2000.0, 3), zeros(3, 0), Z, Z, 1.0, H.PoissonResponse())
        @test no_fixed.converged && isfinite(no_fixed.loglik)
        @test no_fixed.gradient_norm < 1e-8

        extreme = H.laplace_marginal_loglik([1e9], zeros(1, 0), ones(1, 1), ones(1, 1), 1.0, H.PoissonResponse())
        @test extreme.converged && isfinite(extreme.loglik)
        @test extreme.gradient_norm < 1e-4

        # Coefficient scales must not determine whether a mode is declared converged.
        scaled_X = fill(1e12, 3, 1)
        scaled = H.laplace_marginal_loglik(fill(2.0, 3), scaled_X, Z, Z, 1.0, H.PoissonResponse())
        @test scaled.converged
        @test scaled.beta[1] * 1e12 ≈ log(2.0) atol = 1e-8
        @test norm(scaled.u) < 1e-8

        small_X = fill(1e-12, 3, 1)
        small_Z = fill(1e-12, 3, 1)
        small = H.laplace_marginal_loglik(fill(2.0, 3), small_X, small_Z, ones(1, 1), 1.0, H.PoissonResponse())
        @test small.converged
        @test small.beta[1] * 1e-12 ≈ log(2.0) atol = 1e-8
        @test abs(small.u[1] * 1e-12) < 1e-8

        y_rare = zeros(1000); y_rare[1] = 1.0
        Z_rare = reshape(y_rare, :, 1)
        rare = H.laplace_marginal_loglik(y_rare, ones(1000, 1), Z_rare, ones(1, 1), 1e6, H.PoissonResponse())
        @test rare.converged && isfinite(rare.loglik)
        @test rare.gradient_norm < 1e-8
    end

    @testset "Laplace and variational controls reject invalid values" begin
        y = [0.0, 1.0, 3.0, 4.0]
        X = ones(4, 1)
        Z = Matrix{Float64}(I, 4, 4)
        Ai = Matrix{Float64}(I, 4, 4)
        family = H.PoissonResponse()

        # An infinite tolerance currently declares the zero start converged,
        # despite a large score and a nonzero fitted intercept.
        for bad_tol in (Inf, NaN, 0.0, -1.0)
            @test_throws ArgumentError H.laplace_marginal_loglik(
                y, X, Z, Ai, 1.0, family; tol = bad_tol)
            @test_throws ArgumentError H.variational_marginal_loglik(
                y, X, Z, Ai, 1.0, family; tol = bad_tol)
        end
        for bad_maxiter in (0, -1)
            @test_throws ArgumentError H.laplace_marginal_loglik(
                y, X, Z, Ai, 1.0, family; maxiter = bad_maxiter)
            @test_throws ArgumentError H.variational_marginal_loglik(
                y, X, Z, Ai, 1.0, family; maxiter = bad_maxiter)
        end
        @test_throws ArgumentError H.laplace_marginal_loglik(
            y, X, Z, Ai, Inf, family)
        @test_throws ArgumentError H.variational_marginal_loglik(
            y, X, Z, Ai, Inf, family)
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

    # A diagonal variational covariance is not the inverse Hessian for the
    # random-effect means. With a shared random-effect design, using it in the
    # fixed-effect Schur correction makes a valid integrated model appear
    # indefinite (the correct profiled curvature is 1/4 here).
    correlated_design = H.variational_marginal_loglik(
        [0.0],
        ones(1, 1),
        ones(1, 3),
        Matrix{Float64}(I, 3, 3),
        1.0,
        H.GaussianResponse(1.0);
        covariance = :diagonal,
    )
    @test correlated_design.converged
    @test isfinite(correlated_design.elbo)
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

@testset "Wave 2 non-Gaussian fitter validates effect IDs before fitting" begin
    H = HSquared
    y = [1.0, 2.0, 3.0]
    X = ones(3, 1)
    Z = Matrix{Float64}(I, 3, 3)
    Ainv = Matrix{Float64}(I, 3, 3)
    invalid_start = (sigma_a2 = -1.0, sigma_e2 = 1.0)

    function error_for_ids(ids)
        err = try
            H.fit_laplace_reml(
                y,
                X,
                Z,
                Ainv;
                family = :gaussian,
                ids = ids,
                initial = invalid_start,
            )
            nothing
        catch caught
            caught
        end
        return err
    end

    wrong_length = error_for_ids(["a", "b"])
    @test wrong_length isa ArgumentError
    @test occursin("ids", lowercase(sprint(showerror, wrong_length)))
    too_many = error_for_ids(["a", "b", "c", "d"])
    @test too_many isa ArgumentError
    @test occursin("ids", lowercase(sprint(showerror, too_many)))
    duplicate = error_for_ids(["a", "a", "c"])
    @test duplicate isa ArgumentError
    @test occursin("unique", lowercase(sprint(showerror, duplicate)))

    initial = (sigma_a2 = 0.5, sigma_e2 = 1.0)
    supplied = H.fit_laplace_reml(
        y, X, Z, Ainv;
        family = :gaussian,
        ids = ["a", "b", "c"],
        initial = initial,
        iterations = 1,
    )
    default = H.fit_laplace_reml(
        y, X, Z, Ainv;
        family = :gaussian,
        initial = initial,
        iterations = 1,
    )
    @test supplied.ids == ["a", "b", "c"]
    @test default.ids == [1, 2, 3]
end

@testset "Wave 2 profile intervals require a usable point fit" begin
    H = HSquared
    y = [3.0, 5.0, 8.0]
    X = ones(3, 1)
    Z = Matrix{Float64}(I, 3, 3)
    Ainv = Matrix{Float64}(I, 3, 3)

    function captured_error(f)
        try
            f()
            nothing
        catch err
            err
        end
    end
    error_message(err) = err isa Exception ? lowercase(sprint(showerror, err)) : ""

    nonconverged = captured_error(() -> H.laplace_reml_interval(
        y, X, Z, Ainv; family = :poisson, initial = (sigma_a2 = 1.0,), iterations = 1,
    ))
    @test nonconverged isa ArgumentError
    @test occursin("converged", error_message(nonconverged))

    boundary = captured_error(() -> H.laplace_reml_interval(
        y, X, Z, Ainv; family = :poisson, initial = (sigma_a2 = 1e-8,),
    ))
    @test boundary isa ArgumentError
    @test occursin("boundary", error_message(boundary))

    q = 8
    groups = repeat(1:q, inner = 8)
    Zrep = zeros(length(groups), q)
    for (i, group) in enumerate(groups)
        Zrep[i, group] = 1.0
    end
    yrep = Float64.(repeat([1, 1, 1, 2, 2, 15, 16, 17], inner = 8))
    Xrep = ones(length(yrep), 1)
    Ainv_rep = Matrix{Float64}(I, q, q)
    ci = H.laplace_reml_interval(yrep, Xrep, Zrep, Ainv_rep; family = :poisson)
    @test ci.converged
    @test ci.lower < ci.sigma_a2 < ci.upper
end

@testset "Wave 2 profile LRT rejects failed inner likelihood evaluations" begin
    H = HSquared
    y = [3.0, 5.0, 8.0]
    X = ones(3, 1)
    Z = Matrix{Float64}(I, 3, 3)
    Ainv = Matrix{Float64}(I, 3, 3)
    err = try
        H._laplace_profile_lrt(
            y, X, Z, Ainv, 1.0, H.PoissonResponse(), -10.0, 3.84; maxiter = 1,
        )
        nothing
    catch caught
        caught
    end
    @test err isa ArgumentError
    @test occursin("profile", lowercase(sprint(showerror, err)))
end

include(joinpath(@__DIR__, "test_nongaussian_inner_convergence.jl"))

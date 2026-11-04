# HSquared.jl #424: the NelderMead fitters report `converged = true` only when a
# shared gradient and curvature check at the optimum passes, not on Optim's
# simplex-spread rule alone. Each fitter gets a design whose REML surface is an
# exact ridge (one record per unrelated animal, so every variance component
# loads on the same diagonal); there the simplex still contracts, but the
# optimum is not identified.
# Standalone:
# julia --project=. -e 'include("test/test_issue_424_nelder_mead_convergence.jl")'

using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "issue 424 shared NelderMead convergence check" begin
    @testset "helper: gradient, curvature, boundary mask, known invariance" begin
        bowl(x) = (x[1] - 1)^2 + 4 * (x[2] + 2)^2
        at_min = HSquared._nelder_mead_stationarity(bowl, [1.0, -2.0])
        @test at_min.stationary
        @test at_min.gain < 1e-12
        @test isapprox(at_min.ridge, 1.0; rtol = 1e-6)
        # the bowl still descends from here: Newton gain 0.5 * 0.4^2 / 2 = 0.04
        off_min = HSquared._nelder_mead_stationarity(bowl, [1.2, -2.0])
        @test !off_min.stationary
        @test isapprox(off_min.gain, 0.04; rtol = 1e-4)
        # only x1 + x2 is identified: a flat direction
        ridge(x) = (x[1] + x[2] - 1)^2
        @test !HSquared._nelder_mead_stationarity(ridge, [0.3, 0.7]).stationary
        # a declared exact invariance is not a ridge
        @test HSquared._nelder_mead_stationarity(ridge, [0.3, 0.7]; null_dims = 1).stationary
        # a coordinate the fitter reports as a boundary is not checked
        @test HSquared._nelder_mead_stationarity(ridge, [0.3, 0.7]; free = [true, false]).stationary
        saddle(x) = x[1]^2 - x[2]^2
        @test !HSquared._nelder_mead_stationarity(saddle, [0.0, 0.0]).stationary
    end

    n = 40
    y = [3.0 + 1.5 * sin(1.7 * i) + 0.4 * cos(0.3 * i^2) for i in 1:n]
    y2 = [1.0 + 0.6 * y[i] + 0.8 * cos(2.3 * i) for i in 1:n]
    X = ones(n, 1)
    I_n = sparse(1.0I, n, n)
    ridge_warning = (:warn, r"not all identifiable")

    @testset "fit_variance_components" begin
        fit = fit_variance_components(animal_model_spec(y, X, I_n, I_n; method = :REML))
        @test !fit.converged
        @test fit.optimizer_status == "not_converged"
    end

    @testset "fit_sparse_reml" begin
        fit = fit_sparse_reml(animal_model_spec(y, X, I_n, I_n; method = :REML))
        @test !fit.converged
        @test fit.optimizer_status == "not_converged"
    end

    @testset "fit_two_effect_reml" begin
        fit = @test_logs ridge_warning match_mode = :any fit_two_effect_reml(
            y, X, I_n, I_n, I_n, I_n)
        @test !fit.converged
    end

    @testset "fit_multi_effect_reml" begin
        fit = @test_logs ridge_warning match_mode = :any fit_multi_effect_reml(
            y, X, [(I_n, I_n), (I_n, I_n)])
        @test !fit.converged
    end

    @testset "fit_direct_maternal_reml" begin
        @test !fit_direct_maternal_reml(y, X, I_n, I_n, I_n).converged
    end

    @testset "fit_repeatability_reml" begin
        @test !fit_repeatability_reml(y, X, I_n, I_n).converged
    end

    @testset "fit_random_regression_reml" begin
        @test !fit_random_regression_reml(y, X, ones(n, 1), I_n, I_n).converged
    end

    @testset "fit_multivariate_reml" begin
        @test !fit_multivariate_reml(hcat(y, y2), X, I_n, I_n).converged
    end

    @testset "fit_multivariate_repeatability_reml" begin
        @test !fit_multivariate_repeatability_reml(hcat(y, y2), X, I_n, I_n).converged
    end

    @testset "fit_gllvm_laplace_reml" begin
        # T = 2 traits, one common factor plus two specific variances: four
        # parameters for the three entries of a 2 x 2 genetic covariance.
        q = 30
        Y = hcat([1.0 + 0.8 * sin(1.3 * i) + 0.5 * cos(2.9 * i) for i in 1:q],
                 [2.0 + 0.6 * sin(1.3 * i) + 0.5 * sin(3.7 * i) for i in 1:q])
        fit = HSquared.fit_gllvm_laplace_reml(Y, Matrix(1.0I, q, q), HSquared.GaussianResponse(0.25);
                                              rank = 1, structure = :factor_analytic)
        @test fit.mode_converged
        @test !fit.optimizer_converged
        @test !fit.converged
    end

    @testset "fit_laplace_reml (Gaussian NelderMead branch)" begin
        fit = fit_laplace_reml(y, X, I_n, I_n; family = :gaussian,
                               initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
        @test !fit.boundary
        @test !fit.converged
    end

    @testset "identified designs still converge" begin
        # two records per animal separate sigma_a2 from sigma_e2
        Zr = sparse(1:(2n), repeat(1:n, 2), 1.0, 2n, n)
        yr = vcat(y, [y[i] + 0.9 * sin(5.1 * i) for i in 1:n])
        spec = animal_model_spec(yr, ones(2n, 1), Zr, I_n; method = :REML)
        @test fit_variance_components(spec).converged
        @test fit_sparse_reml(spec).converged
    end
end

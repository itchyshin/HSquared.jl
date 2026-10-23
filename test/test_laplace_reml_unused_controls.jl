# HSquared.jl #439 — fit_laplace_reml must not silently drop family-specific controls.
# Standalone: julia --project=. -e 'include("test/test_laplace_reml_unused_controls.jl")'

using HSquared
using LinearAlgebra
using Test

function _laplace_unused_fixture(y)
    ped = normalize_pedigree(["sire", "dam", "calf"], ["0", "0", "sire"], ["0", "0", "dam"])
    return y, ones(3, 1), Matrix(1.0I, 3, 3), pedigree_inverse(ped)
end

function _unused_control_error(y; kwargs...)
    yv, X, Z, Ainv = _laplace_unused_fixture(y)
    try
        fit_laplace_reml(yv, X, Z, Ainv; kwargs...)
        return nothing
    catch e
        return e
    end
end

function _names_unused(err, family, keyword)
    msg = sprint(showerror, err)
    return err isa ArgumentError && occursin(string(keyword), msg) &&
        occursin(":" * string(family), msg)
end

@testset "fit_laplace_reml unused family controls (HSquared.jl #439)" begin
    binary = [0.0, 1.0, 1.0]
    counts = [1.0, 3.0, 5.0]
    positive = [0.8, 1.5, 2.1]
    gaussian_y = [1.0, 2.5, 4.0]

    @testset "unused controls error and name the ignored keyword" begin
        err_rho = _unused_control_error(binary; family = :binomial, n_trials = 2, rho = 0.2)
        @test _names_unused(err_rho, :binomial, "rho")

        err_trials_poisson = _unused_control_error(counts; family = :poisson, n_trials = 20)
        @test _names_unused(err_trials_poisson, :poisson, "n_trials")

        err_trials_bernoulli = _unused_control_error(binary; family = :bernoulli, n_trials = 5)
        @test _names_unused(err_trials_bernoulli, :bernoulli, "n_trials")

        err_theta = _unused_control_error(counts; family = :poisson, theta_init = 2.0)
        @test _names_unused(err_theta, :poisson, "theta_init")

        err_sigma_e2 = _unused_control_error(
            counts;
            family = :poisson,
            initial = (sigma_a2 = 1.0, sigma_e2 = 0.5),
        )
        @test _names_unused(err_sigma_e2, :poisson, "initial.sigma_e2")
    end

    @testset "families that use a control still accept it" begin
        yb, X, Z, Ainv = _laplace_unused_fixture(binary)
        fb = fit_laplace_reml(yb, X, Z, Ainv; family = :binomial, n_trials = 2)
        @test fb.family === :binomial
        @test fb.n_trials == 2

        fbb = fit_laplace_reml(yb, X, Z, Ainv; family = :beta_binomial, n_trials = 4, rho = 0.2)
        @test fbb.family === :beta_binomial
        @test fbb.n_trials == 4
        @test fbb.dispersion == 0.2

        yc, Xc, Zc, Ac = _laplace_unused_fixture(counts)
        fnb = fit_laplace_reml(yc, Xc, Zc, Ac; family = :nbinom, theta_init = 2.0)
        @test fnb.family === :nbinom
        @test fnb.variance_components.theta > 0

        yg, Xg, Zg, Ag = _laplace_unused_fixture(positive)
        fga = fit_laplace_reml(yg, Xg, Zg, Ag; family = :gamma, theta_init = 2.0)
        @test fga.family === :gamma
        @test fga.variance_components.shape > 0

        ygs, Xgs, Zgs, Ags = _laplace_unused_fixture(gaussian_y)
        fgauss = fit_laplace_reml(
            ygs, Xgs, Zgs, Ags;
            family = :gaussian,
            initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
        )
        @test fgauss.family === :gaussian
        @test fgauss.variance_components.sigma_e2 > 0
    end
end

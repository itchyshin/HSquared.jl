# HSquared.jl #434 — repeatability_interval must not difference the REML
# loglik across zero, must return fit.converged, and must flag a boundary
# or non-converged fit instead of a finite interval.
# Standalone: julia --project=. test/test_issue_434_repeatability_interval.jl

using HSquared
using LinearAlgebra
using Test

function _issue434_repeatability_fixture()
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    Z = zeros(8, 4)
    for (rec, an) in enumerate([1, 1, 2, 2, 3, 3, 4, 4])
        Z[rec, an] = 1.0
    end
    y = [14.0, 13.0, 6.9, 6.1, 12.1, 11.5, 8.9, 8.5]
    X = ones(8, 1)
    return y, X, Z, Ainv
end

function _issue434_near_boundary_fit(; converged::Bool = true)
    return (
        variance_components = (sigma_a2 = 1.0, sigma_pe2 = 1e-9, sigma_e2 = 1.0),
        converged = converged,
    )
end

@testset "repeatability interval boundary and convergence (#434)" begin
    y, X, Z, Ainv = _issue434_repeatability_fixture()

    @testset "non-converged fit returns NaN limits and flags" begin
        ci = repeatability_interval(y, X, Z, Ainv; iterations = 1)
        @test ci.converged === false
        @test ci.boundary === true
        @test isfinite(ci.repeatability)
        @test isnan(ci.lower)
        @test isnan(ci.upper)
        @test isnan(ci.se)
    end

    @testset "near-zero variance is a boundary, not a finite SE" begin
        fit = _issue434_near_boundary_fit()
        ci = HSquared._repeatability_interval_from_fit(
            fit, y, X, Z, Ainv;
            level = 0.95, fd_step = 1e-4, boundary_tol = 1e-6,
        )
        @test ci.converged === true
        @test ci.boundary === true
        @test isnan(ci.lower)
        @test isnan(ci.upper)
        @test isnan(ci.se)
        @test ci.repeatability ≈ 0.5
    end

    @testset "t near the unit rail is a boundary" begin
        fit = (
            variance_components = (sigma_a2 = 0.5, sigma_pe2 = 0.5, sigma_e2 = 1e-12),
            converged = true,
        )
        ci = HSquared._repeatability_interval_from_fit(
            fit, y, X, Z, Ainv;
            level = 0.95, fd_step = 1e-4, boundary_tol = 1e-6,
        )
        @test ci.boundary === true
        @test isnan(ci.lower)
        @test isnan(ci.upper)
        @test isnan(ci.se)
        @test ci.repeatability ≈ 1.0 atol = 1e-11
    end

    @testset "finite-difference steps stay inside the parameter space" begin
        theta = [1.0, 1e-9, 1.0]
        h = HSquared._uncertainty_component_steps(theta, 1e-4)
        @test !all(theta .- 2 .* h .> 0)
    end
end

# HSquared.jl #432 — bootstrap intervals must not swallow unexpected
# errors, and must refuse a percentile built from too few interior refits.
# Standalone: julia --project=. -e 'include("test/test_issue_432_bootstrap_interval.jl")'

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

function _issue432_force_handle(err)
    try
        throw(err)
    catch caught
        return HSquared._bootstrap_handle_refit_error(caught)
    end
end

@testset "bootstrap interval drop contract (HSquared.jl #432)" begin
    @testset "only expected numerical failures are dropped" begin
        @test _issue432_force_handle(PosDefException(1)) === nothing
        @test _issue432_force_handle(SingularException(1)) === nothing
        @test _issue432_force_handle(ArgumentError("likelihood numerical range: test")) === nothing

        @test_throws MethodError _issue432_force_handle(MethodError(sin, ("x",)))
        @test_throws BoundsError _issue432_force_handle(BoundsError([1], 2))
        @test_throws InterruptException _issue432_force_handle(InterruptException())
        @test_throws ArgumentError _issue432_force_handle(ArgumentError("unrelated"))
    end

    @testset "refit outcomes are counted by cause" begin
        interior = (variance_components = (sigma_a2 = 0.8, sigma_e2 = 1.2),)
        good = merge(interior, (converged = true,))
        stalled = merge(interior, (converged = false,))
        boundary = (converged = true, variance_components = (sigma_a2 = 0.0, sigma_e2 = 1.2))
        invalid = (converged = true, variance_components = (sigma_a2 = NaN, sigma_e2 = 1.2))

        @test HSquared._bootstrap_refit_status(good) === :usable
        @test HSquared._bootstrap_refit_status(stalled) === :nonconverged
        @test HSquared._bootstrap_refit_status(boundary) === :boundary
        @test HSquared._bootstrap_refit_status(invalid) === :invalid
        @test HSquared._bootstrap_usable_refit(good)
        @test !HSquared._bootstrap_usable_refit(boundary)
    end

    @testset "minimum n_converged is required" begin
        HSquared._bootstrap_require_enough_replicates(
            2, 100; min_converged = 2, min_converged_rate = 0.0,
        )
        err = try
            HSquared._bootstrap_require_enough_replicates(
                1, 1000; min_converged = 2, min_converged_rate = 0.0,
            )
            nothing
        catch caught
            caught
        end
        @test err isa ArgumentError
        @test occursin("min_converged = 2", sprint(showerror, err))
        @test occursin("n_converged = 1 of n_boot = 1000", sprint(showerror, err))

        rate_err = try
            HSquared._bootstrap_require_enough_replicates(
                1, 100; min_converged = 1, min_converged_rate = 0.5,
            )
            nothing
        catch caught
            caught
        end
        @test rate_err isa ArgumentError
        @test occursin("min_converged_rate = 0.5", sprint(showerror, rate_err))
    end

    @testset "public interval keeps #437 and reports drop counts" begin
        y = [1.0, 2.0, 4.0]
        X = ones(3, 1)
        Z = sparse(1.0I, 3, 3)
        Ainv = sparse(1.0I, 3, 3)
        spec = animal_model_spec(y, X, Z, Ainv; method = :REML)
        likelihood = sparse_reml_loglik(spec, 1.0, 1.0)
        stalled = AnimalModelFit(
            spec,
            likelihood,
            (sigma_a2 = 1.0, sigma_e2 = 1.0),
            false,
            "iteration_limit",
            1,
        )
        stalled_err = try
            bootstrap_variance_component_interval(stalled; n_boot = 1)
            nothing
        catch caught
            caught
        end
        @test stalled_err isa ArgumentError
        @test occursin("converged = true", sprint(showerror, stalled_err))

        fit = fit_sparse_reml(spec)
        @test fit.converged
        @test_throws ArgumentError bootstrap_variance_component_interval(
            fit; n_boot = 2, min_converged = 3,
        )

        bs = bootstrap_variance_component_interval(
            fit; n_boot = 2, min_converged = 1, rng = Random.MersenneTwister(432),
        )
        @test bs.n_boot == 2
        @test bs.n_converged + bs.n_dropped_error +
              bs.n_dropped_boundary + bs.n_dropped_nonconverged == 2
        @test length(bs.replicates.sigma_a2) == bs.n_converged
        @test bs.n_converged >= 1
    end
end

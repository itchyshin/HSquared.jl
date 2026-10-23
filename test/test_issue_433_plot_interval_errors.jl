# HSquared.jl #433 — plot-data intervals report expected failures and rethrow
# interrupts or programming errors.
# Standalone: julia --project=. test/test_issue_433_plot_interval_errors.jl

using HSquared
using LinearAlgebra
using SparseArrays
using Test

function _issue433_force_handle(err)
    try
        throw(err)
    catch caught
        return HSquared._plot_interval_failure_reason(caught)
    end
end

@testset "variance-component plot interval errors (#433)" begin
    @test _issue433_force_handle(PosDefException(1)) ==
          "non_positive_definite_information"
    @test _issue433_force_handle(SingularException(1)) == "singular_information"
    @test startswith(
        _issue433_force_handle(DomainError(-1.0, "test domain")),
        "domain_error: ",
    )
    @test startswith(
        _issue433_force_handle(ArgumentError("expected interval refusal")),
        "argument_error: ",
    )

    @test_throws MethodError _issue433_force_handle(MethodError(sin, ("x",)))
    @test_throws BoundsError _issue433_force_handle(BoundsError([1], 2))
    @test_throws InterruptException _issue433_force_handle(InterruptException())

    y = [1.0, 2.0, 4.0]
    X = ones(3, 1)
    Z = sparse(1.0I, 3, 3)
    Ainv = sparse(1.0I, 3, 3)

    ml_spec = animal_model_spec(y, X, Z, Ainv; method = :ML)
    ml_fit = AnimalModelFit(
        ml_spec,
        gaussian_loglik(ml_spec, 1.0, 1.0; method = :ML),
        (sigma_a2 = 1.0, sigma_e2 = 1.0),
        true,
        "test",
        0,
    )
    ml_plot = variance_components_plot_data(ml_fit)
    @test ml_plot.interval_status == "none"
    @test all(isnan, ml_plot.lo)
    @test length(ml_plot.interval_reason) == 3
    @test all(startswith(reason, "argument_error: ") for reason in ml_plot.interval_reason)
    @test all(occursin("REML", reason) for reason in ml_plot.interval_reason)

    reml_spec = animal_model_spec(y, X, Z, Ainv; method = :REML)
    stalled = AnimalModelFit(
        reml_spec,
        sparse_reml_loglik(reml_spec, 1.0, 1.0),
        (sigma_a2 = 1.0, sigma_e2 = 1.0),
        false,
        "iteration_limit",
        1,
    )
    err = try
        variance_components_plot_data(stalled)
        nothing
    catch caught
        caught
    end
    @test err isa ArgumentError
    @test occursin("converged = true", sprint(showerror, err))
    @test occursin("iteration_limit", sprint(showerror, err))
end

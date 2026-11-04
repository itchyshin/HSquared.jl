using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "univariate uncertainty refuses non-converged fits (#437)" begin
    y = [1.0, 2.0, 4.0]
    X = ones(3, 1)
    Z = sparse(1.0I, 3, 3)
    Ainv = sparse(1.0I, 3, 3)
    spec = animal_model_spec(y, X, Z, Ainv; method = :REML)
    likelihood = sparse_reml_loglik(spec, 1.0, 1.0)
    fit = AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = 1.0, sigma_e2 = 1.0),
        false,
        "iteration_limit",
        1,
    )

    calls = (
        () -> variance_component_covariance(fit),
        () -> variance_component_standard_errors(fit),
        () -> heritability_standard_error(fit),
        () -> heritability_interval(fit),
        () -> heritability_interval(fit; method = :profile),
        () -> variance_component_interval(fit),
        () -> bootstrap_variance_component_interval(fit; n_boot = 1),
    )

    for call in calls
        err = try
            call()
            nothing
        catch caught
            caught
        end
        @test err isa ArgumentError
        message = sprint(showerror, err)
        @test occursin("converged = true", message)
        @test occursin("iteration_limit", message)
    end
end

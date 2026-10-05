# HSquared.jl #407 — point AI-REML q > 512 aborts at fit_sparse_reml.
# Standalone:
# julia --project=. -e 'include("test/test_issue_407_boundary_score_pointer.jl")'

using HSquared
using LinearAlgebra
using Logging
using SparseArrays
using Test

@testset "issue 407 boundary_score_unresolved points at fit_sparse_reml" begin
    help = read(joinpath(@__DIR__, "..", "src", "likelihood.jl"), String)
    @test occursin("_AI_REML_BOUNDARY_TRACE_MAX_COLUMNS", help)
    @test occursin("more than 512 animals", help)
    @test occursin("HSquared.jl #407", help)
    @test occursin("fit_sparse_reml", HSquared._BOUNDARY_SCORE_UNRESOLVED_MSG)
    @test occursin("512", HSquared._BOUNDARY_SCORE_UNRESOLVED_MSG)
    @test occursin("iterate at abort", HSquared._BOUNDARY_SCORE_UNRESOLVED_MSG)

    q = 513
    spec = animal_model_spec(
        sin.(collect(1:q)),
        ones(q, 1),
        sparse(1.0I, q, q),
        sparse(1.0I, q, q);
        method = :REML,
    )
    result = @test_logs(
        (:warn, r"not separately identifiable"),
        (:warn, r"fit_sparse_reml"),
        min_level = Logging.Warn,
        HSquared._fit_ai_reml_diagnostics(
            spec;
            initial = (sigma_a2 = 1e-16, sigma_e2 = 1.7),
            iterations = 1,
        ),
    )
    @test result.fit.optimizer_status == "boundary_score_unresolved"
    @test !result.fit.converged
    @test result.diagnostics.termination_reason == "boundary_score_unresolved"
end

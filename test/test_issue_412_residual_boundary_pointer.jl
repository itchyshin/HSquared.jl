# HSquared.jl #412 — point residual-boundary AI-REML failures at fit_sparse_reml.
# Standalone:
# julia --project=. -e 'include("test/test_issue_412_residual_boundary_pointer.jl")'

using HSquared
using LinearAlgebra
using Logging
using SparseArrays
using Test

function _mrode3_animal_spec()
    ids = string.(1:8)
    ped = normalize_pedigree(
        ids,
        ["0", "0", "0", "1", "3", "1", "4", "3"],
        ["0", "0", "0", "0", "2", "2", "5", "6"],
    )
    y = [4.5, 2.9, 3.9, 3.5, 5.0]
    sex = ["male", "female", "female", "male", "male"]
    X = hcat(ones(length(y)), [s == "female" ? 1.0 : 0.0 for s in sex])
    Z = spzeros(length(y), length(ids))
    for (i, animal) in enumerate(4:8)
        Z[i, animal] = 1.0
    end
    return animal_model_spec(y, X, Z, pedigree_inverse(ped); ids = ped.ids, method = :REML)
end

@testset "issue 412 residual-boundary AI-REML points at fit_sparse_reml" begin
    help = read(joinpath(@__DIR__, "..", "src", "likelihood.jl"), String)
    @test occursin("residual boundary", help)
    @test occursin("HSquared.jl #412", help)
    @test occursin("fit_sparse_reml", help)
    @test occursin("_RESIDUAL_BOUNDARY_UNRESOLVED_MSG", help)
    @test occursin("fit_sparse_reml", HSquared._RESIDUAL_BOUNDARY_UNRESOLVED_MSG)
    @test occursin("Ve -> 0", HSquared._RESIDUAL_BOUNDARY_UNRESOLVED_MSG)
    @test occursin("last iterate", HSquared._RESIDUAL_BOUNDARY_UNRESOLVED_MSG)
    @test HSquared._AI_REML_RESIDUAL_BOUNDARY_SHARE == 1e-6

    spec = _mrode3_animal_spec()
    result = @test_logs(
        (:warn, r"fit_sparse_reml"),
        min_level = Logging.Warn,
        HSquared._fit_ai_reml_diagnostics(
            spec;
            initial = (sigma_a2 = 0.6, sigma_e2 = 1e-4),
            iterations = 100,
        ),
    )
    fit = result.fit
    vc = fit.variance_components
    residual_share = vc.sigma_e2 / (vc.sigma_a2 + vc.sigma_e2)
    @test !fit.converged
    @test fit.optimizer_status == "not_converged"
    @test residual_share <= HSquared._AI_REML_RESIDUAL_BOUNDARY_SHARE

    sparse = fit_sparse_reml(spec)
    @test sparse.converged
    @test sparse.variance_components.sigma_e2 /
          (sparse.variance_components.sigma_a2 + sparse.variance_components.sigma_e2) <=
          HSquared._AI_REML_RESIDUAL_BOUNDARY_SHARE
    @test sparse.likelihood.loglik > fit.likelihood.loglik
end

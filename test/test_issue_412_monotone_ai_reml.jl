# HSquared.jl #412 - AI-REML must not lower the REML log-likelihood, and must not
# end at a start-dependent point, when the optimum is on the residual boundary.
# Standalone:
# julia --project=. -e 'include("test/test_issue_412_monotone_ai_reml.jl")'

using HSquared
using LinearAlgebra
using Base.CoreLogging: NullLogger, with_logger
using SparseArrays
using Test

function _mrode3_monotone_spec()
    ids = string.(1:8)
    ped = normalize_pedigree(
        ids,
        ["0", "0", "0", "1", "3", "1", "4", "3"],
        ["0", "0", "0", "0", "2", "2", "5", "6"],
    )
    y = [4.5, 2.9, 3.9, 3.5, 5.0]
    X = hcat(ones(5), [1.0, 0.0, 0.0, 1.0, 1.0])
    Z = spzeros(5, 8)
    for (i, animal) in enumerate(4:8)
        Z[i, animal] = 1.0
    end
    return animal_model_spec(y, X, Z, pedigree_inverse(ped); ids = ped.ids, method = :REML)
end

function _quiet_ai_fit(spec; kwargs...)
    return with_logger(NullLogger()) do
        HSquared._fit_ai_reml_diagnostics(spec; em_warmup = 0, kwargs...)
    end
end

@testset "issue 412 AI-REML REML objective is monotone on the residual boundary" begin
    spec = _mrode3_monotone_spec()
    reference = fit_sparse_reml(spec).likelihood.loglik
    starts = [(1.0, 1.0), (0.5, 0.5), (0.1, 5.0), (5.0, 0.1)]

    for (a0, e0) in starts
        initial = (sigma_a2 = a0, sigma_e2 = e0)
        # More iterations never give a lower log-likelihood.
        short = _quiet_ai_fit(spec; initial = initial, iterations = 100).fit
        long = _quiet_ai_fit(spec; initial = initial, iterations = 400).fit
        @test long.likelihood.loglik >= short.likelihood.loglik - 1e-9

        # The objective is non-decreasing along the whole path.
        path = [
            _quiet_ai_fit(spec; initial = initial, iterations = k).fit.likelihood.loglik
            for k in 1:25
        ]
        @test all(diff(path) .>= -1e-9)

        # The exit point is the boundary optimum, not a start-dependent iterate.
        vc = long.variance_components
        @test abs(long.likelihood.loglik - reference) < 1e-3
        @test isapprox(vc.sigma_a2, 0.676; atol = 0.01)
        @test vc.sigma_e2 / (vc.sigma_a2 + vc.sigma_e2) <= HSquared._AI_REML_RESIDUAL_BOUNDARY_SHARE
        # The Ve score never vanishes on the boundary, so the flag stays honest.
        @test !long.converged
    end

    # The boundary-face step was actually used on this problem.
    diag = _quiet_ai_fit(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0), iterations = 100).diagnostics
    @test diag.boundary_face_steps + diag.fallback_em_steps > 0
end

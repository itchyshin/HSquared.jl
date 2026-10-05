# HSquared.jl #441 — K-effect sparse AI-REML must not abort at the 512-column
# boundary-score budget. Standalone:
#   julia --project=. -e 'include("test/test_issue_441_keffect_boundary_cap.jl")'

using HSquared
using LinearAlgebra
using SparseArrays
using Test

function _issue441_over_budget_fixture()
    q = 257
    X = ones(q, 1)
    Z = sparse(1.0I, q, q)
    Q = sparse(1.0I, q, q)
    y = sin.(collect(1:q))
    initial = [1e-16, 1e-16, 1.7]
    return y, X, [(Z, Q), (Z, Q)], initial
end

@testset "K-effect AI-REML takes an EM step past the 512-column cap (#441)" begin
    y, X, effects, initial = _issue441_over_budget_fixture()
    ws = HSquared._multi_reml_workspace(y, X, effects)
    sigmas = initial[1:2]
    evar = initial[3]
    HSquared._assemble_lhs_rhs!(ws, sigmas, evar)
    factor = HSquared._factorize!(ws)
    solution = factor \ ws.rhs
    residual = y - ws.Xs * solution[1:ws.nfixed] - ws.Zf * solution[(ws.nfixed + 1):end]
    us = [solution[(ws.offsets[i] + 1):(ws.offsets[i] + ws.qs[i])] for i in 1:2]
    traces = HSquared.selinv_block_traces(factor, ws.Ainvs, ws.offsets)
    # Old behavior: combined triggered columns (257+257) refuse the streamed score.
    @test HSquared._multi_reml_scores(ws, factor, sigmas, evar, residual, traces, us) === nothing

    result = fit_sparse_multi_effect_aireml(
        y, X, effects; initial = initial, iterations = 1)
    # Old behavior aborted at the start and reported that iterate as a Bool
    # boundary verdict. The EM fallback must move the components instead.
    @test !result.converged
    @test result.status != "boundary_score_unresolved"
    @test result.variance_components.sigmas != initial[1:2]
    @test all(>(0), result.variance_components.sigmas)
    @test result.variance_components.sigma_e2 > 0
    @test isfinite(result.loglik)
    @test length(result.boundary) == 2
    if result.status == "boundary_score_unresolved"
        @test all(ismissing, result.boundary)
    else
        @test result.boundary isa AbstractVector{Bool}
    end
end

# HSquared.jl #427 — matrix-free MC-REML must not label a relative-change
# stop as AI-REML "converged", and cannot certify when trace_mcse is NaN.
# Standalone:
# julia --project=. -e 'include("test/test_issue_427_mc_reml_status.jl")'

using HSquared
using LinearAlgebra
using SparseArrays
using Test

function _issue427_pedigree()
    return normalize_pedigree(
        ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
    )
end

function _issue427_multi_effect()
    ped = _issue427_pedigree()
    n = 8
    X = ones(n, 1)
    Ainv = sparse(Matrix(pedigree_inverse(ped)))
    Z1 = sparse(1.0I, n, 8)
    ng = 3
    Z2 = spzeros(n, ng)
    for i in 1:n
        Z2[i, (i % ng) + 1] = 1.0
    end
    y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    return y, X, [(Z1, Ainv), (Z2, sparse(1.0I, ng, ng))]
end

function _issue427_animal_spec()
    ped = _issue427_pedigree()
    n = 8
    y = [2.0, 3.0, 2.5, 3.5, 4.0, 1.5, 3.0, 4.5]
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    Ainv = sparse(Matrix(pedigree_inverse(ped)))
    return animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
end

@testset "MC-REML relative-change stop is not labelled converged (#427)" begin
    y, X, effects = _issue427_multi_effect()

    @testset "one probe cannot certify a relative-change stop" begin
        one = fit_multi_effect_mc_reml(
            y, X, effects;
            nprobe = 1, iterations = 5, tol = 1e2, seed = 1,
        )
        @test all(isnan, one.trace_mcse)
        @test !one.converged
        @test one.optimizer_status == "not_converged"
        @test one.optimizer_status != "converged"
    end

    @testset "a certified stop uses fixed_point_relchange" begin
        mf = fit_multi_effect_mc_reml(
            y, X, effects;
            nprobe = 8, iterations = 5, tol = 1e2, seed = 1,
        )
        @test all(isfinite, mf.trace_mcse)
        @test mf.converged
        @test mf.optimizer_status == "fixed_point_relchange"
        @test mf.optimizer_status != "converged"

        routed = fit_multi_effect(
            y, X, effects;
            method = :matrix_free, nprobe = 8, iterations = 5, tol = 1e2,
            verbose = false, seed = 1,
        )
        @test routed.dispatch == :matrix_free
        @test routed.optimizer_status == "fixed_point_relchange"
    end

    @testset "AnimalModelFit wrapper keeps the same status string" begin
        spec = _issue427_animal_spec()
        am = fit_matrix_free_reml(
            spec;
            nprobe = 8, iterations = 5, tol = 1e2, seed = 1,
            compute_loglik = false,
        )
        @test am.converged
        @test am.optimizer_status == "fixed_point_relchange"
        @test am.optimizer_status != "converged"
    end
end

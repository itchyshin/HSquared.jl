# HSquared.jl #435 — fit_multi_effect must not silently drop matrix-free
# keywords on the :exact route. Standalone:
# julia --project=. -e 'include("test/test_fit_multi_effect_exact_unused_keywords.jl")'

using HSquared
using LinearAlgebra
using SparseArrays
using Test

function _exact_unused_fixture()
    ped = normalize_pedigree(
        ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"],
        ["0", "0", "a1", "a1", "a2", "a2", "a3", "a5"],
        ["0", "0", "a2", "a2", "0", "0", "a4", "a6"],
    )
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
    effects = [(Z1, Ainv), (Z2, sparse(1.0I, ng, ng))]
    return y, X, effects, 1 + 8 + ng
end

function _exact_unused_error(; kwargs...)
    y, X, effects, _ = _exact_unused_fixture()
    try
        fit_multi_effect(y, X, effects; kwargs...)
        return nothing
    catch e
        return e
    end
end

function _names_unused(err, keyword)
    msg = sprint(showerror, err)
    return err isa ArgumentError && occursin(string(keyword), msg)
end

@testset "fit_multi_effect exact unused keywords (HSquared.jl #435)" begin
    y, X, effects, N = _exact_unused_fixture()

    @testset "exact route errors and names the dropped keyword" begin
        for (keyword, value) in (
            :nprobe => 512,
            :shared_probes => true,
            :compute_loglik => true,
            :slq_probes => 8,
            :slq_steps => 10,
            :verbose => false,
        )
            err = _exact_unused_error(; method = :exact, keyword => value)
            @test _names_unused(err, keyword)
        end

        auto_exact = _exact_unused_error(; method = :auto, nprobe = 512)
        @test _names_unused(auto_exact, :nprobe)
    end

    @testset "exact route still fits when those keywords are omitted" begin
        ex = fit_multi_effect(y, X, effects; method = :exact)
        @test ex.dispatch == :exact
    end

    @testset "routes that honour the keywords still accept them" begin
        mf = fit_multi_effect(
            y, X, effects;
            method = :matrix_free, nprobe = 200, verbose = false,
        )
        @test mf.dispatch == :matrix_free

        auto_mf = fit_multi_effect(
            y, X, effects;
            method = :auto, direct_max_n = N - 1, nprobe = 200, verbose = false,
        )
        @test auto_mf.dispatch == :matrix_free
    end
end

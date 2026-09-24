# HSquared.jl #365 — dense vs sparse REML loglik convention metadata.
#
# Dense multi-effect / repeatability omit −½(n−p)log(2π); sparse Henderson
# paths include it. Absolute loglik differs by that constant; components agree
# when identified. This slice does NOT rewrite dense absolute values (optima
# unchanged; R still pins the offset). It makes the convention self-describing
# and provides `comparable_loglik` so AIC/LRT can be made safe.
#
# Fence: no covered flip; public_covered_count stays 7; version stays 0.9.0.

using Test
using LinearAlgebra
using SparseArrays
using HSquared

@testset "HSquared.jl #365 loglik convention metadata" begin
    Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
    Z = zeros(8, 4)
    for (rec, an) in enumerate([1, 1, 2, 2, 3, 3, 4, 4])
        Z[rec, an] = 1.0
    end
    y = [14.0, 13.0, 6.9, 6.1, 12.1, 11.5, 8.9, 8.5]
    X = ones(8, 1)
    n = length(y)
    p = size(X, 2)
    expected_offset = reml_full_constant_offset(n, p)
    @test expected_offset ≈ -0.5 * (n - p) * log(2π) atol = 0.0

    @testset "dense repeatability is omit-2π and converts to full" begin
        dense = fit_repeatability_reml(y, X, Z, Ainv)
        @test dense.loglik_convention === LOGLIK_CONVENTION_OMIT_2PI
        @test dense.loglik_comparable_across_routes === false
        @test dense.loglik_full_constant_offset ≈ expected_offset atol = 1e-14
        @test comparable_loglik(dense) ≈ dense.loglik + expected_offset atol = 1e-14
    end

    @testset "sparse multi-effect is full-constant (offset 0)" begin
        Zs = sparse(Z)
        Ais = sparse(Matrix{Float64}(Ainv))
        Ipe = sparse(Matrix{Float64}(I, 4, 4))
        sparse_fit = fit_sparse_multi_effect_aireml(y, X, [(Zs, Ais), (Zs, Ipe)])
        @test sparse_fit.loglik_convention === LOGLIK_CONVENTION_FULL
        @test sparse_fit.loglik_comparable_across_routes === true
        @test sparse_fit.loglik_full_constant_offset == 0.0
        @test comparable_loglik(sparse_fit) ≈ sparse_fit.loglik atol = 0.0
    end

    @testset "same-θ dense↔sparse gap is exactly the REML constant" begin
        # Exact objective identity (no optimizer): sparse full-constant == dense omit
        # plus −½(n−p)log(2π). Same pin as the sparse AI-REML block in runtests.jl.
        A = inv(Symmetric(Matrix{Float64}(Ainv)))
        I4 = Matrix{Float64}(I, 4, 4)
        ZAs = [(Z, A), (Z, I4)]
        Zs = sparse(Z)
        Ais = sparse(Matrix{Float64}(Ainv))
        Ipe = sparse(I4)
        eff = [(Zs, Ais), (Zs, Ipe)]
        for θ in ([0.7, 0.3, 1.3], [2.0, 1.0, 3.0], [0.1, 0.9, 0.4])
            de = HSquared._multi_effect_dense(y, X, ZAs, θ[1:2], θ[3])[1]
            sp = sparse_multi_reml_loglik(y, X, eff, θ[1:2], θ[3])[1]
            @test sp ≈ de + expected_offset atol = 1e-8
            # comparable_loglik on a synthetic omit-2π fit recovers sparse.
            syn = merge((loglik = de,), HSquared.loglik_convention_fields(LOGLIK_CONVENTION_OMIT_2PI, n, p))
            @test comparable_loglik(syn) ≈ sp atol = 1e-8
        end
    end

    @testset "fitted dense multi-effect comparable_loglik matches sparse at dense θ" begin
        # Avoid PE-boundary tiny fixtures: compare at the dense fit's own θ.
        A = inv(Symmetric(Matrix{Float64}(Ainv)))
        I4 = Matrix{Float64}(I, 4, 4)
        me = fit_multi_effect_reml(y, X, [(Z, Matrix(Ainv)), (Z, I4)])
        @test me.loglik_convention === LOGLIK_CONVENTION_OMIT_2PI
        @test me.loglik_comparable_across_routes === false
        θ = vcat(me.variance_components.sigmas, me.variance_components.sigma_e2)
        Zs = sparse(Z)
        Ais = sparse(Matrix{Float64}(Ainv))
        Ipe = sparse(I4)
        sp = sparse_multi_reml_loglik(y, X, [(Zs, Ais), (Zs, Ipe)], θ[1:2], θ[3])[1]
        @test comparable_loglik(me) ≈ sp atol = 1e-6
    end

    @testset "dense multi-effect / two-effect carry omit-2π metadata" begin
        te = fit_two_effect_reml(y, X, Z, Ainv, Z, Matrix{Float64}(I, 4, 4))
        @test te.loglik_convention === LOGLIK_CONVENTION_OMIT_2PI
        @test comparable_loglik(te) ≈ te.loglik + expected_offset atol = 1e-14
    end

    @testset "comparable_loglik refuses fits without convention metadata" begin
        @test_throws ArgumentError comparable_loglik((loglik = -1.0,))
    end
end

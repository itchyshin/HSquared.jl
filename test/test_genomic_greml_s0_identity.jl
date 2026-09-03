# test_genomic_greml_s0_identity.jl — 0.7-S0 N1/N2/N3 identity scaffolding
#
# design-51 obligations. NOT a covered flip. Count stays 6.
# Marker↔supplied-Q route identity remains the primary pin in runtests.jl
# (genomic_public_activation_target). This file adds S0-named obligations.

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

@testset "0.7-S0 genomic GREML identity scaffolding (not a covered flip)" begin
    rng = MersenneTwister(20260902)
    n, m = 16, 48
    markers = rand(rng, 0:2, n, m) .* 1.0
    ids = ["g$i" for i in 1:n]
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    G = genomic_relationship_matrix(markers)
    y = cholesky(Symmetric(Matrix(G) .+ 1e-8 .* I(n))).L * randn(rng, n) .+ 0.7 .* randn(rng, n)

    @testset "N1 naming: SNP-BLUP σ²_g = σ̂_marker · k; supplied-var GBLUP≡SNP GEBV" begin
        snp = fit_snp_blup_reml(y, X, markers; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
        @test snp.converged
        @test snp.k > 0
        # Naming contract: total genomic VC is σ̂_marker · k (design-51 N1).
        sigma_marker = snp.sigma_g2 / snp.k
        @test snp.sigma_g2 ≈ sigma_marker * snp.k atol = 0
        # Unregularized GBLUP↔SNP-BLUP GEBV identity (same σ²_g). VanRaden G is
        # rank-deficient — route GBLUP through the marginal V, never invert at
        # ridge=0 (runtests.jl Phase 2 pin). Ridge K_lambda breaks this identity
        # (design-44 fence; not asserted here).
        Gmat = genomic_relationship_matrix(markers)
        V = snp.sigma_g2 .* Matrix(Gmat) + snp.sigma_e2 * I
        beta = (transpose(X) * (V \ X)) \ (transpose(X) * (V \ y))
        u_gblup = snp.sigma_g2 .* Matrix(Gmat) * (V \ (y .- X * beta))
        snp_sup = fit_snp_blup(y, X, markers, snp.sigma_g2, snp.sigma_e2; ids = string.("m", 1:m))
        @test maximum(abs.(u_gblup .- snp_sup.gebv)) <= 1e-8
    end

    @testset "N2 numeric ratio on K_lambda is genomic-scale (label owed on R)" begin
        Q = genomic_relationship_inverse(G; ridge = 0.01)
        fit = fit_gblup_reml(y, X, Z, Q; ids = ids)
        @test fit.converged
        r = heritability(fit)
        @test 0 < r < 1
        # Engine heritability(::AnimalModelFit) is a bare Float64 ratio. Public label
        # `genomic_variance_ratio` is an R-surface obligation (design-51 N2).
        @test r isa Real
        vc = fit.variance_components
        @test r ≈ vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2) atol = 0
    end

    @testset "N3 ridge freeze default 0.01 on activation construction" begin
        construction = HSquared._genomic_activation_construction(markers, ids)
        @test construction.provenance.ridge == 0.01
        @test construction.provenance.relationship_scale == "K_lambda"
        Q_expect = genomic_relationship_inverse(G; ridge = 0.01)
        @test Matrix(construction.Q) ≈ Matrix(Q_expect) atol = 1e-10
    end

    @testset "marker route vs supplied-Q identity (reuse activation constructors)" begin
        construction = HSquared._genomic_activation_construction(markers, ids)
        supplied_Q = genomic_relationship_inverse(G; ridge = 0.01)
        marker_fit = fit_gblup_reml(y, X, Z, construction.Q; ids = ids)
        supplied_fit = fit_gblup_reml(y, X, Z, supplied_Q; ids = ids)
        @test marker_fit.converged && supplied_fit.converged
        @test marker_fit.variance_components.sigma_a2 ≈
              supplied_fit.variance_components.sigma_a2 atol = 1e-10
        @test marker_fit.variance_components.sigma_e2 ≈
              supplied_fit.variance_components.sigma_e2 atol = 1e-10
        @test heritability(marker_fit) ≈ heritability(supplied_fit) atol = 1e-10
    end
end

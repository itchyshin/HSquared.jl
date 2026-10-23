# test_genomic_greml_s0_identity.jl — 0.7-S0 N1/N2/N3 identity scaffolding
#
# design-51 obligations. NOT a covered flip. Count stays 6.
# RNG-free: Julia randn is not version-stable (Julia 1.12 CI vs 1.10). Do not
# gate these identities on tiny-draw REML convergence.

using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "0.7-S0 genomic GREML identity scaffolding (not a covered flip)" begin
    n, m = 8, 24
    markers = Float64[mod(i + 2j, 3) for i in 1:n, j in 1:m]
    ids = ["g$i" for i in 1:n]
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    G = genomic_relationship_matrix(markers)
    y = 1.0 .+ Matrix(G) * ones(n)
    sigma_g2, sigma_e2 = 0.6, 0.4

    @testset "N1 naming: SNP-BLUP σ²_g is genomic VC; GBLUP≡SNP via marginal V" begin
        cm = centered_markers(markers)
        @test cm.k > 0
        # Naming contract: SNP-BLUP MME uses marker prior σ²_g / k (design-51 N1).
        snp_sup = fit_snp_blup(y, X, markers, sigma_g2, sigma_e2; ids = string.("m", 1:m))
        @test snp_sup.k ≈ cm.k atol = 1e-12
        @test sigma_g2 ≈ (sigma_g2 / snp_sup.k) * snp_sup.k atol = 0
        # Unregularized GBLUP↔SNP-BLUP GEBV identity. VanRaden G is rank-deficient —
        # route GBLUP through the marginal V, never invert at ridge=0.
        Gmat = Matrix(G)
        V = sigma_g2 .* Gmat + sigma_e2 * I
        beta = (transpose(X) * (V \ X)) \ (transpose(X) * (V \ y))
        u_gblup = sigma_g2 .* Gmat * (V \ (y .- X * beta))
        @test maximum(abs.(u_gblup .- snp_sup.gebv)) <= 1e-8
    end

    @testset "N2 numeric ratio on K_lambda is genomic-scale (label owed on R)" begin
        Q = genomic_relationship_inverse(G; ridge = 0.01)
        fit = fit_gblup(y, X, Z, Q, sigma_g2, sigma_e2; ids = ids)
        r = heritability(fit)
        @test 0 < r < 1
        @test r isa Real
        @test r ≈ sigma_g2 / (sigma_g2 + sigma_e2) atol = 1e-12
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
        @test Matrix(construction.Q) ≈ Matrix(supplied_Q) atol = 1e-10
        marker_fit = fit_gblup(y, X, Z, construction.Q, sigma_g2, sigma_e2; ids = ids)
        supplied_fit = fit_gblup(y, X, Z, supplied_Q, sigma_g2, sigma_e2; ids = ids)
        @test heritability(marker_fit) ≈ heritability(supplied_fit) atol = 1e-12
        @test maximum(abs.(breeding_values(marker_fit).values .-
                           breeding_values(supplied_fit).values)) <= 1e-10
    end
end

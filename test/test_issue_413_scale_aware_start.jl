# HSquared.jl #413 — the two-effect and repeatability dense fitters default to a
# scale-aware start (set from var(y)), so the REML optimum no longer depends on the
# unit of the response. Standalone:
# julia --project=. -e 'include("test/test_issue_413_scale_aware_start.jl")'

using HSquared
using LinearAlgebra
using Random
using Statistics: var
using Test

@testset "issue 413 scale-aware default start" begin
    rng = MersenneTwister(20261025)
    nsire, ndam, noff = 6, 12, 90
    ids = collect(1:(nsire + ndam + noff))
    sire = zeros(Int, length(ids))
    dam = zeros(Int, length(ids))
    for k in 1:noff
        sire[nsire + ndam + k] = rand(rng, 1:nsire)
        dam[nsire + ndam + k] = nsire + rand(rng, 1:ndam)
    end
    Ainv = pedigree_inverse(ids, sire, dam)
    q = length(ids)
    # two records per offspring; common environment = 15 groups unrelated to pedigree
    rec_animal = repeat((nsire + ndam + 1):q, inner = 2)
    n = length(rec_animal)
    Z = zeros(n, q)
    for (r, a) in enumerate(rec_animal)
        Z[r, a] = 1.0
    end
    ngrp = 15
    Zc = zeros(n, ngrp)
    for r in 1:n
        Zc[r, rand(rng, 1:ngrp)] = 1.0
    end
    X = ones(n, 1)
    Lc = cholesky(Symmetric(Matrix(inv(Symmetric(Matrix(Ainv)))))).L
    u = Lc * randn(rng, q) .* sqrt(1.0)
    y = 10 .+ Z * u .+ Zc * (randn(rng, ngrp) .* sqrt(0.7)) .+ randn(rng, n) .* sqrt(1.5)
    Ic = Matrix(1.0I, ngrp, ngrp)
    Ip = Matrix(1.0I, q, q)
    c = 1000.0
    ybig = y .* c

    @testset "start helper" begin
        s = HSquared._scale_aware_start(ybig, 2)
        v = var(ybig)
        @test s ≈ [0.25v, 0.25v, 0.5v]
        @test HSquared._scale_aware_start(fill(3.0, 5), 2) == [1.0, 1.0, 1.0]
        @test HSquared._scale_aware_start([2.0], 2) == [1.0, 1.0, 1.0]
    end

    @testset "two-effect optimum is scale-equivariant by default" begin
        small = fit_two_effect_reml(y, X, Z, Ainv, Zc, Ic)
        big = @test_logs min_level = Base.CoreLogging.Warn fit_two_effect_reml(ybig, X, Z, Ainv, Zc, Ic)
        vs = collect(values(small.variance_components))
        vb = collect(values(big.variance_components))
        @test small.converged
        @test big.converged
        @test isapprox(vb, vs .* c^2; rtol = 1e-3)
        @test isapprox(big.ratio1, small.ratio1; atol = 1e-4)
        # the failure of #413: not the near-zero-h2 point
        @test big.ratio1 > 0.01
        @test big.variance_components.sigma_e2 < 3.0 * var(ybig)
        # explicit initial is still honoured
        same = fit_two_effect_reml(y, X, Z, Ainv, Zc, Ic;
            initial = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = 1.0))
        @test same.loglik ≈ small.loglik atol = 1e-4
    end

    @testset "repeatability optimum is scale-equivariant by default" begin
        small = fit_repeatability_reml(y, X, Z, Ainv)
        big = @test_logs min_level = Base.CoreLogging.Warn fit_repeatability_reml(ybig, X, Z, Ainv)
        vs = collect(values(small.variance_components))
        vb = collect(values(big.variance_components))
        @test isapprox(vb, vs .* c^2; rtol = 1e-3)
        @test isapprox(big.heritability, small.heritability; atol = 1e-4)
        @test big.repeatability > 0.05
    end

    @testset "interval wrappers take the same default" begin
        ri = repeatability_interval(ybig, X, Z, Ainv)
        rs = repeatability_interval(y, X, Z, Ainv)
        @test isapprox(ri.repeatability, rs.repeatability; atol = 1e-4)
    end
end

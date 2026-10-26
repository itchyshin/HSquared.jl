# HSquared.jl #411 -- the dense *_interval functions must not be forced to refit,
# and repeatability_interval must honour max_dense_cells.
# Standalone: julia --project=. test/test_issue_411_interval_from_fit.jl

using HSquared
using LinearAlgebra
using Random
using SparseArrays
using Test

function _issue411_repeatability_fixture()
    # MersenneTwister streams differ between Julia 1.10 and 1.12+, so this seed is
    # chosen to give an interior, converged REML fit on both (seed 20260618 hit the
    # sigma_pe2 boundary and did not converge on 1.12+, giving a NaN interval).
    rng = MersenneTwister(20260623)
    nsire, ndam, noff, reps = 8, 16, 40, 3
    sids = ["s$i" for i in 1:nsire]; dids = ["d$i" for i in 1:ndam]; oids = ["o$i" for i in 1:noff]
    ids = vcat(sids, dids, oids)
    sire = vcat(fill("0", nsire + ndam), [sids[((i - 1) % nsire) + 1] for i in 1:noff])
    dam = vcat(fill("0", nsire + ndam), [dids[((i - 1) % ndam) + 1] for i in 1:noff])
    ped = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv)))); q = length(ped.ids)
    a = cholesky(Symmetric(A)).L * randn(rng, q)
    pe = randn(rng, q) .* sqrt(0.6)
    n = q * reps; X = ones(n, 1); Z = zeros(n, q); y = zeros(n)
    for an in 1:q, k in 1:reps
        row = (an - 1) * reps + k
        Z[row, an] = 1.0
        y[row] = 5.0 + a[an] + pe[an] + sqrt(1.4) * randn(rng)
    end
    return y, X, Z, Ainv
end

function _issue411_two_effect_fixture()
    rng = MersenneTwister(20260701)
    sires = 8; q = 60
    sire = zeros(Int, sires + q)
    for i in 1:q; sire[sires + i] = rand(rng, 1:sires); end
    Ainv = pedigree_inverse(collect(1:(sires + q)), sire, zeros(Int, sires + q))
    A = inv(Symmetric(Matrix(Ainv))); na = size(Ainv, 1)
    g = cholesky(Symmetric(A + 1e-8I)).L * randn(rng, na)
    ngrp = 12; grp_eff = randn(rng, ngrp) .* sqrt(0.5)
    n = q; X = ones(n, 1)
    Z1 = zeros(n, na); Z2 = zeros(n, ngrp); y = zeros(n)
    for (r, an) in enumerate((sires + 1):(sires + q))
        Z1[r, an] = 1.0; gg = rand(rng, 1:ngrp); Z2[r, gg] = 1.0
        y[r] = 3.0 + g[an] + grp_eff[gg] + randn(rng)
    end
    return y, X, sparse(Z1), Ainv, sparse(Z2), sparse(Matrix(1.0I, ngrp, ngrp))
end

@testset "repeatability_interval: max_dense_cells and no-refit method (#411)" begin
    y, X, Z, Ainv = _issue411_repeatability_fixture()
    cells = length(y)^2 + size(Ainv, 1)^2

    # The cap is forwarded to the fit, so a cap below the model size is refused with
    # the named guard, and a cap at the model size is honoured.
    @test_throws ArgumentError repeatability_interval(y, X, Z, Ainv; max_dense_cells = cells - 1)
    ci = repeatability_interval(y, X, Z, Ainv; max_dense_cells = cells)
    @test isfinite(ci.repeatability)

    fit = fit_repeatability_reml(y, X, Z, Ainv; max_dense_cells = cells)

    # Fit-taking method reproduces the refitting method exactly (same fit, same FD).
    ci_fit = repeatability_interval(fit, y, X, Z, Ainv; max_dense_cells = cells)
    @test ci_fit == ci
    @test ci_fit.boundary === false
    @test 0 < ci_fit.lower < ci_fit.repeatability < ci_fit.upper < 1

    # It does not refit: a fit with other components is evaluated at those components.
    vc = fit.variance_components
    moved = merge(fit, (variance_components =
        (sigma_a2 = 1.1 * vc.sigma_a2, sigma_pe2 = vc.sigma_pe2, sigma_e2 = vc.sigma_e2),))
    ci_moved = repeatability_interval(moved, y, X, Z, Ainv; max_dense_cells = cells)
    total = 1.1 * vc.sigma_a2 + vc.sigma_pe2 + vc.sigma_e2
    @test ci_moved.repeatability ≈ (1.1 * vc.sigma_a2 + vc.sigma_pe2) / total
    @test ci_moved.repeatability != ci.repeatability

    # Guards: size cap and level are checked on the fit-taking method too.
    @test_throws ArgumentError repeatability_interval(fit, y, X, Z, Ainv; max_dense_cells = cells - 1)
    @test_throws ArgumentError repeatability_interval(fit, y, X, Z, Ainv; level = 1.5)
end

@testset "two_effect_ratio_interval: no-refit method (#411)" begin
    y, X, Z1, Ainv1, Z2, Ainv2 = _issue411_two_effect_fixture()
    ci = two_effect_ratio_interval(y, X, Z1, Ainv1, Z2, Ainv2)
    fit = fit_two_effect_reml(y, X, Z1, Ainv1, Z2, Ainv2)

    ci_fit = two_effect_ratio_interval(fit, y, X, Z1, Ainv1, Z2, Ainv2)
    @test ci_fit == ci
    @test ci_fit.converged === fit.converged
    @test 0 < ci_fit.ratio1.lower < ci_fit.ratio1.estimate < ci_fit.ratio1.upper < 1

    # which = and level are honoured without a refit
    c1 = two_effect_ratio_interval(fit, y, X, Z1, Ainv1, Z2, Ainv2; which = :ratio1)
    @test c1.ratio1 == ci.ratio1
    @test isnan(c1.ratio2.lower) && c1.ratio2.estimate == fit.ratio2
    c90 = two_effect_ratio_interval(fit, y, X, Z1, Ainv1, Z2, Ainv2; level = 0.90)
    @test (c90.ratio1.upper - c90.ratio1.lower) < (ci.ratio1.upper - ci.ratio1.lower)

    # It does not refit: a fit with other components is evaluated at those components.
    vc = fit.variance_components
    s1 = 1.1 * vc.sigma1
    tot = s1 + vc.sigma2 + vc.sigma_e2
    moved = merge(fit, (variance_components = (sigma1 = s1, sigma2 = vc.sigma2, sigma_e2 = vc.sigma_e2),
                        ratio1 = s1 / tot, ratio2 = vc.sigma2 / tot))
    cm = two_effect_ratio_interval(moved, y, X, Z1, Ainv1, Z2, Ainv2)
    @test cm.ratio1.estimate ≈ s1 / tot
    @test cm.ratio1.estimate != ci.ratio1.estimate

    @test_throws ArgumentError two_effect_ratio_interval(fit, y, X, Z1, Ainv1, Z2, Ainv2; level = 1.5)
    @test_throws ArgumentError two_effect_ratio_interval(fit, y, X, Z1, Ainv1, Z2, Ainv2; which = :bogus)
end

@testset "direct_maternal_interval: no-refit method (#411)" begin
    ids = String[]; sire = String[]; dam = String[]
    addp!(i, s, d) = (push!(ids, i); push!(sire, s); push!(dam, d))
    fd = ["fd$i" for i in 1:10]; fs = ["fs$i" for i in 1:5]
    for d in fd; addp!(d, "0", "0"); end
    for s in fs; addp!(s, "0", "0"); end
    g1 = String[]; k = 0
    for d in fd, _ in 1:6
        k += 1; o = "g1_$k"; addp!(o, fs[(k % 5) + 1], d); push!(g1, o)
    end
    g1dams = g1[1:15]; g1sires = g1[16:30]
    g2 = String[]; k = 0
    for d in g1dams, _ in 1:6
        k += 1; o = "g2_$k"; addp!(o, g1sires[(k % length(g1sires)) + 1], d); push!(g2, o)
    end
    P = normalize_pedigree(ids, sire, dam)
    Ainv = pedigree_inverse(P)
    q = size(Ainv, 1)
    pos = Dict(id => i for (i, id) in enumerate(P.ids))
    dam_of = Dict(ids[i] => dam[i] for i in eachindex(ids))
    recorded = vcat(g1, g2); n = length(recorded)
    Zd = zeros(n, q); Zm = zeros(n, q)
    for (r, o) in enumerate(recorded)
        Zd[r, pos[o]] = 1.0; Zm[r, pos[dam_of[o]]] = 1.0
    end
    rng = MersenneTwister(20264106)
    A = inv(Symmetric(Matrix(Ainv)))
    LA = cholesky(Symmetric(A + 1e-10I)).L
    LG = cholesky(Symmetric([1.0 -0.25; -0.25 0.6])).L
    U = LA * randn(rng, q, 2) * transpose(LG)
    X = ones(n, 1)
    y = 5.0 .+ [U[pos[o], 1] for o in recorded] .+ [U[pos[dam_of[o]], 2] for o in recorded] .+ randn(rng, n)

    ci = direct_maternal_interval(y, X, Zd, Zm, Ainv)
    fit = fit_direct_maternal_reml(y, X, Zd, Zm, Ainv)
    ci_fit = direct_maternal_interval(fit, y, X, Zd, Zm, Ainv)
    @test ci_fit == ci
    @test ci_fit.information_posdef

    # It does not refit: a fit with other components is evaluated at those components.
    vc = fit.variance_components
    G = [1.05 * vc.sigma_ad vc.sigma_dm; vc.sigma_dm vc.sigma_am]
    moved = merge(fit, (variance_components = merge(vc, (G_dm = G, sigma_ad = G[1, 1])),
                        genetic_correlation = G[1, 2] / sqrt(G[1, 1] * G[2, 2])))
    cm = direct_maternal_interval(moved, y, X, Zd, Zm, Ainv)
    @test cm.variance_components.sigma_ad.estimate ≈ 1.05 * vc.sigma_ad
    @test cm.variance_components.sigma_ad.estimate != ci.variance_components.sigma_ad.estimate

    @test_throws ArgumentError direct_maternal_interval(fit, y, X, Zd, Zm, Ainv; level = 1.0)
    @test_throws ArgumentError direct_maternal_interval(fit, y, X, Zd, Zm, Ainv; max_dense_cells = n * n - 1)
end

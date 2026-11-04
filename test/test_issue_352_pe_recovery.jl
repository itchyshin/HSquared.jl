# HSquared.jl #352 -- known-truth recovery of VA and VPE for animal + permanent
# environment (repeated records per animal), univariate Julia path.
#
# test_issue_352_pe_dispatch_docs.jl locks the documented 1 / 2 / 3+ dispatch and
# test_multivariate_repeatability.jl pins the multivariate fit; nothing else
# asserted that the univariate dense routes recover the two components, or that an
# animal-only fit on the same data inflates VA (the symptom in the issue).
#
# Data: test/fixtures/issue_352_pe_recovery (written by generate.jl on Julia 1.10;
# randn streams differ across Julia versions, so the CSVs are the pin).
# Truth: Va = 1.0, Vpe = 0.6, Ve = 0.8. 100 founders + 200 offspring with random
# sires and dams, 3 records per animal (900 rows). Breeding values are gene-dropped
# (drawing them i.i.d. would make A = I and the two effects non-identifiable).
#
# Tolerance (stated, generous): one fixed draw with 300 animals has a REML standard
# error of about 0.28 for Va and 0.17 for Vpe (multi_effect_variance_component_
# standard_errors on this fixture). Va and Vpe must land within 0.5 of truth
# (about 1.8 and 3 SE), sigma_e2 within 0.15. This is a recovery smoke gate on one
# deterministic draw, not a coverage or bias claim.
# Standalone: julia --project=. test/test_issue_352_pe_recovery.jl

using DelimitedFiles: readdlm
using HSquared
using LinearAlgebra
using Test

const _I352_DIR = joinpath(@__DIR__, "fixtures", "issue_352_pe_recovery")

function _issue352_fixture()
    ped = readdlm(joinpath(_I352_DIR, "pedigree.csv"), ',', Int; skipstart = 1)
    yd = readdlm(joinpath(_I352_DIR, "y.csv"), ',', Any; skipstart = 1)
    rec = Int.(yd[:, 1])
    y = Float64.(yd[:, 2])
    size(ped) == (300, 3) || error("issue 352 pedigree fixture must be 300x3, got $(size(ped))")
    length(y) == 900 || error("issue 352 y fixture must have 900 rows, got $(length(y))")
    isapprox(sum(y), 1749.3545551305; atol = 1e-6) ||
        error("issue 352 y fixture checksum mismatch: $(sum(y))")
    Ainv = pedigree_inverse(ped[:, 1], ped[:, 2], ped[:, 3])
    q = size(ped, 1)
    Z = zeros(length(y), q)
    for (r, a) in enumerate(rec)
        Z[r, a] = 1.0
    end
    return y, ones(length(y), 1), Z, Ainv, q
end

@testset "issue 352: animal + permanent environment known-truth recovery" begin
    Va, Vpe, Ve = 1.0, 0.6, 0.8
    y, X, Z, Ainv, q = _issue352_fixture()
    tol_component = 0.5
    tol_resid = 0.15

    # The pedigree is not degenerate: A differs from I, so PE is separable from VA.
    @test norm(Matrix(Ainv) - I) > 1.0

    rep = fit_repeatability_reml(y, X, Z, Ainv)
    @test rep.converged
    vr = rep.variance_components
    @test isapprox(vr.sigma_a2, Va; atol = tol_component)
    @test isapprox(vr.sigma_pe2, Vpe; atol = tol_component)
    @test isapprox(vr.sigma_e2, Ve; atol = tol_resid)
    @test vr.sigma_a2 > 0.1 && vr.sigma_pe2 > 0.1   # neither collapsed to the boundary

    Ipe = Matrix{Float64}(I, q, q)
    multi = fit_multi_effect_reml(y, X, [(Z, Ainv), (Z, Ipe)])
    @test multi.converged
    vm = multi.variance_components
    @test isapprox(vm.sigmas[1], Va; atol = tol_component)
    @test isapprox(vm.sigmas[2], Vpe; atol = tol_component)
    @test isapprox(vm.sigma_e2, Ve; atol = tol_resid)

    # The two routes fit the same model and must agree.
    @test isapprox(vm.sigmas[1], vr.sigma_a2; rtol = 1e-3)
    @test isapprox(vm.sigmas[2], vr.sigma_pe2; rtol = 1e-3)
    @test isapprox(vm.sigma_e2, vr.sigma_e2; rtol = 1e-3)
    @test isapprox(multi.loglik, rep.loglik; atol = 1e-4)

    # Animal-only fit on the same repeated records: the permanent-environment
    # variance is not absorbed by the residual, it is pushed into VA, so VA
    # estimates about VA + VPE (the inflation described in the issue).
    only = fit_multi_effect_reml(y, X, [(Z, Ainv)])
    @test only.converged
    va_only = only.variance_components.sigmas[1]
    @test isapprox(va_only, Va + Vpe; rtol = 0.35)
    @test isapprox(va_only, vr.sigma_a2 + vr.sigma_pe2; rtol = 0.3)
    @test va_only > vr.sigma_a2 + 0.3                 # clearly inflated vs the separated VA
    @test va_only > Va + 0.3                          # and vs the true VA
    @test only.ratios[1] > rep.heritability + 0.05    # h2 is overstated too
end

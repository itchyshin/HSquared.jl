# test_matfree_reml_inci_pins.jl — V1-MATFREE-REML in-CI STRUCTURAL / NUMERIC pins
#
# Ports the v0.7 in-CI deterministic NUMERIC gates that `f261165e` left behind
# when it copied the fitter body onto this `main`-based campaign. The fence
# itself is already pinned in `test/runtests.jl` (`V1-MATFREE-REML opt-in fence`,
# JL-8 recursive src/ scan at `c0f53e0d`). This file pins the FITTER PATH:
# result tags, the exact-loglik identity, seed determinism / sensitivity,
# extractors, the `compute_loglik = false` NaN skip, and the REML-only guard.
#
# HONESTY — what this is not:
#   - NOT a covered flip. `V1-MATFREE-REML` stays `partial` / experimental.
#   - NOT a recovery-to-truth gate. That lives in the frozen S5 driver
#     (`sim/phase_s5_matfree_tail_recovery_gate.jl`, q = 25,000, opt-in).
#   - NOT a port of v0.7 items (h) and (i): those assert
#     `fit_animal_model(spec; target = :matrix_free)` and `_auto_reml_route`,
#     which this branch refuses / does not have. Copying them would require
#     widening the surface the fence exists to keep closed.
#   - NO stored numeric recovery value, NO `randn` fixture. The 2026-08-04
#     RNG-fragility class fix stays learned.
#
# Provenance: v0.7 testset
#   `fit_matrix_free_reml (F6 matrix-free MC EM-REML) recovers the AI-REML optimum`
# on `codex/2026-07-13-v07-performance-localization` / PR #274 (read-only). The
# fixture recipe is the same class (deterministic half-sib + `detnoise`); the
# size is CI-budgeted. Identity pins do not need the n=400 / nprobe=256
# recovery-scale fixture that now lives in `sim/f6_matfree_recovery.jl` on v0.7.
#
# `public_covered_count` stays 5.

using HSquared
using LinearAlgebra
using SparseArrays
using Test

@testset "V1-MATFREE-REML in-CI pins (fitter path exists; not a covered flip)" begin
    function _halfsib(q)
        nsire = max(2, round(Int, 0.04q))
        ndam = max(2, round(Int, 0.08q))
        noff = q - nsire - ndam
        sids = ["s$i" for i in 1:nsire]
        dids = ["d$i" for i in 1:ndam]
        oids = ["o$i" for i in 1:noff]
        normalize_pedigree(
            vcat(sids, dids, oids),
            vcat(fill("0", nsire + ndam), [sids[((i - 1) % nsire) + 1] for i in 1:noff]),
            vcat(fill("0", nsire + ndam), [dids[((i - 1) % ndam) + 1] for i in 1:noff]),
        )
    end
    detnoise(i; f1 = 0.7123, f2 = 1.9787, f3 = 3.3105) =
        sin(f1 * i) + 0.6 * cos(f2 * i) - 0.3 * sin(f3 * i)

    n = 80
    ped = _halfsib(n)
    Ainv = pedigree_inverse(ped)
    na = length(ped.ids)
    u = zeros(na)
    for i in 1:na
        s = ped.sire[i]
        d = ped.dam[i]
        pa = s > 0 ? u[s] : 0.0
        pb = d > 0 ? u[d] : 0.0
        nk = (s > 0) + (d > 0)
        msv = nk == 0 ? 1.0 : (nk == 1 ? 0.75 : 0.5)
        u[i] = 0.5 * (pa + pb) + sqrt(0.4 * msv) * detnoise(i)
    end
    y = 10.0 .+ u .+ sqrt(0.6) .* detnoise.((1:na) .+ 10_000; f1 = 1.317, f2 = 0.531, f3 = 2.71)
    X = ones(n, 1)
    Z = sparse(1.0I, n, n)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)

    mf = fit_matrix_free_reml(spec; nprobe = 32, seed = 20260728)

    # (a) result-shape / tag identity — the path exists and self-labels.
    #     No numeric-recovery claim (S5 owns that, off CI).
    @test mf.target === :matrix_free_reml
    @test mf.variance_components_source === :estimated_matrix_free_mc_reml
    @test mf.sparse_mme_path
    @test !mf.dense_validation_path
    @test mf.variance_components.sigma_a2 > 0
    @test mf.variance_components.sigma_e2 > 0

    # (b) the returned loglik is the EXACT sparse REML loglik at those VCs
    #     (one factorization after the fit; not a stochastic loglik).
    direct_ll = sparse_reml_loglik(
        spec,
        mf.variance_components.sigma_a2,
        mf.variance_components.sigma_e2,
    )
    @test mf.likelihood.loglik ≈ direct_ll.loglik rtol = 1e-12
    @test isfinite(mf.likelihood.loglik)

    # (c) deterministic given the seed; a DIFFERENT seed moves the estimate
    #     (it really is Monte-Carlo). Same-process comparison: no stored
    #     expected numeric. The *stream* is still version-sensitive: some
    #     Hutchinson draws drive this CI-budgeted fixture into a PCG/PosDef
    #     breakdown (2026-08-04 RNG-fragility class). seed=99 is a 1.12
    #     landmine here (CI 1.12.7: ArgumentError pᵀCp=0; local 1.12.6:
    #     PosDefException) while completing on 1.10. seed=7 completed and
    #     moved σ²a on local 1.10.12 and 1.12.6; do not restore 99.
    @test fit_matrix_free_reml(spec; nprobe = 32, seed = 20260728).variance_components ==
          mf.variance_components
    @test fit_matrix_free_reml(spec; nprobe = 32, seed = 7).variance_components.sigma_a2 !=
          mf.variance_components.sigma_a2

    # (d) standard extractors work on the returned AnimalModelFit
    @test length(breeding_values(mf).values) == n
    @test length(fixed_effects(mf)) == 1

    # (e) compute_loglik = false skips the one factorization and reports NaN honestly
    mfn = fit_matrix_free_reml(spec; nprobe = 8, seed = 1, compute_loglik = false)
    @test isnan(mfn.likelihood.loglik)
    @test mfn.target === :matrix_free_reml

    # (f) supplied `initial` is accepted in animal-model (sigma_a2, sigma_e2) naming
    mfi = fit_matrix_free_reml(
        spec;
        nprobe = 16,
        seed = 5,
        initial = (sigma_a2 = 0.5, sigma_e2 = 0.5),
    )
    @test mfi.variance_components.sigma_a2 > 0
    @test mfi.variance_components.sigma_e2 > 0

    # (g) REML-only, per the row: an ML spec is refused before any numerics run.
    @test_throws ArgumentError fit_matrix_free_reml(
        animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :ML),
    )

    # NOT PORTED from v0.7, and must stay that way:
    #   fit_animal_model(spec; target = :matrix_free)      — refused here (fence)
    #   HSquared._auto_reml_route(...)                    — absent here (fence)
    # Those assertions are false on this branch. The fence testset already
    # pins the refusal / absence. Do not "repair" them back to v0.7's shape.
end

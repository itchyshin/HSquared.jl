# After-task — v0.8 matrix-free fit: V8.1 loglik + V8.2 variance reduction (2026-07-03)

**Session:** Claude solo (Opus), autonomous continuation. Turns the matrix-free Monte-Carlo REML
fit (merged PR #249) into a *full, cheaper* REML fit — the two highest-leverage items from the
completion ultra-plan (doc-25).
**Repo:** `HSquared.jl` only (R twin frozen). **Branch:** `feat/2026-07-03-matfree-varreduction-loglik`.

## Headline

Two additive slices on the matrix-free fit, both local-gated + Rose-audited; **no covered flip,
honesty pins held** (`validation_status()` rows **54** / covered **13** / `public_covered_count`
**5** UNCHANGED — no new row; the existing `V3-NEFFECT-MATFREE-FIT` `partial` row gains the
delivered items).

1. **V8.2 — shared-probe trace variance reduction.** `mc_reml_block_traces(...; shared_probes=true)`
   and `fit_multi_effect_mc_reml(...; shared_probes=true)` estimate ALL `K` block traces from one
   FULL-random Rademacher probe per solve — `nprobe` solves/iteration instead of `nprobe·K`
   (`K×` fewer). Unbiased (`E[z_b z_{b'}ᵀ]=δ_{bb'}I`); at equal solve budget as tight or tighter
   than the per-block estimator (measured: block RMSE 0.0031→0.0016 / 0.031→0.021 at 120 solves,
   K=3). Default stays `false` (the validated Slice C path unchanged); opt-in `true` is the cheaper
   path.

2. **V8.1 — matrix-free REML loglik.** `matrix_free_reml_loglik(y, X, effects, sigmas, σ²e)` — the
   one determinant term that needs `C`, `log|C|`, is estimated by **stochastic Lanczos quadrature**
   (matrix-free Lanczos → tridiagonal → quadrature); `log|R|`, `log|G|` (`log|Aᵢ⁻¹|` via a one-time
   sparse Cholesky of the pedigree/identity precision — far cheaper than `C`), and `yᵀPy` (a
   matrix-free solve) are exact/cheap. Matches the exact `sparse_multi_reml_loglik` within the SLQ
   Monte-Carlo error band — |diff| 0.61 at q=300, 1.47 at q=1000, both < 3·MCSE. Returns
   `(loglik, loglik_mcse)`; stochastic (the loglik carries MC noise, `∝1/√slq_probes`). This is the
   term that unlocks LRTs + the interval machinery (V8.3).

## De-risk-before-productionize

Both slices were prototyped + validated against exact references before touching `src/`: the
shared-probe RMSE-at-equal-budget comparison, and the SLQ-vs-`logdet(cholesky(C))` validation
(relerr ~0.4–1% at q=300–1000, shrinking with probes). Only then implemented + unit-tested.

## Checks

- `Pkg.test()` GREEN (count 54 UNCHANGED; new testsets: shared-probe unbiasedness, matrix-free
  loglik within the SLQ band + more-probes-tighter + guards). `docs/make.jl` GREEN (`matrix_free_reml_loglik`
  added to api.md).
- Honesty pins UNCHANGED (54/13/5); no covered flip — these are additive engine capabilities on an
  experimental `partial` row. Both estimators are STOCHASTIC and honestly fenced (approximate,
  MC-noise-reported, exact path preferred at validation scale).

## Next (doc-25)

V8.3 (matrix-free intervals — now unblocked: the loglik supports LRT/profile machinery, and the
observed information can be built stochastically) and V8.4 (external comparator through the
matrix-free path at scale). Then the v0.7 GPU fan-out (G-B Float32 + cross-device replicates).

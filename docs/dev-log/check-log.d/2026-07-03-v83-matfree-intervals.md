# Check-log — v0.8-V8.3 matrix-free intervals (2026-07-03)

**Slice:** asymptotic variance-ratio / `h²` intervals for the matrix-free multi-effect fit via a
matrix-free average-information (AI) matrix. New: `matrix_free_reml_information`,
`matrix_free_ratio_intervals` (exported). Branch `feat/2026-07-03-v83-matfree-intervals`.

## Key result

The AI matrix `0.5·WᵀPW` is built purely from working-variate `P`-projections (matrix-free MME
re-solves) — it needs NO stochastic trace (only the *score* needs the trace). So the matrix-free AI
matrix is **EXACT** (not stochastic): it reproduces the exact Cholesky-factor AI matrix
(`fit_sparse_multi_effect_aireml`'s `information`) to the PCG tolerance. The logit delta-method ratio
intervals then match the exact `multi_effect_ratio_interval`.

## Evidence

- Prototype: matrix-free AI vs exact factor-based AI — `max|diff|` 3e-8 (q=200,K=2) / 8e-6 (q=500,K=3);
  ratio intervals identical to exact-AI intervals.
- Test (`test/runtests.jl` "Matrix-free AI information + ratio intervals"): AI matches exact to <1e-6
  (pcg_tol=1e-13); ratio intervals match the exact-AI intervals to <1e-3 (the logit·inv(AI) transform
  amplifies the PCG-tolerance AI residual); both paths agree on boundary-NaN-ness; animal-block ratio
  is a valid `h²∈(0,1)`; guards.
- `Pkg.test()` GREEN (count 54 UNCHANGED); `docs/make.jl` GREEN (2 new api.md entries).

## Honesty

Asymptotic, AI-based, NOT coverage-calibrated (like all engine intervals). No covered flip; the
matrix-free fit stays experimental `partial` (V3-NEFFECT-MATFREE-FIT). Coverage-calibrated intervals
+ an external comparator through the matrix-free path remain owed (V8.4).

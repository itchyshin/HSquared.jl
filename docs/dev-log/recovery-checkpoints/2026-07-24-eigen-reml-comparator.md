# Result — `fit_eigen_reml` same-estimand external REML comparator (`sommer`): **AGREE**

**Date:** 2026-07-24 · **Estimator:** `fit_eigen_reml` (V1-EIGEN-REML) · **Comparator:** `sommer` 4.4.5
(R 4.6.0), independent REML optimizer · **Data:** recovery-gate Arm-WS seed **20267000** (n=1000,
window=50), reconstructed byte-identically by `comparator/prepare_sommer_eigen.jl`.

This discharges the **G11 same-estimand external REML comparator leg** for `V1-EIGEN-REML` (the "kind"
requirement — REML-vs-REML — is honored; this is not Bayesian agreement). Together with the PASSED
known-truth recovery gate (`2026-07-24-eigen-reml-recovery-gate-result.md`), **G11 is now fully
satisfied** for the eigen-once single-effect fitter. It still does not promote anything: G8 (Rose) and
G10 (owner) remain, and **`public_covered_count` stays 5**.

## Verdict: **AGREE** (max rel.diff 7.77e-09, tol 2e-2)

`sommer::mmer(y ~ 1, random = ~ vsr(animal, Gu = A), rcov = ~ units)` on the SAME data + SAME A matrix:

| component | engine (`fit_eigen_reml`) | sommer (independent REML) | rel.diff |
|---|---|---|---|
| σ²a | 1.266229 | 1.266229 | **7.77e-09** |
| σ²e | 1.442756 | 1.442756 | 2.08e-09 |
| h² | 0.467418 | 0.467418 | 5.25e-09 |

Two independent REML implementations converge to the SAME single-effect optimum to **~1e-8** — far
inside the 2e-2 tolerance, and tighter than the ~1e-4/1e-5 the prior covered promotions (V3-NEFFECT,
V4-DIRECT-MATERNAL) recorded against `sommer`/`blupf90+`. (The seed's σ²a=1.27 is above the truth 1.0
because this is ONE draw; the comparator tests same-data agreement, not recovery — recovery is the gate.)

## High-fill regime — established transitively (rigorous)

The direct comparator ran on the well-structured Arm-WS seed (where `sommer` is most robust). Agreement on
the higher-fill (window=0) Arm-HF pedigree follows transitively (an estimand-identity inference, not a direct
`sommer` measurement) from two measured legs:

- `sommer` ≡ `fit_eigen_reml` on Arm-WS seed 20267000: **7.77e-09** (this doc).
- `fit_eigen_reml` ≡ `fit_ai_reml` across ALL 96 gate seeds incl. the 48 higher-fill Arm-HF seeds:
  **≤ 2.62e-7** (all-96 max; `2026-07-24-eigen-reml-recovery-gate-result.md`).

→ `sommer` ≡ `fit_eigen_reml` on the higher-fill arm to ~2e-7 by transitivity. (NB the gate's HF arm is
`nnz(L)/n ≈ 49` at n=1000 — a higher-fill *structure*, still below the `:auto` threshold 60; see the result
doc's erratum.) A direct high-fill `sommer` run is a cheap optional add if a reviewer wants it.

## Reproduce

```sh
julia --project=. comparator/prepare_sommer_eigen.jl   # writes comparator/sommer_eigen/{eigen,A,engine_target}.csv
Rscript comparator/run_sommer_eigen.R                   # → COMPARATOR: AGREE (max rel.diff 7.77e-09)
```

> Related: `docs/design/16-promotion-gate-predicates.md` (G11 substitutability) ·
> `comparator/prepare_sommer_eigen.jl` · `comparator/run_sommer_eigen.R` ·
> `2026-07-24-eigen-reml-recovery-gate-result.md`.

# Result — `fit_ai_reml` DIRECT same-estimand external REML comparator (`sommer`): **AGREE**

**2026-07-24 · Estimator:** `fit_ai_reml` (sparse single-effect AI-REML — the Wave-F production-scale
fitter) · **Comparator:** `sommer` 4.4.5 (R 4.6.0), independent REML optimizer · **Data:** fresh seed
**20268400**, n=2000, well-structured (window=50), disjoint from the F5 gate seeds. OPT-IN; promotes
NOTHING; `public_covered_count` stays 5.

This is the **F8 same-estimand REML comparator leg (S6)** for the sparse AI-REML fitter, run
DIRECTLY (not transitively). It complements the eigen-thread comparator, which established
`sommer ≡ fit_eigen_reml` (7.77e-9) and, with the gate's `fit_eigen_reml ≡ fit_ai_reml`, gave
`sommer ≡ fit_ai_reml` transitively (~2e-7). Here `sommer` is fitted directly against
`fit_ai_reml`'s target.

## Verdict: **AGREE** (max rel.diff 3.59e-05, tol 2e-2)

`sommer::mmer(y ~ 1, random = ~ vsr(animal, Gu = A), rcov = ~ units)` on the SAME data + SAME A:

| component | engine (`fit_ai_reml`) | sommer (independent REML) | rel.diff |
|---|---|---|---|
| σ²a | 0.997534 | 0.997498 | **3.59e-05** |
| σ²e | 1.504770 | 1.504779 | 5.99e-06 |
| h²  | 0.398646 | 0.398636 | 2.52e-05 |

Two independent REML implementations converge to the SAME single-effect optimum to ~1e-5 — far
inside the 2e-2 tolerance. The REML-vs-REML "kind" requirement is honored (this is not Bayesian
agreement). `pedigreemm` is not installed locally and remains an optional owed leg (doc-18); `sommer`
is the runnable same-estimand REML comparator.

## Scope
The comparator tests same-data **agreement** (the two optimizers hit the same optimum), not recovery
— recovery at scale is the F5 gate. Together with F5 (recovery to 0.49% at q=1e5) and the F0
benchmark, this is the S6 evidence leg. It discharges nothing on its own: a staged
experimental→(production-default) declaration still requires a REAL Rose G8 + owner G10.

## Reproduce
```sh
julia --project=. comparator/prepare_sommer_aireml.jl   # writes comparator/sommer_aireml/*
Rscript comparator/run_sommer_aireml.R                   # → COMPARATOR: AGREE (max rel.diff 3.59e-05)
```

> Related: `docs/design/16-promotion-gate-predicates.md` (G11) ·
> `2026-07-24-eigen-reml-comparator.md` (the eigen/transitive leg) ·
> `comparator/prepare_sommer_aireml.jl` · `comparator/run_sommer_aireml.R`.

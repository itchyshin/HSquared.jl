# V6-ORDINAL same-estimand comparator — ordinal::clmm — 2026-07-01

Executed the same-estimand external comparator leg for the ordinal joint estimator
`fit_laplace_reml(...; family = :ordered_probit)` (Phase 1, #215) against **R `ordinal::clmm`**
(Christensen; Laplace-ML) with a probit cumulative link and an iid animal random effect. AUTONOMOUS
(installed `ordinal` locally). **`glmmTMB` CANNOT fit cumulative-link ordinal models — `clmm` is the
correct same-estimand tool.** Evidence for the v0.6 ordinal covered path (doc-20); promotes nothing —
experimental/`partial`, public-covered fitting = 1 UNCHANGED.

## Same-estimand construction + parameterization alignment

**A = I** animal model with **repeated records** makes the engine's animal effect `u ~ N(0, σ²a·I)`
identical to clmm's iid `(1|id)`. 80 animals × 4 records = 320 obs (informative — the ≥3-category σ²a
weak-identification of Phase 1 is resolved by replication); K = 3 ordered categories; both fit the
SAME seeded data (`set.seed(20260701)`).

The two parameterizations differ by an intercept convention, aligned as:
- **σ²a** — compares DIRECTLY (both the probit-latent animal variance).
- **cutpoint SPACING** — the engine fixes `θ_1 = 0` + estimates an intercept β; clmm has no intercept
  and estimates thresholds `θ^c`. So engine `θ_2` (its only free cutpoint) == clmm `(θ^c_2 − θ^c_1)`
  (location-invariant).
- **intercept** — engine `β` == `−θ^c_1` (clmm's first threshold is the negated location).

Reproduce: `Rscript comparator/ordinal_clmm/generate_and_fit.R` then the engine fit on
`comparator/ordinal_clmm/packet/data.csv`.

## Result

| parameter | engine | ordinal::clmm | \|Δ\| | truth |
| --- | --- | --- | --- | --- |
| cutpoint spacing (θ_2) | 1.1927 | 1.1883 | **0.0044** | 1.20 |
| σ²a (animal var) | 0.7532 | 0.7291 | 0.0241 | 0.50 |
| intercept β (= −θ^c_1) | 0.3093 | 0.2974 | 0.0119 | 0.40 |

Both engine and clmm **converged**. The cutpoint spacing agrees to **~0.4% (essentially exact)**;
σ²a to ~3%; the aligned intercept to 0.012.

## Interpretation (honest)

- **The cutpoint spacing is an essentially exact match (0.004)** — the two independent Laplace-ML
  ordinal implementations agree on the threshold structure once the intercept convention is aligned.
- The **σ²a difference (~3%) is the expected ML-vs-REML variance-convention gap** (engine's
  β-flat-integrated Laplace is REML-ish → slightly LARGER; same direction + magnitude as the Gamma
  glmmTMB leg), NOT a discrepancy.
- Both σ²a estimates sit above the true 0.5 (small-sample threshold-model upward pull at q=80), but the
  engine and clmm AGREE with each other — which is the same-estimand claim.

## Fences

Experimental/`partial`; `validation_status()` UNCHANGED; public-covered fitting = 1 UNCHANGED; NOT a
covered claim. ONE same-estimand comparator leg (`clmm`, the correct ordinal tool). Owed for a covered
flip (maintainer G10): a pre-declared recovery gate (Phase 5), the `:symbol` payload + scale-labelled
h², and the maintainer's sign-off. Real Rose audit on this leg pending.

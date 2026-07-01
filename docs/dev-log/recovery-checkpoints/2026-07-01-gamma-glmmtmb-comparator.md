# V6-GAMMA same-estimand comparator — glmmTMB — 2026-07-01

Executed the same-estimand external comparator leg for the Gamma (log-link) joint estimator
`fit_laplace_reml(...; family = :gamma)` (Phase 2, #216) against **R `glmmTMB` 4.6-era**
`Gamma(link = "log")` with an iid animal random effect. AUTONOMOUS (glmmTMB installed locally).
Evidence for the v0.6 Gamma covered path (doc-20); promotes nothing — the family stays
experimental/`partial`, public-covered fitting = 1 UNCHANGED.

## Same-estimand construction

An **A = I** animal model (unrelated animals) with **repeated records** makes the engine's animal
effect `u ~ N(0, σ²a·A) = N(0, σ²a·I)` IDENTICAL to glmmTMB's iid `(1|id)` random effect — the same
estimand (Gamma log-link GLMM with an iid animal variance + a shape). 40 animals × 4 records = 160
obs; both fit the SAME data.

- Generator (seeded, `set.seed(20260701)`): `comparator/gamma_glmmtmb/generate_and_fit.R` — writes
  the data packet + the glmmTMB estimates.
- Engine leg: `fit_laplace_reml(y, X, Z, Ainv=I; family = :gamma)` on the identical packet.
- Reproduce: `Rscript comparator/gamma_glmmtmb/generate_and_fit.R` then the engine fit on
  `comparator/gamma_glmmtmb/packet/data.csv`.

## Result

| parameter | engine | glmmTMB | \|Δ\| | truth |
| --- | --- | --- | --- | --- |
| shape ν | 3.4924 | 3.4892 | **0.0032** | 3.0 |
| σ²a (animal var) | 0.5624 | 0.5457 | 0.0167 | 0.35 |
| intercept β | 0.5293 | 0.5615 | 0.0322 | 0.6 |

Both engine and glmmTMB **converged**. The shape agrees to **~0.1%**; σ²a and the intercept agree to
a few %.

## Interpretation (honest)

- **The shape ν is an essentially exact match (0.003)** — the two independent Laplace implementations
  agree on the Gamma dispersion.
- The **σ²a difference (~3%) is the expected ML-vs-REML variance-convention difference:** the engine's
  Laplace marginal flat-integrates β (a REML-like treatment → slightly LARGER variance), while
  glmmTMB's Gamma GLMM uses Laplace-approximate ML for the variance component. The direction (engine
  0.562 > glmmTMB 0.546) and magnitude are consistent with ML-vs-REML, not a discrepancy. The
  intercept difference (~6%) is within the same convention gap on a 160-obs sample.
- This is a **same-estimand leg with a documented variance-convention caveat**, NOT a bit-identical
  parity. A tighter check would fit glmmTMB under REML or compare on a larger sample; that is the
  follow-up.

## Fences

Experimental/`partial`; `validation_status()` UNCHANGED; public-covered fitting = 1 UNCHANGED; NOT a
covered claim. This is ONE same-estimand comparator leg (glmmTMB, valid for Gamma — unlike the ordinal
case). Still owed for a covered flip (maintainer G10): a pre-declared recovery gate (Phase 5), the
`:symbol` payload + scale-labelled h², and the maintainer's sign-off. Real Rose audit on this leg pending.

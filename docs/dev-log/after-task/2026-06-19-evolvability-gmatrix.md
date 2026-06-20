# After-task — #55 Evolvability / G-matrix geometry (2026-06-19)

Overnight autonomous runway run (Ada). First innovation-backlog feature delivered
(planned feature, not just a gap closure).

## Goal

Deliver issue #55 — Julia-native Hansen & Houle (2008) evolvability metrics and
genetic principal axes on a genetic covariance `G`. Chosen as the cleanest solo
win in the backlog because every metric is a function of `G` itself, so it is
**rotation-invariant** and sidesteps the FA loading-rotation convention that gates
the structured bridge payload and structured SEs.

## What landed

- `src/evolvability.jl` (exported, 8 functions): `evolvability`,
  `conditional_evolvability`, `respondability`, `autonomy`,
  `variance_along_gradient`, `genetic_pca`, `g_max`, `mean_evolvability` — each on
  a matrix or a multivariate result. PSD-safe metrics work on a reduced-rank `G`;
  the inverse-using `conditional_evolvability`/`autonomy` require a PD `G`.
- 61-assertion testset of hand-checked identities + explicit rotation-invariance.
- capability-status + validation-debt `V4-EVOLVE` + `validation_status()`
  `V4-EVOLVE` row (count 33 → 34).

## Review (adversarial workflow)

(Recorded after the workflow returns — Kirkpatrick / Noether+Gauss / Rose.)

## Local checks

- `Pkg.test()` → exit 0 (evolvability testset 61/61; green after the
  `validation_status` row + count bump).
- `docs/make.jl` → exit 0.

## Claim boundary

Descriptive G-matrix geometry only; rotation-invariant; NOT a selection-response
prediction or a fitting/estimation claim. Metrics on an estimated `G` inherit the
`V4-MV-REML`/`V4-FA` caveats. No external comparator yet. No capability moved to
covered. Population-averaged conditional-evolvability/autonomy (random-skewers,
no simple closed form) left as future work.

# Two-Effect REML (common-environment / maternal estimation)

Active lenses: Gauss, Fisher, Falconer, Mendel, Curie, Rose (inline).
Spawned subagents: none.

## Goal

REML estimation for the general two-effect model — estimate (σ1, σ2, σe²) and the
variance ratios (e.g. `h²`, common-environment `c²`, maternal variance),
completing the Phase-3 standard-QG engine kernel alongside `two_effect_mme`.

## Files Changed

- `src/likelihood.jl` (`_two_effect_dense`; `fit_two_effect_reml`;
  `_repeatability_dense` refactored to delegate)
- `src/HSquared.jl` (export `fit_two_effect_reml`)
- `test/runtests.jl` (testset; `length(validation)` 24→25)
- `src/validation_status.jl` (row `V3-TWOEFFECT-REML`; `V3-TWOEFFECT` missing updated)
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/after-task/2026-06-13-two-effect-reml.md`

## Implementation

`fit_two_effect_reml` maximizes the dense two-effect REML log-likelihood
`V = σ1·Z1A1Z1ᵀ + σ2·Z2A2Z2ᵀ + σe²·I` over the log-variances (NelderMead),
returning the VCs, `ratio1 = σ1/total`, `ratio2 = σ2/total`, β, both BLUPs,
loglik, converged. `_repeatability_dense` now delegates to the shared
`_two_effect_dense` (dedup; guarded by the repeatability-REML tests).

## Checks

- `Pkg.test()`: passed, 724 total. New testset = 12 checks. The strong anchor is
  the **exact reduction**: `fit_two_effect_reml(Z2=Z1, A2=I)` equals the
  already-validated `fit_repeatability_reml` (rtol 1e-4); plus the loglik reduces
  to the animal-model REML at σ2=0 and a common-environment fit converges with
  valid ratios.
- One-off seeded common-environment recovery (NOT committed; suite RNG-free):
  σc² and σe² recover well; σa² is underestimated on a small, partially
  confounded design (genetic vs common-environment need more contrast to
  separate) — reported honestly, not a strong recovery claim.

## Public Claim Audit

Allowed: experimental REML estimation of the two-effect-model variances and
ratios (common-environment / maternal), with the exact reduction to the validated
repeatability REML as the key check.

Blocked: a committed recovery test; ratio uncertainty intervals; correlated
direct–maternal genetic (2×2 G); external comparators; the R model-spec.

## Coordination Notes

Engine-internal; no contract change. The R `common_env()` / maternal mapping
stays coordinated with the R twin.

## Known Limitations

- Dense / validation-scale; small/confounded data can underestimate σa² or hit a
  boundary.
- No committed recovery harness; no ratio intervals; independent effects only.

## Next Actions

1. Ratio (h²/c²) uncertainty intervals (finite-difference Hessian of the dense
   loglik) and a committed recovery harness (per the RNG decision note).
2. Correlated direct–maternal genetic model (2×2 G) — Phase-4-flavored.
3. Coordinate the R `common_env()` / maternal model-spec with the R twin.

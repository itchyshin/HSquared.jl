# Heritability Intervals + Variance-Component Covariance

Active lenses: Fisher, Gauss, Curie, Noether, Rose (inline).
Spawned subagents: none. A local probe first showed the naive (linear-scale)
delta interval is degenerate (CI outside [0,1]); the design note records why the
logit-transform interval was chosen.

## Goal

Give `hsquared` an uncertainty for its namesake parameter: variance-component
standard errors and a confidence interval for `h²`. Previously `heritability(fit)`
was a point estimate only.

## Files Changed

- `src/likelihood.jl` (`_standard_normal_quantile`, `_reml_information_matrix`;
  `variance_component_covariance`, `variance_component_standard_errors`,
  `heritability_standard_error`, `heritability_interval`)
- `src/HSquared.jl` (export the four public functions)
- `test/runtests.jl` (testset; `length(validation)` 20→21)
- `src/validation_status.jl` (row `V1-HERIT-CI`)
- `docs/src/api.md`, `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md`, `docs/src/changelog.md`,
  `docs/dev-log/check-log.md`,
  `docs/dev-log/decisions/2026-06-13-heritability-interval-design.md` (resolved),
  `docs/dev-log/after-task/2026-06-13-heritability-intervals.md`

## Implementation

`variance_component_covariance(fit)` inverts the REML average-information matrix
(`_reml_information_matrix`, the same AI metric `fit_ai_reml` uses) to get the
asymptotic covariance of `(σ²a, σ²e)`. `heritability_standard_error` applies the
delta method. `heritability_interval(fit; level)` builds the interval on the
**logit scale** and back-transforms, so it is always inside `(0, 1)` — avoiding
the out-of-range intervals the naive linear delta method produces. A
self-contained Acklam standard-normal quantile supplies the two-sided `z` without
adding a dependency. REML-only (the information is the REML information).

## Checks

- `Pkg.test()`: passed, 680 total. New testset = 19 checks (see check-log).
  The key independent anchor: the AI matrix matches a finite-difference Hessian
  of the REML log-likelihood (observed information) to ~8% on the fixture.

## Public Claim Audit

Allowed: experimental, asymptotic variance-component SEs and a logit-delta `h²`
interval that is always in `(0, 1)`, from the REML AI matrix.

Blocked: any coverage claim (not calibrated); reliability at small n (the
interval is wide and the AI matrix ill-conditioned — stated in the docstring);
profile-likelihood / bootstrap intervals (future); ML (non-REML) information.

## Tests Of The Tests

The AI matrix is checked against an *independent* finite-difference REML Hessian
(not against itself); the interval's `(0,1)` containment, estimate-coverage, and
level-nesting are structural checks; the Acklam quantile is pinned to textbook
z-values; the REML-only and level guards fire.

## Coordination Notes

Engine-internal; no bridge / `result_payload` / model-spec change. Works for
pedigree and genomic REML fits alike.

## Known Limitations

- Asymptotic; unreliable at small n. Not coverage-calibrated.
- REML-only; no ML information. No profile-likelihood / bootstrap alternative.

## Next Actions

1. Large-n coverage calibration (needs a seeded simulation harness — currently
   the suite is RNG-free).
2. Profile-likelihood interval as a boundary-aware alternative.

# After-task — Binomial/Bernoulli profile-LRT σ²a interval

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/binomial-profile-interval`. A direct follow-on to the per-record `n_trials`
slice (#118): with the Binomial fitter now general, the natural next accuracy step
is to close the `V6-BINOMIAL`/`V6-BERNOULLI` "no intervals" gap by extending the
already-validated Poisson profile-LRT interval to the other single-component families.

## Summary

Generalized `laplace_reml_interval` from `:poisson`-only to `:poisson` /
`:bernoulli` / `:binomial` (the single-variance-component families), reusing the
validated `_profile_root` marginal-LRT inversion unchanged. Extracted a shared
`_resolve_single_family(family, n_trials)` helper so the fitter and the interval
construct the family identically and cannot drift; the fitter now calls it (refactor
only — the 31 scalar + 39 per-record Binomial fitter assertions pass unchanged).

Whether the interval is two-sided depends on where `σ̂²a` sits relative to the flat
near-zero region of the profile — NOT on the family (this framing was corrected by the
adversarial review, which refuted an initial "adequate-trial ⇒ fully two-sided" claim):
- Scalar **Binomial** m=20 (`σ̂²a≈0.98`): two interior χ²₁ LRT roots — genuinely two-sided.
- The same data with a per-record vector (`σ̂²a≈0.37`): the LOWER endpoint clamps.
- Binary **Bernoulli**: doubly clamped/degenerate.

To make this honest at the API, the interval returns `lower_clamped`/`upper_clamped`/
`converged` flags so a non-crossing (clamped) endpoint is SELF-DESCRIBING, not a silent
finite triple. `marginal = :variational` is rejected (the ELBO is not a χ²₁ LRT), and a
scalar non-integer `n_trials` now gives a clean `ArgumentError`.

## Definition of Done

- implementation — `src/nongaussian.jl`: `_resolve_single_family` helper, the fitter
  refactor to use it, the `laplace_reml_interval` generalization + honest docstring.
- tests — "Phase 6 Binomial/Bernoulli profile-LRT interval (σ²a)": 20 assertions
  (point==MLE, deviance vanishes, brackets + σ²a>0; the scalar m=20 fixture genuinely
  two-sided via `!lower_clamped && !upper_clamped` + interior χ²₁ at 95% AND 90% +
  nesting; the per-record fixture WITNESSES the lower clamp; the Bernoulli witnesses the
  double clamp; `marginal = :variational` rejected; guards incl. non-integer scalar).
  The Poisson interval testset (12) and the Binomial fitter testsets (31+39) unchanged.
- documentation — interval docstring (honest two-sidedness + clamp-flag + variational
  caveats); the V6-FIT / V6-BERNOULLI / V6-BINOMIAL capability rows + V6-FIT / V6-BINOMIAL
  debt rows + the `V6-LAPLACE` `validation_status()` row updated (stale "no intervals" /
  "Poisson only" removed). `docs/make.jl` clean.
- check-log — `docs/dev-log/check-log.d/2026-06-20-binomial-profile-interval.md`.
- after-task — this file.
- adversarial verification — focused Fisher (inference validity) + Rose (claim gate)
  pass over the diff. Fisher (SOUND-with-concerns) confirmed the LRT inversion is as
  valid for Binomial/Bernoulli as for Poisson and caught the over-generalized two-sided
  claim, the silent-clamp hazard, the uncalibrated `:variational` path, and the scalar
  non-integer `MethodError`; Rose caught two stale "Poisson-only" claims the first sweep
  missed (`validation_status.jl` V6-LAPLACE, capability-status V6-FIT clause). ALL fixed
  before landing (clamp/converged flags + `:variational` guard + clean scalar error +
  softened/destaled claims + 4 new assertions).
- clean local checks — `Pkg.test()` + `docs/make.jl` GREEN.
- clean CI — gated on the PR.

## Honest status

EXPERIMENTAL, asymptotic, single-component only, NO coverage calibration. The
Gaussian/two-component interval (nuisance profiling) is still future work; no external
comparator; no R model-spec. `validation_status()` UNCHANGED (41 rows) — this widens an
existing experimental family, nothing is promoted to `covered`.

## Next

The Gaussian two-component (σ²a, σ²e) interval (nuisance profiling); large-n coverage
calibration of these asymptotic intervals; a probit/threshold comparator for the binary
σ²a bias. None gates this slice.

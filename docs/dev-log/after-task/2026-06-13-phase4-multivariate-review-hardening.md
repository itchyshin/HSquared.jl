# Phase 4: multivariate engine adversarial-review hardening

Active lenses (review): Gauss, Karpinski, Fisher, Kirkpatrick, Henderson, Curie,
Rose. Fixes by the main loop.

## Goal

Run the independent adversarial review of the Phase-4 multivariate engine that the
earlier session could not (subagent session limits), then act on confirmed
findings — closing the "no adversarial review yet" caveat on the REML estimator.

## The review

A 7-lens workflow (`mv-engine-adversarial-review`): each specialist lens reviewed
`src/multivariate.jl` + the Phase-4 testsets + the status surfaces, and every
blocker/major finding was handed to an independent verifier that **ran Julia** to
confirm or refute it (default refuted). 18 agents total; the Gauss review lens
itself died on a transient rate limit, but its scope was covered by Karpinski +
Henderson and the verifiers.

## Confirmed findings (all robustness/consistency — no correctness bug on valid inputs)

1. **Non-finite `Inf` phenotypes silently accepted.** `_is_present` filtered only
   `missing`/`NaN`, so `Inf` in `Y` (or `Z`) passed through: `multivariate_mme`
   returned an all-NaN `β`/EBV with no error, and `fit_multivariate_reml` returned
   finite-looking `G0`/`R0`/`h²` with `converged=false` (the NelderMead start
   point) — a silent trap for a caller who doesn't check `converged`.
2. **Empty trait column → opaque error.** A trait with zero observed records gave a
   bare `SingularException(0)` / `PosDefException`, naming neither the trait nor the
   cause.
3. **REML loglik off the package scale.** `fit_multivariate_reml.loglik` dropped the
   `(N−p')·log(2π)` REML constant, so it differed from `gaussian_loglik` /
   `sparse_reml_loglik` by exactly that constant — a silent LRT/AIC hazard across
   functions. (Verified numerically: the gap equalled `(n−p)/2·log(2π)` to 8 digits.)

## Fixes (`src/multivariate.jl`)

- `_mv_validate_inputs` (new, shared by `multivariate_mme` and `_mv_observed`):
  rejects a non-finite observed `Y[i,k]` (message names the cell + trait), a
  non-finite `X`/`Z`, and an empty-trait column (names the trait); `Ainv`
  finiteness is checked in both entry points. Fail-loud, so garbage never returns
  plausible-looking covariances.
- `_mv_reml_loglik_core` adds the `(N−p')·log(2π)` constant → the loglik is the
  full REML loglik and now **equals** the univariate `sparse_reml_loglik` at
  `t=1` (not merely up to a constant). Docstring updated; the optimizer argmax is
  unaffected (a constant shift).

## Validation

- `Pkg.test()`: passed. New/strengthened committed checks:
  - supplied-covariance testset 23 → 26: `Inf`-in-`Y`, `Inf`-in-`Z`, and
    empty-trait guards;
  - REML testset 21 → 24: the loglik is now asserted **equal** to the univariate
    `sparse_reml_loglik` at `t=1` on two points (atol 1e-7), plus `Inf` and
    empty-trait guards on the estimator.
- `julia --project=docs docs/make.jl`: green (docstrings updated).

## Status surfaces (lockstep)

`validation_status.jl` (`V4-MULTIVARIATE` + `V4-MV-REML`: guards + loglik-scale +
"adversarial-reviewed"), `capability-status.md`, `validation-debt-register.md`,
`changelog.md`, `check-log.md`, this report.

## Public claim audit (Rose, inline)

The review removes a real overclaim risk: `V4-MV-REML` previously listed "no
adversarial review yet" as a gap; that gap is now closed (review run, findings
fixed). The estimator stays `partial`/experimental — external-comparator parity, a
committed recovery harness, and covariance SEs remain genuinely outstanding, and
are still listed as such.

## Coordination

Engine-internal; no bridge-contract change; the R v0.1 univariate path is
untouched (already communicated on issue #6). Lands on the PR #15 branch (tip of
the Phase-4 train).

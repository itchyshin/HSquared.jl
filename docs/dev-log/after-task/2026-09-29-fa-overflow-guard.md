# After-task: FA optimizer overflow guard

## 1. Goal

Keep invalid numerical trial points inside the multivariate REML optimizer,
while reporting invariant input errors to the caller.

## 2. Implemented

Moved covariance transforms into the objective's candidate-error guard, checked
parameter-vector length before evaluation, and limited likelihood-stage
recovery to positive-definiteness failures. Added a pre-fit fixed-design rank
check. Overflowing uniqueness proposals now return `Inf`; malformed vector
length and unrelated dimension errors propagate.

## 3a. Decisions and Rejected Alternatives

- Kept `ArgumentError` handling around parameter transforms, where an
  overflowing exponential yields a nonfinite covariance and a constructor
  refusal.
- Let `ArgumentError` and `DimensionMismatch` from likelihood evaluation
  propagate to expose invariant input problems.
- Validate the fixed-effect rank once before optimization so a singular
  `X′V⁻¹X` cannot be mistaken for a bad covariance trial.
- Did not alter optimizer settings or start strategy.

## 4. Files Touched

- `src/multivariate.jl`
- `test/test_multivariate_fa_multistart.jl`
- `GATES.md`
- `docs/dev-log/check-log.d/2026-09-29-fa-overflow-guard.md`
- `docs/dev-log/after-task/2026-09-29-fa-overflow-guard.md`

## 5. Checks Run

- Focused multistart test file: 47/47 passed.
- Focused FA uniqueness and production-map Jacobian test: 29/29 passed.
- Full `Pkg.test()` exited 0 with `Testing HSquared tests passed`.
- Full Julia documentation build exited 0. It retained existing warnings about
  47 docstrings missing from the manual, absent deployment/environment
  configuration, missing VitePress customization/favicon/package metadata,
  and a large JavaScript chunk.
- The test run warned that project dependencies or compat requirements had
  changed since the manifest was resolved. I did not resolve or update them.
- Gauss's independent review passed the narrow guard and test changes.
- Current `src/multivariate.jl` SHA-256:
  `2cd41a9745802ef8899cc354e3f4a07d03a6a5eb481f8589cb4d48f945d716a0`.
- After-task structure, prose, and diff checks passed. Gates A2, E1, and V3
  remain open.

## 6. Tests of the Tests

The regression checks that `exp(1000)` produces a nonfinite FA covariance and
residual covariance, then verifies that both proposals return `Inf`. A NaN
likelihood result also maps to `Inf`; ordinary parameters return a finite
objective. Separate assertions check parameter length validation and
propagation of a dimension mismatch from likelihood evaluation. Duplicate
fixed-effect columns produced no error before the rank check; the corrected
fitter now refuses them with a clear message.

## 7a. Issue Ledger

- Fixed: overflowing FA uniqueness proposals could throw outside the objective
  handler and stop the optimizer.
- Fixed: the broad exception scope could hide fixed-design singularity as an
  invalid covariance trial.
- Fixed: malformed optimizer vectors could be misclassified as numerical
  candidate failures.
- Open: ordinary-start recovery, fitted likelihood information, floor
  sensitivity, inferential calibration, and broader FA cells.

## 8. Consistency Audit

The helper preserves the REML objective for finite covariance proposals and
changes only error handling. Full package tests cover other multivariate
structures. The explicit rank check applies to their shared fixed-effect
design as well. The FA capability remains partial and experimental.

## 9. What Did Not Go Smoothly

Gauss's first review found that the initial exception scope also covered the
likelihood calculation. I narrowed the catches, added fixed-design validation,
and added propagation tests. A second review found residual Cholesky overflow
and NaN objective values; finite checks now handle both, and the third review
passed the narrow helper contract.

## 10. Known Residuals

- A2 remains HOLD pending routine-start, fitted-information, inference, and
  whole-panel evidence.
- Full `Pkg.test()` passed with a stale-manifest warning caused by current
  project dependency or compatibility edits; no resolve was attempted.
- This slice did not run R checks or the held recovery campaign.

## 11. Team Learning

The optimizer should reject errors caused by its parameter proposals. Model
design errors must be checked outside that loop, where they remain visible and
do not resemble failed covariance candidates.

## 12. Cross-Product Coverage

Covers Julia's shared dense multivariate REML objective, the FA overflow case,
and fixed-effect rank validation. Does NOT cover R-Julia parity for this guard,
ordinary-start FA recovery, uncertainty calibration, other engines, GPU work,
release submission, or a public tag.

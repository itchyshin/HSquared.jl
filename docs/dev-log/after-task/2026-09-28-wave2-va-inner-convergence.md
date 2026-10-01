## 1. Goal

Require the experimental variational animal-model objective to report failure when its inner covariance fixed point misses tolerance, even if its outer gradient is small.

## 2. Implemented

- `_va_covariance` now returns convergence status, iterations, and final successive-variance change.
- `variational_marginal_loglik` requires both the outer gradient and final covariance fixed point to converge before returning a finite objective.
- Added the positive `covariance_maxiter` control, with default 200, and appended diagnostics after the existing result fields to preserve positional field order.
- Added a symmetric Binomial regression where the outer gradient is effectively zero after one step while the inner covariance solve is deliberately capped at one iteration.
- The new regression is included through `test/wave2_nongaussian_contracts.jl`, which the standard test runner includes.
- Astra's independent numerical review found no remaining must-fix in the changed behavior. Its boundary, full/diagonal, and compatibility observations are recorded below.

Active lenses: Gauss for numerical behavior; Astra for independent adversarial review. Spawned review agent: `review_va_inner_convergence_fix`. The broader Wave 2 review remains separately open.

## 3a. Decisions and Rejected Alternatives

Keep the default covariance iteration cap at 200. Expose a testable cap so callers can distinguish inner failure from outer stationarity. Preserve the historical first ten named-tuple fields in their original order. Do not return the partially converged objective as a valid fit; report `NaN` unless both convergence conditions hold.

## 4. Files Touched

- `src/nongaussian.jl`
- `test/test_nongaussian_inner_convergence.jl`
- `test/wave2_nongaussian_contracts.jl`
- `docs/dev-log/after-task/2026-09-28-wave2-va-inner-convergence.md`

## 5. Checks Run

- RED: `julia --compiled-modules=no --project=. test/test_nongaussian_inner_convergence.jl` failed because the old fitter did not expose the covariance iteration cap or convergence diagnostics.
- GREEN: `julia --compiled-modules=no --project=. -e 'include("test/test_multivariate_repeatability.jl"); include("test/test_multivariate_fa_multistart.jl"); include("test/test_data_empty_marker_status.jl"); include("test/wave2_nongaussian_contracts.jl")'` passed 154 assertions across the included focused testsets.
- `git diff --check` passed after the runner integration.
- No full `Pkg.test()`, documentation build, CI, simulation campaign, GPU run, or R bridge fit was run in this slice.

## 6. Tests of the Tests

The pre-fix run failed at the new `covariance_maxiter` keyword. After implementation, the test requires a near-zero gradient and a fixed-point error above tolerance while `converged` is false and `elbo` is `NaN`. The companion default-cap and diagonal-covariance assertions confirm a normal convergence path. The test also pins the original ten result-field positions and rejects a zero covariance iteration cap.

## 7a. Issue Ledger

- **Fixed in this slice:** the covariance fixed-point loop previously returned no convergence state, so an outer stationary gradient could mask an unfinished inner solve.
- **Open:** the Wave 2 packet still has broader separation, profile-interval, ID, and objective-label findings. Whole-wave review and panel sign-off remain open.
- **Open:** this new test is in the standard test include chain, but the full package suite has not been rerun on the integrated candidate.
- **Carried:** the diagnostic reports the final inner solve's iteration count and absolute successive marginal-variance change. It does not report total inner work or a matrix covariance residual.

## 8. Consistency Audit

Reviewed both `_va_covariance` call sites and confirmed the result remains consumed by name inside `variational_marginal_loglik`. Confirmed that the first ten returned fields retain their former order. Astra independently checked full and diagonal behavior, the symmetric-gradient fixture, nonpositive iteration caps, and the returned objective. Public R bridge payloads and capability-status rows were not changed.

## 9. What Did Not Go Smoothly

The first red run reported the absent control keyword rather than a failed convergence assertion, because no inner-cap control existed. The test was then kept as a deterministic failure-path check, and the implementation was independently reviewed against the stationary-gradient condition.

## 10. Known Residuals

This slice does not close the source-review wave. The test and source changes have focused verification only; exact-candidate full package checks and CI remain required. A pathological covariance or Schur-complement failure may still throw before the objective is masked as `NaN`; that behavior predates this repair and remains outside its scope.

The current source-review closeout lane owns `docs/dev-log/check-log.md` and `docs/dev-log/coordination-board.md`. Those shared logs still need this result appended after that lease is released.

## 11. Team Learning

Nested numerical solvers need separate convergence signals. A small outer score does not prove that a variance-dependent working covariance has reached its own fixed point. Keep test controls for inner iteration limits so this distinction remains reproducible.

Memory receipt: repository `AGENTS.md`, Wave 2 source-review notes, and current gate/check-log evidence were consulted. No durable project decision or memory update was needed. Golden Set: not run; this bookkeeping fix does not change an estimator cell.

## 12. Cross-Product Coverage

Covers: Julia variational marginal fitting with full and diagonal covariance, inner convergence diagnostics, and the existing standard test include chain.

does NOT cover: R formula or bridge exposure of these diagnostics, the opt-in Poisson GLLVM Laplace objective, non-Gaussian factor-analytic uniqueness, population recovery, interval calibration, whole-engine review, or release readiness.

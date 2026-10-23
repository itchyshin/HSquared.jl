# After-task: finite variance validation in sparse Gaussian REML

## 1. Goal

Reject nonfinite variance inputs in the sparse Gaussian REML evaluator and optimizer starts, and keep optimizer overflow from escaping as a nonfinite likelihood.

## 2. Implemented

`sparse_reml_loglik` and its cached internal evaluator now require positive, finite genetic and residual variances. `fit_sparse_reml` rejects nonfinite or nonpositive initial variances. Its log-scale objective maps exponential overflow and underflow to `Inf` before evaluating the likelihood. A new regression test covers `Inf` and `NaN` evaluator inputs, invalid starts, and a finite control. The test is registered in the package suite.

## 3a. Decisions and Rejected Alternatives

Kept the change within the sparse REML evaluator and fitter. The same finite-value defect occurs in other evaluators, but expanding the patch would cross unrelated active lanes. Optimizer-domain failures return the usual infinite penalty; explicit user inputs receive an `ArgumentError`.

## 4. Files Touched

- `src/likelihood.jl`
- `test/test_sparse_reml_finite_variances.jl`
- `test/runtests.jl`
- `docs/dev-log/after-task/2026-09-28-finite-variance-validation.md`

## 5. Checks Run

- `julia --project=. test/test_sparse_reml_finite_variances.jl`: 7/7 passed.
- `julia --project=. test/test_matfree_reml_inci_pins.jl`: 22/22 passed.
- `git diff --check`: passed.

Both Julia checks used one Julia thread, one BLAS thread, offline package mode, and the writable temporary depot. Each took under ten seconds after startup.

## 6. Tests of the Tests

Before the guard was added, a two-row identity-precision counterexample with `sigma_a2 = Inf` returned `-Inf` rather than rejecting the input. The new tests assert `ArgumentError` for both `Inf` and `NaN` in either variance position and for nonfinite starts.

## 7a. Issue Ledger

- Fixed: positive-infinity variances could pass the sparse REML checks and corrupt the likelihood.
- Fixed: nonfinite optimizer starts were not rejected at the fit boundary.
- Deferred: equivalent finite-value checks in other likelihood and non-Gaussian routes; they need their own lane review and cross-product tests.

## 8. Consistency Audit

Reviewed the public sparse REML evaluator, its cached internal evaluator, and the sparse fitter objective. The existing matrix-free REML cache pins still pass. The direct dense Gaussian evaluator and other engine paths were not changed.

## 9. What Did Not Go Smoothly

The shared candidate had unrelated in-flight edits in the same source and test files. A file-level lease was acquired, and the patch was limited to the named sparse REML contract. An initial patch matched the dense fit's start checks; that unintended scope was reverted before verification.

## 10. Known Residuals

The full package suite and CI were not rerun for this narrow repair. This does not close FA/GLLVM acceptance gates or the broader Julia source-review waves. No recovery simulation was run. Totoro availability does not satisfy the separate approval gate for the estimated 7.4-hour FA study.

## 11. Team Learning

For log-parameterized variance optimizers, validate supplied starts at the API boundary and turn exponentiation overflow or underflow into an optimizer penalty before constructing covariance matrices.

Memory receipt: loaded the repository LOAD-FIRST manifest via `route.py` and followed its ownership, estimate-before-run, and bounded-scope instructions. The Golden Set was not run because this was a local sparse-likelihood input-validation repair, not a known-mistake class covered by that suite.

## 12. Cross-Product Coverage

- Sparse Gaussian REML evaluator and fitter: covered for finite and nonfinite variance inputs ✓.
- Cached likelihood path: covered by the same checks ✓.
- Matrix-free, dense ML/REML, AI-REML, multivariate FA, and non-Gaussian routes: this change does NOT cover them ✗.

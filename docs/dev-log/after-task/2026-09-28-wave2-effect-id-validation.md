## 1. Goal

Reject supplied non-Gaussian animal-model effect IDs when their number does not match the breeding values or when IDs are duplicated.

## 2. Implemented

- `fit_laplace_reml()` now checks the supplied/default ID count against `size(Z, 2)` and requires unique IDs before entering a family-specific fit.
- The fitter documentation states the ID contract.
- Added focused malformed-ID checks to the standard Wave 2 test file. The tests use an invalid initial value so a pre-fix call fails before optimization and proves that ID validation happens first.

Active lens: Boole's formula/input-contract review. Boole independently signed off on the guard and red-test scope. The broader Wave 2 source-review panel remains open. No external message or release action occurred.

## 3a. Decisions and Rejected Alternatives

Treat each `Z` column as one breeding value and require one distinct label per column. Keep `ids = nothing` behavior, which generates unique sequential labels. Reject malformed labels before optimizer work rather than letting result extraction return mislabeled effects.

## 4. Files Touched

- `src/nongaussian.jl`
- `test/wave2_nongaussian_contracts.jl`
- `docs/dev-log/after-task/2026-09-28-wave2-effect-id-validation.md`

## 5. Checks Run

- RED: `julia --compiled-modules=no --project=. -e 'include("test/wave2_nongaussian_contracts.jl")'` failed both new assertions. Wrong-length and duplicate IDs reached the later `initial variances must be positive` error.
- GREEN: the focused multi-file command including repeatability/FA, empty-marker, and Wave 2 tests passed 162 assertions after the guard and positive ID-preservation cases.
- `git diff --check` passed.
- Two one-iteration Gaussian fits checked preservation of explicit and default IDs. No simulation campaign, GPU run, full `Pkg.test()`, docs build, or CI run was done for this slice.

## 6. Tests of the Tests

The red run confirms the assertions detect absent ID checks rather than merely accepting any `ArgumentError`. The invalid initial value ensures the unfixed path stops before optimizing; the test checks that the thrown error names the ID contract. The green run includes the regression through `test/runtests.jl`'s existing Wave 2 include. Boole confirmed the malformed-input calls stop before optimization and signed off on the scoped change.

## 7a. Issue Ledger

- **Fixed in this slice:** wrong-length and duplicate effect IDs were not rejected by the experimental non-Gaussian fitter.
- **Open:** the Wave 2 packet still has other numerical and inference findings, and the whole-wave panel has not signed off.
- **Open:** exact-candidate full package tests and CI remain to be run after lane integration.

## 8. Consistency Audit

The validation is applied after relationship-precision dimensions are checked and before any family-specific optimizer. Default IDs remain generated as `1:size(Z, 2)`. Existing extraction continues to receive the accepted ID vector. The R-facing bounded FA/GLLVM routes and capability rows were not changed.

## 9. What Did Not Go Smoothly

The first regression run reached the invalid-start error for both malformed inputs. This confirmed the missing check and established a no-fit route for testing it.

## 10. Known Residuals

This fix addresses only ID count and uniqueness in `fit_laplace_reml()`. It does not certify all public bridge ID-ordering cases or resolve other Wave 2 findings. Shared source-review logs are held by another active lane and need this result appended when its lease clears.

## 11. Team Learning

Validate labels at the boundary where latent-effect columns acquire names. This prevents downstream result extraction from silently pairing estimates with the wrong or repeated IDs.

Memory receipt: current Julia source-review packet and repository instructions were consulted. No durable project decision was added. Golden Set: not run; this check targeted input validation. Estimator recovery remains outside its scope.

## 12. Cross-Product Coverage

Covers: Julia `fit_laplace_reml()` effect-ID count and uniqueness for all supported families before fitting.

does NOT cover: R formula or bridge ID ordering, all payload-v2 ID contracts, estimator recovery, interval calibration, whole-wave sign-off, release readiness, or GPU execution.

## 1. Goal

Independently validate the streamed and completed output of the approved, frozen 200-seed ordinary-start FA campaign. Preserve every requested attempt in the denominator and prevent a partial stream from being reported as complete. Add a deterministic scientific check of weak FA information directions.

## 2. Implemented

Added a Python standard-library validator and synthetic negative-control suite. The validator checks the 23-column contract, primary seed order, source and driver fingerprints, outcome flags, class precedence, start diagnostics, terminal summary and final log marker. It independently calculates the recovery proportion, Monte Carlo standard error and Wilson interval. Partial mode produces an explicit partial result.

Added and registered a deterministic Julia test for an analytically known weak FA direction, its approach to nonidentification, and trait-unit/order transformations. This test uses fixed matrices and performs no optimization or simulation.

## 3a. Decisions and Rejected Alternatives

The campaign driver and Julia source stay frozen. Validation runs independently of Julia and does no fitting. Caller-supplied expected fingerprints are trust anchors. The scalar TSV cannot reconstruct the original covariance matrices or verify every hidden numeric value. Rounded threshold values and diagnostics serialized as `NA` require explicit ambiguity handling.

## 4. Files Touched

- `tools/validate_fa_ordinary_start.py`
- `tools/test_validate_fa_ordinary_start.py`
- `docs/dev-log/after-task/2026-09-30-fa-result-validator.md`
- `docs/dev-log/check-log.d/2026-09-30-fa-result-validator.md`
- `test/test_fa_weak_direction.jl`
- `test/runtests.jl`, one new include while preserving every prior line
- `docs/dev-log/source-review/2026-09-30-fa-weak-direction.md`
- `docs/dev-log/source-review/2026-09-30-fa-result-validator-independent-review.md`
- `docs/dev-log/source-review/2026-09-30-e1-current-coverage-reconciliation.md`
- `docs/dev-log/source-review/2026-09-30-placeholder-exact-review.md`
- `docs/dev-log/source-review/2026-09-30-a2-remaining-acceptance-design.md`

Separate panel receipts reconcile the 24 current Julia source files, accept the complete placeholder fallback/help contract, and define the remaining bounded A2 checks. Those reviews make no whole-programme completion claim.

## 5. Checks Run

The initial 19-test suite passed in the staged copy and again in the candidate. Independent review found a scalar-projection defect. The amended tool passed all 22 tests independently and again after candidate integration (0.397 seconds). An independently copied 19-row campaign snapshot passed partial validation with 11 recovered, 14 converged, 5 nonconverged, 2 G-error and 1 R-error outcomes. Complete mode rejected that snapshot with `completed mode requires all 200 seeds`.

Parent reran `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 julia --project=. --startup-file=no --compiled-modules=no test/test_fa_weak_direction.jl`: 36/36 new assertions and 4/4 existing helper assertions passed, exit 0. Estimate was under one minute. The analytic null had rank 17/18 and relative residual `1.4165e-17`; reducing epsilon from 0.01 to 0.001 contracted directional information by `0.00999835`. Unit/order and both scientific negative controls passed. This is expected information in natural covariance coordinates.

Final SHA-256 pins:

- Validator: `2b2d7d60c313180b0a0668cb7d51929bdccb95d80d8f1279cbcd27c578420abb`
- Python tests: `f407ea0b46cdfe8b5226e1b03c879f227518b733f3955957dbef79ef61ec863f`
- New Julia test: `158ae089596b4c2bcf9e1fd889e0777771776d11c417359a9aba350fe6b82b5c`
- Runner after registration: `b2d77c7f0937f5fcf0ed8ec32913c816b2c942f27c83825c8424107a5bc58b24`

Curie accepted the amended validator on the final exact pins. The initial faulty pins are superseded in the independent receipt. `git diff --check` passed. Full Julia `Pkg.test()` and hosted CI were not rerun for this slice; focused checks exercise the added tools and test. The after-task structure check passed; its combined acceptance check exited 1 because the programme and retained child ledgers still have unmet gates. Those gates were preserved.

Frozen Julia source fingerprint remained `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. Driver fingerprint remained `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`.

## 6. Tests of the Tests

Synthetic controls corrupt the hashes, seed stream, field count, booleans, outcome labels, summary statistics and completion marker. Truncated streams fail completed mode. An exception-only stream keeps all 200 attempts in its denominator. Threshold-boundary controls account for 12-significant-digit serialization. The independent reviewer also supplied a driver-producible overflow case omitted by the first implementation.

## 7a. Issue Ledger

Fixed: the first validator incorrectly treated all missing error metrics as having the same comparison behavior. The frozen driver serializes nonfinite scalars as `NA`; positive infinity, negative infinity and NaN have distinct Julia comparison outcomes. The repaired validator admits compatible hidden outcomes, records projection ambiguity separately, and rejects impossible recovery flags. Three new regression tests exercise these cases; independent exact re-review passed.

Programme gates A2, E1 and V3 remain open. This tool supplies campaign-closeout infrastructure.

## 8. Consistency Audit

The source and driver fingerprints agree with the approved campaign manifest. All 200 requested primary seeds remain the final denominator. Partial rates describe only the completed prefix. There is no preregistered campaign-level pass cutoff; validator success confirms output consistency and completion, without deciding a capability promotion.

## 9. What Did Not Go Smoothly

The independent review found the missing nonfinite-scalar projection case after the first 19 tests passed. A mistyped expected fingerprint was rejected during a parent command; rerunning with the correct pin succeeded. The prose checker resolves relative paths against the brain root, so the parent repeated it with absolute paths after the first invocation could not locate the reports.

## 10. Known Residuals

Full matrix finiteness, covariance errors and start objectives cannot be recomputed from the scalar TSV. A final log marker is one completion witness and does not authenticate remote host contents independently. Full source review, bridge defects, ordinary-start unit/order sensitivity and final candidate integration remain separate work. No GPU, submission or tag is part of this slice.

## 11. Team Learning

Active agents: Sol 6.1 High implemented the validator; Curie with Sol 6.1 High independently challenged its projection and denominator contracts; Rose with Sol 6.1 High reconciled exact-current coverage; Emmy with Sol 6.1 High reviewed the placeholder source; Kirkpatrick with Astra High designed the remaining FA checks. Parent reran tool tests and checked live campaign and source pins. A realistic serialization counterexample improved the validator beyond a passing synthetic suite.

## 12. Cross-Product Coverage

Covers: output validation for the frozen Gaussian T4/K1 primary campaign, including a partial-prefix mode and independent completion summaries; a deterministic expected-information weak-direction regression.

Does not cover: population interval calibration, loading inference, automatic rank selection, other FA cells, non-Gaussian recovery, public capability promotion, hosted CI or release readiness.

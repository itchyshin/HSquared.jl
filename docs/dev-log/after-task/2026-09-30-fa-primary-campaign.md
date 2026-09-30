## 1. Goal

Complete the approved frozen 200-seed ordinary-start Gaussian FA recovery campaign on Totoro CPU, preserve every outcome and verify the complete output. This closes campaign execution, not programme acceptance. A2, E1 and V3 remain open.

## 2. Implemented

All 200 ordered seeds completed. Raw TSV, log and PID, scalar validator summary, completion witness and artifact hashes are retained under `docs/dev-log/recovery-checkpoints/fa-primary-complete-20260930/`. The process is no longer present and the final log contains the WROTE completion marker. The live Julia source and driver were unchanged through completion.

## 3a. Decisions and Rejected Alternatives

Kept seeds 20261200:20261399, two ordinary starts, 5000 iterations per start, the original DGP and diagnostic thresholds. Retained all failures and flags. No seed replacement, primary restart, truth-start substitution, extra fit or retrospective campaign pass cutoff was used. The user approved the 18-hour estimate; measured per-seed runtime totals about 3 hours 53 minutes. No GPU work.

## 4. Files Touched

Added the final artifact directory, this report and its check-log entry. Updated the current programme pointer separately. Existing dirty engine, R, tests and documentation were preserved. Prepared fixes remain isolated and require composition and integration checks.

## 5. Checks Run

The existing strict independent scalar validator exited zero with complete status: 200 ordered unique seeds, 23 columns, matching metadata and final log marker. Source-tree SHA-256: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. Original driver SHA-256: `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`. Both local and Totoro recomputations matched at completion. Julia 1.10.0, four Julia threads and one BLAS thread. Remote PID lookup returned exit one with empty output after completion; the original launch-shell wait exit code is unavailable.

Outcomes: 110 recovered, 20 G errors, 11 R errors and 59 nonconverged. All 200 attempts remain in the denominator. Recovery rate 0.55, Monte Carlo standard error 0.03517812, Wilson 95% interval [0.48075615, 0.61735932]. There are zero recorded exceptions, nonfinite outcomes and below-truth-objective classes. The selected result converged in 141 rows. Both starts were valid in all rows; default converged 133 times and balanced 129 times. Total optimizer iterations across starts: 1371932.

Thirteen near-uniqueness-floor flags and two better-nonconverged-start flags remain visible, including six and one recovered rows respectively. Two scalar uniqueness-floor comparisons are rounding-ambiguous. Measured mean per-row runtime 69.75538 seconds, maximum 137.89158 seconds. The original conservative 14.4-hour stop/report bound was not reached.

## 6. Tests of the Tests

The validator already passed 22 adversarial standard-library tests, with an independent review retained in earlier receipts. It rejects incomplete or reordered streams, inconsistent declared pins and missing completion markers. Its count, Monte Carlo standard error and Wilson computations use every attempted seed. Full covariance matrices and objective reevaluation cannot be reconstructed from the scalar TSV; this is an explicit limit of its oracle.

## 7a. Issue Ledger

The recorded 59 nonconverged rows and 31 converged covariance-error classifications are measured limitations. The diagnostic thresholds were not preregistered as a campaign-level acceptance bar. The independent panel accepts the scientific diagnostic component for bounded experimental FA; whole A2 remains open for current-source comparator reconciliation, remaining engine/R spans, wording cleanup and whole-wave signoff. Its report is retained with the final artifacts. No new source defect was inferred from finite sampling errors alone, and no broad reliability claim follows from beating the generating likelihood.

## 8. Consistency Audit

The cell is complete balanced Gaussian data: 60 pedigree animals, four traits, one genetic factor, three records each, trait intercepts and an estimated unstructured residual covariance. This campaign is distinct from the five-case founder unit/order diagnostic, which uses 10000 iterations per start. Those five transformations are not replacement replicates. The FA genetic covariance includes uniqueness; the low-rank part alone is not the fitted full G.

## 9. What Did Not Go Smoothly

The initial transfer's macOS metadata files were removed before the same-source pre-run and before the primary launch; that earlier provenance is retained in the launch receipt. The completed primary had no restart or output corruption. Its 55 percent diagnostic recovery and 29.5 percent nonconvergence prevent a general optimizer-reliability claim.

## 10. Known Residuals

Whole A2 panel signoff, remaining source and bridge E1 review, reviewed repair integration, fresh package checks and final Rose audit V3 remain open. The full programme still has 8 of 11 gates met. No calibrated loading or uniqueness inference, broad rank support, missing-response support, automatic rank selection, release readiness or GPU completion is claimed.

## 11. Team Learning

Preserve the fixed primary denominator and distinguish solver convergence, covariance recovery and exact model identities. Independently validating the complete projection does not recreate the full fitted matrices. Golden Set: reused the approved fixed stream and existing adversarial validator. No Codex memory was updated.

## 12. Cross-Product Coverage

This report covers execution and scalar closeout of the frozen Gaussian T4/K1 complete-record pedigree recovery cell. It does NOT cover interval calibration, general optimization reliability, other ranks or families, whole engine approval, full R integration, public covered status, new submissions, tags or GPU execution. The next action is panel disposition of this evidence and isolated repair composition.

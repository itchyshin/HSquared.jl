# PR 495 scale-normalized numerical rank

## 1. Goal

Make the warning pre-check robust to nonzero rescaling of computed covariance columns.

## 2. Implemented

Each nonzero covariance column and the residual column are normalized before the
existing singular-value rank test. Scaling by the largest absolute entry first
avoids overflow when the column norm exceeds the Float64 range. Exactly zero
columns remain zero; nonfinite columns return the existing skip-check sentinel.

## 3a. Decisions and Rejected Alternatives

The `1e-8` relative SVD tolerance was retained. It now applies to normalized
column directions instead of raw component scales, which deliberately changes
numerical warning decisions for all existing callers. The check is numerical,
not a certificate of structural non-identifiability. No estimator, variance or
fit threshold was changed. We assumed skipping a nonfinite matrix is preferable
to an SVD failure, consistent with existing skipped checks.

## 4. Files Touched

`src/likelihood.jl`, `test/test_issue_416_sibling_fitters_warning.jl`,
`docs/src/changelog.md`, this report, the prior warning-correction report and
`docs/dev-log/check-log.d/2026-11-04-pr495-scale-normalized-rank.md`.

## 5. Checks Run

On Julia 1.12.6, BLAS threads 1 and Julia threads 2, the #416 sibling, existing
#416 and #424 files passed 82 assertions. The source-change test first failed
on the original raw-column rule. A Julia 1.10.12 smoke check of the
normalization arithmetic also passed; it did not load the package. Full package
CI is needed on the pushed head.

## 6. Tests of the Tests

The old rule returned rank 2, 3 and 1 for three independent columns when a
component was multiplied by `1e-12`, `1` and `1e12`; nonfinite values caused
an error. The new tests also cover zero columns, near-collinearity on either
side of the fixed tolerance, finite `1e308` values and a nonzero subnormal.

## 7a. Issue Ledger

Part of #416. The warning is now invariant to nonzero rescaling when the computed Float64 columns remain
finite and nonzero; no scientific status or issue closure is implied.

## 8. Consistency Audit

The shared helper feeds dense, sparse, matrix-free, repeatability and
direct-maternal checks. Each gets the same normalization; source docstrings and
changelog describe the revised rule. Independent mathematical review passed
22 no-fit cases and confirmed exact dependence preservation within the limits
below. Routed guidance and scoped ownership were checked. Golden Set was not
run because no hub guard was added.

## 9. What Did Not Go Smoothly

The original numerical threshold produced different rank results under a unit
change and could throw when the input matrix contained nonfinite values.

## 10. Known Residuals

A fixed tolerance can classify nearly dependent columns as deficient even when
they are mathematically independent. Angular numerical rank does not measure
practical estimator precision. Input rounding, overflow before the helper
is called and zero-variance components remain limits. Nonfinite columns skip
the check, so no warning is not evidence of identification. Full CI is
pending. The repo-root after-task validator has existing unmet `GATES.md`
entries; they were not changed.

## 11. Team Learning

Compare covariance directions at a common scale when a rank decision should not
depend on the units assigned to individual variance components.

## 12. Cross-Product Coverage

This covers the shared Julia rank pre-check on the stated algebraic fixtures and
existing focused tests. It does NOT cover R warning presentation, calibration,
non-Gaussian models, production-scale behavior or scientific acceptance gates.

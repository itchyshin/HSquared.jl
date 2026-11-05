# PR 485 uncertainty boundary guard

## 1. Goal

Make the new uncertainty bundle honor its documented boundary error.

## 2. Implemented

The bundle now lets the existing delta-interval helper check the heritability
boundary before calculating covariance. Interior fits still build it once.

## 3a. Decisions and Rejected Alternatives

Reused the existing boundary check instead of maintaining a duplicate. The
assumption is that its documented error precedence is appropriate for the bundle;
invalid fits with multiple defects may now report the boundary first.

## 4. Files Touched

`src/likelihood.jl`, `test/test_issue_408_variance_component_uncertainty.jl`,
this report, and `docs/dev-log/check-log.d/2026-11-04-pr485-boundary-guard.md`.

## 5. Checks Run

On Julia 1.12.6, BLAS threads 1 and Julia threads 2, the focused #408 and
#437 files passed 43 assertions. `bash tools/preamble_cap.sh` and
`git diff --check` passed. Full package CI is required on the pushed head.

## 6. Tests of the Tests

Before the fix, the new boundary test failed twice: it observed
`PosDefException` and one covariance call instead of the expected argument
error and zero calls. The original interior tests passed. The final test covers
both boundaries, non-convergence, ML and singular information.

## 7a. Issue Ledger

Addresses the new #408 bundle's boundary error. It does not close #408.

## 8. Consistency Audit

Independent bridge review found no blocking defect in the patch. The existing
interval helper owns the shared boundary rule. Routed project guidance and the
preflight/lease protocol were consulted; no capability row changed. Golden Set
was not run because this correction adds no hub guard.

## 9. What Did Not Go Smoothly

A rounded boundary on finite positive variances exposed a Cholesky exception
before the documented error. The original PR tests did not exercise it.

## 10. Known Residuals

The repo-root report validator also found existing unmet `GATES.md` entries;
the structure-only check passed from scratch. Those gates remain unchanged.
Hosted CI, merged-base compatibility and post-merge main checks remain pending.
The prior Windows timing-guard change remains weaker than its original bound.

## 11. Team Learning

Validate cheap domain conditions before expensive matrix construction, while
reusing the same validation path as the standalone API.

## 12. Cross-Product Coverage

This tests the Julia animal-model uncertainty bundle and selected invalid-fit
paths. It does NOT cover the R bridge, other model families, inference
calibration, performance, or scientific validation gates.

# PR 495 identifiability-warning correction

## 1. Goal

Make the #416 warnings accurately describe the information a numerical rank
check provides across the newly supported fitters.

## 2. Implemented

Warnings no longer attribute rank loss to a particular pair of effects, assert
an exact flat ridge, or promise a universal design remedy. They state numerical
rank, possible weak identification, and sensitivity to covariance scaling.
Adjacent Julia docstrings and the #416 changelog entry carry the same limitation.

## 3a. Decisions and Rejected Alternatives

The existing raw-column SVD threshold remains unchanged. Normalizing the columns
would change deployed warning decisions, including dense fitters, and needs its
own design and regression review. We assumed the generic warning was preferable
to a specific diagnosis the rank check cannot support.

## 4. Files Touched

`src/likelihood.jl`, `test/test_issue_416_sibling_fitters_warning.jl`,
`docs/src/changelog.md`, this report and the corresponding check-log shard.

## 5. Checks Run

Julia 1.12.6 with BLAS threads 1 and Julia threads 2: the sibling #416, existing
#416 and #424 focused test files passed 68 assertions. `git diff --check`
passed. Full package CI remains required on the final pushed head.

## 6. Tests of the Tests

Before the correction, no-fit warning assertions failed because the message
incorrectly named animal variance, prescribed cross-fostering and claimed an
exact flat ridge. The repeatability example independently shows animal and
permanent-environment covariance equal while permanent environment and residual
covariances are distinguishable.

## 7a. Issue Ledger

Part of #416: warning wording corrected. Scale sensitivity remains unresolved;
no claim closes the issue or upgrades validation status.

## 8. Consistency Audit

The matrix-free fitter calls the same warning helper and contains no additional
claim about its rank result. The affected sparse and direct-maternal docstrings
and changelog now state the numerical limits. The parent reviewed the diff.
Project routing and scoped ownership checks were consulted; no hub guard changed.
Golden Set was not run because no hub guard was added.

## 9. What Did Not Go Smoothly

The numerical rank check uses unnormalized columns: changing component units can
change its reported rank without changing structural dependence.

## 10. Known Residuals

The scale-sensitive threshold remains in place, so false positive or false
negative warnings are possible. A normalized-column alternative needs separate
review of scale, zero columns, nonfinite values and near-collinear cases. The repo-root report validator found existing unmet `GATES.md` entries after
the structure check passed; those gates are unchanged. Hosted CI and final
integration are pending.

## 11. Team Learning

Numerical rank alone cannot identify which component combination is deficient.

## 12. Cross-Product Coverage

This covers warning text for Julia dense, sparse, matrix-free, repeatability and
direct-maternal paths that use the common helper. It does NOT cover R warning
surfacing, changing the rank criterion, estimator recovery or calibration.

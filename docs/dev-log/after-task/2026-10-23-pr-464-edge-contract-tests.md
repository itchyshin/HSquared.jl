# After-task: refresh PR 464 edge-contract tests

## 1. Goal

Refresh the focused builder edge-contract test PR onto current `main`, preserve all current test includes, and record exactly which checks do and do not apply to the refreshed head.

## 2. Implemented

Merged current `main` at `500518bbedca86d79870807b6f39adcac5c23a4a` into PR #464's exact head `ba8f66289a6f34abc9e1c841b57de09b78c43d70`. Resolved one conflict in `test/runtests.jl` by retaining both the upstream `test_issue_340_lowrank_rotation.jl` include and this PR's `test_builders_gmax_legendre.jl` include.

Active lenses: performance review agent completed a read-only review of the test scope and current hosted evidence. The parent task integrated the branch. No other agent edited files.

## 3a. Decisions and Rejected Alternatives

Kept both test includes because they cover separate regressions. Did not rebase away upstream history or alter either test's assertions. Did not change the PR from draft while fresh checks are pending.

## 4. Files Touched

- `test/runtests.jl` for the conflict resolution.
- `docs/dev-log/check-log.md`.
- `docs/dev-log/after-task/2026-10-23-pr-464-edge-contract-tests.md`.

The existing new test file and its focused coverage are unchanged. No source, public documentation, capability-status, validation-debt, or coordination-board file changed.

## 5. Checks Run

- Live GitHub PR state before refresh: head `ba8f66289a6f34abc9e1c841b57de09b78c43d70`, draft, 3 commits ahead and 15 behind current `main`.
- Existing CI on the old merge ref passed all four Julia version and operating-system jobs. The opt-in live-draw check was skipped.
- Existing Documenter job built the documentation but failed at the `gh-pages` push because the remote branch had advanced. This does not validate the refreshed head.
- The refreshed branch targets current main commit `500518bbedca86d79870807b6f39adcac5c23a4a`. Fresh hosted checks have not yet run.
- `git diff --check` passed after resolving the include conflict.
- The after-task structure check passed. The full canonical check exited 1 because the repository-wide Arc 1 `GATES.md` still contains UNMET gates; that protected ledger is outside this test-only PR.

## 6. Tests of the Tests

Independent review found the test file included by the package runner and covering repeated-eigenvalue `g_max`, `legendre_design`, and `diagonal_covariance` edge contracts. The prior integrated CI executed the test suite successfully on its merge ref. The new current-main merge has not yet been tested, so no current-head test pass is claimed.

## 7a. Issue Ledger

PR #464 remains draft. Its isolated test scope has no reported assertion defect. Current-head Julia checks and a successful documentation deploy remain outstanding.

## 8. Consistency Audit

The conflict resolution preserves both the upstream test inclusion and this PR's test inclusion. No implementation behavior or fitted capability changes. `public_covered_count` and Arc 1 gate status are untouched.

## 9. What Did Not Go Smoothly

The test-runner include block conflicted while merging current main. The conflict involved distinct includes, so both were retained. The prior documentation deployment also encountered a non-fast-forward rejection on `gh-pages`; it must be checked again on the refreshed head.

## 10. Known Residuals

No tests or documentation workflow have run on the refreshed branch. The PR must remain unmerged until its new required checks settle successfully and GitHub reports it mergeable.

## 11. Team Learning

Test-only PRs can still require careful integration when several branches add includes to the shared test runner. Inspect both sides and preserve all distinct test modules. Next: push the refreshed branch to PR #464, then wait for and inspect Julia CI and Documenter results on that exact head. Merge only through the verified merge gate if the PR is no longer draft and every required check is settled green.

## 12. Cross-Product Coverage

This is a Julia test integration and branch refresh only. It does NOT cover or change `hsquared`, the R-Julia bridge, model behavior, scientific validation status, Arc 1 gates, GPU support, or release readiness.

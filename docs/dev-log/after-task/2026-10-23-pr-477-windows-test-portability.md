# After-task: PR 477 Windows test portability

## 1. Goal

Remove a platform-specific test failure from PR #477 while retaining a direct check that the upper-triangle finite-difference Hessian matches the former full-loop calculation.

## 2. Implemented

Removed hard-coded interval and point-estimate snapshots from the simulated direct-maternal fixture. The test still checks within-run agreement with the fitted model, positive standard errors, interval ordering and widths, and wider intervals at higher confidence levels. The separate deterministic Hessian test still checks exactly 40 objective evaluations and compares the new mirrored matrix against the old 64-evaluation loop.

No production source code changed.

## 3a. Decisions and Rejected Alternatives

Kept the deterministic formula comparison and same-run interval invariants. Rejected further tolerance widening: the failed Windows run differed materially in point estimates, so a small absolute tolerance would not address the observed failure and would leave brittle snapshots in place.

Assumptions made without asking: none.

## 4. Files Touched

- `test/runtests.jl`
- `docs/dev-log/after-task/2026-10-23-pr-477-windows-test-portability.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- Read the exact CI diagnostics for PR #477 head `403ab528cbe656ecbada740a7186f24e5a68f7ae`. The Julia 1.10 Windows job had 16 failures among 48 assertions, all from fixed numeric snapshots; the same-run fit/interval checks passed.
- `git diff --check`: passed after the test edit.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R /Users/z3437171/.codex/worktrees/pr477-portability/HSquared.jl/docs/dev-log/after-task/2026-10-23-pr-477-windows-test-portability.md`: structure passed; the checker warned that the acceptance ledger is not runnable in this checkout, so gate state is unknown.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py /Users/z3437171/.codex/worktrees/pr477-portability/HSquared.jl/docs/dev-log/after-task/2026-10-23-pr-477-windows-test-portability.md`: zero findings.
- Local Julia tests were not run because no Julia executable is available in this session (`julia: command not found`). Commit `8dc239c5fe2709540b583100e36800e9f3e93df8` has been pushed to PR #477; its Julia and Documenter checks are pending.

## 6. Tests of the Tests

The retained deterministic test counts calls and compares the upper-triangle helper with the former full-loop calculation on the same smooth function. Existing assertions in the simulated fixture check agreement among outputs from the same run rather than fixed platform-specific values. No mutation test was added.

## 7a. Issue Ledger

- Fixed: PR #477's Windows CI failure caused by cross-platform numeric snapshots.
- Unresolved: the reason the fitted values differ across environments was not isolated. The test now verifies mathematical equivalence of the changed Hessian loop without asserting one environment's fit values.

## 8. Consistency Audit

Reviewed the surrounding direct-maternal interval testset and the added Hessian test. The numerical properties, boundary checks, and objective-evaluation count remain covered. The diff changes only test assertions and comments; it does not alter the estimator, interval method, public API, or capability status.

## 9. What Did Not Go Smoothly

Julia was unavailable locally, so the revised test must be validated by hosted CI. An initial closeout-helper invocation routed a starter report into the brain Dropbox folder; that single file was removed immediately. No other brain or Dropbox working-tree files were changed.

## 10. Known Residuals

The revised test has not yet run on Julia. The updated PR head must pass its full CI matrix and documentation check before merge. The PR remains draft until that evidence is available. Updating the PR description through the GitHub connector returned HTTP 403; the same description correction was then applied successfully with the authenticated GitHub CLI.

## 11. Team Learning

For simulated numerical fixtures, prefer deterministic method-equivalence checks and same-run invariants over hard-coded outputs when supported environments produce materially different fits.

## 12. Cross-Product Coverage

This is a Julia test-only portability correction. It covers the direct-maternal Hessian helper and its interval test fixture. It does NOT cover the R package, R-Julia parity, statistical interval calibration, other interval methods, Arc 1 acceptance gates, capability promotion, or release readiness.

# After-task: issue 408 single information-matrix build without global instrumentation

## 1. Goal

Remove the production mutable global counter used only to test that `variance_components_plot_data` builds the information covariance once. Preserve the plotting-data results and prove one covariance-builder call through test-local instrumentation.

## 2. Implemented

Removed `_REML_INFO_CALLS` and its mutation from `_reml_information_matrix`. Extracted the existing plotting-data body into private `_variance_components_plot_data(fit, level, covariance_builder)`. The public `variance_components_plot_data` method delegates with `variance_component_covariance`; the test injects a local counting closure and verifies one call plus numerical parity with the standalone extractors. This is an internal testability seam; it does not change the public API or its claims.

Active lenses/agents: the PR review/performance agent implemented the focused source/test change, and the test-only review agent independently checked the diff and returned a clean PASS. The parent task coordinated ownership. No scientific-method review was needed because this change only replaces test instrumentation and preserves the existing calculation.

## 3a. Decisions and Rejected Alternatives

Kept the covariance reuse behavior at the caller that needs it and injected the builder privately for a deterministic call-count assertion. Rejected a process-global counter because concurrent tests or callers could race on shared mutable state. Did not introduce broader mocking infrastructure or alter the information-matrix calculation.

## 4. Files Touched

- `src/likelihood.jl`
- `test/test_issue_408_plot_data_single_information.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-23-issue-408-single-information-matrix.md`

`test/runtests.jl` already included the test on the exact PR head and was not changed. No coordination-board, capability-status, validation-debt, or public documentation files were changed.

## 5. Checks Run

- Focused Julia test `test/test_issue_408_plot_data_single_information.jl`: **7/7 passed** after the implementation. The preceding test-first run failed as expected because the private helper did not yet exist.
- Full `Pkg.test()` on Julia 1.10: **exit 0**, `Testing HSquared tests passed`; the included issue 408 testset passed **7/7**. Existing boundary/identifiability diagnostic warnings were emitted without test failures.
- `git diff --check`: passed after source/test changes and again during closeout.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-10-23-issue-408-single-information-matrix.md`: the after-task structure check passed, then the command exited 1 because the existing checkout `GATES.md` has UNMET gates. This closeout slice does not change or claim to complete the broader Arc 1 ledger.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py /Users/z3437171/.codex/worktrees/pr469-info-counter-fix/HSquared.jl/docs/dev-log/after-task/2026-10-23-issue-408-single-information-matrix.md`: exit 0, `FINDINGS: 0` (3 hits / 734 words, below the configured threshold).

The Julia dependency environment used the preserved task-specific depot `/private/tmp/hsquared-pr469-julia-depot`; the generated `Manifest.toml` was removed after testing because it was absent before instantiation. No dependency declaration changed.

## 6. Tests of the Tests

The test observes a local `Ref` owned by the test and passes its closure into the private helper. The assertion fails if the plotting-data operation calls the builder zero or multiple times, without mutating production-global state. The test also compares resulting interval values with standalone extractors. Test-first execution confirmed the new regression test fails before the helper implementation; after implementation it passed in both focused and full-suite runs. No broader mutation/corruption test harness was added.

## 7a. Issue Ledger

Issue 408's single information-matrix reuse assertion no longer relies on a mutable production global. The PR #469 local source/test slice is complete. No capability or validation-debt status change was made; the public covered count and scientific status are unchanged.

Coordination: work stayed in the dedicated PR #469 worktree at the exact assigned head. The R checkout and all other PR worktrees were left untouched. `test/runtests.jl` was not edited because the target test was already included. The coordination board remained untouched as protected.

## 8. Consistency Audit

The public method signature and returned plotting-data structure remain unchanged. Its covariance result is still computed once and reused for the same panel calculations, including the existing captured-exception behavior. The information-matrix calculation itself is unchanged apart from removal of the test counter increment. No public API or claim changed. The test file is already included by `test/runtests.jl` at the reviewed PR head.

## 9. What Did Not Go Smoothly

The isolated checkout initially needed dependency instantiation; the registry fetch reported a network DNS warning, then resolved from the existing cached registry. The package tests completed successfully. Process-list inspection was unavailable in the sandbox, so no process was killed or launched for inspection. The repo-local checker path was initially assumed but absent; the canonical checker was then located in the brain tools directory. An initial attempt invoked the R checker through Python and produced a Python syntax error; it was rerun using `Rscript`, the correct interpreter.

## 10. Known Residuals

This change proves one covariance-builder call in this plotting-data route; it does not establish thread-safety of unrelated package state or broader numerical correctness. Hosted CI and Documenter checks were not rerun for this local uncommitted diff. At last remote read, CI was green and Documenter was still running on the pre-fix PR head; neither status validates these local edits. No commit, push, PR metadata change, or merge was performed.

## 11. Team Learning

Call-count tests should instrument the narrow operation at the call site with test-owned state, rather than mutate a process-global counter in numerical production code. Before reporting a canonical checker missing, check the repo and the central tools location named by the operating contract.

Next action: the owner released the lane overlap and authorized continuing PR triage. Transfer this reviewed patch to PR #469, wait for checks on the new head, and use the verified merge gate only if every required check settles green. At the time of this report update, no commit, push, merge, or PR metadata change has occurred.

## 12. Cross-Product Coverage

This is a Julia-internal testability and concurrency-safety repair for issue 408. It does NOT cover the R package, the R-Julia bridge, other information-matrix callers, scientific capability validation, performance benchmarking, release readiness, or hosted checks on this local diff. The global after-task validator's structure phase passed, but its full command remains non-green because the pre-existing Arc 1 `GATES.md` ledger contains unmet gates outside this slice.

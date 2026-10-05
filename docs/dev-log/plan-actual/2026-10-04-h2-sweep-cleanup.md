# Plan versus actual: H2 sweep cleanup, 4 Oct 2026

Rose, then Melissa. Worktrees only. No covered-status flip.

## Rose

No what-passed issue was filed. The 3 Oct receipts are absent, and the tracker comments on hsquared#304 and HSquared.jl#431 say so. Those comments bucket open issues. They do not say a route passed or is covered.

`validation_status` is unchanged. The help text for `hs_control()` now says the default `cbind()` path forwards `max_dense_cells` and errors above the cap. That sentence matches the new test. It does not move a row to covered.

## Melissa

Plan: safe maximum. Fix hsquared#267, #303, #321, #323 and HSquared.jl#442, #443. Triage the other open issues on the two trackers. File what-passed only from receipts.

Actual:

- Receipts absent. What-passed stays unfiled. Comments: hsquared#304#issuecomment-5980689447 and HSquared.jl#431#issuecomment-5980689613.
- Triage comments: hsquared#304#issuecomment-5980689777 (5 + 1 + 0 + 71 = 77) and HSquared.jl#431#issuecomment-5980690067 (2 + 0 + 7 + 74 = 83). Recounted against `gh issue list` after posting.
- R tests in `tests/testthat/test-ignored-arguments-sweep.R`: 7 failures on unmodified `origin/main` sources, then 8 passes and 1 warning after the fix. The warning is the existing cbind experimental warning, which still prints on the error path.
- Julia tests in `test/test_sweep_dense_and_newton.jl`: failures on unmodified sources (missing `max_dense_cells`, and `SingularException` on the undamped Poisson step), then 9 passes after the fix. `test/wave2_nongaussian_contracts.jl` then passed (149 checks across its testsets).
- Local commits on `cursor/h2-sweep-cleanup-20261004`. No push, no merge.

Deviations, all adaptive:

- #321 is fixed in `hs_parse_animal_call` (`R/model-spec.R`). `animal()` itself is not evaluated inside a formula.
- The Julia worktree is `~/local-scratch/hsqjl-sweep-cleanup-20261004`. The planned `HSquared-sweep-cleanup` path is the same folder as the R worktree on a case-insensitive disk.
- The Newton fixture uses a Poisson count of 150 and 30 iterations, the case sketched on HSquared.jl#442. A count of 20 still converged after damping and did not separate the old step from the new one.
- Univariate `engine = "fit"` still does not apply `max_dense_cells`. That path is sparse AI-REML. The help text says so.

Left as the plan left them: the other open issues, the 0.9 pull requests, Codex's multivariate screen, and any claim that AI-REML works past the default fit.

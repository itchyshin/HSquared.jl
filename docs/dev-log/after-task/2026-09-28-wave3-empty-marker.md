## 1. Goal

Fix the `data_status()` failure for an accepted empty marker map and retain a focused regression test.

## 2. Implemented

- `data_status()` now reports both position bounds as unavailable when a marker map is empty; marker and chromosome counts remain zero.
- Added a real `HSData` regression test for the empty-map input.
- Independent Henderson review found no animal-model blocker in the assigned pedigree spans. The empty-map diagnostics issue was reproduced and fixed here.

Active lens: Henderson (animal-model and pedigree input review). Read-only neighboring review: Gauss (non-Gaussian engine), Hopper (FA bridge test contract). Spawned agents: `wave3_pedigree_input_review`, `wave2_nongaussian_review`, and `fa_start_diagnostics_test_review`.

## 3a. Decisions and Rejected Alternatives

Keep empty marker metadata accepted. An empty map has valid zero counts but no minimum or maximum position, so those two fields return `not_available`. Rejecting the map would change constructor behavior without improving model fitting.

## 4. Files Touched

- `src/data.jl`
- `test/test_data_empty_marker_status.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-28-wave3-empty-marker.md`

## 5. Checks Run

- Red: `julia --compiled-modules=no --project=. test/test_data_empty_marker_status.jl` errored at `minimum(empty)` in `_data_marker_status`.
- Green: the same command passed, 2/2 assertions, after the guard.
- `git diff --check -- src/data.jl test/test_data_empty_marker_status.jl` passed.
- The test is not yet included in `test/runtests.jl`; that file is held by the active Wave 2 review lane. Full `Pkg.test()` and CI were not run on this change.

## 6. Tests of the Tests

The test was run against the unfixed source first and failed with the exact empty-reduction `MethodError` in `minimum(marker_spec.position)`. After the fix, it passed and asserted all seven marker-status rows, including zero counts and unavailable position bounds.

## 7a. Issue Ledger

- **Fixed:** empty marker maps caused `data_status()` to throw while computing position bounds.
- **Open:** wire the test into the standard test entry point when `test/runtests.jl` is released by its current owner.
- **Carried:** the independent Gauss review identified unresolved variational covariance convergence, separation, profile-interval, ID-validation, and objective-label findings in `src/nongaussian.jl`. Those findings are outside this fix and keep the broader source-review wave on HOLD.

## 8. Consistency Audit

Searched `src/data.jl` for `minimum`, `maximum`, `first`, `last`, `mean`, and `reduce`. The only such reductions are the two guarded position bounds. This change does not alter marker alignment, genotype counts, pedigree calculations, or model fitting. No full neighboring HSData test set was run.

## 9. What Did Not Go Smoothly

- The first follow-up command referenced a nonexistent test file after the new test itself had passed; the intended test was then rerun alone successfully.
- The closeout generator could not write to this managed worktree through the shell sandbox. This report follows its required section template. The structure check passed, but integrated acceptance-ledger re-verification could not complete: GATES V1/V2 test commands hit Julia-cache `EPERM`, and the checker could not write its `.unlazy/locks` file. GATES is held by the active evidence lane.
- JuliaCall’s R-side live test attempt was blocked by sandbox permissions on the Julia compiled cache; no R–Julia fit evidence is claimed.

## 10. Known Residuals

The new regression is a standalone test file and is not yet reached by `Pkg.test()`. The exact candidate has no full package-test, documentation-build, or CI evidence from this slice. This bounded fix does not close Wave 3, the whole-engine review, the FA bridge diagnostics work, or any release gate.

## 11. Team Learning

Diagnostics should define empty-input behavior explicitly: a zero count is meaningful, while a position bound over no markers is unavailable. Test accepted empty metadata through the public status API, not only through private validators.

Memory receipt: loaded the `HSquared.jl` LOAD-FIRST manifest, repository instructions, and `validation-harness`; they directed the isolated input test and explicit limits. No sibling-project research was performed.

Golden Set: not run; this diagnostic edge case is not a genetic estimator or known-model recovery case.

## 12. Cross-Product Coverage

Covers: Julia `HSData` marker-status position bounds for an accepted empty marker map.

Does NOT cover: R `data_status()`, marker/genotype alignment, marker-effect fitting, FA or GLLVM bridge behavior, non-Gaussian estimator validity, arbitrary-depth pedigrees, GPU execution, release submission, or public capability promotion.

## 1. Goal

Repair the experimental Julia genomic REML boundary classifier's false lower-boundary result for a strict interior optimum near zero. Reject malformed provenance and convert known numerical factorization failures into unresolved results.

## 2. Implemented

- Added the analytic derivative of the profiled REML objective at both domain endpoints, preserving the frozen KKT signs.
- Kept the refined likelihood in endpoint comparisons when its ratio is within the strict-interior epsilon. Such a fit is unresolved if the refined candidate beats an endpoint.
- Added finite-string checks for relationship source and fingerprint provenance before comparisons.
- Added a narrow wrapper for `PosDefException`, `SingularException`, `LAPACKException`, and sparse `ZeroPivotException`. Other exceptions are rethrown.
- Added the current-candidate amendment in design 59. Frozen design 46 and its historical hash are unchanged.
- No capability status, validation-debt status, public claim, or covered count was promoted.

## 3a. Decisions and Rejected Alternatives

- Retained the frozen design 46 unchanged. The analytic endpoint score is documented as a current-candidate amendment in design 59; the historical holdout is not treated as evidence for the changed algorithm.
- Returned `boundary_unresolved` for a refined strict optimum inside the boundary epsilon. Reporting it as an exact endpoint would be wrong, while reporting it as strict interior would contradict the declared epsilon.
- Caught only known linear-algebra factorization exceptions. Invalid controls and programming errors, including `ArgumentError`, remain visible.

## 4. Files Touched

- `src/likelihood.jl`
- `test/runtests.jl`
- `test/wave4_genomic_boundary_near_endpoint.jl`
- `docs/design/59-v07-genomic-boundary-score-amendment.md`
- `docs/design/capability-status.md`
- `GATES.md`
- `docs/dev-log/source-review/2026-09-29-wave4-boundary-followup.md`
- `docs/dev-log/check-log.d/2026-09-29-wave4-boundary-followup.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-genomic-boundary-classifier.md`

## 5. Checks Run

- `JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia julia --project=. test/wave4_genomic_boundary_near_endpoint.jl`: 19/19 passed after final test edits.
- Full `Pkg.test()` on Julia 1.10.0 passed and includes the final 19/19 amendment testset; output ended `Testing HSquared tests passed`. The existing Project/Manifest mismatch warning appeared. No resolve or update was run.
- `git diff --check`: passed.
- `python3 /Users/z3437171/shinichi-brain/tools/memory_regression.py --selftest`: passed; every detector discriminated.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-09-29-genomic-boundary-classifier.md`: structural check passed; integrated acceptance ledger still reports five open programme gates (`hsq-fa-closeout`, `hsq-gllvm-foundation`, `hsq-w105`, `hsq-wave2-bridge`, and root `GATES.md`). This bounded slice did not close or abandon those ledgers.
- `python3 tools/closeout.py new ...` could not create this report because the helper resolved the Git common directory to the protected Dropbox parent. The report was written in the authorized worktree and validated with the R structure checker.
- No simulation, GPU execution, docs build, hosted CI, release submission, registry submission, merge, or tag was run.

## 6. Tests of the Tests

- Before the implementation change, the near-endpoint fixture returned `boundary_lower`; the expected `boundary_unresolved` assertion failed.
- The analytic-score assertion was run before the helper existed and failed with `UndefVarError`.
- Missing relationship source reproduced `TypeError: non-boolean (Missing) used in boolean context` before the provenance guard was added.
- The numerical guard assertion was run before the helper existed and failed with `UndefVarError`. Its final test confirms a positive-definite factorization error is converted to an unresolved result and an `ArgumentError` is rethrown.
- The near-endpoint test also confirms that the frozen `delta = 1e-6` secant has the opposite sign in the counterexample, while the refined candidate prevents the false boundary classification.

## 7a. Issue Ledger

- Fixed: strict interior REML maximum within `1e-7` of zero could be reported as `boundary_lower`.
- Fixed: missing and non-string source/fingerprint provenance could throw during Boolean comparisons.
- Fixed: named numerical factorization failures could escape the closed-boundary wrapper.
- Open: independent matched R-oracle comparison for the amended endpoint score and endpoint-adjacent comparison; near-upper-endpoint regression; wider source-review wave and panel signoff; FA/GLLVM acceptance gates A2, E1, and V3.

## 8. Consistency Audit

The exact lower and upper derivative signs agree with the profiled REML objective, and the fixed-effect trace correction is included. The test checks the lower counterexample, both endpoint scores against one-sided finite differences with two fixed-effect columns, provenance values, and exception pass-through. The test is included in `test/runtests.jl`. Design 46 remains sealed; design 59 states what changed and which historical evidence no longer transfers. Capability status now identifies the frozen historical candidate and links design 59; no fitted capability or validation-debt status changed.

## 9. What Did Not Go Smoothly

Julia initially attempted to write a compiled cache under the protected home depot. The tests ran after routing the writable cache to `/private/tmp/hsq-julia-depot`. The closeout template helper also resolved the Git common directory to the protected Dropbox parent; no external file was created, and the report was written in the authorized worktree. The initial preflight surfaced a stale 15-day handover note; the current coordination board assigns the active branch and source span to Codex, and the census showed one active lane.

## 10. Known Residuals

The frozen doc-46 holdout does not validate the amended analytic-score rule. No matched R oracle, broad endpoint calibration, near-upper-endpoint recovery, or whole-file/E1 signoff is established. The source-review report records these limits. No GPU work or release action occurred.

## 11. Team Learning

The independent numerical review found that a finite-difference step can cross a very sharp local maximum and reverse an endpoint score. The review also caught the contract mismatch with the frozen algorithm before closeout. Treat candidate-specific math changes as explicit amendments and keep historical holdouts attached only to the exact algorithm they tested.

Memory receipt: The first `route.py` call did not resolve the worktree path and no LOAD-FIRST manifest was loaded. The explicit lane preflight, current coordination board, and repository review packets established the active source scope. The Golden-Set memory regression self-test passed. No external literature or sister-project scout was run.

## 12. Cross-Product Coverage

This covers only the experimental Julia genomic REML closed-boundary resolver and its registered tests. It does NOT cover the R bridge, public/default fitting, genomic calibration, broad estimator reliability, other likelihood paths, FA or GLLVM acceptance, unusual inheritance, CUDA/GPU, or any release or registry action.

# Arc 1 resumed: launcher cleanup and G8 crosswalk

## 1. Goal

Resume Arc 1 from its retained checkpoint, repair bounded Julia launcher cleanup after review found an exited process-group leader could leave descendants alive, and reconcile current gate receipts to the frozen G0–G8 ledger without changing gate status.

## 2. Implemented

Process cleanup now signals and checks the process group even after its leader exits, uses bounded TERM and KILL waits, and bounds post-cleanup stream collection. Timeout results record whether cleanup was confirmed and whether output streams were complete. A regression test starts a live descendant, waits for its group leader to exit, then verifies cleanup removes the group. A provisional G8 crosswalk now maps each frozen gate to its current receipt and names the missing study bundles and independent pins; it records no G8 credit.

## 3a. Decisions and Rejected Alternatives

Kept the repair inside the existing launcher. Did not run the outer-4 candidate: its seed was already consumed, and the adopted G2 decision excludes N=80/null indices 1–30. The separately reviewed outer-31 tranche proposal requires owner approval before manifest edits or numerical execution.

## 4. Files Touched

- `sim/arc1/run_cell.py`
- `test/test_arc1_executor.py`
- `docs/dev-log/after-task/2026-10-09-g8-plan-to-artifact-crosswalk.md`
- `docs/dev-log/after-task/2026-10-09-g2-launcher-process-group-cleanup.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`

## 5. Checks Run

- `python3 test/test_arc1_executor.py` : PASS, 6 tests.
- `python3 -m py_compile sim/arc1/run_cell.py test/test_arc1_executor.py` : PASS.
- `git diff --check` : PASS.
- `python3 tools/arc1_manifest.py --validate-only` : PASS before this repair; 644,480 unique seed allocations. No allocation or fit was started.
- Astra exact-source review : PASS. Final hashes: `run_cell.py` `663148b42ae5945ccaa706bc065a1f46c8829ab217a694bb855dcad628f2639c`; `test_arc1_executor.py` `d0eed4d1ddae10f67706b2dd59647aef1d840c57eee4099c81902b933aa6fc88`. The reviewer confirmed the test-only import/refactor did not change behavior. Scope excludes ordinary-success descendant detection.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <absolute report path>` : structure PASS; overall closeout returns nonzero because the three Arc 1/FA-rank/H2 GATES ledgers remain unmet.
- `python3 ~/shinichi-brain/tools/slop_check.py <absolute report path>` : PASS, zero findings.
- `python3 ~/shinichi-brain/tools/memory_regression.py --selftest` : PASS; all detectors discriminate their fixtures.
- `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --status --scope arc1-gaussian-reliability` : four gates checked (G0, G1, G6, G7); five remain unmet (G2–G5, G8).

## 6. Tests of the Tests

The new regression failed against the original code because `_stop_process_group` returned when the leader had exited, leaving the descendant alive. After the repair it passed, along with the full launcher test file.

## 7a. Issue Ledger

- Fixed: exited process-group leaders no longer bypass descendant cleanup.
- Open: the successful-exit path does not check for descendants that close their output streams; the reviewer explicitly limited the PASS to timeout/interruption cleanup.
- Held: G2 fresh development. All indices 1–30 are exhausted. The existing independent proposal for an amended-source tranche at indices 31–60 across nine cells is reviewed PASS but awaits owner approval before manifest changes and the N=80/null outer-31 pre-run.

## 8. Consistency Audit

Checked all direct callers of `execute_cli`, the launcher tests, the current-source manifest validator, the frozen acceptance ledger, and the approved-plan checklist. The production source pins in the rejected outer-4 admission are now stale because `run_cell.py` changed; that admission remains unusable regardless of its consumed seed. The adopted six-split method decision and the fresh-tranche review both preserve source-version separation and prohibit replacement seeds. G8 still needs G2–G5 study evidence and final-source scientific review.

## 9. What Did Not Go Smoothly

The first fresh admission targeted outer 4 based on an incomplete seed-availability assumption. Independent review found a retained start and result for that index. No model fit occurred; the candidate is held and must not be reused.

## 10. Known Residuals

This repair does not complete a statistical gate. The full Arc 1 goal remains active; G2 and the other open gates remain open. No G2 campaign or pre-run was launched. The owner must approve the fresh 31–60 tranche before its manifest update and pre-run. The current cleanup contract is bounded for timeout and interruption paths; it does not detect every possible descendant after an ordinary successful exit.

## 11. Team Learning

LOAD-FIRST was unavailable for this managed worktree; repository instructions, Graft, and the retained Arc 1 records governed the work. The process-group descendant defect was tested directly. The brain Golden Set self-test was run. Astra's read-only review shaped the runner repair and stopped use of a consumed seed.

Naturalness assessment: 6/10, medium confidence. Genre/coverage: whole short engineering closeout report. Evidence/repair: the required numbered closeout structure is repetitive, but each section has a distinct evidence function; no change needed because the template is mandatory. Gates: science = not applicable because no scientific model claim is made; facts = pass for file hashes and command outputs; references = pass for local evidence paths, with no external citations. Provenance: self-review of report v1, 2026-10-09; no held-out style controls were used.

## 12. Cross-Product Coverage

Covers ✓: Julia Arc 1 single-attempt launcher timeout and interruption cleanup, with focused Python transport tests; a current-status crosswalk from the frozen G0–G8 acceptance ledger to retained receipts. does NOT cover: R execution or parity beyond the separately retained G6 receipt, ordinary-success descendant detection, model fit reliability, seed allocation, G2–G5 qualification, final G8 review, any pilot or confirmation study, or overall H2 completion.

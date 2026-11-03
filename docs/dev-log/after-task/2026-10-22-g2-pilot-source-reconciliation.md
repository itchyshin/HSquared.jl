## 1. Goal

Reconcile locally retained Arc 1 FA-rank admissions with their source locks, and determine whether the owner-approved post-outcome 24-of-30 exploratory pilot screen can be applied to existing evidence without running fits.

## 2. Implemented

Completed a read-only inventory of local Arc 1 admission directories and source-lock matches. Reconstructed the admission-pinned 1,275-file source root in a separate `/private/tmp` directory, leaving the recovery tree untouched. Of those files, 1,270 were copied from the recovery tree and five were restored from a matching retained source snapshot; every reconstructed file was checked against the admission hash. The frozen `verify_run_admission` function then passed for all 14 admissions against this root. The admissions remain marked `admitted_before_execution`; the source reconstruction does not prove execution or produce fit results. The 24-of-30 policy implementation was not changed in this slice. This slice launched no fits or seed runs, opened no result bodies, and changed no gate status.

The local `/private/tmp/arc1-g2-pilot-20261020-admissions` contains 14 N80/null pilot admissions. Their 1,275 source pins matched the current recovery tree for 1,270 files, with five mismatches. In the attached worktree, 143 pins matched, 41 mismatched, and 1,091 paths were missing. The reconstructed root is `/private/tmp/arc1-g2-pilot-20261020-source-reconstructed-20261022-v1`; its manifest hash is `b0f30c66132b9fd21c02ce7b6fe2b317eb592b32e48ce23c989d85505e1d3822`. The companion receipt is `/private/tmp/arc1-g2-pilot-20261020-source-reconstructed-20261022-v1.receipt.json`.

The local four-file N80/null pilot admission set under `/private/tmp/arc1-g2-n80-null-frozen-20261021-admissions` has 156 source pins per admission; all 156 match `/private/tmp/arc1-g2-n80-null-frozen-20261021-stage`. Those four admissions are also marked `admitted_before_execution`, so they do not establish that any fit ran. A retained tally reports 14 N80/null pilot outputs on Totoro, 12 successful and two failed, but does not provide the complete nine-cell receipt bundle required by the gate. A separate note reports 25/30 usable in an N80/null series; this slice did not verify that tally against a complete, source-bound receipt, so it is not scored as passing the amended screen.

The remaining cell-specific admission directories inspected here, outside N80/null pilot, contain development-phase admissions only. No complete nine-cell pilot receipts-and-pins bundle was found in the searched locations. The amended screen therefore has no new study score and no gate credit.

## 3a. Decisions and Rejected Alternatives

Kept 24/30 as a separately labelled, post-outcome exploratory feasibility screen. The frozen 29/30 rule remains the baseline. Did not treat source-matching admissions as evidence of executed fits, combine admissions from different source roots, or infer reference-audit success from the retained usability tally.

## 4. Files Touched

- `docs/dev-log/after-task/2026-10-22-g2-pilot-source-reconciliation.md` (managed worktree report)
- `/private/tmp/arc1-g2-pilot-20261020-source-reconstructed-20261022-v1/` (1,275 admission-pinned files)
- `/private/tmp/arc1-g2-pilot-20261020-source-reconstructed-20261022-v1.receipt.json`

No protected file, recovery-tree file, Dropbox checkout, or source file was edited.

## 5. Checks Run

- `bash ~/shinichi-brain/tools/lane_preflight.sh "$PWD" --file docs/dev-log/after-task/2026-10-22-g2-pilot-source-reconciliation.md`: identified the new report path as untracked and unowned; also reported foreign lanes and existing unrelated leases. A path-scoped lease for this report was then granted with elevated filesystem access.
- Read-only Python inventory of local admission JSON metadata: found only `admitted_before_execution` status in the inspected admission sets.
- SHA-256 comparison of the 156-file source lock for the N80/null frozen-stage admissions: 156/156 matched the stage; 152/156 matched the recovery tree; 115 matched, 36 mismatched, and 5 were missing in the attached worktree.
- SHA-256 comparison of the 1,275-file N80/null pilot admission map: 1,270 matched, 5 mismatched in the recovery tree; 143 matched, 41 mismatched, and 1,091 were missing in the attached worktree.
- Reconstructed all 1,275 pinned files from local retained copies, then verified every resulting SHA-256 against the admissions. The frozen `verify_run_admission` passed for 14/14 admissions at that reconstructed source root; protocol SHA-256 was `5ff8c489f263f72eb2762ed9345b0c8f2f9ff333fb32fc37eeae254a86aaae4d`.
- Independent post-copy audit found exactly 1,275 files, all 1,275 matching pins; the retained source-map and root-manifest hashes both matched the reconstruction receipt.
- Remote inventory commands were sent with `-S` pointing at the existing Totoro socket and reported 14 outer directories and 112 files in the named pilot output directory. A later request returned `session open refused by peer` while also emitting a directory inventory. Since the commands used `ControlMaster=no`, I cannot rule out fallback to a fresh connection after a socket refusal. No further remote access was attempted.
- `Rscript tools/check-after-task.R ...` and `python3 tools/evidence_gate.py` could not run from this worktree because those files are absent here. `Rscript ~/shinichi-brain/tools/check-after-task.R <absolute-report-path>` passed the report structure check. The generic closeout helper was not used for a final check because its root resolves through the Dropbox-backed brain path.
- `python3 ~/shinichi-brain/tools/slop_check.py <absolute-report-path>`: passed with zero findings. `git diff --check`: passed.
- No fits, bootstrap runs, consumed-seed reruns, or K1 reference-grid reruns were performed.

## 6. Tests of the Tests

The eight synthetic amendment tests and two existing rank-gate regression tests passed in the preceding slice. No test code or amendment implementation changed in this slice, so those tests were not rerun. No study receipt was submitted to the amendment evaluator.

## 7a. Issue Ledger

- Open: the full nine-cell pilot receipt bundle and independent pins are not present in the searched local locations.
- Open: the 1,275-file pilot source lock does not match five files in the current recovery tree. The attached worktree is a different source identity.
- Open: the retained 24/30 usability result does not establish expanded-reference maxima for all required ranks.
- No issue was created in an external tracker. No gate or capability status changed.

## 8. Consistency Audit

The frozen experiment manifest remains at 29/30. The separate 24/30 policy remains exploratory and cannot admit confirmation. G2 through G8 remain open. `public_covered_count` remains 7 and v7 remains HOLD. No missing reference maximum was converted to a pass.

## 9. What Did Not Go Smoothly

The repository-level closeout helper resolved its root through the Dropbox-backed brain path and attempted to create the report there. That write was denied. I did not retry against Dropbox; this report was created directly in the authorized managed worktree. The first lane-lease attempt also lacked permission to write the shared registry; after the required escalation, the report-only lease was granted and then released. A redundant release call matched a legacy lease named `codex-pr-cleanup-462` by session PID; that lease had not appeared among the live claims in preflight. No repository files were changed by the release call.

## 10. Known Residuals

The exact bytes pinned by the 14 N80/null admissions are now available in a separate reconstructed source root. The completed receipts, independent pins, and reference audits for all nine pilot cells are still missing from an authorized local path before the amended evaluator can be run. The remote request boundary is uncertain: a command addressed to the existing socket reported a session refusal but returned directory output, so I cannot establish that no fresh connection was opened. G2 remains open, and no other gate is changed by this report.

## 11. Team Learning

An admission pins a planned execution; it does not prove that execution occurred. Check both source hashes and execution status before treating a candidate as evidence. Keep pilot feasibility thresholds separate from frozen confirmation requirements.

Memory receipt: the Shinichi-brain search for the Arc 1 source-lock and threshold decision returned no results; local repository instructions and retained artifacts were used as the governing evidence.

Golden Set: not run. This slice changed no engine behavior and made no capability claim.

## 12. Cross-Product Coverage

Covers: local Arc 1 pilot admission and source-lock reconciliation, plus the boundary on applying the exploratory 24/30 screen.

Does NOT cover: completed pilot scoring, expanded-reference audits, confirmation, new model fits, the R-Julia parity gate, G2 through G8 closure, or completion of the wider non-GPU HSquared project.

# G2 v13 bounded admission and preflight

## 1. Goal

Prepare the exact-source G2 N80/null outer32 singleton admission for owner review. This slice must not launch a fit without exact owner approval.

## 2. Implemented

Created v13 of the nine-cell G2 admission candidate, ran its offline tests, obtained an independent Astra PASS bound to its candidate and source-lock hashes, and staged the exact 306 pinned source files plus five candidate-support files in a fresh isolated Totoro directory. The exact remote no-launch preflight passed. No study attempt, fit, or seed consumption occurred.

## 3a. Decisions and Rejected Alternatives

Kept v12 unchanged because the earlier checkpoint edit made its source lock stale. Created v13 rather than editing the reviewed artifact. The outer32 attempt remains separate from the later 268 seeds and gives no gate credit by itself. No owner approval receipt was manufactured from a general instruction to continue.

## 4. Files Touched

- Added builder, executor, tests, candidate JSON, and source lock under `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v13/`.
- Added the independent review record and Totoro runtime/preflight record in the same directory.
- Staged the 311-file bundle at `/home/snakagaw/hsq_work/arc1-g2-development-nine-cell-20261010/source-v13/`.
- No package source, seed manifest, gate ledger, or checkpoint changed in this slice.

## 5. Checks Run

- V13 offline candidate suite: 19/19 passed in 67.770 seconds.
- Astra independent review: PASS for candidate SHA-256 `26668e32e3ff0caf9fb923723d072709c6f3aae77d288e630172f93528000edf` and source-lock SHA-256 `051d10957ddcf87b2bd4dde65b7f3daf396df7b0400b8623290d6a3917e3df17`.
- Totoro no-launch preflight: `PREFLIGHT_PASS_NO_LAUNCH`; all 306 pins matched.
- Totoro Julia 1.10.0, project/manifest hashes, output-parent safety, and current disk/memory were checked through the existing ControlMaster socket.
- `git diff --check` and `slop_check.py` on both prose evidence files passed.
- The after-task structure check passed. Its completion phase correctly exited 1 because Arc 1 and the parent automatic-rank/non-GPU ledgers have unmet gates.

## 6. Tests of the Tests

The 19 candidate tests include mutated source and candidate locks, path collisions and symlinks, outer31/outer33 and tranche-scope rejection, missing or mismatched receipts, retained failed and started-only attempts, and a mocked singleton launch that never invokes Julia. No study code was executed.

## 7a. Issue Ledger

- G2 remains open. The exact owner approval receipt is pending.
- G3, G4, G5, and G8 remain open.
- Current recorded G0, G1, G6, and G7 statuses are unchanged.
- The original candidate preflight on macOS refused `/home` because that component resolves through a local symlink. Repeating the exact candidate preflight on Totoro passed.

## 8. Consistency Audit

The candidate names exactly one N80/null outer32 seed, `18043834289602542821`. Review and owner approval remain separate receipts. The target output directory was not created. The remote source staging directory is isolated from the earlier shared source snapshot. No gate checkbox or public capability claim changed; covered count remains seven and capability remains experimental.

## 9. What Did Not Go Smoothly

The first Totoro shell probe found Julia 1.12.7 on the default search path and exited before later checks. A bounded follow-up found the lane-pinned Julia 1.10.0 executable and verified its version. The local candidate wrapper also cannot validate a Totoro absolute path because of the Mac `/home` symlink, so its no-launch check had to run on Totoro.

## 10. Known Residuals

The exact owner approval is not present. No fit or seed attempt has started. If approved, rerun the candidate no-launch check against the staged source, then launch only outer32 with both exact receipts. This singleton does not authorize or qualify the remaining development tranche, pilot, or confirmation campaign. Campaign estimates and any required approvals remain separate.

## 11. Team Learning

For a remote singleton admission, check the execution host's pinned runtime and output-path components there. A local symlink result does not describe the remote path. Keep candidate review, owner authorization, environment preflight, and launch as separate evidence.

Naturalness assessment: automated check found 0 hits per 1,000 words. Scientific gate: no model result. Factual gate: exact hashes and outputs recorded above. Reference gate: evidence paths are local and bounded to this candidate.

## 12. Cross-Product Coverage

Covers: a Julia-only G2 singleton admission candidate and its Totoro preflight.

Does not cover: G2 reliability, automatic-rank confirmation, FA or repeatability interval calibration, R package parity beyond existing G6/G7 receipts, final scientific review, release, or GPU work.

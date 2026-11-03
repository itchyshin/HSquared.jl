## 1. Goal

Reconcile the profile-v4 co-winner contract and verify one bounded current-source N160 engineering replay without closing scientific gates.

## 2. Implemented

Recorded the proposed co-winner rule with the exact two absolute `1e-8`, zero-relative-tolerance comparisons used by the Julia implementation. Qualified the historical replay provenance and replaced the unsupported current-source claim. Added the stronger old-versus-current artifact comparison as the required check for the formed-target and eleven-point claims. Ran the focused v4 test file and a new pinned replay against the current Julia source and test bytes. The independent checker confirmed the target formed, all eleven old unresolved points resolved, and the singular zero-residual proposal remained. Astra reviewed the corrected contract and evidence at exact hashes.

## 3a. Decisions and Rejected Alternatives

The inspected N160 data remains engineering-only and is excluded from pilot or confirmation denominators. The original source-mismatched bundle remains intact as historical evidence; a new replay was written to a separate directory and does not overwrite its artifacts. No gate was closed from a single-data replay. The canonical design keeps the co-winner amendment proposed pending full Arc 1 contract reconciliation and G0 admission.

## 4. Files Touched

- `docs/design/arc1-gaussian-reliability-20261002.md` (modified).
- `.unlazy/h2-nongpu-completion/evidence/profile-v4-certified-ties-n160-rerun-20261004/decision-amendment.md` (modified to match implemented tolerance and scope).
- `.unlazy/h2-nongpu-completion/evidence/profile-v4-certified-ties-n160-rerun-20261004/receipt.md` (modified with a provenance correction; old claims and logs retained).
- `.unlazy/h2-nongpu-completion/evidence/profile-v4-current-source-replay-20261004/` (new retained scripts, pins, logs, result objects, and receipt; 229 MB).
- `docs/dev-log/check-log.d/2026-10-04-profile-v4-current-source-replay.md` (new).
- `docs/dev-log/after-task/2026-10-04-profile-v4-current-source-replay.md` (new).
- Temporary working copy and duplicate run artifacts remain at `/private/tmp/h2-arc1-v4-current-source-20261004/`.

No Julia source or test file was changed in this slice. No R source was changed.

## 5. Checks Run

- `python3 tools/arc1_package_checks.py --self-test`: PASS, synthetic success and failure/timeout/input-mutation guards.
- `python3 tools/arc1_manifest.py --validate-only`: PASS, 644,480 unique keys and seeds (10,060 outer and 634,420 nested).
- `python3 /Users/z3437171/shinichi-brain/tools/arc_gate_lock.py verify LOOP/lanes/arc1-gaussian-reliability-20261002`: PASS.
- `julia --startup-file=no --project=. test/arc1_profiles_v4.jl`: PASS, 198 assertions in 31.451 seconds.
- Pinned current-source N160 replay: PASS, exit 0 in 156.464 seconds. Source and test hashes were unchanged before and after. Replay source identity: `38848c4dfe61aae662b3920227ba844a1d7ffe2be98a039ea9bb82bd715e690b`.
- Corrected artifact analysis: exit 0, 12.688 seconds. Its marker alone is not the acceptance check.
- Old-versus-current artifact comparison: PASS, exit 0 in 3.576 seconds; target formed, 11 prior unresolved points `:ok`, one singular residual-zero proposal preserved.
- `git diff --check` on the canonical design: PASS. `slop_check.py` on the design: zero findings.
- Structural `check-after-task.R` passed. The combined `closeout.py check` did not pass its evidence-promotion gate because the project gate ledgers still contain open Arc 1 and H2 requirements; it did not reject the report structure.
- Current source and evidence review by Astra: scoped PASS. This does not close G0 or any scientific gate.

## 6. Tests of the Tests

The 176 bounded-control assertions include co-winner order permutations, likelihood values just inside and outside `1e-8`, certificate status and convergence refusals, invalid values, borrowed source identity, and candidate-owned ties. The synthetic package-runner self-test verifies rejection of input mutation, missing success markers, timeout, and failure statuses. No new test implementation was added in this slice.

## 7a. Issue Ledger

- Fixed: the canonical proposed rule now states both implemented likelihood comparisons, including zero relative tolerance.
- Fixed: the evidence record no longer presents the original mismatched replay as a verified current-source run.
- Fixed: target formation and resolution of the eleven points are tied to the stronger old-versus-current comparison; the separate analysis marker accepts unresolved and singular statuses.
- Deferred: the historical bundle's source/replay hash inconsistency remains unresolved, but it is preserved and superseded for current-source engineering evidence by the new pinned replay.
- Open: G0 executable-contract admission, G1-G8, and project H1-H9 remain open. No pilot or confirmation study has run.

## 8. Consistency Audit

Checked implementation comparisons in `src/arc1_profiles.jl`, co-winner regressions in `test/arc1_profiles_v4.jl`, the old and new replay/analyzer/comparison scripts, the serialized profile and sink, and the relevant design/evidence text. The fresh replay output and comparison agree; the singular boundary remains visible. The current runner's R selector includes seven Arc1 test files, but no R execution was performed. Capability-status rows and the covered count were not changed. Lane preflight found active foreign Cursor lanes and many branch references for the shared check-log and coordination-board paths; those two files were left untouched.

## 9. What Did Not Go Smoothly

The first retained G7 freeze was stale. Review found an inaccurate exact-equality phrase and contradictory historical replay pins. The initial copied analyzer failed because it expected `final-source` artifact names while the replay wrote `post-bypass-fix` names. The failure was preserved, the temporary helper paths were corrected, and both artifact checks then passed. The closeout generator initially targeted the Dropbox brain root instead of this package worktree; a template was generated in `/private/tmp` and this report was completed in the package. Its structural check passed, while its evidence-promotion gate reported the project's intentionally open Arc 1 and H2 ledgers. No failed evidence was deleted or relabeled as a pass.

## 10. Known Residuals

This one inspected dataset does not establish interval calibration or broad profile reliability. R parity, live R controls, current full Julia/R package checks, documentation rendering, rank-selection confirmation, repeatability coverage, and independent final scientific review are still owed. The R checkout has active Cursor lanes, so no shared R files were changed. The earlier G7 source freeze is stale after the design/evidence edits. No source admission or gate closure is claimed.

## 11. Team Learning

Memory receipt: loaded the repo's LOAD-FIRST manifest and applied the source-freeze, negative-space, estimate-before-fit, and shared-lane rules. No second-brain note was used as scientific evidence.

Golden Set: inspected the known `completion-overclaim` case list. No transcript file was submitted to the heuristic runner; all gate boxes and capability status were kept open, so the completion-overclaim failure was avoided.

## 12. Cross-Product Coverage

Covers: current Julia profile-v4 control behavior for the focused assertions and one retained Gaussian N160 engineering input, plus its artifact-level comparison.

Does NOT cover: the R public interface or Julia/R parity; any confirmation seed; calibration, coverage, rank-selection rates, other sample sizes, or general profile reliability; whole-package checks or docs rendering; release or capability promotion; the remaining non-GPU H2 route groups.

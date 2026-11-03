# Arc 1 G8 readiness update after G7 v28

## 1. Goal

Update the provisional plan-to-artifact reconciliation to the current Arc 1 ledger, G7 v28 evidence, and G2 v13 admission state. This report does not close G8.

## 2. Implemented

Added this dated supplement. The 2026-10-10 G8 readiness report remains a historical snapshot; its G7 v26 counts and G2 no-admission wording are superseded here. No code, plan threshold, seed allocation, capability status, or gate checkbox changed.

## 3a. Decisions and Rejected Alternatives

Keep G8 open until G2-G5 study requirements pass and an independent final-source review reconciles all admitted artifacts. Do not treat a reviewed G2 candidate or no-launch preflight as study evidence.

## 4. Files Touched

- Added this G8 update only.
- Current gate ledger: `.unlazy/arc1-gaussian-reliability/GATES.md`, SHA-256 `53d383c24e782c6ec16ae75ba8e05ddbec97a434329ad63460a4e1ecae196a27`.
- Approved plan: `LOOP/lanes/arc1-gaussian-reliability-20261002/ultra-plan.md`, SHA-256 `1e5d09b59c7519d92850ecd50cab51e7ee7b45a5bd68cba90ec976c79d1c1103`.

## 5. Checks Run

- G7 v28 retained verifier rerun: exit 0, `ARC1_G7_RETAINED_RECEIPT_VERIFIED`. Receipt SHA-256 `bb37e40611d139d064e3ab4974870872fa3b756563e12658eb2eea9bc661dddb`; reviewed freeze SHA-256 `7de310f9e367b28799f7c889d7db2711a86fbc416b07697f340b86c3ca82deda`.
- G2 v13 candidate suite: 19/19 passed. Astra review is PASS for candidate SHA-256 `26668e32e3ff0caf9fb923723d072709c6f3aae77d288e630172f93528000edf` and source-lock SHA-256 `051d10957ddcf87b2bd4dde65b7f3daf396df7b0400b8623290d6a3917e3df17`.
- Totoro's exact candidate preflight returned `PREFLIGHT_PASS_NO_LAUNCH`. No model fit ran and no seed was consumed.
- Current scientific-gate checker suite rerun: 22/22 passed in 30.032 seconds. Retained log SHA-256 `79be30c4a870cb3346adc49ada9461b1bcc9795e1c619aba7e295d4133e439dc` at `.unlazy/arc1-gaussian-reliability/evidence/scientific-gate-checker-tests/20261010-current.log`.
- The after-task structure check passed for this report. Its ledger phase correctly remains non-passing because required gates are open.
- After adding this G8 report, the G7 retained verifier passed again. Log SHA-256 `8bf5f6281c746f6e0a673484f4231f5064ec429b30a033f512823c2f362a0656` at `.unlazy/arc1-gaussian-reliability/evidence/retained-checks/20261010-post-g8-note-g7.log`.

## 6. Tests of the Tests

The G2 v13 tests exercise source and candidate drift, unsafe paths, wrong seed and outer scopes, receipt mismatches, retained failure accounting, and a mocked one-attempt launch that never invokes Julia. They validate admission controls only. The 22-case scientific-gate checker suite exercises rank and interval gate rules with positive and negative fixtures. Neither suite provides model calibration or coverage evidence.

## 7a. Issue Ledger

- G0: met for the frozen protocol and execution boundary; each study still needs its exact admission and any required campaign approval.
- G1: met for the reviewed likelihood, gradient, covariance, ordering, and identity checks; this does not establish fresh-data optimizer reliability.
- G2: open. Candidate v13 is reviewed and preflighted, but exact owner approval for outer32 remains pending; no attempt receipt exists.
- G3: open. No nine-cell pilot or confirmation bundle and independent per-cell pins exist.
- G4: open. No qualifying bootstrap pilot, nested endpoint evidence, or confirmation bundle exists.
- G5: open. Engineering checks do not establish five-target interval formation, all-attempt coverage, boundary behavior, or fitted-trace performance.
- G6: met for the retained required-live R parity and failure-control scope.
- G7: met for the exact reviewed v28 package and documentation freeze.
- G8: open. Final-source review and plan-to-admitted-artifact reconciliation await G2-G5 study evidence.

## 8. Consistency Audit

The G7 v28 receipt records 10,227 parsed Julia assertions, 682/682 required-live R assertions, `R CMD check` Status OK with 4,606 passes, zero failures, 26 warnings, and 48 skips, plus a passing local documentation build. Its retained verifier passed again. This supports G7 only at the recorded freeze.

The G2 v13 candidate contains 269 remaining seeds across nine cells. N80/null outer31 remains consumed and counted. Outer32 is the single proposed attempt with seed `18043834289602542821`; it has no standalone gate credit. The candidate requires separate exact review and owner receipts. Its preflight authorizes no execution. No G2 study, G3 pilot, G4 bootstrap pilot, or G5 confirmation evidence is present.

The capability remains experimental and the covered count remains seven. This update changes neither public status nor the approved statistical criteria.

## 9. What Did Not Go Smoothly

The earlier G8 readiness report described G7 v26 as current and said the G2 candidate did not yet exist. Those statements were accurate for that dated snapshot but stale for the present state. They are retained rather than rewritten; this supplement provides the current reconciliation.

## 10. Known Residuals

G2-G5 still need their exact admitted development or pilot evidence, qualified pilots, confirmation evidence, retained failures, and independent pins under the frozen rules. Any campaign projected above three hours still needs its measured pre-run and separate approval. G8 cannot pass before those requirements and the final scientific review pass. The broader non-GPU H2 goal is not complete.

## 11. Team Learning

Date each status reconciliation and link it to the exact source freeze and retained receipt. A new engineering admission changes readiness information but does not create scientific evidence or close its gate.

Style: 3/10, medium confidence. Genre/coverage: short technical reconciliation, read in full. Evidence/repair: the parallel G0-G8 ledger makes the open rows easy to distinguish; no change needed. Gates: science = pass for the limited status claims against the frozen plan and current ledger; facts = pass against the current GATES file, checkpoint, v28 receipt, and v13 candidate; references = pass for the local paths and hashes cited. Provenance: self-review, this draft v1, 2026-10-10; current repo evidence was inspected, not independently style-rated.

## 12. Cross-Product Coverage

Covers: current Arc 1 Julia/R gate readiness and the G2 candidate admission state.

Does not cover: statistical results from new study data, final G8 approval, capability promotion, the full non-GPU HSquared programme, GPU, releases, or publication.

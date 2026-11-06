## 1. Goal

Triage retained v1 G2 failures without consuming study seeds or changing frozen acceptance rules.

## 2. Implemented

Recorded the retained v7 attempt counts, unresolved Hager-Zhang stop detail, and source-hash mismatch in the Arc 1 checkpoint. No production code or acceptance rule changed.

## 3a. Decisions and Rejected Alternatives

Did not launch another replay. The current source differs from the v7 admission, so a new run could only be a changed-source diagnostic. A reviewed outer-19 replay already records the Wolfe-condition stop; later reviewed outer-19 and outer-25 replays also exist. Did not relax optimizer, gradient, covariance, or candidate-refusal criteria.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-10-06-arc1-v1-failure-triage.md`

## 5. Checks Run

- Parsed the retained v7 `batch-summary.json`: 24/24 scheduled attempts completed; 20 eligible selections and four refusals (outer indices 7, 19, 20, 25).
- Inspected all four retained summaries: failed K1 iterations span 55–186; outer 7 has five line-search and one finite-difference failure, outer 19 has 18 line-search failures, outer 20 has 18 line-search failures, and outer 25 has 11 line-search plus four finite-difference failures.
- Compared all 190 v7 source pins with current files: 10 differ, including the optimizer and selector. The original `src/arc1_fa.jl` pin is `01a47052c2a0fb658a9ab054ade22f26af6454a000632c95e845e31783931906`; current is `150960c7f6b943d9ae4fd23b59841f1ad03f7ce837bc91ad671ceaf5105a24b2`.
- Verified the retained outer-19 optimizer diagnostic audit SHA-256 `2d3f5338054cb1a18f072547769b91fafa8beb6f381bc36ab8d993f736c922f3`: 18 K1 starts returned finite steps satisfying neither Wolfe condition; 19 finite-difference sides encountered invalid covariance proposals.
- Read the checkpoint records for the later reviewed outer-19 and outer-25 changed-source replays. Both remain diagnostic-only and outside denominators.
- `git diff --check` passed for the checkpoint and check log.
- `slop_check.py` passed on the report's absolute worktree path with 0 findings. The first relative-path invocation resolved to a different checkout and was discarded.
- Repository preflight reported two live lanes. A scoped Arc 1 lease was registered after the first sandbox-blocked lease attempt.
- The report's structure subcheck passed. Full `closeout.py check` failed at acceptance-ledger validation because the Arc 1, automatic FA-rank, and non-GPU H2 ledgers still have unmet gates. This checkpoint records those unresolved gates.

## 6. Tests of the Tests

No behavioral tests were run in this triage, and no regression was added. The saved selector and audited replay receipts are diagnostic records; they leave the current test and G2 qualification requirements unmet.

## 7a. Issue Ledger

- Open: 10/190 source pins differ between the original v7 admission and current files; current-source runs cannot be described as exact v7 reproductions.
- Open: outer 20 has not received the same changed-source diagnostic treatment as outer 19 and 25, and its 18 K1 line-search failures still need reconciliation with the current-source method.
- Open: the four refusals remain in the original all-attempt denominator; no gate or scientific status changed.

## 8. Consistency Audit

The lane checkpoint, check log, and coordination board all distinguish original v7 evidence from reviewed changed-source diagnostics. The outer-19 audit resolves the Wolfe-condition stop detail; later outer-19/25 replays do not replace original attempts or qualify G2. The root non-GPU goal remains active. Arc 1 remains incomplete, as do its remaining scientific gates. Julia/R parity, R live behavior, and package-level G7 acceptance were not tested in this task.

## 9. What Did Not Go Smoothly

The lane registry and default Julia depot were outside the writable sandbox; the scoped lease succeeded after the approved escalated retry. I initially missed the already-retained outer-19 audit and described its stop detail as unresolved. A read-only independent review caught this, and the checkpoint and report now record the existing audit and corrected iteration/failure counts. The prose linter's first relative-path call resolved to a different checkout; the final absolute-path check passed.

## 10. Known Residuals

This continuation made no source repair, added no deterministic regression, launched no new development attempt, and ran no pilot, confirmation, or R parity test. Full H2 non-GPU completion remains far away; H1–H9 are not complete. The worktree remains broadly dirty, and protected settings and the original R checkout were left untouched.

## 11. Team Learning

Memory receipt: `route.py` found no LOAD-FIRST manifest for this managed worktree. The supplied repository instructions, current Arc 1 checkpoint, retained admission, exact attempt summaries, and the existing `astra_current_v4_review` lens shaped the triage; its follow-up was read-only. Check source pins before classifying a replay: a mismatched source supports only a fresh, reviewed changed-source diagnostic. Exact reproduction requires matching pins. Golden Set: outside scope because no method or behavior changed.

## 12. Cross-Product Coverage

Covers: retained Julia v1 selector failure accounting and checkpoint continuity.

This diagnostic does NOT cover: current-source numerical behavior, the R twin, Julia/R parity, interval calibration, pilot or confirmation acceptance, or any GPU route.

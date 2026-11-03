# G2 K0 six-split follow-up decision candidate

Date: 2026-10-07  
Decision owner: Arc 1 driver  
Status: proposed for independent review; active selector unchanged.

## Evidence

The exact-source-reviewed v4 diagnostic replayed only consumed outer7 and outer10 data. Astra's retained-artifact audit passed the exact candidate, source, runtime, review, output, and original-ledger bindings. Each case completed six eligible K0 and eighteen eligible K1 starts. The best K0 starts were `split_0.7` for outer7 and `split_0.3` for outer10. Expanded-reference shortfalls were `3.410605131648481e-13` in both cases, below the frozen `1e-4` tolerance. Original 19-start ledgers and failures were preserved: six original failures for outer7 and eighteen for outer10. No seeds or denominators changed. The diagnostic counts as zero G2 cases.

The result supports a start-sensitivity problem in the one-start K0 route and shows that the six-split schedule can recover the frozen reference result on these two inputs. It does not prove global optimality, qualify selection rates, calibrate uncertainty, or establish performance on untouched cases.

## Proposed method amendment

For the bounded four-trait Gaussian pedigree T4 `arc1_v1` route, use six deterministic K0 starts in this order: `0.05, 0.15, 0.3, 0.5, 0.7, 0.9`. Construct the fourth (`0.5`) start by calling the unchanged production K0 initializer directly, so it remains bit-for-bit identical even for variances near the uniqueness floor. Construct the other five starts with the audited `arc1_reference_k0_start` rule: calculate each trait's sample variance around its sample mean from observed `Y` only, use `1.0` for a nonfinite/nonpositive sample variance, set `v=max(variance, 2*FA_UNIQUENESS_FLOOR)`, `Gdiag=max(split*v, 2*FA_UNIQUENESS_FLOOR)`, and `R=Diagonal((1-split)*v)`, then use the existing uniqueness-to-unconstrained and covariance-to-Cholesky transforms. Add a regression with a small positive trait variance that proves the production `0.5` start is unchanged and differs from the floored reference formula where expected. Apply the existing per-start assessment with the 2,000-iteration cap. Select the highest finite eligible K0 likelihood; break exact ties by frozen schedule order. If no K0 start is eligible, preserve all planned K1 rows as unattempted and refuse selection.

Keep K1's eighteen-start schedule unchanged: the existing `default` and `balanced` starts plus the existing sixteen derived starts. Derive those sixteen only from the selected best eligible K0. Apply the better-unaccepted safeguard to both ranks: a materially better finite, independently checked but unaccepted K0 or K1 attempt blocks selection. Keep the frozen score, covariance and ordering checks, nesting witness, uniqueness floor, acceptance thresholds, failure handling, all-attempt denominators, seeds, and study allocations unchanged. Retain every K0 and K1 attempt, including failures. A failed individual start is retained and may be allowed under the predeclared availability rule; the stop rule applies when the cell-level frozen criterion fails, not merely because one attempt fails.

This proposal changes ordinary K0 start policy only. It does not alter public syntax or the structural result schema; `arc1_v1` attempt ledgers will contain six K0 rows rather than one, and the R/Julia parity evidence must reflect those added rows identically. Model scope, selection score, evidence phase, and capability status remain unchanged.

## Required evaluation and stop rules

After independent review of this amendment and exact source review of any implementation, evaluate the amended schedule only on allocated development cases that an attempt-registry and manifest audit prove are untouched. All N=80/null development indices 1–30 are already consumed and excluded; exclude any other previously attempted index as well. Do not create replacement development seeds, borrow pilot seeds for tuning, or reuse outer7/outer10 or any other consumed seed as a new observation. Keep results separated by method/source version; do not pool old one-start outcomes into the amended-method qualification numerator. Bind every run to exact source, runtime, manifest, and output hashes. Audit every flagged case and the preselected reference subset under the frozen reference protocol. Preserve failures and the original denominators.

The development result is a qualification screen, not G2/G3 acceptance. If any frozen reliability/refusal rule fails, stop pilot admission, retain the failure, and return for a method decision. Do not change the `1e-4` reference tolerance, optimizer budget, score, denominators, or seed allocation to obtain a pass. No pilot or confirmation starts under this decision candidate.

## Decision boundary

Astra must review this candidate before the active selector changes or any new numerical execution begins. This document is a proposal, not evidence of implementation or gate completion. G2, G3, G4, G5, and G8 remain open; the consumed-case diagnostic grants zero gate credit.

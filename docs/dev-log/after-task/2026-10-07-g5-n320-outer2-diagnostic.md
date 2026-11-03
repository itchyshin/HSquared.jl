# G5 N320 outer-2 development diagnostic

## 1. Goal

Resume the retained Arc 1 G5 profile-v4 investigation with one new, source-pinned N=320 near-zero-additive development attempt. Preserve the frozen method, acceptance criteria, denominators, and consumed seed history.

## 2. Implemented

The active driver ran one approved attempt. Astra's `attempt4_astra_review` role reviewed the exact admission before launch and audited the retained result afterward. The post-run review is `docs/dev-log/source-review/2026-10-07-g5-n320-outer2-postrun-review.md`. No new parallel implementation agent was started in this slice. The user-requested scope is the HSquared Arc 1 software project.

## 3a. Decisions and Rejected Alternatives

The exact v2 admission and plan were used without changing source, seeds, thresholds, or allocation. Outer 1 remains a consumed timeout. Outer 2 is a distinct consumed development attempt. The candidate review cleared outer 2 only. This run does not authorize pilot, confirmation, or G5 qualification.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/astra-review.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/verify_outer2_attempt.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/outer2-verification.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/run-outer-2.time`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/load-preflight.log`
- `docs/dev-log/source-review/2026-10-07-g5-n320-outer2-postrun-review.md`
- `docs/dev-log/after-task/2026-10-07-g5-n320-outer2-diagnostic.md`
- `docs/dev-log/check-log.d/2026-10-07-g5-n320-outer2-diagnostic.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md` and `checkpoint-archive-20261007-before-g5-outer2.md`.

The shared `docs/dev-log/check-log.md` and `docs/dev-log/coordination-board.md` were not edited. File-level lane preflight reports that other refs carry changes this checkout lacks; the dated sidecar and checkpoint retain this slice without overwriting shared work.

The full result, binary artifact, and Julia log remain on Totoro. Their SHA-256 values are recorded in the compact verification JSON. No production Julia or R source changed.

## 5. Checks Run

- The Arc 1 gate lock verified before and after this diagnostic. The live ledger records G0, G1, G6, and G7 as met, with G2-G5 and G8 open. G0, G1, G6, and G7 remain marked met; G2, G3, G4, G5, and G8 remain open.
- The v2 admission pins matched all 194 source files before launch and again during the independent review. The outer seed CSV remained unchanged.
- The focused executor and admission tests passed 161/161, 10/10, and 15/15 before the attempt. The load-only Totoro preflight reported Julia 1.10.0, four Julia threads, and BLAS one.
- The run used N=320, two records per offspring, 640 records, near-zero additive variance, outer 2, seed `688524427072088691`, and `arc1_profile_v4`. Child exit was zero. End-to-end wall time was 447.46 seconds; maximum resident set size was 9,554,532 KiB.
- The result reports `success=true`, `status=ok`; the point fit is `ok` and `point_fit_not_optimal=false`. All five interval target records passed the pinned interval-formula, status, segment-order, and bounds checks. Every target is marked formed.
- Result SHA-256: `6d9fc12b6284999b925968b467f60f14b0ca1d9433379e2d2059ffefbd53c1b9`. Full JLS SHA-256: `6868c4b15c85f58d261b5935dd860a94a071ea7f71047215ab1d11c821386172`. Julia log SHA-256: `bd482e26015773766014d285e204ca6250ff098421a117b7fccb89d59c73d367`. Profile summary SHA-256: `bfa44bea2a95a4285857ca73d78a619888017ccb7a6b697f47aab0d366eff597`.
- The independent post-run review returned PASS for record integrity and reported target outcomes, with the limits recorded in its review note.

## 6. Tests of the Tests

Previously recorded focused test results were 161/161, 10/10, and 15/15 successes. This slice did not run corruption attacks against the broad Arc 1 gate checkers. The new one-attempt projection script was syntax-checked and executed on the exact remote result. It fails closed on identity, formula, status, hash, runtime, and timeout mismatches; a separate adversarial test of this helper remains undone.

## 7a. Issue Ledger

- G0, G1, G6, and G7 remain recorded as met; G2, G3, G4, G5, and G8 remain open.
- Five intervals formed for one development dataset. Formation-rate and coverage requirements remain untested at the campaign level.
- No public documentation, package capability row, covered count, release state, or default changed.

## 8. Consistency Audit

File-level lane preflight found no missing work on the checkpoint path and reported one lane. The Julia checkout remains dirty from earlier Arc 1 work; existing edits were preserved. The isolated R checkout and protected local configuration were not touched. Totoro was accessed through its existing SSH control socket. The multi-gigabyte raw output remains in persistent `~/hsq_work`; a compact hash-bound projection is retained locally. The main check log and coordination board were not edited because preflight reports changes in other refs that this checkout lacks. The dated check-log sidecar and checkpoint preserve this slice.

## 9. What Did Not Go Smoothly

The earlier N=320 outer-1 attempt timed out during result construction and remains failed. The repaired digest path allowed outer 2 to complete, but runner serialization and hashing consumed several minutes and about 9.11 GiB peak RSS. The raw JSON result and Julia log are each about 1.37 GB. A first draft of the local runtime verifier assumed that the nested engine identity directly contained runtime fields; that check was corrected to validate the retained preflight, exact runner timing command, and Julia execution identity. The final verifier passed.

## 10. Known Residuals

- This is only one N=320 near-zero-additive development result. The five formed intervals do not estimate formation rates or coverage.
- Residual variance and repeatability intervals exclude their true values for this dataset. The pilot and all-attempt coverage gates remain open.
- Astra hash-checked the JLS artifact but did not deserialize it or reconstruct the raw-profile/tail-certificate correspondence. Timeout cleanup was not exercised.
- G2, G3, G4, G5, and G8 remain open. No pilot or confirmation run is admitted.
- Two of 30 development attempt slots in this cell are consumed: outer 1 timed out and outer 2 succeeded. The measured 447.46-second wall time gives a preliminary projection of about 3 hours 29 minutes for 28 remaining attempts in this cell, before overhead. A 25% planning allowance gives about 4 hours 21 minutes. One attempt is a small timing sample, so this projection has substantial uncertainty. The frozen plan requires approval before continuing a campaign projected above three hours.

## 11. Team Learning

A large single-run serialization workload needs a measured pre-run with memory and wall-time recorded before campaign sizing. The N=320 cell has two consumed development indices; do not replace either. The next step is to seek approval for the remaining 28 attempts using the measured 447.46-second run and a 25% allowance, or propose a separately bounded sub-three-hour slice. Do not launch until the over-three-hour approval is recorded, and do not mark G5 met.

## 12. Cross-Product Coverage

Covers one Julia G5 development attempt, its admitted runtime and source identity, five interval formation records, and a bounded independent review. Does not cover R parity, the other repeatability cells, exact-zero boundary cells, FA selection or bootstrap campaigns, G2-G4, G8, GPU, package release, or completion of the wider H2 project.

## Post-draft naturalness assessment

Style score: 3/10, medium confidence; the report is specific and evidence-led, though its required sections create some uniform structure. **Genre/coverage:** after-task diagnostic report, read in full. **Evidence/repair:** “Five intervals formed for one development dataset” is a concrete, bounded result; no change needed. The original phrase “not a paper or release” was replaced with a direct scope statement. **Gates:** science = pass for accurately limiting this result to one dataset; facts = pass against the retained verification JSON, run timing, gate ledger, and Astra review; references = not applicable, no external citations. **Provenance:** self-review, version after-task diagnostic 2026-10-07, prior source evidence already seen.

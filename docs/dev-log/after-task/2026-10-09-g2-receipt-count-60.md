## 1. Goal

Align FA-rank receipt validation with the adopted 60-attempt development allocation without running a study or changing the allocation.

## 2. Implemented

`_expected_outer_count` now reads `FA_RANK_DEVELOPMENT_COUNT` for FA-rank development receipts. Current FA-rank test fixtures now cover 60 attempts. Repeatability and FA-interval development fixtures remain at 30. The accepted manifest allocation and thresholds did not change.

## 3a. Decisions and Rejected Alternatives

Kept the checker tied to the canonical manifest constant rather than adding a second literal 60. Updated the FA-rank test fixtures and their stale seed-CSV hash to match the current canonical manifest. Did not change repeatability counts or weaken receipt validation.

## 4. Files Touched

- `tools/arc1_receipt_check.py`
- `test/test_arc1_receipt_adversaries.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint-archive-20261009-before-g2-receipt-count-fix.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-receipt-checker-count-60-test-v1.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-current-container-preflight-v1/run-result-20261009/`
- `sim/arc1/manifests/arc1_seed_manifest.json`
- `sim/arc1/manifest-revisions.md`
- `docs/dev-log/check-log.d/2026-10-09-g2-receipt-count-60.md`
- This report.

## 5. Checks Run

The new regression failed before the source change with 30 expected versus 60 in the manifest. After the fix, the focused denominator and failed-candidate tests passed. The complete `python3.13 test/test_arc1_receipt_adversaries.py` run passed 55/55 in 712.873 seconds. Python compilation passed for the checker and test file. Canonical manifest validation passed with 10,330 outer and 634,420 nested seeds. The G0 lock verifier reported `GATES OK`; `git diff --check` passed. Exact source hashes and final suite result are retained in `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-receipt-checker-count-60-test-v1.json`.

The G5 synthetic current-container receipt and output captures were copied from `/private/tmp` into the evidence directory. All copied hashes match. This retains engineering evidence only.

## 6. Tests of the Tests

The new assertion reproduces the allocation mismatch before the fix and passes after the checker reads the canonical manifest constant. Existing adversarial tests continued to cover seed pins, missing attempts, failed candidates, denominator integrity, selection rules, and refusal states.

## 7a. Issue Ledger

Fixed the FA-rank receipt checker and test fixtures that still assumed 30 development attempts. Deferred the G2 tranche, all pilot and confirmation work, and statistical G5. No gate receives credit from this change.

## 8. Consistency Audit

The manifest still specifies 60 FA-rank development attempts and 30 for repeatability and FA intervals. The seed CSV digest and protocol identity remain valid. The G0 lock passed. The new evidence keeps `gate_credit=false`, `study_attempt=false`, and `legacy_artifact_read=false`. No thresholds, capability status, covered count, or R public controls changed.

## 9. What Did Not Go Smoothly

The first full suite exposed test fixtures that still used 30 FA-rank rows; a follow-up run exposed two remaining expected-count assertions. The fixtures and assertions were corrected, and the final full run passed. The shared `docs/dev-log/check-log.md` preflight showed 15 other references with work absent from this checkout, so the dated entry was placed in `check-log.d/`. The repo's `closeout.py` resolves paths to the brain checkout and could not write this worktree report; the exact external R section validator was used directly instead.

## 10. Known Residuals

This proves receipt-count consistency only. It does not prove FA fitting reliability or calibration. The outer31 pre-run remains a single case with zero G2 credit. Its v13 source freeze is stale after this checker change, so no tranche can use that admission. The full 270-attempt tranche remains pending separate approval. G2 through G5 and G8 remain open, except for G0, G1, G6, and G7 at their recorded scopes.

## 11. Team Learning

When an allocation changes, update the receipt checker and its full-cell fixtures from the single canonical manifest constant. A focused count assertion catches a mismatch early, while the adversarial suite checks the all-attempt denominator behavior. Memory receipt: the repository LOAD-FIRST manifest, Arc 1 checkpoint, and lane preflight shaped this work; hub cross-repo guards were not loaded. Golden Set: not run because no numerical estimator or model behavior changed.

## 12. Cross-Product Coverage

Covers the Julia Arc 1 manifest allocation as consumed by Python receipt validation and the corresponding synthetic test fixtures.

Does NOT cover the R public API or isolated R parity, fitted-model reliability, FA selection rates, repeatability interval coverage, campaign admission, confirmation evidence, capability promotion, release, or GPU work.

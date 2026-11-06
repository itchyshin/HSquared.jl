# 2026-10-09 G2 receipt allocation checker

The receipt checker now derives the FA-rank development denominator from the canonical manifest constant, which is 60 under the adopted amended allocation. The repeatability and FA-interval development counts remain 30.

Regression evidence: the new assertion failed against the prior checker (`30 != 60`) and passed after the fix. The complete command `python3.13 test/test_arc1_receipt_adversaries.py` passed 55/55 in 712.873 seconds. `python3.13 -m py_compile tools/arc1_receipt_check.py test/test_arc1_receipt_adversaries.py` passed. The exact source and manifest hashes are in `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-receipt-checker-count-60-test-v1.json`.

No G2 attempts, seed allocations, gate credit, capability changes, or acceptance-threshold changes resulted. The main `check-log.md` was left untouched because lane preflight found 15 other references with work absent from this checkout. The dated addendum is stored in `check-log.d/`.

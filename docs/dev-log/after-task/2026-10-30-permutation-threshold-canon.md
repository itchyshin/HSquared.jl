# After-task: permutation threshold canon decision (#48)

## 1. Goal

Record the owner decision that the existing permutation max-statistic
threshold is the genome-wide calibration canon. Binding source: Decision
(Shinichi, 25 Oct 2026) on #48.

## 2. Implemented

Docs-only decision note at
`docs/dev-log/decisions/2026-10-30-permutation-threshold-canon.md`.
No source, test, harness, or public-docs change.

Active lenses: Rose (claim vs evidence, docs-only). No subagent was spawned.

## 3. Decisions and rejected alternatives

Accepted the owner "yes": use `genome_wide_threshold_from_null` as the canon.
Rejected waiting for PLINK / GEMMA / GCTA on a machine that does not have
them. Rejected closing #48 or treating this record as the realistic-LD
calibration or the metadata wiring.

## 4. Files touched

- `docs/dev-log/decisions/2026-10-30-permutation-threshold-canon.md`
- `docs/dev-log/check-log.d/2026-10-30-permutation-threshold-canon.md`
- `docs/dev-log/after-task/2026-10-30-permutation-threshold-canon.md`

No `src/`, `test/`, `GATES.md`, capability-status, or validation-debt edit.

## 5. Checks run

- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: green.
- `bash tools/build_check_log.sh --check`: expected to pass on this shard
  shape.
- No package tests or docs build.

## 6. Tests of the tests

None. This slice adds no test.

## 7. Issue ledger

#48 remains open. Remaining gates are realistic-LD type-I calibration,
marker-scan metadata wiring, and a Rose audit before public wording.
`public_covered_count` remains 7.

## 8. Public claim audit (Rose perspective)

The note states a canon choice only. It repeats that the scoped covered row
is not a public default and that this record does not activate significance
wording.

## 9. What did not go smoothly

The owner comment named `DECISIONS.md`. This repo keeps decisions under
`docs/dev-log/decisions/`. The note lives there.

## 10. Known residuals

Realistic-LD calibration and output wiring are still owed on #48. A second
external comparator remains standing debt on the scoped covered row.

## 11. Next actions

Keep #48 open. Do not run consumed seeds. Do not change R `gwas()` wording
from this record.

## 12. Cross-product coverage

Julia-lane documentation only. It does not change `hsquared`.

## 1. Goal

Fix the Julia `data_status()` fallback marker count when genotype tables use a configured ID column other than `id`, and retain a regression for that input.

## 2. Implemented

- Passed `HSData.genotype_id` to the fallback marker-count helper.
- Excluded the configured ID field using `_same_column_name`, matching the existing marker-ID handling.
- Added a table-genotype test with `genotype_id = :sample` that checks the marker-status column count.
- Recorded the finding and bounded review outcome in the Wave 3 packet.

## 3a. Decisions and Rejected Alternatives

Kept the fallback specific to table-like genotypes without an explicit marker specification. Matrix genotype counts remain based on matrix width, and explicit marker specifications retain their existing count. The configured ID is compared by the package's existing column-name rule rather than by hard-coded spelling. No R behavior or capability claim changed.

## 4. Files Touched

- `src/data.jl`
- `test/runtests.jl`
- `docs/dev-log/source-review/2026-09-27-wave3.md`
- `docs/dev-log/check-log.md`
- `GATES.md`
- `docs/dev-log/after-task/2026-09-27-w3-data-status-fix.md`

## 5. Checks Run

- Test-first reproduction failed as expected: the marker-status row returned `"2"` for one marker plus a `sample` ID column, while the expected count was `"1"`.
- The same focused command passed after the fix and printed `CUSTOM_GENOTYPE_ID_MARKER_COUNT_OK`.
- Full `Pkg.test()` passed in `/private/tmp/hsq-fa-closeout-20260927-copy` after copying the current `src/` and `test/` trees and confirming both with `diff -qr`; output ended `Testing HSquared tests passed`.
- `git diff --check` and the package preamble-cap check passed.
- After-task structure check passed. Its integrated ledger check remains unable to read `GATES.md:V1` in this sandbox; no ledger-wide pass is claimed.

## 6. Tests of the Tests

The negative control used the real `HSData` and `data_status` API with two IDs in a `sample` field and one `m1` marker. Before the production fix, `status.marker_status[2].value` was `"2"`; after the fix it was `"1"`. The committed test asserts the full seven-row marker status and catches the custom-ID overcount.

## 7a. Issue Ledger

- **Fixed:** fallback table marker count included a configured custom genotype ID column.
- **Carried:** a worst-case deep pedigree chain for recursive topological sort; other uninspected Wave 3 source spans; live R-Julia parity for the new behavior; and whole-wave source-review signoff.

## 8. Consistency Audit

Reviewed the fallback count, matrix overload, explicit marker-spec path, configured genotype ID storage, and existing genotype status marker-ID extraction. The fix aligns the fallback with the already-correct `_same_column_name` exclusion and leaves the matrix and explicit-spec routes unchanged. Boole's read-only recheck confirmed the fix covers the reported defect without changing those adjacent routes. Henderson found no A/Ainv formula error in the assigned pedigree spans, with a deep-chain stress check still owed.

## 9. What Did Not Go Smoothly

The first regression checked `genotype_status`, which already excluded the configured custom ID, so it passed without exercising the defect. Inspection showed the affected count was in `marker_status`; the corrected assertion failed on the old code before implementation. Full tests had to run in a writable content-matched copy because comparator tests write generated files in the managed checkout.

## 10. Known Residuals

The result is limited to this diagnostic count. Separate evidence is still needed for marker-map alignment and model fitting. It does not close Wave 3, validate R-Julia parity, or establish the deeper pedigree recursion behavior. The branch's current remote CI status is reported in `GATES.md`; any subsequent push needs its own check result.

## 11. Team Learning

When an API exposes both component-specific status and aggregate marker status, test the exact row where the defect was found. Similar naming across status surfaces does not imply they share the same code path.

## 12. Cross-Product Coverage

Covers: Julia table-genotype fallback marker counts with a non-default ID column.

Does NOT cover: R behavior; explicit marker maps; marker alignment; model fitting; all `data.jl` input paths; deep pedigree-chain robustness; whole Wave 3 review; automatic rank selection; GPU execution; release submission; or public capability promotion.

## 1. Goal

Make explicit genotype and expression ID vectors validate against dictionary-backed source row counts.

## 2. Implemented

Added dictionary column row counting and a clear error for inconsistent dictionary column lengths. Added focused regression tests for genotype and expression ID mismatches, valid lengths, and inconsistent columns.

## 3a. Decisions and Rejected Alternatives

- Derive dictionary row count from its columns so existing explicit-ID validation applies uniformly.
- Reject differing column lengths instead of selecting one column as authoritative.
- Keep the change limited to the data-container contract; no fitting or capability claim changed.

## 4. Files Touched

- `src/data.jl`
- `test/test_data_dict_id_lengths.jl`
- `test/runtests.jl`
- `docs/dev-log/source-review/2026-09-29-dictionary-row-count-contract.md`
- `docs/dev-log/check-log.d/2026-09-29-dictionary-row-count-contract.md`
- `docs/dev-log/after-task/2026-09-29-dictionary-row-count-contract.md`

## 5. Checks Run

- Focused Julia regression file: 8/8 passed.
- `git diff --check`: passed.
- Full Julia `Pkg.test()` passed on the final source and test bytes, ending `Testing HSquared tests passed`. The first run exposed a stale expected `genotype_rows` status for a dictionary with duplicate marker names; the expected value now reports the determinable row count `2`.
- The suite warned that project dependency/compat metadata differs from the manifest. No resolve or update was run.

## 6. Tests of the Tests

Tests assert both genotype and expression ID-list mismatches throw, correctly sized dictionary data reports its row count, inconsistent dictionary columns throw, integer and string IDs remain distinct, and empty phenotype input is rejected. The full suite caught and verified the intentional diagnostic change for duplicate-named but equal-length dictionary columns.

## 7a. Issue Ledger

- Fixed: dictionary-backed source data skipped explicit source-ID length checks because `_row_count` returned `nothing`.
- Open: broader E1 source-review coverage; A2 and V3 programme gates.

## 8. Consistency Audit

The fix uses all dictionary column lengths, preserving the existing ID validation route. The test file is registered in `test/runtests.jl`. `genotype_rows` reports the known row count even with duplicate marker names; the separate duplicate-marker diagnostic remains present. No capability-status or validation-debt row changed.

## 9. What Did Not Go Smoothly

The first test launch attempted to write Julia's compiled cache under the restricted default depot. Re-running with a task-local depot succeeded.

## 10. Known Residuals

This does NOT cover full `src/data.jl` review, exact-type bridge identity behavior, R parity, model fitting, FA/GLLVM acceptance, GPU execution, or release readiness. E1, A2, and V3 remain open. No simulation, release submission, registry submission, merge, or tag occurred.

## 11. Team Learning

When explicit IDs are accepted for a table-like dictionary, its row count must be derived from every column and inconsistent columns must fail before an ID list can be checked against an arbitrary first column.

## 12. Cross-Product Coverage

This covers Julia `HSData` dictionary row counts for genotype and expression sources. It does NOT cover the R bridge, pedigree normalization, fitting, unusual inheritance, GPU paths, or other input containers.


## 2026-09-30 follow-up: NamedTuple and malformed columns

The exact-current row-count guard now covers both NamedTuple and dictionary
sources. Each container validates every column length, rejects a column without
`length`, and rejects unequal lengths before explicit source IDs can pass
validation. The dictionary test file passes 14 assertions; the neighboring
empty-marker and pedigree-status file passes 15 assertions. Exact hashes are
recorded in `docs/dev-log/source-review/2026-09-29-dictionary-row-count-contract.md`.
Curie reviewed the added guards and test assertions; Rose found no public claim or
capability-status change and confirmed E1 remains open.

This follow-up does NOT establish full `src/data.jl` coverage, custom containers
whose `length` method throws, R parity, FA/GLLVM acceptance, or E1 signoff.

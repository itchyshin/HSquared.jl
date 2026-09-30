# Data input-contract exact-current review, 2026-09-30

## Scope and pins

Read-only validation review by Curie of the data-normalization source and its registered dictionary-ID and empty-marker tests. All pins matched the candidate:

| File | SHA-256 |
| --- | --- |
| `src/data.jl` | `91ab80b4140459eb406547974876b1d15169d4fb5a2c3676ddaaf9ce3f16541a` |
| `test/test_data_dict_id_lengths.jl` | `530e0f3914a722fdf70c5ba94e5bc93ed95120d6fc0a87c7c81a7c217be257b8` |
| `test/test_data_empty_marker_status.jl` | `82ffbb1cbb11466adef918ada7da2fb193c202a4289f7dc352b4cd48b43111b1` |

Reviewed spans include `_source_ids` (`src/data.jl:465-475`), table marker validation (`:595-635,673-684`), row-count behavior (`:1216-1240`), registered marker tests (`test/runtests.jl:2098-2110,2218-2235`), and direct new test files. No tests or edits were made. Preflight found one divergent ref with work on `src/data.jl`; its diff hard-codes literal `id` and would break the current configurable genotype-ID marker-count behavior. That alternative was not adopted.

## Supported contracts and current test evidence

- Explicit IDs are checked against `_row_count`; Dict sources validate all column lengths. The registered test covers too-few genotype IDs, mismatched expression IDs, valid status counts, unequal-length Dict columns, typed IDs remaining distinct, and empty phenotype IDs (`test/test_data_dict_id_lengths.jl:4-38`).
- Table-derived marker names exclude the configured `genotype_id`; explicit marker IDs validate against marker columns and matrix inputs validate against matrix columns. Marker-map IDs must match exactly. Current tests cover inferred table marker order/index and general `ArgumentError` outcomes for map mismatch/no marker columns.
- Empty-marker status tests preserve metric order, zero counts, unavailable minimum/maximum, and the no-genotype alignment label (`test/test_data_empty_marker_status.jl:4-27`).

## Findings and gaps

1. **Input-contract defect to resolve:** `_row_count(::NamedTuple)` reads only the first column's length (`src/data.jl:1216-1225`). If a valid first column is followed by a shorter column, explicit-ID alignment can pass despite unequal row counts. There is no regression test for this shape. Determine whether all table-like columns must be length-consistent, then add a minimal malformed-NamedTuple test and a specific diagnostic.
2. **Narrow test gaps:** no string-key Dict compatibility test; no exact error-message assertions; no direct assertion that an explicit table marker-ID count must match; no empty genotype matrix/table case or empty-map plus nonempty marker case.
3. The alternative ref's `_fallback_genotype_marker_count` counts every named column except the literal string `id`, which conflicts with the supported `genotype_id` setting. Keep the current configured-ID implementation unless a reviewed change preserves that contract.

## Verdict and limits

Component verdict: **conditional pass** for the tested Dict and marker-status contracts, with the unequal-NamedTuple row-count validation defect carried. No test run is implied by this static review. This does not close `src/data.jl`, E1, the entire data ingress surface, malformed-ID diagnostics, matrix/model parity, or any fitted capability gate.

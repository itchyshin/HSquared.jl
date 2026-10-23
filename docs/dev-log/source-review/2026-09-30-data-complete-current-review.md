# E1 current data source review, 2026-09-30

## 1. Verdict

Verdict: HOLD for full-file approval. All 1,251 lines of the frozen `src/data.jl` have a source disposition. One new P2 diagnostics defect remains carried because the approved FA campaign freezes the source. The complete review ledger does not promote E1, a capability row, bridge parity, inference, or recovery status.

Review lenses: Emmy for container/API semantics, Hopper for diagnostic transport and twin boundaries, Boole for key normalization and malformed-input behavior. This is one bounded reviewer applying those lenses.

## 2. Request and ownership

Complete the current data-file coverage by reviewing its residual declarations, metadata, and diagnostics, then reattest named historical components against the frozen source. Ownership was limited to this scratch report and a scratch deterministic probe. Live source, tests, docs, source-review receipts, and other lanes' dirty work were preserved.

## 3. Candidate and pins

Candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, branch `codex/hsquared-fa-gllvm-20260927`.

- HEAD before and after inspection: `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`.
- `src/data.jl`: 1,251 lines, SHA-256 `39efaac183375e0f735836e5c3d398a1b8f59fffb5b7e7f3b616678b01d727b8`, unchanged before and after the runtime probe.
- Parent source-tree freeze: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. This review checked the data-file pin directly; the parent owns the aggregate tree measurement.
- `test/test_data_dict_id_lengths.jl`: `f589690d9d58c945c287103837cfa81a0395b87a37567c7540027d744ab54c37`.
- `test/test_data_empty_marker_status.jl`: `82ffbb1cbb11466adef918ada7da2fb193c202a4289f7dc352b4cd48b43111b1`.
- Current `test/runtests.jl`: `b2d77c7f0937f5fcf0ed8ec32913c816b2c942f27c83825c8424107a5bc58b24`. The older component receipt's `b4802d82...` test-entry pin is historical. No fresh package-suite claim is made from that receipt.

## 4. Complete inclusive span partition

These disjoint intervals cover every line exactly once, including docstrings and separators. Fresh residual inspection accounts for 893 lines; component reattestation or an exact-current component receipt accounts for 358 lines. Some prior reports split a function at a line boundary or overlapped line 685. The partition below resolves those bookkeeping overlaps around whole current functions.

| Current span | Lines | Basis | Disposition |
|---|---:|---|---|
| 1-263 | 263 | Fresh structs, diagnostic row types, displays, and public constructor documentation | PASS with snapshot/reference and metadata-only limits |
| 264-412 | 149 | Wave 3 constructor approval; exact byte comparison with its baseline | Reattested PASS; delayed malformed-table validation fenced below |
| 413-429 | 17 | Fresh extractor and status documentation | PASS; diagnostic-only boundary remains explicit |
| 430-475 | 46 | Wave 3 status orchestration and ID-source approval; exact baseline byte comparison | Reattested PASS within accepted ingress scope |
| 476-594 | 119 | Fresh column lookup, annotation/environment, map metadata, absent-component guards | HOLD for D1 through column lookup |
| 595-637 | 43 | Prior marker-alignment review; current function read and exact baseline byte comparison | Reattested PASS for marker membership/order and supplied marker counts |
| 638-672 | 35 | Fresh explicit/alias marker columns and table-name extraction | PASS for Symbol/string column keys; broad arbitrary key support is unclaimed |
| 673-705 | 33 | Prior marker-column count review plus Wave 3 string-ID validation; exact baseline byte comparison | Reattested PASS; removes the historical shared line 685 |
| 706-986 | 281 | Fresh chromosome/position hygiene, component/overlap rows, raw/normalized pedigree vectors, duplicate IDs, marker/annotation/environment status | PASS with existing repairs reattested and F2 fenced |
| 987-1003 | 17 | Prior custom-ID marker-count approval; fresh current-body attestation | Reattested PASS; whole helper begins at 987, not historical 989 |
| 1004-1181 | 178 | Fresh alignment labels, genotype/expression summaries, missing-value count, feature names, key/string normalization | HOLD for D1 at 1071-1080 |
| 1182-1215 | 34 | Wave 3 typed-ID, ordered set operations, generic row count; exact baseline byte comparison | Reattested PASS with unsupported source-size fallback preserved |
| 1216-1251 | 36 | Exact-current NamedTuple/Dict row-count follow-up plus current missing-value predicate inspection | PASS for component row-count repair; F1 remains scoped |
| Total | 1251 | Union 1-1251; zero uncovered or duplicate lines | Coverage complete; approval HOLD D1 |

## 5. Historical approvals and delta evidence

Named receipts consulted:

- `docs/dev-log/source-review/2026-09-27-wave3.md`: scoped PASS at baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214`; original data spans 264-412, 430-475, 685-705, 1182-1233. Current source was compared to that baseline rather than assuming old coordinates still apply.
- `docs/dev-log/source-review/2026-09-29-data-parent-alias.md`: recognized sire/dam aliases handled independently; missing side remains unknown. Current 839-853 retains that reviewed implementation. The corrected follow-up supersedes the earlier Wave 3 prose about positional inference for a missing side.
- `docs/dev-log/source-review/2026-09-30-data-input-contract-exact-review.md`: older `91ab80...` component pin, marker alignment 595-636 and 673-685. Its unequal-NamedTuple finding has been repaired by the exact-current follow-up below.
- `docs/dev-log/source-review/2026-09-30-data-custom-id-marker-count.md`: old source `91ab80...`; current 987-1001 still passes `data.genotype_id` into the fallback and normalizes comparison via `_same_column_name`. Its distinct matrix rule is retained. Current code was directly reattested; no archive of all old dirty `91ab80...` bytes is claimed.
- `docs/dev-log/source-review/2026-09-29-dictionary-row-count-contract.md`, section "Exact-current follow-up: NamedTuple and unsupported columns": exact current `39efaac...` pin, focused tests 14/14 and neighboring tests 15/15 recorded there. Those runs are historical evidence on the matching focused source/test files; they were not repeated here.

The full baseline-to-current diff contains only the known parent-alias, empty-marker bounds, configured fallback-ID count, and row-count changes. Exact unchanged interval checks returned true for 264-412, 430-475, 595-637, 673-705, and 1182-1215. Thus no earlier constructor/ID algebra was discarded because the file-level hash changed.

## 6. New actionable finding

### D1: P2, carried, ambiguous dictionary lookup undercounts missing genotype cells

Current anchors: `_column` at 477-490; `_genotype_missing_value_count` at 1071-1080.

A Dict containing both a Symbol and its matching string key is an accepted diagnostic case. Existing tests explicitly report its duplicate marker name. However, the missing-value counter enumerates each original key, then `_column` converts the string key to a Symbol and prefers the Symbol entry. The Symbol column is counted twice, while the string-key column can be omitted.

Deterministic reproduction on frozen source:

```julia
phenotypes = (id = ["a", "b"], y = [1.0, 2.0])
genotypes = Dict(:id => ["a", "b"], :m1 => [0, 1], "m1" => [missing, 3])
rows = data_status(HSData(phenotypes; genotypes)).genotype_status
Dict(row.metric => row.value for row in rows)["missing_genotype_values"]
# observed "0"; the two physical marker columns contain one missing cell
```

This can hide missing genotype values in the surface that diagnoses malformed or duplicate marker names. No model fit or genotype matrix construction is implicated.

Recommended repair after the freeze: the Dict missing-cell counter should read each original key's value directly, while excluding configured ID keys with `_same_column_name`. Preserve the supported duplicate-name diagnostics. Add a regression with differing missingness in the Symbol/string columns and require `missing_genotype_values == "1"`. Test both orientations to catch undercount and double count. This report does not apply that repair.

Closure: D1 must receive a repair on newly frozen bytes and focused regression evidence, or explicit parent/panel acceptance as carried diagnostic debt. Review coverage alone does not waive it.

## 7. Existing repaired neighbors

- The empty-map status guards at 895-898 prevent minimum/maximum on empty vectors; zero counts and unavailable bounds remain distinct.
- `_raw_parent_columns` at 839-853 preserves one recognized parent alias independently and ignores unrelated metadata on the missing side.
- Explicit source-ID lengths use `_row_count`, whose current NamedTuple/Dict methods inspect all columns, reject unequal lengths, and reject columns without applicable length.
- Custom table genotype IDs are excluded from marker counts in both summaries; matrices count every marker column because their row IDs are supplied separately. A fresh string-key `"sample"` probe agreed with the existing Symbol-key test.
- Marker-map IDs, genotype marker membership, and marker order are checked separately from typed sample IDs. Sample IDs keep `1` and `"1"` distinct. Annotation/environment keys deliberately normalize to strings and retain duplicate-key diagnostics.

## 8. Fenced limits and nonblocking follow-ups

F1: delayed validation for inferred table IDs. `_source_ids` calls `_row_count` only when explicit IDs are supplied. A NamedTuple with `id = ["a", "b"]` and `m1 = [0]` is therefore stored successfully when IDs are inferred; `data_status` rejects it with the current unequal-row-count `ArgumentError`. Phenotype columns beyond the ID field are also stored without a whole-table shape check. Accept this only as a metadata-container boundary: constructor success establishes ID hygiene; a rectangular table ready for fitting needs a separate check. Earlier row-count repairs apply to explicit IDs and status. No new malformed-column blanket claim is approved.

F2: raw pedigree positional convention. When neither recognized sire nor dam alias exists, columns 2 and 3 are interpreted as parents. A custom pedigree ID in column 2 is consequently read as a parent and produces self-parent counts. The reader page documents the three-column convention. Accept the fallback only for an ID-first, parent-second, parent-third table; custom ID names do not authorize arbitrary positional order. Prefer recognized aliases or normalized `Pedigree`. Making the ID-first requirement explicit in the reader page is a narrow follow-up; general arbitrary column-order support remains unclaimed.

Other limits: input objects and cached metadata are held by reference, so mutation can make a cached ID/marker summary stale; custom column `length`/property access and unusual numeric conversions can surface their own exceptions; dense/sparse numerical storage, external twin parity, malformed custom table protocols, and fitted output are outside this file's source approval. No claim extends to generic file-backed ingestion or production genomic preprocessing.

## 9. Verification

The one-thread deterministic probe used:

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
JULIA_DEPOT_PATH=/private/tmp/hsq-review-depot:/Users/z3437171/.julia \
julia --compiled-modules=no --project=. /private/tmp/e1-data-exact-current-probe-20260930.jl
```

Estimate stated before launch: under one minute. The process completed within that estimate, with the Julia testset reporting 6/6 assertions in 1.3 seconds. Assertions capture current behavior, including the defect; they are not a green repair test. Printed observations were `DUPLICATE_KEY_MISSING_COUNT reported=0 direct=1`, accepted malformed inferred-ID construction followed by rejection from status, and positional custom-ID self-parent count 2. No package suite, model fit, campaign, network action, GPU action, or external message ran.

Scratch probe: `/private/tmp/e1-data-exact-current-probe-20260930.jl`.

## 10. Graft and workflow evidence

Read-only lane preflight reported two live lanes and a historical Claude handover; this reviewer took only the parent-owned scratch review and preserved repository files. The first full-path route lookup found no manifest; the canonical `route.py HSquared.jl` call returned the LOAD-FIRST manifest. Brain retrieval supplied no task-specific approval, so current repository receipts decided the review.

Graft preceded source reads. Calls: two `skeleton src/data.jl` calls, `grep _marker_map_spec`, `callers _column`, `grep _raw_parent_columns`, and `grep pedigree_id`. The second skeleton was an avoidable repeat after output truncation. Graft's reported savings sum to approximately 209,294 tokens, a tool estimate inflated by its whole-file comparison baseline. The reviewed lines are those in the partition, regardless of that estimate.

## 11. Parent integration and remaining work

Integrate this exact-current file ledger as complete source disposition with HOLD D1. Preserve the frozen source during the approved campaign. After source edits become authorized again, assign the Dict missing-cell counter repair and regression to one owner, then repin the file and reattest only the changed helper and its caller/diagnostic rows. The parent owns E1 panel acceptance, after-task integration, aggregate tree verification, and any status decision. No public covered count or capability state changed in this review.

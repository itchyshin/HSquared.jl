# HSData custom-ID marker-count contract review

Date: 2026-09-30  
Candidate: `codex/hsquared-fa-gllvm-20260927` at HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`  
Reviewer: Curie validation tester role, GPT-6 Luna, medium reasoning effort.

## Exact pins

| File | SHA-256 |
| --- | --- |
| `src/data.jl` | `91ab80b4140459eb406547974876b1d15169d4fb5a2c3676ddaaf9ce3f16541a` |
| `test/runtests.jl` | `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691` |

## Review verdict

**PASS for the focused custom-ID marker-count contract.** `src/data.jl:989-1001` passes the configured `data.genotype_id` through to the generic table fallback, compares names after normalization through `_column_symbol`, and counts every matrix column as a marker when row IDs are supplied separately. This correctly excludes custom table ID names such as `:sample`.

The reviewer also inspected the four-line alternative on `origin/codex/handover-0910-20260907`. It removes the configured ID argument and excludes only a literal column whose string form is `"id"`. That alternative would incorrectly count a `:sample` ID column as a marker, so it was not adopted.

## Test evidence and limits

`test/runtests.jl:2137-2160` covers a default `id` table, a dictionary with symbol/string-equivalent marker names, and a custom `genotype_id = :sample` NamedTuple without a marker map. The custom-ID case expects one marker, distinguishing the current implementation from the alternative. The reviewer did not run tests or edit files.

Remaining narrow test gaps: custom ID in a dictionary, `genotype_id = "sample"`, and string-key custom ID. These are useful hardening cases but do not invalidate the current tested `:sample` contract. The branch alternative and this review do not receive whole-file or E1 signoff. The current source hash remains the one pinned in the 2026-09-29 inventory; all other `src/data.jl` ranges remain outside this receipt.

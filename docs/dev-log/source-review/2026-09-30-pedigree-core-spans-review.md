# Pedigree core source spans review, 2026-09-30

## Scope and pins

Read-only review by Henderson, animal-model specialist, of residual pedigree core spans and direct constructor tests. The exact candidate pins matched:

| File | SHA-256 |
| --- | --- |
| `src/pedigree.jl` | `faccbde29a6e3168921a8c273a4ee19cbaa354c28a2c674705464ad0241369d5` |
| `test/test_pedigree_constructor_contract.jl` | `2e3e36c7b70fda43547dad8e80d4290949d0e6c66c1a5d4618660b6b545555c9` |

The review examined ID validation and parent recoding (`src/pedigree.jl:22,68`), sparse Henderson inverse construction (`:323`), metafounder order/precision boundaries (`:686,708`), and recursive topological sorting (`:835`), plus direct tests (`test/test_pedigree_constructor_contract.jl:32,38`; registered at `test/runtests.jl:11146`). Two refs carry divergent work on `src/pedigree.jl`; no edit or test was made.

## Review findings

- ID uniqueness and missing/unknown marker checks, parent recoding, self-parent rejection, optional selfing, and cycle detection are represented in the inspected code. `pedigree_inverse` accumulates Henderson per-animal sparse contributions using inbreeding-based Mendelian sampling variances; this path does not form dense `A`.
- Raw wrappers align `group_of` with topological pedigree order and distinguish the inverse animal block from combined metafounder precision. The direct test covers wrapper alignment, custom parent markers, selfing, and single-step row alignment.
- Normalization rejects selfing by default, but direct `Pedigree(...)` construction accepts `sire == dam`. The test intentionally constructs this case. Decide whether direct construction is an explicit selfing route; otherwise callers can bypass the default sexual-pedigree policy.
- `_topological_order` uses recursive DFS, which may exhaust the call stack on a very deep pedigree. Existing large-pedigree tests may be shallow; test a deep chain directly.
- The direct test does not exercise invalid or singular `Γ` or fully parented animals without an unknown-group marker. Check for direct tests elsewhere before relying on these contracts.
- Constructor tests do not validate Henderson MME equations, EBV/BLUP extraction, fitted variance components, or uncertainty output. Matched fitted-output comparisons and production sparse-solve evidence remain required before those capabilities are claimed.

## Verdict and limits

Component verdict: **conditional pass** for the inspected normalization, sparse inverse, and wrapper-alignment contracts, with policy and validation findings carried. No animal-model fit or capability signoff is implied. The review does not cover every span in `src/pedigree.jl`, whole E1, Mrode fitted-output validation, or production-scale use.

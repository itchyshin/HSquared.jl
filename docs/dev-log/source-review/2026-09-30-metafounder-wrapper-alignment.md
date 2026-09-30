# Metafounder raw-wrapper alignment review

Date: 2026-09-30  
Scope: raw-array wrapper ID/order contracts and validation-status wording only.  
Branch: `codex/hsquared-fa-gllvm-20260927`  
Base HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`

## Exact reviewed files

| File | SHA-256 |
| --- | --- |
| `src/pedigree.jl` | `faccbde29a6e3168921a8c273a4ee19cbaa354c28a2c674705464ad0241369d5` |
| `src/genomic.jl` | `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f` |
| `src/validation_status.jl` | `95f90c3a166f7ead65afc4205d5139155f86c002c697045388a1b2d383d14010` |
| `test/test_pedigree_constructor_contract.jl` | `2e3e36c7b70fda43547dad8e80d4290949d0e6c66c1a5d4618660b6b545555c9` |
| `docs/src/validation-status.md` | `c7c89e62f6b6c8639e34361036c35f2aa5bdc003a086df6826f9bb5ef0719600` |

## Findings and disposition

- All five raw-array metafounder wrappers route through shared pedigree normalization. `group_of` is reordered by normalized pedigree ID order and the wrappers consistently pass marker/selfing controls.
- The single-step raw-array wrapper maps `genotyped_rows` from caller ID positions into normalized pedigree positions. The supplied genomic matrix `G` remains in the order of the caller-supplied genotype-row vector.
- Documentation now states those ordering contracts for relationship inverse, inbreeding, combined inverse, and single-step routines. The combined precision documentation distinguishes its animal block from the separate animal-model MME route.
- A direct regression rejects out-of-range raw `genotyped_rows`.
- Source and generated validation status retain V1-METAFOUNDER as partial and experimental, limited to supplied-Γ construction and supplied-variance utilities at validation scale. There is no R-facing formula or payload, external comparator, or covered claim. No capability count changed.

## Reviewer evidence

- Henderson and Mrode reviewed the wrapper ID mapping and keyword forwarding. Mrode noted that the explicit cache-limit assertion is on the relationship wrapper, while the remaining wrappers structurally forward the option.
- Rose audited the exact five hashes above and passed the documentation, ordering, input-bound, and public-claim boundary. No reviewer made edits or ran tests.
- This is a narrow wrapper contract review, not a biological comparator, fitted-model, or whole-source-wave signoff.

## Checks

- Exact-current focused test: `test/test_pedigree_constructor_contract.jl`, 38/38 assertions passed (20 direct-constructor assertions and 18 wrapper/status assertions).
- Full `Pkg.test()` passed on the same implementation and status correction before the final documentation-only wording refinements and the additional status-boundary assertion. The exact-current focused test covers those final changes.
- Generated validation page was generated to `/private/tmp` and compared byte-for-byte with `docs/src/validation-status.md`; no difference.
- `git diff --check` passed.
- A full docs build, `preamble_cap.sh`, and global package closeout checks were not run for this slice.
- Julia emitted the existing Project/Manifest dependency compatibility warning. No dependency resolution or manifest update was run.

## Residuals

This slice does NOT cover fitted metafounder models, an external Mrode comparator, broad scale/performance evidence, R syntax or payload, capability promotion, or the remaining FA/GLLVM and Julia source-review gates. The overall programme remains active.

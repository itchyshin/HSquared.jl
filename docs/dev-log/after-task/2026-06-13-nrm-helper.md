# Dense NRM Helper (_numerator_relationship, internal)

Active lenses: Henderson, Mrode, Curie, Rose (inline).
Spawned subagents: none (design from the `phase2-engine-plan` workflow).

## Goal

Provide the full dense numerator (additive) relationship matrix `A` and its
genotyped submatrix `A₂₂` as one internal helper — a prerequisite for the
single-step H-inverse (Slice 5) — while deduplicating a recursion that existed in
three places.

## Files Changed

- `src/pedigree.jl` (added `_numerator_relationship` (2 methods); refactored
  `inbreeding_coefficients` to use it)
- `test/runtests.jl` (removed duplicate `_dense_relationship_for_test`; two
  cross-checks now use `HSquared._numerator_relationship`; new testset
  "Phase 2 dense NRM helper")
- `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/after-task/2026-06-13-nrm-helper.md`

## Implementation

The tabular recursion that builds `A` was computed inside
`inbreeding_coefficients` and then thrown away (only the diagonal was returned),
and was duplicated verbatim as the test-only `_dense_relationship_for_test`. It
now lives once in `_numerator_relationship(pedigree)`, with
`_numerator_relationship(pedigree, rows) = A[rows, rows]` for `A₂₂`.
`inbreeding_coefficients` takes the diagonal of the helper. The bounded-cache
guard moved into the helper (still `ArgumentError`).

## Checks

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed, 632
  total. New testset = 7 checks; the existing pedigree/inbreeding tests are
  unchanged and green (the refactor is behavior-preserving).

## Public Claim Audit

Allowed: internal note that a dense `A` / `A₂₂` helper exists for single-step
construction (validation-only, dense). No capability/validation-debt/
validation_status row — this graduates no user-facing capability.

Blocked: any single-step or large-pedigree/performance claim (this slice
computes `A` only; dense, bounded by the cache guard).

## Tests Of The Tests

The pinned `A` (with an inbred animal, `A[5,5]=1.25`) catches a wrong recursion;
the cross-check against `inv(pedigree_inverse)` is an independent route (sparse
Henderson rules vs the dense recursion); `A₂₂ == A[g,g]` pins the submatrix
method; the diagonal vs `inbreeding_coefficients` ties the refactor to the
existing extractor.

## Coordination Notes

Internal, no public-contract impact. Unblocks the single-step H-inverse slice.

## Known Limitations

- Dense, validation-scale only (bounded by `max_relationship_cache`); not a
  production sparse/large-pedigree builder.

## Next Actions

1. Single-step `H⁻¹` construction utility (`_single_step_Hinv`) using this helper
   for `A` and `A₂₂`.

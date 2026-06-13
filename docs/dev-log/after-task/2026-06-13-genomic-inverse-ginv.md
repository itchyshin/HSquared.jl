# Regularized Genomic Inverse (Ginv)

Active lenses: Kirkpatrick, Falconer, Gauss, Curie, Rose (inline perspectives).
Spawned subagents: none.

## Goal

Finish the Phase-2 `Ginv` slice to Definition of Done. On resume, the working
tree held an uncommitted, untested draft of `genomic_relationship_inverse`. This
slice completes it as a self-contained, additive engine utility — the
ridge-regularized dense inverse of a genomic relationship matrix `G`, which is
the engine-internal step a later GBLUP solve will consume.

## Files Changed

- `src/genomic.jl` (added `genomic_relationship_inverse`; honest docstring)
- `src/HSquared.jl` (export `genomic_relationship_inverse`)
- `test/runtests.jl` (testset "Phase 2 regularized genomic inverse (Ginv)";
  `length(validation)` 15→16)
- `src/validation_status.jl` (row `V2-GINV`; trimmed "Ginv" from `V2-GRM`)
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/after-task/2026-06-13-genomic-inverse-ginv.md`

## Implementation

`genomic_relationship_inverse(G; ridge = 0.01)` returns
`inv(Symmetric(G) + ridge·I)`. A genomic `G` built from markers is usually
rank-deficient (markers < individuals), so a diagonal ridge regularizes it
before inversion. Guards throw `ArgumentError` for a non-square `G`, a negative
ridge, or a regularized matrix that is still not positive definite ("increase
ridge"). `LinearAlgebra` (`Symmetric`, `I`, `isposdef`, `inv`) was already in
module scope.

## Checks

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed, 599
  total checks. New testset = 10 checks: pinned hand inverse at `ridge = 0`
  (det = 2·2 − 0.5² = 3.75), the defining identity `(G + ridge·I)·Ginv ≈ I`,
  symmetry, ridge-changes-result, singular-matrix-throws-at-`ridge = 0`, a
  rank-deficient marker-`G` round-trip with the default ridge, and
  non-square / negative-ridge guards.

## Public Claim Audit

Allowed: `genomic_relationship_inverse` returns the ridge-regularized dense
inverse `inv(G + ridge·I)` of a genomic relationship matrix; validated on the
defining identity plus a hand inverse and guards.

Blocked: GBLUP / SNP-BLUP fitting, single-step `A`/`G` blending (`H`-matrix),
marker-effect estimation, genomic prediction — all still planned. The utility is
**not wired into model fitting**; it only produces a matrix that a later GBLUP
slice could pass as the relationship inverse.

## Tests Of The Tests

The pinned `ridge = 0` inverse would fail for a wrong determinant or a
transpose error; the `(G + ridge·I)·Ginv ≈ I` identity ties the result to the
regularized matrix actually inverted (catching a wrong/forgotten ridge); the
singular-matrix case proves the PD guard fires; the rank-deficient marker-`G`
round-trip proves the default ridge rescues the realistic (m < n) case.

## Coordination Notes

Additive, engine-internal — no bridge / result / model-spec change, so no R-twin
action is required for this slice. The contract-touching parts (GBLUP wiring of
`G` into the MME, and the R `genomic()`/`markers()` → engine model-spec mapping)
remain the next slice and will be coordinated with the R twin before landing.

## What Did Not Go Smoothly

- Nothing notable. The draft was correct; this slice added the evidence chain
  (test, status rows, docs, after-task) it was missing.

## Known Limitations

- Construction only; not wired into GBLUP/fitting; no single-step blending.
- Dense inverse `O(n³)`; large-scale / sparse `Ginv` and Metal-GPU dense
  acceleration are later optimizations.
- Fixed-constant ridge; no data-driven ridge selection or `G`↔`A` blending.
- No external comparator (AGHmatrix/sommer/BLUPF90) yet.

## Next Actions

1. Coordinate the genomic model-spec contract with the R twin, then wire `G`/
   `Ginv` into the Henderson MME for GBLUP (reuses the existing engine).
2. External comparator (AGHmatrix/sommer) to move `V2-GRM` / `V2-GINV` toward
   covered.

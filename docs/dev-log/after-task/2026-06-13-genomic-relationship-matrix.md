# Genomic Relationship Matrix (VanRaden G)

Active lenses: Falconer, Kirkpatrick, Curie, Jason, Rose (inline perspectives).
Spawned subagents: none.

## Goal

Begin Phase 2 (genomic relationship models) with the VanRaden (2008) genomic
relationship matrix `G` — the foundational, self-contained, dense engine utility
that GBLUP / single-step build on, and the dense linear-algebra piece where the
local Apple M1 Ultra GPU (Metal) will pay off later.

## Files Changed

- `src/genomic.jl` (new; `genomic_relationship_matrix`)
- `src/HSquared.jl` (include + export)
- `test/runtests.jl` (testset "Phase 2 genomic relationship matrix (VanRaden)";
  `length(validation)` 14→15)
- `src/validation_status.jl` (row `V2-GRM`)
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/coordination-board.md`,
  `docs/dev-log/after-task/2026-06-13-genomic-relationship-matrix.md`

## Implementation

`genomic_relationship_matrix(markers; allele_frequencies = nothing)` returns the
dense symmetric `G = Z Zᵀ / (2 Σ_j p_j(1−p_j))` with `Z = markers − 2p`. Markers
are individuals×markers, coded 0/1/2 (or dosages in [0,2]). Allele frequencies
are estimated from the columns (`p_j = mean / 2`) unless supplied. Validated and
range/monomorphic guards throw `ArgumentError`.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. New testset = 9 checks:
  pinned hand-computed entries (`G[1,1] = 1.130435`, `G[1,2] = -1.304348` for a
  4×3 fixture), symmetry, PSD (`eigmin ≈ 0`), supplied-frequency parity, and
  coding/length/monomorphic guards.

## Public Claim Audit

Allowed: `genomic_relationship_matrix` builds the VanRaden `G` from a marker
matrix; validated on a tiny hand-computed fixture.

Blocked: `Ginv`, GBLUP / single-step fitting, marker-effect estimation, genomic
prediction, marker/QTL/eQTL scans — all still planned. `G` is rank-deficient
when markers < individuals and is not invertible without regularization.

## Tests Of The Tests

The pinned entries would fail for a wrong centering (`2p`) or scaling
(`2 Σ p(1−p)`); the PSD check guards against a sign/transpose error; the
supplied-frequency parity check ties the estimated-frequency path to an explicit
frequency vector.

## Coordination Notes

Phase boundary. Engine-internal, additive — no bridge / result / model-spec
change. Heads-up posted to `hsquared` issue #9. The contract-touching genomic
model-spec (R `genomic()`/`markers()` → engine) + `Ginv`/GBLUP wiring is the next
slice and will be coordinated with the R twin before landing.

## What Did Not Go Smoothly

- Nothing notable; the VanRaden formula was verified numerically before
  implementation (hand-computed reference entries).

## Known Limitations

- Construction only; no `Ginv`/GBLUP/single-step/marker effects.
- Dense `G` (O(n²·m)); GPU (Metal) acceleration of the dense products is a later
  optimization, and large-scale/streaming marker handling is Phase 8.
- No external comparator (AGHmatrix/sommer/BLUPF90) check yet.

## Next Actions

1. Coordinate the genomic model-spec contract with the R twin, then `Ginv`
   (regularized) + wire `G` into the MME for GBLUP (reuses the existing engine).
2. External comparator (AGHmatrix/sommer) to move `V2-GRM`/`V5-GBLUP` toward
   covered.
3. Metal GPU acceleration of the dense `G` products once GBLUP is in place.

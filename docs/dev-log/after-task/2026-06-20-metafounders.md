# After-task — Supplied-Γ metafounders (#53)

Date: 2026-06-20. Lane: Julia engine. Branch: `julia/s53-metafounders`. Innovation
backlog #53 (metafounders), built this ultracode session.

## Summary

Extended the relationship-matrix family to unknown-parent groups ("metafounders",
Legarra et al. 2015): `metafounder_relationship` (dense `A^Γ`), `metafounder_inverse`
(combined `[metafounders; animals]` sparse Henderson inverse), the distinct descriptive
`metafounder_relationship_inverse` (animal-only `inv(A^Γ)`), and `metafounder_inbreeding`,
from a USER-SUPPLIED `m×m` metafounder covariance `Γ` and a `group_of` assignment. `A^Γ`
is the existing tabular recursion with the `Γ` block seeded and unknown parents remapped
to metafounder columns. Supplied-Γ / descriptive — `Γ` is never estimated.

The algorithm was pinned by an ultracode design+scout Workflow (literature, engine
design, codebase integration, R-coordination → synthesis). One synthesis claim (reduction
at "Γ=I") was corrected by first-principles derivation to **Γ=0** and confirmed by the
reduction test against `_numerator_relationship`/`pedigree_inverse` (the
construction-independent ground truth).

## Definition of Done

- implementation — four exported functions + wrappers + internal helpers in
  `src/pedigree.jl`, reusing the tabular recursion + `_mendelian_sampling_variance`.
- tests — "Phase 1 metafounder relationship / inverse (supplied Γ, #53)": reduction,
  independent dense oracle, round-trip, shared-MF relatedness, two-inverse distinctness,
  full guard set, convenience wrappers. Full suite green (37 status rows).
- documentation — docstrings (supplied-Γ / descriptive / two-inverse distinction /
  Γ-scale convention); api.md (4 exports); capability-status experimental row.
- validation-debt — `V1-METAFOUNDER` (`partial`) in `validation_status()`.
- scout note — `docs/dev-log/scout/2026-06-20-metafounder-Agamma-algorithm-pin.md`.
- check-log — `docs/dev-log/check-log.d/2026-06-20-metafounders.md`.
- after-task — this file.
- Rose audit — run before merge (claim-vs-evidence gate).
- clean local checks — `Pkg.test()` + `docs/make.jl` exit 0.

## Key correctness anchors (construction-independent)

- `Γ=0` ⇒ `A^Γ == additive_relationship`, `metafounder_relationship_inverse ==
  pedigree_inverse`, `metafounder_inbreeding == inbreeding_coefficients` (exact).
- `A_combined · metafounder_inverse == I` round-trip (~3.3e-16).
- Independent dense tabular oracle (written in the test) with a two-group PD `Γ`.
- The combined-inverse animal block is deliberately NOT `inv(A^Γ_animals)`
  (two-inverse-distinctness gate guards against conflation).

## Claim boundary

Supplied-Γ, descriptive, validation-scale, dense. `Γ` is an INPUT, never estimated. No
external comparator (AGHmatrix/nadiv lack metafounder Γ; opt-in BLUPF90 deferred), no
R-facing metafounder model-spec / bridge payload, not wired into `henderson_mme`, no
single-step `H^Γ`. Nothing promoted to covered.

## Next (deferred, on #61 / roadmap)

- R-lane coordination on the metafounder / unknown-parent-group vocabulary + Γ payload
  (posted to #61) — gate any bridge on ratification.
- Γ estimation (García-Baccino Fst/MoM) — separate genomic problem, out of supplied-Γ scope.
- Opt-in BLUPF90 (preGSf90/GAMMAF90) external-comparator scaffold (JWAS-style env gate).
- Single-step `H^Γ` + wiring `metafounder_inverse` into the MME as extra random levels.
- Per-slot (sire/dam separate) metafounder assignment for crossbred animals.

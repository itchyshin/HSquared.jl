# 2026-06-20 Supplied-Γ metafounder relationship / inverse (#53)

- Goal: innovation-backlog #53 — extend the relationship-matrix family to
  unknown-parent groups ("metafounders", Legarra et al. 2015) with a SUPPLIED Γ.
  Descriptive / supplied-Γ (Γ NOT estimated), validation-scale.
- Lenses: Henderson + Mrode + Gauss (numerics/MME), Kirkpatrick (Γ as covariance),
  Mendel + Falconer (interpretation), Rose (claim gate). Algorithm pinned by an
  ultracode design+scout Workflow (Jason literature, Henderson engine design, Explore
  codebase, Shannon R-coordination → Ada synthesis); scout note at
  `docs/dev-log/scout/2026-06-20-metafounder-Agamma-algorithm-pin.md`.

## What was done

- `src/pedigree.jl` (exported): `metafounder_relationship` (dense `A^Γ`),
  `metafounder_inverse` (combined `[metafounders; animals]` sparse Henderson inverse,
  `inv(Γ)` block + `[1,-½,-½]/d_k` outer products), `metafounder_relationship_inverse`
  (descriptive animal-only `inv(A^Γ)` — DISTINCT from the combined inverse),
  `metafounder_inbreeding`, plus `(ids,sire,dam,group_of,Γ)` wrappers and internal
  helpers `_metafounder_combined_indices` / `_metafounder_combined_A` / `_validate_gamma`.
  `group_of` mirrors `clone_of`; unknown parents remapped to metafounder columns;
  metafounder `F = Γ−1` (negative allowed), `d_k` not clamped.
- Deterministic testset "Phase 1 metafounder relationship / inverse (supplied Γ, #53)":
  REDUCTION to `additive_relationship`/`pedigree_inverse`/`inbreeding_coefficients` at
  `Γ=0`; INDEPENDENT dense tabular oracle (two-group `Γ`); `A_combined·metafounder_inverse=I`
  round-trip; shared-metafounder relatedness (off-diag `γ`, diag `1+γ/2`);
  two-inverse distinctness; `Γ` dim/symmetry/PSD/PD + group-label + remap + length
  guards; convenience-wrapper agreement.
- Honest status: `V1-METAFOUNDER` (`partial`) in `validation_status()` (36 → 37);
  capability-status experimental row; api.md (4 exports); docstrings state
  supplied-Γ/descriptive/two-inverse-distinct/validation-scale and the `Γ`-scale
  convention.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (metafounder testset green; reduction exact; round-trip ~3.3e-16; `validation_status()`
  37 rows).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (exit 0)** (4 new api.md
  entries resolve).

## Claim boundary

Descriptive supplied-Γ construction at validation scale — `Γ` is an INPUT, never
estimated. NO external-comparator evidence (AGHmatrix/nadiv do not implement metafounder
Γ; opt-in BLUPF90 deferred), NO R-facing metafounder model-spec or bridge payload, NOT
wired into `henderson_mme`, NO single-step `H^Γ`. Nothing promoted to covered.

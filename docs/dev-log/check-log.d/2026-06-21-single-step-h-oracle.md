# 2026-06-21 single-step dense-H oracle fixture

- Goal: harden the ordinary single-step H-inverse construction by checking it
  against an independent dense-H relationship oracle.
- Lenses: Gauss + Noether (H/H-inverse algebra), Mrode + Fisher + Curie
  (validation target boundary), Rose (claim boundary), Grace (checks),
  Ada + Shannon (lane discipline).
- Spawned subagents: none.

## Commands

- Focused one-off algebra probe mirroring the test oracle — passed. The
  independent dense-H oracle round-tripped with `_single_step_Hinv` at machine
  precision for trailing genotyped rows (`max left/right residual 6.66e-16`) and
  scattered genotyped rows (`2.22e-16`).
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The updated
  `Phase 2 single-step H-inverse construction` testset passed 18/18.
- `julia --project=docs docs/make.jl` — passed, with the existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

## Boundary

This is an internal algebra fixture, not a published Mrode Ch.11 target and not
external comparator evidence. It checks the package H-inverse against a dense-H
oracle for validation-scale matrices only; blending defaults, BLUPF90/AGHmatrix
parity, R formula/payload work, metafounder comparator evidence, and sparse/APY
scaling remain open.

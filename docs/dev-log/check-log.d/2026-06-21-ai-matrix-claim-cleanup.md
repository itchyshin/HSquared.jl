# 2026-06-21 AI-matrix claim cleanup (#38)

- Goal: close the R-lane flagged stale claim in
  `docs/design/03-engine-contract.md` without changing engine behavior.
- Lenses: Rose (claim boundary), Fisher + Gauss (information-matrix wording),
  Shannon (R-lane request honored in Julia repo only).
- Spawned subagents: none.

## Commands

- `rg -n "250-animal|0\\.99|eigen-G|eigen G|AI matrix matches" docs/design/03-engine-contract.md`
  — verified no stale 250-animal, 0.99, or eigen-G wording remains; only the
  corrected finite-difference Hessian claim remains.
- `julia --project=docs docs/make.jl` — passed, with existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

## Boundary

Doc-only wording cleanup. This does not add validation evidence, does not widen
the AI-REML claim, and does not change code or tests.

# 2026-06-21 BLUPF90 multivariate comparator starter packet

- Goal: prepare a reproducible BLUPF90/RENUMF90/AIREMLF90 starter packet for the
  existing `test/fixtures/phase4_multitrait_parity/` fixture.
- Lenses: Curie + Fisher + Mrode (same-estimand validation target), Rose
  (claim boundary), Grace (local checks), Shannon (R/Julia lane separation).

## Commands

- `julia comparator/prepare_blupf90_multitrait.jl` — passed and generated
  ignored files under `comparator/blupf90_multitrait/`:
  `blupf90_multitrait.dat`, `blupf90_multitrait.ped`,
  `hsquared_targets.csv`, and `renumf90.par`.
- `git status --short --ignored comparator/blupf90_multitrait comparator/prepare_blupf90_multitrait.jl .gitignore`
  — confirmed generated packet files are ignored and only the script/README are
  untracked or modified for commit.

## Boundary

This is not BLUPF90 evidence and does not promote `V4-MV-REML`. It only reduces
setup friction for a future second same-estimand comparator leg. A real evidence
record still needs BLUPF90-family executables, versions, generated `renf90.par`,
convergence output, aligned estimates, tolerance, and Rose audit.

## Repo Checks

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` — passed. Existing-style
  local-build warnings were observed for undocumented docstrings, missing local
  Vitepress logo/favicon assets, skipped deployment detection, and npm audit
  output.
- `git diff --check` — passed.

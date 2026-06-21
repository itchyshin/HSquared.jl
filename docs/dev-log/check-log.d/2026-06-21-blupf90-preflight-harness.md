# 2026-06-21 BLUPF90 multivariate preflight harness

- Goal: harden the BLUPF90/AIREMLF90 second-comparator setup for the existing
  two-trait REML fixture without claiming external evidence.
- Lenses: Curie + Fisher + Mrode (same-estimand validation target), Rose
  (claim boundary), Grace (local checks), Ada + Shannon (R/Julia lane split).
- Spawned subagents: none.

## Commands

- `julia comparator/prepare_blupf90_multitrait.jl` — passed. Generated and
  validated 80 phenotype rows and 20 pedigree rows under
  `comparator/blupf90_multitrait/`; local executable probe reported
  `renumf90`, `airemlf90`, `blupf90`, `remlf90`, and `gibbsf90` not found.
- `julia comparator/run_blupf90_multitrait.jl` — passed skip guard. Generated
  and validated the packet, then exited 0 without running external software
  because `HSQUARED_RUN_BLUPF90` was unset.

## Boundary

This is not BLUPF90 evidence and does not promote `V4-MV-REML`. It validates
the packet shape, removes header/comment rows from BLUPF90-consumed generated
files, and adds a skip-safe opt-in runner. A real evidence record still needs
BLUPF90-family executable versions, generated `renf90.par`, convergence output,
aligned estimates, tolerance, and Rose audit.

## Repo Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The new
  `BLUPF90 multivariate starter packet preflight (#49)` testset passed 19/19.
- `julia --project=docs docs/make.jl` — passed, with existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

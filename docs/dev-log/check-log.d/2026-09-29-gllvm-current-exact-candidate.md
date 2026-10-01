# 2026-09-29 current-candidate GLLVM regression and live bridge check

## Checks

- Julia focused command with one BLAS thread and four Julia threads:
  `julia --project=. --startup-file=no test/genetic_gllvm_trait_effects.jl`
  passed 73/73 assertions. The new multi-column fixed-effect Gaussian
  reduction and basis-change check passed 6/6.
- Full Julia `Pkg.test()` exited 0 and ended with
  `Testing HSquared tests passed`. It emitted the existing project/manifest
  mismatch warning; no `Pkg.resolve()` or update was run.
- Live R command with JuliaCall pointed at the current Julia candidate:
  `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-gllvm-depot:/Users/z3437171/.julia HSQUARED_JULIA_PROJECT=/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl HSQUARED_JULIA_TESTS=true Rscript --vanilla -e 'devtools::test(filter = "gllvm-optin")'`
  passed 87/87 in 18.5 seconds, zero failures, zero warnings, zero skips.
  The live direct-fit parity and trait-order fit both executed.
- Julia source and matched R candidate hashes are recorded in
  `docs/dev-log/source-review/2026-09-29-gllvm-current-exact-candidate.md`.
- `git diff --check -- test/genetic_gllvm_trait_effects.jl` passed.

## Limits

These results do not close whole-file E1, FA A2, or full-candidate V3. They do
not establish external comparator agreement, population recovery, broad
calibration, public capability promotion, or release readiness.

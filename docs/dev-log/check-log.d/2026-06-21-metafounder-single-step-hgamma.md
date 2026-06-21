# 2026-06-21 Metafounder single-step H^Gamma bridge primitive

- Goal: finish the Julia-owned bridge primitive for supplied-Gamma
  metafounder single-step `H^Gamma` while preserving the validation and public
  claim boundary.
- Lenses: Hopper + Boole + Emmy (bridge/payload target shape), Gauss +
  Noether (relationship precision), Curie + Fisher + Mrode (validation gate),
  Rose (claims), Grace (checks), Ada + Shannon (lane split).

## Commands

- `for exe in renumf90 airemlf90 blupf90 remlf90 gibbsf90; do ...; done` —
  all five BLUPF90-family executables were missing on `PATH` in this local
  environment. The PR #127 packet generator is therefore locally blocked from a
  real second-comparator run, not contradicted by one.
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
  The new test set `Phase 2 metafounder single-step H^Gamma bridge primitive`
  passed 10/10 assertions.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` — passed. Existing-style
  local-build warnings were observed for omitted internal docstrings, skipped
  deployment detection, default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

## Evidence

- `metafounder_single_step_inverse` builds dense `H^Gamma^-1` by replacing the
  pedigree relationship in the ordinary single-step update with the
  animal-only `A^Gamma` block.
- Reduction gate: `Gamma = 0` reduces to the existing ordinary
  `single_step_inverse` path.
- Manual-construction gate: nonzero `Gamma` equals manually building `A^Gamma`
  / `inv(A^Gamma)` and calling ordinary `single_step_inverse`.
- Wrapper gates: supplied-variance and REML helper functions delegate through
  the same `H^Gamma` precision.

## Boundary

This is engine-side bridge readiness only. `Gamma` is supplied, not estimated;
the implementation is dense/validation-scale; blending/tau/omega/ridge defaults
are not comparator-validated; no R formula payload or bridge fixture is claimed;
no BLUPF90 or other single-step-metafounder comparator was run; no capability is
promoted to covered.

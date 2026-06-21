# 2026-06-21 JWAS fitted-target agreement probe

- Goal: turn the existing opt-in JWAS comparator scaffold for
  `test/fixtures/animal_model_fitted_target/` into a runnable local probe and
  record the result without promoting any validation row.
- Lenses: Curie + Fisher + Mrode (validation target and estimator boundary),
  Jason (JWAS source/setup scout), Rose (claim boundary), Grace (checks),
  Ada + Shannon (lane discipline).
- Spawned subagents: none.

## Commands

- `command -v renumf90 || true; command -v airemlf90 || true; command -v blupf90 || true; command -v remlf90 || true; command -v gibbsf90 || true`
  — no BLUPF90-family executable was found on `PATH`, so the multivariate
  same-estimand BLUPF90 comparator remains locally blocked.
- `julia --project=comparator comparator/run_jwas_animal_model.jl` — passed
  skip guard, exits 0 without importing JWAS when `HSQUARED_RUN_JWAS` is unset.
- `julia --project=comparator -e 'using Pkg; Pkg.instantiate()'` — failed before
  edits because JWAS is not registered in Julia General and the local UUID was
  stale/wrong.
- `julia --project=comparator comparator/setup_jwas_env.jl` — passed after
  edits; installed JWAS 2.3.6 from `https://github.com/reworkhow/JWAS.jl` into
  the git-ignored comparator manifest.
- `HSQUARED_RUN_JWAS=true julia --project=comparator comparator/run_jwas_animal_model.jl`
  — passed after the output-directory fix. JWAS 2.3.6, Julia 1.10.0, seed
  `20260620`, `chain_length = 50000`, `burnin = 10000`,
  `output_samples_frequency = 100`; 20/20 animal EBVs aligned; EBV correlation
  against the HSquared.jl REML target was `0.999`; max absolute EBV difference
  was `0.1103`.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `julia --project=docs docs/make.jl` — passed, with existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

## Boundary

This is a Bayesian/MCMC agreement probe, not same-estimand REML parity. It does
not promote `V1-MME`, does not validate fitted Mrode outputs, and does not
replace R-lane or production-software comparator evidence. The useful evidence
is that an independent Bayesian animal-model implementation gives nearly
identical EBV ranking on the serialized fitted target.

Generated JWAS files are ignored under `comparator/Manifest.toml`,
`comparator/_jwas_pedigree.csv`, `comparator/IDs_for_individuals_with_pedigree.txt`,
and `comparator/results/`.

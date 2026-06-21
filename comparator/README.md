# Opt-in external comparators (`comparator/`)

This directory holds **opt-in, outside-CI** external comparator runners. They use a
**separate Julia environment** (`comparator/Project.toml`) so their heavy/3rd-party
dependencies (e.g. JWAS) are **never** package dependencies of HSquared.jl and are
never imported by the engine or its test suite.

## JWAS animal-model comparator (#49)

`run_jwas_animal_model.jl` fits the same single-trait animal model as the serialized
target fixture (`test/fixtures/animal_model_fitted_target/`) with **JWAS.jl** and
reports **agreement** with the engine's REML target.

```sh
julia --project=comparator -e 'using Pkg; Pkg.instantiate()'
HSQUARED_RUN_JWAS=true julia --project=comparator comparator/run_jwas_animal_model.jl
```

Without `HSQUARED_RUN_JWAS=true` the runner prints a skip notice and exits 0 (and
does not import JWAS).

### Honesty

- JWAS is **MCMC/Bayesian**; HSquared.jl reports **REML**. These are different
  estimators, so agreement is expected only **approximately** (shrinkage, prior,
  Monte-Carlo error). The runner reports agreement (EBV correlation + max abs
  difference); it **never** claims "parity" or "validation".
- A comparator run does **not** by itself move any capability to `covered` — the
  evidence chain (tolerance, versions, design) must be recorded first.
- The JWAS public API has shifted across releases; confirm the
  `build_model`/`set_covariate`/`set_random`/`get_pedigree`/`runMCMC` names + output
  keys against your installed JWAS version (the runner flags this inline).

`comparator/Manifest.toml` is git-ignored (instantiate locally); only
`Project.toml` is committed.

## BLUPF90/AIREMLF90 multivariate starter packet

`prepare_blupf90_multitrait.jl` rewrites the deterministic two-trait fixture
(`test/fixtures/phase4_multitrait_parity/`) into a BLUPF90-family starter
packet under `comparator/blupf90_multitrait/`.

```sh
julia comparator/prepare_blupf90_multitrait.jl
```

The generated packet contains whitespace-delimited data/pedigree files, a
target-covariance CSV, and a conservative starter `renumf90.par` template for a
future RENUMF90/AIREMLF90 run:

```sh
cd comparator/blupf90_multitrait
renumf90 renumf90.par
airemlf90 renf90.par
```

Generated BLUPF90 input/output files are git-ignored. This is **not** comparator
evidence until BLUPF90-family executables are actually run, versions and
generated `renf90.par` are recorded, outputs are aligned to the fixture targets,
and a Rose audit confirms the claim boundary.

# 2026-06-19 Julia-native fitted target fixture + JWAS comparator scaffold (#46/#49)

- Goal: serialize a Julia-native FITTED univariate animal-model target (#46, the
  long-standing fitted-Mrode debt) and add an opt-in JWAS.jl comparator scaffold
  (#49), without typing textbook EBVs from memory and without adding a package
  dependency.
- Lenses: Mrode (validation canon) + Curie + Fisher; Rose (claim gate).

## What was done

- `test/fixtures/animal_model_fitted_target/`: `generate.jl` (the engine fits its
  OWN single-trait REML animal model on a 20-animal multi-generation pedigree with
  a covariate `x`, interior optimum, and serializes the output) + the serialized
  CSVs (`pedigree`, `phenotypes`, `expected_variance_components`/`beta`/`ebv`/
  `reliability`/`metadata`) + `README.md`. RNG is used once in `generate.jl` to
  realize a dataset with genuine additive structure; the committed fixture + test
  are deterministic.
  - Fitted target: `sigma_a2 = 1.0940`, `sigma_e2 = 0.6855`, `h² = 0.6148`,
    `loglik = -31.8096`, `Intercept = 5.147`, `x = 2.251`, converged.
- Committed CI test (`test/runtests.jl`, "Univariate fitted animal-model target
  fixture (#46)"): rebuilds `Ainv` from the pedigree and checks SELF-CONSISTENCY —
  the Henderson MME at the stored variance components reproduces the stored
  β/EBVs/PEV/reliability and the REML loglik (`sparse_reml_loglik`), plus
  interior/label/converged checks.
- `comparator/` (opt-in, outside CI, separate env): `Project.toml` (JWAS + CSV/
  DataFrames/etc. — NOT package deps), `run_jwas_animal_model.jl` (env-gated
  `HSQUARED_RUN_JWAS=true`; skips + exits 0 otherwise without importing JWAS;
  reports AGREEMENT, not parity), `README.md`. `.gitignore` ignores the comparator
  Manifest + temp pedigree.
- Decision note `docs/dev-log/decisions/2026-06-19-univariate-target-and-jwas-comparator-protocol.md`.
- Rows: new capability-status "Fitted univariate animal-model target fixture" row;
  `V1-MME` validation-debt updated to cite the serialized target + opt-in comparators.
  Package `Project.toml` UNCHANGED (no JWAS).

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → (recorded after run).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → unaffected (no `src/` or
  `docs/src/` change); confirmed after run.
- The JWAS comparator is opt-in / outside CI and is NOT exercised by the suite.

## Claim boundary

A SERIALIZED confrontation target + opt-in comparator scaffold — NOT external
validation. The committed test is self-consistency only. JWAS is MCMC/Bayesian vs
the engine's REML, so any agreement is approximate by construction (reported
honestly, never "parity"). No comparator evidence recorded yet; no capability moved
to covered. The R-lane `nadiv`/`pedigreemm` confrontation is cross-lane (#61/#46).

# After-task — Fitted univariate target fixture + JWAS comparator scaffold (2026-06-19)

Overnight autonomous runway run (Ada). The last committed item of the BT2/BT3
runway (#46 fitted target + #49 JWAS comparator).

## Goal

Retire the long-standing fitted-Mrode debt with a Julia-native FITTED univariate
animal-model target (#46) and add a Julia-native MCMC comparator scaffold (#49),
honestly, without typing textbook EBVs from memory and without adding a package
dependency.

## What landed

- `test/fixtures/animal_model_fitted_target/` — the engine fits its OWN single-trait
  REML model (`generate.jl`, 20-animal multi-generation pedigree + covariate,
  interior optimum) and serializes the output. Committed CI self-consistency test
  (Henderson MME at the stored VCs reproduces β/EBVs/PEV/reliability/loglik).
- `comparator/` — opt-in JWAS.jl runner in a separate env (`HSQUARED_RUN_JWAS=true`),
  reporting agreement (not parity). JWAS is never a package dependency.
- Decision note + capability-status / `V1-MME` rows + `.gitignore`.

## Honesty / Mrode rule

The fitted target is the engine's OWN output, serialized — NOT external evidence.
No textbook EBVs were typed from memory. JWAS is MCMC/Bayesian vs the engine's
REML, so agreement is approximate by construction and is reported, never claimed as
"parity"/"validation". The R-lane `nadiv`/`pedigreemm` confrontation is cross-lane
(coordinate on #61/#46). No capability moved to covered.

## Local checks

- `Pkg.test()` → exit 0 (new fitted-target self-consistency testset).
- `docs/make.jl` → unaffected (no `src/`/`docs/src/` change).

## Note on the JWAS API

The JWAS public API has shifted across releases; the runner flags inline that the
`build_model`/`set_covariate`/`set_random`/`get_pedigree`/`runMCMC` names + output
keys must be confirmed against the installed JWAS version. The scaffold is opt-in
plumbing (outside CI), so this is a run-time concern for whoever instantiates the
comparator env, not a CI gate.

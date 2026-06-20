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

## Local checks + review

- **AUTHORITATIVE — CI on a clean checkout (PR #72):** Julia 1 / 1.10 / docs /
  deploy all pass. `Pkg.test()` exit 0 (fitted-target testset 13/13);
  `docs/make.jl` exit 0.
- 2-lens review (Mrode/Curie + Rose). Mrode **pass_with_nits** — verified by
  *running*: re-ran `generate.jl` (byte-for-byte reproducible), mutation-tested the
  self-consistency test (non-vacuous), confirmed the interior optimum + the
  cross-method checks. Nits addressed: a test/README note that EBV self-consistency
  re-solves the same MME (β/loglik/PEV span distinct routes); strengthened the JWAS
  `ID`-column caveat; dropped the unused `Random` from `comparator/Project.toml`.
- Rose **concerns** (evidence-integrity, not an overclaim): Dropbox sync can
  transiently rewrite the committed fixture CSVs mid-run (Rose caught a conflicted
  `x,9.9` and a 1/13 spurious failure). The committed fixtures are correct and CI on
  a clean checkout (and Rose's `git archive HEAD` export) is green. **Resolution:**
  CI on a clean checkout is the authoritative gate (which is why every PR this
  session was CI-gated); recorded the Dropbox caveat in the check-log.

## Note on the JWAS API

The JWAS public API has shifted across releases; the runner flags inline that the
`build_model`/`set_covariate`/`set_random`/`get_pedigree`/`runMCMC` names + output
keys must be confirmed against the installed JWAS version. The scaffold is opt-in
plumbing (outside CI), so this is a run-time concern for whoever instantiates the
comparator env, not a CI gate.

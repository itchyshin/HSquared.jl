# After-task — JWAS fitted-target agreement probe

Date: 2026-06-21. Lane: Julia engine (`HSquared.jl`). Branch:
`codex/jwas-comparator-probe`. Type: validation/comparator evidence slice.

## Live Phase Snapshot

As of this report, Julia `main` is `758349d` after the supplied-Gamma
single-step `H^Gamma` primitive. R `hsquared` main has the live
metafounder/H^Gamma bridge banked separately. The multivariate `V4-MV-REML`
second-comparator gate remains locally blocked for BLUPF90-family software
because `renumf90`, `airemlf90`, `blupf90`, `remlf90`, and `gibbsf90` are not
on `PATH`. This slice records one opt-in JWAS agreement probe for the
univariate fitted target; no capability is promoted to covered.

## Goal

Start the Big-3 evidence lane by attempting the highest-leverage comparator
work. Because the BLUPF90 same-estimand multivariate run is still locally
blocked, make the existing JWAS univariate comparator scaffold runnable and
record what it can honestly say.

## Active Lenses

Curie + Fisher + Mrode checked the validation target and estimator mismatch.
Jason checked the JWAS source/setup facts. Rose kept the claim boundary clean.
Grace covered local checks. Ada + Shannon kept the R/Julia lane split. No
subagents were spawned.

## Files Changed

- `.gitignore` — ignores JWAS local output files under `comparator/`.
- `comparator/Project.toml` — correct JWAS UUID and setup instruction.
- `comparator/setup_jwas_env.jl` — opt-in unregistered JWAS setup helper.
- `comparator/README.md` and `comparator/run_jwas_animal_model.jl` — updated
  setup command and output hygiene.
- `src/validation_status.jl`, `test/runtests.jl`,
  `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/src/validation-status.md` — record JWAS agreement without promotion.
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-jwas-comparator-probe.md`
- `docs/dev-log/scout/2026-06-21-jwas-comparator-setup.md`

## Commands / Results

- BLUPF90-family executable probe — no `renumf90`, `airemlf90`, `blupf90`,
  `remlf90`, or `gibbsf90` was found on `PATH`.
- `julia --project=comparator comparator/run_jwas_animal_model.jl` — passed the
  skip guard when `HSQUARED_RUN_JWAS` was unset.
- `julia --project=comparator -e 'using Pkg; Pkg.instantiate()'` — failed
  before edits because JWAS is unregistered and the local UUID was stale/wrong.
- `julia --project=comparator comparator/setup_jwas_env.jl` — passed; installed
  JWAS 2.3.6 from `https://github.com/reworkhow/JWAS.jl` into the git-ignored
  comparator manifest.
- `HSQUARED_RUN_JWAS=true julia --project=comparator comparator/run_jwas_animal_model.jl`
  — passed after output hygiene edits. JWAS 2.3.6, Julia 1.10.0, seed
  `20260620`, `chain_length = 50000`, `burnin = 10000`, 20 aligned animals,
  EBV correlation `0.999`, max abs EBV difference `0.1103` against the
  HSquared.jl REML target.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `julia --project=docs docs/make.jl` — passed, with existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.
- `git diff --check` — passed.

## Public Claim Audit

Clean with limitations. The JWAS run is an independent Bayesian/MCMC agreement
probe. It is not same-estimand REML parity, not fitted-Mrode validation, not a
production-software comparator, and not a covered-status gate. The useful claim
is limited to: "the opt-in JWAS 2.3.6 probe gives nearly identical EBV ranking
on the serialized fitted target."

## Tests Of The Tests

The `validation_status()` test now requires the `V1-MME` row to mention
`JWAS 2.3.6` and to keep the claim boundary phrase `agreement only`. The JWAS
runner remains env-gated; without `HSQUARED_RUN_JWAS=true` it exits 0 before
importing JWAS.

## Coordination Notes

R lane was not edited. The R twin still owns same-estimand R comparator work and
public user-facing evidence summaries. This Julia slice only records a Julia
opt-in comparator probe and keeps the BLUPF90 multivariate blocker explicit.

## Known Limitations / Next Actions

- Run a true same-estimand REML comparator for the fitted target or multivariate
  fixture when tooling is available.
- Keep BLUPF90-family multivariate evidence blocked until executables are
  available.
- Do not promote `V1-MME` or `V4-MV-REML` on the JWAS probe.

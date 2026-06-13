# R Henderson MME Bridge Target Sync

Date: 2026-06-13

Active lenses: Ada, Hopper, Henderson, Fisher, Rose, Grace.

Spawned subagents: none.

## Goal

Mirror the R twin's explicit opt-in supplied-variance Henderson MME bridge
target in Julia status and docs while keeping Julia APIs and `result_payload()`
unchanged.

## R Handoff

R commits:

- `99d974a Add Henderson MME bridge target`;
- `00b9e33 Record Henderson MME bridge CI evidence`.

Reported R evidence:

- R-CMD-check `27462763849`: success;
- pkgdown `27462763842`: success;
- Pages `27462799025`: success.

R behavior:

- user can opt into `hs_control(engine = "julia", engine_control =
  list(target = "henderson_mme", variance_components = ...))`;
- R calls Julia `normalize_pedigree()`, `pedigree_inverse()`,
  `animal_model_spec()`, and `henderson_mme()`;
- R normalizes fixed effects, EBVs/BLUPs, fitted values, supplied variance
  components, simple `h2`, `nobs`, diagnostics, and convergence status into
  `hsquared_fit`;
- R deliberately omits `logLik`, AIC, `df`, and optimizer output.

## Julia Action

Updated:

- `docs/design/03-engine-contract.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/src/roadmap.md`;
- `docs/src/changelog.md`;
- `README.md`;
- `ROADMAP.md`.

No Julia code changed.

## Public Claim Audit

Allowed wording:

- R has external experimental evidence for an opt-in supplied-variance
  Henderson MME bridge target.
- The target is validation-scale and requires supplied variance components.
- The path omits log-likelihood, AIC, `df`, and optimizer output.

Blocked wording:

- variance components are estimated;
- AI-REML exists;
- fitted Mrode output validation exists;
- production sparse fitting works;
- the base Julia `result_payload()` contract changed.

Rose verdict: clean with limitations.

## Checks To Run

- `julia --project=docs docs/make.jl`;
- `git diff --check`;
- additions-only ASCII scan;
- claim scan.

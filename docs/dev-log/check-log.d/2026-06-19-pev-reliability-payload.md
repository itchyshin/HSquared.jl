# 2026-06-19 PEV/reliability into the standard result payload (#43)

- Goal: deliver the engine half of the locked #61 / hsquared#21 decision — make
  `prediction_error_variance` and `reliability` standard fields of the univariate
  bridge payload `result_payload(::AnimalModelFit)`, computed through the
  production-direction Takahashi selected inverse (`:selinv`), so the R twin can
  make its PEV/reliability enrichment unconditional and close hsquared#21.
- Lenses: Hopper + Boole + Emmy (bridge/result-payload contract), Gauss + Noether
  (selinv numerics), Rose (claim gate). Adversarial review run as a workflow.

## What was done

- `result_payload(fit::AnimalModelFit)` (src/likelihood.jl): now computes
  `pev = prediction_error_variance(fit; method = :selinv)` and
  `rel = reliability(fit; method = :selinv)` and adds two standard fields,
  `prediction_error_variance = (ids, values)` and `reliability = (ids, values)`,
  placed after `predictions` and before `diagnostics`. Docstring updated.
- Shape matches the R unpack: the R twin (`../hsquared/R/julia-bridge.R`) reads
  top-level `raw$prediction_error_variance` / `raw$reliability`, each `(ids,
  values)`, via `hs_julia_id_values()` (hsquared#21). No try/catch — boundary
  behaviour is identical to calling the extractors directly (interior REML/Henderson
  fits are PD; the locked decision is "unconditional for those targets").
- Tests (`test/runtests.jl`, "Phase 1 dense fit extractors"): extended the strict
  `propertynames(payload)` tuple to include the two new fields, and pinned
  `payload.prediction_error_variance.values` ≈ both `:selinv` and `:dense`
  extractor values, and `payload.reliability.values` ≈ `:selinv` reliability.
- Rows: capability-status "R result payload shape" (the "deliberately keeps
  PEV/reliability out of base payload" wording replaced with the `:selinv` landing
  + machine-precision + hsquared#21 note); validation-debt `V1-RESULT` and
  `V1-SELINV-PEV` updated.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (baseline green before the change; green after, with the widened payload tuple +
  PEV/reliability value parity).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → (recorded in after-task).
- Adversarial review workflow (Hopper / Gauss+Noether / Rose) → (recorded in
  after-task).

## Claim boundary

A validation-scale bridge-shape change only. `:selinv` matches the dense MME
inverse diagonal to machine precision (`V1-SELINV-PEV`) but this is NOT a
production large-pedigree reliability claim, and there is no external fitted-model
comparator for PEV/reliability. No capability moved to covered.

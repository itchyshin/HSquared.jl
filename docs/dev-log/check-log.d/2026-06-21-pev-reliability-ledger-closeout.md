# 2026-06-21 PEV/Reliability Payload Ledger Closeout

- Goal: close the Julia-side #43 ledger drift after `result_payload(::AnimalModelFit)`
  already gained standard `prediction_error_variance` and `reliability` fields.
- Active lenses: Ada, Shannon, Hopper, Emmy, Fisher, Grace, Rose.
- Starting point: `main` at `008ea4d` after the genomic GBLUP/SNP-BLUP target
  fixture. No open Julia PRs were present when the slice started. R-lane #21
  mirror work was delegated separately; while this branch was in progress the R
  lane merged hsquared PR #73 at `adc2e63` and closed R issue #21 with the same
  no-promotion boundary. This branch touches only `HSquared.jl`.
- Evidence confirmed before editing:
  - `src/likelihood.jl` computes `pev = prediction_error_variance(fit;
    method = :selinv)` once inside `result_payload(fit)` and returns
    `prediction_error_variance = (ids, values)` plus
    `reliability = (ids, values)`.
  - `test/runtests.jl` pins the `propertynames(result_payload(fit))` tuple
    with both fields, verifies field values against `:selinv`, and verifies
    PEV against the dense MME inverse on the same validation fixtures.
  - The nonzero supplied-Γ H^Γ smoke also checks standard payload
    PEV/reliability shape and selected-inverse parity.
- Documentation/status updates:
  - Updated the engine contract, bridge compatibility matrix, roadmap,
    Documenter roadmap/quickstart pages, public claims register, capability
    status, v0.1 contract, and coordination board so current surfaces no
    longer say fitted `AnimalModelFit` payloads keep PEV/reliability outside the
    base payload.
  - Kept the claim boundary explicit: these are validation-scale standard
    payload fields, not production large-pedigree reliability, and supplied-
    variance `HendersonMMEResult` bridge paths may still use explicit
    extractor enrichment rather than `result_payload()`.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
  - `julia --project=docs docs/make.jl` — passed with existing local Documenter
    warnings for skipped deployment detection, missing logo/favicon, substituted
    Vitepress defaults, and npm audit output.
  - `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-pev-reliability-ledger-closeout.md` — passed.
  - `git diff --check` — passed.
- Rose verdict: clean with limitations. The #43 bridge shape is current on the
  Julia side; production sparse reliability, multivariate per-trait
  PEV/reliability, and external comparator validation remain separate gates.

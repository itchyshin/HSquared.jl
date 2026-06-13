# Coordination Board

## Active Lane Split

- Julia lane: this repository, `HSquared.jl`.
- R lane: sibling repository, `hsquared`.
- Coordinator lane: shared issue ledger, public-claim wording, and
  cross-repo contract checks.

## Current Rule

This Julia thread edits only `HSquared.jl`. The R/coordinator twin edits
`hsquared`.

## Shared Contract

- `hsquared` is the R public identity.
- `HSquared.jl` is the Julia engine.
- Phase 0 is operating system plus honest scaffold only.
- The R twin can parse the narrow v0.1 formula contract and stop at the Julia
  bridge boundary.
- The Julia twin can validate low-level animal-model specs and run an
  experimental dense variance-component optimizer for those specs.
- R-to-Julia bridge execution, sparse production fitting, EBVs, and
  heritability remain planned.
- Public claims require code, tests, docs, validation rows, and Rose audit.

## Current State

- Phase 0 public scaffold: complete.
- Public repos: `itchyshin/hsquared` and `itchyshin/HSquared.jl`.
- Initial GitHub issue ledger: issues #1-#7 in both repos.
- Phase 1 Julia lane:
  - pedigree normalization and direct sparse `Ainv` utility implemented;
  - low-level `AnimalModelSpec` validation implemented;
  - dense Gaussian likelihood evaluation implemented for supplied variance
    components;
  - experimental dense variance-component optimization implemented for
    validated specs;
  - experimental dense variance-component, fixed-effect, EBV/BLUP,
    fitted-value, and heritability extractors implemented for validated specs.
- R lane handoff from `itchyshin/hsquared` head `d85f356`:
  - inert `animal()` marker exported;
  - `hs_build_model_spec()` parses `animal(1 | id, pedigree = ped)`;
  - `hsquared()` validates the narrow contract and stops at
    `HSquared.fit_animal_model(y, X, Z, Ainv; method = :REML)`;
  - R-CMD-check, pkgdown, and Pages deploy were green; site is live at
    `https://itchyshin.github.io/hsquared/`.
- Next shared seam: explicit payload/result parity tests for `y`, `X`, `Z`,
  encoded IDs, pedigree metadata, Julia-side `Ainv`, method, family, fit-target
  dispatch, variance components, breeding values, and heritability.

## Sister References

- `DRM.jl`: Julia twin discipline, DocumenterVitepress structure, bridge
  contract, quality gates, and GPL-to-MIT provenance guardrails.
- `GLLVM.jl`: Julia engine role discipline, Documenter status pages, speed-claim
  evidence rules, and cross-project scout cadence.
- `drmTMB` / `gllvmTMB`: R-side documentation/status discipline and public
  fitted/planned/missing separation.

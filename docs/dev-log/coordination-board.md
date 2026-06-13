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
- The Julia twin has an in-memory `HSData` container mirroring the current R
  `hs_data()` ID-map vocabulary.
- The R twin has an internal JuliaCall smoke over the current Julia payload path
  and `result_payload()` at `hsquared` head `c837f2d`.
- Public R-to-Julia bridge execution, sparse production fitting, sparse
  production reliability/PEV, and sparse diagnostics remain planned.
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
    fitted-value, heritability, PEV, and reliability extractors implemented
    for validated specs;
  - experimental direct `fit_animal_model(y, X, Z, Ainv; ...)` target
    implemented for bridge-shaped payloads.
  - `HSData`, `HSDataIDMap`, and `id_map()` implemented as a conservative
    in-memory mirror of the R `hs_data()` input-container contract.
- R lane handoff from `itchyshin/hsquared` head `b57b48e`:
  - inert `animal()` marker exported;
  - `hs_build_model_spec()` parses `animal(1 | id, pedigree = ped)`;
  - internal `hs_bridge_payload` includes numeric `y`, dense `X`, sparse `Z`,
    `Ainv = NULL`, method, family, normalized `ids`, normalized pedigree with
    parent indices, and metadata;
  - `hsquared()` validates the narrow contract and stops at the Julia target;
  - R-CMD-check, pkgdown, and Pages deploy were green; site is live at
    `https://itchyshin.github.io/hsquared/`.
- R lane handoff from `itchyshin/hsquared` head `e543cd7`:
  - internal `hs_new_fit()` and exported extractors expect result fields
    `variance_components`, `heritability`, `breeding_values`,
    `fixed_effects`, `random_effects`, `loglik`, `df`, `nobs`,
    `predictions`, `diagnostics`, and `converged`;
  - R tests use mocked result fields only; live `hsquared()` fitted objects are
    not returned yet.
- R lane handoff from `itchyshin/hsquared` head `644c75e`:
  - `hs_data()` stores phenotypes, optional pedigree, genotypes, markers,
    expression, annotation, and environment inputs;
  - its `id_map` records phenotype, pedigree, genotype, and expression overlap;
  - this is not file-backed storage, relationship construction, QTL/eQTL scan
    support, or model fitting.
- R lane handoff from `itchyshin/hsquared` head `c837f2d`:
  - internal `hs_fit_julia_payload()` uses JuliaCall;
  - the smoke test activates the sibling local `HSquared.jl` checkout;
  - the path is `normalize_pedigree()` -> `pedigree_inverse()` ->
    `fit_animal_model(y, X, Z, Ainv; ids = ..., method = ...)` ->
    `result_payload()`;
  - R normalizes the result into the current internal `hsquared_fit` contract;
  - public `hsquared()` still stops before fitting.
- Next shared seam: sparse marshalling instead of dense `Z`, stable
  user-facing engine controls, Mrode validation, and `hs_data()` to `HSData`
  payload parity.

## Sister References

- `DRM.jl`: Julia twin discipline, DocumenterVitepress structure, bridge
  contract, quality gates, and GPL-to-MIT provenance guardrails.
- `GLLVM.jl`: Julia engine role discipline, Documenter status pages, speed-claim
  evidence rules, and cross-project scout cadence.
- `drmTMB` / `gllvmTMB`: R-side documentation/status discipline and public
  fitted/planned/missing separation.

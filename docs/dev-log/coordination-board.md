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
- The Julia twin has `sparse_csc_matrix()` for R `Matrix::dgCMatrix` slot
  marshalling.
- The R twin has an opt-in experimental tiny/local Julia path at `hsquared`
  head `9eabf0d`: `control = hs_control(engine = "julia")`.
- The R twin has PEV/reliability extractor contracts at `hsquared` head
  `78ba5ff`; Julia keeps those fields out of `result_payload()` until bridge
  tests widen in lockstep.
- The R twin consumes Julia `sparse_csc_matrix()` for sparse `Z` marshalling at
  `hsquared` head `398e019`.
- The R twin mirrors the shared tiny out-of-order calf/sire/dam Ainv validation
  fixture at `hsquared` head `fe7e346`.
- The R twin records an optional `nadiv::Mrode9` / `nadiv::makeAinv()` external
  Ainv comparator at `hsquared` head `369d14a`.
- Production R-to-Julia bridge execution, sparse production fitting, sparse
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
    components with a `max_dense_cells` guard;
  - experimental dense variance-component optimization implemented for
    validated specs;
  - experimental dense variance-component, fixed-effect, EBV/BLUP,
    fitted-value, heritability, PEV, and reliability extractors implemented
    for validated specs;
  - experimental direct `fit_animal_model(y, X, Z, Ainv; ...)` target
    implemented for bridge-shaped payloads.
  - sparse Henderson MME solving at supplied variance components implemented.
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
- R lane handoff from `itchyshin/hsquared` head `9eabf0d`:
  - opt-in path: `hsquared(..., control = hs_control(engine = "julia"))`;
  - default remains `hs_control(engine = "validate")`;
  - R-specific Julia controls live in `engine_control`: `julia_project`,
    `initial`, and `max_dense_cells`;
  - local/remote R checks were reported green.
- R lane handoff from `itchyshin/hsquared` head `78ba5ff`:
  - exported R `prediction_error_variance()` and `reliability()` generics and
    `hsquared_fit` methods exist;
  - R has future-compatible normalization if Julia later returns
    `prediction_error_variance` or `reliability`;
  - current R live-bridge tests still expect those fields to be absent from the
    Julia payload;
  - local/remote R checks were reported green.
- R lane handoff from `itchyshin/hsquared` head `398e019`:
  - R now sends `Matrix::dgCMatrix` `Z` slots through
    `HSquared.sparse_csc_matrix(...; index_base = :zero)`;
  - `hs_fit_julia_payload()` no longer takes or uses `max_dense_cells`;
  - local live bridge tests and remote R-CMD-check, pkgdown, and Pages were
    reported green;
  - this is sparse `Z` marshalling only, not large-data readiness, relationship
    object marshalling, production sparse fitting, performance evidence, or
    Mrode validation.
- R lane handoff from `itchyshin/hsquared` head `fe7e346`:
  - added internal `hs_tiny_animal_validation_fixture()`;
  - fixture uses out-of-order calf/sire/dam input and expected normalized IDs
    `sire`, `dam`, `calf`;
  - expected parent indices are sire `0, 0, 1` and dam `0, 0, 2`;
  - expected Ainv is `[1.5 0.5 -1.0; 0.5 1.5 -1.0; -1.0 -1.0 2.0]`;
  - R local full tests, R-CMD-check, pkgdown, and Pages were reported green;
  - this is a tiny Ainv fixture only, not fitted Mrode validation.
- R lane handoff from `itchyshin/hsquared` head `369d14a`:
  - added optional `nadiv` Suggests and
    `hs_mrode9_pedigree_validation_fixture()`;
  - fixture loads `nadiv::Mrode9`, documented by `nadiv` as adapted from Mrode
    example 9.1;
  - R computes `nadiv::makeAinv()`, aligns names, and compares the result with
    Julia `normalize_pedigree()` plus `pedigree_inverse()` at tolerance
    `1e-10`;
  - R local focused/full tests, R-CMD-check, pkgdown, and Pages were reported
    green;
  - boundary: pedigree inverse agreement only; no fitted Mrode animal-model
    validation, EBV/h2/variance-component validation, production sparse
    fitting, or large-pedigree readiness.
- Next shared seam: lockstep PEV/reliability payload widening, relationship
  marshalling beyond `Z`, Mrode validation, and `hs_data()` to `HSData` payload
  parity.

## Sister References

- `DRM.jl`: Julia twin discipline, DocumenterVitepress structure, bridge
  contract, quality gates, and GPL-to-MIT provenance guardrails.
- `GLLVM.jl`: Julia engine role discipline, Documenter status pages, speed-claim
  evidence rules, and cross-project scout cadence.
- `drmTMB` / `gllvmTMB`: R-side documentation/status discipline and public
  fitted/planned/missing separation.

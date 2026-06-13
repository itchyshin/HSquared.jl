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
- The R twin can now feed `hs_data()` into `model_spec()` and `hsquared()` for
  the v0.1 parser at `hsquared` head `36efbf3`; the bridge payload shape is
  unchanged and live Julia `HSData` object marshalling remains planned.
- The Julia twin has `sparse_csc_matrix()` for R `Matrix::dgCMatrix` slot
  marshalling.
- The R twin has an opt-in experimental tiny/local Julia path at `hsquared`
  head `9eabf0d`: `control = hs_control(engine = "julia")`.
- The R twin has PEV/reliability extractor contracts at `hsquared` head
  `78ba5ff`; at head `8235289` it enriches opt-in tiny/local Julia bridge
  results from exported Julia extractors when available. Julia keeps those
  fields out of the compact base `result_payload()`.
- The R twin consumes Julia `sparse_csc_matrix()` for sparse `Z` marshalling at
  `hsquared` head `398e019`.
- The R twin mirrors the shared tiny out-of-order calf/sire/dam Ainv validation
  fixture at `hsquared` head `fe7e346`.
- The R twin records an optional `nadiv::Mrode9` / `nadiv::makeAinv()` external
  Ainv comparator at `hsquared` head `369d14a`.
- The R twin expanded planned backend controls at `hsquared` head `5feac1f`;
  Julia mirrors the same backend and accelerator vocabulary as metadata only.
- The R twin added `backend_info()` diagnostics at `hsquared` head `8266a82`;
  Julia mirrors the same planned/unavailable status surface with typed rows.
- The R twin reserved planned genomic/QTL formula markers at `hsquared` head
  `3c82c9a`; Julia mirrors those names as planned vocabulary only.
- The R twin reserved planned standard quantitative-genetic formula markers at
  `hsquared` head `10e8fd7`; Julia mirrors those names as planned vocabulary
  only.
- The R twin added `formula_status()` at `hsquared` head `7ba2df4`; Julia
  mirrors the grammar-status diagnostic with `formula_status()` and a
  Documenter status table.
- The Julia twin now exposes `validation_status()` as a diagnostic validation
  ladder for covered, external, partial, and planned evidence. It does not run
  comparators or promote fitted Mrode support.
- The R twin expanded the genomics/QTL/GLLVM/GPU/HPC plan at `hsquared` head
  `2c18b30`; Julia mirrors the plan with Documenter and design notes as
  roadmap only.
- The R twin added exported `model_spec()` at `hsquared` head `bacef9c`; this
  previews the v0.1 formula-to-bridge payload without fitting or Julia
  execution.
- Production R-to-Julia bridge execution, sparse production fitting, sparse
  production reliability/PEV, sparse diagnostics, GPU execution, backend
  benchmarking, CPU/GPU agreement tests, genomic prediction, single-step
  fitting, marker scans, QTL/eQTL scans, GLLVM animal models, APY, Takahashi
  selected inversion, production AI-REML, standard quantitative-genetic
  extension fitting, and custom relationship/precision kernel fitting remain
  planned.
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
  - `validation_status()` implemented as a diagnostic validation-evidence
    table.
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
- R lane handoff from `itchyshin/hsquared` head `36efbf3`:
  - `model_spec()` and `hsquared()` can accept an `hs_data()` object as
    `data`;
  - model variables are read from `data$phenotypes`;
  - formula components such as `pedigree = pedigree` are resolved from the
    `hs_data()` bundle;
  - the bridge payload shape is unchanged: `y`, `X`, sparse `Z`, normalized
    pedigree/ID metadata, method, family, and Julia target metadata;
  - reported remote evidence: R-CMD-check `27460091544`, pkgdown
    `27460091551`, and Pages `27460131691` success;
  - boundary: phenotype/pedigree parser integration only. No file-backed
    storage, genotype/omics automatic model construction, production bridge
    hardening, or general fitting.
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
- R lane handoff from `itchyshin/hsquared` head `8235289`:
  - the opt-in local Julia bridge enriches tiny validation-path results with
    PEV/reliability if sibling Julia exports `prediction_error_variance(fit)`
    and `reliability(fit)`;
  - R still starts from `result_payload(fit)` and merges those two fields if
    available, preserving the compact base Julia payload contract;
  - reported remote evidence: R-CMD-check `27459709156`, pkgdown
    `27459709148`, and Pages `27459742852` success;
  - boundary: bridge-available for tiny local validation path only. No
    production sparse PEV/reliability, general animal-model fitting, Mrode
    fitted-output validation, or base `result_payload()` widening claim.
- R lane handoff from `itchyshin/hsquared` head `bacef9c`:
  - added exported `model_spec()`;
  - validates the same v0.1 grammar as `hsquared()` and builds the same
    internal bridge payload;
  - previews response/family/method, fixed-effect columns, sparse `Z`
    dimensions, normalized animal IDs, observed ID mapping, pedigree founder
    count, and Julia targets;
  - reported remote evidence: R-CMD-check `27459924245`, pkgdown
    `27459924261`, and Pages `27459952909` success;
  - boundary: preview only. No model fitting, Julia execution, expanded
    grammar, or production bridge claim.
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
- R lane handoff from `itchyshin/hsquared` head `5feac1f`:
  - expanded `hs_control()` metadata vocabulary;
  - backend names: `auto`, `cpu`, `threads`, `cuda`, `amdgpu`, `metal`,
    `oneapi`;
  - accelerator names: `auto`, `none`, `gpu`, `cuda`, `amdgpu`, `metal`,
    `oneapi`;
  - R-CMD-check `27457948686`, pkgdown `27457948693`, and Pages
    `27457985141` were green;
  - boundary: control metadata only; no GPU execution, backend benchmarking, or
    CPU/GPU numerical agreement claim.
- R lane handoff from `itchyshin/hsquared` head `8266a82`:
  - added public `backend_info(control = hs_control())`;
  - rows: `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, `oneapi`;
  - columns: `backend`, `accelerator`, `requested`, `selectable`,
    `execution_available`, `status`, and `note`;
  - all rows are selectable, execution unavailable, and planned;
  - R-CMD-check `27458148965`, pkgdown `27458148970`, and Pages
    `27458179717` were reported green for the implementation commit;
  - R-CMD-check `27458206919`, pkgdown `27458206905`, and Pages
    `27458237087` were green for the evidence commit;
  - boundary: status diagnostic only; no runtime backend probing, GPU
    execution, backend benchmarking, or CPU/GPU agreement claim.
- R lane handoff from `itchyshin/hsquared` head `3c82c9a`:
  - added inert planned-only formula markers `genomic()`, `single_step()`,
    `markers()`, `marker_scan()`, and `qtl_scan()`;
  - parser rejects those terms before model-frame construction with
    planned-not-implemented wording;
  - local R formula tests, full tests, and `devtools::check()` were reported
    green;
  - R-CMD-check `27458338370`, pkgdown `27458338374`, and Pages
    `27458374477` were reported green for implementation commit `dc53584`;
  - boundary: syntax reservation only; no genomic prediction, marker scan,
    single-step, QTL/eQTL, or marker-effect estimation claim.
- R lane handoff from `itchyshin/hsquared` head `10e8fd7`:
  - added inert planned-only formula markers `permanent()`, `common_env()`,
    `maternal_genetic()`, `maternal_env()`, `paternal_genetic()`,
    `paternal_env()`, `cytoplasmic()`, `imprinting()`, `dominance()`,
    `epistasis()`, `relmat()`, and `precision()`;
  - parser rejects those terms before model-frame construction with
    planned-not-implemented wording;
  - R-CMD-check `27458718993`, pkgdown `27458718981`, and Pages
    `27458751023` were reported green for latest R head;
  - R issue note:
    `https://github.com/itchyshin/hsquared/issues/4#issuecomment-4697708772`;
  - boundary: syntax reservation only; no Phase 2+ fitting, parental effect,
    inheritance-kernel, dominance/epistasis, or custom precision fitting claim.
- R lane docs-sync handoff from `itchyshin/hsquared` head `794722f`:
  - added pkgdown article `vignettes/articles/formula-grammar.Rmd`;
  - article separates parsed-today syntax, reserved Phase 2+ QG/inheritance
    markers, reserved genomic/marker terms, planned multivariate/FA syntax,
    and the early planned-not-implemented error rule;
  - R-CMD-check `27458881927`, pkgdown `27458881926`, and Pages
    `27458916142` were reported green;
  - R issue note:
    `https://github.com/itchyshin/hsquared/issues/4#issuecomment-4697726092`;
  - Julia mirrors this with Documenter page `model-spec-grammar.md`.
- R lane handoff from `itchyshin/hsquared` head `7ba2df4`:
  - added `formula_status()` grammar diagnostics;
  - table has 20 rows and columns `term`, `category`, `phase`,
    `syntax_status`, `fitting_status`, and `current_behavior`;
  - separates parsed v0.1 animal syntax, reserved inert Phase 2+ and genomic
    markers, and planned multivariate/factor-analytic syntax;
  - R-CMD-check `27459105695`, pkgdown `27459105696`, and Pages
    `27459143480` were reported green;
  - R issue note:
    `https://github.com/itchyshin/hsquared/issues/4#issuecomment-4697748409`;
  - Julia mirrors this as diagnostic only; no parser or fitting expansion.
- R lane handoff from `itchyshin/hsquared` head `2c18b30`:
  - expanded `docs/design/07-genomics-qtl-gpu-plan.md` with the full
    genomics, QTL/eQTL, GLLVM, GPU, backend, benchmark, HPC, validation, and
    first-implementation plan;
  - added pkgdown-facing summary `vignettes/articles/genomics-gpu-roadmap.Rmd`;
  - recorded concrete local leads from `DRM.jl/src/takahashi_selinv.jl`,
    `GLLVM.jl/src/fit.jl`, `GLLVM.jl/src/structured_schur.jl`, and
    `gllvmTMB/CLAUDE.md`;
  - reported remote evidence: R-CMD-check `27459454821`, pkgdown
    `27459454815`, and Pages `27459486904` success for the evidence commit;
  - boundary: roadmap/design only. No genomic fitting, QTL/eQTL scan,
    GLLVM animal model, GPU execution, APY, Takahashi selected inverse,
    AI-REML, HPC, or performance claim.
- Next shared seam: deciding whether PEV/reliability should ever become
  required base payload fields, relationship marshalling beyond `Z`, Mrode
  validation, live Julia `HSData` object marshalling parity, the first real
  genomic/QTL model-spec contract, and the first real standard
  quantitative-genetic model-spec contract.

## Sister References

- `DRM.jl`: Julia twin discipline, DocumenterVitepress structure, bridge
  contract, quality gates, and GPL-to-MIT provenance guardrails.
- `GLLVM.jl`: Julia engine role discipline, Documenter status pages, speed-claim
  evidence rules, and cross-project scout cadence.
- `drmTMB` / `gllvmTMB`: R-side documentation/status discipline and public
  fitted/planned/missing separation.

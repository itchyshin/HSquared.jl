# Check Log

Newest entries go at the top.

## 2026-06-13 Planned Quantitative-Genetic Marker Vocabulary Mirror

- Goal: mirror the R twin's inert planned standard quantitative-genetic,
  parental, inheritance-kernel, and custom-kernel formula markers as Julia
  vocabulary reservations.
- Active lenses: Ada, Shannon, Boole, Hopper, Noether, Mendel, Henderson, Rose,
  Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `14e5781` added planned-only `permanent()`,
    `common_env()`, `maternal_genetic()`, `maternal_env()`,
    `paternal_genetic()`, `paternal_env()`, `cytoplasmic()`, `imprinting()`,
    `dominance()`, `epistasis()`, `relmat()`, and `precision()` markers.
  - `hsquared` head `10e8fd7` records QG marker CI evidence.
  - R parser detects these terms before model-frame construction and errors
    with planned-not-implemented wording.
  - Reported remote evidence: R-CMD-check `27458718993`, pkgdown
    `27458718981`, and Pages `27458751023` success.
- R docs-sync handoff:
  - `hsquared` head `92c1d12` added pkgdown article
    `vignettes/articles/formula-grammar.Rmd`.
  - `hsquared` head `794722f` records formula-grammar article CI evidence.
  - Reported remote evidence: R-CMD-check `27458881927`, pkgdown
    `27458881926`, and Pages `27458916142` success.
- Julia-side action:
  - Extended `planned_model_terms()` and added `planned_quantgen_terms()`.
  - Added exported `permanent()`, `common_env()`, `maternal_genetic()`,
    `maternal_env()`, `paternal_genetic()`, `paternal_env()`,
    `cytoplasmic()`, `imprinting()`, `dominance()`, `epistasis()`,
    and `relmat()` functions that throw planned-not-implemented errors.
  - Added qualified `HSquared.precision()` for the planned precision-kernel
    marker because `Base.precision` already exists.
  - Updated formula grammar, engine contract, README, docs pages, status
    tables, validation debt, public claims, and coordination board.
  - Added Documenter page `docs/src/model-spec-grammar.md` to mirror the R
    formula-grammar status separation.
- Local checks:
  - First `julia --project=. -e 'using Pkg; Pkg.test()'` failed because
    exporting `precision()` conflicted with `Base.precision`. Fixed by keeping
    the marker available as `HSquared.precision()` and reserving `:precision`
    in the vocabulary table without exporting the unqualified function.
  - Final `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 282
    checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    Phase 2+ QG fitting, custom relationship/precision kernels, genomic
    prediction, marker scans, QTL/eQTL scans, GPU execution, ASReml
    superiority, backend benchmarking, or CPU/GPU numerical agreement.
- Boundary:
  - Syntax/model-term vocabulary reservation only.
  - No permanent/common environment fitting.
  - No maternal or paternal effect fitting.
  - No cytoplasmic, imprinting, dominance, or epistasis fitting.
  - No custom relationship or precision-kernel fitting.

## 2026-06-13 Planned Genomic/QTL Marker Vocabulary Mirror

- Goal: mirror the R twin's inert planned genomic/QTL formula markers as Julia
  vocabulary reservations.
- Active lenses: Ada, Shannon, Boole, Hopper, Noether, Jason, Rose, Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `dc53584` added planned-only `genomic()`,
    `single_step()`, `markers()`, `marker_scan()`, and `qtl_scan()` markers.
  - `hsquared` head `3c82c9a` records genomic marker CI evidence.
  - R parser detects these terms before model-frame construction and errors
    with planned-not-implemented wording.
  - Reported implementation evidence: local formula tests 17 pass, local full
    tests 158 pass, `devtools::check()` 0/0/0, R-CMD-check `27458338370`,
    pkgdown `27458338374`, and Pages `27458374477` success.
- Julia-side action:
  - Added `planned_model_terms()`.
  - Added exported `genomic()`, `single_step()`, `markers()`, `marker_scan()`,
    and `qtl_scan()` functions that throw planned-not-implemented errors.
  - Updated formula grammar, engine contract, README, docs pages, status
    tables, validation debt, public claims, and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 227 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    genomic prediction, single-step fitting, marker-effect estimation, marker
    scans, QTL/eQTL scans, GPU execution, ASReml superiority, backend
    benchmarking, or CPU/GPU numerical agreement.
- Remote checks for commit `bc0fe77`:
  - CI `27458684148`: success.
  - Documenter `27458684126`: success.
  - Pages deploy `27458715550`: success.
  - Live docs `https://itchyshin.github.io/HSquared.jl/`: HTTP 200.
- Boundary:
  - Syntax/model-term vocabulary reservation only.
  - No genomic prediction.
  - No marker-effect estimation.
  - No marker scans, QTL scans, or eQTL scans.
  - No single-step fitting.

## 2026-06-13 Backend Status Diagnostics Mirror

- Goal: mirror the R twin's `backend_info()` honest status diagnostic in Julia.
- Active lenses: Ada, Shannon, Hopper, Karpinski, Grace, Rose, Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `498d41f` added public `backend_info()`.
  - `hsquared` head `8266a82` records backend diagnostics CI evidence.
  - rows: `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, `oneapi`;
  - columns: `backend`, `accelerator`, `requested`, `selectable`,
    `execution_available`, `status`, and `note`;
  - all rows are selectable, execution unavailable, and planned.
  - Reported implementation evidence: local R tests 151 pass,
    `devtools::check()` 0/0/0, R-CMD-check `27458148965`, pkgdown
    `27458148970`, and Pages `27458179717` success.
  - R evidence commit checks: R-CMD-check `27458206919`, pkgdown
    `27458206905`, and Pages `27458237087` success.
- Julia-side action:
  - Added `BackendInfoRow` and `BackendInfo`.
  - Added `backend_info(control = HSControl())`.
  - Added tests for row order, requested flags, selectable flags,
    `execution_available == false`, and `status == :planned`.
  - Updated README, API docs, engine contract, status tables, public claims,
    and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 211 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    runtime backend probing, GPU execution, backend benchmarking, CPU/GPU
    numerical agreement, QTL/eQTL support, or ASReml superiority.
- Remote checks for commit `80bd8be`:
  - CI `27458402884`: success.
  - Documenter `27458402883`: success.
  - Pages deploy `27458435663`: success.
  - Live docs `https://itchyshin.github.io/HSquared.jl/`: HTTP 200.
- Boundary:
  - Status diagnostic only.
  - No runtime backend probing.
  - No GPU execution.
  - No backend benchmarking.
  - No CPU/GPU numerical agreement claim.

## 2026-06-13 Planned Backend Vocabulary Mirror

- Goal: mirror the R twin's planned backend and accelerator vocabulary in
  Julia controls and docs.
- Active lenses: Ada, Shannon, Hopper, Karpinski, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `5feac1f` expanded `hs_control()` metadata vocabulary.
  - backend names: `auto`, `cpu`, `threads`, `cuda`, `amdgpu`, `metal`,
    `oneapi`;
  - accelerator names: `auto`, `none`, `gpu`, `cuda`, `amdgpu`, `metal`,
    `oneapi`;
  - R-CMD-check `27457948686`, pkgdown `27457948693`, and Pages
    `27457985141` were green.
- Julia-side action:
  - Added marker types: `ThreadsBackend`, `AMDGPUBackend`, `MetalBackend`, and
    `OneAPIBackend`.
  - Expanded `HSControl()` validation for the shared backend and accelerator
    vocabulary.
  - Updated API docs, roadmap, capability status, validation debt, public
    claims, and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 197 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
- Remote checks:
  - CI `27458145243`: success.
  - Documenter `27458145252`: success.
  - Pages `27458175711`: success.
  - Live docs returned HTTP 200.
- Boundary:
  - Control metadata only.
  - CPU remains the trusted always-available path.
  - CUDA, AMDGPU, Metal, and oneAPI are future optional-extension markers.
  - No GPU execution, backend availability diagnostics, backend benchmarking,
    or CPU/GPU numerical agreement claim.

## 2026-06-13 Phase 1N Sparse REML Identity And Mrode9 Ainv Sync

- Goal: add a sparse supplied-variance REML likelihood identity and mirror the
  R twin's optional Mrode9/nadiv pedigree-Ainv comparator evidence.
- Active lenses: Ada, Shannon, Henderson, Gauss, Fisher, Curie, Mrode, Grace,
  Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added `sparse_reml_loglik(spec, sigma_a2, sigma_e2)`.
  - The evaluator uses the sparse Henderson MME determinant identity at
    supplied positive variance components.
  - Shared the sparse MME system builder with `henderson_mme()`.
  - Kept `fit_animal_model()` and `result_payload()` unchanged.
- Test evidence:
  - Added dense-vs-sparse REML equivalence tests on the simple identity
    relationship fixture.
  - Added dense-vs-sparse REML equivalence tests on the existing Henderson MME
    validation fixture.
  - Added error tests for non-positive variances and saturated REML design.
- R twin handoff:
  - Verified read-only from the sibling R repo.
  - `hsquared` head `f0e71c7` added optional `nadiv`, the
    `hs_mrode9_pedigree_validation_fixture()`, and
    `tests/testthat/test-mrode-validation.R`.
  - `hsquared` head `369d14a` recorded green CI evidence.
  - The R test computes `nadiv::makeAinv()` for `nadiv::Mrode9` and compares
    it with Julia `normalize_pedigree()` plus `pedigree_inverse()` at
    tolerance `1e-10`.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 192 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
- Boundary:
  - `sparse_reml_loglik()` evaluates REML at supplied variance components
    only. It is not variance-component estimation, AI-REML, or production
    sparse fitting.
  - The Mrode9/nadiv evidence covers pedigree inverse agreement only. It is not
    fitted Mrode animal-model validation, EBV/h2/variance-component validation,
    ASReml/BLUPF90/DMU/WOMBAT comparison, or large-pedigree readiness.

## 2026-06-13 R Tiny Ainv Fixture Mirror

- Goal: mirror the R twin's first deterministic Ainv validation atom in the
  Julia design/status ledger.
- Active lenses: Ada, Henderson, Curie, Mrode, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `c161a7f` added `hs_tiny_animal_validation_fixture()`.
  - `hsquared` head `fe7e346` recorded green CI evidence.
  - Fixture: out-of-order calf/sire/dam input; normalized IDs `sire`, `dam`,
    `calf`; sire indices `0, 0, 1`; dam indices `0, 0, 2`; expected Ainv
    `[1.5 0.5 -1.0; 0.5 1.5 -1.0; -1.0 -1.0 2.0]`.
  - R-CMD-check `27457553099`, pkgdown `27457553093`, and Pages
    `27457582221` were reported green.
- Julia-side action:
  - Recorded the shared fixture in the engine contract, capability status,
    validation debt, and coordination board.
  - No code changed.
- Boundary:
  - Tiny Ainv fixture only.
  - Not Mrode validation, external comparator validation, production sparse
    fitting, large-pedigree readiness, or genomic/single-step validation.

## 2026-06-13 Phase 1M Sparse Henderson MME Supplied-Variance Solve

- Goal: add a sparse Henderson mixed-model-equation solve at supplied variance
  components and record the R twin's sparse `Z` marshalling handoff.
- Active lenses: Ada, Henderson, Gauss, Karpinski, Fisher, Mrode, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `2a9ba37` uses sparse `Z` bridge marshalling.
  - `hsquared` head `398e019` records green CI evidence.
  - R now calls `HSquared.sparse_csc_matrix(...; index_base = :zero)` for
    `Matrix::dgCMatrix` `Z` slots.
  - `hs_fit_julia_payload()` no longer takes or uses `max_dense_cells`.
  - R-CMD-check `27457295759`, pkgdown `27457295761`, and Pages `27457326836`
    were reported green.
- Implementation evidence:
  - Added `HendersonMMEResult`.
  - Added `henderson_mme(spec, sigma_a2, sigma_e2)`.
  - The solver forms Henderson's equations from sparse `X`, `Z`, and `Ainv`
    and solves for fixed effects plus animal effects at supplied variance
    components.
  - Added `fixed_effects()`, `breeding_values()`, and `fitted_values()` methods
    for `HendersonMMEResult`.
  - Kept `result_payload()` fields unchanged.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 180 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only blocked/planned/historical-audit wording, not public
    claims that sparse production fitting works, Mrode validation is complete,
    AI-REML is implemented, or PEV/reliability are returned through the bridge
    payload.
- Boundary:
  - Supplied variance components only.
  - Not variance-component estimation, AI-REML, production sparse fitting,
    Mrode validation, external comparator validation, or a bridge payload
    change.

## 2026-06-13 Phase 1L Dense Validation Size Guard And R PEV Sync

- Goal: add a Julia-side dense validation size guard aligned with the R
  `engine_control$max_dense_cells` vocabulary, and record the R twin's
  PEV/reliability extractor-contract handoff without changing Julia bridge
  payload fields.
- Active lenses: Ada, Shannon, Hopper, Karpinski, Gauss, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `78ba5ff` added exported
    `prediction_error_variance()` and `reliability()` generics and fitted-object
    methods.
  - R has future-compatible normalization if Julia later returns
    `prediction_error_variance` or `reliability`.
  - Current R live-bridge tests expect those fields to be absent from Julia
    `result_payload()`.
- Implementation evidence:
  - Added `max_dense_cells` to `gaussian_loglik()`.
  - Threaded `max_dense_cells` through `fit_variance_components()`,
    `fit_animal_model(spec)`, and direct
    `fit_animal_model(y, X, Z, Ainv; ...)` dispatch.
  - Guard fails before the current dense validation path converts covariance or
    relationship matrices.
  - Kept `result_payload()` fields unchanged.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 169 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only blocked/planned wording in old after-task reports and
    the claims register, not public claims that PEV/reliability are returned
    through the bridge, sparse production fitting works, Mrode validation is
    complete, or GPU/QTL support exists.
- Boundary:
  - `max_dense_cells` is a guard for the temporary dense path, not a sparse
    production solver.
  - R PEV/reliability bridge fields remain a planned lockstep task.
  - Sparse production fitting, Mrode validation, and production reliability/PEV
    remain planned.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1K Sparse CSC Bridge Marshalling

- Goal: add a Julia sparse CSC marshalling helper for R `Matrix::dgCMatrix`
  slots and record the R twin's opt-in Julia engine path.
- Active lenses: Ada, Shannon, Hopper, Karpinski, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `9eabf0d` added
    `hsquared(..., control = hs_control(engine = "julia"))`.
  - Default remains `hs_control(engine = "validate")`.
  - R-specific Julia controls stay in `engine_control`: `julia_project`,
    `initial`, and `max_dense_cells`.
  - R-CMD-check `27456875004`, pkgdown `27456874995`, and Pages `27456904688`
    were reported green.
- Implementation evidence:
  - Added `sparse_csc_matrix()`.
  - Supports zero-based R slots and one-based Julia slots.
  - Validates dimensions, column pointers, row indices, value lengths, and row
    ordering within CSC columns.
  - Added direct payload integration test showing a `Z` reconstructed from
    zero-based slots feeds the same `fit_animal_model()` path as the original
    sparse matrix.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 163 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims that R
    already uses sparse `Z` marshalling, production sparse fitting works, Mrode
    validation is complete, or bridge performance has been demonstrated.
- Boundary:
  - Julia helper exists.
  - Superseded by Phase 1M: R head `398e019` now consumes sparse `Z` slots
    through this helper; relationship-object marshalling beyond `Z` remains
    planned.
  - Production fitting, Mrode validation, and stable production controls remain
    planned.

## 2026-06-13 R Internal Julia Bridge Smoke Sync

- Goal: record the R twin's internal JuliaCall smoke evidence without changing
  Julia result payload fields or claiming public fitting support.
- Active lenses: Ada, Shannon, Hopper, Lovelace, Emmy, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `c837f2d` added internal `hs_fit_julia_payload()`.
  - The smoke activates the sibling local `HSquared.jl` checkout and calls
    `normalize_pedigree()` -> `pedigree_inverse()` ->
    `fit_animal_model(y, X, Z, Ainv; ids = ..., method = ...)` ->
    `result_payload()`.
  - R normalizes the returned result into the current internal `hsquared_fit`
    contract.
  - Public `hsquared()` still stops before fitting.
- R remote evidence reported:
  - R-CMD-check `27456664820`: success.
  - pkgdown `27456664821`: success.
  - Pages `27456696277`: success.
- Julia-side action:
  - Updated engine, formula, v0.1, roadmap, capability, validation, public
    claims, and coordination docs.
  - Kept `result_payload()` field names stable.
  - Did not add dense PEV/reliability to `result_payload()` because the R result
    contract has not grown those fields.
- Commands run:
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only planned/blocked wording, not public claims that
    `hsquared()` fits through Julia, full sparse bridge marshalling is complete,
    stable user-facing engine controls exist, or Mrode validation is complete.
- Boundary:
  - Internal bridge smoke exists externally in the R twin.
  - Public R fitting remains planned.
  - Sparse `Z` marshalling, stable engine controls, and Mrode validation remain
    next shared gates.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1J Dense PEV And Reliability

- Goal: add dense experimental prediction-error-variance and reliability
  extractors for the low-level Gaussian animal-model validation path.
- Active lenses: Ada, Henderson, Gauss, Fisher, Curie, Mrode, Grace, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added `prediction_error_variance(fit)`.
  - Added `reliability(fit)`.
  - PEV uses the lower-right random-effect block of the dense
    mixed-model-equation inverse.
  - Reliability uses `1 - PEV_i / (sigma_a2 * A_ii)` and does not clip values.
- Tests:
  - Added identity-relationship checks against a test-side MME inverse.
  - Extended the Henderson MME fixture to check PEV and reliability against the
    same equation system used for fixed effects and EBVs.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 148 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only allowed dense-experimental wording and blocked/audit
    rows, not public claims that production sparse reliability/PEV, sparse
    production fitting, AI-REML, R-to-Julia bridge execution, or GPU support are
    implemented.
- Boundary:
  - Dense validation path only.
  - Not production sparse reliability/PEV.
  - Not external comparator validation.
  - Not included in `result_payload()` until the R result contract grows those
    fields.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1I HSData Input Container

- Goal: mirror the R `hs_data()` input-container contract in Julia without
  widening claims to file-backed storage, genomic modelling, QTL/eQTL, or model
  fitting.
- Active lenses: Ada, Shannon, Hopper, Emmy, Jason, Karpinski, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `644c75e` added `hs_data()` for phenotypes, optional
    pedigree, genotypes, markers, expression, annotation, and environment.
  - R local/remote evidence was reported green in the coordination handoff.
- Implementation evidence:
  - Added `HSData`, `HSDataIDMap`, and `id_map()`.
  - Added exact ID-map fields aligned to the R vocabulary.
  - Added tests for repeated phenotype IDs, normalized and raw pedigree IDs,
    matrix genotypes with explicit IDs, expression IDs, mismatch fields, and
    invalid input errors.
  - Added Documenter page `docs/src/data.md` and design note
    `docs/design/09-hsdata-contract.md`.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 140 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims that
    file-backed storage, QTL/eQTL, genomic relationship construction, live
    R-to-Julia marshalling, sparse production fitting, AI-REML, or GPU support
    are implemented.
- Boundary:
  - `HSData` is an in-memory exact-ID container.
  - It does not normalize IDs across types.
  - It does not read large file formats, construct genomic relationships, run
    scans, or fit models.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1H Result Payload Contract

- Goal: align Julia dense fit result names with the R `hsquared_fit` extractor
  contract before live bridge execution is wired.
- Active lenses: Ada, Shannon, Hopper, Emmy, Fisher, Karpinski, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `e543cd7` added `hs_new_fit()` and extractors over mocked
    result fields.
  - Expected result names are `variance_components`, `heritability`,
    `breeding_values`, `fixed_effects`, `random_effects`, `loglik`, `df`,
    `nobs`, `predictions`, `diagnostics`, and `converged`.
- Implementation evidence:
  - Added `result_payload(fit)`.
  - Added exact field-name tests and value tests for the R contract names.
  - Kept internal `AnimalModelFit` stable; bridge result shaping is explicit.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 121 checks
    across Phase 0, pedigree/Ainv, spec validation, likelihood, dense
    optimizer, dense extractor/result payload, direct payload target, and
    Henderson MME validation testsets.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims that R
    live execution returns fitted objects, R extractors consume real Julia
    results, production sparse reliability/PEV, sparse diagnostics, or GPU/QTL
    support are implemented.
- Boundary:
  - Result shape exists on the Julia side.
  - R live execution and result marshalling remain planned.
  - Reliability, PEV, and sparse solver diagnostics remain planned.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1G Henderson MME Validation Fixture

- Goal: add a first MME validation fixture for the dense Phase 1 output path.
- Active lenses: Ada, Henderson, Mrode, Gauss, Fisher, Curie, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added a test-only Henderson mixed-model-equation solver.
  - Added a five-animal pedigree fixture with founders, offspring, repeated
    records, fixed effects, sparse `Z`, and supplied variance components.
  - Cross-checked dense marginal-output fixed effects, breeding values, fitted
    values, and heritability against the MME solution.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 105 checks
    across Phase 0, pedigree/Ainv, spec validation, likelihood, dense
    optimizer, dense extractor, direct payload target, and Henderson MME
    validation testsets.
- Boundary:
  - MME fixture is a deterministic validation check, not a full textbook Mrode
    reproduction.
  - No external comparator package has been run yet.
  - Sparse production solves remain planned.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1F Direct Bridge Payload Target

- Goal: implement the Julia method that the R parser currently names as its
  bridge target: `fit_animal_model(y, X, Z, Ainv; method = :REML)`.
- Active lenses: Ada, Shannon, Hopper, Boole, Henderson, Gauss, Karpinski,
  Grace, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added direct payload `fit_animal_model(y, X, Z, Ainv; ids, family, method,
    kwargs...)`.
  - The method validates through `animal_model_spec()` and dispatches to the
    dense `fit_variance_components()` path.
  - Added parity tests showing direct payload fitting matches validated-spec
    fitting for likelihood, variance components, method, IDs, and breeding
    value IDs.
  - Mirrored R payload semantics from `hsquared` head `b57b48e`: normalized
    parent-before-offspring IDs, parent index vectors, sparse `Z` dimensions,
    and Julia-side `Ainv` construction.
  - Added error tests for payload dimension and ID mismatches.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 100 checks across
    Phase 0, pedigree/Ainv, spec validation, likelihood, dense optimizer, dense
    extractor, and direct payload target testsets.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims that the
    R bridge executes, R formula calls fit through Julia, sparse production
    fitting works, AI-REML works, or results are comparator-validated.
- Boundary:
  - Julia target exists; R-to-Julia marshalling still does not.
  - Dense validation path only.
  - Not sparse production fitting or AI-REML.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1E Dense Fit Extractors

- Goal: add first low-level result extractors for the dense Gaussian
  validation path.
- Active lenses: Ada, Henderson, Gauss, Fisher, Falconer, Hopper, Karpinski,
  Grace, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added `BreedingValues`.
  - Added `variance_components()`, `fixed_effects()`, `breeding_values()`,
    `fitted_values()`, and `heritability()`.
  - Added hand-checked dense tests with identity `A`, `V = 2I`, beta = 2,
    EBVs `[-0.5, 0, 0.5]`, fitted values `[1.5, 2, 2.5]`, and `h2 = 0.5`.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 85 checks across
    Phase 0, pedigree/Ainv, spec validation, likelihood, dense optimizer, and
    dense extractor testsets.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    implemented production sparse EBVs, reliability, prediction error variance,
    AI-REML, R bridge execution, GPU, or QTL/eQTL support.
- Boundary:
  - Dense validation path only.
  - Not sparse production BLUP solving.
  - No reliability or prediction error variance yet.
  - No R bridge execution yet.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1D Dense Variance-Component Optimizer

- Goal: add a conservative dense optimizer for the Gaussian likelihood over
  positive additive and residual variance components.
- Active lenses: Ada, Shannon, Hopper, Henderson, Gauss, Fisher, Karpinski,
  Grace, Rose.
- Spawned subagents: none.
- R twin handoff recorded:
  - `hsquared` head `d85f356` parses the narrow `animal(1 | id, pedigree = ped)`
    grammar and stops at the Julia bridge boundary.
  - R local and remote checks were reported green, and the R pkgdown site is
    live at `https://itchyshin.github.io/hsquared/`.
  - Julia mirrored this as a payload-parity next seam; bridge execution remains
    planned.
- Implementation evidence:
  - Added `AnimalModelFit`.
  - Added `fit_variance_components()`.
  - Added `fit_animal_model(spec::AnimalModelSpec)` dispatch.
  - Added tests that the optimizer improves the tiny likelihood from a starting
    point, returns positive variance components, and validates bad initial
    values.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 76 checks across
    Phase 0, pedigree/Ainv, spec validation, likelihood, and dense optimizer
    testsets.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    implemented sparse fitting, AI-REML, EBVs, heritability, GPU, or
    QTL/eQTL support.
- Boundary:
  - Uses dense matrices and `Optim.NelderMead()`.
  - Low-level Julia spec path only.
  - Not sparse production fitting, not AI-REML, not R bridge execution, and no
    EBVs/heritability yet.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1C Gaussian Likelihood Evaluation

- Goal: add a checked Gaussian ML/REML log-likelihood evaluator at supplied
  variance components.
- Active lenses: Ada, Henderson, Gauss, Fisher, Karpinski, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added `src/likelihood.jl`.
  - Added exports: `GaussianLikelihoodResult` and `gaussian_loglik`.
  - Added tests against hand-calculated ML and REML values for a tiny `V = 2I`
    case.
  - Added error tests for non-positive variance components, unsupported method,
    and saturated REML design.
- Boundary:
  - The evaluator intentionally densifies matrices.
  - It evaluates an objective at supplied variance components.
  - It does not optimize variance components, compute EBVs, or fit a model.
- Rose verdict: clean with limitations. This may be described as experimental
  likelihood evaluation, not as animal-model fitting.

## 2026-06-13 Phase 1B Animal Model Spec Validation

- Goal: add the Julia-side typed validator for the low-level animal-model
  payload produced by the R parser lane.
- Active lenses: Ada, Shannon, Hopper, Henderson, Gauss, Karpinski, Rose.
- Spawned subagents: none.
- Coordination note:
  - R/coordinator lane reports an inert `animal()` marker and
    `hs_build_model_spec()` parser are now present in `hsquared`.
  - Julia mirrors that direction with `animal_model_spec()` for `y`, `X`, `Z`,
    `Ainv`, IDs, `GaussianFamily()`, and ML/REML method validation.
  - Bridge execution and model fitting remain planned.
- Implementation evidence:
  - Added `src/model_spec.jl`.
  - Added exports: `GaussianFamily`, `AnimalModelSpec`, and
    `animal_model_spec`.
  - Added tests for valid spec construction, method normalization, default IDs,
    dimension mismatches, ID mismatch, family mismatch, and method mismatch.
- Rose verdict: clean with limitations. This is a bridge-ready validator, not a
  fitting engine.

## 2026-06-13 Genomics QTL GPU HPC Roadmap

- Goal: turn the extended user direction on genomics, QTL/eQTL/GWAS,
  GLLVM-style models, CPU/GPU backends, and HPC into repo-visible Julia docs.
- Active lenses: Ada, Shannon, Jason, Hopper, Karpinski, Grace, Rose, Darwin,
  Falconer, Kirkpatrick.
- Spawned subagents: none.
- Added:
  - `docs/src/genomics-qtl-gpu-hpc.md`
  - `docs/design/08-genomics-qtl-gpu-hpc-plan.md`
- Updated:
  - `docs/make.jl`
  - `docs/src/index.md`
  - `docs/src/changelog.md`
- Source anchors checked:
  - CUDA.jl array and backend docs.
  - AMDGPU.jl quick-start docs.
  - Metal.jl docs and `MtlArray` docs.
  - oneAPI.jl repository.
  - KernelAbstractions.jl docs.
- Rose verdict: clean with limitations. The roadmap is ambitious and public,
  but wording marks genomics/QTL/eQTL/GPU/HPC as planned or experimental until
  implementation, validation, and benchmark evidence exist.

## 2026-06-13 Phase 1A Pedigree And Ainv Utility

- Goal: finish the first Julia Phase 1A engine slice: pedigree normalization,
  direct sparse `Ainv`, and docs-site scaffold.
- Active lenses: Ada, Shannon, Henderson, Mrode, Gauss, Karpinski, Grace,
  Jason, Rose, Pat.
- Spawned subagents: none.
- Coordination boundary:
  - Julia lane edited only `HSquared.jl`.
  - R/coordinator twin owns matching `hsquared` formula/model-spec/status work.
  - Shared contract note: R docs may say Julia `Ainv` construction exists, but
    model fitting remains planned.
- Sister references checked:
  - `DRM.jl/AGENTS.md`, `DRM.jl/docs/make.jl`, `DRM.jl/docs/src/index.md`
  - `GLLVM.jl/AGENTS.md`, `GLLVM.jl/docs/make.jl`,
    `GLLVM.jl/docs/src/index.md`
- Implementation evidence:
  - Added `src/pedigree.jl`.
  - Added exports: `Pedigree`, `normalize_pedigree`,
    `inbreeding_coefficients`, and `pedigree_inverse`.
  - Added tests for valid sorting, malformed parents, duplicate IDs,
    self-parent, same known sire/dam, cycle detection, cache limit, tiny
    hand-checked `Ainv`, and dense inverse comparison.
- Documentation evidence:
  - Added DocumenterVitepress scaffold: `docs/Project.toml`, `docs/make.jl`,
    `docs/src/`.
  - Updated formula/v0.1 contract notes to make R syntax parity the target and
    to require documented, tested bridge translations for any Julia
    discrepancies.
  - Added user-needs and comparator programme docs for breeders, evolutionary
    geneticists, genomic users, and production breeding comparators, while
    keeping superiority claims evidence-gated.
  - Added `Documenter.yml` workflow.
  - Updated README, roadmap, capability status, validation debt, public claims,
    engine contract, coordination board, and AGENTS.
  - Added scout note
    `docs/dev-log/scout/2026-06-13-julia-sister-boundaries.md`.
- Commands run:
  - `julia --project=. test/runtests.jl` passed: 17 Phase 0 checks and 15
    initial Phase 1A checks.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed: 17 Phase 0 checks
    and 17 Phase 1A checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped,
    as expected outside CI. VitePress dependency audit reported npm advisories
    in generated dependencies; build succeeded.
  - `git diff --check` passed.
- Rose verdict: clean with limitations. `Ainv` construction is implemented as
  an engine utility with tiny deterministic evidence; animal-model fitting,
  EBVs, heritability, and R bridge execution remain planned.

## 2026-06-13 Phase 0 Julia Scaffold

- Goal: create the initial `HSquared.jl` package scaffold and operating docs.
- Active lenses: Ada, Shannon, Henderson, Hopper, Boole, Rose, Grace,
  Karpinski.
- Spawned subagents: none after R-lane worker shutdown; R lane belongs to the
  coordinator twin.
- Commands run:
  - `julia --project=. test/runtests.jl` passed with 17 tests.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` first failed because
    `Test` was missing from package test targets.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed after adding
    `Test` to `[extras]` and `[targets]`.
  - `gh repo create itchyshin/HSquared.jl --public --source=. --remote=origin --push`
    created the public GitHub repository and pushed `main`.
  - `gh run watch 27451520721 --repo itchyshin/HSquared.jl --exit-status`
    passed for Julia 1.10 and stable Julia.
  - `gh run watch 27451548449 --repo itchyshin/HSquared.jl --exit-status`
    passed after opting workflow actions into Node 24.
- GitHub verification:
  - `itchyshin/HSquared.jl` visibility is `PUBLIC`.
  - `itchyshin/hsquared` visibility was read-only checked as `PRIVATE` and
    left to the R/coordinator lane.
- Deliberately not run here: R package checks. The R/coordinator twin owns
  `/Users/z3437171/Dropbox/Github Local/hsquared`.

## 2026-06-13 Coordinator Closeout Sync

- Goal: finish the Phase 0 operating plan by syncing the Julia memory skeleton
  with the now-public R twin.
- Active lenses: Ada, Shannon, Rose, Grace, Gauss, Karpinski, Hopper.
- Spawned subagents: none.
- Verified before edits:
  - `git status --short --branch`
  - `git log --oneline --decorate -5`
  - `gh repo view itchyshin/HSquared.jl --json nameWithOwner,visibility,isPrivate,url,defaultBranchRef,licenseInfo,hasIssuesEnabled`
  - `gh run list --repo itchyshin/HSquared.jl --limit 5`
- Result before edits: clean `main`, public repo, issues enabled, MIT license
  detected by GitHub, latest CI green.
- Added mirrored project-local skills and launchable role configs:
  - `.agents/skills/`
  - `.codex/agents/`
- Added missing design surfaces to match the R-side operating skeleton:
  `00-vision.md`, `02-formula-grammar.md`, `03-engine-contract.md`,
  `04-validation-canon.md`, `05-roadmap.md`,
  `06-public-claims-register.md`, and `10-after-task-protocol.md`.
- Updated README and roadmap to remove stale Phase 0 next actions and
  unsupported `fast` wording.
- Validation after edits:
  - temporary PyYAML target plus
    `/Users/z3437171/.codex/skills/.system/skill-creator/scripts/quick_validate.py`
    validated all 11 mirrored project-local skills.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 17 tests.
  - `git diff --check` passed.
  - unsupported-claim scan found only audit/register text, not public claims
    of implemented fitting or speed.

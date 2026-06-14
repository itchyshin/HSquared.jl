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
- The Julia twin mirrors the R twin's marker-map and genotype-marker metadata
  validation semantics locally in `HSData`; this does not change bridge
  payloads or add genomic fitting.
- The R twin added marker-status summary diagnostics at `hsquared` head
  `b1a4e48`; this is R-only reporting, with no bridge payload change and no
  required Julia action unless a later `HSData` summary parity slice is chosen.
- The R twin added `data_status()` diagnostics at `hsquared` head `1fe0f4c`;
  Julia mirrors this as `data_status(::HSData)` with typed diagnostic rows and
  no bridge payload change.
- The R twin added pedigree-status diagnostics at `hsquared` head `3fafa08`;
  Julia mirrors this in `data_status(::HSData)` with typed pedigree diagnostic
  rows and no bridge payload change.
- The R twin can now feed `hs_data()` into `model_spec()` and `hsquared()` for
  the v0.1 parser at `hsquared` head `36efbf3`; the bridge payload shape is
  unchanged and live Julia `HSData` object marshalling remains planned.
- The R twin added formula ergonomics at `hsquared` heads `74eef82` and
  `39ca990`: `animal(1 | id)` may use the pedigree stored in
  `data = hs_data(..., pedigree = ped)`. The explicit
  `animal(1 | id, pedigree = ped)` syntax remains the shared portable
  contract, and no Julia engine API or bridge payload change is required.
- The R twin added genotype-status diagnostics at `hsquared` head `f067cd9`:
  `summary(hs_data(...))` and `data_status()` report genotype rows, genotype
  IDs, marker-column counts, named/unnamed marker-column counts, duplicate
  named marker-column counts, missing genotype value counts, and component
  type. Julia mirrors this as `HSDataGenotypeStatusRow` metadata diagnostics
  only. No bridge payload, PLINK/VCF parsing, genotype imputation, genomic
  relationship construction, marker scan, QTL/GWAS/eQTL, GLLVM, or fitting
  claim changes.
- The R twin added fit-object diagnostics at `hsquared` head `060988d`:
  `fit_diagnostics()` reports existing result-payload metadata such as engine,
  method, family, target, convergence, optimizer status, iterations, logLik,
  `df`, `nobs`, dense-validation-path flags, variance-component source, and
  scalar Julia diagnostics when present. Julia mirrors this as
  `fit_diagnostics()` metadata extraction for `AnimalModelFit` and
  supplied-variance `HendersonMMEResult` objects. This does not widen
  `result_payload()` and does not add new fitting behavior.
- The R twin added environment-key diagnostics at `hsquared` head `e7fbb31`:
  `hs_data(..., environment = env, environment_id = "site")` validates a
  shared key and reports `environment_status` in `summary()` and
  `data_status()`. Julia mirrors this as `HSEnvironmentSpec` and
  `HSDataEnvironmentStatusRow` metadata diagnostics only. No bridge payload,
  model-term, automatic join, or fitting claim changes.
- The R twin added annotation-feature diagnostics at `hsquared` head
  `87888d9`: `hs_data(..., annotation = annot, annotation_id = "gene_id")`
  validates expression-feature annotation metadata and reports
  `annotation_status` in `summary()` and `data_status()`. Julia mirrors this
  as `HSAnnotationSpec` and `HSDataAnnotationStatusRow` metadata diagnostics
  only. No bridge payload, automatic annotation join, eQTL/omics, GLLVM, or
  fitting claim changes.
- The R twin added expression-status diagnostics at `hsquared` head `06cdf59`:
  `summary(hs_data(...))` and `data_status()` report expression rows,
  expression IDs, feature counts, named/unnamed feature counts, duplicate
  named feature counts, and component type. Julia mirrors this as
  `HSDataExpressionStatusRow` metadata diagnostics only. No bridge payload,
  automatic expression join, eQTL/omics, GLLVM, or fitting claim changes.
- The Julia twin has `sparse_csc_matrix()` for R `Matrix::dgCMatrix` slot
  marshalling.
- The R twin has an opt-in experimental tiny/local Julia path at `hsquared`
  head `9eabf0d`: `control = hs_control(engine = "julia")`.
- The R twin has PEV/reliability extractor contracts at `hsquared` head
  `78ba5ff`; at head `8235289` it enriches opt-in tiny/local Julia bridge
  results from exported Julia extractors when available. At head `d7e8914`, it
  also enriches supplied-variance `target = "henderson_mme"` bridge results
  from `prediction_error_variance(mme)` and `reliability(mme)` when applicable.
  Julia keeps those fields out of the compact base `result_payload()`.
- The R twin added EBV/BLUP/accuracy extractor ergonomics at `hsquared` head
  `afa25f1`; Julia mirrors `EBV()`, `BLUP()`, and checked `accuracy()` as local
  extractor vocabulary only, with no bridge payload change.
- Julia now provides validation-scale `prediction_error_variance(mme)` and
  `reliability(mme)` methods for supplied-variance `HendersonMMEResult`
  objects. These reuse the dense MME inverse block for tiny fixtures only and
  do not change `result_payload()`.
- The R twin added an explicit opt-in supplied-variance Henderson MME bridge
  target at `hsquared` head `00b9e33`: `engine_control$target =
  "henderson_mme"` with supplied `sigma_a2` and `sigma_e2`. The path normalizes
  fixed effects, EBVs/BLUPs, fitted values, supplied variance components,
  simple `h2`, `nobs`, diagnostics, and convergence status into
  `hsquared_fit`; it deliberately omits `logLik`, AIC, `df`, and optimizer
  output.
- The Julia twin now has the matching direct convenience target:
  `fit_animal_model(...; target = :henderson_mme, variance_components = ...)`.
  It returns `HendersonMMEResult` and deliberately has no log-likelihood, AIC,
  `df`, optimizer output, or variance-component estimation.
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
- The Documenter workflow isolates npm cache state during the docs build after
  a transient remote DocumenterVitepress/npm cache failure on run
  `27461779343`. This is workflow hygiene only and does not change the package
  API, docs content, bridge contract, or capability status.
- The R twin added a supplied-variance Henderson MME fixture at `hsquared`
  heads `ec2a9cc` and `ca8bce1`; Julia mirrors the fixture for `Ainv`, fixed
  effects, EBVs, fitted values, and `h2`. This remains supplied-variance
  validation only: no variance-component estimation, AI-REML, fitted Mrode
  validation, external fitted-model parity, or production sparse fitting claim.
- Julia now has a Mrode9-shaped supplied-variance fixture that pins `Ainv`,
  ML/REML likelihood values, fixed effects, EBVs, fitted values, PEV,
  reliability, derived accuracy, and `h2`. This strengthens supplied-variance
  equation and extractor evidence, but remains not fitted Mrode output
  validation and not variance-component estimation.
- Julia now has an experimental `fit_sparse_reml()` path and matching
  `fit_animal_model(...; target = :sparse_reml)` dispatch for validated REML
  specs and direct payloads. This optimizes the sparse REML objective for tiny
  validation fixtures only. It does not change the compact `result_payload()`,
  does not require an R bridge change, and is not AI-REML, fitted Mrode
  validation, external fitted-model parity, or production sparse fitting.
- Julia now has experimental production-sparse PEV/reliability:
  `prediction_error_variance`/`reliability` accept `method = :selinv`, a
  Takahashi selected inverse (kernel adapted from DRM.jl, MIT) of the sparse MME
  coefficient matrix. The selinv diagonal matches the dense MME inverse diagonal
  to machine precision on tiny + Mrode9 fixtures. The default extractor path
  stays dense and `result_payload()` is unchanged (no R bridge change required);
  R can opt in via its existing PEV/reliability extractor enrichment. Posted to
  `HSquared.jl` issue #6.
- Julia now has experimental Phase-4B structured multivariate genetic covariance
  support: `diagonal_covariance`, `lowrank_covariance`,
  `factor_analytic_covariance`, and
  `fit_multivariate_reml(...; genetic_structure = :diagonal | :lowrank |
  :factor_analytic, rank = K)`. This is dense/validation-scale and
  engine-internal; `result_payload()` and the R bridge contract are unchanged.
  Returned loading metadata is sign-canonicalized on the Julia side only, with
  the sign-only policy recorded in
  `docs/dev-log/decisions/2026-06-14-loading-rotation-identifiability.md`.
  R-facing covariance-structure syntax, full loading rotation/interpretation
  conventions, and external comparators remain coordinated future work.
- Julia now also has an opt-in Phase-4B structured-covariance recovery harness:
  `sim/phase4b_structured_covariance_recovery.jl`. It runs seeded low-rank and
  factor-analytic repeated-record half-sib simulations outside CI, accepts
  explicit `--seeds` lists, and records loose covariance-recovery thresholds
  with per-case summaries. This strengthens Julia-internal recovery tooling
  only; it does not open R-facing covariance syntax, bridge payload changes,
  broad multi-seed calibration, or comparator claims.
- Julia now has a shared deterministic two-trait CSV fixture at
  `test/fixtures/phase4_multitrait_parity/` for R-lane sommer/ASReml/BLUPF90
  comparator work. It serializes the pedigree, phenotypes, and Julia REML
  target values (`G0`, `R0`, beta, EBVs, h², loglik). This is a target fixture
  for future R-lane parity, not external comparator evidence and not a bridge
  payload change.
- The fixture README and
  `docs/dev-log/decisions/2026-06-14-multitrait-comparator-protocol.md` now
  define the R-lane comparator protocol: same bivariate Gaussian animal model,
  REML target, likelihood-scale caveat, version/control reporting, and no row
  promotion until a comparator run records a tolerance and evidence chain.
- Julia now has opt-in unstructured multivariate REML recovery evidence at
  `sim/phase4_multivariate_reml_recovery.jl`. Default seed `20260616` passes on
  a repeated-record half-sib design outside CI, and the harness now accepts
  `--seed` or explicit `--seeds` lists with summaries. This retires the "no
  committed recovery harness" gap for `V4-MV-REML`, but does not provide broad
  multi-seed calibration or external comparator parity.
- Julia now records the shared multivariate recovery calibration protocol at
  `docs/dev-log/decisions/2026-06-14-multivariate-recovery-calibration-protocol.md`.
  It defines the seed-count, run-plan, and reporting gate required before any
  broad multi-seed calibration claim for `V4-MV-REML` or `V4-FA`. The protocol
  has now been executed on predeclared seed lists and did not pass
  (unstructured 6/10, factor-analytic 8/10, low-rank 9/10; all fits converged).
  This does not change R syntax, bridge payloads, or comparator status.
- Julia now has `single_marker_scan` as a direct Phase 5 fixed-effect Gaussian
  marker-screening utility. It residualizes `y` and centered marker dosages
  against `X` and returns effects, supplied-variance standard errors, z-scores,
  chi-square statistics, approximate two-sided Gaussian/Wald p-values,
  Bonferroni-adjusted p-values, Benjamini-Hochberg q-values, fixed-effect
  known-variance LOD-equivalent scores, denominators, marker IDs, allele
  frequencies, and the VanRaden scale. `marker_scan_table()` prepares
  row-aligned marker-scan tables from those direct scan fields in original scan
  order, with allele variances, marker-variance contributions, optional
  total-variance proportions, optional variance components / marker groups
  when present, and optional exact marker-map metadata alignment. It is not
  `gwas_table()` / `qtl_table()` / `eqtl_table()` activation.
  `marker_effects()` prepares
  sorted top-marker effect summaries from those direct scan fields, with
  optional exact marker-map metadata alignment. `marker_variance_explained()`
  prepares sorted marker-level variance-contribution summaries as
  `2p(1-p) * effect^2`, with optional total-variance proportions and exact
  marker-map metadata alignment; it is not a calibrated PVE/model R² claim.
  `marker_significance_summary()` reports nominal returned-marker-set raw,
  Bonferroni, and BH significance flags/counts plus top-marker provenance from
  the same direct scan fields; it is not a calibrated genome-wide threshold
  workflow.
  `marker_manhattan_data()`
  prepares plot-ready Manhattan data from those direct scan fields and can
  consume already-validated `HSMarkerMapSpec` / `HSData` marker metadata by
  exact marker ID. `marker_region_data()` prepares one-chromosome or
  coordinate-window regional data from those row-aligned scan fields,
  preserving original scan indices and optional marker-variance proportions for
  future regional display code. `marker_qq_data()` prepares sorted
  observed/expected QQ plot data from the same direct scan output, and
  `marker_genomic_inflation()` computes a genomic-control-style lambda_GC
  diagnostic from returned chi-square values. The opt-in
  `sim/phase5_marker_scan_recovery.jl` harness records default-seed marker
  recovery smoke for fixed, supplied-variance mixed, and supplied LOCO direct
  scans outside CI.
  This is engine-internal / direct-Julia only:
  no mixed-model GWAS/QTL/eQTL, relatedness or population-structure correction,
  calibrated mixed-model p-values, calibrated PVE/model R² claims,
  interval-mapping or mixed-model LOD workflows, marker file parsing, plotting
  backend, calibrated/correlated-marker genome-wide thresholds,
  `regional_plot()` / fine-mapping activation,
  advanced/correlated-marker multiple-testing workflow,
  `gwas_table()` / `qtl_table()` / `eqtl_table()` activation,
  R `marker_scan()` formula activation, bridge payload change, or
  `result_payload()` change.
- Julia now has `mixed_model_marker_scan` as a direct Phase 5 dense
  supplied-variance GLS marker-screening utility. It forms
  `V = sigma_a2 * Z * A * Z' + sigma_e2 * I` from supplied variance components
  and a supplied relationship precision, then runs marker-by-marker Wald tests
  conditional on `X`. This is engine-internal / direct-Julia only: no
  marker-scan variance-component estimation, LOCO, sparse production scan,
  calibrated p-values, calibrated PVE/model R² claims, interval-mapping or
  mixed-model LOD workflows, plotting backend, R `marker_scan()` formula
  activation, bridge payload change, or `result_payload()` change.
- Julia now has `loco_relationship_precisions` and
  `loco_mixed_model_marker_scan` as direct Phase 5 leave-one-group-out
  marker-screening utilities. The construction helper drops each marker group,
  builds a dense VanRaden relationship from the remaining markers, and applies
  the existing ridge-regularized inverse; the scan helper selects the matching
  precision before running the dense supplied-variance GLS scan. This is
  engine-internal / direct-Julia only: no public LOCO defaults, marker-scan
  variance-component estimation, sparse production scan, calibrated p-values,
  calibrated PVE/model R² claims, plotting backend, R `marker_scan()` formula
  activation, bridge payload change, or `result_payload()` change.
- R head `21161a5` documents multivariate extractor examples, with CI recorded
  by `6b5758b`. Julia mirrors the extractor vocabulary locally for
  multivariate result `NamedTuple`s:
  `variance_components`, `fixed_effects`, `heritability` (REML results only),
  and `breeding_values`/`EBV`/`BLUP`. These are copy-returning wrappers over
  existing result fields and do not change `result_payload()` or the R bridge
  contract.
- The Julia backend algorithm roadmap now distinguishes the implemented
  Phase-4B dense CPU validation-scale structured-`G0` path from the still
  planned GPU/performance path. This is status wording only: no backend
  dispatch, R-facing covariance syntax, bridge payload, or `result_payload()`
  change.
- Julia now has an experimental average-information REML estimator:
  `fit_ai_reml` / `fit_animal_model(...; target = :ai_reml)`. It recovers the
  same optimum as the dense/sparse NelderMead optimizers, and its AI matrix
  matches the observed information (ratio ~0.99) on a 250-animal sim — a valid
  Newton metric (a read-only forensic study of DRM.jl found its AI-REML failed
  because its augmented-state Laplace model gives a ~5× undersized AI metric;
  HSquared's exact-Gaussian animal model is the regime where AI-REML is valid).
  REML-only, Gaussian, experimental; `result_payload()` unchanged; no external
  comparator yet. Posted to `HSquared.jl` issue #5. For future non-Gaussian
  phases, observed-information Newton (DRM's solution) is the reuse path.
- Phase 2 (genomic) started on the Julia lane: `genomic_relationship_matrix`
  builds the VanRaden `G` from a marker matrix — engine-internal, additive, no
  bridge/result/model-spec change. The contract-touching part (Ginv + GBLUP
  wiring + the genomic model-spec mapping R's `genomic()`/`markers()` to the
  engine) is the NEXT slice and will be coordinated with the R twin before
  landing. Phase-boundary heads-up posted to `hsquared` issue #9. The dense `G`
  ops are the Apple M1 Ultra (Metal) GPU target later; clusters deferred.

## Current State

- Phase 0 public scaffold: complete.
- Public repos: `itchyshin/hsquared` and `itchyshin/HSquared.jl`.
- Initial GitHub issue ledger: issues #1-#7 in both repos.
- Phase 1 Julia lane:
  - pedigree normalization and direct sparse `Ainv` utility implemented;
  - low-level `AnimalModelSpec` validation implemented;
  - dense Gaussian likelihood evaluation implemented for supplied variance
    components with a `max_dense_cells` guard;
  - experimental sparse REML validation optimization implemented for validated
    REML specs;
  - experimental dense variance-component optimization implemented for
    validated specs;
  - experimental dense variance-component, fixed-effect, MME-backed EBV/BLUP
    aliases and fitted-value, heritability, PEV, reliability, and checked
    accuracy extractors
    implemented for validated specs;
  - `fit_diagnostics()` metadata extraction implemented for low-level
    `AnimalModelFit` and supplied-variance `HendersonMMEResult` objects;
  - experimental direct `fit_animal_model(y, X, Z, Ainv; ...)` target
    implemented for bridge-shaped payloads.
  - sparse Henderson MME solving at supplied variance components implemented
    and mirrored against the shared R/Julia supplied-variance fixture.
  - Mrode9-shaped supplied-variance validation implemented for dense/sparse
    likelihood identity, Henderson MME outputs, PEV, reliability, accuracy, and
    `h2`; fitted Mrode output validation remains planned.
  - `HSData`, `HSDataIDMap`, and `id_map()` implemented as a conservative
    in-memory mirror of the R `hs_data()` input-container contract.
  - `HSData` marker-map metadata validation and genotype-marker alignment
    checks implemented.
  - `data_status(::HSData)` diagnostics implemented for component presence,
    ID overlap, pedigree status, genotype status, marker status, expression status,
    annotation-feature status, and environment-key status.
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
- R lane handoff from `itchyshin/hsquared` heads `74eef82` and `39ca990`:
  - `animal(1 | id)` can use the pedigree stored in
    `data = hs_data(..., pedigree = ped)`;
  - canonical portable syntax remains `animal(1 | id, pedigree = ped)`;
  - reported remote evidence: R-CMD-check `27461601773`, pkgdown
    `27461601799`, and Pages `27461636297` success;
  - boundary: R parser/data-container ergonomics only. No Julia engine API
    change and no bridge payload shape change.
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

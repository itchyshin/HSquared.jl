# Changelog

## Unreleased

- Added pedigree normalization and sparse `Ainv` construction utilities.
- Added low-level animal-model specification validation.
- Added dense Gaussian ML/REML log-likelihood evaluation at supplied variance
  components.
- Added sparse REML log-likelihood evaluation at supplied variance components
  using the Henderson MME determinant identity.
- Expanded planned backend marker/control vocabulary to include threaded CPU,
  AMDGPU, Metal, and oneAPI markers alongside CPU, CUDA, and auto metadata.
- Added `backend_info()` typed status diagnostics for planned backend rows with
  execution marked unavailable.
- Added planned genomic/QTL model-term vocabulary reservations:
  `genomic()`, `single_step()`, `markers()`, `marker_scan()`, and `qtl_scan()`.
- Added planned standard quantitative-genetic model-term vocabulary
  reservations: `permanent()`, `common_env()`, `maternal_genetic()`,
  `maternal_env()`, `paternal_genetic()`, `paternal_env()`, `cytoplasmic()`,
  `imprinting()`, `dominance()`, `epistasis()`, `relmat()`, and
  `HSquared.precision()` in direct Julia code.
- Added a Documenter model-spec grammar page mirroring the R twin's status
  separation for parsed, reserved, and planned syntax.
- Added `formula_status()` grammar diagnostics and a Documenter status table
  mirroring the R twin's parsed/reserved/planned grammar rows.
- Added `validation_status()` diagnostics for covered, external, partial, and
  planned validation rows.
- Added `max_dense_cells` guards for the temporary dense validation path.
- Added experimental dense variance-component optimization for validated
  low-level animal-model specs.
- Added experimental low-level variance-component, fixed-effect, EBV/BLUP,
  fitted-value, and heritability extractors for the dense spec path.
- Switched `breeding_values(fit)` to the Henderson MME solve at the fit's
  variance components.
- Switched `fitted_values(fit)` to the same Henderson MME solve at the fit's
  variance components.
- Added experimental dense prediction-error-variance and reliability extractors
  for the dense spec path.
- Extended validation-scale prediction-error-variance and reliability
  extractors to supplied-variance `HendersonMMEResult` objects.
- Extended supplied-variance `variance_components()` and `heritability()`
  extractors to `HendersonMMEResult` objects.
- Added `EBV()` and `BLUP()` aliases for `breeding_values()`, plus
  `accuracy()` as a checked square-root transformation of reliability.
- Added experimental direct payload `fit_animal_model(y, X, Z, Ainv; ...)`
  target for bridge-shaped inputs.
- Added explicit `fit_animal_model(...; target = :henderson_mme,
  variance_components = ...)` dispatch for supplied-variance Henderson MME
  solving.
- Added `henderson_mme()` for sparse Henderson mixed-model-equation solving at
  supplied variance components.
- Added a shared R/Julia Henderson mixed-model-equation validation fixture for
  the supplied-variance output path.
- Added `result_payload()` with field names aligned to the R `hsquared_fit`
  extractor contract.
- Added `HSData`, `HSDataIDMap`, and `id_map()` as an in-memory mirror of the R
  `hs_data()` input-container contract.
- Added `HSData` marker-map metadata validation and genotype-marker alignment
  checks.
- Added `data_status(::HSData)` diagnostics mirroring the R twin's
  `data_status()` surface for component presence, ID-overlap counts, pedigree
  status, marker-alignment status, and environment-key status. Diagnostic
  only; no bridge payload, raw-pedigree Ainv construction, genotype parsing,
  relationship construction, environment-covariate joins, environmental model
  terms, marker scan, genomic fitting, or QTL/eQTL claim.
- Recorded the R twin's `hs_data()` environment-key diagnostics from
  `hsquared` head `e7fbb31` and mirrored them in Julia `HSData` as metadata
  diagnostics only.
- Added `sparse_csc_matrix()` for R `Matrix::dgCMatrix` slot marshalling.
- Recorded the R twin's PEV/reliability bridge extractor contract while keeping
  Julia `result_payload()` fields unchanged.
- Recorded the R twin's tiny/local bridge enrichment of PEV/reliability from
  exported Julia extractors, still without widening base `result_payload()`.
- Recorded the R twin's supplied-variance `target = "henderson_mme"`
  enrichment from `prediction_error_variance(mme)` and `reliability(mme)`,
  still without widening base `result_payload()`.
- Recorded the R twin's opt-in supplied-variance Henderson MME bridge target,
  with explicit no-log-likelihood/no-variance-estimation boundary.
- Recorded the R twin's sparse `Z` bridge marshalling handoff.
- Recorded the R twin's optional `nadiv::Mrode9` pedigree-Ainv comparator
  evidence.
- Recorded the R twin's `model_spec()` preview surface for the v0.1
  formula-to-bridge payload.
- Recorded the R twin's `hs_data()` parser integration for the v0.1
  formula-to-bridge payload without changing the Julia payload shape.
- Recorded the R twin's `animal(1 | id)` shorthand for
  `data = hs_data(..., pedigree = ped)` as R-side formula ergonomics only; the
  explicit `animal(1 | id, pedigree = ped)` contract and Julia payload shape
  are unchanged.
- Added DocumenterVitepress documentation scaffold.
- Added audience and comparator programme notes.
- Added genomics/QTL/eQTL/GLLVM/GPU/HPC strategic roadmap.
- Added a backend and algorithm roadmap page for CPU, threads, CUDA, AMDGPU,
  Metal, oneAPI, AI-REML, Takahashi selected inversion, Woodbury paths, APY,
  and claim gates.
- Kept high-level fitting entry points as honest placeholders.

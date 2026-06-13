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
- Added `max_dense_cells` guards for the temporary dense validation path.
- Added experimental dense variance-component optimization for validated
  low-level animal-model specs.
- Added experimental low-level variance-component, fixed-effect, EBV/BLUP,
  fitted-value, and heritability extractors for the dense spec path.
- Added experimental dense prediction-error-variance and reliability extractors
  for the dense spec path.
- Added experimental direct payload `fit_animal_model(y, X, Z, Ainv; ...)`
  target for bridge-shaped inputs.
- Added `henderson_mme()` for sparse Henderson mixed-model-equation solving at
  supplied variance components.
- Added a Henderson mixed-model-equation validation fixture for the dense
  output path.
- Added `result_payload()` with field names aligned to the R `hsquared_fit`
  extractor contract.
- Added `HSData`, `HSDataIDMap`, and `id_map()` as an in-memory mirror of the R
  `hs_data()` input-container contract.
- Added `sparse_csc_matrix()` for R `Matrix::dgCMatrix` slot marshalling.
- Recorded the R twin's PEV/reliability bridge extractor contract while keeping
  Julia `result_payload()` fields unchanged.
- Recorded the R twin's tiny/local bridge enrichment of PEV/reliability from
  exported Julia extractors, still without widening base `result_payload()`.
- Recorded the R twin's sparse `Z` bridge marshalling handoff.
- Recorded the R twin's optional `nadiv::Mrode9` pedigree-Ainv comparator
  evidence.
- Recorded the R twin's `model_spec()` preview surface for the v0.1
  formula-to-bridge payload.
- Recorded the R twin's `hs_data()` parser integration for the v0.1
  formula-to-bridge payload without changing the Julia payload shape.
- Added DocumenterVitepress documentation scaffold.
- Added audience and comparator programme notes.
- Added genomics/QTL/eQTL/GLLVM/GPU/HPC strategic roadmap.
- Added a backend and algorithm roadmap page for CPU, threads, CUDA, AMDGPU,
  Metal, oneAPI, AI-REML, Takahashi selected inversion, Woodbury paths, APY,
  and claim gates.
- Kept high-level fitting entry points as honest placeholders.

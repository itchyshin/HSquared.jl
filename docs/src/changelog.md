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
- Recorded the R twin's sparse `Z` bridge marshalling handoff.
- Recorded the R twin's optional `nadiv::Mrode9` pedigree-Ainv comparator
  evidence.
- Added DocumenterVitepress documentation scaffold.
- Added audience and comparator programme notes.
- Added genomics/QTL/eQTL/GLLVM/GPU/HPC strategic roadmap.
- Kept high-level fitting entry points as honest placeholders.

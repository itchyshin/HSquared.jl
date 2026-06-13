# Capability Status

| Capability | Status | Evidence |
| --- | --- | --- |
| Package loads | implemented | `test/runtests.jl` |
| Backend marker types | implemented | `CPUBackend`, `ThreadsBackend`, `CUDABackend`, `AMDGPUBackend`, `MetalBackend`, `OneAPIBackend`, and `AutoBackend` tests; marker types only, no backend dispatch |
| `HSControl` validation | implemented | validates shared R/Julia planned backend and accelerator vocabulary in `test/runtests.jl`; no backend execution claim |
| `backend_info()` status diagnostics | implemented | typed rows for `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, and `oneapi`; all selectable, all `execution_available == false`, all `status == :planned`; no runtime probing |
| Backend and algorithm roadmap documentation | implemented | Documenter page and design note mirror R head `2c18b30`; roadmap only, no backend execution, GPU, APY, AI-REML, Takahashi selected inversion, GLLVM fitting, or performance claim |
| `formula_status()` grammar diagnostics | implemented | 20 typed rows matching the R twin's parsed, reserved, and planned grammar status categories; diagnostic only |
| Planned genomic/QTL model-term vocabulary | implemented | `planned_genomic_qtl_terms()`, `genomic()`, `single_step()`, `markers()`, `marker_scan()`, and `qtl_scan()` tests; functions throw planned-not-implemented errors and do not construct model specs |
| Planned standard quantitative-genetic model-term vocabulary | implemented | `planned_quantgen_terms()`, `permanent()`, `common_env()`, `maternal_genetic()`, `maternal_env()`, `paternal_genetic()`, `paternal_env()`, `cytoplasmic()`, `imprinting()`, `dominance()`, `epistasis()`, `relmat()`, and `HSquared.precision()` tests; functions throw planned-not-implemented errors and do not construct model specs |
| `HSData` input container | implemented | in-memory phenotype/pedigree/genotype/expression ID-map tests; no file-backed storage or modelling claim |
| `hsquared()` fitting | planned | Phase 0 placeholder only |
| `fit_animal_model(spec)` dense fitting | experimental | dispatches to `fit_variance_components()` for validated `AnimalModelSpec`; all other signatures remain placeholders |
| Pedigree validation | implemented | `normalize_pedigree()` valid, malformed, duplicate, missing-parent, self-parent, same-parent, and cycle tests |
| Sparse `Ainv` | implemented | `pedigree_inverse()` hand-checked tiny pedigrees and dense inverse comparison; shared calf/sire/dam fixture mirrored by R head `fe7e346`; optional R-side `nadiv::Mrode9` / `nadiv::makeAinv()` comparator at R head `369d14a`; bounded relationship cache, no huge-scale claim |
| Sparse CSC bridge marshalling | implemented | `sparse_csc_matrix()` zero-based R-slot, one-based Julia-slot, malformed-slot, and direct payload integration tests |
| Animal model spec validation | implemented | `animal_model_spec()` dimension, ID, family, and method tests |
| Gaussian ML/REML likelihood evaluation | experimental | `gaussian_loglik()` hand-calculated tiny tests; dense evaluator only, supplied variance components only |
| Sparse REML likelihood identity | experimental | `sparse_reml_loglik()` matches dense REML on tiny fixtures using the Henderson MME determinant identity; supplied variance components only, no optimizer or AI-REML |
| Dense variance-component optimization | experimental | `fit_variance_components()` tiny improvement and dispatch tests; dense path only |
| Dense validation size guard | implemented | `max_dense_cells` tests for likelihood, dense optimizer, spec dispatch, and direct payload dispatch; guard only, not a sparse solver |
| Supplied-variance Henderson MME solve | experimental | `henderson_mme()` sparse solve tested against deterministic Henderson MME fixture; does not estimate variance components or claim production fitting |
| Dense EBVs/BLUPs | experimental | `breeding_values()` hand-checked dense identity-relationship test and Henderson MME fixture; no sparse production solve or comparator yet |
| Dense heritability | experimental | `heritability()` hand-checked simple univariate variance-ratio test |
| Dense reliability / PEV | experimental | `prediction_error_variance()` and `reliability()` tested against dense Henderson MME inverse; no sparse production solve or comparator yet |
| Direct payload fit target | experimental | `fit_animal_model(y, X, Z, Ainv; ...)` parity tests against validated-spec dispatch; dense path only |
| R result payload shape | experimental | `result_payload()` field-name/value tests aligned to R `hsquared_fit` extractor contract; R head `c837f2d` has an internal JuliaCall smoke over these fields; R head `8235289` enriches the opt-in tiny/local R bridge from exported Julia PEV/reliability extractors when available, while Julia deliberately keeps those fields out of base `result_payload()` |
| R v0.1 formula parser and payload preview | external implemented | `hsquared` head `b57b48e`; R parser builds the narrow bridge payload; head `9eabf0d` adds opt-in experimental `hs_control(engine = "julia")` for tiny/local use; head `398e019` records sparse `Z` marshalling through Julia `sparse_csc_matrix()`; head `bacef9c` adds exported `model_spec()` preview without fitting or Julia execution |
| R `hs_data()` data container | external implemented | `hsquared` head `644c75e`; Julia mirror exists as `HSData`, but live marshalling is not implemented |
| Opt-in R-to-Julia bridge execution | external experimental | `hsquared` head `398e019`; R consumes Julia `sparse_csc_matrix()` for sparse `Z`, but still no production sparse fitting, Mrode validation, large-data readiness, or relationship-object marshalling beyond `Z` |
| File-backed phenotype/genotype storage | planned | no Arrow/Parquet/PLINK/VCF/HDF5/Zarr implementation yet |
| Sparse production fitting / AI-REML | planned | sparse REML objective identity exists for supplied variances only; no sparse optimizer or AI-REML yet |
| Production sparse reliability / PEV | planned | no implementation yet |
| Multivariate G matrices | planned | no implementation yet |
| Factor-analytic G matrices | planned | no implementation yet |
| Genomic prediction, single-step fitting, marker scans, and QTL/eQTL | planned | vocabulary reserved only; no implementation yet |
| Standard QG effects and custom kernels | planned | vocabulary reserved only; no implementation yet |
| Non-standard inheritance | planned | no implementation yet |
| GLLVM-style animal models | planned | no implementation yet |

Status words:

- `implemented`: code, tests, and docs exist.
- `experimental`: code exists but public claims are restricted.
- `planned`: roadmap/design only.
- `missing`: not yet designed.

# Public Claims Register

Use this register before changing README, docs, issue text, or examples.

| Claim | Status | Evidence | Allowed wording |
| --- | --- | --- | --- |
| `HSquared.jl` is a Julia package scaffold | covered | local tests and GitHub Actions CI green | implemented scaffold |
| `HSquared.jl` is the Julia engine package identity | covered | public repo exists and package loads | Julia engine scaffold |
| backend and accelerator vocabulary is recorded | covered | `HSControl` tests for CPU, threaded CPU, CUDA, AMDGPU, Metal, oneAPI, generic GPU, and auto metadata; R head `5feac1f` mirrors the same vocabulary | planned control metadata only; CPU is the trusted always-available path, accelerator names are future optional-extension targets |
| backend status diagnostics are available | covered | `backend_info()` tests mirror R `backend_info()` row shape and report all rows as planned/unavailable | honest status diagnostic only; no runtime probing |
| planned genomic/QTL model-term vocabulary is reserved | covered | `planned_genomic_qtl_terms()` and planned-term error tests; R head `3c82c9a` mirrors the same public names | syntax reservation only; no genomic prediction, marker scan, single-step, QTL/eQTL, or marker-effect estimation |
| planned standard quantitative-genetic model-term vocabulary is reserved | covered | `planned_quantgen_terms()` and planned-term error tests; R head `10e8fd7` mirrors the same public names | syntax reservation only; no permanent/common environment, maternal/paternal, cytoplasmic, imprinting, dominance, epistasis, custom relationship, or precision-kernel fitting |
| GPU backend execution works | planned | marker types and controls only | planned |
| Julia `hsquared()` performs model fitting | planned | placeholder only | planned |
| high-level `fit_animal_model()` performs production Gaussian animal-model fitting | planned | unsupported signatures still use honest placeholder errors; exact low-level dense methods are experimental | planned production target |
| pedigree validation and sorting | covered | `normalize_pedigree()` tests over valid and malformed pedigrees | implemented engine utility |
| sparse Ainv construction | covered | `pedigree_inverse()` tests over tiny pedigrees and dense inverse comparison; R head `369d14a` optional `nadiv::Mrode9` / `nadiv::makeAinv()` comparator | direct sparse pedigree inverse utility with optional Mrode9/nadiv comparator evidence; not a fitted model |
| low-level animal model spec validation | covered | `animal_model_spec()` tests over dimensions, IDs, family, and method | bridge-ready validator; not a fitted model |
| Gaussian animal model ML/REML likelihood value | partial | `gaussian_loglik()` tiny hand-calculated tests | experimental dense likelihood evaluator at supplied variance components |
| Sparse REML likelihood identity | partial | `sparse_reml_loglik()` dense-vs-sparse REML equivalence tests on tiny fixtures | experimental sparse REML objective evaluation at supplied variance components; not a sparse optimizer, AI-REML, or production fitting |
| Dense variance-component optimization | partial | `fit_variance_components()` tiny improvement tests | experimental low-level Julia spec path; not sparse production or R bridge fitting |
| Dense validation path is size-guarded | covered | `max_dense_cells` tests over likelihood, optimizer, spec dispatch, and direct payload dispatch | safety guard for the temporary dense path; not evidence of sparse production scale |
| Henderson MME equations can be solved at supplied variance components | partial | `henderson_mme()` deterministic MME fixture tests | sparse supplied-variance equation solve; not variance-component estimation, Mrode validation, or production fitting |
| Dense EBV/BLUP, heritability, reliability, and PEV extractors | partial | `breeding_values()`, `heritability()`, `prediction_error_variance()`, and `reliability()` tiny hand-checked tests plus Henderson MME fixture | experimental dense low-level extractors; not production sparse EBVs, reliability, or PEV |
| Direct Julia payload fit target exists | partial | `fit_animal_model(y, X, Z, Ainv; ...)` parity tests against spec dispatch | experimental dense Julia target for bridge-shaped payloads; not R bridge execution |
| Julia result payload matches R extractor names | partial | `result_payload()` tests for R contract names and values; R head `c837f2d` internal JuliaCall smoke | experimental result payload shape; public R fitting still planned |
| R v0.1 formula parser can build the bridge target | external partial | `hsquared` head `b57b48e`; R checks green and pkgdown live | R can parse the narrow grammar and build an internal bridge payload; public bridge execution remains planned |
| Opt-in R-to-Julia bridge path works for tiny/local smoke examples | external partial | `hsquared` head `9eabf0d`; R-CMD-check `27456875004`, pkgdown `27456874995`, Pages `27456904688` green | experimental tiny/local path via `hs_control(engine = "julia")`; default remains `engine = "validate"` |
| R bridge consumes sparse `Z` slots | external partial | `hsquared` head `398e019`; R-CMD-check `27457295759`, pkgdown `27457295761`, Pages `27457326836` green | sparse `Z` marshalling through Julia `sparse_csc_matrix()`; not large-data readiness or production sparse fitting |
| PEV/reliability are returned through the R bridge payload | planned | R head `78ba5ff` adds extractor contracts and future-compatible normalization; Julia `result_payload()` deliberately excludes these fields | planned bridge-widening task requiring lockstep R and Julia tests |
| Production R-to-Julia bridge execution works | planned | sparse `Z` marshalling exists, but no Mrode validation, production sparse fitting, production controls, or relationship-object marshalling beyond `Z` yet | planned |
| Sparse Gaussian animal model REML/ML fitting | planned | sparse REML identity exists only for supplied variances | planned production fitting target |
| Production sparse EBVs/BLUPs, reliability, and PEV | planned | none | planned |
| multivariate G matrices | planned | none | roadmap |
| factor-analytic G matrices | planned | none | roadmap |
| genomic prediction, single-step, marker scans, and QTL/eQTL | planned | syntax names are reserved only | roadmap |
| standard QG effects and custom relationship/precision kernels | planned | syntax names are reserved only | roadmap |
| GLLVM-style animal models | planned | none | roadmap |
| non-standard inheritance systems | planned | none | roadmap |

Public docs may describe roadmap targets but must not say planned capabilities
are implemented.

# Public Claims Register

Use this register before changing README, docs, issue text, or examples.

| Claim | Status | Evidence | Allowed wording |
| --- | --- | --- | --- |
| `HSquared.jl` is a Julia package scaffold | covered | local tests and GitHub Actions CI green | implemented scaffold |
| `HSquared.jl` is the Julia engine package identity | covered | public repo exists and package loads | Julia engine scaffold |
| Julia `hsquared()` performs model fitting | planned | placeholder only | planned |
| `fit_animal_model()` performs Gaussian animal-model fitting | planned | placeholder only | planned Phase 1 target |
| pedigree validation and sorting | covered | `normalize_pedigree()` tests over valid and malformed pedigrees | implemented engine utility |
| sparse Ainv construction | covered | `pedigree_inverse()` tests over tiny pedigrees and dense inverse comparison | direct sparse pedigree inverse utility; not a fitted model |
| low-level animal model spec validation | covered | `animal_model_spec()` tests over dimensions, IDs, family, and method | bridge-ready validator; not a fitted model |
| Gaussian animal model ML/REML likelihood value | partial | `gaussian_loglik()` tiny hand-calculated tests | experimental dense likelihood evaluator at supplied variance components |
| Dense variance-component optimization | partial | `fit_variance_components()` tiny improvement tests | experimental low-level Julia spec path; not sparse production or R bridge fitting |
| Dense EBV/BLUP, heritability, reliability, and PEV extractors | partial | `breeding_values()`, `heritability()`, `prediction_error_variance()`, and `reliability()` tiny hand-checked tests plus Henderson MME fixture | experimental dense low-level extractors; not production sparse EBVs, reliability, or PEV |
| Direct Julia payload fit target exists | partial | `fit_animal_model(y, X, Z, Ainv; ...)` parity tests against spec dispatch | experimental dense Julia target for bridge-shaped payloads; not R bridge execution |
| Julia result payload matches R extractor names | partial | `result_payload()` tests for R contract names and values; R head `c837f2d` internal JuliaCall smoke | experimental result payload shape; public R fitting still planned |
| R v0.1 formula parser can build the bridge target | external partial | `hsquared` head `b57b48e`; R checks green and pkgdown live | R can parse the narrow grammar and build an internal bridge payload; public bridge execution remains planned |
| Internal R-to-Julia bridge smoke works | external partial | `hsquared` head `c837f2d`; R-CMD-check `27456664820`, pkgdown `27456664821`, Pages `27456696277` green | internal contract validation only; public `hsquared()` still stops before fitting |
| Public R-to-Julia bridge execution works | planned | no public bridge return test yet | planned |
| Sparse Gaussian animal model REML/ML fitting | planned | none | planned production fitting target |
| Production sparse EBVs/BLUPs, reliability, and PEV | planned | none | planned |
| multivariate G matrices | planned | none | roadmap |
| factor-analytic G matrices | planned | none | roadmap |
| genomic and single-step models | planned | none | roadmap |
| GLLVM-style animal models | planned | none | roadmap |
| non-standard inheritance systems | planned | none | roadmap |

Public docs may describe roadmap targets but must not say planned capabilities
are implemented.

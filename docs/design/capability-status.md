# Capability Status

| Capability | Status | Evidence |
| --- | --- | --- |
| Package loads | implemented | `test/runtests.jl` |
| Backend marker types | implemented | `CPUBackend`, `CUDABackend`, `AutoBackend` tests |
| `HSControl` validation | implemented | `test/runtests.jl` |
| `hsquared()` fitting | planned | Phase 0 placeholder only |
| `fit_animal_model(spec)` dense fitting | experimental | dispatches to `fit_variance_components()` for validated `AnimalModelSpec`; all other signatures remain placeholders |
| Pedigree validation | implemented | `normalize_pedigree()` valid, malformed, duplicate, missing-parent, self-parent, same-parent, and cycle tests |
| Sparse `Ainv` | implemented | `pedigree_inverse()` hand-checked tiny pedigrees and dense inverse comparison; bounded relationship cache, no huge-scale claim |
| Animal model spec validation | implemented | `animal_model_spec()` dimension, ID, family, and method tests |
| Gaussian ML/REML likelihood evaluation | experimental | `gaussian_loglik()` hand-calculated tiny tests; dense evaluator only, supplied variance components only |
| Dense variance-component optimization | experimental | `fit_variance_components()` tiny improvement and dispatch tests; dense path only |
| Dense EBVs/BLUPs | experimental | `breeding_values()` hand-checked dense identity-relationship test; no sparse production solve or comparator yet |
| Dense heritability | experimental | `heritability()` hand-checked simple univariate variance-ratio test |
| Direct payload fit target | experimental | `fit_animal_model(y, X, Z, Ainv; ...)` parity tests against validated-spec dispatch; dense path only |
| R v0.1 formula parser and payload builder | external implemented | `hsquared` head `b57b48e`; R parser builds the narrow bridge payload but does not execute Julia fitting |
| R-to-Julia bridge execution | planned | no marshalling/parity test yet |
| Sparse production fitting / AI-REML | planned | no implementation yet |
| Reliability / PEV | planned | no implementation yet |
| Multivariate G matrices | planned | no implementation yet |
| Factor-analytic G matrices | planned | no implementation yet |
| Genomic/single-step models | planned | no implementation yet |
| Non-standard inheritance | planned | no implementation yet |
| GLLVM-style animal models | planned | no implementation yet |

Status words:

- `implemented`: code, tests, and docs exist.
- `experimental`: code exists but public claims are restricted.
- `planned`: roadmap/design only.
- `missing`: not yet designed.

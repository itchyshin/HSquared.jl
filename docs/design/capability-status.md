# Capability Status

| Capability | Status | Evidence |
| --- | --- | --- |
| Package loads | implemented | `test/runtests.jl` |
| Backend marker types | implemented | `CPUBackend`, `CUDABackend`, `AutoBackend` tests |
| `HSControl` validation | implemented | `test/runtests.jl` |
| `hsquared()` fitting | planned | Phase 0 placeholder only |
| `fit_animal_model()` fitting | planned | Phase 0 placeholder only |
| Pedigree validation | implemented | `normalize_pedigree()` valid, malformed, duplicate, missing-parent, self-parent, same-parent, and cycle tests |
| Sparse `Ainv` | implemented | `pedigree_inverse()` hand-checked tiny pedigrees and dense inverse comparison; bounded relationship cache, no huge-scale claim |
| Animal model spec validation | implemented | `animal_model_spec()` dimension, ID, family, and method tests |
| Gaussian ML/REML likelihood evaluation | experimental | `gaussian_loglik()` hand-calculated tiny tests; dense evaluator only, supplied variance components only |
| Variance-component optimization / fitting | planned | no implementation yet |
| EBVs/BLUPs | planned | no implementation yet |
| Heritability | planned | no implementation yet |
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

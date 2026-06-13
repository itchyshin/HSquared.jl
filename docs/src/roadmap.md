# Roadmap

This page mirrors the repository roadmap. It is evidence-gated: a capability is
public only when code, tests, documentation, validation status, and the R-Julia
contract agree.

## Current Status

Phase 0 is complete. Phase 1 has started.

Implemented:

- package scaffold and CI;
- control/backend markers for the shared planned `auto`, `cpu`, `threads`,
  `cuda`, `amdgpu`, `metal`, and `oneapi` vocabulary;
- `backend_info()` status diagnostics for the planned backend vocabulary;
- `formula_status()` grammar diagnostics for parsed, reserved, and planned
  syntax rows;
- `validation_status()` diagnostics for covered, external, partial, and
  planned validation rows;
- planned model-term vocabulary reservations aligned to the R genomic/QTL and
  standard quantitative-genetic markers;
- placeholder fitting entry points;
- pedigree validation and topological sorting;
- direct sparse `Ainv` construction for validated pedigrees;
- optional external R-side `nadiv::Mrode9` / `nadiv::makeAinv()` comparator
  evidence for `pedigree_inverse()`;
- low-level animal-model spec validation;
- dense Gaussian likelihood evaluation with a `max_dense_cells` guard;
- sparse REML likelihood evaluation at supplied variance components via the
  Henderson MME determinant identity;
- experimental dense variance-component optimization;
- experimental MME-backed EBV/BLUP aliases, fitted-value, heritability, PEV,
  reliability, and checked accuracy extraction for dense spec and
  supplied-variance Henderson MME validation paths;
- experimental direct payload fitting target for `y`, `X`, `Z`, `Ainv`;
- sparse Henderson MME solving at supplied variance components, with a shared
  R/Julia fixture for Ainv, fixed effects, EBVs, fitted values, and `h2`;
- sparse CSC marshalling helper for R sparse matrix slots;
- `HSData` marker-map metadata validation and genotype-marker alignment checks;
- `data_status()` diagnostics for `HSData` component presence, ID-overlap
  counts, pedigree status, and marker-alignment status;
- external opt-in R bridge evidence from `hsquared` head `9eabf0d`;
- external R PEV/reliability bridge enrichment evidence from `hsquared` head
  `8235289`; R can merge those fields from exported Julia extractors for
  tiny/local validation fits while Julia keeps base `result_payload()` compact.
- external R EBV/BLUP/accuracy extractor ergonomics evidence from `hsquared`
  head `afa25f1`; Julia mirrors the names locally without adding payload
  fields.
- external R supplied-variance Henderson MME bridge evidence from `hsquared`
  head `00b9e33`; R can opt into `engine_control$target = "henderson_mme"` and
  supplied variance components, with no log-likelihood, AIC, `df`, optimizer
  output, variance-component estimation, AI-REML, or fitted Mrode claim.
- external R `model_spec()` preview evidence from `hsquared` head `bacef9c`;
  this previews the v0.1 formula-to-bridge payload without fitting or Julia
  execution.
- external R `hs_data()` parser integration evidence from `hsquared` head
  `36efbf3`; this lets `model_spec()` and `hsquared()` read v0.1 model
  variables from `data$phenotypes` and resolve `pedigree` from the bundle
  while keeping the bridge payload shape unchanged.
- external R formula-ergonomics evidence from `hsquared` heads `74eef82` and
  `39ca990`; `animal(1 | id)` may use the pedigree stored in
  `data = hs_data(..., pedigree = ped)`, while explicit
  `animal(1 | id, pedigree = ped)` remains the shared portable contract.
- external sparse `Z` bridge marshalling evidence from `hsquared` head
  `398e019`.
- roadmap documentation for genomics, QTL/eQTL, GLLVM, backend, algorithm, and
  HPC strategy mirrored from the R twin's expanded plan at `hsquared` head
  `2c18b30`.

Not implemented:

- sparse production animal-model REML/ML or AI-REML fitting;
- production sparse EBVs/BLUPs, reliability, and prediction error variance;
- production R-to-Julia fitting bridge;
- genomic prediction, single-step fitting, marker-effect estimation,
  marker scans, and QTL/eQTL scans;
- permanent environment, common environment, maternal/paternal effects,
  cytoplasmic inheritance, imprinting, dominance, epistasis, and custom
  relationship/precision kernels;
- backend execution dispatch, runtime backend availability probing, GPU
  execution, backend benchmarking, and CPU/GPU numerical agreement tests.
- APY approximation, Takahashi selected inversion, production AI-REML,
  Woodbury-backed factor/GLLVM engines, and HPC checkpointing.

## Phase 1: Simple Gaussian Animal Model

Next engine targets:

1. Mrode-style validation and comparator checks;
2. R/Julia decision on whether PEV/reliability should ever become required
   base bridge payload fields;
3. live Julia `HSData` object marshalling, relationship-object marshalling
   beyond sparse `Z`, and stable production
   engine controls;
4. production sparse covariance/precision computations;
5. AI-REML or a documented sparse optimizer path;
6. production sparse reliability and prediction error variance.

## Later Phases

- Phase 2: genomic relationship models, GBLUP, SNP-BLUP, supplied `Hinv`, and
  first marker-effect outputs.
- Phase 3: maternal, paternal, repeatability, common-environment, dominance,
  cytoplasmic, and inheritance-kernel models.
- Phase 4: multivariate G matrices with `us()`, `diag()`, `lowrank(K)`, and
  `fa(K)`.
- Phase 5: QTL/GWAS/eQTL scans, LOCO option, multiple testing, and basic
  plots.
- Phase 6: non-Gaussian and GLLVM-style animal models, omics, and community
  examples.
- Phase 7: CPU/GPU acceleration with CPU, threads, Metal, CUDA, AMDGPU, oneAPI,
  and portable kernels.
- Phase 8: HPC and production scaling with checkpointing, disk-backed data,
  streaming marker scans, distributed computation, and multi-GPU experiments.

Every new public capability must update the status tables, validation debt,
tests, docs, and after-task report in the same slice.

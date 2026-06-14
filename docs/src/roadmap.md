# Roadmap

This page mirrors the repository roadmap. It is evidence-gated: a capability is
public only when code, tests, documentation, validation status, and the R-Julia
contract agree.

For a dashboard view of this status, see [Mission control](mission-control.md).

## Current Status

Phase 0 is complete. The Julia engine now has experimental validation-scale
coverage through univariate animal models, genomic utilities, repeatability /
two-effect models, multivariate REML, structured multivariate genetic
covariance, and a first fixed-effect marker-screening helper. These are not
production sparse pipelines or public R formula defaults.

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
- experimental sparse REML validation optimization for low-level validated
  specs;
- experimental average-information REML for two-component Gaussian animal
  models, with R-lane recovery / published-anchor evidence but pending
  Julia-native large-pedigree hardening;
- experimental dense variance-component optimization;
- experimental MME-backed EBV/BLUP aliases, fitted-value, heritability, PEV,
  reliability, and checked accuracy extraction for dense spec and
  supplied-variance Henderson MME validation paths;
- `fit_diagnostics()` metadata extraction for low-level fit objects;
- experimental direct payload fitting target for `y`, `X`, `Z`, `Ainv`;
- sparse Henderson MME solving at supplied variance components, with a shared
  R/Julia fixture for Ainv, fixed effects, EBVs, fitted values, and `h2`;
- sparse CSC marshalling helper for R sparse matrix slots;
- `HSData` marker-map metadata validation and genotype-marker alignment checks;
- `data_status()` diagnostics for `HSData` component presence, ID-overlap
  counts, pedigree status, genotype status, marker-alignment status,
  expression status, annotation-feature status, and environment-key status;
- external opt-in R bridge evidence from `hsquared` head `9eabf0d`;
- external R PEV/reliability bridge enrichment evidence from `hsquared` head
  `8235289`; R can merge those fields from exported Julia extractors for
  tiny/local validation fits while Julia keeps base `result_payload()` compact.
- external R EBV/BLUP/accuracy extractor ergonomics evidence from `hsquared`
  head `afa25f1`; Julia mirrors the names locally without adding payload
  fields.
- external R `fit_diagnostics()` evidence from `hsquared` head `060988d`;
  Julia mirrors this as a metadata-only helper over existing result fields.
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
- external R `hs_data()` genotype diagnostics evidence from `hsquared` head
  `f067cd9`; Julia mirrors the genotype-shape metadata diagnostics locally in
  `HSData`, with no PLINK/VCF parsing, genotype imputation, genomic
  relationship construction, bridge payload, marker scan, QTL/GWAS/eQTL, or
  genomic fitting claim.
- external R `hs_data()` environment diagnostics evidence from `hsquared` head
  `e7fbb31`; Julia mirrors the shared-key metadata diagnostics locally in
  `HSData`, with no bridge payload or modelling change.
- external R `hs_data()` expression diagnostics evidence from `hsquared` head
  `06cdf59`; Julia mirrors the expression-shape metadata diagnostics locally
  in `HSData`, with no bridge payload, automatic join, eQTL, omics, or GLLVM
  workflow claim.
- external R `hs_data()` annotation diagnostics evidence from `hsquared` head
  `87888d9`; Julia mirrors the expression-feature metadata diagnostics
  locally in `HSData`, with no bridge payload, automatic join, eQTL, omics, or
  GLLVM workflow claim.
- external sparse `Z` bridge marshalling evidence from `hsquared` head
  `398e019`.
- roadmap documentation for genomics, QTL/eQTL, GLLVM, backend, algorithm, and
  HPC strategy mirrored from the R twin's expanded plan at `hsquared` head
  `2c18b30`.
- experimental genomic utilities: VanRaden `G`,
  `genomic_relationship_inverse`, supplied-variance `fit_gblup`,
  `fit_snp_blup`, single-step `H`-inverse construction, genomic REML over a
  `Ginv` spec, direct fixed-effect `single_marker_scan`, supplied-variance
  `mixed_model_marker_scan`, dense LOCO precision construction via
  `loco_relationship_precisions`, supplied `loco_mixed_model_marker_scan`, and
  Manhattan/QQ plot-data helpers.
- experimental repeatability / two-effect REML utilities.
- experimental multivariate animal-model utilities, including
  supplied-covariance MME, missing-trait records, dense multivariate REML,
  structured genetic covariance (`diag`, `lowrank`, `fa`), Julia-side
  extractors, opt-in recovery harnesses, and a serialized target fixture for
  future R-lane comparator work.

Not implemented:

- production sparse animal-model REML/ML/AI-REML fitting;
- production sparse EBVs/BLUPs, reliability, and prediction error variance;
- production R-to-Julia fitting bridge;
- public R-facing genomic/marker model-spec fitting, production genomic
  prediction, APY/sparse genomic scaling, formula-driven mixed-model marker
  scans, public LOCO workflows, calibrated mixed-model p-values,
  interval-mapping or mixed-model LOD workflows, genome-wide calibration, and
  QTL/eQTL intervals;
- public R-facing permanent environment, common environment,
  maternal/paternal effects,
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
5. production hardening for sparse REML / AI-REML;
6. production sparse reliability and prediction error variance.

## Later Phases

- Phase 2: genomic relationship models, GBLUP, SNP-BLUP, supplied `Hinv`, and
  first marker-effect outputs are experimental engine utilities; production
  genomic model-spec wiring and comparator parity remain future work.
- Phase 3: maternal, paternal, repeatability, common-environment, dominance,
  cytoplasmic, and inheritance-kernel models.
- Phase 4: multivariate G matrices with `us()`, `diag()`, `lowrank(K)`, and
  `fa(K)` are experimental engine utilities; R-facing syntax and comparator
  parity remain future work.
- Phase 5: direct fixed-effect marker screening has started with Wald p-values,
  Bonferroni/BH adjustments, LOD-equivalent scores, and marker-map-backed
  Manhattan, QQ, and lambda_GC diagnostic data. A supplied-variance dense GLS
  `mixed_model_marker_scan` exists for direct Julia relationship-corrected
  screening, `loco_relationship_precisions` constructs dense
  VanRaden-plus-ridge leave-one-group-out precision matrices, and
  `loco_mixed_model_marker_scan` can select among supplied LOCO precision
  matrices. Formula-driven QTL/GWAS/eQTL scans, public LOCO workflow defaults,
  genome-wide calibration, calibrated p-values, and actual plotting
  backends remain future work.
- Phase 6: non-Gaussian and GLLVM-style animal models, omics, and community
  examples.
- Phase 7: CPU/GPU acceleration with CPU, threads, Metal, CUDA, AMDGPU, oneAPI,
  and portable kernels.
- Phase 8: HPC and production scaling with checkpointing, disk-backed data,
  streaming marker scans, distributed computation, and multi-GPU experiments.

Every new public capability must update the status tables, validation debt,
tests, docs, and after-task report in the same slice.

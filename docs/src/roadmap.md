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
- experimental dense EBV/BLUP, heritability, PEV, and reliability extraction;
- experimental direct payload fitting target for `y`, `X`, `Z`, `Ainv`;
- sparse Henderson MME solving at supplied variance components;
- sparse CSC marshalling helper for R sparse matrix slots;
- external opt-in R bridge evidence from `hsquared` head `9eabf0d`;
- external R PEV/reliability bridge extractor contract evidence from
  `hsquared` head `78ba5ff`, with Julia payload widening still planned.
- external sparse `Z` bridge marshalling evidence from `hsquared` head
  `398e019`.

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

## Phase 1: Simple Gaussian Animal Model

Next engine targets:

1. Mrode-style validation and comparator checks;
2. lockstep R/Julia decision on PEV/reliability bridge payload fields;
3. relationship-object marshalling beyond sparse `Z` and stable production
   engine controls;
4. production sparse covariance/precision computations;
5. AI-REML or a documented sparse optimizer path;
6. production sparse reliability and prediction error variance.

## Later Phases

- Phase 2: repeatability, maternal, common-environment, sire, and related
  standard animal-model extensions.
- Phase 3: multivariate Gaussian animal models.
- Phase 4: factor-analytic G matrices.
- Phase 5: genomic and single-step models.
- Phase 6: non-Gaussian and GLLVM-style animal models.
- Phase 7: non-standard inheritance.
- Phase 8: huge-scale and accelerator strategy.

Every new public capability must update the status tables, validation debt,
tests, docs, and after-task report in the same slice.

# Roadmap

This page mirrors the repository roadmap. It is evidence-gated: a capability is
public only when code, tests, documentation, validation status, and the R-Julia
contract agree.

## Current Status

Phase 0 is complete. Phase 1 has started.

Implemented:

- package scaffold and CI;
- control/backend markers;
- placeholder fitting entry points;
- pedigree validation and topological sorting;
- direct sparse `Ainv` construction for validated pedigrees;
- low-level animal-model spec validation;
- dense Gaussian likelihood evaluation;
- experimental dense variance-component optimization;
- experimental dense EBV/BLUP, heritability, PEV, and reliability extraction;
- experimental direct payload fitting target for `y`, `X`, `Z`, `Ainv`;
- sparse CSC marshalling helper for R sparse matrix slots;
- external opt-in R bridge evidence from `hsquared` head `9eabf0d`.

Not implemented:

- sparse production animal-model REML/ML or AI-REML fitting;
- production sparse EBVs/BLUPs, reliability, and prediction error variance;
- production R-to-Julia fitting bridge.

## Phase 1: Simple Gaussian Animal Model

Next engine targets:

1. R-side sparse CSC marshalling and stable production engine controls;
2. Mrode-style validation and comparator checks;
3. production sparse covariance/precision computations;
4. AI-REML or a documented sparse optimizer path;
5. production sparse reliability and prediction error variance.

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

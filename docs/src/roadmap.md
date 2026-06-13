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
- direct sparse `Ainv` construction for validated pedigrees.

Not implemented:

- animal-model REML/ML fitting;
- EBVs/BLUPs;
- heritability;
- R-to-Julia fitting bridge.

## Phase 1: Simple Gaussian Animal Model

Next engine targets:

1. fixed-effect and animal random-effect design handling;
2. Gaussian ML/REML objective;
3. conservative optimizer path;
4. variance components;
5. EBVs/BLUPs;
6. heritability;
7. Mrode-style validation and comparator checks.

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

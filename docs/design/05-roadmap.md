# Roadmap Detail

## Phase 0: Operating System And Scaffold

Status: covered.

- Public Julia package scaffold.
- CI.
- Honest placeholder exports.
- Team and memory docs.
- Capability and validation status docs.
- GitHub issue ledger.

## Phase 1: Simple Gaussian Animal Model

- Pedigree validation and sorting. Covered for initial utility surface.
- ID recoding. Covered inside `normalize_pedigree()`.
- Sparse direct `Ainv`. Covered for initial utility surface.
- Gaussian REML/ML objective.
- EBVs/BLUPs.
- Variance components and heritability.
- Mrode and tiny validation examples.

## Phase 2: Standard Animal-Model Extensions

- repeatability;
- permanent environment;
- maternal and common environment;
- sire models;
- groups and unknown parent groups;
- reliability/accuracy.

## Phase 3: Multivariate Gaussian

- block sparse designs;
- `A kron G_A`;
- residual covariance;
- missing trait records;
- genetic correlations.

## Phase 4: Factor-Analytic G Matrices

- diagonal, low-rank, and factor-analytic G structures;
- loadings and specific variance;
- latent breeding values;
- evolvability outputs.

## Phase 5: Genomic And Single-Step

- GBLUP, SNP-BLUP, HBLUP;
- `Ginv` and `Hinv`;
- APY approximations;
- marker-derived genomic relationships.

## Phase 6: GLLVM And Non-Gaussian Models

- Poisson, negative binomial, binomial, ordinal, and zero-inflated families;
- wide response matrices;
- latent genetic axes;
- ordination outputs.

## Phase 7: Non-Standard Inheritance

- selfing;
- clonal/asexual systems;
- haplodiploidy;
- polyploidy;
- cytoplasmic effects;
- dominance and epistasis;
- custom precision kernels.

## Phase 8: Huge-Scale And Accelerators

- disk-backed workflows;
- preconditioned iterative solvers;
- GPU-aware dense/factor paths where justified;
- documented benchmark evidence.

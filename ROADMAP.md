# HSquared.jl Roadmap

`HSquared.jl` is the Julia engine for the R package `hsquared`.

The roadmap is intentionally evidence-gated. A capability is public only when
implementation, tests, documentation, validation status, and the R-Julia
contract agree.

## Current Status

Phase 0 scaffold.

- Package loads.
- Control/backend placeholders exist.
- Fitting is not implemented.
- Public model syntax is planned, not executable.

## Phase -1: Learn The Existing Teams

Learn from:

- `drmTMB`: R package discipline, formula grammar, validation debt, after-task
  reports, fitted/planned/missing status.
- `DRM.jl`: Julia twin constitution, R parity, workflows, quality battery, and
  bridge design.
- `gllvmTMB`: long/wide discipline, reader-first docs, capability status,
  covariance grammar, and article gates.
- `GLLVM.jl`: Julia engine structure, performance wording, sparse/low-rank
  computation, and quality checks.
- `drmTMB/docs/agent-kit`: portable team and memory operating system.

Gate: `docs/design/00-ecosystem-lessons.md` records what is borrowed, adapted,
and refused.

## Phase 0: Public Twin Scaffold And Constitution

- Create public `itchyshin/HSquared.jl`.
- Keep `hsquared` as the R public identity.
- Add `AGENTS.md`, roadmap, design docs, dev-log scaffolding, placeholder
  exports, tests, and CI.
- Keep all fitting claims marked planned.

Gate: package loads, tests pass, CI exists, both twins have synchronized
operating docs, and no public docs claim model fitting.

## Phase 1: Simple Gaussian Animal Model

First real capability:

- pedigree validation and sorting;
- ID recoding;
- founder and unknown-parent handling;
- direct sparse `Ainv`;
- fixed and random-effect design;
- univariate Gaussian REML/ML;
- EBVs/BLUPs;
- variance components and heritability.

Gate: Mrode simple animal-model example plus tiny hand-checked pedigrees and
comparator checks where available.

## Phase 2: Standard Quantitative-Genetic Models

Add repeatability, permanent environment, maternal effects, common environment,
sire models, unknown parent groups, inbreeding, and the first random-regression
slice.

Gate: every model has a canonical example, recovery check, extractor check,
capability row, and validation-debt row.

## Phase 3: Multivariate Gaussian Animal Models

Add long-format trait grammar, `A kron G_A`, residual `R`, missing trait
records, G/R/P matrices, genetic correlations, and cross-trait EBVs.

Gate: long-format examples and missing-record tests land before public
tutorial claims.

## Phase 4: Factor-Analytic G Matrices

Add `diag()`, `lowrank(K)`, and `fa(K)` covariance structures:

- `lowrank(K) = Lambda Lambda'`
- `fa(K) = Lambda Lambda' + Psi`

Gate: Kirkpatrick and Noether sign off on notation, syntax, parameterization,
and extractor meanings.

## Phase 5: Genomic And Single-Step Models

Add GBLUP, SNP-BLUP, single-step HBLUP, APY approximation, marker-derived
relationships, and scaling/blending of `G` and `A`.

Gate: Jason scout plus Rose license/claim audit.

## Phase 6: Non-Gaussian And GLLVM-Style Animal Models

Add non-Gaussian families, wide matrix responses, genetic latent factors,
ordination, and community/ecology examples.

Gate: long and wide examples are paired whenever both formats are supported.

## Phase 7: Non-Standard Inheritance

Add selfing, clonal/asexual, haplodiploid, polyploid, cytoplasmic, dominance,
epistasis, and custom precision kernels.

Gate: each inheritance system has a documented relationship/precision
construction and biological interpretation.

## Phase 8: Huge-Scale And Accelerator Strategy

CPU first. GPU later for dense/massively parallel pieces where evidence says it
helps.

Gate: speed claims report hardware, data size, records, animals, traits,
nonzeros, memory, and comparator.

## Next Work Queue

1. Keep Julia and R Phase 0 wording synchronized.
2. Create the public GitHub repository.
3. Run local tests.
4. Add GitHub issues for Phase 1 design slices.

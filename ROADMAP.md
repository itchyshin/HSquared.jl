# HSquared.jl Roadmap

`HSquared.jl` is the Julia engine for the R package `hsquared`.

The roadmap is intentionally evidence-gated. A capability is public only when
implementation, tests, documentation, validation status, and the R-Julia
contract agree.

## Current Status

Phase 0 public scaffold is complete. Phase 1 has started with the first
pedigree/Ainv engine utility slice.

- Package loads.
- Control/backend placeholders exist.
- Pedigree validation, ID recoding, unknown-parent handling, and topological
  sorting exist.
- In-memory `HSData` input container and conservative ID-overlap map exist.
- Direct sparse `Ainv` construction exists for validated pedigrees, with tiny
  hand-checked tests.
- Low-level animal-model spec validation exists for `y`, `X`, `Z`, `Ainv`, IDs,
  Gaussian family, and ML/REML method.
- Dense Gaussian ML/REML log-likelihood evaluation exists for supplied variance
  components.
- Experimental dense variance-component optimization exists for low-level
  validated Julia specs.
- Experimental low-level variance-component, fixed-effect, EBV/BLUP,
  fitted-value, and heritability extractors exist for the dense spec path.
- Experimental direct payload fitting target exists for `y`, `X`, `Z`, `Ainv`
  bridge-shaped inputs.
- High-level formula fitting and R bridge execution are not implemented.
- Public model syntax is planned, not executable.
- `itchyshin/HSquared.jl` is public and GitHub Actions CI is green.
- Matching labels, Phase 0-8 milestones, and issues #1-#7 exist.

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

Gate: covered by `docs/design/00-ecosystem-lessons.md`.

## Phase 0: Public Twin Scaffold And Constitution

- Create public `itchyshin/HSquared.jl`.
- Keep `hsquared` as the R public identity.
- Add `AGENTS.md`, roadmap, design docs, dev-log scaffolding, placeholder
  exports, tests, and CI.
- Keep all fitting claims marked planned.

Gate: covered. Package loads, tests pass, CI exists, both twins have
synchronized operating docs, and public docs do not claim model fitting.

## Phase 1: Simple Gaussian Animal Model

First real capability:

- pedigree validation and sorting; initial utility covered;
- ID recoding; initial utility covered;
- founder and unknown-parent handling; initial utility covered;
- direct sparse `Ainv`; initial utility covered;
- low-level animal-model spec validation; initial bridge validator covered;
- fixed and random-effect design;
- univariate Gaussian ML/REML likelihood evaluation; dense initial evaluator
  covered for supplied variance components;
- experimental dense variance-component optimization; initial low-level path
  covered for validated specs;
- experimental dense EBV/BLUP, fitted-value, and heritability extractors;
- experimental direct payload fitting target for the R parser's intended
  `y`, `X`, `Z`, `Ainv` handoff;
- sparse production optimizer and AI-REML;
- production sparse EBVs/BLUPs, reliability, prediction error variance, and
  heritability.
- in-memory phenotype/pedigree/genotype/expression ID container; initial mirror
  covered.
- file-backed phenotype/genotype storage; planned.

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

1. Add cross-repo R-to-Julia marshalling tests around the current R parser and
   Julia direct payload target.
2. Add Julia-side `HSData` integration tests once the R bridge sends actual
   `hs_data()` payloads.
3. Add Mrode/simple comparator validation for the dense low-level path.
4. Replace dense covariance equations with sparse production computations.
5. Keep `hsquared` issue #2 synchronized with this engine contract.
6. Add Mrode/comparator validation before promoting animal-model fitting.

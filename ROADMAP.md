# HSquared.jl Roadmap

`HSquared.jl` is the Julia engine for the R package `hsquared`.

The roadmap is intentionally evidence-gated. A capability is public only when
implementation, tests, documentation, validation status, and the R-Julia
contract agree.

## Current Status

Phase 0 public scaffold is complete. Phase 1 has started with the first
pedigree/Ainv engine utility slice.

- Package loads.
- Control/backend placeholders exist for the shared planned vocabulary:
  `auto`, `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, and `oneapi`.
- Planned model-term vocabulary exists for genomic/QTL terms and standard
  quantitative-genetic terms: `genomic()`, `single_step()`, `markers()`,
  `marker_scan()`, `qtl_scan()`, `permanent()`, `common_env()`,
  `maternal_genetic()`, `maternal_env()`, `paternal_genetic()`,
  `paternal_env()`, `cytoplasmic()`, `imprinting()`, `dominance()`,
  `epistasis()`, `relmat()`, and `precision()`. These names error honestly and
  do not construct model specs yet. In direct Julia code, the precision-kernel
  marker is qualified as `HSquared.precision()` because `Base.precision`
  already exists.
- Pedigree validation, ID recoding, unknown-parent handling, and topological
  sorting exist.
- In-memory `HSData` input container and conservative ID-overlap map exist.
- Direct sparse `Ainv` construction exists for validated pedigrees, with tiny
  hand-checked tests and optional R-side `nadiv::Mrode9` comparator evidence.
- Low-level animal-model spec validation exists for `y`, `X`, `Z`, `Ainv`, IDs,
  Gaussian family, and ML/REML method.
- Dense Gaussian ML/REML log-likelihood evaluation exists for supplied variance
  components, with a `max_dense_cells` guard for the temporary dense path.
- Sparse REML likelihood evaluation exists at supplied variance components via
  the Henderson MME determinant identity.
- Experimental dense variance-component optimization exists for low-level
  validated Julia specs.
- Experimental low-level variance-component, fixed-effect, EBV/BLUP,
  fitted-value, heritability, PEV, and reliability extractors exist for the
  dense spec path.
- Experimental direct payload fitting target exists for `y`, `X`, `Z`, `Ainv`
  bridge-shaped inputs.
- Sparse Henderson mixed-model-equation solving exists at supplied variance
  components.
- Sparse CSC marshalling helper exists for R `Matrix::dgCMatrix` slots.
- R twin has an opt-in experimental tiny/local Julia engine path at `hsquared`
  head `9eabf0d`; R head `8235289` enriches that path with PEV/reliability
  from exported Julia extractors when available while Julia keeps the compact
  base `result_payload()` unchanged.
- R head `398e019` records sparse `Z` bridge marshalling through Julia
  `sparse_csc_matrix()`.
- R head `2c18b30` records the expanded genomics/QTL/GLLVM/GPU/HPC plan; Julia
  mirrors it as roadmap and algorithm/backend documentation only.
- Production high-level formula fitting and production R bridge execution are
  not implemented.
- Backend execution dispatch, runtime backend availability probing, GPU
  execution, backend benchmarking, and CPU/GPU numerical agreement tests are
  not implemented.
- APY approximation, Takahashi selected inversion, production AI-REML,
  Woodbury-backed factor/GLLVM engines, and HPC checkpointing are not
  implemented.
- Genomic prediction, single-step fitting, marker-effect estimation,
  marker scans, and QTL/eQTL scans are not implemented.
- Permanent environment, common environment, maternal/paternal effects,
  cytoplasmic inheritance, imprinting, dominance, epistasis, and custom
  relationship/precision kernels are not implemented.
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
- optional `nadiv::Mrode9` / `nadiv::makeAinv()` Ainv comparator through the R
  twin; pedigree inverse agreement covered externally;
- low-level animal-model spec validation; initial bridge validator covered;
- fixed and random-effect design;
- univariate Gaussian ML/REML likelihood evaluation; dense initial evaluator
  covered for supplied variance components with a dense-size guard;
- sparse REML likelihood identity at supplied variance components; initial
  validation bridge covered against the dense evaluator;
- experimental dense variance-component optimization; initial low-level path
  covered for validated specs;
- experimental dense EBV/BLUP, fitted-value, and heritability extractors;
- experimental direct payload fitting target for the R parser's intended
  `y`, `X`, `Z`, `Ainv` handoff;
- sparse Henderson MME solve at supplied variance components;
- sparse production optimizer and AI-REML;
- production sparse EBVs/BLUPs, reliability, prediction error variance, and
  heritability.
- in-memory phenotype/pedigree/genotype/expression ID container; initial mirror
  covered.
- file-backed phenotype/genotype storage; planned.

Gate: Mrode simple animal-model example plus tiny hand-checked pedigrees and
comparator checks where available.

## Phase 2: Genomic Relationship Models

Add `G` and `Ginv`, GBLUP, SNP-BLUP, supplied `Hinv`, genotype ID matching,
and first marker-effect outputs.

Gate: Jason scout plus Rose license/claim audit, with JWAS/sommer/BLUPF90
style comparator checks before public fitting claims.

## Phase 3: Standard Quantitative-Genetic And Inheritance Models

Add repeatability, permanent environment, maternal effects, common environment,
sire models, dominance, cytoplasmic inheritance, selfing, clonal/asexual,
haplodiploid, polyploid, unknown parent groups, inbreeding, and the first
random-regression slice.

Gate: every model has a canonical example, recovery check, extractor check,
capability row, and validation-debt row.

## Phase 4: Multivariate Gaussian Animal Models

Add long-format trait grammar, `A kron G_A`, residual `R`, missing trait
records, G/R/P matrices, genetic correlations, and cross-trait EBVs.

Gate: long-format examples and missing-record tests land before public
tutorial claims.

## Phase 4B: Factor-Analytic G Matrices

Add `diag()`, `lowrank(K)`, and `fa(K)` covariance structures:

- `lowrank(K) = Lambda Lambda'`
- `fa(K) = Lambda Lambda' + Psi`

Gate: Kirkpatrick and Noether sign off on notation, syntax, parameterization,
and extractor meanings.

## Phase 5: QTL, GWAS, And eQTL

Add single-marker scans, mixed-model marker scans, LOCO, LOD/p-value output,
cis/trans eQTL, multiple testing, and basic plots.

Gate: marker-map validation, estimand definition, multiple-testing checks, and
comparator/simulation evidence.

## Phase 6: Non-Gaussian And GLLVM-Style Animal Models

Add non-Gaussian families, wide matrix responses, genetic latent factors,
ordination, and community/ecology examples.

Gate: long and wide examples are paired whenever both formats are supported.

## Phase 7: CPU/GPU Acceleration

CPU first, then threaded CPU, Metal, CUDA, AMDGPU, oneAPI, and portable kernels
where benchmarks support accelerator use.

Gate: CPU/GPU agreement tests and benchmarks report hardware, data size,
records, animals, traits, nonzeros, memory, precision, and comparator.

## Phase 8: HPC And Production Scaling

Add checkpointing, disk-backed data, streaming marker scans, distributed
simulation, multi-GPU experiments, and national-computer benchmarks.

Gate: production runs are restartable and report machine, data shape, memory,
diagnostics, and comparator context.

## Next Work Queue

1. Add Mrode/simple comparator validation for the dense and sparse
   supplied-variance paths.
2. Decide with the R twin whether PEV/reliability should ever become required
   base `result_payload()` fields; keep current enrichment optional and
   tiny/local.
3. Add Julia-side `HSData` integration tests once the R bridge sends actual
   `hs_data()` payloads.
4. Replace dense covariance equations with sparse production computations.
5. Add AI-REML or a documented sparse optimizer path.
6. Keep `hsquared` issue #2 synchronized with this engine contract.

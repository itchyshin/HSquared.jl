# HSquared.jl Roadmap

`HSquared.jl` is the Julia engine for the R package `hsquared`.

The roadmap is intentionally evidence-gated. A capability is public only when
implementation, tests, documentation, validation status, and the R-Julia
contract agree.

## Current Status

Phase 0 public scaffold is complete. Phases 1-3 have landed as experimental,
validation-scale Julia engine utilities (pedigree/Ainv, supplied-variance and
REML/AI-REML Gaussian animal-model fitting, the VanRaden genomic engine with
GBLUP/SNP-BLUP/single-step `H`-inverse, and the repeatability / two-random-effect
standard quantitative-genetic models). These are engine-internal and not the
public default; production high-level fitting and the public R model-spec remain
unimplemented.

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
- Validation-status diagnostics exist for covered, external, partial, and
  planned validation rows.
- Pedigree validation, ID recoding, unknown-parent handling, and topological
  sorting exist.
- In-memory `HSData` input container and conservative ID-overlap map exist.
- `HSData` validates marker-map metadata and genotype-marker alignment as
  metadata hygiene only.
- `data_status()` reports `HSData` component presence, ID-overlap counts, and
  pedigree, genotype, marker-alignment, expression, annotation-feature, and
  environment-key status as diagnostics only.
- R head `f067cd9` adds `hs_data()` genotype-status diagnostics for
  `summary()` and `data_status()`; Julia mirrors this in `HSData` and
  `data_status()` as metadata diagnostics only.
- R head `06cdf59` adds `hs_data()` expression-status diagnostics for
  `summary()` and `data_status()`; Julia mirrors this in `HSData` and
  `data_status()` as metadata diagnostics only.
- R head `87888d9` adds `hs_data()` annotation-feature diagnostics for
  `summary()` and `data_status()`; Julia mirrors this in `HSData` and
  `data_status()` as metadata diagnostics only.
- R head `e7fbb31` adds `hs_data()` environment-key diagnostics for
  `summary()` and `data_status()`; Julia mirrors this in `HSData` and
  `data_status()` as metadata diagnostics only.
- R head `36efbf3` connects `hs_data()` to the v0.1 R parser for
  `model_spec()` and `hsquared()` while preserving the same bridge payload
  shape; live Julia `HSData` object marshalling remains planned.
- R heads `74eef82` and `39ca990` let R use `animal(1 | id)` as shorthand
  when `data = hs_data(..., pedigree = ped)` supplies the pedigree. The
  explicit `animal(1 | id, pedigree = ped)` syntax remains the shared
  portable contract, and the Julia engine API is unchanged.
- Direct sparse `Ainv` construction exists for validated pedigrees, with tiny
  hand-checked tests and optional R-side `nadiv::Mrode9` comparator evidence.
- Low-level animal-model spec validation exists for `y`, `X`, `Z`, `Ainv`, IDs,
  Gaussian family, and ML/REML method.
- Dense Gaussian ML/REML log-likelihood evaluation exists for supplied variance
  components, with a `max_dense_cells` guard for the temporary dense path.
- Sparse REML likelihood evaluation exists at supplied variance components via
  the Henderson MME determinant identity.
- Experimental sparse REML validation optimization exists for validated REML
  specs; it is not AI-REML and not production sparse fitting.
- Experimental dense variance-component optimization exists for low-level
  validated Julia specs.
- Experimental low-level variance-component, fixed-effect, MME-backed
  EBV/BLUP aliases, fitted-value, heritability, PEV, reliability, and checked
  accuracy extractors exist for the dense spec and supplied-variance Henderson
  MME validation paths.
- Experimental direct payload fitting target exists for `y`, `X`, `Z`, `Ainv`
  bridge-shaped inputs.
- Experimental direct supplied-variance Henderson target exists through
  `fit_animal_model(...; target = :henderson_mme, variance_components = ...)`.
- Sparse Henderson mixed-model-equation solving exists at supplied variance
  components, with a shared R/Julia fixture for Ainv, fixed effects, EBVs,
  fitted values, and `h2`.
- Julia has a Mrode9-shaped supplied-variance fixture for Ainv, ML/REML
  likelihood values, fixed effects, EBVs, fitted values, PEV, reliability,
  derived accuracy, and `h2`. This is still not fitted Mrode output validation
  or variance-component estimation.
- Experimental average-information REML (`fit_ai_reml`) estimates the two
  variance components on the sparse Henderson MME (score from the Takahashi
  selected inverse; AI matrix from working-variate re-solves); experimental,
  REML-only, 2-component, Gaussian-only, not the public default. Known-truth
  recovery and the published gryphon anchor are validated externally in the R
  lane via the bridge (`V1-AI-REML`).
- Experimental sparse selected-inversion PEV/reliability exists via
  `method = :selinv` (Takahashi selected inverse of the sparse MME coefficient
  matrix), matching the dense MME inverse diagonal to machine precision on
  tiny and Mrode9-shaped fixtures.
- Experimental variance-component covariance and a heritability confidence
  interval (`variance_component_covariance`, `heritability_standard_error`,
  `heritability_interval`; logit-transform delta interval) build on the REML
  AI matrix; asymptotic, REML-only, not coverage-calibrated.
- Experimental genomic relationship engine (Phase 2): VanRaden `G`
  (`genomic_relationship_matrix`), regularized inverse
  (`genomic_relationship_inverse`), GBLUP (`fit_gblup`), SNP-BLUP with
  marker-effect output and the GBLUP/SNP-BLUP equivalence
  (`fit_snp_blup`, `centered_markers`), single-step `H`-inverse construction,
  GBLUP REML variance-component estimation, and fixed-effect single-marker
  screening (`single_marker_scan`) exist as experimental supplied-variance /
  validation-scale engine utilities. No production genomic fitting, mixed-model
  marker scan, or QTL/eQTL scan; not the public default.
- Experimental standard quantitative-genetic models (Phase 3): repeatability /
  permanent-environment (`repeatability_mme`, `fit_repeatability_reml`) and a
  general two-random-effect model for common-environment / maternal-genetic
  effects (`two_effect_mme`, `fit_two_effect_reml`) exist as experimental
  dense/validation-scale engine utilities at supplied or REML-estimated
  variance components. No R-facing model-spec; not the public default.
- Experimental multivariate Gaussian animal-model utilities (Phase 4): supplied
  covariance `multivariate_mme`, missing-trait handling, and dense
  `fit_multivariate_reml` estimation of `G0`/`R0` exist as engine-internal,
  validation-scale utilities. The multivariate REML path now has an opt-in
  seeded recovery harness outside CI and a serialized two-trait Julia target
  fixture plus comparator protocol for R-lane comparator work. Julia-side
  extractors (`variance_components`, `fixed_effects`, `heritability`, and
  `breeding_values`/`EBV`/`BLUP`) wrap existing multivariate result fields
  without changing `result_payload()` or the R bridge. Phase 4B now has
  structured genetic
  covariance builders and REML constraints for diagonal, low-rank, and
  factor-analytic `G0`, copy-returning structured-metadata accessors, plus its
  own opt-in seeded recovery harness. No R-facing multivariate model-spec, no
  external comparator parity, no full loading rotation/interpretation
  convention, and no production sparse multivariate fitting.
- Sparse CSC marshalling helper exists for R `Matrix::dgCMatrix` slots.
- R twin has an opt-in experimental tiny/local Julia engine path at `hsquared`
  head `9eabf0d`; R heads `8235289` and `d7e8914` enrich tiny validation
  bridge paths with PEV/reliability from exported Julia extractors when
  available while Julia keeps the compact base `result_payload()` unchanged.
- R head `afa25f1` adds R-side EBV/BLUP/accuracy extractor ergonomics. Julia
  mirrors `EBV()`, `BLUP()`, and checked `accuracy()` locally without changing
  the bridge payload.
- R head `00b9e33` adds an explicit opt-in supplied-variance
  `target = "henderson_mme"` bridge path. It returns supplied-variance MME
  outputs but deliberately omits log-likelihood, AIC, `df`, optimizer output,
  variance-component estimation, AI-REML, and fitted Mrode claims.
- R head `398e019` records sparse `Z` bridge marshalling through Julia
  `sparse_csc_matrix()`.
- R head `bacef9c` adds exported `model_spec()` as a preview of the same v0.1
  formula-to-bridge payload without fitting or Julia execution.
- R head `2c18b30` records the expanded genomics/QTL/GLLVM/GPU/HPC plan; Julia
  mirrors it as roadmap and algorithm/backend documentation only.
- Production high-level formula fitting and production R bridge execution are
  not implemented.
- Backend execution dispatch, runtime backend availability probing, GPU
  execution, backend benchmarking, and CPU/GPU numerical agreement tests are
  not implemented.
- APY approximation, Woodbury-backed factor/GLLVM engines, and HPC
  checkpointing are not implemented. AI-REML and the Takahashi selected inverse
  exist only as the experimental, validation-scale utilities above, not as
  production-scale, sparse, large-pedigree fitting.
- Mixed-model marker scans and QTL/eQTL scans are not implemented. Genomic
  prediction, single-step `H`-inverse, marker-effect estimation, and a
  fixed-effect single-marker scan exist only as the experimental engine
  utilities above, not as production genomic fitting.
- Paternal effects, cytoplasmic inheritance, imprinting, dominance, epistasis,
  sire models, random regression, unknown-parent groups, and custom
  relationship/precision kernels are not implemented. Permanent environment,
  common environment, and maternal-genetic effects exist only as the
  experimental engine utilities above, not as a public model-spec.
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
- experimental sparse REML validation optimization; initial low-level REML-only
  path covered on tiny fixtures;
- experimental dense variance-component optimization; initial low-level path
  covered for validated specs;
- experimental MME-backed EBV/BLUP aliases and fitted-value extractors, plus
  heritability, PEV, reliability, and checked accuracy extractors;
- experimental direct payload fitting target for the R parser's intended
  `y`, `X`, `Z`, `Ainv` handoff, including the supplied-variance
  `target = :henderson_mme` convenience path;
- sparse Henderson MME solve at supplied variance components, with a shared
  R/Julia supplied-variance fixture for fixed effects, EBVs, fitted values,
  and `h2`;
- Mrode9-shaped supplied-variance validation for dense/sparse likelihood
  identity, Henderson MME outputs, PEV, reliability, derived accuracy, and
  `h2`;
- production sparse optimizer and AI-REML;
- production sparse EBVs/BLUPs, reliability, prediction error variance, and
  heritability.
- in-memory phenotype/pedigree/genotype/expression ID container plus
  `data_status()` diagnostics for ID overlap, pedigree status, genotype
  status, marker status, expression status, annotation-feature status, and
  environment-key status; initial mirror covered.
- file-backed phenotype/genotype storage; planned.
- genotype parsing, marker imputation, marker scanning, and genomic
  relationship construction from `HSData`; planned.

Gate: Mrode simple animal-model example plus tiny hand-checked pedigrees and
comparator checks where available.

## Phase 2: Genomic Relationship Models

Add `G` and `Ginv`, GBLUP, SNP-BLUP, supplied `Hinv`, genotype ID matching,
and first marker-effect outputs.

Status: the engine utilities have landed (experimental, validation-scale) —
`genomic_relationship_matrix`, `genomic_relationship_inverse`, `fit_gblup`,
`fit_snp_blup`/`centered_markers`, single-step `H`-inverse construction, and
GBLUP REML. The first Phase-5 marker utility,
`single_marker_scan`, also exists as a fixed-effect Gaussian screening helper
with supplied residual variance. These are engine-internal; production
genotype-ID matching at scale, mixed-model marker scans, QTL/eQTL scans, a
public genomic model-spec, and external comparator parity remain open.

Gate: Jason scout plus Rose license/claim audit, with JWAS/sommer/BLUPF90
style comparator checks before public fitting claims.

## Phase 3: Standard Quantitative-Genetic And Inheritance Models

Add repeatability, permanent environment, maternal effects, common environment,
sire models, dominance, cytoplasmic inheritance, selfing, clonal/asexual,
haplodiploid, polyploid, unknown parent groups, inbreeding, and the first
random-regression slice.

Status: the first engine utilities have landed (experimental, validation-scale)
— repeatability / permanent-environment (`repeatability_mme`,
`fit_repeatability_reml`) and a general two-random-effect model covering
common-environment and maternal-genetic effects (`two_effect_mme`,
`fit_two_effect_reml`). Sire models, dominance, cytoplasmic inheritance,
non-standard inheritance systems, unknown-parent groups, and random regression
remain open, as does any public model-spec.

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

Status: initial engine utilities have landed (experimental, dense /
validation-scale). `diagonal_covariance`, `lowrank_covariance`, and
`factor_analytic_covariance` build the structured trait covariance matrices, and
`fit_multivariate_reml(...; genetic_structure = :diagonal | :lowrank |
:factor_analytic, rank = K)` estimates constrained genetic covariance structures
while leaving residual `R0` unstructured. Deterministic tests cover constructor
identities, metadata, loglik self-consistency, PSD/PD properties, and constrained
loglik ordering. The opt-in script
`sim/phase4b_structured_covariance_recovery.jl` records seeded low-rank and
factor-analytic known-truth recovery outside CI and now accepts explicit
`--seeds` lists with per-case summaries. The shared calibration protocol in
`docs/dev-log/decisions/2026-06-14-multivariate-recovery-calibration-protocol.md`
defines the seed-count, run-plan, and reporting gate required before any broad
multi-seed calibration claim. The protocol was executed on the predeclared
10-seed structured sets and did not pass: factor-analytic passed 8/10 and
low-rank passed 9/10, with all fits converged. Rotation conventions, covariance
inference, external comparators, and R syntax remain open.

The returned loading metadata now has a deterministic sign convention: each
factor column is flipped, if needed, so its largest-absolute loading is
non-negative. This does not solve rotation non-identifiability for `rank > 1`,
and loadings remain uninterpreted engine metadata until extractor meanings and
external parity are validated. The current sign-only policy is recorded in
`docs/dev-log/decisions/2026-06-14-loading-rotation-identifiability.md`;
full rotation and biological interpretation remain future work.

`test/fixtures/phase4_multitrait_parity/` serializes a deterministic two-trait
Julia REML target for R-lane sommer/ASReml/BLUPF90 parity work. It is an input
and target bundle, not external comparator evidence.

`sim/phase4_multivariate_reml_recovery.jl` records opt-in seeded unstructured
two-trait REML recovery outside CI. It accepts `--seed` for the historical
single-seed run or explicit `--seeds` lists with summaries. The default seed
`20260616` passes with relative errors `G = 0.174500` and `R = 0.131056`
against thresholds `0.25` and `0.20`. This is internal recovery evidence only;
the shared calibration protocol was later executed on a predeclared 10-seed
unstructured set and did not pass (6/10 passed, all fits converged). It is not
broad multi-seed calibration, external comparator parity, or an R bridge change.
The calibration failure response decision note requires any future rerun,
threshold revision, or narrower claim to be declared before execution. The
deterministic failure-mode triage records that the unstructured failures were
mostly G-threshold failures, factor-analytic had both G-only and G+R failures,
and low-rank had one R-only failure.

Gate: Kirkpatrick and Noether sign off on notation, syntax, parameterization,
and extractor meanings.

## Phase 5: QTL, GWAS, And eQTL

Add single-marker scans, mixed-model marker scans, LOCO, LOD output,
calibrated mixed-model p-values, cis/trans eQTL, multiple testing, and basic
plots.

Status: `single_marker_scan` provides the first direct Julia engine utility for
fixed-effect single-marker screening. It residualizes `y` and centered marker
dosages against `X` and reports effects, supplied-variance standard errors,
Wald z-scores, chi-square statistics, and approximate two-sided Gaussian/Wald
p-values with Bonferroni and Benjamini-Hochberg adjustments over the returned
marker set, fixed-effect known-variance LOD-equivalent scores, and plot-ready
Manhattan data. It is not a mixed-model GWAS/QTL scan, does not account for
relatedness/population structure, does not compute interval-mapping or
mixed-model LOD workflows or calibrated / correlated-marker multiple-testing
workflows, does not draw plots, and does not activate the R-facing
`marker_scan()` formula term.

Gate: marker-map validation, estimand definition, genome-wide multiple-testing
calibration, and comparator/simulation evidence.

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

1. Decide with the R twin whether PEV/reliability should ever become required
   base `result_payload()` fields; keep current enrichment optional and
   tiny/local.
2. Add live Julia `HSData` object marshalling tests once the bridge contract
   deliberately sends data-container objects rather than the current low-level
   payload.
3. Add fitted Mrode output validation with source-recorded response data,
   estimator target, expected variance components, EBVs, `h2`, comparator
   versions, and tolerances.
4. Replace dense covariance equations with sparse production computations.
5. Add AI-REML or a documented sparse optimizer path.
6. Keep `hsquared` issue #2 synchronized with this engine contract.

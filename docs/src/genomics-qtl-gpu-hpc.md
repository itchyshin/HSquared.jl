# Genomics, QTL, GPU, And HPC Roadmap

This page records the long-range technical plan for `hsquared` and
`HSquared.jl`.

Status: roadmap plus experimental Julia engine utilities. The implemented
Julia capability now includes pedigree/Ainv utilities, validation-scale animal
models, genomic relationship / GBLUP / SNP-BLUP utilities, and a fixed-effect
single-marker screening helper. Public R-facing genomic/QTL/eQTL syntax,
mixed-model marker scans, GLLVM-style models, and GPU acceleration remain
planned unless a capability table says otherwise.

See [Backend And Algorithm Roadmap](backend-algorithm-roadmap.md) for the
Julia-side execution plan behind CPU, threaded CPU, CUDA, AMDGPU, Metal,
oneAPI, AI-REML, Takahashi selected inversion, Woodbury paths, APY, and backend
claim gates.

The formula names `genomic()`, `single_step()`, `markers()`, `marker_scan()`,
and `qtl_scan()` are now reserved in both twins. In Julia they currently throw
planned-not-implemented errors. They do not fit genomic models or run QTL/eQTL
scans. Direct Julia utilities such as `fit_snp_blup()` and
`single_marker_scan()` are engine-internal and do not activate those formula
terms.

Related Phase 2+ names such as `permanent()`, `common_env()`,
`maternal_genetic()`, `paternal_genetic()`, `dominance()`, `epistasis()`,
`relmat()`, and `HSquared.precision()` are also reserved as planned vocabulary.
They do not fit standard quantitative-genetic extensions or custom kernels yet.

## 1. Executive Summary

`hsquared` and `HSquared.jl` should become a coherent, open, Julia-powered
modelling system for quantitative genetics.

The goal is not to bundle unrelated genetics tools. The goal is one modelling
language where phenotypes, pedigrees, genotypes, markers, QTL/eQTL, G matrices,
maternal/paternal effects, unusual inheritance systems, and high-dimensional
latent structure are all expressed as structured mixed-model components.

Architecture:

- `hsquared`: R user interface, formula grammar, validation, docs, S3 methods,
  plotting, extractors, and R-to-Julia bridge.
- `HSquared.jl`: Julia engine, relationship/precision construction, solvers,
  likelihoods, EBVs/BLUPs, G matrices, genomics/QTL kernels, GLLVM-style
  latent models, and CPU/GPU backends.

Strategic niche:

- ASReml-style animal and genomic models;
- open-source and community-oriented;
- R-friendly syntax;
- Julia engine headroom;
- sparse precision computation;
- pedigree, genomic, QTL/eQTL, omics, G-matrix, GLLVM, and inheritance-system
  integration;
- explicit CPU/GPU/HPC benchmarking.

## 2. Scientific Motivation

The target users are livestock breeders, plant breeders, evolutionary
geneticists, quantitative geneticists, genomic prediction users, and applied
analysts working with real phenotype-genotype-pedigree data.

They need to answer simple questions:

- What is heritability?
- What are the EBVs?
- What are the variance components?
- What is the G matrix?
- What are the genetic correlations?
- Which markers, QTL, or eQTL matter?
- Do CPU and GPU runs agree?
- Is the model weakly identified, or did the software fail?

Existing tools each cover important parts of this space:

- ASReml-R: mature proprietary REML animal-model workflows.
- BLUPF90, DMU, WOMBAT: production animal-breeding software.
- MCMCglmm: flexible Bayesian animal models.
- sommer: open R mixed models with relationship structures.
- JWAS.jl: Bayesian genomic prediction and GWAS in Julia.
- GCTA, GEMMA, BGLR: specialized genomic association/prediction tools.
- XSim.jl: simulation of genomes, pedigrees, and breeding programs.
- GLLVM.jl / gllvmTMB: high-dimensional latent-variable and response-matrix
  modelling.
- drmTMB / DRM.jl: R-Julia twin discipline, formula grammar, and Julia engine
  design.

`hsquared` should differ by integrating these ideas into one structured
quantitative-genetic modelling language. Superiority claims must wait for
benchmarks.

## 3. Software Architecture

`hsquared` owns:

- R formulas and user-facing syntax;
- friendly errors;
- validation before Julia calls;
- S3 fit objects and extractors;
- plotting;
- vignettes/pkgdown;
- bridge calls through Julia.

`HSquared.jl` owns:

- canonical model specification objects;
- ID recoding and data alignment kernels;
- sparse pedigree and relationship precision matrices;
- REML/ML/AI-REML and later Laplace/variational engines;
- marker/genomic computations;
- G matrices and factor-analytic covariance;
- GLLVM-style latent-factor response models;
- backend dispatch and benchmarking.

Julia should cover everything R exposes with equivalent semantics. Julia may
also carry experimental features earlier than R. Those features must be marked
experimental and must not be presented as stable R syntax until the bridge and
docs catch up.

## 4. Core Formula Grammar

Basic animal model:

```r
fit <- hsquared(
  y ~ sex + age + animal(1 | id, pedigree = ped),
  data = pheno,
  family = gaussian(),
  REML = TRUE
)
```

Repeated records:

```r
fit <- hsquared(
  y ~ sex + age +
    animal(1 | id, pedigree = ped) +
    permanent(1 | id),
  data = pheno,
  family = gaussian()
)
```

Maternal, paternal, and common-environment model:

```r
fit <- hsquared(
  y ~ sex + age +
    animal(1 | id, pedigree = ped) +
    maternal_genetic(1 | dam, pedigree = ped) +
    maternal_env(1 | dam) +
    paternal_genetic(1 | sire, pedigree = ped) +
    paternal_env(1 | sire) +
    common_env(1 | family),
  data = pheno,
  family = gaussian()
)
```

Candidate marker names:

- `animal()` for direct additive genetic animal effect.
- `permanent()` for permanent environmental effect.
- `common_env()` for litter, family, cage, block, or plot effects.
- `maternal_genetic()` for genetic effects of dams.
- `maternal_env()` for maternal identity or care effects.
- `paternal_genetic()` for sire genetic effects.
- `paternal_env()` for paternal care or paternal identity effects.
- `cytoplasmic()` for maternal-line cytoplasmic inheritance.
- `imprinting()` for parent-of-origin effects.
- `sex_linked()` for sex-linked inheritance structures.

Julia direct syntax should stay close where possible:

```julia
fit = hsquared(
    @formula(y ~ sex + age + animal(1 | id, pedigree = ped));
    data = pheno,
    family = Gaussian(),
    REML = true,
)
```

Allowed Julia discrepancies are language-level differences such as `true`
versus `TRUE` and Julia type names. Different model meanings for the same token
are not allowed.

## 5. Data Model

R-side proposal:

```r
dat <- hs_data(
  phenotypes  = pheno,
  pedigree    = ped,
  genotypes   = geno,
  markers     = marker_map,
  expression  = expr,
  annotation  = annot,
  environment = env
)
```

Julia-side proposal:

```julia
dat = HSData(;
    phenotypes = pheno,
    pedigree = ped,
    genotypes = geno,
    markers = marker_map,
    expression = expr,
    annotation = annot,
    environment = env,
)
```

Core alignment tasks:

- integer ID encoding;
- phenotype-to-pedigree matching;
- phenotype-to-genotype matching;
- marker-to-map matching;
- expression trait-to-gene/transcript matching;
- repeated record indexing;
- long and wide trait representations;
- multi-environment indexing;
- ungenotyped individuals with pedigree;
- genotyped individuals without phenotype;
- phenotyped individuals without genotype.

File formats:

- CSV/TSV for examples;
- Arrow/Parquet for large phenotypes and covariates;
- PLINK BED/BIM/FAM for SNP genotypes;
- VCF/BCF for variant input;
- dosage matrices for imputed genotypes;
- sparse marker matrices;
- HDF5/Zarr-style stores for omics and huge marker panels;
- memory-mapped and chunked arrays for streaming computations.

The first implementation should support simple in-memory tables. The data
abstraction should not block later on-disk or streaming backends.

## 6. Animal-Model And Inheritance Modules

Relationship structures:

- `A`: additive numerator relationship matrix;
- `Ainv`: sparse inverse additive relationship matrix;
- `G`: genomic relationship matrix;
- `Ginv`: inverse genomic relationship matrix;
- `H` / `Hinv`: single-step relationship and precision;
- `D` / `Dinv`: dominance relationship and precision;
- `E`: epistatic relationship;
- `M`: maternal or cytoplasmic relationship;
- `P`: paternal or sex-linked relationship;
- `K`: user-supplied kernel;
- `Q`: user-supplied precision.

Syntax:

```r
animal(1 | id, pedigree = ped)
animal(1 | id, Ainv = Ainv)
genomic(1 | id, G = G)
genomic(1 | id, Ginv = Ginv)
single_step(1 | id, Hinv = Hinv)
dominance(1 | id, pedigree = ped)
epistasis(1 | id, pedigree = ped)
relmat(1 | id, K = K)
precision(1 | id, Q = Q)
```

In direct Julia code the planned precision marker is qualified as
`HSquared.precision()` because `Base.precision` already exists. The public R
formula grammar remains `precision(1 | id, Q = Q)`.

Generic engine abstraction:

```text
random effect = Z
relationship = K
precision = Q
trait covariance = G0
covariance contribution = K kron G0
precision contribution = Q kron inv(G0)
```

Inheritance systems:

```r
animal(1 | id, pedigree = ped, inheritance = diploid())
animal(1 | id, pedigree = ped, inheritance = selfing(rate = s))
animal(1 | id, pedigree = ped, inheritance = clonal())
animal(1 | id, pedigree = ped, inheritance = haplodiploid())
animal(1 | id, pedigree = ped, inheritance = polyploid(ploidy = 4))
cytoplasmic(1 | maternal_line)
```

Phase rule: unusual inheritance can be experimental in Julia first, but R docs
must not promote it until relationship construction and biological
interpretation are validated.

## 7. Genomic Prediction Modules

Initial scope:

- `G` and `Ginv` input;
- GBLUP;
- SNP-BLUP;
- single-step HBLUP with supplied `Hinv`;
- marker-effect extraction;
- genomic relationship construction;
- genotype ID matching;
- scaling/blending of `G` and `A`;
- APY approximation later.

Example:

```r
fit <- hsquared(
  y ~ sex + batch + genomic(1 | id, Ginv = Ginv),
  data = pheno,
  family = gaussian()
)
```

Marker-effect model:

```r
fit <- hsquared(
  y ~ sex + batch + markers(M, model = "random"),
  data = pheno,
  genotypes = geno,
  family = gaussian()
)
```

Mathematical links:

- GBLUP: breeding values `u ~ N(0, G sigma_g^2)`.
- SNP-BLUP: marker effects `alpha ~ N(0, I sigma_alpha^2)` and breeding values
  `u = M alpha`.
- Single-step HBLUP: pedigree and genomic information combine through `H` or
  `Hinv`.
- Bayesian marker models can remain future work or interoperate with JWAS.jl.

## 8. QTL, GWAS, And eQTL Modules

Levels:

1. single-marker scan;
2. multi-marker penalized or random-effect model;
3. joint marker scan with pedigree/genomic random effects.

Current Julia status: `single_marker_scan(y, X, markers; sigma_e2 = 1.0)` is a
fixed-effect Gaussian screening helper. It centers biallelic dosages,
residualizes `y` and each marker against `X`, and reports marker effects,
supplied-variance standard errors, Wald z-scores, chi-square statistics, and
approximate two-sided Gaussian/Wald p-values plus Bonferroni and
Benjamini-Hochberg adjustments over the returned marker set, and
LOD-equivalent scores `chisq / (2log(10))`. `marker_manhattan_data()` can use
already-validated `HSData` / `HSMarkerMapSpec` marker metadata to align
chromosomes and positions by exact marker ID. `marker_effects()`
prepares sorted top-marker effect summaries from the same scan fields, with
optional chromosome/position alignment. `marker_qq_data()` prepares sorted
observed/expected QQ plot data from the same direct scan result.
`mixed_model_marker_scan(y, X, Z, Ainv, markers, sigma_a2, sigma_e2)` is a
dense supplied-variance GLS helper that accounts for a supplied relationship
covariance through `V = sigma_a2 * Z * A * Z' + sigma_e2 * I`.
`loco_relationship_precisions()` constructs dense VanRaden-plus-ridge
leave-one-group-out relationship precisions from marker groups, and
`loco_mixed_model_marker_scan()` selects a precision by marker group before
running the same dense GLS scan. These helpers do not compute interval-mapping
or mixed-model LOD workflows or calibrated/correlated-marker multiple-testing
workflows, estimate marker-scan variance components, choose public LOCO
defaults, parse marker files, draw figures, or activate the R-facing
`marker_scan()` formula term. `marker_genomic_inflation()` provides a
diagnostic lambda summary over returned chi-square statistics; it does not
calibrate p-values or correct scan statistics.

```julia
y = [1.0, 2.0, 4.0, 2.0, 3.0]
X = ones(5, 1)
M = [0.0 0.0; 1.0 0.0; 2.0 1.0; 0.0 2.0; 1.0 2.0]
scan = single_marker_scan(y, X, M; marker_ids = ["m1", "m2"])
scan.p_values
scan.bh_q_values
scan.lod_scores
Z = zeros(5, 1)
mixed_scan = mixed_model_marker_scan(y, X, Z, Matrix(1.0I, 1, 1), M, 2.0, 1.0)
mixed_scan.p_values
loco_precisions = loco_relationship_precisions(M, ["1", "2"]; ridge = 0.01)
loco_scan = loco_mixed_model_marker_scan(
    y,
    X,
    Matrix{Float64}(I, 5, 5),
    loco_precisions,
    ["1", "2"],
    M,
    2.0,
    1.0,
)
manhattan = marker_manhattan_data(scan)
qq = marker_qq_data(scan)
inflation = marker_genomic_inflation(scan)
effects = marker_effects(scan; sort_by = :p_value, top_n = 2)
marker_data = HSData((id = ["example"], y = [0.0]); markers = (
    marker = ["m1", "m2"],
    chr = ["1", "2"],
    pos = [10, 20],
))
map_manhattan = marker_manhattan_data(scan, marker_data)
map_effects = marker_effects(scan, marker_data; top_n = 2)
manhattan.neglog10_p_values
qq.expected_neglog10_p_values
```

QTL/GWAS syntax:

```r
fit <- hsquared(
  y ~ sex + age +
    animal(1 | id, pedigree = ped) +
    marker_scan(M, map = marker_map),
  data = pheno,
  genotypes = geno,
  family = gaussian()
)
qtl <- qtl_table(fit)
plot_manhattan(qtl)
plot_qq(qtl)
```

Mixed-model GWAS:

```r
fit <- hsquared(
  y ~ sex + age +
    genomic(1 | id, Ginv = Ginv) +
    marker_scan(M, map = marker_map, leave_one_chr_out = TRUE),
  data = pheno,
  genotypes = geno,
  family = gaussian()
)
```

eQTL:

```r
fit <- hsquared(
  expression ~ genotype_marker +
    covariates(batch, sex, age) +
    genomic(1 | id, Ginv = Ginv),
  data = expr_long,
  genotypes = geno,
  family = gaussian()
)
eqtl <- eqtl_table(fit)
```

High-dimensional eQTL:

```r
fit <- hsquared(
  expr_matrix ~ batch + sex +
    marker_scan(M, map = marker_map) +
    sample_factors(K = 5) +
    genomic(1 | id, Ginv = Ginv),
  data = expr_data,
  genotypes = geno,
  family = gaussian()
)
```

Core package versus extension:

- Core `hsquared`: model grammar, kinship correction, small/medium marker scans,
  basic QTL/GWAS/eQTL output tables.
- Optional `hsquaredQTL` / `HSquaredQTL.jl`: huge scans, fine mapping,
  streaming marker IO, advanced multiple-testing workflows, and specialized
  plots.

## 9. Multivariate G-Matrix And Factor-Analytic Modules

Long-format multivariate model:

```r
fit <- hsquared(
  y ~ trait + trait:sex + trait:age +
    animal(trait | id, pedigree = ped, cov = us()) +
    residual(trait | unit, cov = us()),
  data = long_dat,
  family = gaussian()
)
G <- G_matrix(fit, effect = "animal")
```

Factor-analytic model:

```r
fit <- hsquared(
  y ~ trait + trait:sex + trait:age +
    animal(trait | id, pedigree = ped, cov = fa(K = 2)) +
    residual(trait | unit, cov = fa(K = 1)),
  data = long_dat,
  family = gaussian()
)
```

Definitions:

```text
us()        = full unstructured covariance
diag()      = trait-specific variances only
lowrank(K)  = Lambda Lambda'
fa(K)       = Lambda Lambda' + Psi
```

Outputs:

- `G_matrix()`;
- `R_matrix()`;
- `P_matrix()`;
- `genetic_correlations()`;
- `loadings()`;
- `specific_variance()`;
- `latent_breeding_values()`;
- `eigen_G()`;
- `evolvability()`.

## 10. GLLVM Integration Strategy

GLLVM-style extension:

```r
fit <- hsquared(
  Y ~ treatment + environment +
    animal_fa(K = 3, id = id, pedigree = ped, psi = TRUE) +
    site_fa(K = 2) +
    batch(1 | batch_id),
  data = community_or_omics_data,
  family = negative_binomial()
)
G <- G_matrix(fit, effect = "animal")
ordination(fit)
```

Borrowed computational ideas from the GLLVM family:

- low-rank latent factors;
- Woodbury identities for `Lambda Lambda' + diagonal` structures;
- Gaussian closed-form marginalization where available;
- Laplace approximation for non-Gaussian random effects;
- variational approximation as an optional experimental path;
- fixed effects and trait-specific covariates;
- fourth-corner trait-environment interactions;
- phylogenetic and spatial random effects;
- ordination outputs;
- missing response matrices.

Biological interpretation:

`hsquared` should estimate G matrices not only as covariance matrices, but as
latent biological axes: genetic architecture, evolvability, tradeoffs,
constraint, and high-dimensional phenotype structure.

## 11. CPU/GPU Backend Architecture

Backend types:

```julia
CPUBackend()
ThreadsBackend()
CUDABackend()
AMDGPUBackend()
MetalBackend()
OneAPIBackend()
AutoBackend()
```

R control:

```r
hs_control(backend = "cpu")
hs_control(backend = "auto", accelerator = "gpu")
hs_control(backend = "metal")
hs_control(backend = "cuda", threads = 32)
```

Julia control:

```julia
fit_cpu = hsquared(model, data; backend = CPUBackend())
fit_gpu = hsquared(model, data; backend = AutoBackend(), accelerator = :gpu)
compare_backends(fit_cpu, fit_gpu)
```

Dependency rule:

- CPU backend is always available and reliable.
- GPU packages are optional extensions.
- Loading `CUDA.jl`, `AMDGPU.jl`, `Metal.jl`, or `oneAPI.jl` can activate the
  corresponding extension.

Possible extension layout:

- `ext/HSquaredCUDAExt.jl`
- `ext/HSquaredAMDGPUExt.jl`
- `ext/HSquaredMetalExt.jl`
- `ext/HSquaredOneAPIExt.jl`

## 12. Cross-Platform GPU Strategy

Candidate Julia GPU ecosystem:

- CUDA.jl for NVIDIA GPUs and `CuArray`;
- AMDGPU.jl for AMD/ROCm and `ROCArray`;
- Metal.jl for Apple/macOS GPUs and `MtlArray`;
- oneAPI.jl for Intel accelerators and `oneArray`;
- KernelAbstractions.jl for vendor-neutral kernels over CUDA, ROCm, oneAPI,
  and Metal-style backends.

Maturity strategy:

- CPU first for correctness.
- CUDA first for production HPC.
- Metal early for local Mac development checks.
- AMDGPU for ROCm-based supercomputers.
- oneAPI as a careful experimental lane.
- KernelAbstractions where a custom kernel can stay backend-generic.

Generic Julia code should avoid hard-coding `Array`. Prefer array-interface
programming and dispatch over:

- `Array`;
- `SubArray`;
- `SparseMatrixCSC`;
- `CuArray`;
- `ROCArray`;
- `MtlArray`;
- `oneArray`.

Precision policy:

- `Float64` default for REML and publication-quality variance components.
- `Float32` optional for exploratory huge GLLVM/genomic scans.
- Mixed precision later, only after CPU/GPU agreement tests exist.

Risk controls:

- explicit numerical tolerances by backend and precision;
- reproducibility notes for GPU nondeterminism;
- seed management;
- device memory checks;
- host-device transfer accounting;
- chunking and streaming for huge marker panels;
- no automatic GPU superiority claim.

## 13. Benchmarking And CPU/GPU Comparison

User-level API:

```r
bench <- benchmark_backend(
  y ~ trait + trait:sex +
    animal(trait | id, pedigree = ped, cov = fa(K = 2)),
  data = long_dat,
  family = gaussian(),
  backends = c("cpu", "metal", "cuda"),
  metrics = c("time", "memory", "logLik", "parameters", "gradient")
)
print(bench)
plot(bench)
```

Fit comparison:

```r
compare_backends(fit_cpu, fit_gpu)
```

Metrics:

- wall-clock time;
- memory and device memory;
- iterations;
- log-likelihood difference;
- fixed-effect differences;
- variance-component differences;
- EBV differences;
- heritability differences;
- G-matrix differences;
- gradient and convergence diagnostics.

Testing matrix:

- local Mac CPU;
- local Mac GPU / Metal;
- Linux CPU;
- Linux NVIDIA / CUDA;
- Linux AMD / ROCm;
- Linux Intel / oneAPI;
- HPC cluster batch jobs.

CI strategy:

- ordinary CPU tests on GitHub Actions;
- docs build on GitHub Actions;
- optional small GPU tests where runners exist;
- nightly or manual benchmark workflow;
- HPC benchmark scripts outside ordinary CI;
- gold-standard numerical fixtures for CPU/GPU agreement.

## 14. HPC Cluster Workflow

HPC support should include:

- SLURM scripts;
- Julia project setup;
- precompilation;
- thread control;
- GPU selection;
- memory logging;
- checkpointing;
- restartable fits;
- batch benchmarking;
- distributed simulation;
- multi-node support later.

R workflow:

```r
fit <- hsquared(
  y ~ sex + batch + genomic(1 | id, Ginv = Ginv),
  data = "phenotypes.parquet",
  family = gaussian(),
  control = hs_control(
    backend = "cuda",
    threads = 32,
    checkpoint = "fit_checkpoint/",
    save = "minimal"
  )
)
```

Julia workflow:

```julia
fit = hsquared(
    model,
    data;
    backend = CUDABackend(),
    checkpoint = "checkpoints/run1",
    save = :minimal,
)
```

Script lanes:

- CPU animal-model benchmark;
- GPU genomic matrix benchmark;
- multi-trait G-matrix benchmark;
- GLLVM benchmark;
- genomic prediction benchmark;
- QTL/eQTL scan benchmark;
- ASReml/sommer/JWAS/GLLVM comparator benchmark.

## 15. Validation

Validation hierarchy:

1. tiny deterministic hand checks;
2. Mrode textbook examples;
3. XSim.jl simulation truth;
4. comparator package checks;
5. CPU/GPU agreement checks;
6. large-scale benchmark reporting.

Comparator targets:

- ASReml for REML animal-model outputs where available;
- BLUPF90/DMU/WOMBAT for production animal-breeding examples;
- sommer for open R relationship-structure checks;
- MCMCglmm for Bayesian animal-model contrasts;
- JWAS for Bayesian genomic models;
- AGHmatrix and nadiv for relationship-matrix construction;
- GLLVM.jl and gllvmTMB for high-dimensional latent models;
- XSim.jl for simulated breeding/genomics scenarios.

No failed recovery should be called an engine bug until the DGP, estimand, and
comparator target are aligned.

## 16. Outputs And Extractors

Animal/genomic:

- `variance_components(fit)`;
- `heritability(fit)`;
- `breeding_values(fit)`;
- `EBV(fit)`;
- `BLUP(fit)`;
- `reliability(fit)`;
- `accuracy(fit)`;
- `prediction_error_variance(fit)`;
- `genetic_correlations(fit)`;
- `G_matrix(fit)`;
- `R_matrix(fit)`;
- `P_matrix(fit)`.

Genomics/QTL:

- `marker_effects(fit)`;
- `marker_variance_explained(fit)`;
- `qtl_table(fit)`;
- `eqtl_table(fit)`;
- `gwas_table(fit)`;
- `lod_scores(fit)`;
- `manhattan_plot(fit)`;
- `qq_plot(fit)`;
- `regional_plot(fit)`;
- `fine_map(fit)`.

GLLVM/multivariate:

- `loadings(fit, effect = "animal")`;
- `specific_variance(fit, effect = "animal")`;
- `latent_breeding_values(fit)`;
- `ordination(fit)`;
- `trait_scores(fit)`;
- `individual_scores(fit)`;
- `species_scores(fit)`;
- `eigen_G(fit)`;
- `evolvability(fit)`;
- `conditional_G(fit)`.

Computation:

- `backend(fit)`;
- `device_info(fit)`;
- `benchmark(fit)`;
- `memory_profile(fit)`;
- `compare_backends(fit_cpu, fit_gpu)`.

## 17. Documentation And Vignettes

R pkgdown:

- getting started;
- simple animal model;
- pedigree input rules;
- genomic relationship models;
- maternal/paternal effects;
- multivariate G matrices;
- QTL/GWAS/eQTL;
- backend comparison;
- fitted/planned/missing status.

Julia Documenter:

- engine utility docs;
- model-spec internals;
- backend architecture;
- performance and benchmark notes;
- bridge contract;
- experimental Julia-only features;
- API reference.

Both docs sites must keep claims synchronized.

## 18. Development Roadmap

Phase 0: architecture and public scaffold.

Phase 1: univariate Gaussian animal model.

- pedigree validation;
- sparse `Ainv`;
- fixed and random-effect design;
- REML/ML;
- EBVs/BLUPs;
- heritability;
- Mrode validation.

Phase 2: genomic relationship models.

- `G` and `Ginv`;
- GBLUP;
- SNP-BLUP;
- supplied `Hinv`;
- genotype ID matching.

Phase 3: maternal/paternal and inheritance models.

- maternal genetic/environmental;
- paternal/sire;
- common environment;
- permanent environment;
- dominance;
- cytoplasmic;
- selfing;
- clonal/asexual;
- haplodiploid;
- polyploid.

Phase 4: multivariate G matrices.

- long-format multivariate model;
- `us()`, `diag()`, `lowrank(K)`, `fa(K)`;
- genetic correlations;
- latent breeding values.

Phase 5: QTL/GWAS/eQTL.

- single-marker scans;
- mixed-model marker scans;
- LOCO;
- interval-mapping / mixed-model LOD output and calibrated mixed-model p-value
  workflows;
- cis/trans eQTL;
- multiple testing;
- plots.

Phase 6: GLLVM integration.

- wide response matrices;
- non-Gaussian families;
- latent genetic factors;
- sample/environment factors;
- ordination;
- omics and community examples.

Phase 7: GPU acceleration.

- CPU backend baseline;
- Metal test lane;
- CUDA production lane;
- AMDGPU and oneAPI experimental lanes;
- vendor-neutral kernels;
- backend comparison tools.

Phase 8: HPC and production scaling.

- checkpointing;
- disk-backed data;
- streaming marker scans;
- distributed simulation;
- multi-GPU experiments;
- national-computer benchmarks.

## 19. Risks And Tradeoffs

- Scope creep: keep one coherent mixed-model language, not a loose toolbox.
- Syntax drift: R syntax parity is the public contract; Julia experiments must
  be labelled.
- GPU overpromise: many sparse pedigree tasks are CPU-first.
- Dense memory traps: never silently densify huge relationship matrices.
- Comparator mismatch: compare the same estimand before claiming disagreement.
- Numerical tolerance: CPU/GPU and Float32/Float64 need explicit tolerances.
- Optional dependencies: GPU packages must not become ordinary install
  requirements.
- Public claims: no ASReml-beating wording until benchmark evidence exists.

## 20. First Minimal Viable Implementation

Already implemented:

- Julia package scaffold;
- backend marker placeholders;
- `HSControl`;
- pedigree normalization;
- direct sparse `Ainv`;
- Documenter docs site.

Next minimal implementation:

1. Mirror the R `hs_build_model_spec()` payload in Julia as a typed
   `HSModelSpec`.
2. Build fixed-effect matrix handling from parsed R payloads.
3. Build animal random-effect design `Z`.
4. Implement Gaussian ML/REML objective for one random animal effect.
5. Add conservative optimizer path.
6. Extract variance components, EBVs/BLUPs, and heritability.
7. Validate against Mrode tiny examples.
8. Add one open comparator check where feasible.
9. Keep Documenter and pkgdown status pages synchronized.

## Checked GPU Source Anchors

These sources were checked while drafting this roadmap:

- [CUDA.jl array programming](https://cuda.juliagpu.org/stable/usage/array/)
  for `CuArray`.
- [JuliaGPU CUDA backend](https://juliagpu.org/backends/cuda/) for CUDA.jl
  maturity and backend scope.
- [AMDGPU.jl stable quick start](https://amdgpu.juliagpu.org/stable/tutorials/quickstart)
  for ROCm/AMD GPU support.
- [Metal.jl stable documentation](https://metal.juliagpu.org/stable/) and
  [Metal.jl array programming](https://metal.juliagpu.org/stable/api/array/)
  for macOS GPU support and `MtlArray`.
- [oneAPI.jl repository](https://github.com/JuliaGPU/oneAPI.jl) for Intel
  accelerator support and current platform caveats.
- [KernelAbstractions.jl documentation](https://juliagpu.github.io/KernelAbstractions.jl/)
  for backend-generic kernel design.

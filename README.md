# HSquared.jl

Documentation: [HSquared.jl engine docs](https://itchyshin.github.io/HSquared.jl/) |
R twin: [hsquared pkgdown site](https://itchyshin.github.io/hsquared/) |
[hsquared repository](https://github.com/itchyshin/hsquared)

`HSquared.jl` is the Julia engine underneath the R package `hsquared`.

The long-term goal is open, sparse, inheritance-aware quantitative genetics:
sparse animal models, pedigree and genomic relationship structures, REML/ML
estimation, breeding values, G matrices, factor-analytic genetic covariance,
and high-dimensional GLLVM-style extensions.

The intended users are breeders, plant and livestock geneticists, evolutionary
geneticists, genomic prediction users, and applied analysts who need R syntax
with a Julia engine underneath. Comparator packages such as ASReml,
BLUPF90, DMU, WOMBAT, sommer, MCMCglmm, JWAS, AGHmatrix, and nadiv are
benchmarks to learn from and test against, not claims of current superiority.

## Current Status

This repository has moved beyond the scaffold. It has experimental
validation-scale engine utilities for univariate animal models, REML/AI-REML
estimation, genomic relationship models, repeatability / two-effect models,
multivariate REML, structured multivariate genetic covariance, and fixed-effect
marker screening. It is still not a production sparse animal-model engine and
does not provide the public R formula default for most of those surfaces.

The Documenter site includes a [mission-control dashboard](https://itchyshin.github.io/HSquared.jl/dev/mission-control.html)
for the current twin-lane status, evidence gates, and blocked claims.

Implemented now:

- package metadata and CI;
- a small control object for future backend/save/precision choices, aligned to
  the R twin's planned `auto`, `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, and
  `oneapi` vocabulary;
- backend marker types for CPU, threaded CPU, CUDA, AMDGPU, Metal, oneAPI, and
  auto selection;
- `backend_info()` status diagnostics showing that planned backend names are
  selectable metadata but not execution-ready yet;
- planned model-term vocabulary reservations through `planned_model_terms()`,
  including `genomic()`, `single_step()`, `markers()`, `marker_scan()`,
  `qtl_scan()`, `permanent()`, `common_env()`, `maternal_genetic()`,
  `maternal_env()`, `paternal_genetic()`, `paternal_env()`, `cytoplasmic()`,
  `imprinting()`, `dominance()`, `epistasis()`, `relmat()`, and
  `HSquared.precision()`; these names error honestly and do not construct
  model specs yet;
- `formula_status()` grammar diagnostics that mirror the R twin's parsed,
  reserved, and planned formula-status table;
- `validation_status()` diagnostics for the validation evidence ladder,
  including covered, external, partial, and planned rows;
- pedigree validation, ID recoding, unknown-parent handling, and topological
  sorting;
- direct sparse inverse additive relationship matrix construction for validated
  pedigrees, with optional R-side `nadiv::Mrode9` comparator evidence;
- low-level animal-model spec validation for `y`, `X`, `Z`, `Ainv`, IDs,
  Gaussian family, and ML/REML method;
- dense Gaussian ML/REML log-likelihood evaluation at supplied variance
  components for validated animal-model specs, with a `max_dense_cells` safety
  guard for the temporary dense path;
- sparse REML log-likelihood evaluation at supplied variance components via
  the Henderson MME determinant identity;
- experimental sparse REML validation optimization for low-level validated
  animal-model specs;
- experimental average-information REML for two-component Gaussian animal
  models, with R-lane known-truth and published-anchor evidence;
- experimental dense variance-component optimization for low-level validated
  animal-model specs;
- experimental variance-component, fixed-effect, MME-backed EBV/BLUP aliases,
  fitted-value, heritability, prediction-error-variance, reliability, and
  derived accuracy extractors for the low-level spec and supplied-variance
  Henderson MME validation paths;
- `fit_diagnostics()` metadata extraction for low-level `AnimalModelFit` and
  supplied-variance `HendersonMMEResult` objects;
- experimental direct payload fitting target
  `fit_animal_model(y, X, Z, Ainv; ...)` for bridge-shaped inputs;
- explicit supplied-variance Julia target
  `fit_animal_model(...; target = :henderson_mme, variance_components = ...)`
  returning `HendersonMMEResult`;
- sparse Henderson mixed-model-equation solve at supplied variance components,
  with a shared R/Julia fixture for Ainv, fixed effects, EBVs, fitted values,
  and `h2`;
- a Julia-native Mrode9-shaped supplied-variance validation fixture for Ainv,
  ML/REML likelihood values, fixed effects, EBVs, fitted values, PEV,
  reliability, derived accuracy, and `h2`;
- in-memory `HSData` container and ID-overlap map for phenotype, pedigree,
  genotype, expression, marker, annotation, and environment inputs;
- genotype-component metadata diagnostics inside `HSData`;
- marker-map metadata validation and genotype-marker alignment checks inside
  `HSData`;
- expression-component metadata diagnostics inside `HSData`;
- annotation-feature metadata diagnostics inside `HSData`;
- environment-key metadata diagnostics inside `HSData`;
- `data_status()` diagnostics for `HSData` component presence, ID-overlap
  counts, pedigree status, genotype status, marker-alignment status,
  expression status, annotation-feature status, and environment-key status;
- external R `hs_data()` parser integration evidence: R `model_spec()` and
  `hsquared()` can start from an `hs_data()` bundle for the v0.1 parser while
  preserving the same bridge payload shape;
- sparse CSC marshalling helper for R `Matrix::dgCMatrix` slots;
- external R `model_spec()` evidence for previewing the v0.1
  formula-to-bridge payload without fitting or Julia execution;
- external opt-in tiny/local R bridge evidence from the `hsquared` twin over
  the current Julia payload path and `result_payload()`, with R-side
  enrichment from Julia PEV/reliability extractors for tiny validation fits
  and supplied-variance `target = "henderson_mme"` results when applicable;
- external opt-in R bridge evidence for a supplied-variance
  `target = "henderson_mme"` path; this returns fixed effects, EBVs/BLUPs,
  fitted values, supplied variance components, simple `h2`, diagnostics, and
  convergence status, but no log-likelihood, AIC, `df`, optimizer output, or
  variance-component estimation;
- external R `fit_diagnostics()` evidence from the `hsquared` twin; Julia now
  mirrors the same idea as metadata-only extraction without widening
  `result_payload()`;
- experimental genomic utilities: VanRaden `G`, regularized `Ginv`,
  supplied-variance GBLUP, SNP-BLUP / marker effects, single-step `H`-inverse
  construction, genomic REML over a `Ginv` spec, direct fixed-effect marker
  screening, supplied-variance mixed-model marker screening, dense LOCO
  relationship precision construction and supplied leave-one-group-out marker
  screening, approximate Wald p-values plus
  Bonferroni and Benjamini-Hochberg adjustments, LOD-equivalent scores,
  row-aligned marker-scan table preparation, marker-effect summaries,
  marker-variance contribution summaries, nominal returned-marker-set
  significance summaries, and marker-map-backed Manhattan, regional-window,
  QQ, and lambda_GC diagnostic preparation, plus an opt-in marker-scan recovery
  harness outside CI;
- experimental repeatability and two-effect model utilities;
- experimental multivariate animal-model utilities, including supplied-
  covariance MME, missing-trait records, dense multivariate REML, structured
  genetic covariance (`diag`, `lowrank`, `fa`), local extractors, opt-in
  recovery harnesses, and a serialized target fixture for future R-lane
  comparator work;
- honest placeholder entry points;
- team, memory, roadmap, and capability-status documentation.

Planned, but not implemented yet:

- backend execution dispatch, runtime backend availability probing, GPU
  execution, backend benchmarking, and CPU/GPU numerical agreement tests;
- production sparse optimization / AI-REML fitting;
- relationship-object marshalling beyond sparse `Z`, production engine
  controls, and validated high-level public formula fitting;
- production sparse EBVs/BLUPs, reliability, and prediction error variance;
- R-facing multivariate model-spec syntax and external comparator parity;
- public R-facing genomic model-spec fitting, production genomic prediction,
  APY/sparse genomic scaling, formula-driven mixed-model marker scans, public
  LOCO workflows, interval-mapping or mixed-model LOD workflows,
  genome-wide multiple-testing calibration, QTL/eQTL intervals, and
  non-standard inheritance models;
- GLLVM-style high-dimensional animal models.

## Julia Surface

The first Phase 1 utility surface is available for pedigree checks:

```julia
using HSquared

ped = normalize_pedigree(
    ["calf", "sire", "dam"],
    ["sire", "0", "0"],
    ["dam", "0", "0"],
)
Ainv = pedigree_inverse(ped)
```

This is an engine utility only. It is not yet connected to a fitted animal
model.

The first Julia data container mirrors the R `hs_data()` input contract:

```julia
data = HSData(
    phenotypes;
    id = :id,
    pedigree = ped,
    genotypes = genotype_matrix,
    genotype_ids = genotype_ids,
)

id_map(data)
data_status(data)
```

This records exact ID overlap and data-container diagnostics only. File-backed
storage, relationship construction from genotypes, and QTL/eQTL scans remain
planned.

`HSData` also validates marker-map metadata and genotype-marker alignment when
both marker maps and genotypes are supplied. This is metadata validation only;
it is not genotype parsing, imputation, marker scanning, genomic fitting, or
QTL/eQTL support.

When genotypes are supplied, `data_status()` reports genotype rows, matched
genotype IDs, marker-column counts, named and unnamed marker-column counts,
duplicate named marker columns, missing genotype value counts, and component
type. This is metadata diagnostics only. It does not parse PLINK/VCF, impute
genotypes, construct genomic relationship matrices, run marker scans, or fit
genomic/QTL/GWAS/eQTL models. Plain Julia matrices are reported as matrix
components with unnamed marker columns because base matrices do not carry
marker column names.

When expression data are supplied, `data_status()` reports expression rows,
matched expression IDs, feature-column counts, named and unnamed feature
counts, duplicate named features where table-like inputs expose names, and
component type. This is metadata diagnostics only. It does not join expression
features into model matrices, fit eQTL or other omics models, or run GLLVM
workflows. Plain Julia matrices are reported as matrix components with unnamed
features because base matrices do not carry feature column names.

When annotation metadata and `annotation_id` are supplied, `HSData` validates
annotation feature keys against table-like expression feature columns and
`data_status()` reports feature coverage, annotation-only features, expression
features without annotation, and duplicate annotation features. This is
metadata diagnostics only. It does not join annotation covariates into model
matrices, fit eQTL or other omics models, or run GLLVM workflows.

`data_status()` also reports pedigree-table diagnostics such as founder rows,
known parent links, duplicate raw pedigree IDs, missing known parent IDs,
self-parent rows, and same-known-parent rows. These diagnostics do not
normalize the pedigree or build `Ainv`; `normalize_pedigree()` remains the
engine validation path.

When an environment table and `environment_id` are supplied, `HSData` validates
that the key exists in both phenotype and environment metadata and
`data_status()` reports overlap, missing metadata keys, environment-only keys,
and duplicate environment IDs. This is metadata diagnostics only. It does not
join environment covariates into model matrices or fit environmental,
multi-environment, QTL/eQTL, or GLLVM workflows.

On the R side, `hs_data()` can feed the v0.1 parser for `model_spec()` and
`hsquared()` by reading variables from `data$phenotypes` and resolving
`pedigree` from the bundle. That R integration still produces the same bridge
payload shape. R also allows `animal(1 | id)` to use the bundled pedigree when
`data = hs_data(..., pedigree = ped)`, but the explicit
`animal(1 | id, pedigree = ped)` spelling remains the shared portable
contract. Julia `HSData` object marshalling remains planned.

The planned genomic/QTL and standard quantitative-genetic vocabulary is
reserved but not implemented:

```julia
planned_model_terms()
planned_genomic_qtl_terms()
planned_quantgen_terms()
formula_status()
```

Calls such as `genomic()`, `single_step()`, `markers()`, `marker_scan()`, and
`qtl_scan()` currently throw planned-not-implemented errors. So do planned
standard quantitative-genetic terms such as `permanent()`, `common_env()`,
`maternal_genetic()`, `dominance()`, `relmat()`, and
`HSquared.precision()`. They do not build model specs, fit genomic models, run
marker/QTL scans, or fit Phase 2+ quantitative-genetic effects.

The first bridge-ready model specification validator is also available:

```julia
spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = :REML)
```

This validates the low-level inputs that the R parser will eventually hand to
Julia. It does not fit the model.

The first Gaussian likelihood evaluator is available for supplied variance
components:

```julia
lik = gaussian_loglik(spec, 1.0, 1.0)
sparse_lik = sparse_reml_loglik(spec, 1.0, 1.0)
```

These evaluate objective values. They do not optimize variance components or
return EBVs.

The first experimental dense optimizer is available for validated specs:

```julia
fit = fit_variance_components(spec)
```

This is a low-level Julia validation path. It is not the production sparse
animal-model engine, and the R twin's opt-in path remains experimental and
tiny/local.
Use `max_dense_cells` in direct Julia validation runs where accidental dense
allocation needs to fail early.

An experimental sparse REML validation optimizer is also available:

```julia
sparse_fit = fit_sparse_reml(spec)
```

This optimizes the same sparse REML objective used by `sparse_reml_loglik()`.
It is REML-only, not AI-REML, not the default fitting path, and not production
sparse fitting.

The first sparse equation solve is also available at supplied variance
components:

```julia
mme = henderson_mme(spec, 1.0, 1.0)
breeding_values(mme)
EBV(mme)
```

This solves Henderson's mixed-model equations for fixed effects and animal
effects. It does not estimate variance components. Validation-scale
`variance_components(mme)`, `heritability(mme)`,
`prediction_error_variance(mme)`, `reliability(mme)`, and `accuracy(mme)`
methods report supplied variances and dense-MME-inverse outputs for tiny
fixtures only. `accuracy()` is derived from reliability and errors instead of
clipping when reliability is outside `[0, 1]`.

The dense validation path also has first extractors:

```julia
variance_components(fit)
breeding_values(fit)
BLUP(fit)
heritability(fit)
prediction_error_variance(fit)
reliability(fit)
accuracy(fit)
```

These are experimental low-level outputs, not yet production sparse results.
For supplied-variance MME results, use the same extractor names on `mme`.

The backend-control diagnostic mirrors the R twin's planned vocabulary:

```julia
info = backend_info(HSControl(accelerator = :gpu))
info.rows
```

All rows currently report `execution_available == false` and
`status == :planned`. This is a status surface, not runtime GPU probing.

The high-level modelling surface is still planned:

```julia
using HSquared

fit = hsquared(
    # planned formula interface
)
```

For lower-level bridge-shaped engine work, the direct payload target is
available experimentally:

```julia
fit = fit_animal_model(y, X, Z, Ainv; method = :REML)
sparse_fit = fit_animal_model(y, X, Z, Ainv; method = :REML, target = :sparse_reml)
mme = fit_animal_model(
    y,
    X,
    Z,
    Ainv;
    method = :REML,
    target = :henderson_mme,
    variance_components = (sigma_a2 = 1.2, sigma_e2 = 0.8),
)
```

`hsquared()` currently throws a Phase 0 not-implemented error. `fit_animal_model`
works for a validated `AnimalModelSpec` or the direct `y, X, Z, Ainv` payload;
other calls remain placeholders.

## Twin Package Boundary

- `hsquared` is the R-facing public identity: formulas, validation, user
  documentation, S3 methods, plotting, and the eventual R-to-Julia bridge.
- `HSquared.jl` is the Julia engine: sparse relationship matrices, solvers,
  likelihoods, EBVs, G matrices, and computational kernels.

The R package may describe planned syntax, but executable examples should not
claim fitting support until this Julia engine implements and validates it.

## Development

Run the Julia tests with:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

See `AGENTS.md`, `ROADMAP.md`, and `docs/design/` for the operating system that
keeps the two twins synchronized.

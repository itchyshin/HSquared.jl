# HSquared.jl

!!! warning "Experimental 0.8.0 — not production"
    Version number tracks covered capability, not maturity. **Not** in the
    Julia General registry. An earlier attempt
    ([General PR #166969](https://github.com/JuliaRegistries/General/pull/166969),
    v0.5.0) was closed. Install with `Pkg.add(url=...)` only — do **not**
    use `Pkg.add("HSquared")` by name.
    `public_covered_count` is **7** (R-public; G10 multivariate + 0.7 genomic GREML default-route).

I used language-model tools (Claude, Codex, and Cursor) on substantial
parts of this engine: source, tests, and docs. I review the code I
ship, and I am responsible for it. Tests and Documenter run in CI.
This release is experimental 0.8.0. It is not a production engine and
it is not version 1.0. HSquared is not in the Julia General registry
yet; until a later registration actually merges, install with
`Pkg.add(url=...)` only.

`HSquared.jl` is the Julia engine twin of the R package
[hsquared](https://github.com/itchyshin/hsquared). This is not the package
you type a formula into.

R users: start at [hsquared](https://github.com/itchyshin/hsquared)
(`y ~ sex + age + animal(1 | id, pedigree = ped)`), or the
[hsquared pkgdown site](https://itchyshin.github.io/hsquared/).
That is the applied-user interface. These pages document the engine.

This engine already has experimental validation-scale fitting: pedigree
checks, sparse `Ainv`, low-level REML and Henderson MME solves, and
extractors for heritability, EBVs, and PEV. Those are engine utilities,
not a public formula API and not a production sparse pipeline.

`hsquared()` here still throws. Lower-level `fit_animal_model` and
`fit_ai_reml` exist as experimental engine paths, not the applied
default. Read [Get started](quickstart.md) and `validation_status()`
before treating any path as production.

## What Works Today

This repository is still early. It has experimental validation-scale
engine fitting (dense and sparse REML, supplied-variance MME) for
validated Julia specs, and the R twin has an opt-in tiny/local JuliaCall
path over that engine. It does not yet provide production animal-model
fitting or production R bridge execution.

Implemented engine utilities:

- package loading and control/backend marker types;
- planned backend and accelerator control vocabulary for CPU, threaded CPU,
  CUDA, AMDGPU, Metal, oneAPI, generic GPU preference, and auto selection;
- `backend_info()` status diagnostics showing selectable planned backend names
  with execution unavailable;
- `formula_status()` grammar diagnostics showing parsed, reserved, and planned
  syntax rows without enabling fitting;
- `validation_status()` diagnostics showing covered, external, partial, and
  planned validation rows without running comparator packages;
- planned model-term vocabulary reservations through `planned_model_terms()`,
  including genomic/QTL terms and standard quantitative-genetic terms such as
  `permanent()`, `common_env()`, `maternal_genetic()`, `dominance()`,
  `relmat()`, and `HSquared.precision()`; these error honestly and do not
  build model specs yet;
- honest placeholder entry points for future model fitting;
- pedigree validation, ID recoding, unknown-parent handling, and topological
  sorting;
- direct sparse inverse additive relationship matrix construction for validated
  pedigrees;
- low-level animal-model spec validation;
- dense Gaussian ML/REML log-likelihood evaluation at supplied variance
  components, with a `max_dense_cells` guard for the temporary dense path;
- sparse REML log-likelihood evaluation at supplied variance components via
  the Henderson MME determinant identity;
- experimental sparse REML validation optimization for low-level validated
  specs;
- experimental average-information REML for two-component Gaussian animal
  models, with known-truth and published-anchor evidence recorded through the
  R lane;
- experimental dense variance-component optimization for validated specs;
- experimental variance-component, fixed-effect, MME-backed EBV/BLUP aliases,
  fitted-value, heritability, PEV, reliability, and checked accuracy extractors
  for the dense spec and supplied-variance Henderson MME validation paths;
- `fit_diagnostics()` metadata extraction for low-level fit objects;
- experimental direct payload fitting target for `y`, `X`, `Z`, `Ainv`;
- experimental direct supplied-variance Henderson target through
  `fit_animal_model(...; target = :henderson_mme, variance_components = ...)`;
- sparse Henderson mixed-model-equation solve at supplied variance components,
  with a shared R/Julia fixture for Ainv, fixed effects, EBVs, fitted values,
  and `h2`;
- sparse CSC marshalling helper for R sparse matrix slots;
- `HSData` in-memory data-container diagnostics for component presence,
  ID-overlap counts, pedigree status, genotype metadata status, marker
  alignment, expression metadata status, annotation-feature metadata status,
  and environment-key metadata status;
- experimental genomic utilities: VanRaden `G`,
  `genomic_relationship_inverse`, supplied-variance `fit_gblup`,
  `fit_snp_blup`, single-step `H`-inverse construction, genomic REML over a
  `Ginv` spec, direct fixed-effect `single_marker_scan`, supplied-variance
  `mixed_model_marker_scan`, dense LOCO precision construction via
  `loco_relationship_precisions`, supplied `loco_mixed_model_marker_scan`, and
  row-aligned marker-scan tables, GWAS/QTL/eQTL labelled table wrappers,
  marker-effect summaries, marker-variance contribution summaries, nominal
  returned-marker-set significance summaries, and marker-map-backed
  `marker_manhattan_data`, `marker_region_data`, and `marker_qq_data`
  plot-data preparation, plus an opt-in marker-scan recovery
  harness outside CI;
- experimental repeatability, two-effect, multivariate, and structured
  genetic-covariance utilities, all validation-scale and not public R formula
  defaults;
- external opt-in R bridge evidence from the `hsquared` twin;
- small deterministic tests for malformed pedigrees, hand-checked `Ainv`
  matrices, and supplied-variance Henderson MME outputs.
- optional R-side `nadiv::Mrode9` comparator evidence for `pedigree_inverse()`.

Planned, but not implemented yet:

- sparse production REML/ML and AI-REML fitting;
- production sparse EBVs/BLUPs, reliability, prediction error variance, and
  heritability extraction;
- production R-to-Julia fitting bridge;
- genotype parsing, imputation, public genomic model-spec fitting,
  formula-driven mixed-model marker scans, public LOCO workflows, calibrated
  mixed-model p-values, calibrated PVE/model R² claims, interval-mapping or
  mixed-model LOD workflows, genome-wide multiple-testing calibration, and
  QTL/eQTL intervals;
- environmental model terms, automatic environment joins, and
  multi-environment animal-model workflows;
- expression-feature joins and eQTL/omics fitting from expression metadata;
- annotation joins, eQTL/omics fitting, and GLLVM workflows from annotation
  metadata;
- R↔engine element-wise multivariate parity in CI, and ASReml/JWAS
  multivariate comparator legs;
- non-standard inheritance models;
- GLLVM-style high-dimensional animal models.
- backend execution dispatch, runtime backend availability probing, GPU
  execution, backend benchmarking, and CPU/GPU numerical agreement tests.

## Install

HSquared is **not** in the Julia General registry. An earlier attempt
([General PR #166969](https://github.com/JuliaRegistries/General/pull/166969),
v0.5.0) was closed. Do **not** use `Pkg.add("HSquared")` by name. This
`0.8.0` number is experimental; `public_covered_count` is **7** (R-public; G10 multivariate + 0.7 genomic GREML default-route).

```julia
using Pkg
Pkg.add(url = "https://github.com/itchyshin/HSquared.jl")
```

## First Engine Utility

```@example pedigree
using HSquared

ped = normalize_pedigree(
    ["calf", "sire", "dam"],
    ["sire", "0", "0"],
    ["dam", "0", "0"],
)

ped.ids
```

```@example pedigree
Ainv = pedigree_inverse(ped)
Matrix(Ainv)
```

## Twin Boundary

- `hsquared` is the R-facing package identity: formulas, validation, user
  documentation, S3 methods, plotting, and bridge calls.
- `HSquared.jl` is the computational engine: sparse relationship matrices,
  likelihoods, solvers, EBVs, G matrices, and low-level diagnostics.

The R package can describe planned syntax, but public executable examples must
not claim model fitting until the Julia engine implements and validates it.

## Start Here

- [Mission control](mission-control.md)
- [Get started](quickstart.md)
- [Model spec grammar](model-spec-grammar.md)
- [Data containers](data.md)
- [Pedigrees and Ainv](pedigree-ainv.md)
- [Audience and comparators](audience-comparators.md)
- [Genomics, QTL, GPU, and HPC](genomics-qtl-gpu-hpc.md)
- [Backend and algorithm roadmap](backend-algorithm-roadmap.md)
- [Roadmap](roadmap.md)
- [Reference](api.md)

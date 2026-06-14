# HSquared.jl

`HSquared.jl` is the Julia engine twin of the R package `hsquared`.

Its scope is inheritance-aware quantitative genetics: pedigree and genomic
precision matrices, Gaussian animal models, breeding values, heritability,
G matrices, factor-analytic genetic covariance, and later high-dimensional
GLLVM-style extensions.

## What Works Today

This repository is still early. It has a low-level experimental dense fitting
path for validated Julia specs, and the R twin has an opt-in tiny/local
JuliaCall path over that engine. It does not yet provide production
animal-model fitting or production R bridge execution.

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
  row-aligned marker-scan tables, marker-effect summaries, marker-variance
  contribution summaries, nominal returned-marker-set significance summaries,
  and marker-map-backed `marker_manhattan_data`, `marker_region_data`, and
  `marker_qq_data` plot-data preparation;
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
- R-facing multivariate model-spec syntax and comparator parity;
- non-standard inheritance models;
- GLLVM-style high-dimensional animal models.
- backend execution dispatch, runtime backend availability probing, GPU
  execution, backend benchmarking, and CPU/GPU numerical agreement tests.

## Install

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

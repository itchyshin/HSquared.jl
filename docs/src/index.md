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
- experimental dense variance-component optimization for validated specs;
- experimental variance-component, fixed-effect, EBV/BLUP, fitted-value, and
  heritability, PEV, and reliability extractors for the dense spec path;
- experimental direct payload fitting target for `y`, `X`, `Z`, `Ainv`;
- sparse Henderson mixed-model-equation solve at supplied variance components;
- sparse CSC marshalling helper for R sparse matrix slots;
- external opt-in R bridge evidence from the `hsquared` twin;
- small deterministic tests for malformed pedigrees and hand-checked `Ainv`
  matrices.
- optional R-side `nadiv::Mrode9` comparator evidence for `pedigree_inverse()`.

Planned, but not implemented yet:

- sparse production REML/ML and AI-REML fitting;
- production sparse EBVs/BLUPs, reliability, prediction error variance, and
  heritability extraction;
- production R-to-Julia fitting bridge;
- multivariate animal models and G matrices;
- genomic prediction, single-step fitting, marker-effect estimation,
  marker scans, QTL/eQTL scans, and non-standard inheritance models;
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

- [Get started](quickstart.md)
- [Model spec grammar](model-spec-grammar.md)
- [Data containers](data.md)
- [Pedigrees and Ainv](pedigree-ainv.md)
- [Audience and comparators](audience-comparators.md)
- [Genomics, QTL, GPU, and HPC](genomics-qtl-gpu-hpc.md)
- [Roadmap](roadmap.md)
- [Reference](api.md)

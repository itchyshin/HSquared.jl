# HSquared.jl

`HSquared.jl` is the Julia engine twin of the R package `hsquared`.

Its scope is inheritance-aware quantitative genetics: pedigree and genomic
precision matrices, Gaussian animal models, breeding values, heritability,
G matrices, factor-analytic genetic covariance, and later high-dimensional
GLLVM-style extensions.

## What Works Today

This repository is still early. It does not fit animal models yet.

Implemented engine utilities:

- package loading and control/backend marker types;
- honest placeholder entry points for future model fitting;
- pedigree validation, ID recoding, unknown-parent handling, and topological
  sorting;
- direct sparse inverse additive relationship matrix construction for validated
  pedigrees;
- small deterministic tests for malformed pedigrees and hand-checked `Ainv`
  matrices.

Planned, but not implemented yet:

- REML/ML or AI-REML fitting;
- EBVs/BLUPs and heritability extraction;
- R-to-Julia fitting bridge;
- multivariate animal models and G matrices;
- genomic, single-step, and non-standard inheritance models;
- GLLVM-style high-dimensional animal models.

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
- [Pedigrees and Ainv](pedigree-ainv.md)
- [Audience and comparators](audience-comparators.md)
- [Genomics, QTL, GPU, and HPC](genomics-qtl-gpu-hpc.md)
- [Roadmap](roadmap.md)
- [Reference](api.md)

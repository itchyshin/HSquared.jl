# Vision

`HSquared.jl` is the sparse Julia engine for the `hsquared` quantitative-
genetic modelling system.

The R package gives applied users a friendly formula interface. This Julia
package owns the computational contracts: pedigree and genomic precision
matrices, Gaussian animal-model likelihoods, EBVs/BLUPs, heritability,
G matrices, diagnostics, and later high-dimensional and inheritance-aware
extensions.

## Niche

The project aims for:

```text
ASReml-style animal-model capability
+ MCMCglmm-like biological flexibility
+ brms/drmTMB-like syntax on the R side
+ Julia sparse precision computation
+ GLLVM-style high-dimensional G-matrix modelling
+ unusual inheritance systems
+ open community software
```

These are roadmap targets, not current capabilities. Phase 0 is a scaffold.

## Current Status

Phase 0 scaffold. No model fitting, sparse Ainv construction, REML/ML engine,
or R-Julia bridge is implemented yet.

## First Capability Target

The first working slice should support the lower-level engine call:

```julia
fit = fit_animal_model(y, X, Z, Ainv; method = :REML)
```

This is planned for Phase 1.

# HSquared.jl

`HSquared.jl` is the planned Julia engine underneath the R package
`hsquared`.

The long-term goal is open, sparse, inheritance-aware quantitative genetics:
sparse animal models, pedigree and genomic relationship structures, REML/ML
estimation, breeding values, G matrices, factor-analytic genetic covariance,
and high-dimensional GLLVM-style extensions.

## Current Status

This repository is a **Phase 0 scaffold**. It does not fit models yet.

Implemented now:

- package metadata and CI;
- a small control object for future backend/save/precision choices;
- backend marker types;
- honest placeholder entry points;
- team, memory, roadmap, and capability-status documentation.

Planned, but not implemented yet:

- pedigree validation and sparse `Ainv` construction;
- REML/ML or AI-REML fitting;
- EBVs/BLUPs and heritability;
- multivariate animal models and G matrices;
- genomic, single-step, and non-standard inheritance models;
- GLLVM-style high-dimensional animal models.

## Planned Julia Surface

```julia
using HSquared

fit = hsquared(
    # planned formula interface
)
```

For lower-level engine work, the first planned target is:

```julia
fit = fit_animal_model(y, X, Z, Ainv; method = :REML)
```

Both functions currently throw a Phase 0 not-implemented error.

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

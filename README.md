# HSquared.jl

`HSquared.jl` is the planned Julia engine underneath the R package
`hsquared`.

The long-term goal is open, sparse, inheritance-aware quantitative genetics:
sparse animal models, pedigree and genomic relationship structures, REML/ML
estimation, breeding values, G matrices, factor-analytic genetic covariance,
and high-dimensional GLLVM-style extensions.

The intended users are breeders, plant and livestock geneticists, evolutionary
geneticists, genomic prediction users, and applied analysts who need R syntax
with a fast Julia engine underneath. Comparator packages such as ASReml,
BLUPF90, DMU, WOMBAT, sommer, MCMCglmm, JWAS, AGHmatrix, and nadiv are
benchmarks to learn from and test against, not claims of current superiority.

## Current Status

This repository has completed Phase 0 and has started Phase 1. It has an
experimental dense fitting path for validated low-level Julia specs, but it is
not yet a production animal-model engine.

Implemented now:

- package metadata and CI;
- a small control object for future backend/save/precision choices;
- backend marker types;
- pedigree validation, ID recoding, unknown-parent handling, and topological
  sorting;
- direct sparse inverse additive relationship matrix construction for validated
  pedigrees;
- low-level animal-model spec validation for `y`, `X`, `Z`, `Ainv`, IDs,
  Gaussian family, and ML/REML method;
- dense Gaussian ML/REML log-likelihood evaluation at supplied variance
  components for validated animal-model specs;
- experimental dense variance-component optimization for low-level validated
  animal-model specs;
- experimental variance-component, fixed-effect, EBV/BLUP, fitted-value, and
  heritability, prediction-error-variance, and reliability extractors for the
  dense low-level spec path;
- experimental direct payload fitting target
  `fit_animal_model(y, X, Z, Ainv; ...)` for bridge-shaped inputs;
- in-memory `HSData` container and ID-overlap map for phenotype, pedigree,
  genotype, expression, marker, annotation, and environment inputs;
- sparse CSC marshalling helper for R `Matrix::dgCMatrix` slots;
- external opt-in tiny/local R bridge evidence from the `hsquared` twin over
  the current Julia payload path and `result_payload()`;
- honest placeholder entry points;
- team, memory, roadmap, and capability-status documentation.

Planned, but not implemented yet:

- sparse production optimization or AI-REML fitting;
- R-side sparse marshalling, production engine controls, and validated
  high-level public formula fitting;
- production sparse EBVs/BLUPs, reliability, and prediction error variance;
- multivariate animal models and G matrices;
- genomic, single-step, and non-standard inheritance models;
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
```

This records exact ID overlap only. File-backed storage, relationship
construction from genotypes, and QTL/eQTL scans remain planned.

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
```

This evaluates an objective value. It does not optimize variance components or
return EBVs.

The first experimental dense optimizer is available for validated specs:

```julia
fit = fit_variance_components(spec)
```

This is a low-level Julia validation path. It is not the production sparse
animal-model engine, and it is not yet exposed through the R formula bridge.

The dense validation path also has first extractors:

```julia
variance_components(fit)
breeding_values(fit)
heritability(fit)
prediction_error_variance(fit)
reliability(fit)
```

These are experimental low-level outputs, not yet production sparse results.

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

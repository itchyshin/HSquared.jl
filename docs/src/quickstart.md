# Get Started

`HSquared.jl` currently exposes engine utilities, not a full model-fitting
workflow.

## Normalize A Pedigree

```@example quickstart
using HSquared

ped = normalize_pedigree(
    ["offspring", "parent_a", "parent_b"],
    ["parent_a", "0", "0"],
    ["parent_b", "0", "0"],
)
```

The returned pedigree is sorted so known parents precede offspring.

```@example quickstart
ped.ids
```

Unknown parents are encoded as `0` in the normalized parent-index vectors.

```@example quickstart
ped.sire, ped.dam
```

## Build A Sparse `Ainv`

```@example quickstart
Ainv = pedigree_inverse(ped)
Matrix(Ainv)
```

This matrix is the sparse inverse additive relationship matrix used by later
animal-model fitting code.

## Validate A Low-Level Model Spec

The first bridge-ready Julia spec validates `y`, `X`, `Z`, `Ainv`, IDs, family,
and ML/REML method. It still does not fit the model.

```@example quickstart
using LinearAlgebra, SparseArrays

y = [1.0, 2.0, 3.0]
X = [1.0 0.0; 1.0 1.0; 1.0 2.0]
Z = sparse(I, 3, 3)

spec = animal_model_spec(y, X, Z, Ainv; ids = ped.ids, method = "REML")
spec.method
```

R bridge code can pass sparse design matrices without densifying by using CSC
slots from `Matrix::dgCMatrix`.

```@example quickstart
Z_from_slots = sparse_csc_matrix(
    size(Z, 1),
    size(Z, 2),
    Z.colptr .- 1,
    Z.rowval .- 1,
    Z.nzval,
)

Z_from_slots == Z
```

## Evaluate The Gaussian Likelihood

The first likelihood function evaluates ML or REML at supplied variance
components. It is a checked objective value, not an optimizer.

```@example quickstart
lik = gaussian_loglik(spec, 1.0, 1.0)
lik.loglik
```

The first sparse likelihood utility evaluates the same REML objective with the
Henderson mixed-model-equation determinant identity. It still uses supplied
variance components; it is not an optimizer.

```@example quickstart
sparse_lik = sparse_reml_loglik(spec, 1.0, 1.0)
isapprox(sparse_lik.loglik, lik.loglik)
```

## Fit Variance Components Experimentally

`fit_variance_components` optimizes the dense objective for a validated spec.
This is the first low-level fitting path, but it is still for tiny validation
examples rather than production sparse analysis.

```@example quickstart
fit = fit_variance_components(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0))
fit.variance_components
```

The same dense path is available through the direct bridge-shaped payload:

```@example quickstart
payload_fit = fit_animal_model(
    y,
    X,
    Z,
    Ainv;
    ids = ped.ids,
    method = :REML,
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
)
payload_fit isa AnimalModelFit
```

The dense validation path is size-guarded. The guard is intended for tiny/local
bridge checks and fails before the current implementation forms dense
covariance or relationship matrices.

```@example quickstart
try
    fit_variance_components(spec; max_dense_cells = 17)
catch err
    sprint(showerror, err)
end
```

## Solve Henderson Equations At Supplied Variances

The first sparse equation-solve utility uses Henderson's mixed-model equations
at supplied variance components.

```@example quickstart
mme = henderson_mme(spec, 1.0, 1.0)
fixed_effects(mme)
```

```@example quickstart
breeding_values(mme).values
```

This solves for fixed effects and animal-effect BLUPs/EBVs given variance
components. It does not estimate those variance components.

## Extract Experimental Low-Level Results

The dense validation path has first extractors for variance components,
fixed effects, breeding values, fitted values, simple univariate heritability,
prediction error variance, and reliability.

```@example quickstart
variance_components(fit)
```

```@example quickstart
breeding_values(fit).values
```

```@example quickstart
heritability(fit)
```

```@example quickstart
prediction_error_variance(fit).values
```

```@example quickstart
reliability(fit).values
```

For R bridge work, `result_payload` returns the current bridge-facing names:

```@example quickstart
keys(result_payload(fit))
```

These outputs are useful for tiny validation examples. They are not yet sparse
production EBVs, reliabilities, or prediction error variances.

The R twin may enrich opt-in tiny/local bridge results by calling
`prediction_error_variance(fit)` and `reliability(fit)` after
`result_payload(fit)`. Those fields are intentionally not part of the compact
base payload contract.

For checking R formula parity before fitting, the R twin also exposes
`model_spec()`. It validates `animal(1 | id, pedigree = ped)` and previews the
bridge payload and Julia targets without executing Julia.

## What Does Not Work Yet

The high-level fitting functions are placeholders.

```@example quickstart
try
    fit_animal_model(nothing)
catch err
    sprint(showerror, err)
end
```

Sparse production optimization, AI-REML, production sparse reliability,
production sparse prediction error variance, and relationship-object
marshalling beyond sparse `Z` remain Phase 1 targets.

## R Syntax Parity Target

The planned bridge target is that R users write the public `hsquared` syntax and
select the Julia engine from R:

```r
hsquared(
  y ~ sex + age + animal(1 | id, pedigree = ped),
  data = dat,
  family = gaussian(),
  engine = "julia"
)
```

That is not executable yet. The current Julia utilities are the engine pieces
needed underneath that bridge.

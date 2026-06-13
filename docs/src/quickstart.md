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

## Evaluate The Gaussian Likelihood

The first likelihood function evaluates ML or REML at supplied variance
components. It is a checked objective value, not an optimizer.

```@example quickstart
lik = gaussian_loglik(spec, 1.0, 1.0)
lik.loglik
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

## Extract Experimental Low-Level Results

The dense validation path has first extractors for variance components,
fixed effects, breeding values, fitted values, and simple univariate
heritability.

```@example quickstart
variance_components(fit)
```

```@example quickstart
breeding_values(fit).values
```

```@example quickstart
heritability(fit)
```

These outputs are useful for tiny validation examples. They are not yet sparse
production EBVs, reliabilities, or prediction error variances.

## What Does Not Work Yet

The high-level fitting functions are placeholders.

```@example quickstart
try
    fit_animal_model(nothing)
catch err
    sprint(showerror, err)
end
```

Sparse production optimization, AI-REML, reliability, prediction error
variance, and R-to-Julia marshalling remain Phase 1 targets.

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

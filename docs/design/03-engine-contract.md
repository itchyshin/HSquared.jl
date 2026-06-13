# Engine Contract

This file records the planned Julia-side v0.1 engine surface.

## Planned Entry Point

```julia
fit = fit_animal_model(y, X, Z, Ainv; method = :REML)
```

This direct payload entry point is implemented as an experimental dense path.
It validates the payload with `animal_model_spec()` and dispatches to
`fit_variance_components()`.

## Implemented Relationship Utility

```julia
ped = normalize_pedigree(ids, sire, dam)
Ainv = pedigree_inverse(ped)
```

This utility validates and sorts a pedigree, recodes known parents to integer
indices, keeps unknown parents as `0`, and builds a sparse inverse additive
relationship matrix. It does not fit a model.

## Implemented Model-Spec Validator

```julia
spec = animal_model_spec(y, X, Z, Ainv; ids = ids, family = GaussianFamily(),
                         method = :REML)
```

This validates response/design dimensions, `Ainv`, encoded IDs, family, and
ML/REML method. It is bridge-ready groundwork for the R `hs_build_model_spec()`
payload. It still does not fit a model.

## Implemented Likelihood Evaluator

```julia
lik = gaussian_loglik(spec, sigma_a2, sigma_e2)
```

This evaluates the Gaussian ML or REML log-likelihood at supplied variance
components. The current implementation intentionally forms dense matrices so
the objective can be tested before the production sparse solver lands.

It does not optimize variance components, compute EBVs, or return a fitted
model.

## Experimental Dense Optimizer

```julia
fit = fit_variance_components(spec)
fit = fit_animal_model(spec)
```

For a validated `AnimalModelSpec`, Julia can now optimize the dense Gaussian
objective over positive additive and residual variance components using a
log-variance parameterization and `Optim.NelderMead()`.

This is a low-level validation path. It is not the production sparse animal
model engine, not AI-REML, and not yet exposed through the R formula bridge.

## Experimental Low-Level Extractors

```julia
variance_components(fit)
fixed_effects(fit)
breeding_values(fit)
fitted_values(fit)
heritability(fit)
```

These operate on `AnimalModelFit` objects from the dense validation path.
`breeding_values(fit)` returns a `BreedingValues` object with encoded `ids` and
dense animal-effect BLUP/EBV values.

The current breeding-value equation is:

```text
u_hat = sigma_a2 * A * Z' * V^-1 * (y - X * beta)
```

This is intentionally dense and small-scale. Production sparse BLUP solves,
reliability, and prediction error variance remain planned.

## R Result Payload Contract

R head `e543cd7` defines an `hsquared_fit` contract with extractors looking for
these result names:

- `variance_components`
- `heritability`
- `breeding_values`
- `fixed_effects`
- `random_effects`
- `loglik`
- `df`
- `nobs`
- `predictions`
- `diagnostics`
- `converged`

Julia mirrors those names with:

```julia
result = result_payload(fit)
```

`result_payload(fit)` returns a `NamedTuple` with exactly those fields. This is
the bridge-facing result shape, not a claim that R live execution is wired.

## Current R Bridge Handoff

R head `b57b48e` parses the narrow v0.1 formula:

```r
hsquared(y ~ fixed + animal(1 | id, pedigree = ped), data = dat)
```

and builds an internal `hs_bridge_payload`. Current payload shape:

- `y`: numeric response vector;
- `X`: dense fixed-effect model matrix;
- `Z`: sparse `Matrix::dgCMatrix`, with one row per observation and one column
  per normalized pedigree ID;
- `Ainv`: `NULL` on the R side, with `metadata$ainv_status =
  "build_in_julia"`;
- `method`: `"REML"` or `"ML"`;
- `family`: `"gaussian"`;
- `ids`: normalized parent-before-offspring pedigree IDs;
- `pedigree`: `id`, `sire`, `dam`, `sire_index`, `dam_index`, and
  `original_order`;
- `metadata`: response name, fixed terms/contrasts, fixed column names,
  observed IDs, observed ID indices, `ainv_status`, and target strings.

The Julia target path is:

```julia
pedigree = normalize_pedigree(id, sire, dam)
Ainv = pedigree_inverse(pedigree)
spec = animal_model_spec(y, X, Z, Ainv; ids = ids, method = :REML)
fit = fit_animal_model(spec)
```

The Julia direct payload method also exists:

```julia
fit = fit_animal_model(y, X, Z, Ainv; ids = ids, method = :REML)
```

The next bridge task is cross-repo marshalling, not wider syntax. The Julia
tests now cover parent-index semantics, `ids` order, sparse `Z` dimensions,
Julia-side `Ainv`, and parity between spec dispatch and direct payload
dispatch. The actual R-to-Julia call still does not exist.

## Input Payload

- `y`: numeric response vector.
- `X`: fixed-effect design matrix.
- `Z`: sparse random-effect design matrix.
- `Ainv`: sparse additive relationship precision matrix.
- `method`: `:REML` or `:ML`.
- `family`: Gaussian only in v0.1.
- `ids`: encoded animal IDs.
- `metadata`: original names, levels, pedigree map, and engine provenance.

## Result Shape

The planned result should include:

- `converged`;
- `optimizer_status`;
- `loglik`;
- `reml_loglik`;
- `variance_components`;
- `fixed_effects`;
- `breeding_values`;
- `heritability`;
- `gradient_norm`;
- `iterations`;
- `warnings`;
- `id_map`.

Currently implemented bridge payload fields are the dense-path subset:
variance components, heritability, breeding values, fixed effects, random
effects, log-likelihood, degrees of freedom, number of observations,
predictions, diagnostics, and convergence flag. Gradient diagnostics,
reliability, prediction error variance, and sparse solver metadata remain
planned.

## Storage Policy

- Never silently densify large relationship matrices.
- Do not store dense `A` by default.
- Store minimal metadata by default.
- Keep full design matrices and factorizations behind explicit debug or save
  controls.
- Result objects must be marshalable into an R S3 object.

# Engine Contract

This file records the planned Julia-side v0.1 engine surface.

## Planned Entry Point

```julia
fit = fit_animal_model(y, X, Z, Ainv; method = :REML)
```

This direct payload entry point is still a placeholder. It throws a
not-implemented error.

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

## Current R Bridge Handoff

R head `d85f356` parses the narrow v0.1 formula:

```r
hsquared(y ~ fixed + animal(1 | id, pedigree = ped), data = dat)
```

and stops at the intended Julia target:

```julia
HSquared.fit_animal_model(y, X, Z, Ainv; method = :REML)
```

The next bridge task is payload parity, not wider syntax. The two twins need
tests that the R-produced `y`, `X`, `Z`, encoded IDs, pedigree metadata, family,
method, and Julia-side `Ainv` map to the same `AnimalModelSpec` assumptions
tested here.

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

## Storage Policy

- Never silently densify large relationship matrices.
- Do not store dense `A` by default.
- Store minimal metadata by default.
- Keep full design matrices and factorizations behind explicit debug or save
  controls.
- Result objects must be marshalable into an R S3 object.

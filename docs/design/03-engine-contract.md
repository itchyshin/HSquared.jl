# Engine Contract

This file records the planned Julia-side v0.1 engine surface.

## Planned Entry Point

```julia
fit = fit_animal_model(y, X, Z, Ainv; method = :REML)
```

This direct payload entry point is implemented as an experimental dense path.
It validates the payload with `animal_model_spec()` and dispatches to
`fit_variance_components()`.

## Implemented Control Metadata

```julia
HSControl(backend = :auto, accelerator = :auto)
HSControl(backend = :cpu, accelerator = :none)
HSControl(backend = :threads)
HSControl(backend = :cuda, accelerator = :cuda)
HSControl(backend = :amdgpu, accelerator = :amdgpu)
HSControl(backend = :metal, accelerator = :metal)
HSControl(backend = :oneapi, accelerator = :oneapi)
HSControl(accelerator = :gpu)
info = backend_info()
```

Julia mirrors the R twin's planned backend vocabulary from `hsquared` head
`5feac1f`:

- backend: `auto`, `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, `oneapi`;
- accelerator: `auto`, `none`, `gpu`, `cuda`, `amdgpu`, `metal`, `oneapi`.

This is control metadata only. `CPUBackend()` is the trusted always-available
path. `CUDABackend()`, `AMDGPUBackend()`, `MetalBackend()`, and
`OneAPIBackend()` are future optional-extension markers. There is no GPU
execution, backend benchmarking, device availability detection, or CPU/GPU
numerical agreement test yet.

`backend_info()` returns a typed `BackendInfo` container with six
`BackendInfoRow` records: `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, and
`oneapi`. Row fields are `backend`, `accelerator`, `requested`, `selectable`,
`execution_available`, `status`, and `note`. In the current package state all
rows have `selectable == true`, `execution_available == false`, and
`status == :planned`.

## Implemented Planned-Term Vocabulary

```julia
formula_status()
planned_model_terms()
planned_genomic_qtl_terms()
planned_quantgen_terms()
genomic()
single_step()
markers()
marker_scan()
qtl_scan()
permanent()
common_env()
maternal_genetic()
maternal_env()
paternal_genetic()
paternal_env()
cytoplasmic()
imprinting()
dominance()
epistasis()
relmat()
HSquared.precision()
```

These names mirror the R twin's planned formula markers from `hsquared` heads
`3c82c9a` and `10e8fd7`. They are vocabulary reservations only. Calls throw
planned-not-implemented errors and do not construct `AnimalModelSpec` objects,
genomic relationship specs, marker scans, QTL/eQTL scans, standard
quantitative-genetic extension specs, custom relationship/precision specs, or
fitted models.

`formula_status()` mirrors the R twin's 20-row grammar diagnostic with columns
`term`, `category`, `phase`, `syntax_status`, `fitting_status`, and
`current_behavior`. It is a status table only; it does not parse formulas,
construct model specs, or enable fitting.

The term `:precision` is reserved for bridge payload vocabulary. Direct Julia
calls should use `HSquared.precision()` because `Base.precision` already exists.

## Implemented Relationship Utility

```julia
ped = normalize_pedigree(ids, sire, dam)
Ainv = pedigree_inverse(ped)
```

This utility validates and sorts a pedigree, recodes known parents to integer
indices, keeps unknown parents as `0`, and builds a sparse inverse additive
relationship matrix. It does not fit a model.

The shared tiny Ainv fixture is the out-of-order calf/sire/dam pedigree. The
normalized ID order is `sire`, `dam`, `calf`; parent indices are sire
`0, 0, 1` and dam `0, 0, 2`; expected `Ainv` is:

```text
1.5   0.5  -1.0
0.5   1.5  -1.0
-1.0 -1.0   2.0
```

Julia tests this directly. R head `fe7e346` now records the same fixture and
green CI evidence from the R lane.

The first external pedigree-Ainv comparator is recorded in the R twin at head
`369d14a`. That optional test uses `nadiv::Mrode9`, documented by `nadiv` as
adapted from Mrode example 9.1, computes `nadiv::makeAinv()`, and compares it
with Julia `normalize_pedigree()` plus `pedigree_inverse()` at tolerance
`1e-10`.

This comparator covers pedigree inverse agreement only. It is not fitted Mrode
animal-model validation and does not validate EBVs, heritability, REML
estimands, or variance-component estimates.

## Implemented Data Container

```julia
data = HSData(
    phenotypes;
    id = :id,
    pedigree = pedigree,
    genotypes = genotypes,
    genotype_ids = genotype_ids,
    expression = expression,
)
ids = id_map(data)
```

This mirrors the R `hs_data()` input-container vocabulary from `hsquared` head
`644c75e`. It records exact-ID overlap across phenotypes, pedigree, genotype,
and expression inputs. It is in-memory only. It does not read file-backed
formats, build genomic relationships, or fit a model.

## Implemented Model-Spec Validator

```julia
spec = animal_model_spec(y, X, Z, Ainv; ids = ids, family = GaussianFamily(),
                         method = :REML)
```

This validates response/design dimensions, `Ainv`, encoded IDs, family, and
ML/REML method. It is bridge-ready groundwork for the R `hs_build_model_spec()`
payload. It still does not fit a model.

## Implemented Sparse CSC Bridge Utility

```julia
Z = sparse_csc_matrix(nrow, ncol, colptr, rowval, nzval; index_base = :zero)
```

This constructs a Julia `SparseMatrixCSC{Float64,Int}` from compressed sparse
column slots. It is intended for R `Matrix::dgCMatrix` payloads, where the
`p` and `i` slots are zero-based. The utility validates column pointers, row
indices, value lengths, and strictly increasing row indices within each column.
It is a marshalling helper only; it does not fit a model.

## Implemented Likelihood Evaluator

```julia
lik = gaussian_loglik(spec, sigma_a2, sigma_e2)
sparse_lik = sparse_reml_loglik(spec, sigma_a2, sigma_e2)
```

This evaluates the Gaussian ML or REML log-likelihood at supplied variance
components. The current implementation intentionally forms dense matrices so
the objective can be tested before the production sparse solver lands.
The keyword `max_dense_cells` guards this temporary path before dense covariance
or relationship matrices are formed.

It does not optimize variance components, compute EBVs, or return a fitted
model.

`sparse_reml_loglik()` evaluates the REML objective at supplied variance
components with the sparse Henderson mixed-model-equation determinant identity:

```text
log |V| + log |X' V^-1 X| = log |R| + log |G| + log |C|
```

where `C` is the Henderson coefficient matrix. Julia tests it against the dense
REML evaluator on tiny fixtures. It is a validation bridge toward the sparse
production optimizer, not variance-component estimation and not AI-REML.

## Experimental Henderson MME Solver

```julia
mme = henderson_mme(spec, sigma_a2, sigma_e2)
```

This solves Henderson's mixed-model equations at supplied positive additive and
residual variance components. It builds the equation system from sparse `X`,
`Z`, and `Ainv` inputs and returns fixed effects plus animal-effect
BLUPs/EBVs.

This is not variance-component estimation, not AI-REML, and not Mrode/comparator
validation. It is the first sparse equation-solve utility needed by the
production animal-model path.

## Experimental Dense Optimizer

```julia
fit = fit_variance_components(spec)
fit = fit_animal_model(spec)
```

For a validated `AnimalModelSpec`, Julia can now optimize the dense Gaussian
objective over positive additive and residual variance components using a
log-variance parameterization and `Optim.NelderMead()`.

This is a low-level validation path. It is not the production sparse animal
model engine, not AI-REML, and not the default public R fitting path.

The dense likelihood and optimizer accept:

```julia
gaussian_loglik(spec, sigma_a2, sigma_e2; max_dense_cells = 1_000_000)
fit_variance_components(spec; max_dense_cells = 1_000_000)
fit_animal_model(spec; max_dense_cells = 1_000_000)
```

The guard counts the dense covariance and relationship cells that the current
validation implementation would need. It is a stopgap to keep accidental large
dense runs out of the bridge path; it is not evidence of production-scale
fitting.

## Experimental Low-Level Extractors

```julia
variance_components(fit)
fixed_effects(fit)
breeding_values(fit)
fitted_values(fit)
heritability(fit)
prediction_error_variance(fit)
reliability(fit)
```

These operate on `AnimalModelFit` objects from the dense validation path.
`breeding_values(fit)` returns a `BreedingValues` object with encoded `ids` and
dense animal-effect BLUP/EBV values.

The current breeding-value equation is:

```text
u_hat = sigma_a2 * A * Z' * V^-1 * (y - X * beta)
```

This is intentionally dense and small-scale. Production sparse BLUP solves,
production sparse reliability, and production sparse prediction error variance
remain planned.

`prediction_error_variance(fit)` and `reliability(fit)` use the dense
mixed-model-equation inverse for tiny validation examples. They are not included
in `result_payload(fit)` until the R result contract grows those fields.

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

`result_payload(fit)` returns a `NamedTuple` with exactly those fields. Keep
these field names stable for the R bridge:

- `variance_components.sigma_a2`
- `variance_components.sigma_e2`
- `heritability`
- `breeding_values.ids`
- `breeding_values.values`
- `fixed_effects`
- `random_effects.animal.ids`
- `random_effects.animal.values`
- `loglik`
- `df`
- `nobs`
- `predictions`
- `diagnostics`
- `converged`

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

R head `c837f2d` adds an internal JuliaCall smoke test over this path:

```text
normalize_pedigree()
pedigree_inverse()
fit_animal_model(y, X, Z, Ainv; ids = ..., method = ...)
result_payload()
```

That smoke test activates the sibling local `HSquared.jl` checkout and returns
an internal `hsquared_fit` object. Public `hsquared()` still stops before
fitting, so this is bridge-contract validation rather than public model-fitting
support.

R head `9eabf0d` adds the first opt-in experimental user path:

```r
hsquared(..., control = hs_control(engine = "julia"))
```

The default remains `hs_control(engine = "validate")`, which parses, validates,
builds the payload, and stops. Julia-specific controls stay inside
`engine_control`, currently including `julia_project`, `initial`, and
`max_dense_cells`.

R head `78ba5ff` adds R-side `prediction_error_variance()` and `reliability()`
extractor contracts and future-compatible bridge normalization. Julia already
has dense experimental functions with those names, but they remain deliberately
excluded from `result_payload()` until both twins widen the bridge result tests
in lockstep. The expected future payload shape is `(ids = ..., values = ...)`
for each field.

R head `398e019` records green CI evidence for sparse `Z` bridge marshalling
through Julia `sparse_csc_matrix()`. The bridge now sends R
`Matrix::dgCMatrix` slots for `Z` and no longer passes `max_dense_cells`.

The next bridge tasks are relationship-object marshalling beyond `Z`, lockstep
PEV/reliability payload widening, Mrode validation, and `hs_data()` to `HSData`
marshalling parity. The Julia tests cover parent-index semantics, `ids` order,
sparse `Z` dimensions, Julia-side `Ainv`, CSC slot reconstruction, parity
between spec dispatch and direct payload dispatch, and supplied-variance
Henderson MME solving.

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
reliability and prediction error variance in the bridge payload, and sparse
solver metadata remain planned.

## Storage Policy

- Never silently densify large relationship matrices.
- Do not store dense `A` by default.
- Store minimal metadata by default.
- Keep full design matrices and factorizations behind explicit debug or save
  controls.
- Result objects must be marshalable into an R S3 object.

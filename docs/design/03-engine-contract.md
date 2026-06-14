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

R head `36efbf3` connects `hs_data()` to the R v0.1 parser. On the R side,
`model_spec()` and `hsquared()` can accept an `hs_data()` object as `data`,
read model variables from `data$phenotypes`, and resolve formula components
such as `pedigree = pedigree` from the bundle. The Julia bridge payload shape
does not change. Julia still receives the low-level `y`, `X`, sparse `Z`,
pedigree metadata, method, family, and target metadata contract rather than a
live `HSData` object.

R heads `74eef82` and `39ca990` add a parser-only shorthand:
`animal(1 | id)` can use the pedigree stored in
`data = hs_data(..., pedigree = ped)`. The explicit
`animal(1 | id, pedigree = ped)` spelling remains the shared portable contract.
This shorthand does not require a new Julia engine term, a new `HSData`
marshalling path, or a bridge payload change.

R head `e7fbb31` adds environment-key diagnostics to `hs_data()` and
`data_status()`. Julia mirrors this in `HSData` with `environment` and
`environment_id` metadata: if a key is supplied, it records phenotype
environment IDs, environment metadata IDs, missing metadata, environment-only
IDs, and duplicate environment IDs. This is metadata diagnostics only. It does
not join environment covariates into `X`, add environmental random or fixed
effects, change the R-Julia bridge payload, or fit multi-environment models.

R head `f067cd9` adds genotype-status diagnostics to `hs_data()` and
`data_status()`. Julia mirrors this in `HSData` with genotype component
diagnostics: genotype rows, matched genotype IDs, marker-column counts,
named/unnamed marker-column counts, duplicate named marker-column counts,
missing genotype value counts, and component type. This is metadata
diagnostics only. It does not parse PLINK/VCF, impute genotypes, construct
genomic relationship matrices, add marker terms, change the R-Julia bridge
payload, or fit genomic, QTL, GWAS, or eQTL models.

R head `06cdf59` adds expression-status diagnostics to `hs_data()` and
`data_status()`. Julia mirrors this in `HSData` with expression component
diagnostics: expression rows, matched expression IDs, feature counts, named
and unnamed feature counts, duplicate named feature counts, and component
type. This is metadata diagnostics only. It does not join expression features
into `X`, change the R-Julia bridge payload, fit eQTL or omics models, or run
GLLVM workflows.

R head `87888d9` adds annotation-feature diagnostics to `hs_data()` and
`data_status()`. Julia mirrors this in `HSData` with `annotation` and
`annotation_id` metadata: if a key is supplied, it records annotation feature
IDs, expression feature IDs, expression features with and without annotation
metadata, annotation-only features, and duplicate annotation feature IDs. This
is metadata diagnostics only. It does not join annotation covariates into `X`,
add eQTL/omics/GLLVM model terms, change the R-Julia bridge payload, or fit
omics workflows.

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

## Experimental Sparse REML Optimizer

```julia
fit = fit_sparse_reml(spec)
fit = fit_animal_model(spec; target = :sparse_reml)
```

For a validated REML `AnimalModelSpec`, Julia can optimize the sparse REML
objective over positive additive and residual variance components using the
same log-variance parameterization and `Optim.NelderMead()` style as the dense
validation optimizer.

This path calls `sparse_reml_loglik()` inside the objective and records
`target = :sparse_reml`, `dense_validation_path = false`, `sparse_mme_path =
true`, and `variance_components_source = :estimated_sparse_reml_validation` in
`fit_diagnostics()`. It is REML-only. It is not the default public R fitting
path, not a production sparse solver, and not fitted Mrode or ASReml parity
evidence.

## Experimental Multivariate REML

```julia
fit = fit_multivariate_reml(Y, X, Z, Ainv)
fit = fit_multivariate_reml(Y, X, Z, Ainv;
    genetic_structure = :factor_analytic,
    rank = 1,
)
```

The multivariate engine accepts a wide `Y` matrix (`records × traits`), shared
fixed-effect and incidence designs, and a relationship inverse. The default
estimator uses unstructured genetic and residual trait covariance matrices.
The Phase-4B structured path constrains only the genetic covariance:
`:diagonal` gives `diag(σ²)`, `:lowrank` gives `ΛΛ'`, and `:factor_analytic`
gives `ΛΛ' + Ψ`; residual `R0` remains unstructured.

For `:lowrank` and `:factor_analytic`, returned `genetic_loadings` are
sign-canonicalized as engine metadata: each factor column is multiplied by `-1`
when needed so the largest-absolute loading in that column is non-negative.
This convention is deterministic but not a rotation or lower-triangular
identification constraint; rank-`K > 1` loading columns remain
rotation-nonunique.

The multivariate result accessors are Julia-side wrappers over existing
`NamedTuple` fields:

```julia
variance_components(fit)
fixed_effects(fit)
breeding_values(fit)
EBV(fit)
BLUP(fit)
heritability(fit)   # REML results only
```

They return copies of matrix/vector fields and are guarded so unrelated
`NamedTuple`s fail loudly. They do not add new result fields.

This is a direct Julia engine API only. It does not change the v0.1 R bridge
payload, `result_payload()`, or the R formula grammar. Any future R
multi-trait / covariance-structure syntax must be designed in the R lane and
then mirrored here in lockstep.

## Experimental Average-Information REML

```julia
fit = fit_ai_reml(spec)
fit = fit_animal_model(spec; target = :ai_reml)
```

`fit_ai_reml` estimates the two variance components by average-information (AI)
REML: each iteration solves the sparse Henderson MME, reads the
variance-component score from the BLUP solution and the Takahashi selected
inverse, forms the average-information matrix from two working-variate re-solves
that reuse the Cholesky factor, and takes an AI/Newton step (with step-halving to
keep variances positive). It records `target = :ai_reml`, `sparse_mme_path =
true`, and `variance_components_source = :estimated_ai_reml`.

It is REML-only, two-component, and Gaussian. It is validated to recover the same
optimum as the dense and sparse NelderMead optimizers, and its AI matrix matches
the observed information (ratio ~0.99 on a 250-animal simulation), so it is a
valid Newton metric for this model. The AI form is exact only for the Gaussian
linear mixed model; non-Gaussian / Laplace-approximated models require
observed-information Newton instead. It is experimental: not externally
comparator-validated, not large-pedigree or boundary hardened, and not the public
default.

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

The shared supplied-variance validation fixture from the R twin uses:

- IDs `founder_a`, `founder_b`, `animal_1`, `animal_2`, `animal_3`;
- supplied variance components `sigma_a2 = 1.2` and `sigma_e2 = 0.8`;
- expected fixed effects `(Intercept) = 3.898701298701298` and
  `x = 0.6454545454545471`;
- expected EBVs `0`, `0`, `-0.054545454545454695`,
  `0.05454545454545385`, and `0.8571428571428561`;
- expected fitted values `3.844155844155843`, `4.5987012987012985`,
  `4.755844155844154`, and `5.401298701298701`;
- `h2 = 0.6`.

R head `ca8bce1` records an independent R MME reference and a live Julia
comparison when a sibling `HSquared.jl` checkout is available. This is
supplied-variance validation only. It is not variance-component estimation,
AI-REML, fitted Mrode validation, external fitted-model parity, or production
sparse fitting.

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
fit_diagnostics(fit)
breeding_values(fit)
EBV(fit)
BLUP(fit)
fitted_values(fit)
heritability(fit)
prediction_error_variance(fit)
reliability(fit)
accuracy(fit)
```

These operate on `AnimalModelFit` objects from the dense validation path. The
variance-component, heritability, PEV, and reliability methods also accept
supplied-variance `HendersonMMEResult` objects from `henderson_mme()`.
`breeding_values(fit)` and `fitted_values(fit)` solve Henderson's MME at the
fit's variance components. `breeding_values(fit)` returns a `BreedingValues`
object with encoded `ids` and animal-effect BLUP/EBV values; `fitted_values(fit)`
returns `X * beta + Z * u` from the same supplied-variance solution.

The current breeding-value equation path is:

```text
[X'R^-1X  X'R^-1Z; Z'R^-1X  Z'R^-1Z + Ainv / sigma_a2] [beta; u] =
[X'R^-1y; Z'R^-1y]
```

This is still an experimental low-level extractor path because variance
components come from the current validation fit path, but EBV and fitted-value
extraction now use the same Henderson MME solve as the supplied-variance MME
utility. Production sparse fitting remains planned; experimental sparse
prediction error variance and reliability are available via the `method =
:selinv` selected-inversion path described below.

`prediction_error_variance(fit)` and `reliability(fit)` use the dense
mixed-model-equation inverse for tiny validation examples. The same extractor
names can be used on a supplied-variance `mme` result. `variance_components(mme)`
returns the supplied values and `heritability(mme)` computes the simple
univariate ratio from those supplied values. `EBV()` and `BLUP()` are aliases
for `breeding_values()`. `accuracy()` is a checked square-root transformation
of `reliability()` and errors if reliability values are non-finite or outside
`[0, 1]`; it does not add independent accuracy validation. These fields are
not included in the base `result_payload(fit)` contract.

`prediction_error_variance` and `reliability` accept `method = :dense` (default)
or `method = :selinv`. The `:selinv` path computes the diagonal of the sparse
Henderson MME coefficient-matrix inverse with a Takahashi selected inverse
(`takahashi_diag` / `takahashi_selinv`, adapted from DRM.jl under the MIT
License) in `O(nnz(L))`. The selected inverse is exact only at the `L+Lᵀ`
sparsity pattern; the diagonal — and therefore PEV — is always in pattern and is
exact. Both methods use the identical coefficient matrix, so they agree to
machine precision on tiny and Mrode9-shaped fixtures. The default stays `:dense`
and `result_payload()` is unchanged; this is an experimental sparse path, not
large-pedigree or comparator-validated production reliability.

As of R heads `8235289` and `d7e8914`, the R twin may enrich opt-in tiny/local
Julia bridge results by calling exported Julia extractors:

```julia
prediction_error_variance(fit)
reliability(fit)
prediction_error_variance(mme)
reliability(mme)
```

and merging `(ids = ..., values = ...)` fields on the R side when those
functions are available and applicable. This preserves the compact base
`result_payload()` contract. It is bridge validation for tiny dense fits and
supplied-variance MME results, not production sparse PEV or production sparse
reliability.

R head `afa25f1` adds R-side `EBV()`, `BLUP()`, and `accuracy()` extractor
ergonomics. Julia mirrors the vocabulary locally as aliases and derived output
only; there is no new bridge payload requirement.

R head `21161a5` documents R-side multivariate extractor examples. Julia mirrors
the same local vocabulary for multivariate engine results (`NamedTuple`s) with
copy-returning accessors over existing fields. This is accessor ergonomics only:
`result_payload()` remains compact and no R bridge payload field is required.

R head `060988d` adds R-side `fit_diagnostics()` over existing result-payload
metadata. Julia mirrors this as:

```julia
fit_diagnostics(fit)
fit_diagnostics(mme)
```

The Julia helper returns a compact `NamedTuple` with metadata already stored on
`AnimalModelFit` or `HendersonMMEResult`, including engine, result type, target,
method, family, convergence flag, optimizer status, iterations, log-likelihood
or `nothing`, degrees of freedom or `nothing`, observation count, path flags,
and variance-component source. It does not refit, solve equations, compute
PEV/reliability, probe backends, or widen `result_payload()`.

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

The explicit supplied-variance Henderson target is available in Julia as a
convenience over `animal_model_spec()` plus `henderson_mme()`:

```julia
mme = fit_animal_model(
    spec;
    target = :henderson_mme,
    variance_components = (sigma_a2 = 1.2, sigma_e2 = 0.8),
)
```

The direct payload method accepts the same target and supplied variance
components. This returns `HendersonMMEResult`, not `AnimalModelFit`; it has no
log-likelihood, AIC, `df`, optimizer output, or variance-component estimation.

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
extractor contracts and future-compatible bridge normalization. R head
`8235289` enriches the opt-in tiny/local Julia bridge result by calling the
exported Julia extractors when available and merging `(ids = ..., values = ...)`
fields on the R side. Julia deliberately keeps `result_payload()` compact.
Future changes to required base payload fields still need lockstep R and Julia
tests.

R head `d7e8914` extends the same opportunistic enrichment to the explicit
supplied-variance `target = "henderson_mme"` bridge path when
`prediction_error_variance(mme)` and `reliability(mme)` are applicable. That
target still has no log-likelihood, AIC, `df`, optimizer output,
variance-component estimation, AI-REML, fitted Mrode output validation, or
production sparse PEV/reliability claim.

R head `398e019` records green CI evidence for sparse `Z` bridge marshalling
through Julia `sparse_csc_matrix()`. The bridge now sends R
`Matrix::dgCMatrix` slots for `Z` and no longer passes `max_dense_cells`.

R head `bacef9c` adds exported `model_spec()` as a preview surface for the same
v0.1 formula-to-bridge contract. It validates `animal(1 | id, pedigree = ped)`,
builds the same internal bridge payload, and reports response/family/method,
fixed-effect columns, sparse `Z` dimensions, normalized animal IDs, observed ID
mapping, pedigree founder count, and Julia targets. It does not fit models or
execute Julia.

R head `36efbf3` allows both `model_spec()` and `hsquared()` to take an
`hs_data()` object as `data` for this same contract. Model variables are read
from `data$phenotypes`, formula objects such as `pedigree` can be resolved from
the bundle, and the bridge payload shape remains unchanged.

R heads `74eef82` and `39ca990` allow the R parser shorthand
`animal(1 | id)` when the pedigree is already stored in
`data = hs_data(..., pedigree = ped)`. The payload remains the same as the
explicit `animal(1 | id, pedigree = ped)` contract.

R head `00b9e33` adds an explicit opt-in supplied-variance Henderson MME bridge
target:

```r
hsquared(
  y ~ fixed + animal(1 | id, pedigree = ped),
  data = dat,
  family = gaussian(),
  control = hs_control(
    engine = "julia",
    engine_control = list(
      target = "henderson_mme",
      variance_components = c(sigma_a2 = 1.2, sigma_e2 = 0.8)
    )
  )
)
```

That R path calls Julia `normalize_pedigree()`, `pedigree_inverse()`,
`animal_model_spec()`, and `henderson_mme()`. R normalizes fixed effects,
EBVs/BLUPs, fitted values, supplied variance components, simple `h2`, `nobs`,
diagnostics, and convergence status into `hsquared_fit`. It deliberately omits
`logLik`, AIC, `df`, and optimizer output; `logLik(fit)` is expected to error
for this target. This is supplied-variance validation-scale bridge execution,
not variance-component estimation, AI-REML, Mrode fitted-output validation, or
production sparse fitting.

The next bridge tasks are relationship-object marshalling beyond `Z`, deciding
whether PEV/reliability should ever become required base payload fields, Mrode
validation, and live Julia `HSData` object marshalling parity. The Julia tests
cover parent-index semantics, `ids` order, sparse `Z` dimensions, Julia-side
`Ainv`, CSC slot reconstruction, parity between spec dispatch and direct
payload dispatch, and supplied-variance Henderson MME solving.

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

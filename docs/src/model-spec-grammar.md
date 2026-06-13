# Model Spec Grammar

This page mirrors the R twin's formula-grammar status map for the Julia engine.
It is a status page, not an implementation promise.

The R package owns formula capture and user-facing syntax. `HSquared.jl` owns
the validated engine payloads and numeric computations. Terms listed as
reserved are planned vocabulary only until a bridge payload contract, tests,
validation evidence, and status rows exist.

## Parsed Today

The only R formula shape parsed into the current v0.1 bridge contract is:

```r
y ~ fixed + animal(1 | id, pedigree = ped)
```

Julia receives the corresponding low-level engine pieces:

```julia
spec = animal_model_spec(y, X, Z, Ainv; ids = ids, method = :REML)
```

The Julia side can validate this spec, evaluate dense and sparse objective
pieces, and run experimental low-level dense validation paths. Production sparse
animal-model fitting is still planned.

On the R side, `model_spec()` now previews the same v0.1 formula-to-bridge
contract without fitting or executing Julia. It reports response, family,
method, fixed-effect columns, sparse `Z` dimensions, normalized animal IDs,
observed ID mapping, pedigree founder count, and Julia targets.

## Status Diagnostic

`formula_status()` returns the same status categories as the R twin's
diagnostic. It is a table of current grammar state, not a formula parser and
not a fitting helper.

| term | category | phase | syntax_status | fitting_status | current_behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `animal(1 \| id, pedigree = ped)` | v0.1 animal model | Phase 1 | parsed | experimental tiny bridge only | Validated by the R parser; default `hsquared()` stops before general fitting. |
| `permanent(1 \| id)` | standard quantitative genetics | Phase 2 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `common_env(1 \| group)` | standard quantitative genetics | Phase 2 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `maternal_genetic(1 \| dam, pedigree = ped)` | standard quantitative genetics | Phase 2 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `maternal_env(1 \| dam)` | standard quantitative genetics | Phase 2 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `paternal_genetic(1 \| sire, pedigree = ped)` | standard quantitative genetics | Phase 2 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `paternal_env(1 \| sire)` | standard quantitative genetics | Phase 2 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `cytoplasmic(1 \| maternal_line)` | inheritance and relationship kernels | Phase 3+ | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `imprinting(1 \| id, pedigree = ped, parent = "maternal")` | inheritance and relationship kernels | Phase 3+ | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `dominance(1 \| id, pedigree = ped)` | inheritance and relationship kernels | Phase 3+ | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `epistasis(1 \| id, pedigree = ped)` | inheritance and relationship kernels | Phase 3+ | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `relmat(1 \| id, K = K)` | inheritance and relationship kernels | Phase 3+ | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `precision(1 \| id, Q = Q)` | inheritance and relationship kernels | Phase 3+ | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `genomic(1 \| id, Ginv = Ginv)` | genomic and marker models | Phase 5 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `single_step(1 \| id, Hinv = Hinv)` | genomic and marker models | Phase 5 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `markers(M, model = "random")` | genomic and marker models | Phase 5 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `marker_scan(M, map = marker_map)` | genomic and marker models | Phase 5 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `qtl_scan(position, genotype_probs = probs)` | genomic and marker models | Phase 5 | reserved | not available | Exported as an inert marker; `hsquared()` errors as planned, not implemented. |
| `animal(trait \| id, pedigree = ped, cov = us())` | multivariate and factor analytic | Phase 3-4 | planned | not available | Roadmap syntax; the v0.1 `animal()` parser rejects trait and cov arguments. |
| `animal(trait \| id, pedigree = ped, cov = fa(K = 2))` | multivariate and factor analytic | Phase 3-4 | planned | not available | Roadmap syntax; the v0.1 `animal()` parser rejects trait and cov arguments. |

In direct Julia code, the custom precision-kernel marker is qualified as
`HSquared.precision()` because `Base.precision` already exists. The grammar
status table keeps the R formula spelling `precision(1 | id, Q = Q)`.

## Reserved Phase 2+ Quantitative-Genetic Terms

These names are reserved in both twins:

```julia
planned_quantgen_terms()
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

They currently throw planned-not-implemented errors. They do not construct
model specs, validate relationship or precision matrices, or fit permanent
environment, common environment, maternal/paternal, cytoplasmic, imprinting,
dominance, epistasis, custom relationship, or custom precision-kernel models.

`HSquared.precision()` is qualified because Julia `Base` already exports
`precision`. The reserved bridge term remains `:precision`, matching R.

## Reserved Genomic, Marker, And QTL Terms

These names are reserved in both twins:

```julia
planned_genomic_qtl_terms()
genomic()
single_step()
markers()
marker_scan()
qtl_scan()
```

They currently throw planned-not-implemented errors. They do not construct
genomic relationship specs, fit GBLUP/single-step models, estimate marker
effects, run marker scans, or run QTL/eQTL scans.

## Planned Multivariate And Factor-Analytic Syntax

These are roadmap examples only:

```r
y ~ trait + trait:sex +
  animal(trait | id, pedigree = ped, cov = us()) +
  residual(trait | unit, cov = us())

y ~ trait + trait:sex +
  animal(trait | id, pedigree = ped, cov = fa(K = 2))
```

No Julia model-spec payload for multivariate or factor-analytic animal models
exists yet.

## Error Rule

Unsupported syntax should fail early as planned, not implemented. It must not
be silently treated as a fixed effect, an ordinary random effect, or an
implemented Julia engine capability.

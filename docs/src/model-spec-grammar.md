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

# Model Spec Grammar

This is the Julia engine's model-spec and planning-marker status page. It is
not an implementation promise or an authoritative R formula grammar.

The R package owns formula capture and user-facing syntax. `HSquared.jl` owns
the validated engine payloads and numeric computations. Apart from the
explicitly named v0.1 bridge contract below, R-style spellings on this page are
comparison notation for Julia-local reserved markers. Check
[hsquared's formula status](https://itchyshin.github.io/hsquared/reference/formula_status.html)
for what the R parser currently accepts.

## Parsed Today

The canonical portable R formula shape parsed into the current v0.1 bridge
contract is:

```r
y ~ fixed + animal(1 | id, pedigree = ped)
```

When `data = hs_data(..., pedigree = ped)` supplies the pedigree bundle, the R
parser also accepts the shorthand:

```r
y ~ fixed + animal(1 | id)
```

That shorthand fills the same explicit-pedigree contract on the R side. It is
not a new Julia engine term and it does not change the bridge payload.

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

`formula_status()` is a Julia diagnostic for the engine's current and planned
marker vocabulary. It is not a formula parser or fitting helper, and its
reserved rows do not claim that the R parser accepts or rejects the displayed
R-style spellings.

| term | category | phase | syntax_status | fitting_status | current_behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `animal(1 \| id, pedigree = ped)` | v0.1 animal model | Phase 1 | parsed | Julia bridge diagnostic | The R default `hsquared()` owns its public fitting route; this Julia row records the v0.1 bridge shape, not a limit on the R frontier. |
| `permanent(1 \| id)` | standard quantitative genetics | Phase 2 | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `common_env(1 \| group)` | standard quantitative genetics | Phase 2 | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; consult the R package for its live route and fitting status. |
| `maternal_genetic(1 \| dam, pedigree = ped)` | standard quantitative genetics | Phase 2 | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; consult the R package for its live route and fitting status. |
| `maternal_env(1 \| dam)` | standard quantitative genetics | Phase 2 | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `paternal_genetic(1 \| sire, pedigree = ped)` | standard quantitative genetics | Phase 2 | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `paternal_env(1 \| sire)` | standard quantitative genetics | Phase 2 | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `cytoplasmic(1 \| maternal_line)` | inheritance and relationship kernels | Phase 3+ | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `imprinting(1 \| id, pedigree = ped, parent = "maternal")` | inheritance and relationship kernels | Phase 3+ | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `dominance(1 \| id, pedigree = ped)` | inheritance and relationship kernels | Phase 3+ | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `epistasis(1 \| id, pedigree = ped)` | inheritance and relationship kernels | Phase 3+ | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `relmat(1 \| id, K = K)` | inheritance and relationship kernels | Phase 3+ | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `precision(1 \| id, Q = Q)` | inheritance and relationship kernels | Phase 3+ | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `genomic(1 \| id, Ginv = Ginv)` | genomic and marker models | Phase 5 | Julia-local reserved marker | no Julia formula parser | This row does not state R parser behavior: narrow R genomic GREML is separately default-routed and covered at validation scale; other genomic routes retain their own status. |
| `single_step(1 \| id, Hinv = Hinv)` | genomic and marker models | Phase 5 | Julia-local reserved marker | no Julia formula parser | This row does not state R parser behavior: supplied/constructed R single-step routes remain opt-in partial, while the narrow Julia Hinv cell is engine-covered only. |
| `markers(M, model = "random")` | genomic and marker models | Phase 5 | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `marker_scan(M, map = marker_map)` | genomic and marker models | Phase 5 | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `qtl_scan(position, genotype_probs = probs)` | genomic and marker models | Phase 5 | Julia-local reserved API | no Julia formula parser | Inert Julia diagnostic marker only; it makes no assertion about the live R formula frontier. |
| `animal(trait \| id, pedigree = ped, cov = us())` | multivariate and factor analytic | Phase 3-4 | Julia roadmap notation | no Julia formula parser | This diagnostic row is not a statement about the R formula frontier; check the R route ledger for live multivariate support. |
| `animal(trait \| id, pedigree = ped, cov = fa(K = 2))` | multivariate and factor analytic | Phase 3-4 | Julia roadmap notation | no Julia formula parser | This diagnostic row is not a statement about the R formula frontier; check the R route ledger for live FA support. |

In direct Julia code, the custom precision-kernel marker is qualified as
`HSquared.precision()` because `Base.precision` already exists. The grammar
status table keeps the R formula spelling `precision(1 | id, Q = Q)`.

The R-side `animal(1 | id)` shorthand for `data = hs_data(..., pedigree = ped)`
is intentionally not a separate Julia status row. It is an input default that
normalizes to the explicit `animal(1 | id, pedigree = ped)` contract.

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

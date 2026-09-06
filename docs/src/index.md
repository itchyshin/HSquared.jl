```@raw html
---
layout: home

hero:
  # VitePress renders hero name/text/tagline with v-html, so the wordmark can
  # be two-tone without a theme component or a DOM patch. DRM.jl's near-black
  # `DRM` + coloured `.jl` is the single move that stops the brand line and the
  # question reading as one block; this is the same move in our teal.
  name: "HSquared<span class='hs-jl'>.jl</span>"
  text: "How much is genetic?"
  tagline: "The Julia engine behind hsquared: sparse pedigrees, REML, EBVs, and heritability extractors. Experimental 0.8.0 — an engine, not the package you type a formula into."
  image:
    src: /logo.png
    alt: "HSquared.jl hex mark (PROPOSAL): deep teal hexagon, three hollow gold pedigree rings, h-squared. Not a settled brand."
  actions:
    - theme: brand
      text: First engine utility
      link: /quickstart
    - theme: alt
      text: What is covered today?
      link: /validation-status
    - theme: alt
      text: R users start here
      link: https://itchyshin.github.io/hsquared/

features:
  - title: "The formula lives in R"
    details: "y ~ sex + age + animal(1 | id, pedigree = ped) is the applied path in hsquared. These pages document the engine underneath it."
  - title: "Seven covered routes"
    details: "public_covered_count is 7 at validation scale. Partial and planned rows stay labelled; the version tracks covered capability, not maturity."
  - title: "Point estimates, honestly"
    details: "Report where the route is covered. Standard errors and intervals are experimental and not coverage-calibrated."
  - title: "A twin, not a port"
    details: "MIT-licensed engine; hsquared owns the applied language. Not ASReml, not a GLLVM, not a production sparse pipeline."
---
```

!!! warning "Experimental 0.8.0 — not production"
    Version number tracks covered capability, not maturity. **Not** in the
    Julia General registry. An earlier attempt
    ([General PR #166969](https://github.com/JuliaRegistries/General/pull/166969),
    v0.5.0) was closed. Install with `Pkg.add(url=...)` only — do **not**
    use `Pkg.add("HSquared")` by name.
    `public_covered_count` is **7** (R-public; G10 multivariate + 0.7 genomic GREML default-route).
    **0.9 is not released.**

I used language-model tools (Claude, Codex, and Cursor) on substantial
parts of this engine: source, tests, and docs. I review the code I ship,
and I am responsible for it. Tests and Documenter run in CI. This
release is experimental 0.8.0. It is not a production engine and it is
not version 1.0.

`HSquared.jl` is the Julia engine twin of the R package
[hsquared](https://itchyshin.github.io/hsquared/).
This is not the package you type a formula into.

R users: start at `hsquared(y ~ sex + age + animal(1 | id, pedigree = ped))`,
or the [hsquared pkgdown site](https://itchyshin.github.io/hsquared/).
That is the applied-user interface. These pages document the engine.

`hsquared()` here still throws. Lower-level `fit_animal_model` and
`fit_ai_reml` exist as experimental engine paths, not the applied
default. Read [Get started](quickstart.md) and `validation_status()`
before treating any path as production.

## What works today

This repository is still early. It has experimental validation-scale
engine utilities — pedigree checks, sparse `Ainv`, low-level REML and
Henderson MME solves, and extractors for heritability, EBVs, and PEV.
Those are engine utilities, not a public formula API and not a
production sparse pipeline. Engine `covered` rows are **not**
R-public covered. See [Validation status](validation-status.md) for the
live ladder; do not read this page as a capability dump.

## Install

HSquared is **not** in the Julia General registry. Do **not** use
`Pkg.add("HSquared")` by name.

```julia
using Pkg
Pkg.add(url = "https://github.com/itchyshin/HSquared.jl")
```

## First engine utility

```@example pedigree
using HSquared

ped = normalize_pedigree(
    ["calf", "sire", "dam"],
    ["sire", "0", "0"],
    ["dam", "0", "0"],
)

ped.ids
```

```@example pedigree
Ainv = pedigree_inverse(ped)
Matrix(Ainv)
```

## Twin boundary

- `hsquared` is the R-facing package identity: formulas, validation, user
  documentation, S3 methods, plotting, and bridge calls.
- `HSquared.jl` is the computational engine: sparse relationship matrices,
  likelihoods, solvers, EBVs, G matrices, and low-level diagnostics.

The R package can describe planned syntax, but public executable examples
must not claim model fitting until the Julia engine implements and
validates it. `public_covered_count` is **7** and counts the R-public
covered surface only.

## Start here

- [Get started](quickstart.md)
- [Validation status](validation-status.md)
- [Pedigrees and Ainv](pedigree-ainv.md)
- [Audience and comparators](audience-comparators.md)
- [Reference](api.md)

Developer dashboard (not a first-click path): [Mission control](mission-control.md).

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
      text: "R users: get started in hsquared"
      link: https://itchyshin.github.io/hsquared/
    - theme: alt
      text: First engine utility
      link: /quickstart
    - theme: alt
      text: Choose an engine route
      link: /standard-qg-models

features:
  - title: "1. Get started"
    details: "For applied analysis, begin in hsquared. This site starts with engine utilities."
    link: https://itchyshin.github.io/hsquared/
    linkText: "Start in hsquared"
  - title: "2. Choose a model"
    details: "Read the route scope and engine requirement before running a fit."
    link: /standard-qg-models
    linkText: "Choose a route"
  - title: "3. Fit"
    details: "Run the low-level experimental engine fit; keep opt-in routes explicit."
    link: /quickstart#Fit-Variance-Components-Experimentally
    linkText: "Experimental engine fit"
  - title: "4. Diagnose"
    details: "Check status and diagnostics before extracting or reporting an estimate."
    link: /validation-status
    linkText: "Read live status"
  - title: "5. Report"
    details: "Report point estimates only within the stated route scope."
    link: /twin-boundary
    linkText: "Check reporting scope"
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
default. Choose a route before fitting, then read
[Validation status](validation-status.md) before treating any result as
production-ready or reportable.

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

## Continue by task

```@raw html
<ol start="1">
  <li><a href="./quickstart">Get started</a> with an engine utility, or use <a href="https://itchyshin.github.io/hsquared/">hsquared</a> for the applied formula.</li>
  <li><a href="./standard-qg-models">Choose a model</a> and read its scope before fitting.</li>
  <li><a href="./fitting-at-scale">Fit</a> with the route's explicit engine controls.</li>
  <li><a href="./validation-status">Diagnose</a> the route before extracting an estimate.</li>
  <li><a href="./twin-boundary">Report</a> only the point-estimate claim the route supports.</li>
</ol>
```

The [progression and evidence](progression-evidence.md) page separates this
history from release status. [Mission control](mission-control.md) is a
developer dashboard, not a first-click applied path.

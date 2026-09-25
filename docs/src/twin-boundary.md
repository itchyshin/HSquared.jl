# Twin boundary: R public package vs Julia engine

HSquared.jl and `hsquared` are sibling packages with different jobs. The
boundary is part of the public status contract:

- **`hsquared` is the R-facing public package.** It owns formula syntax,
  input validation, user-facing documentation, S3 methods, plotting, and the
  R-to-Julia bridge.
- **HSquared.jl is the Julia computational engine.** It owns relationship
  matrices, likelihoods, solvers, EBVs, G matrices, and low-level diagnostics.

An engine capability is not automatically an R capability. A Julia function
may be implemented, tested, and marked `covered` in the engine's
`validation_status()` while the corresponding R formula, payload mapping,
user documentation, and R-side evidence remain planned or partial. In that
case the engine result is **engine-covered, not R-public-covered**.

## Current 0.9 honesty fence

The current `public_covered_count` is **7**. It counts the R-public covered
surface; it is not the number of engine rows marked `covered`. The count must
not increase merely because an engine-only validation row is promoted.

The current state is an **experimental 0.9.0 release**. It does not claim
production readiness or a covered-status flip.

In particular:

- **Factor-analytic covariance (`V4-FA`)** is covered only for the Julia S4
  cell: `t=4`, `K=1`, positive Ledermann slack, interior uniqueness, and
  rotation-invariant `G`/`R`/`ψ` (not loadings or other `(t,K)` cells). It is
  validation-scale and opt-in; R factor-analytic grammar and payload
  activation remain open.
- **Single-step (`V2-SSHINV`)** is covered only for Julia H-scale
  `σ²a/σ²e` under ordinary defaults (`τ=ω=1`, zero blend/ridge) and the
  teaching kernel `G=A₂₂+0.05I`. It is validation-scale and opt-in; R
  `single_step()` remains opt-in partial and does not inherit the engine row's
  covered status. `AGHmatrix` supports H/Hinv construction only; fitted
  same-estimand comparator parity remains debt.

See [Validation status](validation-status.md) and the
[roadmap](roadmap.md) for the evidence and remaining gates. For the
applied-user interface, use the
[hsquared pkgdown site](https://itchyshin.github.io/hsquared/).

## How to read a covered row

When a status row says `covered`, check all three scopes:

1. **Engine scope:** what Julia computes and the validation evidence attached
   to that row.
2. **R-public scope:** whether `hsquared` exposes the syntax and routes it
   through the bridge.
3. **Default scope:** whether the route is public/default, or remains opt-in
   and experimental.

Only the second scope changes `public_covered_count`, and only after the
cross-twin bridge and R-side evidence are complete. Engine coverage alone is
not permission to describe an R formula as fitted or production-ready.

## Twin contract rule

Where one twin states an input contract, an output definition, an
identifiability claim, or an exactness claim, the other twin's corresponding
page must state it or link to it. A contract stated once, silently, on only
one side of the boundary is not a twin contract — it is a claim the other
twin's reader has no way to find. This applies regardless of which twin the
claim originates in: an engine docstring that narrows an equivalence (e.g. an
exactness claim that holds only before regularization) must be reachable from
the R-facing page that reports the same result, and an R-side input
requirement (e.g. a required default or a validated range) must be reachable
from the engine function that consumes it.

The matching R-side half lives in
[hsquared: Twin boundary](https://itchyshin.github.io/hsquared/articles/twin-boundary.html).
Readers on either site should follow the link when a claim spans the bridge.

## Documentation map (applied journey)

Both sites follow the same five-step reader journey (Get started → Choose → Fit →
Diagnose → Report). pkgdown owns formula examples; Documenter owns engine utilities
and live `validation_status()` tables.

| Step | hsquared (pkgdown) | HSquared.jl (Documenter) |
| --- | --- | --- |
| Get started | [Getting started](https://itchyshin.github.io/hsquared/articles/hsquared.html) | [Quick start](quickstart.md) |
| Choose a model | [Fitting models](https://itchyshin.github.io/hsquared/articles/fitting-models.html), [Formula grammar](https://itchyshin.github.io/hsquared/articles/formula-grammar.html), [Multivariate](https://itchyshin.github.io/hsquared/articles/multivariate.html), [Genomic prediction](https://itchyshin.github.io/hsquared/articles/genomic-prediction.html) | [Standard QG models](standard-qg-models.md), [Model spec grammar](model-spec-grammar.md), [Multivariate models](multivariate-models.md), [Genomic models](genomic-models.md) |
| Fit | (same fitting-models article; default `hsquared()`) | [Quick start](quickstart.md#Fit-Variance-Components-Experimentally), [Fitting at scale](fitting-at-scale.md) |
| Diagnose | [Visualizing models](https://itchyshin.github.io/hsquared/articles/visualizing-models.html), [`validation_status()`](https://itchyshin.github.io/hsquared/reference/validation_status.html) | [Validation status](validation-status.md) |
| Report | [Can I fit and report this?](https://itchyshin.github.io/hsquared/articles/current-limits.html), [Twin boundary](https://itchyshin.github.io/hsquared/articles/twin-boundary.html) | [Twin boundary](twin-boundary.md), [Progression and evidence](progression-evidence.md) |

Intentional asymmetry: R articles include comparator vignettes, Gryphon, QTL/GWAS
status, inheritance systems, and GPU roadmap slices with no Julia mirror page yet.
Julia [Developer](roadmap.md) routes hold backend roadmap detail R users rarely need
on first read. Engine API lookup:
[Reference (stable API)](https://itchyshin.github.io/HSquared.jl/stable/api.html)
(`/dev/reference/` redirects there after deploy).

## Reporting route-scoped results

Use the R package to decide what an applied workflow exposes. A point estimate
may be reported only within the route scope stated in
[Validation status](validation-status.md); experimental does not itself grant
reporting permission. Standard errors and intervals do not share a single
coverage claim: inspect the named route's evidence and limits first.

For the history behind a label, see [Progression and evidence](progression-evidence.md).
For a comparison with established software, see
[Audience and comparators](audience-comparators.md).

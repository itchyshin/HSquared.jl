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

The current state is an **experimental 0.9.0 candidate**, not a public release.
It does not claim production readiness or a covered-status flip.

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

## Reporting route-scoped results

Use the R package to decide what an applied workflow exposes. A point estimate
may be reported only within the route scope stated in
[Validation status](validation-status.md); experimental does not itself grant
reporting permission. Standard errors and intervals do not share a single
coverage claim: inspect the named route's evidence and limits first.

For the history behind a label, see [Progression and evidence](progression-evidence.md).
For a comparison with established software, see
[Audience and comparators](audience-comparators.md).

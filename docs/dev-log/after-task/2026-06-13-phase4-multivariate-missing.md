# Phase 4: multivariate missing-trait records (unbalanced)

Active lenses: Henderson, Kirkpatrick, Mrode, Gauss, Curie, Rose (inline).

## Goal

Extend the multivariate animal model to **unbalanced / missing-trait records** —
the realistic multi-trait case where not every animal is measured on every trait
— still at supplied covariance.

## What changed

- `src/multivariate.jl`: `multivariate_mme` now detects unobserved traits
  (`missing` or `NaN` in `Y`, via the `_is_present` helper). Observed `(i, k)`
  rows are kept; the residual precision becomes **block-diagonal over
  individuals**, with individual `i`'s block `inv(R0[Sᵢ, Sᵢ])` for its
  observed-trait set `Sᵢ`. Breeding values are still returned for every animal ×
  trait (missing traits borrow information through `G0`). An all-present `Y`
  takes the original Kronecker fast path (balanced output bit-unchanged); an
  all-missing `Y` errors. Docstring updated; no signature change.

## Validation (deterministic, comparator-free)

New testset "Phase 4 multivariate missing-trait records (unbalanced)":

1. **Balanced unchanged** — all-present `Y` gives the same result as before.
2. **Independent loop-built MME** — on a fixture with two missing cells, β/EBVs
   match a from-scratch MME over only the observed rows with per-individual
   residual blocks (committed `1e-9`, observed ~1e-13).
3. **Independent marginal-GLS BLUP** — match `(X'V⁻¹X)⁻¹X'V⁻¹y` with `V` carrying
   a block-diagonal residual (`R0[Sᵢ,Sᵢ]` per individual).
4. `missing` entries ≡ `NaN` entries; all-missing `Y` is rejected.

## Checks

- `Pkg.test()`: passed. `julia --project=docs docs/make.jl`: green (new
  "Missing / unbalanced records" docs section with a runnable example).

## Status surfaces (lockstep)

- `src/validation_status.jl` `V4-MULTIVARIATE`: evidence + boundary updated
  (missing handled; "BALANCED" boundary removed).
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`
  (`V4-MV`): updated.
- `docs/src/changelog.md`, `docs/src/multivariate-models.md`,
  `docs/dev-log/check-log.md`, this report.

## Public claim audit (Rose, inline)

Allowed: missing-trait handling at **supplied** covariance, backed by two
independent numerical references + a balanced-reduction check + guards. Still
experimental / not-public-default.

Blocked / pending: covariance-matrix **estimation** (next slice,
`fit_multivariate_reml`); a long-format interface; per-trait designs; a published
Mrode multi-trait fixture and external comparators; the R-facing model-spec.

## Coordination

Engine-internal; no bridge-contract change. Part of the stacked Phase-4 train.

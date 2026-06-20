# 2026-06-14 Loading Rotation And Identifiability

> **Update 2026-06-19:** the deferred rotation/interpretation question is now
> decided in `docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md` —
> bridge/inference uses rotation-INVARIANT functionals of `G` (eigenstructure /
> evolvability / `Ψ`), never raw loadings. The sign-only convention below remains
> the local metadata convention for returned loadings.

## Decision

For Phase 4B structured multivariate genetic covariance fits, HSquared.jl uses a
minimal deterministic sign convention for returned loading metadata:

- for each loading column, find the loading with largest absolute value;
- if that loading is negative, multiply the whole column by `-1`;
- otherwise leave the column unchanged.

This is a metadata convention only. It removes arbitrary sign flips from
`genetic_loadings(result)` but does not identify factor rotations.

## Scope

This decision applies to Julia-local metadata returned by:

```julia
fit_multivariate_reml(...; genetic_structure = :lowrank, rank = K)
fit_multivariate_reml(...; genetic_structure = :factor_analytic, rank = K)
genetic_loadings(result)
```

It does not apply to R-facing covariance syntax, bridge payloads,
`result_payload()`, plots, loading interpretation, or comparator reports.

## Rationale

Low-rank and factor-analytic covariance models are rotation-nonunique. The
covariance `ΛΛ'` is unchanged by orthogonal rotations of `Λ`, and
`ΛΛ' + Ψ` has the same sign ambiguity column-by-column even when uniquenesses
are positive. A sign convention is useful for deterministic tests and stable
metadata, but it is not enough to make factor columns biologically
interpretable.

A stronger convention such as lower-triangular constraints, varimax rotation,
target rotation, or trait-anchored rotations affects interpretation and should
be designed with the R user syntax, plots, examples, and external comparators.

## Current Allowed Wording

- Returned loading metadata is sign-canonicalized.
- The sign convention is deterministic and test-covered.
- Loading columns remain rotation-nonunique and should not be interpreted as
  identified latent factors.

## Blocked Wording

- Factor loadings are uniquely identified.
- Loading columns have stable biological meaning.
- Rotation is solved.
- R users can request `fa(K)` or loading rotations.
- Comparator parity exists for loading estimates.

## Future Gate

A future rotation/interpretation slice must record:

- the chosen convention or rotation method;
- whether it is fitted as a constraint or applied post hoc;
- invariance of the fitted covariance and likelihood;
- trait/factor naming rules;
- R syntax and extractor behavior;
- external comparator alignment rules;
- tests, validation-status updates, check-log evidence, and after-task report.

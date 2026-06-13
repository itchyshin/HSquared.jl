# Phase 1F Direct Bridge Payload Target

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Boole, Henderson, Gauss, Karpinski,
Grace, Rose.

Spawned subagents: none.

## Scope

Implement the Julia method named by the R parser handoff:

```julia
fit_animal_model(y, X, Z, Ainv; method = :REML)
```

This is the direct bridge-shaped payload target. It is not the actual
R-to-Julia marshalling layer.

R lane handoff `b57b48e` reports that `hs_bridge_payload` contains numeric `y`,
dense `X`, sparse `Z`, `Ainv = NULL`, method, family, normalized IDs,
normalized pedigree with parent indices, and metadata.

## Implementation

Added:

- `fit_animal_model(y, X, Z, Ainv; ids, family, method, kwargs...)`.

The method:

- builds an `AnimalModelSpec`;
- validates dimensions, IDs, family, and method;
- dispatches to the experimental dense `fit_variance_components()` path.

## Tests

Added parity tests showing the direct payload method matches the validated-spec
method for:

- likelihood;
- additive and residual variance components;
- encoded IDs;
- method;
- breeding-value IDs.

Added checks for parent-index semantics, `ids` order, sparse `Z` dimensions,
Julia-side `Ainv` dimensions, and error tests for response/design and ID
mismatches.

Local check:

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 100 checks.
- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only blocked-wording/audit rows, not public claims that the
  R bridge executes, R formula calls fit through Julia, sparse production
  fitting works, AI-REML works, or results are comparator-validated.

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- the Julia direct payload target exists experimentally for `y`, `X`, `Z`, and
  `Ainv` inputs.

Blocked wording:

- the R bridge executes models;
- R formula calls now fit through Julia;
- sparse production REML/ML or AI-REML is implemented;
- results are comparator-validated.

## Next Work

1. Add cross-repo R-to-Julia marshalling tests.
2. Add Mrode validation for the dense path.
3. Replace dense covariance equations with sparse production computations.

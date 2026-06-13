# Phase 1H Result Payload Contract

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Emmy, Fisher, Karpinski, Grace, Rose.

Spawned subagents: none.

## Scope

Align Julia dense-fit result names with the R `hsquared_fit` extractor contract
before live bridge execution is wired.

R head `e543cd7` reports mocked extractor tests for:

- `variance_components`
- `heritability`
- `breeding_values`
- `fixed_effects`
- `random_effects`
- `loglik`
- `df`
- `nobs`
- `predictions`
- `diagnostics`
- `converged`

## Implementation

Added:

- `result_payload(fit)`.

The function returns a `NamedTuple` with the R contract field names. Internal
Julia `AnimalModelFit` fields remain stable; bridge shaping is explicit.

## Tests

Added exact field-name and value tests for:

- variance components;
- heritability;
- breeding values;
- fixed effects;
- random effects;
- log-likelihood;
- degrees of freedom;
- number of observations;
- predictions;
- diagnostics;
- convergence.

Local check:

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 121 checks.
- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only blocked-wording/audit rows, not public claims that R
  live execution returns fitted objects, R extractors consume real Julia
  results, reliability/PEV/sparse diagnostics are implemented, or GPU/QTL
  support is implemented.

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- Julia has an experimental `result_payload()` aligned to the R extractor
  contract names.

Blocked wording:

- R live execution returns a fitted object;
- R extractors consume real Julia results;
- reliability, PEV, or sparse diagnostics are implemented.

## Next Work

1. Add live R-to-Julia marshalling.
2. Add cross-repo result-shape tests.
3. Add reliability, PEV, gradient, and sparse solver diagnostics.

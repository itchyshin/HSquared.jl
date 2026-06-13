# Phase 1J Dense PEV And Reliability

Date: 2026-06-13

Active lenses: Ada, Henderson, Gauss, Fisher, Curie, Mrode, Grace, Rose.

Spawned subagents: none.

## Scope

Add dense experimental prediction-error-variance and reliability extractors for
the low-level Gaussian animal-model validation path.

This is not production sparse reliability, not sparse PEV, and not external
comparator validation.

## Implementation

Added:

- `prediction_error_variance(fit)`
- `reliability(fit)`

`prediction_error_variance(fit)` forms the dense mixed-model-equation
coefficient matrix and returns the diagonal of the lower-right inverse block.

`reliability(fit)` computes:

```text
1 - PEV_i / (sigma_a2 * A_ii)
```

using the dense relationship matrix implied by `Ainv`. Values are not clipped.

## Tests

Added tests for:

- identity-relationship PEV against a test-side MME inverse;
- identity-relationship reliability;
- Henderson MME fixture PEV;
- Henderson MME fixture reliability with non-identity `A`.

Local checks:

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 148 checks.
- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only allowed dense-experimental wording and blocked/audit
  rows, not public claims that production sparse reliability/PEV, sparse
  production fitting, AI-REML, R-to-Julia bridge execution, or GPU support are
  implemented.

## Documentation

Updated:

- README
- ROADMAP
- quickstart
- roadmap page
- API reference
- changelog
- engine contract
- v0.1 contract
- public claims register
- capability status
- validation debt
- coordination board

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- dense experimental PEV and reliability extractors exist for validated
  low-level `AnimalModelFit` objects.

Blocked wording:

- production sparse reliability works;
- production sparse PEV works;
- reliability/PEV has external comparator validation;
- R receives reliability/PEV through the live bridge.

## Next Work

1. Decide with the R twin when reliability and PEV should enter
   `result_payload()` and the R `hsquared_fit` extractor contract.
2. Add Mrode textbook and external comparator checks before promoting any
   animal-model output capability.
3. Replace the dense MME inverse with a sparse production reliability strategy.

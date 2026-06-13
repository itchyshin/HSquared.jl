# Phase 1E Dense Fit Extractors

Date: 2026-06-13

Active lenses: Ada, Henderson, Gauss, Fisher, Falconer, Hopper, Karpinski,
Grace, Rose.

Spawned subagents: none.

## Scope

Add first low-level result extractors for `AnimalModelFit` objects returned by
the dense validation path.

This remains tiny-example infrastructure. It is not the production sparse BLUP
solver.

## Implementation

Added:

- `BreedingValues`;
- `variance_components`;
- `fixed_effects`;
- `breeding_values`;
- `fitted_values`;
- `heritability`.

The dense EBV/BLUP extractor uses:

```text
u_hat = sigma_a2 * A * Z' * V^-1 * (y - X * beta)
```

## Tests

Added exact deterministic checks for an identity-relationship model with
`sigma_a2 = 1`, `sigma_e2 = 1`, and `V = 2I`.

Expected outputs:

- beta = 2;
- EBVs = `[-0.5, 0, 0.5]`;
- fitted values = `[1.5, 2, 2.5]`;
- fixed-only fitted values = `[2, 2, 2]`;
- heritability = 0.5.

Local check:

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 85 checks.
- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only blocked-wording/audit rows, not public claims of
  implemented production sparse EBVs, reliability, prediction error variance,
  AI-REML, R bridge execution, GPU, or QTL/eQTL support.

## Documentation

Updated README, roadmap, Documenter pages, engine contract, capability status,
validation debt, public claims register, coordination board, and check log.

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- experimental dense EBV/BLUP and heritability extractors exist for low-level
  validated Julia specs.

Blocked wording:

- production sparse EBVs/BLUPs work;
- reliability or prediction error variance is available;
- R bridge execution returns these outputs;
- outputs are comparator-validated.

## Next Work

1. Add R-to-Julia payload/result parity tests.
2. Add Mrode simple animal-model validation.
3. Add sparse production BLUP solves.
4. Add reliability and prediction error variance.

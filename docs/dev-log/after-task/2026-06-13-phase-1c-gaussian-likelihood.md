# Phase 1C Gaussian Likelihood Evaluation

Date: 2026-06-13

Active lenses: Ada, Henderson, Gauss, Fisher, Karpinski, Rose.

Spawned subagents: none.

## Scope

Add a deterministic Gaussian ML/REML log-likelihood evaluator for a validated
`AnimalModelSpec` at supplied variance components.

This is objective-function groundwork. It is not fitting.

## Implementation

Added `src/likelihood.jl` with:

- `GaussianLikelihoodResult`;
- `gaussian_loglik`.

The evaluator:

- validates positive additive and residual variance components;
- supports `:ML` and `:REML`;
- computes GLS fixed effects at supplied variance components;
- returns log-likelihood, beta, variance components, method, observation count,
  and fixed-effect count.

## Limitation

The evaluator deliberately forms dense matrices by inverting the dense `Ainv`
inside the objective. This is acceptable for tiny tests and likelihood
validation only. It is not the production sparse solver.

## Tests

Added tests for:

- ML log-likelihood against a hand-calculated `V = 2I` example;
- REML log-likelihood against a hand-calculated `V = 2I` example;
- GLS beta recovery;
- non-positive variance components;
- unsupported method;
- saturated REML fixed-effect design.

## Documentation

Updated:

- README;
- ROADMAP;
- `docs/src/api.md`;
- `docs/src/quickstart.md`;
- `docs/src/changelog.md`;
- `docs/design/03-engine-contract.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/dev-log/check-log.md`.

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- Gaussian ML/REML likelihood evaluation exists at supplied variance components;
- the evaluator is dense and experimental.

Blocked wording:

- variance-component fitting works;
- AI-REML works;
- EBVs/BLUPs are available;
- this path is production sparse or huge-scale ready.

## Next Work

1. Add variance-component parameterization and a conservative optimizer path.
2. Add EBV/BLUP solve at supplied variance components.
3. Replace dense validation path with sparse production path after tiny
   objective tests are stable.

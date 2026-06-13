# Phase 1B Animal Model Spec Validation

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Henderson, Gauss, Karpinski, Rose.

Spawned subagents: none.

## Scope

Add the Julia-side bridge-ready validator for the first Gaussian animal-model
payload.

This mirrors the R/coordinator lane direction: R parses user formula syntax into
a model spec; Julia validates the low-level numeric payload before fitting code
exists.

## Implementation

Added `src/model_spec.jl` with:

- `GaussianFamily`;
- `AnimalModelSpec`;
- `animal_model_spec`.

The validator checks:

- response length;
- fixed-effect design rows;
- animal random-effect design rows;
- square `Ainv`;
- `Z` columns matching `Ainv` dimensions;
- ID length matching `Ainv`;
- Gaussian family marker;
- ML/REML method spelling.

## Tests

Added tests for:

- valid REML spec construction;
- string and symbol method normalization;
- default integer IDs;
- bad `X` rows;
- bad `Z` rows;
- bad `Z` columns;
- non-square `Ainv`;
- bad ID length;
- unsupported family;
- unsupported method.

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

- low-level animal-model spec validation exists;
- the validator is bridge-ready groundwork.

Blocked wording:

- Gaussian REML/ML fitting works;
- EBVs/BLUPs are available;
- R can execute a fitted Julia animal model.

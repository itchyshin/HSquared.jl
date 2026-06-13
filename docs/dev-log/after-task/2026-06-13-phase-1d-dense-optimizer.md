# Phase 1D Dense Variance-Component Optimizer

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Henderson, Gauss, Fisher, Karpinski,
Grace, Rose.

Spawned subagents: none.

## Scope

Add the first conservative low-level fitting path for validated Julia
`AnimalModelSpec` objects.

This is dense, experimental, and intended for tiny validation examples.

## Implementation

Added:

- `AnimalModelFit`;
- `fit_variance_components`;
- `fit_animal_model(spec::AnimalModelSpec)`.

The optimizer:

- works on log-variance parameters;
- uses `Optim.NelderMead()`;
- calls the existing dense `gaussian_loglik`;
- returns likelihood, variance components, convergence flag, status string, and
  iteration count.

## Tests

Added tests that:

- a tiny animal-model spec can be optimized;
- optimized likelihood is no worse than the initial likelihood;
- variance components remain positive;
- `fit_animal_model(spec)` dispatches to the low-level optimizer;
- bad initial values are rejected.

Final local checks:

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 76 checks across
  Phase 0, pedigree/Ainv, spec validation, likelihood, and dense optimizer
  testsets.
- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only blocked-wording/audit rows, not public claims of
  implemented sparse fitting, AI-REML, EBVs, heritability, GPU, or QTL/eQTL
  support.

## Documentation

Updated:

- README;
- ROADMAP;
- `docs/src/index.md`;
- `docs/src/api.md`;
- `docs/src/quickstart.md`;
- `docs/src/changelog.md`;
- `docs/design/01-v0.1-contract.md`;
- `docs/design/02-formula-grammar.md`;
- `docs/design/03-engine-contract.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/dev-log/check-log.md`.

## Coordination

The R twin reported `hsquared` head `d85f356` with:

- inert `animal()` exported;
- `hs_build_model_spec()` parsing `animal(1 | id, pedigree = ped)`;
- `hsquared()` stopping at
  `HSquared.fit_animal_model(y, X, Z, Ainv; method = :REML)`;
- green local and remote R checks;
- live pkgdown site at `https://itchyshin.github.io/hsquared/`.

Julia mirrored the contract as:

- R parser exists;
- Julia low-level spec validation and experimental dense optimization exist;
- R-to-Julia bridge execution and payload parity tests are next.

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- experimental dense variance-component optimization exists for low-level
  validated Julia specs.

Blocked wording:

- sparse production animal-model fitting works;
- AI-REML works;
- R formula bridge execution works;
- EBVs/BLUPs, heritability, or reliability are available;
- this is benchmarked or faster than comparator software.

## Next Work

1. Add BLUP/EBV solving at fitted variance components.
2. Add heritability extraction.
3. Add Mrode validation.
4. Replace the dense path with sparse production computations.

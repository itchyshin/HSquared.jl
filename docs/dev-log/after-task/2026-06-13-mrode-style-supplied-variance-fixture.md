# Mrode-Style Supplied-Variance Fixture

Active lenses: Ada, Shannon, Henderson, Curie, Fisher, Gauss, Grace, Rose.
Spawned subagents: none.

## Goal

Add a Julia-native Mrode9-shaped supplied-variance validation fixture for the
Phase 1 engine path without claiming fitted Mrode validation, variance-component
estimation, AI-REML, external fitted-model parity, or production sparse fitting.

## Files Changed

- `test/runtests.jl`
- `src/validation_status.jl`
- `README.md`
- `ROADMAP.md`
- `docs/src/validation-status.md`
- `docs/design/04-validation-canon.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-13-mrode-style-supplied-variance-fixture.md`

## Implementation

The new test fixture uses the 12-animal `nadiv::Mrode9` pedigree structure and
supplied variance components:

- `sigma_a2 = 1.4`
- `sigma_e2 = 0.9`

The fixture pins:

- normalized IDs;
- sparse `Ainv`;
- ML and REML likelihood values;
- fixed effects;
- EBVs/BLUPs;
- fitted values;
- PEV;
- reliability;
- derived accuracy;
- `h2`.

The reference path remains the independent test-only dense MME helper. The
engine functions under test are `pedigree_inverse()`, `gaussian_loglik()`,
`sparse_reml_loglik()`, `henderson_mme()`, and the validation-scale extractor
methods.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed after the code-only
  fixture edit.
- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed after docs/status
  edits. Testset totals sum to 487 checks, including 31 checks in the new
  Mrode-style supplied-variance fixture.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; Vitepress dependency installation reported the existing
  npm advisory noise in generated/transient build dependencies.
- `git diff --check`: passed.
- Additions-only ASCII scan: found only Julia's existing `≈` test operator in
  new test assertions.
- Claim-boundary scan: found expected blocked/status wording only.
- CI for commit `b8c75d0`: passed, run `27465516616`.
- Documenter for commit `b8c75d0`: passed, run `27465516626`.
- Pages deployment: passed, run `27465552850`.
- Live validation page: HTTP 200 and contains
  `Mrode9-shaped supplied-variance fixture` plus the fitted-Mrode boundary
  wording.

## Public Claim Audit

Allowed wording:

- Julia has a Mrode9-shaped supplied-variance fixture.
- The fixture strengthens dense/sparse supplied-variance likelihood,
  Henderson MME, PEV, reliability, accuracy, and `h2` validation.

Blocked wording:

- fitted Mrode validation is covered;
- variance-component estimation is validated by this fixture;
- AI-REML is implemented;
- ASReml, BLUPF90, DMU, WOMBAT, sommer, or MCMCglmm fitted-output parity exists;
- production sparse fitting or production sparse PEV/reliability is available.

## Tests Of The Tests

The fixture checks the production functions against pinned constants and an
independent dense MME reference helper. It also checks sparse REML against the
dense REML evaluator for the same supplied variance components.

## Coordination Notes

The R twin already records optional external pedigree-inverse comparator
evidence using `nadiv::Mrode9` and `nadiv::makeAinv()`. This Julia slice does
not depend on running `nadiv`; it records a Mrode9-shaped structure locally and
keeps the fitted-output Mrode lane open.

The R twin also reported a new `fit_diagnostics()` helper at head `060988d`.
That is logged as a possible Julia follow-up, not included in this slice.

## Known Limitations

- The response values and supplied variance components are validation-fixture
  choices, not source-recorded fitted Mrode outputs.
- No variance components are estimated.
- No fitted-model comparator package is run.
- PEV and reliability use dense MME inverse blocks for validation-scale fits.

## Next Actions

1. Add true fitted Mrode validation with source-recorded response data,
   estimator target, variance components, EBVs, `h2`, comparator versions, and
   tolerances.
2. Decide whether Julia should add a `fit_diagnostics()` mirror for existing
   result metadata.
3. Continue replacing dense validation blocks with production sparse
   computations before widening public fitting claims.

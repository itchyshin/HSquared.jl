# Sparse REML Validation Optimizer

## Task Goal

Add a Julia-only sparse REML optimization atom that moves Phase 1 forward
without changing the R bridge payload or claiming production sparse fitting.

## Active Lenses

Ada, Shannon, Henderson, Gauss, Fisher, Curie, Karpinski, Grace, Rose, and
Hopper.

Spawned subagents: none.

## Files Changed

- `src/likelihood.jl`
- `src/HSquared.jl`
- `src/validation_status.jl`
- `test/runtests.jl`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-v0.1-contract.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/quickstart.md`
- `docs/src/roadmap.md`

## Implementation

- Added exported `fit_sparse_reml()`.
- Added `fit_animal_model(...; target = :sparse_reml)` dispatch for validated
  REML specs and direct bridge-shaped payloads.
- Extended `AnimalModelFit` with stored diagnostic metadata while preserving
  the existing constructor used by current tests and fixtures.
- Updated `fit_diagnostics()` and compact `result_payload()` diagnostics to
  report stored validation-path metadata.
- Added invalid sparse-objective trial handling so non-positive-definite
  Nelder-Mead trial points return `Inf` instead of aborting.
- Added validation-status, capability-status, validation-debt, public-claims,
  quickstart, API, roadmap, README, mission-control, and coordination-board
  updates.

## Checks Run

- Initial `julia --project=. -e 'using Pkg; Pkg.test()'`: passed with 540
  checks.
- Initial `julia --project=docs docs/make.jl`: exposed a
  non-positive-definite sparse objective trial in the new quickstart example.
- Final `julia --project=. -e 'using Pkg; Pkg.test()'`: passed with 543 checks.
- Final `julia --project=docs docs/make.jl`: passed. Local deployment was
  skipped as expected outside CI; Vitepress dependency installation still
  reported npm advisories in generated/transient build artifacts.
- `git diff --check`: passed.
- Claim-boundary scan: expected blocked/status wording only.

## Public Claim Audit

Allowed wording:

- experimental sparse REML validation optimizer;
- REML-only;
- tiny low-level validation fixtures;
- `fit_animal_model(...; target = :sparse_reml)` direct Julia target.

Blocked wording:

- AI-REML;
- production sparse fitting;
- default public R fitting path;
- fitted Mrode validation;
- ASReml, BLUPF90, DMU, WOMBAT, sommer, MCMCglmm, or other fitted-output
  comparator parity;
- GPU/backend execution or performance claims.

## Tests Of The Tests

- The validation-status test now asserts the new `V1-SPARSE-REML-OPT` row,
  including partial status and the "not AI-REML" claim boundary.
- The variance-component fitting tests check sparse REML improvement over the
  starting objective, spec dispatch, direct payload dispatch, ML rejection, and
  misuse of supplied variance components.
- The fit-diagnostics tests check that sparse REML fits report
  `dense_validation_path = false`, `sparse_mme_path = true`, and
  `variance_components_source = :estimated_sparse_reml_validation`.

## Coordination Notes

- The sibling R repo was observed with an uncommitted edit in
  `R/validation-fixtures.R`. This Julia slice did not touch the R repo.
- No R bridge payload fields were added.
- `result_payload()` field names remain unchanged.

## What Did Not Go Smoothly

- The first docs build found a legitimate optimizer robustness issue: the
  sparse objective could throw on non-positive-definite trial points. The final
  implementation treats those trial points as invalid optimizer locations.

## Known Limitations

- No AI-REML.
- No production sparse diagnostics.
- No fitted Mrode output validation.
- No external fitted-model comparator.
- No production sparse PEV/reliability.
- No high-level public formula fitting claim.

## Next Actions

1. Add a fitted Mrode animal-model fixture with source-recorded response data,
   estimator target, expected variance components, EBVs, and `h2`.
2. Decide the production sparse optimizer path: AI-REML, safeguarded Newton,
   or staged refinement after `fit_sparse_reml()`.
3. Keep R bridge targets stable unless the R coordinator explicitly takes a
   matching bridge slice.

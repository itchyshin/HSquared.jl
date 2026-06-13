# Henderson MME PEV Reliability Methods

Date: 2026-06-13

Active lenses: Ada, Henderson, Fisher, Hopper, Rose, Grace.

Spawned subagents: none.

## Goal

Add validation-scale PEV and reliability extractors for supplied-variance
`HendersonMMEResult` objects while preserving the compact R-Julia
`result_payload()` contract.

## Julia Action

Changed:

- `src/likelihood.jl`;
- `test/runtests.jl`;
- `src/validation_status.jl`;
- `docs/design/03-engine-contract.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/src/index.md`;
- `docs/src/quickstart.md`;
- `docs/src/roadmap.md`;
- `docs/src/changelog.md`;
- `README.md`;
- `ROADMAP.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`.

Implemented:

- `prediction_error_variance(result::HendersonMMEResult)`;
- `reliability(result::HendersonMMEResult)`;
- a shared dense MME inverse-block helper used by both `AnimalModelFit` and
  supplied-variance `HendersonMMEResult` extractors;
- Henderson fixture tests for `prediction_error_variance(mme)` and
  `reliability(mme)`.

No `result_payload()` fields were added.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 362 checks; the Henderson MME supplied-variance validation fixture has 32
  checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependency installation still
  reported npm advisories in transient build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: no matches.
- Claim scan: expected status/limitation hits only.

## Public Claim Audit

Allowed wording:

- PEV and reliability methods are available for tiny validation-scale
  `AnimalModelFit` and supplied-variance `HendersonMMEResult` objects.
- These methods use a dense inverse of the MME coefficient matrix.
- `result_payload()` remains compact; R-side enrichment can stay optional.

Blocked wording:

- production sparse PEV works;
- production sparse reliability works;
- selected inverse or Takahashi support exists;
- variance-component estimation is validated by this slice;
- fitted Mrode output validation exists;
- external ASReml/BLUPF90/DMU/WOMBAT/sommer/MCMCglmm parity exists.

Rose verdict: clean with limitations.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- This complements the R twin's optional PEV/reliability bridge enrichment
  without requiring a payload-shape change.
- Future production sparse PEV/reliability should be a separate selected-inverse
  or sparse-factorization slice with comparator evidence.

## Next Actions

1. Commit and push this slice.
2. Watch CI, Documenter, and Pages.
3. Record remote evidence after green.

# Henderson MME Variance Component H2 Methods

Date: 2026-06-13

Active lenses: Ada, Henderson, Fisher, Hopper, Rose, Grace.

Spawned subagents: none.

## Goal

Add supplied-variance `variance_components()` and `heritability()` methods for
`HendersonMMEResult` so the low-level MME result exposes the same basic
validation outputs as the dense fit path.

## Julia Action

Changed:

- `src/likelihood.jl`;
- `test/runtests.jl`;
- `src/validation_status.jl`;
- `docs/design/03-engine-contract.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/src/quickstart.md`;
- `docs/src/changelog.md`;
- `README.md`;
- `docs/dev-log/check-log.md`.

Implemented:

- `variance_components(result::HendersonMMEResult)`;
- `heritability(result::HendersonMMEResult)`;
- fixture checks for supplied variance components and `h2`.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 364 checks; the Henderson MME supplied-variance validation fixture has 34
  checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependency installation still
  reported npm advisories in transient build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: no matches.
- Claim scan: expected status/limitation hits only.

Remote checks for commit `ed2c932`:

- CI `27462729581`: success on Julia 1 and Julia 1.10.
- Documenter `27462729578`: success.
- Pages deploy `27462764899`: success.

GitHub Actions emitted non-blocking Node 20 deprecation annotations from
upstream actions.

## Public Claim Audit

Allowed wording:

- `HendersonMMEResult` can report supplied variance components.
- `heritability(mme)` computes `sigma_a2 / (sigma_a2 + sigma_e2)` from supplied
  variance components.

Blocked wording:

- variance components are estimated by `henderson_mme()`;
- supplied-variance MME solves are fitted animal-model validation;
- production sparse fitting, production sparse PEV, or production sparse
  reliability is implemented by this slice;
- fitted Mrode or external fitted-model comparator parity is covered.

Rose verdict: clean with limitations.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- No bridge payload fields were added.
- R can continue treating PEV/reliability enrichment as optional and compact.

## Next Actions

1. Keep true Mrode fitted-output validation as a separate fixture with source,
   estimand, and expected values recorded before public claims change.

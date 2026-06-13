# MME-Backed EBV Extractor

Date: 2026-06-13

Active lenses: Ada, Henderson, Fisher, Karpinski, Rose, Grace.

Spawned subagents: none.

## Goal

Move `breeding_values(fit::AnimalModelFit)` from the dense covariance equation
to the Henderson MME solve at the fit's variance components.

## Julia Action

Changed:

- `src/likelihood.jl`;
- `test/runtests.jl`;
- `src/validation_status.jl`;
- `docs/design/03-engine-contract.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/src/index.md`;
- `docs/src/quickstart.md`;
- `docs/src/roadmap.md`;
- `docs/src/changelog.md`;
- `README.md`;
- `ROADMAP.md`.

Implemented:

- `breeding_values(fit)` now calls `henderson_mme(fit.spec, sigma_a2,
  sigma_e2)` and returns the animal-effect block.
- Tests assert `breeding_values(fit)` matches `breeding_values(mme)` for both
  the dense extractor fixture and the shared Henderson MME fixture.

## Public Claim Audit

Allowed wording:

- EBV/BLUP extraction for `AnimalModelFit` is MME-backed at the fit's variance
  components.
- This is still an experimental low-level output path.

Blocked wording:

- sparse production fitting works;
- variance-component estimation is sparse or production-ready;
- production sparse reliability or PEV is implemented;
- fitted Mrode or external fitted-model comparator validation exists.

Rose verdict before checks: clean with limitations.

## Checks To Run

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 366 checks; dense extractor testset has 31 checks and the Henderson MME
  supplied-variance validation fixture has 35 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependency installation still
  reported npm advisories in transient build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: no matches.
- Claim scan: expected status/limitation hits only.

## Known Limitations

- Variance components still come from the experimental dense validation fit
  path.
- Reliability and PEV remain dense validation-scale extractors.
- No fitted Mrode output validation or external fitted-model comparator is
  added by this slice.

## Next Actions

1. Commit and push.
2. Watch CI, Documenter, and Pages.
3. Continue toward Mrode fitted-output validation and sparse production
   optimization as separate evidence-gated slices.

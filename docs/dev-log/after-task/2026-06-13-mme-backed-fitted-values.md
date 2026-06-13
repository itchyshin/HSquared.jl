# MME-Backed Fitted Values

Date: 2026-06-13

Active lenses: Ada, Henderson, Fisher, Karpinski, Rose, Grace.

Spawned subagents: none.

## Goal

Move `fitted_values(fit::AnimalModelFit)` onto the same Henderson MME solve as
`breeding_values(fit)`, using the fit's variance components.

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
- `docs/dev-log/coordination-board.md`;
- `docs/src/index.md`;
- `docs/src/quickstart.md`;
- `docs/src/roadmap.md`;
- `docs/src/changelog.md`;
- `README.md`;
- `ROADMAP.md`.

Implemented:

- `fitted_values(fit)` now calls `henderson_mme(fit.spec, sigma_a2,
  sigma_e2)` at the fit's variance components.
- Tests assert `fitted_values(fit)` matches `fitted_values(mme)` with and
  without random effects for both the dense extractor fixture and the shared
  Henderson MME fixture.

## Public Claim Audit

Allowed wording:

- EBV/BLUP and fitted-value extraction for `AnimalModelFit` are MME-backed at
  the fit's variance components.
- This is still an experimental low-level output path.

Blocked wording:

- sparse production fitting works;
- variance-component estimation is sparse or production-ready;
- production sparse reliability or PEV is implemented;
- fitted Mrode or external fitted-model comparator validation exists.

Rose verdict before checks: clean with limitations.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 371 checks; dense extractor testset has 33 checks and the Henderson MME
  supplied-variance validation fixture has 37 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependency installation still
  reported npm advisories in transient build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: no matches.
- Claim-boundary scan: expected status/limitation hits only.

Remote evidence for implementation commit `e6e38f2`:

- CI `27463342065`: passed on Julia 1 and Julia 1.10.
- Documenter `27463342069`: passed.
- Pages deploy `27463373649`: passed.
- GitHub Actions reported non-blocking Node 20 deprecation annotations for the
  action stack.

Evidence-update checks:

- `julia --project=docs docs/make.jl`: passed after recording remote evidence.
  Local deployment was skipped as expected outside CI; generated Vitepress
  dependency installation still reported npm advisories in transient build
  artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: no matches.

## Known Limitations

- Variance components still come from the experimental dense validation fit
  path.
- Reliability and PEV remain dense validation-scale extractors.
- No fitted Mrode output validation or external fitted-model comparator is
  added by this slice.

## Next Actions

1. Record this evidence commit.
2. Watch CI, Documenter, and Pages for the evidence commit.
3. Continue toward Mrode fitted-output validation and sparse production
   optimization as separate evidence-gated slices.

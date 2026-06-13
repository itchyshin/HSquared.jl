# Direct Henderson MME Fit Target

Date: 2026-06-13

Active lenses: Ada, Hopper, Henderson, Fisher, Karpinski, Rose, Grace.

Spawned subagents: none.

## Goal

Add a Julia-side direct `fit_animal_model(...; target = :henderson_mme,
variance_components = ...)` convenience path that mirrors the R twin's explicit
supplied-variance bridge target while keeping the default dense optimizer path
unchanged.

## Julia Action

Changed:

- `src/likelihood.jl`;
- `test/runtests.jl`;
- `docs/design/03-engine-contract.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/src/index.md`;
- `docs/src/quickstart.md`;
- `docs/src/changelog.md`;
- `README.md`;
- `ROADMAP.md`.

Implemented:

- `fit_animal_model(spec; target = :henderson_mme, variance_components = ...)`
  returns `HendersonMMEResult`.
- `fit_animal_model(y, X, Z, Ainv; target = "henderson_mme",
  variance_components = ...)` builds the validated spec and uses the same
  target dispatch.
- Default `fit_animal_model()` behavior remains the dense validation optimizer.

## Public Claim Audit

Allowed wording:

- Julia has an explicit supplied-variance Henderson MME target.
- The default direct payload path remains the experimental dense validation
  optimizer.

Blocked wording:

- the target estimates variance components;
- the target returns log-likelihood, AIC, `df`, or optimizer output;
- sparse production fitting works;
- AI-REML is implemented;
- fitted Mrode or external fitted-model comparator validation exists.

Rose verdict before checks: clean with limitations.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 383 checks; dense variance-component fitting testset has 22 checks and
  bridge payload fit target testset has 20 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependency installation still
  reported npm advisories in transient build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: no matches.
- Claim-boundary scan: expected status/limitation hits only.

Remote checks for implementation commit `308a103`:

- CI `27463613983`: success on Julia 1 and Julia 1.10.
- Documenter `27463613984`: success.
- Pages deploy `27463649844`: success.
- GitHub Actions reported non-blocking Node 20 deprecation annotations for the
  action stack.

## Known Limitations

- Supplied variance components only.
- No production bridge hardening or relationship-object marshalling beyond
  existing sparse `Z` slot support.
- No fitted Mrode output validation or external fitted-model comparator is
  added by this slice.

## Next Actions

1. Commit and push.
2. Watch CI, Documenter, and Pages.
3. Continue toward Mrode fitted-output validation and sparse production
   optimization as separate evidence-gated slices.

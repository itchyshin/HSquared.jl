# R Model Spec Preview Sync

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Boole, Emmy, Rose, Grace, Pat.

Spawned subagents: none.

## Goal

Mirror the R twin's exported `model_spec()` preview surface in Julia docs and
design memory as a formula-to-bridge parity tool.

## R Handoff

R commit:

- `bacef9c Add model specification preview`.

Reported R evidence:

- R-CMD-check `27459924245`: success;
- pkgdown `27459924261`: success;
- Pages `27459952909`: success.

R behavior:

- validates the same v0.1 grammar as `hsquared()`;
- builds the same internal bridge payload;
- previews response/family/method, fixed-effect columns, sparse `Z` dimensions,
  normalized animal IDs, observed ID mapping, pedigree founder count, and Julia
  targets;
- does not fit models or execute Julia.

## Julia Action

Updated:

- `docs/design/01-v0.1-contract.md`;
- `docs/design/02-formula-grammar.md`;
- `docs/design/03-engine-contract.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/src/model-spec-grammar.md`;
- `docs/src/quickstart.md`;
- `docs/src/roadmap.md`;
- `docs/src/changelog.md`;
- `ROADMAP.md`;
- `README.md`.

No Julia code changed.

## Checks

- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum to
  294 checks.
- `git diff --check`: passed.
- Edited-file ASCII scan: no matches.
- Claim scan: clean with limitations. Hits were expected preview guardrails
  such as "does not fit" and public-claims/after-task blocked wording, not
  unsupported claims that `model_spec()` fits models, executes Julia, or
  expands grammar.

Remote checks for commit `f4ab8af`:

- CI `27460048735`: success;
- Documenter `27460048734`: success;
- Pages deploy `27460080421`: success.

Live docs:

- model-spec grammar page
  `https://itchyshin.github.io/HSquared.jl/dev/model-spec-grammar`: HTTP 200
  and contains `model_spec()` plus `previews the same v0.1 formula-to-bridge
  contract`;
- quickstart `https://itchyshin.github.io/HSquared.jl/dev/quickstart`: HTTP
  200 and contains `model_spec()` plus `without executing Julia`;
- roadmap `https://itchyshin.github.io/HSquared.jl/dev/roadmap`: HTTP 200 and
  contains `model_spec`, `preview evidence`, `bacef9c`, and `without fitting
  or Julia execution`.

GitHub Actions emitted Node 20 deprecation annotations from upstream actions,
but all jobs completed successfully.

## Public Claim Audit

Allowed wording:

- R `model_spec()` previews the v0.1 formula-to-bridge payload.
- The preview helps check formula-to-bridge parity before fitting.
- Julia receives the corresponding low-level engine pieces through
  `animal_model_spec()` or direct payload calls.

Blocked wording:

- `model_spec()` fits models;
- `model_spec()` executes Julia;
- grammar beyond `animal(1 | id, pedigree = ped)` is parsed;
- production R-to-Julia fitting is complete.

Rose verdict: clean with limitations.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- This mirrors R head `bacef9c`.
- The next bridge-impacting changes still need lockstep R and Julia tests.

## Known Limitations

- Documentation/status only.
- No Julia API change.
- No new numerical validation.

## Next Actions

1. Run local docs/test checks.
2. Push and watch CI.
3. Record remote evidence.

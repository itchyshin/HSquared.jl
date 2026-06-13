# Documenter NPM Cache Hardening

Date: 2026-06-13

Active lenses: Ada, Shannon, Grace, Karpinski, Hopper, Rose.

Spawned subagents: none.

## Goal

Reduce repeat risk from the transient DocumenterVitepress/npm cache failure
seen on the first remote Documenter attempt for commit `4363512`.

## Trigger

Documenter run `27461779343` initially failed with an npm cache temporary-file
collision and a generated `docs/package-lock.json` cleanup error. Rerunning
failed jobs passed, and Pages deploy `27461844908` succeeded. This was treated
as workflow hygiene, not a docs-content failure.

## Implementation

Changed `.github/workflows/Documenter.yml` so the build step:

- uses `npm_config_cache = ${{ runner.temp }}/npm-cache` for a per-run npm
  cache;
- removes transient npm cache tmp files before the docs build;
- removes generated `docs/package-lock.json` before the docs build.

## Files Changed

- `.github/workflows/Documenter.yml`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/dev-log/after-task/2026-06-13-documenter-npm-cache-hardening.md`.

## Checks

- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/Documenter.yml"); puts "yaml ok"'`:
  passed.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped
  as expected outside CI; Vitepress dependency installation still reported npm
  advisories in generated/transient build artifacts.
- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 351 checks.
- `git diff --check`: passed.
- Additions-only ASCII scan: returned no matches.
- Claim scan found only expected boundary wording that this is workflow hygiene
  and makes no capability, validation, fitting, bridge, backend-execution, GPU,
  or performance claim.
- Remote checks: pending.

## Public Claim Audit

Allowed wording:

- the Documenter workflow isolates npm cache state to the runner temp
  directory;
- the cleanup is CI hygiene for generated/transient files.

Blocked wording:

- any package API, fitting, validation, bridge, backend-execution, GPU, or
  performance capability changed.

Rose verdict: clean locally, pending remote CI evidence.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- No R-to-Julia bridge contract fields changed.
- No `HSData`, formula grammar, result payload, or backend status surface
  changed.

## What Did Not Go Smoothly

- The previous Documenter evidence run passed only after rerunning failed jobs,
  which indicates a transient CI-cache failure still worth hardening.

## Known Limitations

- This does not remove upstream npm advisories reported by local Vitepress
  dependency installation.
- This does not address unrelated upstream action deprecation annotations.

## Next Actions

1. Run local workflow syntax and docs checks.
2. Commit and push the workflow hardening.
3. Watch CI, Documenter, and Pages.

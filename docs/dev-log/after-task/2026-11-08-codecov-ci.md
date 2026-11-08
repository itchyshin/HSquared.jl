# Codecov CI — Julia coverage collection + documented OIDC upload

Personas: **Grace** (CI), **Rose** (claim-vs-evidence), **Shannon** (lane isolation).
Spawned subagents: none. Review lenses only.

## 1. Goal

First5 Codecov rollout, HSquared.jl lane only. Wire real Julia test-coverage
collection onto the existing four-leg CI matrix and one documented Codecov
OIDC upload. Produce a truthful PR; do not merge to `main`.

## 2. Active lenses and spawned agents

Active lenses: Grace, Rose, Shannon.
Spawned subagents: none.
Current lane: Julia CI/coverage only (`cursor/codecov-first5-0f83`).
Sibling First5 PRs are independent and were not edited: hsquared #364,
DRModels.jl #1269, drmTMB #1686, gllvmTMB #1742.

## 3. Files changed

- `.github/workflows/CI.yml` — after `julia-runtest`, Ubuntu + Julia `1`
  runs `julia-processcoverage@v1`, records event/checkout/PR-head SHAs,
  prints an lcov line-hit summary, and uploads artefact
  `coverage-lcov-julia1-ubuntu`. New non-required `codecov` job downloads
  that file and uploads once with `codecov/codecov-action@v5`,
  `use_oidc: true`, job-scoped `id-token: write`.
- `codecov.yml` — informational project/patch status; ignore
  test/docs/bench/tools/sim/comparator; carryforward flag `julia-linux-1`.
- this report, `docs/dev-log/check-log.d/2026-11-08-codecov-ci.md`,
  `docs/dev-log/check-log.md` pointer, `docs/dev-log/coordination-board.md`
  lane note.

No `src/`, `test/`, fixture, README-badge, capability-status, validation-debt,
or scientific-result changes.

## 4. Checks run and exact outcomes

- `python3` YAML-load of `.github/workflows/CI.yml` and `codecov.yml`: see
  check-log shard.
- `bash tools/preamble_cap.sh`: see check-log shard.
- `git diff --check`: see check-log shard.
- `julia`: **not installed** in this cloud image. No local `Pkg.test()`, no
  local `lcov.info`, no local coverage percentage. That is a missing-env
  blocker, not a fabricated figure.

GitHub Actions on the PR is the collection path. Do not treat this report as
proof that Codecov accepted an upload or that `main` has a report.

## 5. Public claim audit (Rose)

| State | This PR |
|---|---|
| Configured | yes |
| Locally coverage-tested | no (`julia` missing) |
| CI running | pending after push |
| Upload executed | NOT_VERIFIED until the `codecov` job log shows the uploader ran |
| Upload accepted / commit report | NOT_VERIFIED until Codecov accepts that commit |
| Report visible vs `main` coverage | NOT_VERIFIED; dashboard Configure is not proof |
| Default-branch (`main`) functional | no — this PR does not merge |

No badge. No covered-count, version, GPU, registry, or capability claim.

## 6. Tests of the tests

No `test_*.jl` added, skipped, or weakened. The four-leg matrix still runs
the full suite on Julia 1.10/1 × Ubuntu/Windows. Coverage processing is
gated to Ubuntu + Julia `1` so the same suite is not uploaded four times.

## 7. Coordination notes

- Isolated branch off current `origin/main` (`15e932f2`). Did not retarget
  or edit draft PR #498 (Arc 1 handover).
- Did not touch pigauto, GLLVModels.jl, or other repos.
- Job-scoped on `codecov` only: `contents: read`, `actions: read` (same-workflow
  artefact download), `id-token: write` (OIDC). No `CODECOV_TOKEN`, no
  `GITHUB_TOKEN` as a Codecov token, no token minting, no billing change.

## 8. What did not go smoothly

- Latest `main` CI run `42255350096` is red on **Julia 1 / windows-latest**
  only. Ubuntu Julia 1 (the coverage cell) succeeded on that SHA. The
  `codecov` job uses `if: always()` so a Windows-only failure does not skip
  the upload; a missing Ubuntu artefact still fails the upload job honestly.
- This lane does not fix that Windows failure (would be a test change).

## 9. Known limitations

- GitHub `pull_request` jobs check out a synthetic merge commit
  (`github.sha`); the branch head is `github.event.pull_request.head.sha`.
  Both are printed in the coverage and upload jobs. A PR report is not a
  `main` report.
- Compare-to-main / project baseline requires an accepted upload on `main`
  after owner merge, then the next `push` to `main`. Merge is **not**
  authorised here.
- Actual uploader failure (OIDC rejected, repo not activated) is required
  before requesting `CODECOV_TOKEN` or a Codecov grant. Do not treat the
  Codecov dashboard Configure page as proof.

## 10. Next actions

1. Read the PR `codecov` job log: upload executed vs accepted.
2. If OIDC is rejected, owner (not this agent) activates
   `itchyshin/HSquared.jl` at https://app.codecov.io/github/itchyshin
   and, only after a real uploader failure, may add repository secret
   `CODECOV_TOKEN` from that repo's Codecov Configuration.
3. Do not add the `codecov` check to branch protection until an upload
   has been accepted.
4. Coordinator / owner merge decision is out of this lane. CI-wake
   evidence only; do not keep editing unless the coordinator asks.

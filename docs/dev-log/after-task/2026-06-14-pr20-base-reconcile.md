# 2026-06-14 PR20 Base Reconcile

## Task Goal

Resolve PR #20 (`codex/phase5-marker-lod`) against the repaired
`codex/phase5-marker-adjustments` base after PR #19 was reconciled with the
Phase 5 marker-scan stack.

## Active Lenses And Spawned Agents

- Ada/Shannon: keep the stacked train linear and non-merging.
- Fisher: preserve the fixed-effect LOD-equivalent interpretation boundary.
- Curie: keep deterministic marker-scan test evidence intact.
- Grace: verify low-core local checks before push.
- Rose: prevent interval-mapping, mixed-model LOD, LOCO, or bridge claims.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- inherited after-task notes from the repaired base branch
- this report

## What Landed

Merged `origin/codex/phase5-marker-adjustments` into
`codex/phase5-marker-lod`. The only conflict was the append-only
`docs/dev-log/check-log.md`; the resolution keeps:

- the PR #20 fixed-effect marker-scan LOD-equivalent score evidence;
- the PR #19 base reconcile and multiple-testing adjustment evidence;
- the PR #18 base reconcile and p-value evidence;
- the PR #17 main reconcile evidence;
- the current GitHub landing-page docs-link evidence.

No engine code, tests, validation-status rows, capability rows, bridge payload,
`result_payload()`, R package files, or public claims changed in this reconcile
slice.

## Checks Run

- `git diff --check`: passed after conflict resolution.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. The full package suite passed, including Phase 5 fixed-effect
  single-marker scan (`42` checks) and Phase 4B structured genetic covariance
  (`61` checks), on the reconciled PR #20 branch state.
- Initial docs attempts with the same low-core `include("docs/make.jl")`
  command failed in local generated npm/VitePress state: first on stale
  `docs/node_modules` cleanup (`ENOTEMPTY` under `@mathjax`), then on partial
  `esbuild` installs after regenerated npm state.
- After clearing generated `docs/build`, `docs/node_modules`,
  `docs/package-lock.json`, ignored `docs/Manifest.toml`, recreating the
  temporary `docs/package.json` from the DocumenterVitepress template, and
  using a fresh temporary npm cache at `/private/tmp/hsquared-npm-cache-pr20`,
  rerunning
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 NPM_CONFIG_CACHE=/private/tmp/hsquared-npm-cache-pr20 npm_config_cache=/private/tmp/hsquared-npm-cache-pr20 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`
  passed. Generated docs/npm files and the temporary npm cache were removed
  again before commit. Known caveats remained: 8 unrelated docstrings not
  included in the manual, local deployment skipped, VitePress default
  substitutions, missing local logo/favicon substitutions, and 4 npm audit
  advisories in generated docs dependencies.
- Remote workflow-dispatch checks for pushed commit `0c4244c` passed:
  CI `27515882117` and Documenter `27515882111`.

## Public Claim Audit

Allowed claim: PR #20 is reconciled locally against the repaired PR #19 base
while preserving its deterministic fixed-effect LOD-equivalent score output.

Blocked claims remain blocked: no interval mapping, no mixed-model LOD, no
LOCO, no calibrated mixed-model p-values, no correlated-marker or genome-wide
calibration claim, no R formula activation, no bridge payload or
`result_payload()` change, and no comparator parity claim.

## Coordination Notes

This is Julia-lane stack maintenance only. The R repository was not edited.
No R issue action is required because no bridge or public R contract changed.

## Known Limitations

- PR #20 remains draft and should not be merged until the stack base decision
  is made by the maintainer.
- Downstream PRs #22 and above should be rechecked after PR #20 is pushed.

## Next Actions

- Re-check downstream stack mergeability.

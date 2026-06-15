# 2026-06-14 PR23 Base Reconcile

## Task Goal

Resolve PR #23 (`codex/phase5-marker-map-manhattan`) against the repaired
`codex/phase5-marker-plot-data` base after PR #22 was reconciled with the
Phase 5 marker-scan stack.

## Active Lenses And Spawned Agents

- Ada/Shannon: keep the stacked train linear and non-merging.
- Florence: preserve the plot-data-only scope.
- Fisher: preserve marker-map-backed display semantics.
- Grace: verify low-core local checks before push.
- Rose: prevent marker-file parsing, plotting, mixed-model GWAS/QTL, LOCO, or
  bridge claims.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- inherited after-task notes from the repaired base branch
- this report

## What Landed

Merged `origin/codex/phase5-marker-plot-data` into
`codex/phase5-marker-map-manhattan`. The only conflict was the append-only
`docs/dev-log/check-log.md`; the resolution keeps:

- the PR #23 marker-map-backed Manhattan plot-data evidence;
- the PR #22 base reconcile and Manhattan plot-data evidence;
- the PR #20 base reconcile and LOD-equivalent score evidence;
- the PR #19 base reconcile and multiple-testing adjustment evidence;
- the PR #18 base reconcile and p-value evidence;
- the PR #17 main reconcile evidence;
- the current GitHub landing-page docs-link evidence.

No engine code, tests, validation-status rows, capability rows, bridge payload,
`result_payload()`, R package files, marker-file parser, plotting
implementation, or public claims changed in this reconcile slice.

## Checks Run

- `git diff --check`: passed after conflict resolution.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. The full package suite passed, including Phase 0 scaffold /
  validation-status (`195` checks), Phase 5 fixed-effect single-marker scan
  (`72` checks), and Phase 4B structured genetic covariance (`61` checks), on
  the reconciled PR #23 branch state.
- After clearing generated `docs/build`, `docs/node_modules`,
  `docs/package-lock.json`, ignored `docs/Manifest.toml`, recreating the
  temporary `docs/package.json` from the DocumenterVitepress template, and
  using a fresh temporary npm cache at `/private/tmp/hsquared-npm-cache-pr23`,
  the first docs run reached VitePress but failed after npm install because
  the temporary `docs/package.json` disappeared before the npm script phase.
  Restoring the same temporary `docs/package.json` and rerunning
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 NPM_CONFIG_CACHE=/private/tmp/hsquared-npm-cache-pr23 npm_config_cache=/private/tmp/hsquared-npm-cache-pr23 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`
  passed. Generated docs/npm files and the temporary npm cache were removed
  again before commit. Known caveats remained: 8 unrelated docstrings not
  included in the manual, local deployment skipped, VitePress default
  substitutions, missing local logo/favicon substitutions, and 4 npm audit
  advisories in generated docs dependencies.

## Public Claim Audit

Allowed claim: PR #23 is reconciled locally against the repaired PR #22 base
while preserving its deterministic marker-map-backed Manhattan plot-data
output.

Blocked claims remain blocked: no marker-file parser, no plotting
implementation, no mixed-model marker scan, no GWAS/QTL/interval-mapping
claim, no LOCO, no calibrated correlated-marker or genome-wide claim, no R
formula activation, no bridge payload or `result_payload()` change, and no
comparator parity claim.

## Coordination Notes

This is Julia-lane stack maintenance only. The R repository was not edited.
No R issue action is required because no bridge or public R contract changed.

## Known Limitations

- Remote CI/Documenter need to run after push.
- PR #23 remains draft and should not be merged until the stack base decision
  is made by the maintainer.
- Downstream PRs #24 and above should be rechecked after PR #23 is pushed.

## Next Actions

- Push `codex/phase5-marker-map-manhattan`.
- Watch PR #23 CI/Documenter and re-check downstream stack mergeability.

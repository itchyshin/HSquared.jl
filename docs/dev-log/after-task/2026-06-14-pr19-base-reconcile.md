# 2026-06-14 PR19 Base Reconcile

## Task Goal

Resolve PR #19 (`codex/phase5-marker-adjustments`) against the repaired
`codex/phase5-marker-pvalues` base after PR #18 was reconciled with the
Phase 4B train base.

## Active Lenses And Spawned Agents

- Ada/Shannon: keep the stacked train linear and non-merging.
- Fisher/Curie: preserve the multiple-testing adjustment scope.
- Grace: verify low-core local checks before push.
- Rose: keep marker-screening claims bounded to fixed-effect summaries.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- inherited after-task notes from the repaired base branch
- this report

## What Landed

Merged `origin/codex/phase5-marker-pvalues` into
`codex/phase5-marker-adjustments`. The only textual conflict was the
append-only `docs/dev-log/check-log.md`; the resolution keeps:

- the PR #19 fixed-effect marker-scan multiple-testing adjustment evidence;
- the PR #18 base reconcile evidence;
- the PR #17 main reconcile evidence;
- the current GitHub landing-page docs-link evidence.

No engine code, tests, validation-status rows, capability rows, bridge payload,
or R package files changed in this reconcile slice.

## Checks Run

- `git diff --check`: passed after conflict resolution.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. The full package suite passed, including Phase 5 fixed-effect
  single-marker scan (`39` checks) and Phase 4B structured genetic covariance
  (`61` checks), on the reconciled PR #19 branch state.
- Initial docs attempts with the same low-core `include("docs/make.jl")`
  command failed in local generated npm/VitePress state: first on stale
  `docs/node_modules` cleanup, then on a regenerated docs manifest /
  temporary `docs/package.json` mismatch.
- After clearing generated `docs/build`, `docs/node_modules`,
  `docs/package-lock.json`, ignored `docs/Manifest.toml`, and recreating the
  temporary `docs/package.json` from the DocumenterVitepress template, rerunning
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`
  passed. Generated docs/npm files were removed again before commit. Known
  caveats remained: 8 unrelated docstrings not included in the manual, local
  deployment skipped, VitePress default substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.
- Remote workflow-dispatch checks for pushed commit `e9853ff` passed:
  CI `27515455662` and Documenter `27515455643`.

## Public Claim Audit

Allowed claim: PR #19 is reconciled locally against the repaired PR #18 base
while preserving its deterministic Bonferroni and Benjamini-Hochberg output
scope.

Blocked claims remain blocked: no calibrated mixed-model p-values, no LOCO,
no LOD, no correlated-marker or genome-wide calibration claim, no R formula
activation, no bridge payload or `result_payload()` change, and no comparator
parity claim.

## Coordination Notes

This is Julia-lane stack maintenance only. The R repository was not edited.
No R issue action is required because no bridge or public R contract changed.

## Known Limitations

- Remote CI/Documenter need to run after push.
- PR #19 remains draft and should not be merged until the stack base decision
  is made by the maintainer.
- Downstream PRs #20 and above should be rechecked after PR #19 is pushed.

## Next Actions

- Push `codex/phase5-marker-adjustments`.
- Watch PR #19 CI/Documenter and re-check downstream stack mergeability.

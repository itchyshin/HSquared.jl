# 2026-06-14 PR25 Base Reconcile

## Task Goal

Resolve PR #25 (`codex/phase5-mixed-marker-scan`) against the repaired PR #24
base (`codex/phase5-marker-qq-data`) while preserving the supplied-variance
mixed marker-scan scope and keeping the stacked Phase 5 train linear.

## Active Lenses And Spawned Agents

- Ada/Shannon: keep the branch stack linear and non-merging.
- Gauss: preserve the supplied-variance GLS linear-algebra boundary.
- Fisher: preserve Wald-test and p-value claim boundaries.
- Grace: verify low-core local checks before push.
- Rose: prevent LOCO, calibration, plotting, R syntax, bridge, or comparator
  claims.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- inherited after-task notes from the repaired base branch
- this report

## What Landed

Merged `origin/codex/phase5-marker-qq-data` into
`codex/phase5-mixed-marker-scan`. The reconciliation preserved:

- the PR #25 supplied-variance mixed marker-scan evidence;
- the PR #24 QQ plot-data base reconcile and feature evidence;
- the PR #23 marker-map-backed Manhattan evidence;
- the PR #22 Manhattan plot-data evidence;
- the PR #20 LOD-equivalent score evidence;
- the PR #19 multiple-testing adjustment evidence;
- the PR #18 p-value evidence;
- the PR #17 Phase 4B main-reconcile evidence;
- the current GitHub landing-page docs-link evidence.

No engine code, tests, validation-status rows, capability rows, bridge payload,
`result_payload()`, R package files, LOCO path, plotting backend,
genomic-inflation calibration, mixed-model calibration claim, or public claims
changed in this reconcile slice.

## Checks Run

- `git diff --check`: passed after conflict resolution.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. The full package suite passed, including Phase 0 scaffold /
  validation-status (`206` checks), Phase 5 fixed-effect single-marker scan
  (`123` checks), and Phase 4B structured genetic covariance (`61` checks), on
  the reconciled PR #25 branch state before the final PR #24 evidence-wording
  merge, which changed only dev-log files.
- After clearing generated docs/npm artifacts, preserving an empty
  `docs/build` directory for local example expansion, using a keeper loop to
  restore the temporary DocumenterVitepress `docs/package.json` if npm removed
  it mid-build, and using fresh npm cache
  `/private/tmp/hsquared-npm-cache-pr25`, rerunning
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 NPM_CONFIG_CACHE=/private/tmp/hsquared-npm-cache-pr25 npm_config_cache=/private/tmp/hsquared-npm-cache-pr25 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`
  passed before the final PR #24 evidence-wording merge, which changed only
  dev-log files. Generated docs/npm files and the temporary npm cache were
  removed again before commit. Known caveats remained: 8 unrelated docstrings
  not included in the manual, local deployment skipped, VitePress default
  substitutions, missing local logo/favicon substitutions, and 4 npm audit
  advisories in generated docs dependencies.

## Public Claim Audit

Allowed claim: PR #25 is locally reconciled against the repaired PR #24 base
while preserving its direct dense supplied-variance mixed marker-screening
utility.

Blocked claims remain blocked: no variance-component estimation inside the
scan, no LOCO, no sparse production marker scan, no calibrated mixed-model
p-values, no genomic-inflation calibration, no interval-mapping or mixed-model
LOD workflow, no plotting backend, no R `marker_scan()` activation, no bridge
payload or `result_payload()` change, and no comparator parity claim.

## Coordination Notes

This is Julia-lane stack maintenance only. The R repository was not edited.
No R issue action is required because no bridge or public R contract changed.

## What Did Not Go Smoothly

- The first merge conflict was limited to the append-only check log. A later
  PR #24 evidence-wording correction merged cleanly into this branch.
- Local docs used the same temporary `docs/package.json` keeper workaround
  recorded for PR #24 to avoid generated DocumenterVitepress/npm state
  failures.

## Known Limitations

- Remote CI/Documenter need to run after push.
- PR #25 remains draft and should not be merged until the stack base decision
  is made by the maintainer.
- Downstream PRs #26 and above should be rechecked after PR #25 is pushed.

## Next Actions

- Push `codex/phase5-mixed-marker-scan`.
- Watch PR #25 CI/Documenter and then inspect PR #26.

# 2026-06-14 PR24 Base Reconcile

## Task Goal

Resolve PR #24 (`codex/phase5-marker-qq-data`) against the repaired PR #23
base (`codex/phase5-marker-map-manhattan`) while preserving the QQ plot-data
scope and keeping the stacked Phase 5 train linear.

## Active Lenses And Spawned Agents

- Ada/Shannon: keep the branch stack linear and non-merging.
- Florence: preserve the plot-data-only boundary.
- Fisher: preserve QQ/p-value display semantics and avoid calibration claims.
- Grace: verify low-core local checks before push.
- Rose: prevent plotting-backend, genomic-inflation, mixed-model GWAS/QTL, R
  syntax, bridge, or comparator claims.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- inherited after-task notes from the repaired base branch
- this report

## What Landed

Merged `origin/codex/phase5-marker-map-manhattan` into
`codex/phase5-marker-qq-data`. The reconciliation preserved:

- the PR #24 QQ plot-data evidence;
- the PR #23 marker-map-backed Manhattan base reconcile and feature evidence;
- the PR #22 Manhattan plot-data evidence;
- the PR #20 LOD-equivalent score evidence;
- the PR #19 multiple-testing adjustment evidence;
- the PR #18 p-value evidence;
- the PR #17 Phase 4B main-reconcile evidence;
- the current GitHub landing-page docs-link evidence.

No engine code, tests, validation-status rows, capability rows, bridge payload,
`result_payload()`, R package files, plotting backend, genomic-inflation
calibration, mixed-model marker scan, or public claims changed in this
reconcile slice.

## Checks Run

- `git diff --check`: passed on the clean reconciled branch before ledger
  edits.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. The full package suite passed, including Phase 0 scaffold /
  validation-status (`197` checks), Phase 5 fixed-effect single-marker scan
  (`91` checks), and Phase 4B structured genetic covariance (`61` checks), on
  the reconciled PR #24 branch state.
- Local docs retries exposed generated-state failures in
  DocumenterVitepress/npm rather than Julia doc-content failures: missing
  temporary `docs/package.json`, an `ENOTEMPTY` cleanup failure in
  `docs/node_modules`, and an over-cleaned missing `docs/build` directory for
  warn-only example expansion.
- After clearing generated docs/npm artifacts, preserving an empty
  `docs/build` directory for local example expansion, using a keeper loop to
  restore the temporary DocumenterVitepress `docs/package.json` if npm removed
  it mid-build, and using fresh npm cache
  `/private/tmp/hsquared-npm-cache-pr24d`, rerunning
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 NPM_CONFIG_CACHE=/private/tmp/hsquared-npm-cache-pr24d npm_config_cache=/private/tmp/hsquared-npm-cache-pr24d nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`
  passed. Generated docs/npm files and temporary npm caches were removed again
  before commit. Known caveats remained: 8 unrelated docstrings not included
  in the manual, local deployment skipped, VitePress default substitutions,
  missing local logo/favicon substitutions, and 4 npm audit advisories in
  generated docs dependencies.
- Remote workflow-dispatch checks for pushed correction commit `43c28b5`:
  - CI `27516836843`: success on
    <https://github.com/itchyshin/HSquared.jl/actions/runs/27516836843>.
  - Documenter `27516837405`: success on
    <https://github.com/itchyshin/HSquared.jl/actions/runs/27516837405>.
  - Earlier Documenter run `27516780108` was cancelled by the workflow
    concurrency group and superseded by successful run `27516837405`.
  - Known non-failing Node.js 20 deprecation annotations were emitted by
    upstream actions forced onto Node.js 24.

## Public Claim Audit

Allowed claim: PR #24 is locally reconciled against the repaired PR #23 base
while preserving its deterministic fixed-effect marker-scan QQ plot-data output.

Blocked claims remain blocked: no plotting backend, no genomic-inflation
calibration, no calibrated p-values, no marker-file parser, no mixed-model
marker scan, no GWAS/QTL/interval-mapping claim, no LOCO, no R
`marker_scan()` activation, no bridge payload or `result_payload()` change,
and no comparator parity claim.

## Coordination Notes

This is Julia-lane stack maintenance only. The R repository was not edited.
No R issue action is required because no bridge or public R contract changed.

## What Did Not Go Smoothly

- Local docs needed several retries around generated DocumenterVitepress/npm
  state: temporary `package.json` disappearance, one `ENOTEMPTY` cleanup
  failure in `docs/node_modules`, and one over-cleaned missing `docs/build`
  example-workdir failure. The final keeper-backed fresh-cache run passed.

## Known Limitations

- PR #24 remains draft and should not be merged until the stack base decision
  is made by the maintainer.
- Downstream PRs #25 and above should be rechecked after PR #24 is pushed.

## Next Actions

- Inspect PR #25.

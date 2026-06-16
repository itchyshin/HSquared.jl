# 2026-06-16 PR27 Base Reconcile

## Task Goal

Resolve PR #27 (`codex/phase5-loco-relationship-precisions`) against the final
PR #26 base (`codex/phase5-loco-marker-scan`) after PR #26's remote-check
evidence commit, while preserving the narrow dense LOCO
relationship-precision construction scope.

## Active Lenses And Spawned Agents

- Ada/Shannon: keep the stacked Phase 5 train linear.
- Gauss: preserve the VanRaden-plus-ridge LOCO precision-construction
  boundary.
- Fisher: preserve the approximate Wald-test / p-value claim boundary inherited
  from the marker-scan helpers.
- Grace: verify local checks before push.
- Rose: prevent R syntax, bridge, public LOCO workflow, calibration, plotting,
  or comparator claims.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- inherited after-task notes from the repaired PR #26 base branch
- this report

## What Landed

Merged `origin/codex/phase5-loco-marker-scan` into
`codex/phase5-loco-relationship-precisions`. The conflict was limited to the
append-only check log and was resolved by preserving both:

- the PR #27 LOCO relationship-precision construction evidence; and
- the final PR #26 base-reconcile evidence.

No engine code, tests, API docs, validation-status rows, capability-status
rows, validation-debt rows, bridge contract files, R repository files, bridge
payload, or `result_payload()` shape changed in this reconcile slice beyond the
inherited final PR #26 evidence.

## Checks Run

- `git diff --check`: passed after conflict resolution.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. The full package suite passed, including Phase 0 scaffold /
  validation-status (`215` checks), Phase 5 fixed-effect single-marker scan
  (`157` checks), and Phase 4B structured genetic covariance (`61` checks).
- After clearing generated docs/npm artifacts, preserving an empty `docs/build`
  directory for local example expansion, using a keeper loop to restore the
  temporary DocumenterVitepress `docs/package.json` if npm removed it
  mid-build, and using fresh npm cache `/private/tmp/hsquared-npm-cache-pr27`,
  rerunning
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 NPM_CONFIG_CACHE=/private/tmp/hsquared-npm-cache-pr27 npm_config_cache=/private/tmp/hsquared-npm-cache-pr27 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`
  passed. Generated docs/npm files and the temporary npm cache were removed
  again before commit. Known caveats remained: 8 unrelated docstrings not
  included in the manual, local deployment skipped, VitePress default
  substitutions, missing local logo/favicon substitutions, and 4 npm audit
  advisories in generated docs dependencies.
- Remote follow-up for pushed reconcile commit `bd23dcc`:
  - `/opt/homebrew/bin/gh run watch 27613664700 --repo itchyshin/HSquared.jl --exit-status`:
    passed. CI completed for Julia 1 and Julia 1.10; GitHub emitted the known
    non-failing Node.js 20 deprecation annotation.
  - `/opt/homebrew/bin/gh run watch 27613664742 --repo itchyshin/HSquared.jl --exit-status`:
    passed. Documenter completed in 2m51s; GitHub emitted the same known
    non-failing Node.js 20 deprecation annotation.
  - PR #27 was mergeable/clean at head `bd23dcc` after the remote checks.

## Public Claim Audit

Allowed claim: PR #27 is locally reconciled against the final PR #26 base while
preserving its dense validation-scale `loco_relationship_precisions()` helper.

Blocked claims remain blocked: no public LOCO workflow defaults, no marker-scan
variance-component estimation, no sparse production scan, no calibrated
mixed-model p-values, no calibrated PVE/model-R2 claim, no plotting backend, no
R `marker_scan()` activation, no bridge payload or `result_payload()` change,
and no comparator parity claim.

## Tests Of The Tests

This reconcile slice did not add or change tests. It reran the full package
suite after conflict resolution so the existing PR #27 LOCO construction tests,
PR #26 supplied LOCO selection tests, and upstream Phase 5/Phase 4B checks were
exercised together on the reconciled stack state.

## Coordination Notes

This is Julia-lane stack maintenance only. The R repository was not edited.
No R issue action is required because no bridge or public R contract changed.

## What Did Not Go Smoothly

The only conflict was the append-only check log, where the PR #27 feature entry
and PR #26 reconcile entry both wanted the newest position.

## Known Limitations

- PR #27 remains draft and should not be merged until the stack base decision is
  made by the maintainer.
- Downstream PRs #28 and above should be rechecked after PR #27 is pushed.

## Next Actions

- Dispatch CI/Documenter once more after this evidence-only commit lands.
- Continue the stack repair with PR #28 if PR #27 remains clean.

# 2026-06-14 PR26 Base Reconcile

## Task Goal

Resolve PR #26 (`codex/phase5-loco-marker-scan`) against the final PR #25 base
(`codex/phase5-mixed-marker-scan`) after PR #25's remote-check evidence commit,
while preserving the narrow supplied LOCO marker-scan selection scope.

## Active Lenses And Spawned Agents

- Ada/Shannon: keep the stacked Phase 5 train linear.
- Gauss: preserve the supplied relationship-precision selection boundary.
- Fisher: preserve the approximate Wald-test / p-value claim boundary.
- Grace: verify local checks before push.
- Rose: prevent R syntax, bridge, public LOCO workflow, calibration, plotting,
  or comparator claims.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- inherited after-task notes from the repaired PR #25 base branch
- this report

## What Landed

Merged `origin/codex/phase5-mixed-marker-scan` into
`codex/phase5-loco-marker-scan`. The conflict was limited to the append-only
check log and was resolved by preserving both:

- the PR #26 supplied LOCO marker-scan selection evidence; and
- the final PR #25 base-reconcile evidence.

No engine code, tests, API docs, validation-status rows, capability-status
rows, validation-debt rows, bridge contract files, R repository files, bridge
payload, or `result_payload()` shape changed in this reconcile slice beyond the
inherited final PR #25 evidence.

## Checks Run

- `git diff --check`: passed after conflict resolution.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. The full package suite passed, including Phase 0 scaffold /
  validation-status (`213` checks), Phase 5 fixed-effect single-marker scan
  (`142` checks), and Phase 4B structured genetic covariance (`61` checks).

## Public Claim Audit

Allowed claim: PR #26 is locally reconciled against the final PR #25 base while
preserving its supplied LOCO relationship-precision selection helper.

Blocked claims remain blocked: no automatic public LOCO workflow defaults, no
marker-scan variance-component estimation, no sparse production scan, no
calibrated mixed-model p-values, no calibrated PVE/model-R2 claim, no plotting
backend, no R `marker_scan()` activation, no bridge payload or
`result_payload()` change, and no comparator parity claim.

## Coordination Notes

This is Julia-lane stack maintenance only. The R repository was not edited.
No R issue action is required because no bridge or public R contract changed.

## What Did Not Go Smoothly

The only conflict was the append-only check log, where the PR #26 feature
entry and PR #25 reconcile entry both wanted the newest position.

## Known Limitations

- Remote CI/Documenter still need to run after push.
- PR #26 remains draft and should not be merged until the stack base decision is
  made by the maintainer.
- Downstream PRs #27 and above should be rechecked after PR #26 is pushed.

## Next Actions

- Push `codex/phase5-loco-marker-scan`.
- Watch PR #26 CI/Documenter when the work resumes.

# 2026-06-14 PR18 Base Reconcile

## Task Goal

Resolve PR #18 (`codex/phase5-marker-pvalues`) against the repaired
`phase4b-factor-analytic-g` base after PR #17 was reconciled with current
`main`.

## Active Lenses And Spawned Agents

- Ada/Shannon: keep the stacked train linear and non-merging.
- Fisher/Curie: preserve the Phase 5 fixed-effect p-value scope.
- Grace: verify low-core local checks before push.
- Rose: prevent the landing-page merge from widening capability claims.
- Spawned agents: none.

## Files Changed

- `README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-14-github-landing-docs-link.md`
- `docs/dev-log/after-task/2026-06-14-phase4b-pr17-main-reconcile.md`
- this report

## What Landed

Merged `origin/phase4b-factor-analytic-g` into
`codex/phase5-marker-pvalues`. The conflicts were limited to public/docs
evidence files:

- `README.md`: kept the current "Julia engine underneath" wording.
- `docs/dev-log/after-task/2026-06-14-github-landing-docs-link.md`: kept the
  already-merged landing-page audit.
- `docs/dev-log/check-log.md`: preserved PR #17 reconcile evidence, the
  landing-page entry, and the Phase 5 fixed-effect p-value entry.

No engine code, tests, validation-status rows, capability rows, bridge payload,
or R package files changed in this reconcile slice.

## Checks Run

- `git diff --check`: passed after conflict resolution.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. The full package suite passed, including Phase 5 fixed-effect
  single-marker scan (`27` checks) and Phase 4B structured genetic covariance
  (`61` checks), on the reconciled PR #18 branch state.
- `rm -rf docs/build && env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  first attempt rendered the VitePress pages but failed in
  `DocumenterVitepress.deploydocs` because `docs/build/bases.txt` was not yet
  visible at deploy time.
- Re-run without deleting `docs/build`:
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`
  passed with the known local caveats: 8 unrelated docstrings not included in
  the manual, local deployment skipped, VitePress default substitutions,
  missing local logo/favicon/package.json substitutions, and 4 npm audit
  advisories in generated docs dependencies.

## Public Claim Audit

Allowed claim: PR #18 is reconciled locally against the repaired PR #17 base
while preserving its existing fixed-effect Gaussian/Wald p-value scope.

Blocked claims remain blocked: no calibrated mixed-model p-values, no LOD or
multiple-testing expansion beyond existing rows, no LOCO/GWAS/QTL/eQTL public
activation, no R formula activation, no bridge payload or `result_payload()`
change, and no comparator parity claim.

## Coordination Notes

This is Julia-lane stack maintenance only. The R repository was not edited.
No R issue action is required because no bridge or public R contract changed.

## Known Limitations

- The first local docs command built the site but failed in the deploy step
  before the generated `bases.txt` was available. The immediate re-run passed.
- Remote CI/Documenter need to run after push.
- PR #18 remains draft and should not be merged until the stack base decision
  is made by the maintainer.
- Downstream PRs #19 and above were still mergeable before this repair, but
  should be rechecked after PR #18 is pushed.

## Next Actions

- Push `codex/phase5-marker-pvalues`.
- Watch PR #18 CI/Documenter and re-check downstream stack mergeability.

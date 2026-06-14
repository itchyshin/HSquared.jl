# 2026-06-14 Phase 4B PR17 Main Reconcile

## Task Goal

Resolve the `phase4b-factor-analytic-g` draft PR #17 conflict against current
`main` so the Phase 4B structured-covariance base can become mergeable before
more stacked Phase 5 marker work lands.

## Active Lenses And Spawned Agents

- Ada/Shannon: keep the Julia PR stack ordered and non-overlapping.
- Gauss/Karpinski/Kirkpatrick: preserve the existing Phase 4B numerical and
  structured-covariance work.
- Grace: verify local tests and docs after the merge.
- Rose: preserve public-claim boundaries while merging docs evidence.
- Spawned agents: none.

## Files Changed

- `README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-14-github-landing-docs-link.md`
- this report

## What Landed

Merged `origin/main` into `phase4b-factor-analytic-g` and resolved the only
conflict in `docs/dev-log/check-log.md`. A follow-up evidence edit restored
the current-main GitHub landing-page docs-link entry to the top of the
append-only log and added this PR17 reconciliation note.

The merge did not change engine code, R bridge payloads, capability-status
rows, validation-debt rows, or public claims.

## Checks Run

- `git diff --check`: passed.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. The full package suite passed, including Phase 4B structured genetic
  covariance (`61` checks) and Phase 5 fixed-effect single-marker scan (`20`
  checks) on this branch state.
- `rm -rf docs/build && env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats remained: 8 unrelated docstrings not included in
  the manual, local deployment skipped, VitePress default substitutions,
  missing local logo/favicon/package.json substitutions, and 4 npm audit
  advisories in generated docs dependencies.

## Public Claim Audit

Allowed claim: PR #17 has been reconciled locally with current `main` while
preserving the Phase 4B structured-covariance claim boundaries already recorded
on the branch.

Blocked claims remain blocked: no R-facing covariance grammar, no bridge
payload change, no `result_payload()` change, no production sparse
factor-analytic solver, no loading interpretation/rotation convention beyond
the recorded sign convention, no external comparator parity, and no broad
multi-seed recovery calibration claim.

## Tests Of The Tests

This slice did not add test code. The relevant protection is that the existing
full package suite and docs build pass after the merge conflict is resolved.

## Coordination Notes

This is a Julia-lane stack-unblocking slice. It does not edit the R repository.
The downstream Phase 5 marker PRs remain stacked above PR #17 and should not be
merged until PR #17 is green and either approved or explicitly kept as a draft
base for review.

## What Did Not Go Smoothly

The local PR17 conflict-check worktree was already mid-merge from an earlier
attempt. The only unmerged file was `docs/dev-log/check-log.md`; the resolution
kept the branch history and a follow-up restored the `origin/main`
landing-page evidence to the append-only log.

## Known Limitations

- Remote CI/Documenter still need to run after the reconciled branch is pushed.
- PR #17 remains a draft until maintainers decide it is ready.
- The Phase 5 marker stack remains stacked above this base and will need later
  rebasing or retesting after PR #17 moves.

## Next Actions

- Push `phase4b-factor-analytic-g`.
- Watch PR #17 CI and Documenter.
- If green, update the Julia stack status and decide whether to mark PR #17
  ready or keep it draft for human review.

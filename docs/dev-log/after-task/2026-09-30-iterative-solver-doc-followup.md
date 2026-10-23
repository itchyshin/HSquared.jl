## 1. Goal

Correct the matrix-free REML documentation so the optimizer, convergence flag, diagnostic fields, and likelihood values match the implementation.

## 2. Implemented

Revised the relevant `src/iterative_solve.jl` docstrings and inline likelihood comments. The optimizer is described as a stochastic REML score fixed-point iteration, `trace_mcse` is limited to trace-estimation uncertainty, and exact versus stochastic likelihood behavior is stated correctly. Current tests are described as a bounded comparison rather than general recovery evidence.

## 3a. Decisions and Rejected Alternatives

Kept the existing estimator identifier for compatibility. Removed the implied EM ascent and optimum guarantees from the user-facing documentation because the implemented fixed-point update does not establish those properties. Kept the wider capability and release claims unchanged.

## 4. Files Touched

- `src/iterative_solve.jl`
- `docs/dev-log/source-review/2026-09-30-iterative-solver-doc-followup.md`
- `docs/dev-log/check-log.d/2026-09-30-iterative-solver-doc-followup.md`
- `docs/dev-log/coordination-board.md`
- `GATES.md`
- `docs/dev-log/after-task/2026-09-30-iterative-solver-doc-followup.md`

## 5. Checks Run

- Focused Julia tests passed: 249 assertions across Wave 1 numerical and pedigree constructor suites.
- Full candidate command `JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia JULIA_PKG_OFFLINE=true JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test()'` exited 0 and ended `Testing HSquared tests passed`. Julia reported a pre-existing Project/Manifest mismatch warning; no resolve/update was run.
- Documentation build passed in a content-matched temporary copy; Documenter and VitePress rendered the site. Existing 47 orphan-docstring, local deployment, missing favicon/config, and large-bundle warnings remain.
- `git diff --check` passed.
- `bash tools/preamble_cap.sh` passed at 11,024 bytes of 14,000.
- Exact-current reviewer signed off the final doc wording at source SHA-256 `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132`.

## 6. Tests of the Tests

The focused Wave 1 regressions exercise square full-rank fixed-effect solving, final trace MCSE at returned variance components, shared-probe variance behavior, and finite MME diagonals. The pedigree tests cover selfing policy, invalid metafounder conditional variances, group-marker handling, and ID alignment. Earlier red runs in this lane reproduced the solver and pedigree defects before repair. The present doc-only follow-up does not alter behavior.

## 7a. Issue Ledger

- Closed here: stale optimizer and likelihood documentation in `src/iterative_solve.jl`.
- Confirmed in earlier scoped work: square full-rank supplied-variance solve, final-variance trace MCSE, shared-probe precision wording, finite MME diagonal checks, selfing constructor behavior, and metafounder conditional variance guard.
- Carried: stale matrix-free wording and a recovery-status assertion in `src/validation_status.jl`; exact-current evidence and ownership are unresolved.
- Whole E1, A2, and V3 acceptance gates remain open.

## 8. Consistency Audit

Reviewed the adjacent low-level and wrapper docstrings, return fields, and likelihood code paths. An exhaustive Graft search also found older `EM-REML` wording in `src/validation_status.jl`. Preflight reports 34 divergent refs for that file, so it was left untouched in this source-scoped slice. `GATES.md` continues to mark A2, E1, and V3 open. No capability row or covered count changed. A separate Rose public-claims audit remains pending.

## 9. What Did Not Go Smoothly

The first documentation build in `/private/tmp` failed because the copy omitted Git metadata. Adding the worktree `.git` pointer and resolving the local package path allowed the build to complete. The closeout generator's symlink-resolved root is the second-brain checkout, not this project worktree. The project report's structural R check passed. The project gate runner initially could not find Julia because `/bin/sh` did not inherit Juliaup's path. I added the explicit Juliaup directory to the V1 and V2 commands in `GATES.md`; the subsequent ledger check executed those gates and reported the still-open overall programme gates. Those planned gates remain open and were not marked abandoned.

## 10. Known Residuals

The final exact-candidate Julia package suite now passes. This slice does not validate stochastic recovery rates, scale performance, interval coverage, FA identification, GLLVM acceptance, R parity, or all Julia source spans. The V1 validation-status prose remains unreviewed here. No GPU, release submission, registry submission, or tag action occurred.

## 11. Team Learning

An estimator name can outlive the update rule it originally described. State the implemented fixed-point update and what convergence measures; do not transfer an EM ascent guarantee from a neighboring method without checking the equations.

Memory receipt: `route.py` returned no LOAD-FIRST manifest for this project; repository `GATES.md` and current source/test evidence shaped the work. Golden Set: not checked because this bounded code-documentation slice did not match a known-mistake class in the brain.

## 12. Cross-Product Coverage

Covers: Julia matrix-free REML source documentation and the focused solver/pedigree regression suites.

Does NOT cover: the R FA or genetic GLLVM routes, automatic FA rank, broad calibration, all engine/bridge files, status-row reconciliation, whole-wave E1 signoff, A2, V3, GPU execution, or release actions.

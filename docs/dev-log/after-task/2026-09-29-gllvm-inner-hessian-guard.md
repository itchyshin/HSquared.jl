# After-task report: GLLVM inner Hessian failure guard

## 1. Goal

Ensure a finite but nonconverged inner GLLVM mode returns status instead of factoring an observed Hessian. Classify numerical optimizer-trial failures, preserve input errors, and reject an invalid final fitted point.

## 2. Implemented

- The inner kernel returns `loglik = NaN`, mode estimates, gradient norm, stop reason, and backtracks when a finite score misses tolerance. It skips observed-Hessian work on that path.
- Nonfinite scoring quantities, singular or invalid working solves, nonfinite Laplace terms, and non-positive observed curvature use internal typed parameter-evaluation errors.
- The outer objective maps only those typed trial failures to `Inf`. Input-contract errors propagate. The final result must have a converged mode and finite objective.
- The internal kernel docstring now describes this failure contract.

## 3. Decisions and rejected alternatives

- Kept observed curvature for the Laplace correction. No Fisher-curvature substitution, Hessian jitter, or absolute determinant was introduced.
- Kept separate optimizer and inner-mode status fields.
- No simulated biological family or large recovery run was needed. A deterministic synthetic family isolates the numerical cases.

## 4. Files touched in this slice

- `src/genetic_gllvm.jl`
- `test/genetic_gllvm_trait_effects.jl`
- `docs/dev-log/source-review/2026-09-29-gllvm-foundation-followup.md`
- `docs/dev-log/check-log.d/2026-09-29-gllvm-inner-hessian-failure.md`
- `docs/dev-log/coordination-board.md`
- `GATES.md`
- `docs/dev-log/after-task/2026-09-29-gllvm-inner-hessian-guard.md`

These are additions to the already-dirty candidate. Existing changes were preserved.

## 5. Checks run

- First TDD run reproduced a raw `PosDefException` for a finite nonconverged mode.
- Final command: `JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-gllvm-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. test/genetic_gllvm_trait_effects.jl`.
- Result: **61/61 assertions passed**. The new adversarial testset passed **8/8**, covering capped nonconvergence, invalid observed curvature, nonfinite trial curvature, outer final-point rejection, a singular working Hessian, and malformed `Ainv` propagation.
- Gauss reviewed the final source and test diff and approved this bounded failure-path change. The reviewer did not rerun the 61 assertions.
- The default Julia depot could not write its compiled-cache lock. The same focused command passed with a writable temporary depot before the existing depot.
- Fresh full `Pkg.test()` on the integrated candidate exited 0 with `Testing HSquared tests passed` in about 2.5 minutes.
- The docs build exited 0 from `/private/tmp/hsquared-fa-gllvm-docs-copy-20260929-codex` after copying the final `src/genetic_gllvm.jl` (SHA-256 `fd0fb9832b1855f26dc36bb3cffd3b15e131629c4863a1c3db854e1aa8039df4`). It reported 47 docstrings outside manual blocks, skipped local deployment, used default VitePress configuration and favicon settings, and warned about one bundle above 500 kB. These are existing documentation setup warnings; page rendering completed.
- The three new report/check-note files passed `slop_check.py` with 0 findings. The updated source-review packet had 6.2 findings per 1000 words, all in pre-existing review prose, with no em dashes.
- `git diff --check` passed, and `bash tools/build_check_log.sh --check` reported all 210 shards well-formed. Unlazy status still reports A2, E1, and V3 open (8/11 gates met).

## 6. Tests of the tests

The red run failed at Cholesky with the expected raw `PosDefException`, proving the original defect. After repair, the synthetic family reaches the nonconverged and stationary-but-invalid-curvature paths with the specified 1-record setup. Additional cases prove the final optimizer guard and that malformed relationship input is not swallowed by the optimizer catch.

## 7. Issue ledger

- Closed in this slice: premature observed-Hessian factorization; raw failure on non-positive observed curvature; nonfinite/singular parameter-local scoring paths escaping the outer optimizer; invalid final mode accepted as a fit.
- Carried: mode-tolerance scaling, broader ordinary-start recovery and calibration, external matched-objective comparator, sparse scaling, and broader GLLVM validation.
- The narrow code finding does not close GLLVM capability or whole-wave source-review gates.

## 8. Consistency and claim audit

Updated the GLLVM source-review finding, the dated check-log shard, the coordination board, and E1 evidence in `GATES.md`. The capability remains experimental and the GLLVM gates remain open. No R bridge change, capability promotion, public release claim, CRAN submission, registry submission, or tag is implied.

## 9. What did not go smoothly

The first test invocation used the default Julia depot and stopped because the sandbox denied a compiled-cache lock write. A temporary writable depot resolved that without changing the package environment. The managed-worktree LOAD-FIRST route returned no project manifest. The lane preflight warned that an older handover named Claude; the active candidate and exact non-overlapping hunk were retained from the prior checkpoint. No R bridge files were changed.

## 10. Known limitations

The tests use synthetic response families only as branch instruments. They do not establish biological-model recovery, optimizer reliability, calibration, performance, or wider model support. Totoro is available again, but no campaign was started. The frozen 200-seed FA study remains estimated at about 8.5 hours and still requires explicit approval under the compute gate.

## 11. Team learning

The independent Gauss review improved the first implementation by identifying nonfinite trial points, final-fit acceptance, and singular working-curvature gaps. The second test pass and final review closed those bounded defects. This review does not constitute whole-wave signoff.

## 12. Cross-product coverage and next action

Covers: Julia genetic-GLLVM internal Laplace failure handling and its direct focused test.

Does not cover: R bridge/control changes, full package checks, external comparator evidence, broad GLLVM calibration, FA population recovery, GPU execution, automatic-rank behavior, whole-wave source review, any package submission, or a public release tag.

Next: continue the existing bounded GLLVM foundation/source-review arc and keep its open gates explicit. The 200-seed FA run remains held for user approval.

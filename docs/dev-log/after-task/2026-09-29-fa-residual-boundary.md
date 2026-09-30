## 1. Goal

Reject singular residual covariance proposals in the bounded multivariate REML
optimizer, including the Gaussian FA route, without changing the behavior of
other fitters that share the covariance transform.

## 2. Implemented

`_mv_reml_objective` now maps non-positive-definite residual covariance
proposals to `Inf` before evaluating the marginal likelihood. Returned
multivariate optimizer attempts also require positive-definite residual
covariance. The shared Cholesky transform itself remains unchanged.

## 3a. Decisions and Rejected Alternatives

- Rejected a positive-definiteness exception in the shared transform after
  Gauss found that repeatability, direct-maternal, and random-regression
  objectives call it outside their catches.
- Kept the repair in `fit_multivariate_reml`, where rejected trial points are
  already handled as `Inf`; added the same validity rule to result selection.
- No capability or release status change was justified by this numerical guard.

## 4. Files Touched

- `src/multivariate.jl`
- `test/test_multivariate_fa_multistart.jl`
- `GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-09-29-fa-residual-boundary.md`
- `docs/dev-log/source-review/2026-09-29-fa-residual-boundary.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-fa-residual-boundary.md`

## 5. Checks Run

- TDD probe failed before the fix: singular `R0` yielded finite objective
  `2.717389505828925`.
- Focused FA multistart file: 49/49 assertions passed.
- Full Julia 1.10 `Pkg.test()` exited 0 and printed `Testing HSquared tests
  passed` and `PKG_TEST_DONE`.
- `git diff --check` passed for the source and test edits. Closeout prose and
  receipt checks are recorded below after the structural checker runs.
- The test command warned that project dependencies or compatibility differ
  from the resolved manifest. No resolve or update was run.
- Gauss passed the exact source/test hashes. Rose's claim audit found no status
  change warranted.

## 6. Tests of the Tests

The new assertions first construct the underflowed residual covariance and
confirm it is singular. Before the implementation guard, the final assertion
failed because the objective returned the finite value above. It now requires
`Inf`. The focused test therefore detects this specific regression.

## 7a. Issue Ledger

- Fixed: in `fit_multivariate_reml`, residual Cholesky underflow could create a
  singular `R0` while the data-level covariance remained positive definite and
  the REML objective appeared finite.
- Deferred: underflow behavior in repeatability, direct-maternal, and
  random-regression fitter objectives sharing the transform. The shared helper
  was deliberately left unchanged in this slice.

## 8. Consistency Audit

Reviewed the shared transform callers and exact source/test candidate. The
final guard is confined to `fit_multivariate_reml`; it does not alter sibling
fitter exception handling. The capability and validation-debt descriptions
remain accurate without edits. `GATES.md` now refreshes the focused-test count
and exact hashes while retaining A2 as open.

## 9. What Did Not Go Smoothly

The first implementation put the PD guard in the shared helper. Exact-hash
review found that sibling objectives could then throw before their existing
error handlers. That candidate was discarded, the guard moved to the
multivariate REML objective and result validity, and tests were rerun against
the final source. The first full-suite run overlapped that edit and failed on
the discarded candidate; the final run against stable source exited 0.

The provided `closeout.py new` helper resolved paths under the second-brain
root and could not write the package report. No file was created there. This
report was created directly in the package worktree; its structure was checked
with the repository-independent R validator.

## 10. Known Residuals

The full FA A2 gate remains open for fitted likelihood information,
near-floor behavior, routine-start recovery, broad inference, and whole-wave
panel signoff. The helper-level transform can still produce a singular
covariance for extreme values in other fitter paths; those paths are not
covered by this change. The project/manifest warning remains unresolved.

## 11. Team Learning

Reject an optimizer proposal at the objective boundary that owns its error
contract. A shared covariance conversion is unsafe for new exceptions until
every caller's optimizer boundary has been checked.

Memory receipt: loaded the HSquared LOAD-FIRST manifest and repo review rules;
the stale manifest's #366-first pointer was treated as a routing lead and
checked against current repo evidence. No sister-project scout was part of this
slice.

Golden Set: `memory_regression.py --selftest` passed; the known-mistake Golden
Set was checked for the closeout.

## 12. Cross-Product Coverage

Covers: the dense Gaussian `fit_multivariate_reml` optimizer's residual
covariance proposal and fitted-attempt validation, including FA.

Does NOT cover: repeatability, direct-maternal, or random-regression fits that
use the shared transform; R bridge parity; recovery or inference calibration;
the broader FA or GLLVM acceptance gates; GPU execution; registry or CRAN
submission; public release tags.

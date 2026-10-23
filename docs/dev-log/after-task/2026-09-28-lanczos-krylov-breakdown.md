# Lanczos Krylov breakdown repair

## 1. Goal

Stop the matrix-free SLQ Lanczos routine from forming nonfinite tridiagonals or hanging after its Krylov space is exhausted. Preserve scale-relative behavior and test requests longer than the operator dimension.

## 2. Implemented

- Cap allocated Lanczos steps at the operator dimension and validate the starting vector and positive step count.
- Re-orthogonalize the residual twice before testing its norm; detect breakdown relative to operator scale and dimension.
- Return `NaN` before eigendecomposition if the operator output, residual, or tridiagonal is nonfinite.
- Add regression checks for three operator scales, a request of 40 steps in dimension 3, and a repeated-eigenvalue operator whose Krylov dimension is below its matrix dimension.

## 3a. Decisions and Rejected Alternatives

- Kept a relative breakdown rule instead of restoring the old absolute `1e-12` threshold, which truncates valid small-scale operators.
- Kept the existing `NaN` convention for invalid SLQ numerical results rather than inventing a new public exception contract.
- Did not change the public capability status or claim broader matrix-free scalability.

## 4. Files Touched

- `src/iterative_solve.jl`
- `test/wave1_numerical_contracts.jl`
- `docs/dev-log/after-task/2026-09-28-lanczos-krylov-breakdown.md`

## 5. Checks Run

- `julia --compiled-modules=no --project=. -e 'include("test/wave1_numerical_contracts.jl")'`: PASS, 87/87 assertions, 10.9 seconds.
- `git diff --check`: PASS.
- No full `Pkg.test()`, documentation build, CI run, simulation campaign, or GPU work was performed.

## 6. Tests of the Tests

The new checks assert the known exact SLQ values for diagonal positive-definite operators. The independent Astra review reproduced the old failure on a three-dimensional SPD operator: after Krylov exhaustion the tridiagonal contained NaNs and LAPACK hung. It also verified that the earlier absolute threshold returned the expected `log(6)/3` value. I did not run the old implementation under a timeout again, and did not perform mutation testing.

## 7a. Issue Ledger

- This slice fixes Lanczos continuing after a numerically exhausted Krylov basis and reaching eigendecomposition with NaNs.
- Bridge dispatch and result-shape findings, data validation findings, FA test registration, and interval fixtures that conflict with the new boundary guard remain open in other files or lanes. These read-only findings are not changed here.
- Several non-Gaussian improper-integral and initialization risks predate this slice. See the source-review findings shared in this task.

## 8. Consistency Audit

The review traced callers through `matrix_free_reml_loglik`, matrix-free MC REML fitting, and the registered V1 matrix-free tests. The existing scale test remains in place. The new test file is included by `test/runtests.jl` through `wave1_numerical_contracts.jl`. The routine remains an internal SLQ helper and no result schema changed.

## 9. What Did Not Go Smoothly

The sandbox initially prevented writing the shared lane lease outside the repository roots. After a narrow permission grant, the central lease was created successfully. The existing committed graft graph did not match the candidate file's line numbers, so the implementation was checked against the exact candidate source.

## 10. Known Residuals

- Full package tests and cross-version CI remain unverified.
- The shared `check-log.md` update is deferred because the live source-review-closeout lease owns that file.
- The Lanczos quadrature still assumes a symmetric positive-definite operator supplied by its caller; this slice only prevents invalid numerical state from reaching eigendecomposition.
- The new threshold is checked on the focused scale and repeated-spectrum fixtures, not on a broad conditioning campaign.
- The task's bridge, FA, and GLLVM acceptance gates remain open; this slice does not finish the twin programme.

## 11. Team Learning

For fully re-orthogonalized Lanczos, check the residual after orthogonalization and before normalizing it. A pre-orthogonalization norm can be larger than the true residual at Krylov breakdown and allow a numerically empty direction into the basis.

## 12. Cross-Product Coverage

- Matrix-free Gaussian SLQ likelihood path: covered ✓ for finite positive diagonal operators at three scales, `k > N`, and repeated eigenvalues.
- Ordinary sparse REML, FA covariance estimation, Poisson GLLVM, R bridge payloads, and release claims: does NOT cover these surfaces.

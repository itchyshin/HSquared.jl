# FA residual covariance underflow boundary

## Scope

Exact review of the singular-residual optimizer-trial defect in
`fit_multivariate_reml`. This receipt does not close the full FA engine review
(A2).

## Source and change

- `_mv_reml_objective` checks that transformed `R0` is positive definite before
  evaluating the marginal REML likelihood.
- Optimizer-attempt validity checks `R0` again so an invalid final simplex point
  cannot be selected as a fitted result.
- The shared `_chol_params_to_cov` helper remains unchanged. This prevents the
  repair from changing exception behavior in repeatability, direct-maternal, and
  random-regression fitters that also call the helper.

## Finding and test

The exact `exp(-1000)` residual log-Cholesky case produced singular `R0` while
the objective returned finite `2.717389505828925`. The new regression asserts
that the transformed covariance is singular and that the objective returns
`Inf`. Before the fix, that assertion failed with the finite objective above.

Focused file: `test/test_multivariate_fa_multistart.jl`, 49/49 assertions pass.
Full Julia 1.10 `Pkg.test()` exits 0 and prints `Testing HSquared tests passed`.
The usual project/manifest mismatch warning remains; no resolve or update was
run.

## Independent reviews

- Gauss re-reviewed source SHA-256
  `8e39fc4df7ec95cf4fdd5e5485f18ddcf055e2a5eb41a8886c905584b2a1321c` and test
  SHA-256 `ad018c2c60a4d7e5cf58d3cea8adb62e94dd8cabf99499d139b2c54674f20616`.
  Verdict: bounded underflow defect closed; no sibling fitter regression from
  the final scoped implementation. The PD guard is negligible relative to the
  dense likelihood factorization at the measured tiny cell; no general timing
  claim is made.
- Rose audit: no capability, covered-count, or public-claim change. A2 remains
  open.

## Status and limits

This closes only the singular residual trial-point defect for
`fit_multivariate_reml`. Shared-helper underflow behavior in repeatability,
direct-maternal, and random-regression fitters remains unreviewed. The FA
near-floor information, routine-start recovery, broad inference, and whole-wave
panel gates remain open. No capability row or validation-debt row changed.

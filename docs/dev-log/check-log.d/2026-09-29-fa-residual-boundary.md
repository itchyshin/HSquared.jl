# 2026-09-29 FA residual covariance underflow boundary

- Regression-first probe reproduced a finite FA REML objective
  (`2.717389505828925`) with singular residual covariance after both residual
  log-Cholesky diagonals underflowed at `-1000`.
- The test failed before the objective guard. After the repair, the focused
  `test/test_multivariate_fa_multistart.jl` file passed 49/49 assertions.
- Final Julia 1.10 command:
  `JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test(); println("PKG_TEST_DONE")'`
  exited 0, printing `Testing HSquared tests passed` and `PKG_TEST_DONE`.
- `Pkg.test()` reported that project dependencies or compat requirements differ
  from the resolved manifest. No resolve or package update was run.
- Source SHA-256:
  `8e39fc4df7ec95cf4fdd5e5485f18ddcf055e2a5eb41a8886c905584b2a1321c`.
- Test SHA-256:
  `ad018c2c60a4d7e5cf58d3cea8adb62e94dd8cabf99499d139b2c54674f20616`.
- Gauss's exact-hash numerical review passed this bounded repair. Rose found no
  public claim or capability change warranted. The full FA A2 gate remains open.
- No simulation, GPU execution, CRAN/registry submission, release tag, merge,
  or commit.

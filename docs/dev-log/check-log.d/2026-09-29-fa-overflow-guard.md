# 2026-09-29 FA optimizer overflow guard

## Scope

Handle overflowing covariance-parameter proposals as invalid optimizer trials,
while surfacing invariant fixed-design and malformed-input failures.

## Checks

- RED: the duplicate-column fixed-effect fixture returned a fit instead of a
  full-column-rank error.
- Focused multistart tests passed 47/47. This includes finite versus
  overflowing objective points, invalid covariance conversion, malformed
  parameter length, unrelated dimension-error propagation, residual
  Cholesky overflow, NaN objective handling, and fixed-design rank refusal.
- Focused FA uniqueness and production-map Jacobian tests passed 29/29.
- Full command `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia --project=.
  -e 'using Pkg; Pkg.test()'` exited 0 and reported `Testing HSquared tests
  passed`.
- Full command `JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia
  JULIA_PKG_OFFLINE=true OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia
  --project=docs docs/make.jl` exited 0. Existing warnings remain for 47
  docstrings absent from the manual, environment/deployment settings,
  VitePress customization/favicon/package metadata, and the large JavaScript
  chunk.
- Julia emitted a warning that project dependencies or compat requirements
  had changed since the manifest was last resolved. The test run did not
  resolve or update dependencies.
- Gauss independently reviewed the current helper and tests and passed the
  narrow exception-scope and overflow-handling change. This is not full FA A2
  signoff.
- Current `src/multivariate.jl` SHA-256:
  `2cd41a9745802ef8899cc354e3f4a07d03a6a5eb481f8589cb4d48f945d716a0`.
- `git diff --check`, after-task structure validation, report prose check, and
  Julia docs build: passed (with the warnings above).
- Acceptance ledger: A2, E1, and V3 remain unmet; eight other gates are met.

## Limits

This repairs the candidate-transform crash and rejects rank-deficient fixed
designs before optimization. It does not establish FA recovery, covariance
information, inference calibration, or A2 signoff. No recovery campaign or
GPU work was run.

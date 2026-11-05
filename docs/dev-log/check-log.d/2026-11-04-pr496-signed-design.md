# 2026-11-04 PR 496 signed design

On Julia 1.12.6 with `OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=2`:

- `julia --startup-file=no --project=. -e 'using HSquared; include("test/test_issue_421_sparse_laplace.jl")'`: 194 passed.
- Before the source change, the added signed-design test raised the original missing-pattern `ArgumentError`.
- Dense inverse helper controls include a missing selected entry with nonzero true inverse value.
- Full package CI and Windows are pending.

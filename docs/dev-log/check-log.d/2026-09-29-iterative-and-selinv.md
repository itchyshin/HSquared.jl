# Check log shard: iterative solver and selected-inverse review

- Date: 2026-09-29.
- Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- `src/iterative_solve.jl` SHA-256 `265cfc8d6ba9ca33475b85c56c4701cdd0359b90db9b0cdcae47c6740f4d8a34`; Gauss conditional PASS; matrix-free rank/finite-value/PCG-finiteness findings carried.
- `src/takahashi_selinv.jl` SHA-256 `2c43535a5def218e73d3fee49cad886ca173cbf3c86a5d58167b446027388fd1`; Karpinski PASS for mathematical and interface correctness; performance evidence not claimed.
- Inspected tests: `test/test_matfree_reml_inci_pins.jl` SHA `decca8dccfdb244e8260f5bfacf1da5c05a10602a70b718ba4761ea514608282`; `test/test_selinv_trace_contracts.jl` SHA `0a846c9fc6850f6808eb1229f0310cd0bc4384da66311f816f3bd6c6e92dd57d`.
- Parent-run full `Pkg.test()` on the same worktree after current source changes: exit 0, ends `Testing HSquared tests passed`.
- No benchmark, simulation, performance measurement, GPU run, or source edit by reviewers.

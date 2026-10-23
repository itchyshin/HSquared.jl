# Selected inverse and iterative solver review

Gauss reviewed `src/takahashi_selinv.jl` SHA-256 `2c43535a5def218e73d3fee49cad886ca173cbf3c86a5d58167b446027388fd1`. The recursion and permutation mapping appear consistent for successful sparse Cholesky factors; no accidental densification was found. Open findings include an implicit finite-positive factor precondition, support validation after recursion, and missing severe-conditioning/factor-finiteness evidence.

Karpinski reviewed `src/iterative_solve.jl` SHA-256 `265cfc8d6ba9ca33475b85c56c4701cdd0359b90db9b0cdcae47c6740f4d8a34`. Small-case numerical tests cover the inspected correctness paths. Open evidence includes factor-fill/RSS, per-iteration allocations, type stability, and targeted extreme-scale breakdown behavior; no performance claim is supported.

Neither reviewer ran tests or benchmarks. Julia 1.10 `Pkg.test()` passed afterward on unchanged source hashes, ending `Testing HSquared tests passed`; existing Project/Manifest mismatch warning retained and no resolve/update run. E1 remains open. No capability, validation-debt, covered-count, release, or GPU status changed.

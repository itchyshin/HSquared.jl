# Exact-current source review: iterative solvers and selected inverse

Candidate: `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.

## `src/iterative_solve.jl`

- SHA-256: `265cfc8d6ba9ca33475b85c56c4701cdd0359b90db9b0cdcae47c6740f4d8a34`.
- Reviewed sparse relationship precision canonicalization/validation at lines 289–319 and multi-effect matrix-free solver input and diagonal checks at 399–477; cross-checked matrix-free and wave1 numerical contracts.
- Verdict: conditional PASS for sparse precision symmetry/SPD validation. The sparse canonicalizer rejects nonsquare, nonfinite, materially asymmetric, singular, and indefinite precision; accepted roundoff asymmetry is averaged and the same sparse matrix is used downstream.
- Carried moderate-risk gaps: the matrix-free public solver requires only `p < n`, not full rank of `X`, so redundant fixed-effect columns can make beta non-unique; `y`, `X`, and `Z` lack finite-after-conversion checks, and positive diagonal checks admit `Inf`. The PCG recurrence checks positive curvature but does not consistently require finite intermediate and residual values. The pinned `test/test_matfree_reml_inci_pins.jl` hash is `decca8dccfdb244e8260f5bfacf1da5c05a10602a70b718ba4761ea514608282`; its coverage includes solver reductions and starvation diagnostics, not these malformed inputs. No repair or simulation was run in this review.

## `src/takahashi_selinv.jl`

- SHA-256: `2c43535a5def218e73d3fee49cad886ca173cbf3c86a5d58167b446027388fd1`.
- Reviewed selected-inverse and trace spans 94–205, 256–365, and 387–422; exact registered contract test hash `0a846c9fc6850f6808eb1229f0310cd0bc4384da66311f816f3bd6c6e92dd57d`.
- Verdict: PASS for selected-inverse/trace math and interface contracts. The scatter recurrence, selected-entry indexing, permutation mapping, block bounds, and strict-order seam are coherent with the tests. Coverage includes independent dense checks, nonidentity permutations, invalid supports/dimensions, bitwise scatter parity, SIMD tolerance, fit/PEV checks, and multi-effect score/reduction tests.
- Nonblocking carried performance/robustness limits: complexity remains `Θ(Σⱼ |L[:,j]|²)` and scratch includes storage proportional to `nnz(L)`; no exact-source benchmark or allocation profile was run. Production-shaped type-stability, adversarial conditioning/dynamic range, and high-fill resource behavior remain to measure before broad speed or memory claims. Existing benchmark pin should not be bypassed.

## Panel and execution boundary

Gauss reviewed `iterative_solve.jl`; Karpinski reviewed `takahashi_selinv.jl`. Their verdicts apply to these pinned scopes only. The full local Julia suite was run by the parent candidate after the latest shared likelihood changes and passed, but this does not resolve the listed input gaps or establish performance. E1 remains open.

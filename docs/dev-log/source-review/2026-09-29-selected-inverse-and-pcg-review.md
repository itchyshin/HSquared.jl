# Exact-current selected-inverse and PCG source review

- Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Scope: selected-inverse recursion and sparse matrix-free iterative solver; this records two disjoint, read-only component reviews, not E1 signoff.
- Reviewers: Gauss reviewed Takahashi selected inversion; Karpinski reviewed iterative-solver performance and numerical controls.
- Exact source pins: `src/takahashi_selinv.jl` SHA-256 `2c43535a5def218e73d3fee49cad886ca173cbf3c86a5d58167b446027388fd1`; `src/iterative_solve.jl` SHA-256 `265cfc8d6ba9ca33475b85c56c4701cdd0359b90db9b0cdcae47c6740f4d8a34`.
- Test pins inspected: `test/runtests.jl` SHA-256 `e60e5ba2c968076604369d5b5313e736f82f7d73802cdb18c757a41faf77852a`; `test/wave1_numerical_contracts.jl` SHA-256 `c0e21b925bf59b4d48f2b22afcbf7740a6df081c78494d8ad9787a4d578b8c9a`; `test/test_selinv_trace_contracts.jl` is the directly reviewed narrow fixture.

## Findings

### `src/takahashi_selinv.jl`

Gauss found the Takahashi recursion and permutation mapping internally consistent for successful sparse Cholesky factors. Direct tests exercise selected entries, nonidentity CHOLMOD permutations, and trace support. No accidental densification was found; scratch use follows maximum clique width.

- Open, medium: `_selinv_zvals` divides by stored Cholesky diagonals without an explicit finite-positive/success precondition check (source lines 94-210, especially 130-136). Follow-up is checking whether the current CHOLMOD construction/caller contract already guarantees this; no repair is asserted here.
- Open, low: trace-support errors are checked after the full recursion (lines 323-426), making invalid-input errors pay the recursion cost.
- Validation debt: severe conditioning and invalid/nonfinite factor behavior lack direct tests. This review does not establish factor-failure behavior or optimizer gradient/Hessian behavior.

### `src/iterative_solve.jl`

Karpinski found the inspected small-case correctness guards useful: dense solve agreement, assembled/matrix-free equality, operator and diagonal checks, K=1 reduction, iteration starvation, and invalid-input checks (source spans 12-42, 257-319, 409-496, 746-789; tests `test/runtests.jl:3314-3417` and `test/wave1_numerical_contracts.jl:7-150`).

- Open, medium: sparse Cholesky validation can create substantial fill even when the MME stays unassembled. Any scaling claim needs factor `nnz(L)`, allocations, elapsed time, and peak RSS across pedigree and high-fill custom precisions.
- Open, medium: repeated PCG operator applications allocate block/record vectors; warmed allocation, elapsed-time, and peak-RSS measurements are missing.
- Open, low-to-medium: finite but extreme-scale inputs may overflow curvature or updates without a targeted breakdown diagnostic.
- Validation debt: type stability and performance are unmeasured. This review makes no throughput or scaling claim.

## Verification and limits

Reviewers recorded the hashes above unchanged across inspection. Neither reviewer ran tests or benchmarks. After their source review, Julia 1.10 `Pkg.test()` passed on the same pinned sources and tests; it ended `Testing HSquared tests passed`. This covers the integrated suite on these bytes but does not resolve the open numerical and performance findings. The package emitted its existing Project/Manifest mismatch warning; no resolve or update was run.

These component reviews do not complete E1. Other tracked source files, bridge contracts, caller-side factor guarantees, and whole-wave panel signoff remain open. No GPU execution, simulation campaign, capability promotion, release submission, registry submission, merge, or tag occurred.

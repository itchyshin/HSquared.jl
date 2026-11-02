# 2026-10-31 issues 411 and 409: refitting intervals reuse A; profile keeps one MME workspace

Goal: the refitting dense interval forms stop inverting `Ainv` a second time (#411), and the
profile intervals stop assembling the sparse MME from scratch at every evaluation (#409), with
results unchanged.

Commands (Mac Studio, branch `fix/hjl411-snak` from `origin/main` at `8f58b13a`, Julia 1.12,
`OPENBLAS_NUM_THREADS=1`):

- `julia --project=. test/test_issue_411_409_no_redensify_no_rebuild.jl`: red on main plus
  counters only (dense inverses 2 vs 1, 4 vs 2, 4 vs 2, 2 vs 1; MME assemblies 1611 for
  `variance_component_interval` and 68 for the h2 profile), green on the branch.
- Reference script run on a worktree at `8f58b13a` and on the branch, outputs serialised and
  compared leaf by leaf: 64 numeric outputs (small fixtures) and 58 (q = 400 dense, N = 5000
  profile) are bitwise identical.
- Full `Pkg.test()`: see the PR body for the result.

Claim boundary: a speed change only. Timings are one machine, one run, shared CPU. No
capability-status, row-count or version change; `public_covered_count` stays 7.

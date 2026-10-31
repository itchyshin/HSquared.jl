# 2026-10-31 issue 416: rank pre-check on the sibling fitters

Goal: PR 452 added a fit-free identifiability warning (rank of the stacked `vec(Z K Z')`
plus identity) to the dense `fit_two_effect_reml` and `fit_multi_effect_reml` only. This
slice adds the same warning to `fit_sparse_multi_effect_aireml`, `fit_multi_effect_mc_reml`,
`fit_repeatability_reml` (animal + permanent environment) and `fit_direct_maternal_reml`.
The sparse and matrix-free routes form `Z K Z'` as `Z (Ainv \ Z')` from a sparse Cholesky
and use a tighter cap of 1e7 stacked cells. Warning only: no fit value, `converged` flag,
default, result field or payload field changes.

Commands: `julia +1.12 --project=. test/test_issue_416_sibling_fitters_warning.jl` (red on
main: 4 failed, 4 passed; green on branch: 11 passed); `test_issue_416_weak_identifiability_warning.jl`
still 9 of 9; full `Pkg.test()` on Julia 1.12 (result in the PR body). Issue BTdata repro
(569 records, 1040-animal pedigree): animal + dam warns on both the sparse AI-REML and dense
two-effect routes; animal + fosternest does not warn and gives the same estimates.
Cost at the old dense cap (n = 3600, K = 2): pre-check about 0.95 s against a 0.73 s sparse
fit, hence the tighter sparse cap (about 0.3 s at n = 2000).

Claim boundary: a warning, not a diagnostic field. The check is linear (rank of the design
covariances), so it does not flag weak but nonzero identification, and it is skipped above
the caps. The R lane does not yet surface Julia warnings through `heritability()`. No
capability-status change; no new fitted capability.

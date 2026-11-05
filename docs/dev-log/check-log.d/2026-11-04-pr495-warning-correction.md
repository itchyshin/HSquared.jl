# 2026-11-04 PR 495 warning correction

Julia 1.12.6, `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=2`:

- `julia --startup-file=no --project=. -e 'include("test/test_issue_416_sibling_fitters_warning.jl"); include("test/test_issue_416_weak_identifiability_warning.jl"); include("test/test_issue_424_nelder_mead_convergence.jl")'`: 68 passed.
- The added no-fit warning tests failed against the original wording, confirming
  the misleading specific component, remedy and flat-ridge claims.
- `git diff --check`: passed. Full hosted CI is pending.

Raw-column numerical rank remains scale-sensitive; this is a wording correction,
not a replacement rank method or an inference-calibration claim.

# 2026-11-04 PR 495 scale-normalized numerical rank

Julia 1.12.6, `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=2`:

- `julia --startup-file=no --project=. -e 'include("test/test_issue_416_sibling_fitters_warning.jl"); include("test/test_issue_416_weak_identifiability_warning.jl"); include("test/test_issue_424_nelder_mead_convergence.jl")'`: 82 passed.
- Before the source change, the scale-invariance, nonfinite and extreme-value tests failed or errored as expected.
- Julia 1.10.12 normalization arithmetic smoke check passed without loading the package.
- `git diff --check`: passed. Full hosted CI and independent mathematical review remain pending.

The 1e-8 tolerance is unchanged but now operates on normalized column directions;
this changes warning decisions in existing dense routes. Invariance requires computed columns to remain finite and nonzero. Numerical rank is not a
scientific validation or proof of structural non-identifiability.

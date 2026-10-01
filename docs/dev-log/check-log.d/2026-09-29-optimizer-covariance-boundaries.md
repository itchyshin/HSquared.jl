# 2026-09-29 optimizer covariance boundaries

- Focused `test/test_multivariate_repeatability.jl`: 89 assertions passed.
- Full Julia 1.10 `Pkg.test()`: exit 0; `Testing HSquared tests passed`; `PKG_TEST_DONE`.
- `git diff --check` passed for `src/likelihood.jl`, `src/multivariate.jl`, `src/random_regression.jl`, and `test/test_multivariate_repeatability.jl`.
- Exact source/test SHA-256 values are recorded in `docs/dev-log/after-task/2026-09-29-optimizer-covariance-boundaries.md`.
- Julia emitted the existing project/manifest dependency/compat mismatch warning. No resolve/update was run.
- Gauss, Karpinski, and Noether exact-hash source reviews passed. Rose's refreshed evidence and public-claim audit is clean with limitations; exact hashes and supersession wording were confirmed.
- A2, E1, V3, whole-wave source review, and release gates remain open. No capability row, covered count, GPU run, submission, merge, or tag changed.

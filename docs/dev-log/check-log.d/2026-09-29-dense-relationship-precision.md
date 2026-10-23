# 2026-09-29 dense Gaussian relationship precision guard

- Red regressions reproduced lost method validation in `fit_variance_components` and asymmetric `Ainv` acceptance in `gaussian_loglik`.
- Added finite-value and exact-symmetry checks before Cholesky, restored ML/REML validation, and added precision-domain regressions.
- Focused Wave 1 numerical file passed, including the 126/126 contract set and all adjacent new/relationship/APY tests.
- Julia 1.10 `Pkg.test()` passed (exit 0; `Testing HSquared tests passed`). `git diff --check` passed.
- Gauss and Noether passed exact-hash review: source `19974d322f39c18e9788cccc8bf9daccd2933a21bb48680c2f2f6ec8772889a3`; Wave 1 tests `d3b8fb036f24e9bf350a070a6441ea8f3196bfd6a048078b3d3c8a9fb458f02c`; runner `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691`.
- Scope is this dense Gaussian input guard only. A2, E1, and V3 stay open; no capability, covered-count, release, or GPU status changed.
- Detailed receipt: [`source-review/2026-09-29-dense-relationship-precision.md`](../source-review/2026-09-29-dense-relationship-precision.md).

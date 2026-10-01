# Sparse Gaussian REML exact-current component review, 2026-09-30

## Scope and pins

Read-only numerical review by the Gauss numerical engineer role (GPT-6 Sol, high reasoning) of `src/likelihood.jl` and directly relevant tests. Hashes matched before and after review:

| File | SHA-256 |
| --- | --- |
| `src/likelihood.jl` | `19974d322f39c18e9788cccc8bf9daccd2933a21bb48680c2f2f6ec8772889a3` |
| `test/wave1_numerical_contracts.jl` | `2a983d2e5526e945ec6eb090895e7db8c5830cf0b06a7fb9758ecb890d695ed6` |
| `test/test_matfree_reml_inci_pins.jl` | `decca8dccfdb244e8260f5bfacf1da5c05a10602a70b718ba4761ea514608282` |
| `test/test_sparse_reml_finite_variances.jl` | `8a513c4f87d640ab89fe5364654a8a80ec82714864a4b3c06f20c343d1958bc2` |
| `test/runtests.jl` | `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691` |

Reviewed `src/likelihood.jl:174-269,341-412`; `fit_sparse_reml` required the agreed narrow span extension through its closing `end` at line 412. Direct tests inspected: `test/wave1_numerical_contracts.jl:296-323`, `test/test_matfree_reml_inci_pins.jl:71-86`, `test/test_sparse_reml_finite_variances.jl:6-31`, and registered assertions in `test/runtests.jl:2370-2410,2437-2457,2469-2475,2784-2807,2951-2981,3879-3945`.

## Review result

For `R=σe²I`, `G=σa²A`, SPD `Ainv`, and full-column-rank `X`, the code's sparse MME determinant identity yields the Gaussian REML objective with the full `(n-p)log(2π)` constant. It includes `n log(σe²)`, `q log(σa²)-log|Ainv|`, `log|C|`, and the residual-plus-prior quadratic. The reviewed tiny hand-value and dense parity checks, fitted eight-animal optimum/multistart, bounded boundary comparison, cached/direct equality, and large-intercept check support those specific cells.

## Findings, ranked

1. **Moderate, numerical failure handling:** `fit_sparse_reml` maps invalid transformed trials and `PosDefException` to `Inf`, but other numerical exceptions or non-finite objective values can escape. The final likelihood is recomputed without checking finiteness or validity. Add targeted underflow/overflow, near-singular fixed-effect, and very small/large finite-variance cases; require a finite final likelihood and explicit status.
2. **Moderate, convergence and boundary:** the returned flag is only `Optim.converged`. There is no score, Hessian, or boundary diagnostic. The log-variance parameterization cannot attain zero genetic variance, and the existing boundary check uses absolute tolerance `1e-5` without asserting convergence or stationarity. Compare to a profile or analytic boundary reference and define explicit boundary/convergence criteria before strengthening fit claims.
3. **Low to moderate, input error:** `p<n` is checked but `rank(X)` is not. A rank-deficient design reaches Cholesky failure without a specific input error. Add a rank-deficient two-column case and a `p=0` case.
4. **Low, scale:** dense `Ainv` is copied through `Float64.(spec.Ainv)` before conversion to sparse; sparse Cholesky fill can also be large. The path is documented as validation-only. Measure allocation/fill before making scale claims.

The cached helper accepts `Ainv` and `logdet` separately while building `C` from the specification, so callers must supply a consistent cache; the inspected direct test uses matching inputs only.

## Verdict and limits

Component verdict: **conditional pass** for the REML algebra and represented tiny/interior checks. No tests, fits, simulations, or GPU work were run by the reviewer. Nine other refs carry `src/likelihood.jl` work absent from this checkout; no source edit or reconciliation was attempted. This does not close the whole file, Wave 1, E1, A2, or V3, and does not establish production scale, AI-REML behavior, general boundary recovery, or whole-engine signoff.

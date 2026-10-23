# Optimizer covariance-boundary source review

## Scope

Exact candidate review of residual and genetic covariance admissibility in multivariate REML, plus finite-positive log-variance proposal and post-fit checks in multivariate repeatability, direct-maternal, random-regression, scalar repeatability, two-effect, and K-effect dense REML.

## Exact candidate

- `src/likelihood.jl`: `cd36e0c21802c9f4c71e9a0980ece50e926b7bb3337a3efc9442ef88365b8f11`
- `src/multivariate.jl`: `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670`
- `src/random_regression.jl`: `761151eb0297bece4c859db8a504a244a26510d320f123f85a9a9295621e7a5c`
- `test/test_multivariate_repeatability.jl`: `276017e88ebf8b266d3b613166cf43ed81f7ae31144c73e79c35a7a8e13a6d87`

## Findings and fixes

- `fit_multivariate_reml` maps invalid residual covariance and inadmissible genetic covariance to `Inf`, then repeats the covariance rule when validating attempts before selection.
- Unstructured, diagonal, and FA G are required to be positive definite. Low-rank G may be singular but must have positive marginal variance for each trait, matching genetic-correlation result construction.
- Related scalar covariance/log-variance optimizers reject nonfinite objective values and invalid decoded parameters before final solves; finite-positive initial values and ratio totals are checked where applicable.
- Shared raw transforms remain unchanged, avoiding exception leaks to unreviewed direct callers.

## Panel

- Gauss: pass on optimizer and post-fit numerical boundaries; exact hashes above.
- Karpinski: pass on guard placement and negligible fixed-small-vector transform overhead; noted O(t^3) positive-definiteness checks on non-low-rank G/R.
- Noether: pass on positive marginal variance, positive-definite structures, low-rank PSD allowance, and objective-level underflow regression.
- Rose: clean with limitations after receipt refresh. Verified all four exact hashes, focused and full test evidence, and explicit supersession of the residual-only historical snapshot. No public claim or capability promotion was found; A2 and broader gates remain open.

## Validation limits

The focused tests prove helper underflow/overflow behavior, actual residual and unstructured genetic objective rejection, initial-value rejection, and normal repeatability recovery. They do not force every fitter's optimizer into each possible failed post-fit state. This is a numerical repair only; no recovery, inference, bridge, or capability promotion follows.

# Independent FA multistart oracle review

## Scope

Reviewed the one-line change in `test/test_multivariate_fa_multistart.jl` against the Julia 1.13 Linux and Windows failure logs and the diagnostic implementation.

## Finding

The diagnostic range is computed from the valid optimizer attempts, which are the production `:default` and internally constructed `:balanced` starts. The test's `reported_alternative` reproduces the balanced initializer arithmetic exactly. The old expected value used a separate but algebraically equivalent loading expression, so floating-point rounding changed the fitted log likelihood by about `2.84e-14`.

Both hosted failures had the same single assertion failure, with the other 45 assertions in that testset passing. Comparing with `reported_alternative.loglik` now checks the two starts that produced the diagnostic. The test oracle correction is appropriate; no numerical source change is indicated.

## Limits

This review covers the one-line test correction only. A fresh full local package suite passed; exact-current hosted checks and landing remain pending.

## Rose public-claim audit

Rose's exact-current audit is clean with limitations. The bounded public wording remains unchanged: the covered count stays seven, fixed-rank FA and the Poisson GLLVM cell remain experimental, `cov=fa()` remains planned, and automatic rank, broad calibration, raw-loading inference, missing-data routes, and release claims remain outside the demonstrated scope. No correction is required before push. Hosted exact-head CI and merge remain pending.

# Post-fit mixed marker scan review, 2026-09-30

## Scope and pins

Read-only Henderson review of the fitted animal-model convenience wrapper, its supplied-variance GLS implementation, and direct tests. Pins observed:

| File | SHA-256 | Pin note |
| --- | --- | --- |
| `src/postfit.jl` | `d065d525ccdca8c8d881432f3c312141929571d52629f38bf72cfc513bdbf71f` | matched before and after |
| `src/genomic.jl` | `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f` | current source observed |
| `src/model_spec.jl` | `d49de74e3990e18e73db37bab9b3019f46dcaa29c4f7102fc3f53fe60fa9f5fb` | coordinator pin after review |
| `test/runtests.jl` | `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691` | actual current pin; requested review pin was stale and did not match |

The method wrapper is at `src/postfit.jl:30-37`; the scan core is at `src/genomic.jl:898-995`; the fixed-effect post-fit route is at `src/postfit.jl:43-58`. Direct tests examined include `test/runtests.jl:4886-5025`, `:5436-5520`, and `:5522-5670`. No tests, fits, or simulations were run by the reviewer.

## Findings

- For successful interior fits, the mixed wrapper passes the fitted response, fixed/random design, relationship precision, and estimated variance components to the supplied-variance scan. The core forms dense `V = sigma_a2 * Z * A * Z' + sigma_e2 * I`, profiles fixed effects, and computes GLS marker effects and known-covariance Wald errors. The route is explicitly validation-scale because it densifies/inverts `Ainv`.
- P2 boundary finding: the core requires `sigma_a2 > 0`, although `V` remains valid at `sigma_a2 == 0` when residual variance is positive. Existing invalid-input tests cover negative additive variance and zero residual variance. They do not check this boundary or reduction to the fixed scan.
- P2 fit-provenance finding: the convenience wrapper ignores `fit.converged` and optimizer status. It can return scan results from a failed or unresolved fit without signaling that status. The cited wrapper fixtures use converged fits only.
- P2 row-order finding: marker rows are aligned positionally. The core checks row count but receives no observation IDs. `AnimalModelSpec.ids` identify relationship animals, not necessarily observation rows. A parity fixture checks row order before matrix conversion; the public method cannot detect a permuted marker matrix.
- The fixed-effect convenience route intentionally ignores `Z` and `Ainv`; docs and tests identify it as an uncorrected screen.

## Verdict and limits

Conditional algebraic pass for the documented dense scan with an interior, converged fit. Boundary-zero behavior, failed-fit provenance, and visible row-order requirements need resolution before the convenience route can be used safely across fitted cases. Existing tiny direct tests and a frozen same-implementation fixture do not establish external same-estimand parity, optimizer-produced wrapper integration, genome-wide calibration, or general inferential validity. This review does not change capability status or close E1.

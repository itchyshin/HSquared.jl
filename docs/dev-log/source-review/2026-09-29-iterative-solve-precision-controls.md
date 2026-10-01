# Exact-current iterative-solver precision and control review

## Scope and disposition

The Gauss review examined the current numerical contracts in `src/iterative_solve.jl`, including assembled and matrix-free animal PCG, multi-effect PCG, MC-REML fitting, block traces, matrix-free REML likelihood, and REML information. The final review was read-only and clean for this bounded component.

Pinned final hashes:

- `src/iterative_solve.jl`: `56703c9e0989143ee0500c395875e888799119dc1ed1adbc4ca24d26cec09d8d`
- `test/wave1_numerical_contracts.jl`: `083deac6582cca5f583c6cdf8a46bd40df57f98337b16112d9159d8fa4705c56`

## Findings repaired

1. Assembled `solve_animal_model_pcg` now validates and canonicalizes `Ainv` just like the matrix-free route. Zero-response tests reject asymmetric, indefinite, and non-finite precisions; all assembled preconditioners are covered. An indefinite prior whose assembled MME would have positive curvature is also rejected, so the test checks the model contract directly.
2. Public PCG, trace, likelihood, information, and MC-REML controls reject non-finite tolerances and variance inputs after conversion to `Float64`. Variance guards also require a finite reciprocal, excluding subnormal inputs that would create an infinite precision. MC-REML rejects non-finite initial variance components and does not accept non-finite update proposals.
3. `matrix_free_reml_information` and `matrix_free_reml_loglik` reject `p >= n`, X/Y row mismatches, and malformed Z/Ainv dimensions before matrix products.
4. The MC-EM documentation says fixed probes make the map deterministic and explicitly does not promise convergence.

## Verification

- TDD first reproduced the assembled precision bypass and infinite-tolerance acceptance: focused wave-1 tests failed 10 assertions while 88 passed.
- The final focused `test/wave1_numerical_contracts.jl` run passed **126/126**.
- Full Julia `Pkg.test()` on the final code exited 0 and ended `Testing HSquared tests passed`. Its log is retained at `/private/tmp/hsq-pkg-test-final.log`.
- Julia docs built in a writable content-matched copy with the non-deploying local driver. VitePress rendering completed. Existing missing-docstring and default-config warnings remain; deployment was not run.
- `git diff --check` and `bash tools/preamble_cap.sh` passed.

The independent Rose audit of `src/validation_status.jl` and the regenerated `docs/src/validation-status.md` is clean with limitations. It confirms the FA row now limits the S4 evidence to interior-uniqueness point estimates, calls Ledermann slack a generic dimension check rather than pointwise identification evidence, and states that fit-level uniqueness information is not assessed. `public_covered_count` remains 7; GLLVM stays partial and unusual inheritance planned.

## Boundary

This review closes the listed numerical input-contract findings only. It does not close A2, E1, or V3: the broader exact-current source and bridge review still has uncovered spans and pending whole-wave signoff. No capability status, covered count, version, GPU status, or release state changed.

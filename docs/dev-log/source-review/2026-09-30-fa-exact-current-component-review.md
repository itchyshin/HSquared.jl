# FA exact-current component review, 2026-09-30

## Scope and exact pins

Read-only review by Kirkpatrick specialist (Astra, high reasoning) of the bounded Gaussian T=4, K=1 FA engine and registered tests. All hashes matched before and after review:

| File | SHA-256 |
| --- | --- |
| `src/multivariate.jl` | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` |
| `test/test_multivariate_fa_multistart.jl` | `e621d60892c9ec9ceab6a1b06d051495d2aa1b9d6c70346023129a993b2d9085` |
| `test/test_fa_uniqueness_interior.jl` | `56022f372d787cbbe0e21a28d650f28f67b51d4593ebe5f0fbc00d79804c3d72` |
| `test/test_fa_likelihood_information.jl` | `e7e1987cc042db23b813b5c4fc23b5d4b925e3f618636a18ba282ecea77bef71` |

The current integrated candidate then passed full Julia 1.10 `Pkg.test()` with exit 0. The runner is pinned separately in `docs/dev-log/check-log.d/2026-09-30-va-schur-recheck.md`.

## Review findings

- The implementation uses `G = ΛΛ' + diag(ψ)`. Here `ψ` is a specific genetic variance separate from unstructured residual covariance. The docs state the absolute `1e-4` floor and its dependence on trait units (`src/multivariate.jl:374–382, 900–933`).
- The registered production-map Jacobian test gives rank 8 at a generic T4/K1 point and rank 7 at a sparse-loading point (`test/test_fa_uniqueness_interior.jl:33–61`). Likelihood identifiability needs a separate assessment.
- The tests check default-plus-balanced start selection, convergence, and floor diagnostics (`test/test_multivariate_fa_multistart.jl:106–178`). The current ordinary-start result includes a near-floor estimate and substantial between-start disagreement. These tests verify the selection-status contract. They do not estimate optimizer reliability or population recovery.
- The expected-information test uses record-major ordering, trait intercepts, REML projection, and `0.5 tr(P V_a P V_b)` across eight genetic and ten residual coordinates (`test/test_fa_likelihood_information.jl:5–48`). Repeated-pedigree and unrelated one-record cases exercise expected ranks 18 and 10 (`:51–84`). Trait scaling is checked under the stated transformations. The result is plug-in expected information; observed-curvature and interval calibration remain untested.
- The four pins contain no correctness defect that blocks the bounded T4/K1 cell. A2 remains on hold.

## Carried limits and findings

A2 still requires ordinary-start recovery over the predeclared replicates, weak-direction/uncertainty diagnostics, broader ordinary-start unit and trait-order checks, remaining engine and R-route spans, and whole-wave panel signoff. The one-seed replay supplies a diagnostic; it cannot estimate a recovery rate. Repeated eigenvalues, the absolute floor, and the difference between natural-coordinate rank and regularity for inference remain material limits. The reviewer did not run tests, fits, or simulations.

One stale source docstring at `src/multivariate.jl:939–940` calls the package test suite RNG-free while registered tests use seeded RNG fixtures. `lane_preflight.sh --file src/multivariate.jl` found six refs with work on that file. No source edit was made before reconciling their diffs and ownership. This wording issue does not change the fitted model, but remains an A2 cleanup item.

## Verdict

Component verdict: PASS for the mathematical and engine checks represented by these four pins. A2 and the complete Julia source wave remain on hold. This component review and the full package test pass provide no whole-wave signoff, broader recovery result, or whole-source coverage.

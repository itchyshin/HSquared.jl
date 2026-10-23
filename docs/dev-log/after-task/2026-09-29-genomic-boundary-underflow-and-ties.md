# After-task: genomic boundary underflow and endpoint ties

## 1. Goal

Close the bounded genomic-boundary source-review findings without broadening the experimental capability or changing any public status.

## 2. Implemented

The boundary resolver now validates internally derived Float64 variance components before gradient or likelihood evaluation. Values that become zero, nonfinite, or have nonfinite reciprocals return `boundary_unresolved`. Endpoint-adjacent refined candidates that strictly improve on their corresponding exact endpoint also return `boundary_unresolved`, including improvements smaller than the likelihood tie tolerance.

## 3a. Decisions and Rejected Alternatives

- Preserve the exact boundary result and refuse to report a boundary when an endpoint-adjacent candidate improves on it.
- Do not catch all `ArgumentError` values in the numerical guard. User-control errors must still propagate.
- Convert candidate variances to Float64 before checking representability, so the helper's contract matches the likelihood input contract.

## 4. Files Touched

- `src/likelihood.jl`
- `test/wave4_genomic_boundary_near_endpoint.jl`
- `docs/design/59-v07-genomic-boundary-score-amendment.md`
- `docs/dev-log/source-review/2026-09-29-wave4-boundary-underflow-and-ties.md`
- `docs/dev-log/check-log.d/2026-09-29-wave4-boundary-underflow-and-ties.md`
- `docs/dev-log/after-task/2026-09-29-genomic-boundary-underflow-and-ties.md`

## 5. Checks Run

- Targeted red check: the new sub-tie tests initially errored because the predicate had not yet been implemented.
- Focused registered boundary test: **28/28 passed**.
- Full Julia 1.10 `Pkg.test()`: exited 0 and ended with `Testing HSquared tests passed` on the exact source and test hashes below.
- `git diff --check`: passed for the three implementation, test, and design files.
- The after-task structure check passed. The integrated acceptance check exits 1 because the root gate and the GLLVM foundation, W105, and Wave 2 bridge gate files still contain unmet programme gates; this slice does not close them.
- The full suite emitted the existing Project/Manifest mismatch warning. No resolve or update was run.
- Final hashes: `src/likelihood.jl` `041e3c7c71a1c48e138d06c3bff0450d31f952108761ac08ce942f4c665ed383`; focused test `702a2a34e9d893907ce5a8a5f02e8417e0c73f41eab008fcfc129e09e15c89cf`; design amendment `4c07b8202596b8143e14337894ecc89adc4c01e23ab3d27a8e7643c4b155c235`.

### Review lenses

Gauss passed the bounded classification review against all three final hashes and the exact-current full-suite result. Noether passed the numerical representation contract against the final source and test hashes. Astra identified the original underflow issue on the previous source snapshot; an exact-current post-fix Astra verdict was unavailable. No public claim changed, so this repair did not request a Rose claim audit.

## 6. Tests of the Tests

The focused test covers lower and upper endpoint-adjacent gains smaller than the tie tolerance, exact endpoint ties, a non-adjacent candidate, zero variance, reciprocal overflow, and a tiny-response resolver route. The test is registered in the package suite and passed within both the focused and full-suite runs.

## 7a. Issue Ledger

- Fixed: subnormal profile scale could produce unusable derived variance components before likelihood validation; an endpoint-adjacent strict improvement could be accepted as a boundary within the likelihood tie tolerance.
- Open: full Wave 4 and E1 signoff, other Julia source spans, FA acceptance, GLLVM acceptance, and cross-twin acceptance.

## 8. Consistency Audit

The profile ratio still maps to the same variance decomposition. The new guards only reject representations that cannot be used safely by the downstream Float64 likelihood. The endpoint rule follows the design amendment and does not promote endpoint-adjacent fits to strict interior fits. Capability status, covered count, release state, and GPU status are unchanged.

## 9. What Did Not Go Smoothly

The default Julia depot could not write compiled-cache and manifest-usage lock files in this workspace. The focused test ran with `--compiled-modules=no`; the full suite used `JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia`, four Julia threads, and one BLAS thread. Lane preflight found foreign-ref differences on aggregate `check-log.md` and `coordination-board.md`; those files were not edited. The unique report and check-log shard preserve this slice's evidence.

## 10. Known Residuals

This closes only two defects in the genomic-boundary resolver span. It does not sign off the whole `src/likelihood.jl` file, all Wave 4, or E1. No docs build or hosted CI was run. No simulation, GPU execution, public capability flip, release submission, registry submission, merge, or tag occurred.

## 11. Team Learning

When derived estimates cross an API boundary, validate their representability after conversion to the API's storage type. For endpoint rules that use a likelihood tie tolerance, separately test strict improvements smaller than that tolerance.

## 12. Cross-Product Coverage

This covers only the Julia experimental genomic-boundary resolver and its focused regression. It does NOT cover the R bridge, factor-analytic release acceptance, genetic GLLVM usability, remaining Julia review spans, unusual inheritance, GPU computation, or release readiness.

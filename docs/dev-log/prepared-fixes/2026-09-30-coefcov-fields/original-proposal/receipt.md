# Frozen coefcov parser review and scratch fix, 2026-09-30

## 1. Finding

The remaining P2 finding is confirmed on the intended Julia candidate: exported `parse_payload_v2` accepts malformed or missing coefficient-covariance fields and discards all six fields when constructing its resolved block. The scratch validator closes those checks and preserves their metadata. It is prepared for integration and has not been applied to the live candidate.

## 2. Scope

The review covers the remaining `coefcov` finding from `docs/dev-log/source-review/2026-09-30-payload-v2-direct-maternal-and-coefcov-review.md`. Maternal results were not retested. All writes are under `/private/tmp/e1-coefcov-fix-20260930`. No live R or Julia source, campaign driver, numerical estimator, GPU work, commit, push, or capability status was changed.

## 3. Exact candidate pins

Julia root: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, initial HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`, with existing dirty work. Final HEAD is `27fcf3ef50c0329ceb3e7e42bee9eeec821b294d`. The parent confirmed that it authorized and created this commit, scoped to two FA validator tools and three validator receipts. `git show --stat` agrees with that scope. A fresh independent source-tree/parser/schema/runtests hash check after the HEAD advance matched every pin below. This is explained parent coordination, with the reviewed bytes unchanged. R root: `/private/tmp/hsquared-fa-gllvm-20260927`, HEAD `fa98c262eb21694d672e671c9672491ce3369cec`, with existing dirty work.

| Live file | SHA-256 |
| --- | --- |
| `src/bridge_payload_v2.jl` | `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0` |
| `docs/design/21-payload-v2-multiblock-schema.md` | `02fe6d274d83b2c62ae972f11d32186c507e083ef19fcb1dd6702b514adb3e80` |
| `test/test_payload_v2_parity.jl` | `8f281fb60bbc9bf0ccf46559f5152ef32b68148eff1c0457fa01c9abb0dccc73` |
| `src/random_regression.jl` | `761151eb0297bece4c859db8a504a244a26510d320f123f85a9a9295621e7a5c` |
| `test/runtests.jl` | `b2d77c7f0937f5fcf0ed8ec32913c816b2c942f27c83825c8424107a5bc58b24` |

The source-tree hash rooted at `src/` remains `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` after the checks. The live producer/parser file and schema hashes also remained unchanged.

## 4. Exact spans

`src/bridge_payload_v2.jl:148-211` validates common fields and correlated fields, but contains no coefficient-field reads. `_resolve_dispatch` at lines 266-269 returns `:coefcov`. `fit_payload_v2` at lines 673-677 always raises the frozen-slot `Phase0NotImplementedError` for this dispatch. The schema defines the six coefficient fields at `docs/design/21-payload-v2-multiblock-schema.md:108-113` and the frozen fit boundary at line 288. The existing `test/runtests.jl:11039-11068` fixture supplies none of those six fields yet expects parsing to succeed.

## 5. Malformed requests accepted

The unmodified parser accepted all 32 tested malformed cases:

- Missing `basis`, `order`, `Phi`, `covariate`, or `cov_structure`.
- Unsupported or nonstring basis; Boolean, zero, negative, floating, or string order.
- Wrong matrix rows/columns; vector `Phi`; NaN, infinity, strings, complex values, sparse input, or finite BigFloat values that overflow Float64.
- Blank or nonstring covariate.
- Missing Legendre bounds; equal, reversed, infinite, wrong-length, Boolean, or string bounds.
- Unsupported or nonstring covariance structure.

For a valid request, the original resolved block lacked each of the six specific fields. These are observed parser defects, rather than evidence that malformed coefficient models can be fitted.

## 6. Public impact

An expert using exported `parse_payload_v2` receives a successful resolved object without the declared coefficient design or metadata. That is misleading validation and would be unsafe input for future fitting/result wiring. Current `fit_payload_v2` still rejects this slot, so no malformed fit or incorrect fitted estimate was demonstrated.

The current R random-regression bridge uses `HSquared.fit_random_regression_reml` directly (`R/julia-bridge.R:4147-4213`). The R payload emitter still creates a pedigree block and carries random-regression metadata separately (`R/bridge-payload.R:74-103`). Thus this fix does not change the existing R fitting route or enable raw-slope formula syntax. The schema's emitter mapping for RR at line 156 is broader than the current emitter; that wording remains separate from this parser patch.

## 7. Proposed narrow fix

The patch adds `_parse_coefcov_fields` and calls it only for `type="coefcov"`. It requires an allowed string basis, positive integer column count, finite dense real `Phi` of size `n x order`, nonempty covariate name, and allowed string covariance structure. It preserves all six fields in the parsed block. It rejects Float64 overflow after conversion and sparse Phi before conversion, avoiding accidental densification.

Legendre bounds are required; raw bounds may be absent, and supplied bounds must be finite with lower < upper. The original field table specifies the bounds shape but does not explicitly state this conditional requirement. The proposed requirement supports Legendre re-standardization; the accompanying schema prose states it explicitly. No consistency check between numerical Phi values and an original covariate is claimed because the request carries no original covariate values.

The patch updates the existing frozen-slot fixture to provide valid raw coefficient fields and adds focused regressions. It leaves the frozen fitting error intact.

## 8. Tests and results

Pre-run estimate: under 30 seconds per local parser-only run, one Julia and one BLAS thread. Both runs completed within that estimate. The tests load copied parser definitions into an isolated module; the live HSquared module is unchanged. Calling the frozen dispatch only raises its existing error and invokes no numerical estimator.

Original parser: **8 passed, 38 expected failures** in 1.8 seconds of test time. That comprises 32 malformed-input failures and six missing-metadata failures. Patched parser: **53 passed, zero failures** in the final 1.9-second run. It also tests both allowed bases and covariance structures, string-key Dict, symbol-key Dict, NamedTuple forms, metadata preservation, the frozen fit error, and ordinary single-animal/two-effect parsing.

Logs: `baseline-test.log`, `patched-test.log`. The isolated differential test is `test/test_coefcov_parser.jl`; the repo-shaped test is `test/test_coefcov_fields.jl`. The latter uses the same checks with the parser reference changed to HSquared. The full package suite was not run.

## 9. Patch and reproduction

Patch: `coefcov-field-validation.patch`, SHA-256 `d8d80fe075e4e70f713e905a1da7f1cb16f96ac2ad85e242fcd86b5ef54b791b`. It changes only the parser, schema prose, existing fixture, and new test file. `git apply --check` passed against the exact live working tree; the patch was not applied.

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia \
JULIA_PKG_PRECOMPILE_AUTO=0 \
julia --project=/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl \
  /private/tmp/e1-coefcov-fix-20260930/test/test_coefcov_parser.jl
```

Add `COEFCOV_PARSER_MODE=baseline` to reproduce the expected failures against the original copy.

## 10. Remaining limits

The patch is scratch-tested and awaits owner integration after the source freeze permits it. It does not implement a coefficient-covariance estimator, result normalization, broader grammar, mixed coefficient/independent dispatch, or covariance calibration. The proposed bounds requirement and required-field wording are explicit contract clarifications. They should be retained with the implementation, rather than inferred from the successful tests.

## 11. Coordination and final state

Graft was queried first and reported approximately 135,359 tokens saved. Its cache refresh was blocked by read-only permissions, so the exact returned source spans were checked directly. The prior candidate preflights and live campaign ownership were respected. Existing dirty work was preserved; the live Julia source still matches its frozen hash. Deliverable status: proposed patch with failing-original/passing-patched parser evidence, not integrated or capability-promoted.

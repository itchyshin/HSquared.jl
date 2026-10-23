## 1. Goal

Prevent the selected-inverse kernel from silently producing nonfinite output when given an incomplete or invalid CHOLMOD factor.

## 2. Implemented

Added a shared entry-point guard for finite stored factor values and finite positive diagonal pivots. Added a direct regression using a singular sparse matrix factored with `check=false`.

## 3a. Decisions and Rejected Alternatives

- Check the factor at `_selinv_zvals` so all selected-inverse and trace paths share the same validation.
- Keep the error a targeted `ArgumentError`; normal internal callers already use checked Cholesky, while the kernel may receive a factor from other internal/test routes.
- Leave severe-conditioning diagnostics and early support-error checking as separate findings.

## 4. Files Touched

- `src/takahashi_selinv.jl`
- `test/test_selinv_trace_contracts.jl`
- `docs/dev-log/source-review/2026-09-29-selinv-factor-guard.md`
- `docs/dev-log/check-log.d/2026-09-29-selinv-factor-guard.md`
- `docs/dev-log/after-task/2026-09-29-selinv-factor-guard.md`
- `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`
- `GATES.md`

## 5. Checks Run

- The new test failed before the guard because no exception was thrown for a singular partial factor.
- Focused selected-inverse contract tests passed 30/30.
- Full Julia 1.10 `Pkg.test()` passed on the final source/test bytes.
- `git diff --check` passed.
- The suite warned that project dependencies or compat requirements differ from the manifest. No dependency resolve/update was run.

## 6. Tests of the Tests

The regression asserts CHOLMOD returned a factor with a nonfinite or nonpositive diagonal, then requires `takahashi_diag` to reject it. This directly reproduces the failure mode, rather than mocking the factor.

## 7a. Issue Ledger

- Fixed: selected inverse accepted a partial singular factor and returned `Inf` values.
- Open: severe-conditioning behavior, support validation after recursion, caller-side precision-factor assumptions beyond the tested failure, remaining E1 source spans, A2, and V3.
- Pending: independent Gauss review of the exact post-fix source/test hashes.

## 8. Consistency Audit

The guard runs before recursion and applies to all callers of `_selinv_zvals`. Full package tests passed with checked factors. No capability or validation-debt row changed.

## 9. What Did Not Go Smoothly

No additional test failure remained after updating the guard. The package test run retained the existing Project/Manifest warning.

## 10. Known Residuals

This does NOT cover severe ill-conditioning, factor/precision consistency for every caller, large-scale performance, whole-file E1 signoff, CUDA execution, release readiness, or the FA/GLLVM R bridge. E1, A2, and V3 remain open. No simulation, release submission, registry submission, merge, or tag occurred.

## 11. Team Learning

The CHOLMOD factor type alone does not prove factorization success when callers use `check=false`; downstream numerical kernels should validate the structural and numeric invariants they require.

## 12. Cross-Product Coverage

This covers Julia selected-inverse behavior for an incomplete CHOLMOD factor. It does NOT cover R code, other Julia factor types, unusual inheritance, GPU execution, or public release claims.

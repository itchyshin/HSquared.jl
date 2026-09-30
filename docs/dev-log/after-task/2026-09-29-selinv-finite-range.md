## 1. Goal

Reject non-finite Takahashi selected-inverse outputs from valid but extremely small positive-definite factors.

## 2. Implemented

Added finite-result checks to both `_selinv_zvals` exits: the `per_pair` reference path and the optimized recursion. Added a 1×1 tiny-SPD regression covering both routes. Logged exact hashes and independent review in `docs/dev-log/source-review/2026-09-29-selinv-finite-range.md`.

## 3a. Decisions and Rejected Alternatives

- Reject non-finite selected-inverse results with `ArgumentError` rather than return `Inf` to callers.
- Check after computation on both paths, preserving the existing recursion and summation order.
- Keep the scope at finite output detection; do not claim accuracy for ill-conditioned factors.

## 4. Files Touched

- `src/takahashi_selinv.jl`
- `test/test_selinv_trace_contracts.jl`
- `GATES.md`
- `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`
- `docs/dev-log/source-review/2026-09-29-selinv-finite-range.md`
- `docs/dev-log/check-log.d/2026-09-29-selinv-finite-range.md`
- `docs/dev-log/after-task/2026-09-29-selinv-finite-range.md`

## 5. Checks Run

- Red test reproduced missing exceptions on the tiny-SPD factor in both routes.
- Focused Julia tests passed 33/33.
- Julia 1.10 `Pkg.test()` passed and ended `Testing HSquared tests passed`.
- `git diff --check` passed for the source and test files.
- Gauss exact-current review passed on the recorded source and test hashes.
- The suite warned that Project metadata differs from the Manifest. No resolve or update was run.

## 6. Tests of the Tests

The regression first failed because neither route rejected the overflow. It now verifies that the factor diagonal is finite and positive and that both public diagonal extraction and the reference path reject the non-finite inverse. The full suite also exercised selected-inverse use in AI-REML, PEV, and trace tests.

## 7a. Issue Ledger

- Fixed: finite factor pivots could still produce non-finite selected-inverse values outside Float64 range.
- Open: severe-conditioning accuracy, trace-accumulation overflow for finite selected entries, and support-error timing.
- Programme gates E1, A2, and V3 remain open.

## 8. Consistency Audit

Both return paths are guarded. The focused regression is registered through the already included `test/test_selinv_trace_contracts.jl`; no test registration edit was needed. Capability status and validation debt are unchanged. The exact-current coverage table now records the source hash and the new component receipt.

## 9. What Did Not Go Smoothly

The first direct test command omitted the test imports; the focused command was corrected. The closeout generator assumes the second-brain root, so it could not create a report under this repository worktree; the report was written from the repository template and checked directly instead.

## 10. Known Residuals

This does NOT establish accuracy for ill-conditioned factors, finite trace-accumulation safety, performance, full selected-inverse file review, whole E1, FA review A2, or final twin gate V3. It does NOT change model capability claims, release status, GPU status, or covered count.

## 11. Team Learning

A successful positive-definite factorization does not guarantee that every inverse entry is representable in the output type. Check computed outputs at each alternate return path and retain a tiny-scale regression.

Memory receipt: routed through the project instructions and the systematic-debugging and test-driven-development workflows; those shaped the reproduction, two-path guard, and red-green verification. Golden Set: not in scope for this numerical edge-case fix.

## 12. Cross-Product Coverage

Covers Julia selected-inverse finite-result checks and local package use of those routines. It does NOT cover R-Julia parity, alternative numerical types, ill-conditioned accuracy, broad performance, FA/GLLVM statistical validation, GPU execution, public release, or registration.

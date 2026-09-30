# After-task report: variational fixed-effect Schur correction recheck

## 1. Goal

Revalidate the shared-effect variational approximation repair on the exact current Julia candidate and record full-suite evidence.

## 2. Implemented

No source changes were made in this recheck. The current implementation uses the mean Hessian in the fixed-effect Schur complement and documents that the non-Gaussian correction holds variational covariance fixed while profiling fixed effects.

## 3a. Decisions and Rejected Alternatives

Retain the profiled fixed-effect correction as an explicitly qualified approximation. Do not call it an evidence lower bound when the covariance response to fixed effects is omitted.

## 4. Files Touched

- `docs/dev-log/check-log.d/2026-09-30-va-schur-recheck.md`
- `docs/dev-log/after-task/2026-09-30-va-schur-recheck.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `GATES.md`

## 5. Checks Run

- Julia 1.10 `Pkg.test()` on candidate HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`: exit 0; final output `Testing HSquared tests passed`.
- Exact pins: `src/nongaussian.jl` `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00`; `test/wave2_nongaussian_contracts.jl` `c7a6cd8eba56cf54f4b0ffed629ba1b5a5dfbd5220f2d5d7d09e3ec1cebaad60`; `test/runtests.jl` `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691`.
- Focused suites previously passed 92/92 and 13/13 for the related contracts and inner convergence.
- `bash tools/preamble_cap.sh`: PASS, 11024 bytes under 14000-byte cap.
- `git diff --check`: PASS.
- No rendered docs build was run because no rendered documentation or manual files changed in this recheck.

## 6. Tests of the Tests

The regression first reproduced `PosDefException` on the shared-effect Gaussian design before the repair. Its exact current form passes inside the focused and full test suites. Astra/Noether confirm the design exercises the old negative Schur curvature and the positive mean-Hessian correction. Convergence and finiteness are asserted; the exact 1/4 curvature value remains untested.

## 7a. Issue Ledger

- Closed here: the shared-effect VA Schur calculation using the wrong covariance matrix.
- Carried: the fixed-covariance profiling approximation, other non-Gaussian audit findings, and whole-source review.

## 8. Consistency Audit

No public capability, covered-count, or inference claim changed. A2, E1, and V3 remain open. This test pass does not close the Julia source-review wave or establish broader non-Gaussian calibration.

## 9. What Did Not Go Smoothly

The Julia candidate remains on branch `codex/hsquared-fa-gllvm-20260927` with extensive pre-existing dirty changes preserved. The R candidate was not modified. Astra/Noether completed a read-only exact-hash review; no other agents edited files.

An initial hygiene command incorrectly invoked the shell-only `preamble_cap.sh` through Python and failed. The correct Bash invocation passed. A first skill-file read also split a path at spaces; quoting the path resolved it. Neither failure changed repository files.

## 10. Known Residuals

This report covers one numerical repair and a full Julia test rerun. It does not close FA engine review (A2), complete Julia source and bridge review (E1), or final R parity and audit (V3). Continue with the highest-impact uncovered pinned source spans, then reconcile the full cross-twin evidence ledger. No GPU execution, release submission, registry submission, or public tag is authorized by this slice.

## 11. Team Learning

For a variational fixed-effect profile, derive the Schur complement from the mean Hessian explicitly; the optimized variational covariance is a different curvature object.

## 12. Cross-Product Coverage

This slice covers the Julia variational numerical contract and package-suite evidence. It does NOT cover the R package, public bridge, other non-Gaussian objective findings, or whole-wave source review.

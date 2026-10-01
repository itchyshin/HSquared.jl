# After-task report: iterative-solver precision and control contracts

## 1. Goal

Close the current bounded Julia numerical-controls slice by validating finite precision inputs, matrix dimensions, and variance updates across iterative Gaussian and Monte Carlo REML helpers. This is one component of the larger HSquared twin programme, not completion of an FA or GLLVM arc.

## 2. Implemented

- Validated and canonicalized the animal relationship precision matrix before both assembled and matrix-free solver paths.
- Rejected non-finite, non-positive, non-representable, and subnormal variance inputs where their implied precision overflows.
- Added early dimension and fixed-effect rank checks for matrix-free REML likelihood and information helpers.
- Guarded Monte Carlo REML starting values, proposals, trace inputs, and controls.
- Clarified that fixed probes make the Monte Carlo EM map deterministic but do not guarantee convergence; the returned convergence flag remains the evidence.
- Corrected generated FA status wording: the Ledermann screen is not a pointwise identification proof, and fitted uniqueness information remains unassessed.

## 3a. Decisions and Rejected Alternatives

- Kept validation at the public/helper boundaries instead of allowing invalid values to fail later in factorization or optimization.
- Did not alter model defaults, add a dense animal-equation matrix, change capability status, or promote FA/GLLVM claims.
- Did not run a simulation campaign. The evidence required for this slice was deterministic unit testing; no campaign was estimated or started.

## 4. Files Touched

- `src/iterative_solve.jl`
- `test/wave1_numerical_contracts.jl`
- `src/validation_status.jl`
- `docs/src/validation-status.md`
- `GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-09-29-iterative-solve-precision-controls.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/source-review/2026-09-29-iterative-solve-precision-controls.md`
- This after-task report

## 5. Checks Run

- Focused Wave 1 numerical contract tests: **126/126 passed**.
- Julia 1.10 `Pkg.test()`: exited 0 and ended with `Testing HSquared tests passed` using one BLAS thread, four Julia threads, and the recorded candidate depot.
- Non-deploying Documenter/VitePress build from a content-matched writable copy: completed and rendered pages. Existing missing-docstring and VitePress configuration warnings remain; no deployment ran.
- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: passed at 11,024 bytes against the 14,000-byte cap.
- Gauss exact-hash review: clean component signoff for `src/iterative_solve.jl` SHA-256 `56703c9e0989143ee0500c395875e888799119dc1ed1adbc4ca24d26cec09d8d` and `test/wave1_numerical_contracts.jl` SHA-256 `083deac6582cca5f583c6cdf8a46bd40df57f98337b16112d9159d8fa4705c56`.
- Rose claim audit: clean with limitations; public covered count remains 7 and no capability was promoted.

## 6. Tests of the Tests

The focused test file was run before and after the guards were added. The negative control reproduced **10 failing assertions with 88 passing**; the final test run passed **126/126**. This shows the regressions detect the targeted invalid-input cases and pass after repair. It does not validate every solver path or establish statistical recovery.

## 7a. Issue Ledger

- The reviewed finite precision, variance, dimensional, and control-input defects in the named iterative-solver helpers are closed.
- A2 (FA identifiability/recovery evidence), E1 (complete Julia engine source review), and V3 (post-change CI evidence / closeout requirements) remain open.
- Remaining source spans, broad solver calibration, a new CI run for the complete dirty candidate, R/Julia parity for this component, FA or GLLVM capability acceptance, unusual inheritance, GPU work, and release actions remain outside this slice.

## 8. Consistency Audit

The code, tests, generated validation page, check-log shard, source-review receipt, and gate notes agree on the scope. No capability-status row, covered count, version, or release state changed. The generated FA caveat distinguishes a dimension screen from local covariance-map identification and from likelihood-level information.

## 9. What Did Not Go Smoothly

The first lease attempt could not write the shared lease registry under the default sandbox. A scoped lease was then granted through the approved elevated command. The first invocation of the shell preflight was mistakenly passed to Python; the corrected Bash invocation ran and reported the old handover to Claude. The current work proceeded in the dedicated candidate worktree after acquiring a scoped lease. The package manifest mismatch warning was observed; dependencies were not resolved or changed.

## 10. Known Residuals

- A2, E1, and V3 remain open for the broader programme. This slice does not close any of them.
- The structural after-task check passes. The integrated closeout compiler remains red because the programme-wide GATES.md still has A2, E1, and V3 unchecked; that is an accurate hold on whole-programme completion.
- The full local test suite and docs build are candidate-local evidence; CI for the complete current candidate was not verified.
- Docs build warnings about missing docstrings and local VitePress defaults remain.
- **This work does NOT cover** the remaining FA/GLLVM acceptance gates, all tracked Julia source spans, GPU execution, release submission, registry submission, merge, or public tagging.

## 11. Team Learning

Treat representability as part of a positive-variance contract: a finite positive value can still overflow on conversion or reciprocal. Keep solver input validation before both assembled and matrix-free branches, and test the public helper as well as the fit path. Fixed random probes support repeatability, not convergence.

## 12. Cross-Product Coverage

This slice covers the named Julia iterative-solver helpers, their Julia tests, and the generated Julia validation page. It does NOT cover the R package, R-to-Julia parity, any new fitted capability, or another provider. The twin capability boundary and `public_covered_count = 7` remain unchanged. Memory receipt: repository check logs and the active gate ledger carry this slice's durable evidence; no memory decision update was needed. Golden Set: no entry was added because this work supplies input-contract regressions and no new validated scientific reference result.

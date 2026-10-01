# After-task report: exact-current FA component review

## 1. Goal

Obtain an independent exact-current review of the bounded Gaussian T=4, K=1 FA engine and its ordinary-start and expected-information tests.

## 2. Implemented

No model source or test code changed in this review slice. Kirkpatrick, using Astra at high reasoning, reviewed four pinned source/test files. The current candidate's full Julia package test suite passed in the adjacent verification slice.

## 3a. Decisions and Rejected Alternatives

Keep the review verdict scoped to a component pass. Do not use a full-rank covariance-map Jacobian, a plug-in expected-information rank, or one ordinary-start replay to claim regular inference or population recovery.

## 4. Files Touched

- `docs/dev-log/source-review/2026-09-30-fa-exact-current-component-review.md`
- `docs/dev-log/check-log.d/2026-09-30-fa-exact-current-component-review.md`
- `docs/dev-log/after-task/2026-09-30-a2-fa-component-review.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `GATES.md`

## 5. Checks Run

- Read-only exact-hash review: four hashes verified before and after; bounded component PASS, whole A2 HOLD.
- Full Julia 1.10 `Pkg.test()` on the current integrated candidate: exit 0, `Testing HSquared tests passed`; exact runner and selected source/test hashes are recorded in `check-log.d/2026-09-30-va-schur-recheck.md`.
- Current live R bridge tests: 213 passed, 0 failed, 0 warnings, 0 skips with `HSQUARED_REQUIRE_BRIDGE=true`; receipt is in the sibling `hsquared` repository.
- No fit or simulation was run by the reviewer. No simulation was needed for this static component review.

## 6. Tests of the Tests

The reviewer inspected the registered multistart tests, the production FA map rank test, and the expected-information test. The expected-information fixture contrasts repeated pedigree records with unrelated one-record animals. Current package tests ran against the exact pins. These tests establish code-path, map-rank, and plug-in expected-information properties; they do not establish recovery rates or interval calibration.

## 7a. Issue Ledger

- Closed in this slice: independent bounded mathematical review of the four exact-current FA pins.
- Carried: routine-start recovery across the predeclared replicates, weak-direction/uncertainty diagnostics, broader scale/order checks, remaining source spans, and whole-wave panel signoff.
- One source wording cleanup remains: an RNG-free assertion conflicts with seeded test fixtures. The edit is deferred until the six refs reported by file preflight are inspected and ownership is reconciled.

## 8. Consistency Audit

A2 remains open. FA remains bounded and experimental, with no capability or covered-count promotion. The source review does not certify inference, broad recovery, or automatic rank selection. The companion live R bridge pass is current focused evidence; V3 remains open.

## 9. What Did Not Go Smoothly

The preflight for `src/multivariate.jl` found work on six refs and a stale Claude handover in the current worktree. The exact-current docstring cleanup was therefore carried rather than applied without reconciling the other diffs. This does not block documentation-only review receipts.

## 10. Known Residuals

This slice does not close A2, E1, or V3. The 200-seed FA study remains held at its documented estimate above three hours and has not been run. The reviewer did not run simulations or independent fits.

## 11. Team Learning

Keep natural-coordinate expected-information rank, uniqueness-floor behavior, and regular inference as separate evidence claims. A component signoff should report exactly which one its tests establish.

## 12. Cross-Product Coverage

This slice covers a bounded Julia FA engine/test review and records a separate current live R bridge result. It does NOT cover every tracked Julia source span, broad recovery or calibration, hosted CI, GPU execution, or release readiness.

# Arc 1 G5 inspector subprocess boundary tests

## 1. Goal

Add direct tests for the receipt checker's handling of retained-artifact inspector process results. Keep the G5 gate open because test doubles do not prove live Julia execution or scientific evidence.

## 2. Implemented

Added three focused Python tests for empty and missing-inspector cases, launch and timeout errors, subprocess limits, nonzero exit handling, malformed output, row and path validation, and valid JSON after startup noise. Updated the current-source test map to v21.

## 3a. Decisions and Rejected Alternatives

Used mocked subprocess results to isolate the checker's branches without launching Julia or inspecting retained artifacts. A real Julia invocation would test a different boundary and remains open. Assumption: this is a bounded engineering test slice; if the intended goal were live process reliability, these tests would not satisfy it.

## 4. Files Touched

- `test/test_arc1_receipt_adversaries.py`
- `docs/dev-log/check-log.d/2026-10-09-g5-inspector-subprocess-boundaries.log`
- `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v21.md`
- `docs/dev-log/after-task/2026-10-09-g5-inspector-subprocess-boundaries.md`

## 5. Checks Run

- `python3.13 test/test_arc1_receipt_adversaries.py RetainedArtifactInspectorBoundaryTests`: exit 0, 3 tests passed in 0.117 seconds.
- `git diff --check`: pending final run.
- Read-only exact-source review of map v21 passed; the corrected v22 map also passed review at SHA-256 `50ed4562148f0f9db278379b1f1abdb93ac9709fc620124a44c875fc2c3cb4ff`.
- No studies, fits, campaigns, R tests, or scientific gates were run.

## 6. Tests of the Tests

Each adverse subprocess outcome asserts the exact `ReceiptError` path; the success fixture checks that the last stdout line is parsed after startup noise. The test asserts the timeout, one-thread settings, depot prefix, nonzero exit and stderr tail bound. Duplicate paths use two requested rows so the duplicate-path branch is reached after the count check.

## 7a. Issue Ledger

- Fixed: G5 map v20 listed inspector subprocess boundaries as untested. Map v21 records the new direct tests and keeps live subprocess behavior as a residual.
- Open: combined certificate mutations, other checker predicates, live admission, raw diagnostic checks, and artifact performance.

## 8. Consistency Audit

Confirmed the receipt checker source did not change. Checked adjacent JSON decoding, list length, row typing, duplicate detection, exact path matching, subprocess timeout and output handling. The refreshed test log hash is `b0bd6f2298e2537c36b4e09d68c64628ae9843ad52921b73c1f393fc87296345`; the test source hash is `00609e66eb39c02398920f50ed37bb8c19a0c2ff4e3a8cedf56d534074601ed0`.

## 9. What Did Not Go Smoothly

The first patch did not match the import alias and made no change. The initial duplicate-row fixture failed the earlier response-length check, so it was corrected to request the same path twice and reach the duplicate-path check. The closeout generator resolves paths under the brain repository, so the report was written in this checkout and will be validated with the repository's report checker.

## 10. Known Residuals

No live Julia subprocess was started. Tests do not establish actual timeout cleanup, inspector semantics, large-artifact behavior, or G5 acceptance. Two checker predicates remain open: non-dictionary row coverage and invalid path-type coverage are now present; broader malformed-field combinations remain untested. G0 remains met; G1 through G8 remain open. Capability remains experimental; covered count remains seven.

## 11. Team Learning

Memory receipt: read the supplied HSquared.jl operating contract and the repo's current G5 map. The brain route manifest was absent for this worktree; repository docs were used as technical truth. Golden Set: not run; no model behavior or scientific gate changed.

## 12. Cross-Product Coverage

Covers: Python receipt-checker handling of inspector subprocess responses.

does NOT cover: live Julia process behavior, R parity, scientific calibration, campaign evidence, public grammar, or capability promotion.

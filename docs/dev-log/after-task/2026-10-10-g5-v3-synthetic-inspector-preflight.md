# G5 v3 synthetic inspector preflight

## 1. Goal

Check that a synthetic repeatability profile-history artifact built from current source passes the canonical container inspector, with bounded subprocess cleanup and no study seed or scientific gate credit.

## 2. Implemented

Created and ran an isolated v3 engineering capsule with a current-source hash pin, a regression test for that pin, a frozen 46-file input inventory, exact-source review, a synthetic container build, canonical inspection, and an independent retained-receipt check. The run completed in 20.406 seconds. No package API or model source changed.

## 3a. Decisions and Rejected Alternatives

The stale v1 freeze was not reused. The v2 capsule was held after independent review found its embedded executor-test hash stale and its gate file still showed completed v1 checks. V3 updates the pin and tests it. The v1 and v2 evidence remains unchanged. The artifact was inspected in its original fresh output location; copying it elsewhere would change absolute paths that the inspector validates.

## 4. Files Touched

The isolated evidence capsule is `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-current-container-preflight-v3/`. It contains the corrected builder, regression test, source freeze, pre-run review inputs, static and supervisor test logs, retained run outputs, independent check, and post-run gate ledger. The held v2 capsule remains intact. This report, `docs/dev-log/source-review/2026-10-10-g5-current-container-v3-review.md`, `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`, and `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md` record the result.

## 5. Checks Run

- Python supervisor suite: 14/14 passed in 2.370 seconds with host process-inspection permissions. Log SHA-256: `9680c178c681084fc5ea978854cae59034fa173d13bc7da48ae92d0f44ed1064`.
- Python source compilation: exit 0.
- Julia builder parse: `ARC1_G5_BUILDER_PARSE_PASS`.
- Current source freeze: `ARC1_G5_SOURCE_FREEZE_PASS`, 46 pins.
- Retained static-check log SHA-256: `d7390a2995d44d218b361e0673cf042a0bf4361d804f22ecac7637b0709cf877`.
- The five shared Julia files in the G5 freeze match their G7 package-freeze v26 hashes.
- Independent exact-source review: PASS for source-freeze SHA-256 `676d327e1f0d009ddd2066e93ac6fb3b6ecbfc090ea85a42af24b06aff4a4e00`. The reviewed gate-plan SHA-256 was `8cf9a30ad1a73e5d49618085868289c001618c5412a107dca423b145da5c560c`. Review record: `docs/dev-log/source-review/2026-10-10-g5-current-container-v3-review.md`.
- Bounded synthetic artifact preflight: `ARC1_SYNTHETIC_CONTAINER_PREFLIGHT_PASS`, total elapsed time 20.406 seconds. Receipt SHA-256: `604d5ad0f5024e44610311d7a3adcb5e06b20b975db02f5cc8ed2e1163b61ad6`.
- Independent retained-receipt check: `ARC1_G5_V3_RETAINED_RECEIPT_INDEPENDENT_CHECK_PASS`. It verified one inspected row, matching recomputed data identity, result identity and profile-history aliases, successful child cleanup, unchanged source pins, and explicit false values for gate credit, study attempt, seed allocation, and legacy-artifact access.
- Repo preamble cap: `CAP OK`, 9,224 bytes within the 14,000-byte limit.
- After-task structure validation passed. The same command's whole-program acceptance audit correctly returned nonzero because the parent Arc 1, automatic-rank, and non-GPU ledgers still contain unmet gates.

## 6. Tests of the Tests

The new regression test verifies that the builder's embedded hash equals the current frozen executor-test source. It catches the stale v2 value. The independent receipt check verifies retained fields and cleanup after the runner removes its temporary artifact. Neither check treats a fake-engine result as a scientific fit.

## 7a. Issue Ledger

The G5 engineering capsule checks pass. The Arc 1 scientific gates remain G0, G1, G6, and G7 met for their recorded scopes; G2, G3, G4, G5, and G8 open. G5 still requires interval formation, all-attempt coverage, and real fitted-trace performance. No seed, denominator, or study status changed. The after-task structure check passed; its full acceptance audit correctly returned nonzero because the parent Arc 1, automatic-rank, and non-GPU ledgers still contain unmet gates.

## 8. Consistency Audit

No public fitting or interval-calibration claim follows from this probe. Capability status remains experimental and the public covered count remains seven. I compared the five shared files touched since the older G5 freeze against G7 package-freeze v26; all five hashes match exactly, so G7 remains valid for its reviewed v26 source. The R checkout and public grammar were not changed.

## 9. What Did Not Go Smoothly

The v1 freeze was stale for five current source files. V2 was held after review found a stale test-source hash embedded in its builder and v1 results copied into its gate file. Three process-group tests failed in the default sandbox because it denied `ps` and `SIGKILL`; the diagnostic process group was confirmed gone, and all 14 tests passed with access limited to test-owned temporary groups. The first independent receipt script incorrectly expected the temporary artifact to remain after inspection. The runner intentionally removes it. A corrected check verified cleanup and the retained inspector projection.

## 10. Known Residuals

The fixture uses a fake engine and one fixed engineering-probe seed. It tests container construction, semantic identity, result summaries, and profile-history transport through the inspector. It does not test fitted optimizer traces, interval formation, all-attempt coverage, or real profile performance. G5 remains open and this preflight earns no scientific gate credit.

## 11. Team Learning

When a fixture builder pins a test source, test the embedded digest against the frozen source in the fixture suite. A source inventory alone does not prove that an internal constant agrees with the inventory. Keep an engineering preflight ledger separate from the Arc 1 scientific gate ledger.

## 12. Cross-Product Coverage

This work covers the Julia synthetic container writer and canonical inspector with a fake engine. It does NOT cover real Julia model fitting, R source or tests, the R-Julia bridge, public formula grammar, missing-data routes, or downstream statistical interval consumers. G7's previously reviewed Julia/R package check remains valid for its exact v26 source freeze. No cross-product parity claim is added by this work.

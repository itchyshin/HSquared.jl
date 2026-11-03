## 1. Goal

Align the Arc 1 G1 synthetic retained-receipt fixture with the actual nine-suite Julia oracle runner, including the v2 FA contract tests, while preserving the locked verifier source hash.

## 2. Implemented

Updated the synthetic retained-receipt adapter to include the v2 contract test and added a regression test requiring its exact ordered parity with the current oracle runner. The verifier's production source and the normal oracle runner were not changed.

## 3a. Decisions and Rejected Alternatives

Kept the locked production verifier hash intact. Updated only the synthetic receipt fixture so its test commands exercise the same nine-suite list as the live runner. Did not change model code, R code, runner selection, study admission or acceptance thresholds.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/tests/test_verify_retained_checks.py`
- `docs/dev-log/check-log.d/2026-10-05-arc1-g1-verifier-inventory.md`
- `docs/dev-log/after-task/2026-10-05-arc1-g1-verifier-inventory.md`
- `docs/dev-log/after-task/2026-10-05-arc1-g1-verifier-inventory-assessment.json`

The already-dirty runner, R tree and other Arc 1 work were preserved. `tools/arc1_oracles.py` was read and hashed but not edited.

## 5. Checks Run

- The test-first regression failed for the intended reason: the synthetic receipt used an eight-suite list, omitting v2, while the runner expected nine commands.
- Focused verifier tests passed: 8 tests, exit 0.
- All Python tests in the Arc 1 lane test directory passed: 8 tests, exit 0.
- `python3 tools/arc1_oracles.py --self-test` passed with `ARC1_ORACLE_SELF_TEST_PASS`.
- `python3 -m py_compile` on both changed Python files passed.
- Scoped `git diff --check` passed.
- Exact file preflight found no foreign-branch edits on the changed synthetic test path. The wider repository census still showed active Cursor lanes.

## 6. Tests of the Tests

The new equality test was observed failing before the fixture correction, specifically because the synthetic receipt omitted `test/arc1_fa_v2_contracts.jl` and had an incomplete command list. It passed after the fixture was aligned. A Luna read-only review independently confirmed all nine entries match in order.

## 7a. Issue Ledger

Fixed the synthetic G1 receipt fixture's stale Julia suite inventory. The scientific G1 gate remains open pending a reviewed current-source freeze and a fresh admitted run.

## 8. Consistency Audit

Compared the synthetic adapter fixture and live oracle runner. Both contain the same nine paths in the same order; the v2 contract test is second. The locked verifier source hash remains unchanged. Confirmed this slice changes no fitted capability, numerical result, public interface, R source or study protocol.

## 9. What Did Not Go Smoothly

The first test invocation exposed an incorrect relative path in the newly written import. I corrected it before the meaningful red run. The project router has no LOAD-FIRST manifest for this worktree. The global closeout template targets the separate Shinichi brain checkout and could not write into this project, so this report was created directly in the HSquared worktree. No file was written by the failed template command.

## 10. Known Residuals

This is verifier-only evidence. No reviewed current-source freeze or fresh scientific G1 run was produced. G0 remains open on profile-method study admission; G2–G8 and all pilot/confirmation evidence remain outstanding. The R lane and package checks were not run. The shared coordination board was not edited because preflight found 35 refs with divergent work on that file.

## 11. Team Learning

Keep the retained verifier's test inventory in exact ordered parity with the live runner, and assert that parity directly. Loaded the repository instructions, Graft source map, and exact-path lane preflights. No LOAD-FIRST manifest was available. The Golden Set was not run because this test-inventory mismatch did not match a listed recurring error class. No new statistical or public-facing decision was made.

**Naturalness assessment:** recorded separately in `2026-10-05-arc1-g1-verifier-inventory-assessment.json`.

## 12. Cross-Product Coverage

Covers: Julia G1 retained-receipt inventory parity and its synthetic verifier tests.

Does NOT cover: actual scientific G1 results, R live parity, profile-method admission, simulation calibration, package checks, release readiness or any capability-status promotion.

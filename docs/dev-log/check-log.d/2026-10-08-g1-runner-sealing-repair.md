# Arc 1 G1 timeout policy and runner log sealing

The current-source G1 oracle run `20261008T211555Z-0d61003471b8` stopped at the 480-second gate cap after eight Julia test files passed. Its executor log changed after the parent runner returned, so the receipt is retained as failed, unsealed diagnostic evidence only.

The reviewed runner amendment sets timeout-policy version 2 and raises only the G1 gate cap to 900 seconds. G6 remains 4,200 seconds. Per-command limits and scientific inputs do not change. Process cleanup now checks the whole process group even after its parent exits, waits for descendants before sealing logs, records an explicit `log_sealed` state, omits hashes for unresolved logs, and fails closed when descendants survive a successful parent.

G7's package runner now applies the same cleanup contract. Its synthetic runner checks cover parent-first child exit, timeout, interruption, and unresolved groups. The oracle runner has matching synthetic receipt checks plus a helper-level parent-first log test with unconditional cleanup in `finally`.

Independent Astra review passed the exact files:

- `tools/arc1_oracles.py`: SHA-256 `2c63d66326c15840535473bab617c1abefaed888aba2fb14f8269091fcf65672`.
- `tools/arc1_package_checks.py`: SHA-256 `67b405ca2fe2942c2d2968715fa988466ebdcb0ca125f04f1b02b8a6679cc2ab`.

Verification passed: `python3 -m py_compile tools/arc1_oracles.py tools/arc1_package_checks.py`; `python3 tools/arc1_oracles.py --self-test` (`ARC1_ORACLE_SELF_TEST_PASS`); `python3 tools/arc1_package_checks.py --self-test` (`ARC1_PACKAGE_CHECKS_SYNTHETIC_SELFTEST_PASS`); and `git diff --check` on both files.

The existing G1, G6, and G7 runs remain historical. Fresh G1 and G6 runs need a new reviewed paired freeze; G7 needs a new reviewed exact package freeze containing both changed runners, followed by the full package checks. No scientific study or seed allocation ran.

## G1 current-source pass under oracle freeze-v6

G1 run `20261008T222940Z-3fc1157db3e4` passed under reviewed freeze-v6. The retained receipt SHA-256 is `2342624dbfcb35e500ee719a3f30e73505dca7ec5b2d0b622402a26f028d92cb`; the reviewed freeze SHA-256 is `f2a22e3b16c7f9c0b85cfa403b77485913ed0af7ac0eb53ddf280171add6bcfb`. All nine Julia suites passed with 2,950 assertions and zero failures, errors, or broken tests. The executor took 233.650 seconds within its 300-second per-command cap; total G1 time was 516.848 seconds under the 900-second gate cap. Every command log is sealed. The retained verifier emitted `ARC1_G1_RETAINED_RECEIPT_VERIFIED`; Astra independently passed the exact run receipt and source bindings. G1 is closed for its stated mathematical-oracle scope only. G6 is currently running under the same paired freeze. G7 remains open pending a fresh exact freeze and full package run.


## G6 and G7 current-source passes

G6 run `20261008T223834Z-f1eacceae56e` passed under reviewed oracle freeze-v6. Retained verification emitted `ARC1_G6_RETAINED_RECEIPT_VERIFIED`. Astra independently audited the exact receipt and source bindings: 47 Julia and 100 R files match the freeze and source snapshots; all three commands exited zero with sealed logs and no timeout, interruption, or process leak. Required-live R passed 682 assertions across seven files with zero failures, errors, skips, or warnings. Total elapsed time was 3,084.804 seconds. Receipt SHA-256 `63d28a9a55c37b59d157a487f99b088cc94971a1d1846788976281d84de57fa5`; freeze-v6 SHA-256 `f2a22e3b16c7f9c0b85cfa403b77485913ed0af7ac0eb53ddf280171add6bcfb`; live log SHA-256 `9a9b33182251c69bb10846961f85e2eb1d63ed7335e561471e880b993a65f614`.

G7 package run `20261008T233110Z-39f8c05962` passed Julia, required-live R, R CMD check, and docs under reviewed package freeze-v8. The retained verifier emitted `ARC1_G7_RETAINED_RECEIPT_VERIFIED`. The independent reviewer verified all 772 Julia and 275 R inputs, both runners, 14 source snapshots, six zero-exit commands and sealed logs. Julia recorded 11,533 passes; live R recorded 682 assertions with zero failures, errors, skips, or warnings; R CMD check reported zero errors, warnings, or notes (`Status: OK`). The docs output-tree SHA-256 is `ec34d127fb6ad6278480032bf36f4fe68ad3a0631516dc709c8d8642cad608d7`. Receipt SHA-256 `caeea6dd5a2107bec09963c6136a01abfc664dc4e87196c47276d866025e3d47`; freeze-v8 SHA-256 `ff46f444bcda30eb60d5728f47403a3e342a1fb30e44a1a61e9cdb24cdab8bfd`.

The GATES ledger now closes G6 and G7 for their frozen scopes. G2-G5 and G8 remain open; the reviewed G2 fresh-development tranche candidate still awaits owner approval. These package/parity checks provide no scientific selection or interval-calibration credit.

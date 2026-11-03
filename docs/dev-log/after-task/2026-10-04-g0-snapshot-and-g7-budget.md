## 1. Goal

Make the Arc 1 G7 replay budget description consistent with the current runner, record exact independent review, and lock the current G0-G8 acceptance snapshot without starting package or study execution.

## 2. Implemented

- Corrected the current shared R allowance to 120 minutes and stated the measured basis and unmeasured full `R CMD check` duration.
- Labeled earlier package results and the old 3,600-second cap as historical.
- Copied the current Arc 1 G0-G8 ledger byte-for-byte into the lane kit `checks/` directory, then created and verified the gate lock under the existing approval of the full Arc 1 programme.
- Recorded Astra's exact-source review and its limits.

## 3a. Decisions and Rejected Alternatives

Preserved the full G7 acceptance: current-source Julia package tests, required-live R checks, full R package check, rendered documentation, and same-run source evidence. Did not claim a package pass from historical receipts. Created only the acceptance lock; G0 remains open pending executable-contract reconciliation and current-source admission. Did not run a full package replay, allocate seeds, change capability status, or alter the covered count.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/package-check-plan.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checks/arc1-acceptance-ledger.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/gates.lock.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint-archive-20261004-before-g0-lock.md`
- `docs/dev-log/source-review/2026-10-04-g7-plan-chronology-review.md`
- `docs/dev-log/check-log.d/2026-10-04-g0-snapshot-and-g7-budget.md`
- `docs/dev-log/after-task/2026-10-04-g0-snapshot-and-g7-budget.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 tools/arc1_package_checks.py --self-test`: exit 0; synthetic checker cases passed and the success marker was printed.
- `cmp .unlazy/arc1-gaussian-reliability/GATES.md LOOP/lanes/arc1-gaussian-reliability-20261002/checks/arc1-acceptance-ledger.md`: exit 0; both files have SHA-256 `be3bcb8c546d903a55ac47cb79f92ffdbeec2023a98234102dcfd1bdf342a4ef`.
- `git diff --check`: PASS.
- `slop_check.py` on the absolute plan path: PASS, zero findings.
- `arc_gate_lock.py lock LOOP/lanes/arc1-gaussian-reliability-20261002`: PASS; locked GOAL, check snapshot, and ultra-plan.
- `arc_gate_lock.py verify LOOP/lanes/arc1-gaussian-reliability-20261002`: PASS, `GATES OK`.
- Astra exact-source review: PASS for G7 plan chronology and the stated acceptance boundary; not a runtime review.
- After-task structure validation: PASS. Full acceptance-ledger closeout remains open.

## 6. Tests of the Tests

The G7 runner self-test exercises success and failure guards, including nonzero exit, missing markers, timeout, interruption, source mutation, test sandbox mismatch, docs environment, required HTML, and failure propagation. No campaign oracle or statistical gate was exercised.

## 7a. Issue Ledger

- Fixed: the package plan said the active R budget was 60 minutes while the runner and other plan sections specify 120 minutes.
- Fixed: initial historical replay paragraphs were phrased as current status.
- Open: G0 lock and user review of the exact G0-G8 snapshot; fresh independently reviewed source freeze and full G7 replay; every other Arc 1 and non-GPU H2 acceptance gate.

## 8. Consistency Audit

Compared the package plan and current runner limits, verified the unchanged G0-G8 source ledger against the lane snapshot by byte comparison and hash, and reviewed Astra's source-bound findings. The corrected plan distinguishes execution allowance from acceptance. The coordination board now reflects the verified lock while keeping G0 and all scientific gates open. No G0-G8 scientific threshold or failure rule changed.

## 9. What Did Not Go Smoothly

The first relative-path `slop_check.py` call resolved against the brain repository and could not find the worktree file. Repeating with the absolute worktree path produced a valid zero-finding result. An initial lease attempt lacked permission to write the shared registry; the lease was then recorded with narrow scoped permission and verified.

## 10. Known Residuals

The G0 lock is present and verifies against the lane goal, plan, and exact G0-G8 snapshot. Lock SHA-256: `0e54840b39cf68f0798fdd85aff04b70ba61b54d52de28bf21f25766665b74d9`. G0 remains open pending executable-contract reconciliation and current-source admission. No current-source G7 package replay or statistical campaign has run. The full H2 goal is incomplete; H1-H9 and Arc 1 G0-G8 remain open. Public covered count remains seven.

## 11. Team Learning

The source review found a stale timing statement, then exact-hash follow-up confirmed the correction and historical chronology. Graft was used to locate the current MV+PE route, G7 checker, and plan dependencies; it saved approximately 344,465 tokens across three calls this turn. No other agents performed implementation work.

## 12. Cross-Product Coverage

Covers: the Julia lane's G7 plan chronology and an exact G0-G8 acceptance snapshot prepared for approval.

Does NOT cover: current-source Julia/R package passes, rendered docs pass, G7 gate closure, scientific calibration, automatic rank validation, repeatability intervals, MV+PE ordinary-start recovery, other H2 routes, release state, or project completion.

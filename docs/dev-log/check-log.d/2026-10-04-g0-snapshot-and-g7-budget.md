# 2026-10-04 Arc 1 G0 snapshot and G7 budget correction

## Scope

Correct the current G7 package-check plan, independently review its chronology and acceptance boundary, and lock the exact G0-G8 ledger snapshot under the already approved programme. No acceptance gate was marked complete.

## Current inputs

- G0-G8 ledger and snapshot SHA-256: `be3bcb8c546d903a55ac47cb79f92ffdbeec2023a98234102dcfd1bdf342a4ef`; the snapshot under the lane `checks/` directory is byte-identical to `.unlazy/arc1-gaussian-reliability/GATES.md` (`cmp` exit 0).
- G7 plan SHA-256 after correction and historical labeling: `2e3de3a10dc8b850ba4d4fff0ca5216f22be1d96f6b747d4eb620de9f0bd8274`.
- Current G7 runner SHA-256: `a726cbdabe44288323788ff16c6aabbda731271b1b60475436b0097fcf69def3`.
- Current retained-check verifier SHA-256: `b9dd0269d7c00f1be7c3663514b2a4f9f547c7082d3990c5db7ee3c3b80871a6`.

## Checks and review

- `PYTHONDONTWRITEBYTECODE=1 python3 tools/arc1_package_checks.py --self-test`: PASS; all listed synthetic cases passed, including nonzero exit, missing marker, timeout, interruption, source mutation, test-sandbox mismatch, docs environment, required HTML, and failure propagation. Exit 0; marker `ARC1_PACKAGE_CHECKS_SYNTHETIC_SELFTEST_PASS`.
- `cmp .unlazy/arc1-gaussian-reliability/GATES.md LOOP/lanes/arc1-gaussian-reliability-20261002/checks/arc1-acceptance-ledger.md`: PASS; byte-identical SHA-256 above.
- `git diff --check` on the edited plan: PASS.
- `slop_check.py` on the absolute edited plan path: PASS, zero findings.
- Astra reviewed the exact G7 plan and checker source hashes. The 120-minute limit is an execution allowance supported by a partial timing basis, with full package-check time explicitly unmeasured. The changes do not relax acceptance criteria. Review receipt: `docs/dev-log/source-review/2026-10-04-g7-plan-chronology-review.md`.
- After-task report structure check: PASS. The generic full closeout check remains unmet because the overall H2 and Arc 1 gates are still open.

## Outcome and limits

The stale 60-minute current-limit sentence was corrected to 120 minutes. Older replay status and 3,600-second wording were labeled historical. The current G0-G8 ledger was copied exactly into the Arc 1 lane kit and locked. Lock SHA-256: `0e54840b39cf68f0798fdd85aff04b70ba61b54d52de28bf21f25766665b74d9`; `arc_gate_lock.py verify` passes. G0 itself remains open pending executable-contract reconciliation and current-source admission. No full G7 Julia/R/docs replay, real fit, seed allocation, pilot, or confirmation study ran. H1-H9 and Arc 1 G0-G8 remain open; covered count remains seven.

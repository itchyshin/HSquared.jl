## 1. Goal

Validate one source-reviewed synthetic current-container preflight, while preserving the legacy artifact timeout as terminal and keeping statistical G5 open.

## 2. Implemented

Fixed the supervisor's process-group probe to honor a sub-10 ms remaining cleanup budget and fail closed if `ps` times out. Added a regression test for a 4 ms probe budget. Refreshed the 46-file source freeze, test log, exact candidate hashes, and G1-G3 Unlazy evidence. Astra passed the exact synthetic-preflight capsule. One synthetic N=16 fixture was written and checked through the canonical current-container inspector in 26.224 seconds. The exact projection passed, the source and freeze hashes remained unchanged, child groups were reaped, and the fixture directory was removed.

## 3a. Decisions and Rejected Alternatives

Did not retry or read the 130,851,693-byte legacy artifact. The synthetic fixture checks current-container integration only; its 22,812-byte size does not establish legacy-file performance, large-file memory use, interval calibration, or statistical G5. The separate retained-artifact candidate v3 received Astra HOLD and is rejected as stale because it reuses a terminal run and output path, pins an old inspector, lacks executable safeguards, and does not require a successful retained result.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-current-container-preflight-v1/run_preflight.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-current-container-preflight-v1/test_run_preflight.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-current-container-preflight-v1/source-freeze.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-current-container-preflight-v1/supervisor-self-tests.log`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-current-container-preflight-v1/GATES.md`
- `docs/dev-log/decisions/2026-10-09-g5-legacy-artifact-preflight-candidate.md`
- `docs/dev-log/source-review/2026-10-09-g5-synthetic-preflight-source-review.md`
- `docs/dev-log/source-review/2026-10-09-g5-v3-stale-replay-review.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- This report.

The one-run synthetic artifact and receipt are retained under `/private/tmp/arc1-g5-current-container-preflight-v1/`. Temporary Unlazy approvals are under `/private/tmp/arc1-g5-unlazy-approved/`.

## 5. Checks Run

- Python 3.13 supervisor tests: 13/13 passed in 2.251 seconds under unrestricted local execution. Three process-group tests initially failed inside the sandbox; the rerun with the needed process-group permission passed.
- Python compilation passed for the runner, inspector child, and tests.
- Julia 1.10.0 parsed the fixture builder without executing it.
- Exact 46-file source-freeze check passed.
- Astra read-only review passed the synthetic capsule at candidate SHA-256 `d4b5ff931add3c9931d28a34082a9ff7afcaa8f47948ad297c4577c8baa07167` and freeze SHA-256 `2dd5bb7c111d017c02eeff8ff06bf694df355a63f9b4508af5e1d2b60228e57d`.
- The synthetic runner passed in 26.224 seconds. Receipt: `/private/tmp/arc1-g5-current-container-preflight-v1/receipt.json`; artifact SHA-256 `0c899cbbfb6ad90e553a081407dbf2dc42d102dac782256d2f9085f9f8eb725d`. Receipt records no gate credit, study attempt, seed allocation, or legacy artifact read.
- Unlazy local supervisor ledger: 5/5 checks met. Main Arc 1 remains G2-G5 and G8 open; G0, G1, G6, and G7 remain met only for their recorded scopes.
- `python3 ~/shinichi-brain/tools/slop_check.py` on both new review/report prose files: 0 findings.
- `python3 ~/shinichi-brain/tools/arc_gate_lock.py verify LOOP/lanes/arc1-gaussian-reliability-20261002`: passed before the final checkpoint and report updates; rerun after those updates before closeout.

## 6. Tests of the Tests

The new regression asserts that a 4 ms remaining cleanup budget is passed unchanged to the process-table probe and that a timed-out probe reports a possibly-live process. Existing tests exercise timeout, interruption, supervisor signals, cleanup failure, exact projection keys/types, and source-freeze mutation. The final full suite passed all 13 tests.

## 7a. Issue Ledger

- Fixed: process-table probes could exceed a very short remaining cleanup budget.
- Deferred: the legacy 130,851,693-byte artifact remains unread after its terminal timeout.
- Rejected: retained-artifact replay candidate v3 is stale and held by independent review; it changes no gate or study status.
- Open: Arc 1 G2, G3, G4, G5 statistical requirements, and G8.

## 8. Consistency Audit

Confirmed the local preflight is explicitly engineering-only. Its receipt binds the exact source freeze before and after execution, requires the exact four-field inspector projection, and records false for study attempt, seed allocation, legacy read, and gate credit. The G5 design and overall checkpoint remain open. The capability status and covered count were not changed. The G0 gate lock still verifies.

## 9. What Did Not Go Smoothly

The sandbox denied process-group signalling in three integration tests; the exact same suite passed when run with permission to exercise child process groups. The Unlazy approvals were tied to an older inherited PATH, so the unchanged checks needed fresh temporary approval records. The first source-freeze regeneration used the wrong repository-root depth and failed before writing a manifest; the corrected command produced and verified the 46-file freeze. Astra then held the separate legacy-replay candidate for stale identity and missing executable safeguards.

## 10. Known Residuals

No statistical G5 criterion is proved. The synthetic result is small and does not estimate performance on the legacy artifact. No pilot, confirmation, or new study attempt ran. G2 remains paused pending the exact fresh-development allocation decision. G3, G4, and G8 remain open. The current retained-artifact candidate v3 must not run.

## 11. Team Learning

When a source review finds a consumed run path, stale inspector identity, or safeguards expressed only as prose, reject the candidate and preserve that disposition. A passing synthetic container check does not authorize extrapolation to a large legacy artifact.

Memory receipt: loaded the repo's HSquared instructions and Arc 1 checkpoint; `lane_preflight.sh` found one active lane. `route.py` found no LOAD-FIRST manifest for this worktree path. The repository docs and exact source reviews governed the technical decisions. The hub cross-repo guards were not separately loaded.

Golden Set: not run; no production estimator or package contract changed.

## 12. Cross-Product Coverage

This slice covers the Julia current-container writer/inspector integration and the Python supervisor only. It does NOT cover R parity, the legacy artifact, large-file resource use, repeatability intervals, FA rank selection, study-level calibration, package release, or GPU execution. This remains HSquared engineering work; manuscript and publication tasks are out of scope.

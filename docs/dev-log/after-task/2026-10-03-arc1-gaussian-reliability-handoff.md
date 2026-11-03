# Arc 1 Gaussian reliability handoff, 2026-10-03

## 1. Goal

Record the verified state of the wider Arc 1 Gaussian reliability programme after the bounded automatic FA-rank paired programme closed. This report is a handoff and checkpoint. It does not close Arc 1.

The earlier automatic FA-rank programme passed its own eight bounded gates. That result covers its selected scope only. Ordinary optimizer-driven K1 selection, broad reliability, and selection-adjusted interval calibration were not established by that programme.

## 2. Active lenses and agents

The lane uses the scientific, numerical, validation, bridge, and public-claim review lenses specified in the repository instructions. Retained work names Astra reviewers for the independent package freeze and focused scientific reviews, and Luna workers for implementation and execution. The package-freeze reviewer completed a read-only source and runtime audit at 2026-10-03T19:14:05Z. That review did not run tests or fits. The execution checkpoint records active FA and profile implementation owners; this documentation pass made no source edits and started no agents.

## 3. Decisions and boundaries

- Keep all Arc 1 controls opt-in. The legacy path and current experimental status remain unchanged.
- Treat each source-matched receipt as evidence only for its exact inputs. Do not transfer results from an older source freeze to current bytes.
- Preserve the predeclared 400 confirmation attempts per cell. No allocation was changed in this handoff.
- No confirmation study or campaign is authorized by this report. Required measured pre-run evidence and approval for any run projected above three hours still apply.
- GPU, broader model families, production scaling, release, and public capability promotion remain outside this Arc 1 handoff.

## 4. Files changed

This handoff adds this report and appends a dated entry to `docs/dev-log/check-log.md`. It does not change model source, tests, capability status, validation-debt rows, the active execution checkpoint, protected settings, or the isolated R worktree.

## 5. Checks and exact outcomes

- `bash /Users/z3437171/shinichi-brain/tools/lane_preflight.sh /Users/z3437171/.codex/worktrees/b9ae/HSquared.jl` completed. It reported a live Arc 1 lease, overlapping worktrees, and duplicate design slots. This pass therefore stayed documentation-only.
- The current `.unlazy/arc1-gaussian-reliability/GATES.md` has G0 through G8 unchecked. Its retained G1 and G6/G7 receipts verify their historical receipt bundles, but those bundles use earlier freezes and are not current-source acceptance evidence.
- The independent package freeze at `/private/tmp/h2-arc1-g7-independent-freeze-20261003T191405Z/package-freeze-v3.json` records 768 Julia and 273 R files, with base commits Julia `1cb996204e18acbea9e1e7ff9c7a73122d3c34bc` and R `a563ea88f3076819a4a5d8966e2644489efd1688`. Its reviewer explicitly limited the work to a read-only source, runtime, and dependency audit; no tests, documentation builds, fits, or campaigns were run as part of that review.
- A separate full Julia package test run passed in 707.689 seconds. Direct comparison of its 13 pinned source/test inputs against the independent freeze matched all 13. This is current Julia package-test evidence, but it has not yet been admitted by a fresh canonical G7 run.
- A separate full R documentation build and mandatory-live `R CMD check` passed in 527.294 seconds; `R CMD check` reported `Status: OK`. The built source tarball SHA-256 `9b3ef5a63efdc3c0e820a06462f9ea969d17b318f42b6382c8914b848d77b289` matches the freeze. This is current R check evidence, but the canonical G7 runner has not admitted it.
- The canonical package-check command was not run in this handoff. No simulation, fit, bootstrap campaign, or confirmation study was run in this handoff.
- Repository HEAD is Julia `1cb996204e18acbea9e1e7ff9c7a73122d3c34bc`. The isolated R worktree HEAD is `a563ea88f3076819a4a5d8966e2644489efd1688`. Both lanes contain uncommitted work. No commit or push was made.

## 6. Tests of the tests

No checker mutation tests were run during this documentation pass. Earlier checker and oracle work remains recorded in the lane evidence, but it does not close the current G1, G6, or G7 gates until the canonical current-freeze checks pass. The package freeze itself states that hashes bind bytes and do not establish correctness or a new package-check pass.

## 7. Acceptance ledger

| Gate | Current status | What remains |
|---|---|---|
| G0 | Open | Reconcile the executable contract and source-admission metadata, then record current approval and boundaries. |
| G1 | Open | Rerun the exact likelihood, gradient, covariance, ordering, and identity oracles against the current independent freeze. |
| G2 | Open | Complete ordinary K1 numerical reliability evidence against the expanded best-found reference. |
| G3 | Open | Run the frozen K0/K1 confirmation study and meet every per-cell decision rule. |
| G4 | Open | Establish feasibility and calibration for selector-rerun FA heritability intervals. |
| G5 | Open | Meet formation and all-attempt coverage rules for all five repeatability targets and required cells. |
| G6 | Open | Rerun live R controls, parity, interruption, and failure tests against current frozen sources. |
| G7 | Open | Run the canonical package and documentation checker against the reviewed current freeze. |
| G8 | Open | Complete final independent scientific review and plan-to-artifact reconciliation after evidence is available. |

## 8. Public-claim audit

No public documentation or capability row changed. The covered count remains seven. FA remains experimental. The bounded automatic-rank completion must not be described as proof of ordinary selected-K1 reliability or calibrated selection-adjusted intervals.

## 9. Coordination and preserved state

The active Julia branch is `codex/arc1-gaussian-reliability-20261002`. The isolated R branch is `codex/arc1-gaussian-reliability-20261003` under `/private/tmp/hsquared-arc1-r-20261003`. The original Dropbox R checkout remains separate. Protected Julia settings and all in-flight source/test changes were left untouched. No commit or push was made.

The lane preflight also reported a live claim on the Arc 1 lane path, 50 overlapping worktrees, and duplicate design slot identifiers. Resolve ownership and slot duplication through the lane coordination process before changing shared lane artifacts or starting another worker.

## 10. What did not go smoothly

The existing G1, G6, and G7 receipt commands are tied to prior source freezes. A newer independent freeze was completed, so those older receipts cannot establish current-source acceptance. The manual Julia and R package results are encouraging and source-matched in the inspected comparisons, but a canonical runner receipt is still absent. The preflight also rejects a simple ownership assumption because the lane has a live lease and overlapping worktrees.

## 11. Known limitations

Three development allocations were consumed before this handoff: outer 1 failed before data generation, and outers 2 and 3 returned eligible selections after the runtime-identity repair. The retained `development-v1-20261003/README.md` records the seeds and differing source identities. These results must not be pooled across source versions. No pilot or confirmation study has run. No reliability, selection-rate, coverage, or interval-calibration claim is supported by new campaign evidence here. The checkpoint records unresolved profile refusals and unfinished implementation. FA bootstrap feasibility is not demonstrated by a rank-selection frequency or an engineering smoke run. The broader Arc 1 objective is not complete.

## 12. Exact resume actions

1. Read `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`, `LOOP/lanes/arc1-gaussian-reliability-20261002/package-check-plan.md`, and `.unlazy/arc1-gaussian-reliability/GATES.md`. Reconcile the profile contract/source-admission metadata before admitting study inputs.
2. Confirm the live lane owner and resolve the duplicate design-slot issue. Keep one source owner per file.
3. Rerun canonical G1, G6, and G7 using a new receipt pinned to the Astra-reviewed freeze at `/private/tmp/h2-arc1-g7-independent-freeze-20261003T191405Z/package-freeze-v3.json`. The package-check invocation recorded in the lane plan requires `HSQUARED_ARC1_R_ROOT=/private/tmp/hsquared-arc1-r-20261003` and the pinned Julia 1.10 executable on `PATH`.
4. Continue implementation and focused tests, then run qualified development and pilot cells. Do not start confirmation until the frozen pilot screens pass. Estimate every campaign before launch and obtain the required approval for any projection above three hours.
5. Close G2 through G5 only with retained, source-matched campaign bundles and passing canonical gate aggregates. Finish with G8, the after-task audit, capability/debt consistency review, and the package preamble check.

The full current command syntax is in `LOOP/lanes/arc1-gaussian-reliability-20261002/package-check-plan.md`; this report intentionally does not reproduce an unverified command line.

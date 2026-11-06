# G5 container schema hardening slice

## 1. Goal

Close three independently identified current-container gaps with focused writer and reader checks, while leaving the broader G5 gate open.

## 2. Implemented

- Sparse CSC container values now validate the serialized index type as Int32 or Int64 as well as validating their element type.
- Profile-history rows now validate target, fixed-value, status, event-vector, likelihood, and optional event-length field types, with malformed-value adversaries for each category.
- Directory adversaries now exercise duplicate names, reordered names, and overlapping section offsets.
- Nested `producer_history` and `provenance_failures` entries now have explicit field and value contracts. Reconstructed reader rows are revalidated after event references are expanded, closing a reader-path gap that writer-only checks did not cover.
- Writer and reader adversaries reject malformed producer and provenance records with their specific schema errors.

## 3a. Decisions and Rejected Alternatives

- Kept the wire format and scientific protocol unchanged. This slice hardens validation of the existing version-2 container.
- Accepted only Int32 and Int64 sparse indices, matching the supported concrete index representations for this artifact contract.
- Did not claim full field-specific schemas. Metadata, design, profile, result, summary, event payloads, and the complete raw-diagnostic and certificate mutation map remain open.
- Did not read the timed-out legacy artifact or run a fit, seed, or study attempt.

## 4. Files Touched

- `sim/arc1/artifact_container.jl`
- `test/arc1_simulation_executor.jl`
- `docs/dev-log/check-log.d/2026-10-09-g5-container-schema-hardening.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-container-benchmark-v2/bench_container.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-container-benchmark-v2/current-source-smoke-20261009/`
- `docs/dev-log/check-log.d/2026-10-09-g5-container-schema-hardening.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- This report.

The worktree contains other dirty Arc 1 changes. They were preserved and not staged.

## 5. Checks Run

- Focused Julia executor command: `JULIA_DEPOT_PATH=/private/tmp/hsquared-arc1-julia-cache:/Users/z3437171/.julia julia --project=. test/arc1_simulation_executor.jl`. Exit 0. Results: executor 326/326, reference-admission and rank-comparison receipts 15/15, exact UTF-8 diagnostic identity 15/15. The executor took 4m34.4s. A preceding run against pre-fix loaded source failed 2 assertions and 2 fixture cases; its subprocess also hit a read-only Julia cache. The rerun used a disposable cache under `/private/tmp` and passed.
- Current-source benchmark-fixture smoke: 4,000 synthetic events, one Julia thread, no fit; exit 0. Write 0.941 s, read 1.021 s, artifact 1,284,870 bytes. Exact artifact and receipt are retained in `evidence/g5-container-benchmark-v2/current-source-smoke-20261009/`. This small smoke proves only the fixture round-trip and is not scaling or performance evidence.
- The initial fixture run failed because it omitted references and lengths for two empty event vectors. Its failed artifact and receipt are retained beside the passing pair.
- `git diff --check` passed.
- `python3 ~/shinichi-brain/tools/arc_gate_lock.py verify LOOP/lanes/arc1-gaussian-reliability-20261002` passed after the checkpoint update.
- The after-task structure check passed. The full after-task command correctly returned UNMET because three active Arc 1 ledgers still have open gates; this is the expected overall-goal state, not a passed closure check.
- `slop_check.py` reported zero findings.
- Astra independently passed the nested-record rules and post-reconstruction reader validation at the exact current hashes below. The review confirms producer field sets and writer/reader paths. It also identifies remaining limits: the producer `record` contents and `source_id` consistency are not validated, and provenance `value`/`tag` intentionally preserve arbitrary diagnostic inputs.

## 6. Tests of the Tests

The tests require the intended writer or reader error for unsupported empty sparse index types, invalid profile-row targets and value types, malformed nested producer/provenance records, duplicate directory names, unsorted names, and overlapping offsets. The nested reader cases build valid section framing and reject the decoded record at the post-reconstruction schema check. No broad schema-completeness claim follows from these tests.

## 7a. Issue Ledger

- Fixed: sparse-matrix index type was omitted from the supported-type check.
- Fixed: profile-row target and several core value types were not checked.
- Fixed: directory duplicate, reorder, and overlap branches lacked focused adversaries.
- Fixed in this slice: nested producer/provenance records lacked field contracts, and reader validation stopped before checking the reconstructed event entries.
- Fixed: the retained synthetic benchmark fixture now supplies all required profile-row fields, object references, and event lengths for all three event vectors.
- Open: schemas for other nested profile diagnostics, metadata, design, profile, result and summary payloads.
- Open: complete raw-diagnostic and certificate mutation matrix, current-source performance evidence, and source-bound admission prerequisites.

## 8. Consistency Audit

The source and tests agree on the supported sparse index types and the five legal profile targets. Directory tests preserve section payloads and target the intended directory checks. No gate, allocation, seed, denominator, threshold, capability status, or covered count changed.

## 9. What Did Not Go Smoothly

The first focused run exposed stale synthetic producer-history fixtures and showed that reader validation did not recheck values after reference expansion. A later subprocess also could not write into the default read-only Julia cache. The fixtures and reader path were corrected, and the suite passed with a disposable compile cache.

## 10. Known Residuals

The independent reviewer passed this nested-history slice at artifact SHA-256 `a3e5d546f0ede3898236531431d791319bee6bb848244336d4c160edc8f4c6b9` and test SHA-256 `83572254661f026be00cb20ac661201d08b0ae6c4676b0224d43043973854983`. Broader G5 candidate-v2 acceptance remains on HOLD. Current-source verification reopened G1, G6, and G7 because their retained checks refuse the changed inventory; their old receipts remain valid only for the frozen inputs. G0 is met for the recorded plan; G1-G8 are currently open or unmet, and no campaign or statistical validation gate passed in this slice.

## 11. Team Learning

Field presence and a generic recursive type walk do not establish a closed record schema. Each retained record family needs an explicit field contract and adversarial mutations before the artifact can support gate evidence.

Memory receipt: used the retained Arc 1 checkpoint, G5 candidate-v2 contract, current repository source, focused tests, and exact-source reviewer response. No external memory files were read.

Golden Set: not run; this slice changes artifact validation and tests, not a production estimator.

## 12. Cross-Product Coverage

This slice covers Julia container validation only. It does NOT cover R parity, full nested schemas, large-file performance, interval calibration, FA rank-selection confirmation, package release, or GPU execution.

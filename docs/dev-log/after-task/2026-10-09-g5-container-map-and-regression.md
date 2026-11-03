# G5 container-map and regression slice

## 1. Goal

Repair the raw-selector payload collision found in the bounded G5 artifact audit, establish current-source Julia and Python evidence, and produce an independently reviewed partial artifact/container map without claiming G5 acceptance.

## 2. Implemented

- FA rank and interval artifact payloads now keep the raw selector in `raw_selection`; this prevents the later receipt-summary merge from replacing it with compact diagnostics before the raw-result projection check.
- The fake selector fixture now supplies the declared 24 attempted rows required by the receipt contract.
- The Python adversarial test mutation now targets `raw_selection`.
- Regenerated the seed manifest through its canonical writer after tracked-source hashes and seed-context inventory changed. Comparison against the pre-refresh current manifest showed only the generated `historical_seed_audit` field changed; scientific contract, allocation, protocol, and CSV identity were preserved.
- Completed the source map in `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v5.md`. Astra passed that exact file at SHA-256 `7272f73738207968823b8aeadfaf6a2cc8b35e0ff6289f4a1070ef20de52272a`, for partial artifact/container scope only.

## 3a. Decisions and Rejected Alternatives

- Kept raw selector state under a distinct `raw_selection` key because `selection` is the compact field used in the flattened receipt summary. Reusing the same key allows a valid merge to silently replace the object required for independent projection.
- Refreshed only generated audit metadata through `write_manifest`; did not rewrite allocations, seeds, protocol claims, or thresholds.
- Did not retry the 130,851,693-byte legacy JLS artifact on Totoro or increase its timeout. The retained checkpoint requires a fresh bounded inspection proposal and independent review first.

## 4. Files Touched

- `sim/arc1/execute_attempt.jl`
- `test/arc1_simulation_executor.jl`
- `test/test_arc1_receipt_adversaries.py`
- `sim/arc1/manifests/arc1_seed_manifest.json`
- `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v4.md` (superseded draft bytes were edited during map correction)
- `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v5.md`
- `docs/dev-log/after-task/2026-10-09-g5-container-map-and-regression.md`
- `docs/dev-log/check-log.d/2026-10-09-g5-container-map-and-regression.md`
- `docs/dev-log/coordination-board.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`

The worktree already contained other dirty Arc 1 files. They were not reverted or staged.

## 5. Checks Run

- Current-source Julia executor suite: `JULIA_DEPOT_PATH=/private/tmp/arc1-container-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no -e 'using Test, HSquared; include("test/arc1_simulation_executor.jl")'`. Exit 0; 194/194 executor checks, 10/10 admission checks, 15/15 exact-representation checks. Log `/private/tmp/arc1-container-julia-current-source-rerun.log`, SHA-256 `a8edd5e20650970f8adfa8e047e5b90e9cf6cdacf14feb4e70cd425f7d76fd3d`.
- Current-source Python adversarial suite: `python3.13 -m unittest discover -s test -p 'test_arc1_receipt_adversaries.py'`. Exit 0; 55 tests in 705.682 seconds. Log `/private/tmp/arc1-receipt-adversaries-current-source.log`, SHA-256 `8df45004b30b304066aabb0c7ada696be345ae6c49bdc20abad0847c352d2a31`.
- Isolated historical-seed-audit regression: after the canonical manifest refresh, `test_profile_search_contract_admits_v4_without_changing_legacy_meanings` passed 1/1, exit 0. Log `/private/tmp/arc1-historical-seed-audit-regression.log`.
- `git diff --check` passed for the source, test, and manifest files in this slice.
- `slop_check.py` on the v5 map: zero findings; 9 style hits were below threshold.
- The exact v5 map passed Astra's read-only review at the SHA above. The review grants no G5 gate credit.
- After-task R structure check passed. The acceptance-ledger stage correctly returned UNMET because G2-G5/G8 remain open in three active ledgers; I did not mark these goals abandoned. `evidence_gate.py` passed for 8 registered claims. `git diff --check` passed for the full worktree.
- After the coordination/checkpoint updates, the canonical manifest writer and `verify_manifest` both passed. Final manifest SHA-256: `55c099e7bbf4be1dacfe0c69cf61e7c278b54a475ed8cfc2caddb787386c0d3a`. The isolated historical-audit regression passed again 1/1; log `/private/tmp/arc1-historical-seed-audit-closeout.log`, SHA-256 `961e7ae1e17ac71eb38cc7e1ba23540a21924e60254e778ea1e94b2ac3319434`.

## 6. Tests of the Tests

The earlier raw-projection integration attempt failed with `NamedTuple has no field candidate_summary` after the receipt merge replaced the raw selector. The repaired canonical 55-test suite now passes on the corrected source, including the cross-language durable-store/checker path. The 24-row fake schedule also keeps fixture evidence consistent with the production receipt contract. Per-predicate Python mutation coverage beyond named map rows is not claimed.

An earlier full Python run stopped with one stale historical-source-audit mismatch. Regenerating the canonical audit metadata made the isolated failing test pass, and the subsequent full suite passed.

## 7a. Issue Ledger

- **Fixed:** compact FA receipt summary overwrote the raw selector in artifact payloads. The payload now stores `raw_selection`, and the projection checker reads that field.
- **Fixed:** synthetic selector fixture reported 24 attempted starts while retaining only one row.
- **Fixed:** generated seed-manifest audit metadata lagged tracked source and documentation changes.
- **Deferred:** the large legacy JLS artifact cannot be inspected within the prior 900-second read-only attempt. No retry or G5 acceptance was attempted.
- **Open:** G5 admission/process-boundary and confirmation-authorization prerequisites, a reviewed bounded artifact-inspection method, and the measured end-to-end performance path.

## 8. Consistency Audit

Checked the Julia raw payload writer, raw-result projection helper, fake-engine schedule fixture, Python mutation path, and generated seed-manifest verifier. The corrected map distinguishes the successful current-source suite from per-predicate coverage and excludes admission, process-boundary, and confirmation authorization checks. Capability remains experimental; covered count remains seven; the R checkout, gates, allocations, and denominators were not changed.

## 9. What Did Not Go Smoothly

The first current-source Julia invocation completed its tests but its zsh wrapper used the reserved variable `status`, so its process result was rerun with a valid exit-code variable. The initial Python suite exposed stale generated audit metadata, and the focused rerun was first invoked with the wrong module path before passing from the `test` directory. The closeout template helper is anchored to the primary brain repository and attempted to write outside this worktree. I created the report in the authorized worktree; its structural R check and evidence gate pass, while the acceptance-ledger stage correctly reports the larger Arc 1 goal is still open.

## 10. Known Residuals

- This is a partial G5 source/receipt map, not G5 validation or study admission.
- The old 130,851,693-byte artifact still lacks semantic inspection evidence; performance is unmeasured.
- If this currently untracked after-task report becomes a tracked input, regenerate the manifest's historical audit afterward and rerun the isolated verifier test.
- The map does not establish exhaustive per-row adversarial coverage.
- G2's fresh-development tranche still awaits separate user approval. G2-G5 and G8 remain open; G0, G1, G6, and G7 remain met only for their recorded scopes.
- No package-wide `Pkg.test`, R package check, pilot, confirmation, or release action was run in this slice.

## 11. Team Learning

Keep raw model state and compact receipt projections under distinct names when merging artifact payloads. A successful projection audit must retain the raw inputs used to derive the receipt. Generated historical-source audits must be refreshed after tracked documentation or source edits before their verifier is used as a current-source test.

Memory receipt: repo checkpoint and coordination board were consulted; no matching route `LOAD-FIRST` manifest was available in the prior rehydration. The checkpoint's G5 artifact timeout and G2 approval boundary shaped this work. Golden Set: not in scope for this payload/receipt regression.

## 12. Cross-Product Coverage

Covers: Julia Arc 1 artifact payload, Julia raw-result projection, the Python receipt adversary suite, and their current-source integration path.

Does NOT cover: the R public interface, full G5 admission/confirmation, legacy-artifact semantic inspection, campaign calibration, G2/G3 selection evidence, full package checks, public capability promotion, or GPU execution.

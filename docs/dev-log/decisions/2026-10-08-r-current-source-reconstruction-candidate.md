# Candidate: reconstruct the Arc 1 R source and restore named bootstrap-v2 evidence

**Status: proposal for independent review. No package changes are authorized by this note alone.**

## Problem

The Git-backed R parser candidate is based on `a563ea88f3076819a4a5d8966e2644489efd1688`. The retained October 7 G6 source freeze contains 100 R-file hashes. The candidate matches 88 files exactly, differs in nine files, and lacks three required tests. The retained scratch copy contains later Arc 1 source but has no Git metadata. The original `test-arc1-bootstrap-v2-live.R` bytes are not present in either inspected Git object database or the retained evidence archives. Its historical SHA-256 is `d787d406d9227e3aea63f84fc6095551da56c64abdd42783485616e4581d19fb`; the retained testthat receipt records 20 assertions passed. Historical evidence proves this dedicated test ran alongside the embedded v2 block in `test-arc1-uncertainty-live.R`, so the embedded block does not establish that the missing file is redundant.

## Proposed reconstruction

Use the existing disposable candidate `/private/tmp/hsquared-arc1-r-active-20261008` as the Git-backed base. Preserve its commit and the 88 files already matching the historical freeze. The retained overlay is 11 files: `NAMESPACE`; `R/arc1-uncertainty.R`, `R/extractors.R`, `R/fa-rank-selection.R`, and `R/julia-bridge.R`; shared tests `test-arc1-controls.R`, `test-arc1-live-parity.R`, `test-arc1-uncertainty-controls.R`, and `test-arc1-uncertainty-live.R`; and recoverable tests `test-arc1-profile-v4-live.R` and `test-arc1-profile-v4-transport-isolation.R`. Use the October 7 historical oracle freeze as authority for every listed path except `R/julia-bridge.R`; use the October 7 transport source lock as authority for that later bridge file. The required `test-arc1-bootstrap-v2-live.R` is the twelfth changed/added path: its original bytes are unavailable, so author a new test at that path, with a new hash and no claim of historical recovery. This is a reviewed reconstruction, not restoration of one exact historical tree: report historical-freeze, reconstructed-baseline, and final parser-patched hashes separately. The retained scratch hashes include `R/arc1-uncertainty.R` `bf82a23218f1f345f01815977d63815ac722df2fdae47e671c7d40741f20cb91`, `R/extractors.R` `aafe7696b96ea1956f97bf6c35d8116ff2190fd566faa664e905972baf729669`, `R/fa-rank-selection.R` `520d12f3d7c1fe008ec856398c72f7466faad97007f1e575b779e1ee2914e8d9`, `R/julia-bridge.R` `409147b4f9b54f04b09121ccbdd775a4b8d54030ee6b465cc3a165caf52848a0`, and `NAMESPACE` `aea3dc4957c45aff5edf88b85258bc009eff571d09044e2b39e6b0311ef4114e`. The profile-v4 test hashes are `be6bb51da63a59eec405d0ec3c8bf0f189f4b95a38dd23f65f9694c762a08874` and `f9f65cf70c416ded06613f4e04d43c3de9316add3df8087c75088c664edb3716`. Keep the old scratch path read-only. Preserve the candidate's parser regression tests separately while restoring the later Arc 1 sources.

Do not claim that the original bootstrap-v2 test was recovered. Author a new test at the required `tests/testthat/test-arc1-bootstrap-v2-live.R` path, with new source hashes and independent review. Keep the seven-file canonical runner selection. The new live test must make the v2 case explicit and check:

1. An outer automatic four-trait FA fit under `arc1_v2` requests `arc1_bootstrap_v2` with a fixed single smoke replicate and seed.
2. The successful bootstrap attempt contains complete `selector_attempts` and `candidate_summary` values, policy/version, explicit successful attempt status, source identity, and exact requested/usable/failure accounting. It must report all 19 planned v2 starts. `selector_ledger` is interruption/exception evidence and is not required to be nonempty after success.
3. Capture the exact generated response by calling internal `_arc1_bootstrap` with a test wrapper that copies the generated response, counts invocations, and delegates unchanged to the real selector. Preserve the outer selection, seed, designs, pedigree, and trait order. Verify exactly one selector invocation, requested v2 policy, and the complete 19-start selector result. Replay the captured response directly with the v2 selector and compare deterministic rank, candidate summaries, and attempt summaries. Compare the resulting bootstrap summaries against the public R call. Include response/design identity and inner attempt values, not rank alone; do not require the bootstrap rank to differ from the outer rank. This distinguishes actual reselection from merely copying the outer selector result.
4. R and direct Julia agree on method identity, seed accounting, attempt status, rank-frequency role (`diagnostic_only`), and interval rows after normalizing their data-frame versus named-tuple forms and non-finite bound representation; the mismatched v1 extractor request fails closed.
5. Required-live mode errors if JuliaCall, Julia, or the configured engine is missing. The test must not turn a missing live prerequisite into a skip.

The one-replicate test is bridge and reselection evidence only. It provides no interval calibration credit. Keep the original test-attempt and denominator rules unchanged.

## Parser repair integration

After restoring the later Arc 1 sources, port the reviewed parser repair to that exact `R/fa-rank-selection.R` rather than replacing the whole file with the stale candidate version. Preserve v2 strictness, v1/default absent-metadata handling, validation of every present scalar column before iteration (including zero-row payloads), and fixed-fit strictness. Carry forward the reviewed regressions for unknown policies, malformed/present metadata, zero-row mismatches, and row-list/data-frame shapes. Retain the prior review as component evidence only; obtain new exact-source review after the port.

## Review and execution sequence

1. Astra reviews this proposal and the historical hashes. A hold leaves the parser candidate component-only.
2. If passed, reconstruct the exact source overlay in the disposable candidate and write a source-recovery receipt with the 100 expected-file hashes and current inventory.
3. Add the new named bootstrap-v2 live test and parser regressions using test-first edits. Run bounded offline checks only.
4. Obtain exact-source review of all Julia and R inputs before any live fit. Estimate the canonical G1/G6 runtimes from the retained 419-second G1 and 2,287-second G6 results; stop and re-report if a measured estimate exceeds three hours.
5. Generate a new external paired freeze only after every hash matches the reconstructed source and exact test inventory. Then run the canonical G1/G6 runners and retain their complete receipts. Re-run G7 under its own exact source freeze after source and documentation reconciliation.

No seed, denominator, acceptance threshold, estimator rule, public default, capability status, or release state changes. The dirty Dropbox R checkout and all protected settings remain untouched. G2-G5 and G8 remain open.

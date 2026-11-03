## 1. Goal
Diagnose why the read-only G5 semantic inspection of the retained v10 N80 interior artifact exceeded its 921.599-second bound, then make a narrow fix for the receipt defect it exposed.

## 2. Implemented
Measured the framed history reader and inspector components against the exact retained Totoro source and artifact. A 50,000-record deserialization sample took 2.253 seconds; the full production container read took 40.518 seconds. The restored profile contained 378,778 events in 192 evaluation rows and one v4 certificate. Receipt projection emitted 758,960,117 bytes and took 33.285 seconds for one side; full raw-versus-retained projection took 83.440 seconds and reported a mismatch. Per-field comparison isolated that mismatch to `target_diagnostics_identity`; all other receipt fields matched. The identity hashed `repr(Dict)`, which is not stable across Julia processes.

Changed `_arc1_sha256_repr` to hash the sorted-key Arc1 JSON projection and added insertion-order regression coverage. The raw-versus-retained profile check now avoids serializing the evidence sink twice when the artifact preserves the exact shared evidence reference. The v4 design context took 3.874 seconds; its one certificate validated in 0.258 seconds. These timings rule out history decoding, data identity, and v4 certificate recomputation as the earlier long pole. The inspector now returns a compact, evidence-preserving summary by default and exposes full evidence only on the explicit checker path that requires it. A generated fake-engine artifact passed the current builder and canonical inspector after the native artifact-section allowlist was updated to admit `v3_profile_evidence_summary`.

## 3a. Decisions and Rejected Alternatives
Kept the retained artifact, frozen v10 source, and run receipts unchanged. The old artifact retains the unstable identity and remains semantically unqualified; the code fix applies to new outputs only. No seed, fit, bootstrap, pilot, confirmation, or gate credit was added. Did not increase the semantic-inspector timeout or treat partial checks as success.

## 4. Files Touched
Changed `sim/arc1/execute_attempt.jl`, `sim/arc1/inspect_artifacts.jl`, `sim/arc1/artifact_container.jl`, `sim/arc1/runner.py`, `tools/arc1_receipt_check.py`, and focused Julia/Python tests. Updated this report, the check log, GATES.md, and the Arc1 checkpoint. No R package source, protected settings, seed manifest, or retained Totoro artifact was modified.

## 5. Checks Run
- Lane preflight for `sim/arc1/execute_attempt.jl` passed and reported one Codex lane.
- Focused receipt-identity testset passed 20/20 in 1.5 seconds; raw-repeatability projection passed 4/4 in 0.9 seconds. A native artifact round-trip for the compact evidence summary also passed.
- Three Python adversary tests passed in 8.894 seconds, covering the bounded inspector subprocess, compact/full v4 evidence validation, and profile admission identity. Python compilation passed for the receipt checker, runner, and adversary tests.
- A generated fake-engine repeatability artifact passed current-source construction and canonical inspection. The artifact was 23,850 bytes; the inspector retained the compact evidence summary and omitted full evidence in the default mode. This used a temporary copy of the fixture builder with its test-source hash pin updated to the current test file. It is synthetic engineering evidence only.
- Exact-source Totoro read-only probes measured 50,000 history records in 2.253 seconds, the full framed read in 40.518 seconds, data identity in 1.979 seconds, one receipt projection in 33.285 seconds, full receipt comparison in 83.440 seconds, v4 context in 3.874 seconds, and one certificate in 0.258 seconds.
- The read-only receipt comparison found `target_diagnostics_identity` as the sole differing field. Target identity from raw profile: `f2208a44712ae6d860dc35932d395f180b051c5482d0f67c46cd9bd1340ad44c`; retained identity: `2f581b2c494751c575a584076cb0788f30d743872d1bd62f5a72f71088037d17`. Point-fit identity matched.
- The fixed source has not received the full package suite or a new G7 source freeze. The last G7 v29 pass remains valid for its exact older freeze only.

## 6. Tests of the Tests
The identity test checks sorted-key stability across opposite dictionary insertion orders. The projection test refuses missing and altered evidence. The artifact regression round-trips the compact summary through the native container, and the synthetic inspector fixture exercises the complete fake-engine receipt path. These checks validate the targeted transport contract, not interval calibration or the full package.

## 7a. Issue Ledger
- G5 remains open. The v10 artifact has a receipt identity mismatch and is not gate evidence. Default inspection now emits compact evidence metadata; full evidence remains available only through an explicit opt-in path. The successful fixture is synthetic and does not qualify real-artifact replay or any calibration cell.
- G7 is reopened for the current source because `sim/arc1/execute_attempt.jl` and its test changed after freeze v29. The v29 run remains historical evidence for that exact source.
- G2, G3, G4, and G8 remain open. The v17 outer33 seed remains one successful, rate-eligible development observation with no gate credit. No pilot or confirmation ran.

## 8. Consistency Audit
Matched the remote v10 source hashes to the pre-edit local sources: `execute_attempt.jl` `f12a0805ef49ab795f4b04d22dbae9e24015d03866565ef3d4dce29fc1072016` and `inspect_artifacts.jl` `d14a5eca4f39e833409031cab6c76f6227678010205357ec19475648c9e99e9e`. The retained artifact SHA-256 is `bc0543067933e6469f4752d96fd8c586bb6cd33f82f6d0ab434aa2efae9e1b6a`, size 408,658,856 bytes. No remote process or artifact write was left behind.

## 9. What Did Not Go Smoothly
The first current-source fixture exposed a missing native artifact-section allowlist entry for `v3_profile_evidence_summary`; the fake attempt correctly failed closed before inspection. Adding the summary field to the allowlist and adding a container round-trip regression made both fixture construction and canonical inspection pass. The retained v10 receipt still fails its raw projection comparison because its stored identity was created with process-dependent dictionary ordering.

## 10. Known Residuals
The real v10 artifact has not been replayed with the updated source. The canonical identity fix, compact inspector response, and artifact-section change still need an exact-source review and complete current-source G7 run. G5 pilot and coverage criteria remain unmet.

## 11. Team Learning
A successful binary container read does not establish that downstream semantic inspection is bounded. Measure each stage and the serialized response separately. Diagnostic fingerprints over dictionaries must use a stable key ordering. Memory receipt: used the repo's G5 lane checkpoint and source graph to preserve the existing single-artifact boundary. Golden Set: not run; the regression tests directly target cross-process diagnostic identity and shared evidence projection.

## 12. Cross-Product Coverage
This task changes the internal Arc1 Julia simulation receipt and inspector path only. It does NOT cover public R grammar, fitted scientific behavior, R/Julia user-visible parity, interval calibration, selection rates, or capability status. Capability remains experimental and covered count remains seven.

## Follow-up: certificate-shape fail-open repair

The independent source review found that missing or non-vector `v4_tail_certificates` could be compacted to an empty list and accepted as “no certificate.” The summary now preserves an explicit `vector`/`missing`/`malformed` shape marker and omits malformed values rather than replacing them with an empty collection. Native inspection marks a missing or malformed collection invalid, and compact receipt validation requires the marker to say `vector`. Added Julia summary tests for missing and malformed collections and Python adversarial tests for missing/malformed compact and native evidence.

The focused Julia testset passed 25/25 assertions in 1.9 seconds. The two targeted Python adversary tests passed. `py_compile` and `git diff --check` passed. An initial full-file attempt was interrupted while its subprocess-heavy testset remained active. The next run exposed three stale assertions that expected full raw event fields in compact stdout and one Julia shared-cache permission error in a nested test process. The assertions now require the compact history summary and the nested process uses the lane-local depot. The corrected full executor file then passed 541/541 assertions, reference-admission tests 19/19, diagnostic identity tests 25/25, and framing tests 7/7, in 20m50.8s total. Its native inspector cases rewrite a valid artifact to remove or malform the certificate collection and assert `invalid` status, failed design correspondence, false evidence-valid flag, and false combined identity. The two Python adversary tests also passed. The earlier synthetic artifact check proves the valid compact path; the new adversarial inspector cases prove the missing/malformed path. Current exact-source review and G7 remain pending. No fit, seed, bootstrap, study attempt, or gate credit was added. The already completed outer33 seed `11447647806120141284` remains one rate-eligible development observation and was not repeated.

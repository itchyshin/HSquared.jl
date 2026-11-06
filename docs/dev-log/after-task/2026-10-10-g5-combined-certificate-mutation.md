# Arc 1 G5 combined V4 certificate mutation

## 1. Goal

Test whether the native artifact inspector rejects a certificate whose finite, correctly typed values disagree with the recomputed tail certificate, after structural and design checks succeed.

## 2. Implemented

Added a combined `E` and point-log-likelihood mutation to the fake-engine certificate tests. The test asserts the inspector reports matched design correspondence and still marks certificate evidence invalid. Map v23 binds the updated test, source ranges, and passing run. Continued the same bounded G5 checker audit by testing rejection of a non-mapping native evidence section and tuple- or mapping-valued certificate collections; the focused checker test passed 1/1 and map v24 records it.
Added formed-repeatability receipt mutations for malformed point, source, point-fit-diagnostic, and target-diagnostic identities. The focused test passed 1/1; map v25 records the new test range and evidence hashes.

## 3a. Decisions and Rejected Alternatives

Changed two finite, correctly typed fields so the case reaches exact recomputation rather than a scalar type/range rejection. Kept the values non-boundary and left design identity unchanged. Assumption: this fake-engine fixture represents the native retained-artifact path; the `design_correspondence=matched` assertion verifies the intended branch.

## 4. Files Touched

- `test/arc1_simulation_executor.jl`
- `docs/dev-log/check-log.d/2026-10-09-g5-combined-certificate-executor.log`
- `docs/dev-log/check-log.d/2026-10-09-g5-combined-certificate-executor.status.txt`
- `docs/dev-log/check-log.d/2026-10-09-g5-combined-certificate-executor-rerun.log`
- `docs/dev-log/check-log.d/2026-10-09-g5-combined-certificate-executor-rerun.status.txt`
- `docs/dev-log/check-log.d/2026-10-10-g5-combined-certificate-executor-final.log`
- `docs/dev-log/check-log.d/2026-10-10-g5-combined-certificate-executor-final.status.txt`
- `docs/dev-log/source-review/2026-10-10-g5-authoritative-container-field-check-map-v23.md`
- `docs/dev-log/source-review/2026-10-10-g5-authoritative-container-field-check-map-v24.md`
- `docs/dev-log/check-log.d/2026-10-10-g5-native-certificate-container-shapes.log`
- `docs/dev-log/check-log.d/2026-10-10-g5-native-certificate-container-shapes.status.txt`
- `docs/dev-log/check-log.d/2026-10-10-g5-profile-diagnostic-identity-boundaries.log`
- `docs/dev-log/check-log.d/2026-10-10-g5-profile-diagnostic-identity-boundaries.status.txt`
- `docs/dev-log/source-review/2026-10-10-g5-authoritative-container-field-check-map-v25.md`
- `docs/dev-log/source-review/2026-10-10-g5-authoritative-container-field-check-map-v26.md`
- `docs/dev-log/check-log.d/2026-10-10-g5-python-adversary-full-current.log`
- `docs/dev-log/check-log.d/2026-10-10-g5-python-adversary-full-current.status.txt`
- `docs/dev-log/check-log.d/2026-10-10-g5-live-inspector-fixture.log`
- `docs/dev-log/check-log.d/2026-10-10-g5-live-inspector-fixture.status.txt`
- `docs/dev-log/check-log.d/2026-10-10-g5-python-adversary-full-pass.log`
- `docs/dev-log/check-log.d/2026-10-10-g5-python-adversary-full-pass.status.txt`
- `tools/arc1_manifest.py`
- `sim/arc1/manifests/arc1_seed_manifest.json`
- `docs/dev-log/after-task/2026-10-10-g5-combined-certificate-mutation.md`

## 5. Checks Run

- Final focused Julia command: `julia --startup-file=no --check-bounds=yes --threads=4 --project=. -e 'include("test/arc1_simulation_executor.jl")'`, with `JULIA_NUM_THREADS=4`, `OPENBLAS_NUM_THREADS=1`, and the writable Arc 1 depot first. Exit 0; executor 516/516 in 18m50.7s, reference admission 19/19, UTF-8 identity 15/15, framing 7/7.
- Test source SHA-256: `80071cf17c4ecad0bc43f6c03c40429195514ad02f0b1d67c348b9cb8358d908`.
- Passing log SHA-256: `b21afd73723789bdf24b8f1e4b2d731314db1816acddf39f25dce3152214dd3a`; exit-status record SHA-256: `19eaf43821a7660ec323a87c8457bf74823beb296c39f5e01aa8a683aa50f061`.
- The first attempt was interrupted after 412 assertions when it exceeded the initial 18-minute estimate. That log and exit 1 are retained; it is not a pass. The clean rerun passed. A read-only process check found no orphan inspector process after interruption.
- Map v23 SHA-256 `bad166088a481dd35c6700ab44eb49ee46c14e1013901f1600463c993989b82a` passed independent exact-source review. The reviewer confirmed the seven pins, corrected ranges, all retained log/status hashes, and the 516/516, 19/19, 15/15, and 7/7 pass counts. The review is limited to the evidence map and does not close G5.
- Focused Python 3.13 checker test `Arc1ReceiptAdversaries.test_v4_native_certificate_validation_checks_absence_and_interrupted_unavailability` passed 1/1 after adding non-mapping evidence-section, tuple-valued certificate, and mapping-valued certificate rejection cases. Log SHA-256 `fb184ea57734512b1f088f9181209901b9cd46df3eb7eaa2500ea9e48dde20b5`; exit-status SHA-256 `19eaf43821a7660ec323a87c8457bf74823beb296c39f5e01aa8a683aa50f061`; test source SHA-256 `2c184703edea2901b972b04054685474a593e92d0daef766b70025ddca586402`.
- Initial map v24 reviews found stale source spans after the added cases; all seven source pins and the retained test log/status matched. Corrected the artifact-inspector row to 1817-1862, the native-certificate row to 1684-1815, and restored the precise V4 JSON evidence span to 1684-1746. Current map v24 SHA-256 `fad41fd4eed6cb2a902e7e14647a79362e9c3942ac5a9a8833d5c3152b789155` passed bounded independent exact-source review; the reviewer confirmed all corrected ranges, all seven pins, and no stale spans in the reviewed rows. The review confirms the map, not G5.
- Focused Python 3.13 formed-interval receipt test `Arc1ReceiptAdversaries.test_profile_point_guard_binds_all_five_formed_targets` passed 1/1 with malformed shared point, source, point-fit-diagnostic, and target-diagnostic identity cases. Test source SHA-256 `33212c8dbfa3aba75c32805cb2ff9ec080934ec295fb4034c389cd3949193afe`; log SHA-256 `2299339565fdc7c4fedeb54e99b181ba53b821f77194926422cc7df3301ba0ee`; exit-status SHA-256 `19eaf43821a7660ec323a87c8457bf74823beb296c39f5e01aa8a683aa50f061`.
- Map v25 SHA-256 `f8e21e3323ef03835f0a8e8fc5d95a86a387d1e19840db65d25e038c9da0f2bf` passed bounded independent exact-source review. The reviewer confirmed all seven source pins, the four malformed-identity rejection cases, retained test evidence, and corrected downstream Python ranges, with no stale citations in the reviewed rows. This review proves the evidence map only, not G5.
- The first full Python adversary run was interrupted by the operator at the estimated 40-minute boundary while test `test_fresh_julia_json_to_durable_store_to_checker_fixture` was running. It had emitted 23 pass dots and no assertion failure. Retained partial log SHA-256 `8c9e01660980c05471366d6c3917db7d97d1e49bdadb5f7927026afe362e4127`; exit record SHA-256 `c6cc749cc0e5ea997f4a67f173a3ece0b3a173d80668143727fb055f0d64c62b` records operator interruption. This is not a suite pass. The traceback alone did not establish a subprocess cleanup defect, and no checker source change was made.
- The isolated `Arc1ReceiptAdversaries.test_fresh_julia_json_to_durable_store_to_checker_fixture` then passed 1/1 in 2349.242 seconds. It generated and re-inspected retained repeatability and FA-interval artifacts, including live Julia inspector invocations. Test source SHA-256 `33212c8dbfa3aba75c32805cb2ff9ec080934ec295fb4034c389cd3949193afe`; passing log SHA-256 `66f760d33dcea9d34194e8edf9cc89f66437d4eee28eef9ffb60b84658a7bd5b`; exit-status SHA-256 `19eaf43821a7660ec323a87c8457bf74823beb296c39f5e01aa8a683aa50f061`.
- The next full adversary suite completed 58 tests in 2397.058 seconds with 57 passing and one error in the historical seed-audit verification. Its test source was current; the generated manifest audit still held the prior source hashes. Failed-run log SHA-256 `ecc92d851710ed778e100d08fb7281eddb0624f3cb41e83cb0dca32f3c2f0e10`; exit-status SHA-256 `cf205dbb8cea84897f4a67f173a3ece0b3a173d80668143727fb055f0d64c62a`.
- Refreshed the generated manifest audit with `python3 tools/arc1_manifest.py`. The outer-seed CSV remained byte-identical at SHA-256 `498fcac802f01fedf4b8fb4fc90ba7a61d5b05259c44907d000a6e585587fe07`; `--validate-only` passed with 1,001 scanned paths, 394 literals, 10,330 outer rows, 634,420 nested rows, and 644,750 unique keys/seeds. The previously failing focused contract test then passed 1/1 in 2.744 seconds.
- The full current Python adversary suite passed 58/58 in 2427.207 seconds after the metadata refresh. Log SHA-256 `b79952b71b0577a31285e1ba48f54cfb29d463dc54e0064c54298a9556f8468c`; exit-status SHA-256 `19eaf43821a7660ec323a87c8457bf74823beb296c39f5e01aa8a683aa50f061`. Test source SHA-256 `33212c8dbfa3aba75c32805cb2ff9ec080934ec295fb4034c389cd3949193afe`; manifest generator SHA-256 `ad42f93728c12d3df17fd2be307561ec08b320d550271bdc6f456e408e99f64f`; seed manifest SHA-256 `0d31d87ec7fbaba56c315d76b59eb28cc4d0dd499ad0bdaa11704947c1a917a5`. Independent exact-source review passed map v26; review record: `docs/dev-log/source-review/2026-10-10-g5-map-v26-review.md`.
- The current scientific-gate checker tests passed 22/22 in 33.722 seconds. The run covers required-cell completeness, all-attempt rank counts, interval formation denominators, Wilson coverage bounds, repeatability pilot/confirmation markers, and exact-zero diagnostics without nominal coverage claims. Log SHA-256 `99c569e862df31d2748c80af9e8ffa580cce5a4d24d8bb4fb42d10a0dc241d2e`; exit-status SHA-256 `19eaf43821a7660ec323a87c8457bf74823beb296c39f5e01aa8a683aa50f061`.

## 6. Tests of the Tests

The combined case asserts both `v4_tail_certificate_design_correspondence=matched` and `v4_tail_certificate_evidence_valid=false`. This shows the checker passed structural and design correspondence and then refused the changed finite certificate at recomputation.

## 7a. Issue Ledger

- Closed for this test slice: no combined finite-value mismatch case proved the recomputation rejection path.
- Still open: other combined mutations, raw diagnostics, live subprocess boundary behavior, large-artifact performance, and interval calibration.

## 8. Consistency Audit

The receipt-checker source did not change. The fake-engine test writes a retained artifact and invokes the canonical inspector. The added fields retain their required Float64 and finite-value forms; design fields remain untouched. G5 and all Arc 1 gates remain open.

## 9. What Did Not Go Smoothly

The first test attempt exceeded its initial time estimate and was stopped. After the partial result was recorded, the complete run took about 20 minutes wall time and passed. No test failure was hidden or replaced.

## 10. Known Residuals

This closes only bounded G5 test-evidence and independent-map-review items. The isolated fixture proves one current-source live inspector path, while direct boundary cases mock subprocess launch; the synthetic size probes do not establish fitted optimizer-trace performance. None of these checks establishes scientific interval formation or coverage. G0, G1, G6 and G7 are met at their recorded scopes; G2-G5 and G8 remain open. Capability remains experimental; covered count remains seven.

## 11. Team Learning

Memory receipt: used the supplied HSquared.jl operating contract, the retained G5 checkpoint, and maps v23-v25. The brain routing manifest was unavailable for this worktree; repo documents were used as technical truth. Golden Set: not run because these tests change no model or public behavior.

## 12. Cross-Product Coverage

Covers: Julia fake-engine and native artifact-inspector certificate recomputation rejection.

does NOT cover: R controls or parity, statistical interval calibration, study evidence, public grammar, capability promotion, or release status.

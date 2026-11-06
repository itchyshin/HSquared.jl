# G5 producer identity and current-source mapping

## 1. Goal

Harden the G5 container's nested producer-record identity checks, expand native V4 certificate mutations, and bind the bounded results to exact current source, test, and log evidence. This slice does not close G5 or Arc 1.

## 2. Implemented

- Profile-row validation now binds producer owner, candidate ID, path, and positive visit index to the exact five-field producer source identity tuple.
- Writer and reconstructed-reader tests exercise malformed source IDs, identity disagreement, invalid ownership, empty paths, and invalid candidate and visit-index values.
- Added standalone container-framing adversaries for malformed magic, zero section count, schema mismatch, oversized record count, offset gap, and trailing history-section bytes.
- Expanded native V4 certificate inspection mutations from four to twenty-five cases covering required fields, types, boundary values, design identity, and rounding contracts.
- The current field-to-test map pins the exact source and test hashes, identifies remaining G5 validation gaps, and records the integrated test result.

## 3a. Decisions and Rejected Alternatives

- Kept this slice to the existing container contract and added adversaries for each producer identity predicate. No wire-format change was made.
- Kept the traversal visit index separate from the event index because the traversal counter resets and counts vector visits.
- Assumption: this request means resume the current Arc 1 lane from its retained checkpoint. If that interpretation is wrong, the work remains a reviewable G5-only slice and no scientific gate has advanced.
- Did not read the timed-out legacy artifact or start the separately approval-gated G2 development tranche.

## 4. Files Touched

- `sim/arc1/artifact_container.jl`
- `test/arc1_simulation_executor.jl`
- `test/arc1_container_framing.jl`
- `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v6.md`
- `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v7.md`
- `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v8.md`
- `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v9.md`
- `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-field-check-map-v10.md`
- `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-map-review.md`
- `docs/dev-log/check-log.d/2026-10-09-g5-container-framing-integrated.log`
- `docs/dev-log/check-log.d/2026-10-09-g5-v4-certificate-mutations.log`
- `docs/dev-log/check-log.d/2026-10-09-g5-v4-certificate-boundaries.log`
- `docs/dev-log/check-log.d/2026-10-09-g5-raw-projection.log`
- `docs/dev-log/check-log.d/2026-10-09-g5-raw-projection-fixed.log`
- Earlier producer identity logs and two failed framing-harness attempts remain retained beside the integrated passing log.
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- This report

Other dirty Arc 1 files and the protected coordination board/check log were preserved.

## 5. Checks Run

- Focused Julia executor command: `JULIA_DEPOT_PATH=/private/tmp/hsquared-arc1-julia-cache:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no -e 'using Test, HSquared; include("test/arc1_simulation_executor.jl")'`. Exit 0. Executor 434/434 in 8m45.1s; admission/rank-receipt checks 15/15; UTF-8 identity checks 15/15; framing checks 7/7. The V4 certificate matrix includes 20 invalid mutations. Log SHA-256: `47a87c74b3e69f490811bb1bf31965b067a4fb79e5bcf4597951dd0a8f6f0d25`.
- After the five focused boundary cases, the same command passed executor 444/444 in 10m01.9s; adjacent suites 15/15 and 15/15; framing 7/7. The V4 certificate matrix now includes 25 invalid mutations. Log SHA-256: `7cd4017ebc98eab0dcb66dfe562367422017d6402e47deb37418cda22780844f`.
- Raw repeatability projection now passes one valid round-trip and three expected rejection cases. The first run had 446 passes and one fixture error because a Dict was merged with a NamedTuple; that failed log is retained. After using a Dict merge, the focused suite passed executor 447/447 in 9m59.8s; adjacent suites 15/15 and 15/15; framing 7/7. Passing log SHA-256: `8a8dbe81ad584a7cfa8ca04603089869826f4d259de16726d446b926ab99701a`.
- Standalone framing tests also passed 7/7. Standalone test SHA-256: `cd3e8a8fea73e611f7ed7351beffbed4723f8d3eea5579f4ae13480d9dd9cdb5`; standalone log SHA-256: `8261fb2a6385d744d146187893c42af2410d3c269e3dfe059528bb00873b1def`.
- The exact-source reviewer passed map v6 at SHA-256 `aa37e0260d807dd36e543a522312d4cfd6c0df7333a13705681892a457369ac4`, map v8 at `7c55436742f07183be2e0a34f05aa0da581bac53361a710294de2555ff2467a4`, and map v10 at `1477c6aaf8c5235b0d59084eecd7f52d7ff2d3b3763336a9af9b68be9c83f5a5`. Maps v7 and v9 were held for documented evidence corrections. Review receipts are retained in `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-map-review.md`.
- Map v11 updates the test hash to `e6072f7eebab5e07edee6baf79e3281c72f6c360e6c2184ae92604a8ea7e1cb1` and adds the raw repeatability mismatch cases. Map SHA-256 is `17ca5035fc95e99857653d0157c33bf0c8dfea47f16066e5b5594f86b0f2eb95`; exact-source review is pending.
- Map v11 was held because its producer-identity row retained the older 444/444 count. Map v12 records current results and pins executor-test SHA-256 `bd3f0dc3c99f8e11487a6cb2c8746c964d6778a20d6fbc109bcaab450a2b650d`. It maps missing-selector refusal tests at lines 1648-1655. Map v12 SHA-256 `2aada96983f1504e5cf4630cd9a8a3a176ce4da4bb093f8aa74481d4ee33b36a` passed independent exact-source review; all seven source pins, mapped spans, and result counts matched. Receipt: `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-map-review.md`.
- The first run of these new tests passed 429 assertions before a nested Julia process hit `EPERM` creating a cache lock under `~/.julia`; its failed log is retained at `docs/dev-log/check-log.d/2026-10-09-g5-rank-interval-raw-guards.log`. The rerun used a writable temporary depot and passed executor 447/447 in 9m35.3s, reference-admission 17/17, UTF-8 identity 15/15, and framing 7/7.
- Added direct FA-rank and FA-interval raw-selector mismatch tests. The focused writable-depot run passed executor 447/447 in 9m33.2s, reference-admission 19/19, UTF-8 identity 15/15, and framing 7/7. Log: `docs/dev-log/check-log.d/2026-10-09-g5-rank-interval-selector-mismatch.log`, SHA-256 `3116c773b41f9c2e56bb7a66c587f04b88b03724427e9686d43f80ce3454ef5d`.
- Map v12 passed exact-source review at SHA-256 `2aada96983f1504e5cf4630cd9a8a3a176ce4da4bb093f8aa74481d4ee33b36a`. Map v13 was held because the producer-identity row said 17/17 instead of 19/19. Map v14 corrects this count and passed independent exact-source review at SHA-256 `95b8067b999b4d25a204dfc3e7b3e0e9e360532c33d7d5ea4464f6ea0c5a353d`; all seven pins, spans, and retained results matched.
- Map v15 was held because the existing `missing_bound` case omits `E`, not `upper_bound`, and its executor count was stale. Map v16 was held for case-count arithmetic, an interruption span, and three untested scalar predicates. Added direct rejection tests for wrong-type `E`, fractional residual degrees of freedom, and a finite gap equal to its separation threshold. The clean focused run exited 0 and passed executor 513/513 in 17m45.0s, reference-admission 19/19, UTF-8 identity 15/15, and framing 7/7. Log SHA-256 `f56d87095067e23c1a0f574fa677c786ae860b45fc45747668682ce5c39f3bd2`; exit-status record SHA-256 `9dc2d2e634629cfae5776cdd723736ed9f99cae2fb443953b8d86ce065335b45`; test SHA-256 `25d43c7be49227010404df99a6bbc114bbf2c0a6950b3fdc8fd6f73be9fdd181`. Map v17 SHA-256 `c7b58919c4f6c8bd543dc583b955155ccb6f983521437b6f647c46160a6ad68c` passed independent exact-source review.
- Added direct native receipt-checker tests for the valid empty-certificate state and three contradictory absence-status combinations. The focused Python 3.13 test passed 1/1; log SHA-256 `fb184ea57734512b1f088f9181209901b9cd46df3eb7eaa2500ea9e48dde20b5`; source SHA-256 `823638b868c0f7bd8c7765c23c0e66329dadbdd01715adba2bfefd217a56b3e9`. Map v18 SHA-256 `1b9bc692b290108aec27a0e839d7447ec833a307c0cf12bb8e4dcbae852fe904` passed exact-source review in the subsequent v19 review.
- Expanded the same checker test across malformed native evidence, wrong correspondence and evidence flags for the validated state, and wrong correspondence and evidence flags for interruption. The focused Python 3.13 matrix passed 1/1; log SHA-256 `fb184ea57734512b1f088f9181209901b9cd46df3eb7eaa2500ea9e48dde20b5`; source SHA-256 `77260be3941b082f41e4b5cce6766508042260b8328f7b6f54b7ebbc5b6603e0`. Map v19 was initially held for two map-only corrections; corrected map SHA-256 `d43c040febe9cd8c3b883c39ea430281dbdc35110df09d5defb62fc216842086` passed independent exact-source review with all seven pins and retained log hashes matching. Review receipt: `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-map-review.md`.
- The full Python adversary suite first ran 55 tests with one error because the tracked historical seed-audit metadata was stale; after refreshing that audit metadata, the formerly failing contract test passed alone (1/1) and the full suite passed 55 tests in 2390.698s. The two nested Julia subprocess bounds in the Python fixture were raised from 600s to 1800s based on the observed executor runtime. Passing log SHA-256 `e894a19d1798969f65e1561f01326b39b4944a329747d998dfb45b0b8e67f34a`; test source SHA-256 `34e90181aca57208d51431369b901653181e46a9172161035b90bb1ebe20c044`; final seed manifest SHA-256 `1af7d68f952ce751c6202df821c640ed11df89f23739fc0172d400cbcb6f89ef` after refreshing the tracked check-log audit as well. Manifest validation reports 10,330 outer rows, 634,420 nested rows, and 644,750 unique seeds; the outer CSV hash remains `498fcac802f01fedf4b8fb4fc90ba7a61d5b05259c44907d000a6e585587fe07`. No seed CSV or allocation changed in this slice.
- `git diff --check`, the canonical Arc 1 gate-lock verifier, and absolute-path style checks passed on this continuation. `check-after-task.R` passed report structure and returned UNMET for the active Arc 1, automatic FA-rank implementation, and non-GPU completion ledgers.
- `check-after-task.R` passed the report structure check, then correctly returned UNMET because Arc 1, automatic FA-rank implementation, and non-GPU completion ledgers still contain open gates. Current Arc 1 status: G0 met; G1 through G8 open. The evidence-promotion subcheck was not reached.

## 6. Tests of the Tests

The Julia cases require rejection from both the writer and a validly framed reader after record reconstruction. The expanded suite passed all identity cases. Framing adversaries passed in standalone and integrated runs. Twenty-five end-to-end certificate mutations returned invalid status and false evidence validity. Missing raw selectors for FA-rank and FA-interval now receive direct early-refusal assertions. Earlier harness failures caused by helper scope are retained; the corrected standalone harness passed. The certificate matrix is test-only because the production validator already enforces these invariants.

## 7a. Issue Ledger

- Fixed: nested producer identity could contain an owner, candidate ID, or path inconsistent with its enclosing record.
- Fixed in tests: missing direct adversaries for non-tuple IDs, Boolean and non-integer candidate IDs, zero and negative candidate IDs, shared and unresolved owners carrying IDs, an isolated unsupported owner, non-string and empty paths, and Boolean, zero, negative, and non-`Int` visit indices.
- Open: nested producer-record payload contents; combined certificate mutations; all raw-diagnostic checks; inspector subprocess boundaries; large-artifact performance; and interval calibration.

## 8. Consistency Audit

The current source and tests use the same identity tuple and owner rules. Map v16 was held for evidence-map corrections. Map v17 distinguishes 39 invalid value/type/identity mutations plus one E omission from the other 18 field omissions, corrects the interrupted-certificate span, and maps direct tests for the remaining three scalar predicates. Its independent exact-source review passed at SHA-256 `c7b58919c4f6c8bd543dc583b955155ccb6f983521437b6f647c46160a6ad68c`. Map v18 adds direct tests for the valid no-certificate state and three contradictory status combinations; it passed exact-source review at SHA-256 `1b9bc692b290108aec27a0e839d7447ec833a307c0cf12bb8e4dcbae852fe904`. Map v19 expands the native checker test to malformed evidence and both validated and interrupted-unavailable contradictions. After correcting its inspector span to include interruption assertions and describing the contradiction test as a summary-match flag check, corrected map SHA-256 `d43c040febe9cd8c3b883c39ea430281dbdc35110df09d5defb62fc216842086` passed independent exact-source review. Map v20 updates the source pin after increasing nested Julia test timeouts and records the clean 55-test run. It passed independent exact-source review at SHA-256 `61e342842ea9a3c36ccf539bbcee1eef8c04e56656b8bd79667279a40dcdf9a2`; all seven pins, the full-suite log, manifest counts, unchanged outer CSV hash, and all 1,001 historical-audit hashes matched. Review receipts are retained at `docs/dev-log/source-review/2026-10-09-g5-authoritative-container-map-review.md`. Unlazy remains G0 met and G1-G8 open. Capability remains experimental and the covered count remains seven. No seed, attempt allocation, denominator, acceptance rule, or public capability status changed.

## 9. What Did Not Go Smoothly

The first map review found stale line references, so the map was corrected and re-reviewed. Adding predicate tests shifted downstream test references and counts, requiring exact map refreshes. Two framing harness attempts failed because helper bindings were scoped inside a prior testset; the standalone test file corrected this and passed. The latest first-pass executor run hit a nested-process cache-lock permission error after 429 passing assertions; the writable-depot rerun passed. The expanded executor takes about 9.5 minutes. The closeout generator resolves its repository root to the canonical Dropbox checkout, outside this task's writable root, so its `new` command could not create the report here. The report was created in the active worktree. Its structure passed, while overall closeout correctly stopped at the active ledgers with unmet gates.

## 10. Known Residuals

This slice records bounded G5 engineering work. G5 and Arc 1 remain open. FA-rank and FA-interval raw-selector refusals and mismatch branches are tested. All 19 required certificate fields have one-at-a-time absence checks. The latest test tuple exercises 39 invalid value/type/identity mutations plus the E omission, including the three previously missing scalar predicates; the separate loop exercises the other 18 omissions. Combined mutations remain untested. A deterministic short read after a matching declared extent remains untested; the parser validates regular-file size before reading. The timed-out 130,851,693-byte legacy artifact remains untouched. The seed manifest refresh updated only the historical source audit from the already-current source tree; the outer CSV hash and scheduled seeds remained unchanged. The full Python adversary suite now passes, but this is engineering evidence only. No pilot, confirmation, or fit ran. Current Unlazy status remains G0 met and G1-G8 open.

## 11. Team Learning

Memory receipt: used the supplied HSquared.jl instructions, the retained Arc 1 checkpoint, current source and tests, Unlazy status, and exact-source reviews. Maps v7, v9, v11, v13, v15, and v16 were held for evidence corrections; maps v8, v10, v12, v14, v17, v18, and corrected v19 passed exact-source review. Map v20 passed independent exact-source review at SHA-256 `61e342842ea9a3c36ccf539bbcee1eef8c04e56656b8bd79667279a40dcdf9a2`. The initial v19 map was held for map-only corrections. The brain route script returned no LOAD-FIRST manifest for this worktree. No cross-project research was performed.

Golden Set: not run because this slice changes artifact validation and tests. Production estimator behavior was outside its scope.

## 12. Cross-Product Coverage

This slice covers Julia artifact-container validation and its writer/reader tests. It does NOT cover R parity, statistical interval calibration, automatic-rank confirmation, full package release, or GPU execution.

# G5 authoritative-container map review receipts

## Map v7

Decision: HOLD. The exact-source review verified the six source pins and integrated result hashes, and found no production defect. It identified a stale `402/402` count, incomplete inspector test spans, and residual wording that omitted untested scalar predicates.

## Map v8

Decision: PASS for the bounded evidence map only. Exact map SHA-256: `7c55436742f07183be2e0a34f05aa0da581bac53361a710294de2555ff2467a4`. The reviewer confirmed all six pinned file hashes, the retained integrated log hash, results `434/434`, `15/15`, `15/15`, and `7/7`, corrected inspector spans, and the expanded residual list. No mapping discrepancy remained.

This review does not pass G5. The timed-out legacy artifact, remaining certificate predicates, inspector/checker coverage, performance prerequisites, and interval calibration remain open.

## Map v9

Decision: HOLD for two line-range corrections. The reviewer verified all six pins, map hash, integrated result log, and 25-mutation count. Update the fake-engine inspector range from `1297-1610` to `1297-1612`, and the raw-evidence projection range from `1612-1633` to `1614-1635`. No other discrepancy was found.

## Map v10

Decision: PASS for the bounded evidence map only. Exact map SHA-256: `1477c6aaf8c5235b0d59084eecd7f52d7ff2d3b3763336a9af9b68be9c83f5a5`. Both requested spans are corrected. All six source/test pins and the retained log hash match. The map accurately records 25 certificate mutations and `444/444`, `15/15`, `15/15`, `7/7` results.

This review does not pass G5. Remaining certificate predicates, raw-diagnostic/checker coverage, subprocess and performance prerequisites, legacy artifact inspection, and interval calibration remain open.

## Map v11

Decision: HOLD for one stale count. The reviewer verified all seven source/test pins, map hash, retained result log, and raw repeatability range `1614-1645`; update the producer-identity row from 444/444 to 447/447. Rank/interval and certificate/checker residuals are accurately disclosed.

## Map v12

Decision: PASS for the bounded evidence map only. Exact map SHA-256: `2aada96983f1504e5cf4630cd9a8a3a176ce4da4bb093f8aa74481d4ee33b36a`. All seven source/test pins match the inspected files. The mapped spans agree with the current source and tests, including the raw repeatability cases at `1614-1645` and missing rank/interval selector cases at `1648-1655`. The stale producer-identity count is corrected.

The retained log SHA-256 is `22faf200da64a94b36d3fea2d1d8c978b1c2e5c220e5a5809ea85833d6580b39`. It records executor `447/447`, reference-admission `17/17`, UTF-8 identity `15/15`, and framing `7/7`. The framing summary appears twice in that log; this review does not count it as additional independent coverage. The 25 certificate mutations and remaining rank/interval mismatch, certificate, checker, subprocess, performance, and calibration limits remain accurately described.

No source or gate status was changed and no tests were rerun. Only this requested review receipt was appended. This review does not pass G5.

## Map v13

Decision: HOLD for one stale adjacent-suite count. Exact map SHA-256: `dd4685ff3449fc2cc18d899f0a0b4f4f72315f99fd03f2484189fcd996dec3a7`. All seven source/test pins match. The changed test span `1648-1674` correctly covers the two missing-selector refusals and the direct FA-rank and FA-interval selector-projection mismatch cases. Carried-forward spans and the 25-certificate-mutation count remain valid.

The producer-identity table row still reports reference-admission `17/17`; change it to `19/19`. The current-result paragraph and retained log already report the correct results: executor `447/447`, reference-admission `19/19`, UTF-8 identity `15/15`, and framing `7/7`. The log SHA-256 matches `3116c773b41f9c2e56bb7a66c587f04b88b03724427e9686d43f80ce3454ef5d`. Its duplicate framing summary is not additional independent coverage.

No other correction is required for this bounded map. The new cases cover their stated branches, without establishing full raw-projection branch coverage or G5 completion. No source or gate status was changed and no tests were rerun; only this review receipt was appended.

## Map v14

Decision: PASS for the bounded evidence map. Exact map SHA-256: `95b8067b999b4d25a204dfc3e7b3e0e9e360532c33d7d5ea4464f6ea0c5a353d`. All seven source/test pins and the retained result log match. The producer-identity row now correctly reports adjacent results `19/19` and `15/15`; executor `447/447` and framing `7/7` agree throughout. All previously reviewed test spans, the 25-certificate-mutation count, and bounded residual disclosures remain unchanged and valid.

The only evidence change from v13 is the requested count correction; accompanying edits update version and review history. A nonblocking editorial residue remains: the RESUME sentence still says to independently review map v13. This receipt supersedes that instruction and records the completed review of v14. The next action is the stated remaining certificate/checker work.

No source or gate status was changed and no tests were rerun. Only this review receipt was appended. G5 remains open.

## Map v15

Decision: HOLD. Exact map SHA-256: `353084d3b9f32e164d34759a9a5ca6676fa67f28810baad722237c8ffcd4b946`. All seven source/test pins and the retained log hash match. The log records executor `483/483`, reference-admission `19/19`, UTF-8 identity `15/15`, and framing `7/7`, with the framing summary repeated. Required corrections follow.

1. The producer-identity table row still calls `447/447` the current executor result; change it to `483/483`.
2. The claimed certificate omission mapping is incorrect. Test line 1413, named `missing_bound`, removes `E`. Line 1438 incorrectly says it covers `upper_bound` and skips that field. The new loop executes 18 omissions, not 19, and duplicates the existing `E` omission. There are 43 completed-artifact cases, including a duplicate, covering 18 distinct required-field omissions. The existing interrupted cases separately omit `upper_bound` at lines 1469-1470. Either document this exact split, or change the loop to skip `E` instead and obtain fresh evidence. Do not describe the existing 25-case tuple as exclusively value/type/identity mutations: it already contains the `E` omission.
3. Restore the still-open scalar-predicate residuals removed from v14: invalid-type/nonfinite `E`, wrong-type threshold/gap/cutoff, and other untested individual scalar predicates. Adding field-absence tests does not prove those predicates. Keep those gaps in both the table and overall limitation statement.

The other updated test spans locate their stated checks. For a precise retained-interruption span, use `1545-1561` instead of `1548-1569`; the latter includes the certificate assertions but starts after inspection and extends into the next case. No production defect was identified. No source or gate status was changed and no tests were rerun; only this review receipt was appended.

## Map v16

Decision: HOLD for evidence-map corrections only. Exact map SHA-256: `fdd3da0eb2298214a0d56419dd4d03059b4f3e643d34e27affafdb89ee8743a4`. All seven source/test pins match. The retained log hash `2797f7245ce3c47dfe7a77a701904a77027839d5493c2ab504cdbab6b7644608` matches and reports `507/507`, `19/19`, `15/15`, and `7/7`, with the framing summary repeated.

The E/upper-bound omission defect is fixed: line 1425 omits E and the loop at `1447-1468` skips E, covering the other 18 required fields, including upper_bound. All 19 distinct required-field omissions now have completed-artifact tests. Correct the map's arithmetic and spans as follows.

1. The tuple has 37 cases, consisting of 36 value/type/identity mutations plus one E omission. The subsequent loop adds 18 omissions, for 55 completed-artifact mutation cases overall. State that split rather than implying 37 non-omission mutations plus 19 separate omissions, and describe `1447-1468` as the other 18 omissions, with E covered at 1425.
2. Replace the retained-interruption span `1571-1592` with `1560-1576`. The former begins within an assertion and extends into the next failure case. Other changed mapped spans locate their stated tests.
3. Remaining gaps include individual predicates, not just combinations. For example, no direct case supplies invalid-type E, a non-Boolean non-integer residual_df, or a finite gap_lower at or below its separation threshold. Name these residuals in the table and overall limitation statement; field omissions and mismatched recomputed values do not uniquely test these checks.

No additional production defect was identified, and no new test run is required merely to correct this map. No source or gate status was changed and no tests were rerun; only this review receipt was appended. G5 remains open.

## Map v17

Decision: HOLD for four line-range corrections. Exact map SHA-256: `a1423ca5b8d97bd6c3bde8a63cff74310d10e048f24b689d251b8d39a8b0df4a`. All seven source/test pins match. The mutation arithmetic is correct: the first tuple has 39 invalid value/type/identity mutations and one E omission; the omission loop adds 18 distinct other fields, for 58 completed-artifact cases and all 19 required-field omissions. Direct cases for wrong-type E, fractional residual_df, and gap at the finite separation threshold are present at lines 1395, 1390, and 1407-1408 respectively.

Correct the inspector row's fake-engine span to `1297-1654`, raw repeatability span to `1656-1687`, and rank/interval span to `1690-1716`. Its current shorter spans omit assertions. Correct the retained-interruption span to `1564-1580`; the current end at 1579 omits the final assertion continuation. The other revised certificate spans match their tests.

The retained log SHA-256 matches `f56d87095067e23c1a0f574fa677c786ae860b45fc45747668682ce5c39f3bd2`, with clean summaries `513/513`, `19/19`, `15/15`, and `7/7`, and no duplicated framing summary. The log contains no explicit process-exit record, so this file alone does not independently prove the parent's reported zero exit. This limitation does not require another test run; preserve the runner's exit evidence or attribute the exit report to it. Bounded residual wording does not establish exhaustive certificate coverage or G5 completion.

No source or gate status was changed and no tests were rerun; only this review receipt was appended.

## Map v17 corrected

Decision: PASS for the bounded evidence map. Exact map SHA-256: `c7b58919c4f6c8bd543dc583b955155ccb6f983521437b6f647c46160a6ad68c`. All seven source/test pins remain unchanged and match. The four requested spans are corrected to `1297-1654`, `1656-1687`, `1690-1716`, and `1564-1580`. The verified arithmetic remains 39 invalid value/type/identity cases plus 19 distinct required-field omissions, for 58 completed-artifact cases.

The output log hash matches `f56d87095067e23c1a0f574fa677c786ae860b45fc45747668682ce5c39f3bd2`; its summaries are `513/513`, `19/19`, `15/15`, and `7/7`. The added status file hash matches `9dc2d2e634629cfae5776cdd723736ed9f99cae2fb443953b8d86ce065335b45`. It retains the command with pipefail, the driver's observed exit code 0, and matching test-source and output-log hashes. This review checked that retained record without rerunning the command.

The three previously named scalar gaps have direct cases and the stated broader limitations remain open. No further correction is required for this bounded map. Only this review receipt was appended; source, gate status, and test results were unchanged. G5 remains open.

## Map v18

Decision: PASS for the bounded empty-certificate checker slice. Exact map SHA-256: `1b9bc692b290108aec27a0e839d7447ec833a307c0cf12bb8e4dcbae852fe904`. All seven source/test pins match, including Python test hash `823638b868c0f7bd8c7765c23c0e66329dadbdd01715adba2bfefd217a56b3e9`. Test span `1661-1703` maps directly to `_check_v4_native_certificate_validation` at checker lines `351-383`: the no-certificate success tuple returns false as required, while each independently altered status, correspondence, or evidence-validity field raises the expected receipt error. Existing validated and interrupted-unavailable cases remain in that span.

The focused Python log matches `fb184ea57734512b1f088f9181209901b9cd46df3eb7eaa2500ea9e48dde20b5` and reports one test, OK. Carried-forward Julia output and exit-status hashes match, retaining `513/513`, `19/19`, `15/15`, and `7/7`. The shifted Python spans are correct. This review does not establish a current full Python-suite pass, and the map appropriately records the focused run separately.

For precision when next editing the inherited contradiction-test description, the test at `1705-1750` asserts that the inspector's `receipt_summary_matches_retained_result` flag is false. It does not itself call the whole receipt verifier and assert an exception. That distinction does not block the reviewed empty-certificate slice or expand its credit.

Only this review receipt was appended. No source or gate status was changed and no tests were rerun. G5 remains open.

## Map v19

Decision: HOLD for one stale line range. Exact map SHA-256: `c08993a395e4a6d99c9536f4c435c2c0c43043a0b181d6977bd8fd222039a4c8`. All seven source/test pins match, including Python test hash `77260be3941b082f41e4b5cce6766508042260b8328f7b6f54b7ebbc5b6603e0`. The helper span `1661-1725` correctly covers malformed native containers, each no-certificate status predicate, both validated-status predicates, and each interrupted-unavailable conjunction operand at checker lines `351-383`. Validated and interrupted success calls establish acceptance but do not assert their return values; the bounded acceptance/refusal wording is accurate.

In the V4 native certificate inspector row, change the Python span `1597-1703` to `1597-1725`. Line 1703 only sets up the interrupted attempt, so the current span excludes the interruption success and refusal assertions. The G5 receipt row already cites the complete helper span. While editing, apply the v18 precision note to the inherited contradiction-test description: lines `1727-1772` assert that the inspector summary-match flag is false, rather than asserting whole-verifier rejection. This inherited wording distinction does not change the helper-test result.

The focused Python log hash matches `fb184ea57734512b1f088f9181209901b9cd46df3eb7eaa2500ea9e48dde20b5` and reports one test, OK. The carried-forward Julia output and exit-status hashes also match. This review does not establish a current full Python-suite pass. Remaining broader coverage and calibration limits remain open as stated. No test rerun is needed to correct the map.

Only this review receipt was appended. No source or gate status was changed and no tests were rerun. G5 remains open.

## Map v19 corrected

Decision: PASS for the bounded evidence map. Exact map SHA-256: `d43c040febe9cd8c3b883c39ea430281dbdc35110df09d5defb62fc216842086`. All seven source/test pins match. The V4 inspector row now cites `1597-1725`, including the complete interruption assertions. The contradiction-test description now accurately states that `1727-1772` asserts the inspector summary-match flag is false. Both requested corrections are resolved.

The focused Python log retains SHA-256 `fb184ea57734512b1f088f9181209901b9cd46df3eb7eaa2500ea9e48dde20b5` and reports one test, OK. The Julia output and status records retain matching hashes and results `513/513`, `19/19`, `15/15`, and `7/7`, with the driver's observed exit code 0. Source, test, and checker branches are unchanged from the preceding review. The map claims bounded acceptance/refusal evidence and preserves the remaining limitations; it does not establish a full current Python-suite pass or a G5 gate pass.

Only this review receipt was appended. No source or gate status was changed and no tests were rerun. G5 remains open.

## Map v20

Decision: PASS for the bounded evidence map. Exact map SHA-256: `61e342842ea9a3c36ccf539bbcee1eef8c04e56656b8bd79667279a40dcdf9a2`. All seven source/test pins match. Replacing the two current `timeout=1800` values with `timeout=600` reproduces the v19 Python test hash exactly, confirming that this change leaves its mapped test spans and assertions unchanged.

The retained full-suite log `docs/dev-log/check-log.d/2026-10-09-g5-python-adversary-full-rerun.log` matches SHA-256 `e894a19d1798969f65e1561f01326b39b4944a329747d998dfb45b0b8e67f34a` and reports 55 tests in 2390.698 seconds, OK. The preceding full-run log records the one historical-seed-audit mismatch described by the map. The passing suite includes `verify_manifest` at Python test line 338. This review inspected retained evidence; it did not rerun the suite or the separate validate-only command.

Current manifest SHA-256 is `32f3553e7b513abd14a5a8a9fb60c5312942687a392edeb89ae3ea72e5058dcc`. Its retained validation counts are 10,330 outer rows, 634,420 nested rows, and 644,750 unique keys and seeds. The CSV independently contains 10,330 rows and retains SHA-256 `498fcac802f01fedf4b8fb4fc90ba7a61d5b05259c44907d000a6e585587fe07`; summing the manifest's nested ranges yields 634,420. All 1,001 retained historical-audit file hashes match current files. These checks support the stated audit refresh and unchanged outer allocation without providing new scientific study evidence.

The map preserves its residual coverage, performance, admission, and calibration limits and explicitly keeps G5 open. No further correction is required for this bounded map. Only this review receipt was appended. No source or gate status was changed and no tests were rerun.

## Map v20 manifest follow-up

Decision: PASS after the tracked check-log refresh. Current manifest SHA-256 matches `1af7d68f952ce751c6202df821c640ed11df89f23739fc0172d400cbcb6f89ef`. Both the directly called `verify_manifest(..., audit_root=Path.cwd())` and `python3 -B tools/arc1_manifest.py --validate-only` completed with exit 0. They verify 1,001 audited paths, 394 historical literals, 10,330 outer rows, 634,420 nested rows, and 644,750 unique keys and seeds. The outer CSV retains SHA-256 `498fcac802f01fedf4b8fb4fc90ba7a61d5b05259c44907d000a6e585587fe07`; all seven v20 source/test pins remain current.

This supersedes the preceding receipt's manifest hash only. The full suite was not rerun, source and gate status were unchanged, and only this review receipt was appended. G5 remains open.

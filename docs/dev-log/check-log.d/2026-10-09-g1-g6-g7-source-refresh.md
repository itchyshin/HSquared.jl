# 2026-10-09 Arc 1 current-source G1/G6/G7 refresh

## G1

- Freeze: paired oracle freeze-v2, SHA-256 `4c1b0a9135e479fdccb227561dcda6411b88bcd6b2de3723ace6ce610b488b77`.
- Run: `20261009T203142Z-4ac04d7b8b6b`; receipt SHA-256 `ea325df329b1d0c69825cb06290cbcbaca5c4e90ebc09d9bbac40d1c12cb967b`.
- Result: nine suites and 3,120 assertions passed; independent audit passed; retained verifier emitted `ARC1_G1_RETAINED_RECEIPT_VERIFIED`.

## G6

- Freeze: paired oracle freeze-v2, SHA-256 `4c1b0a9135e479fdccb227561dcda6411b88bcd6b2de3723ace6ce610b488b77`.
- Run: `20261009T204058Z-965aeadeb7b4`; receipt SHA-256 `3c2b6415f4cbab015ffe3f8b005a6aae622251071e5b45247c4cae8404748226`.
- Result: 682 required-live R assertions across seven files; zero failures, errors, skips, or warnings. Three commands exited 0 with sealed logs. Runtime 2,212.350 seconds; live R 2,211.804 seconds.
- Independent review: `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/paired-source-freeze-20261009-v1/g6-run-review-v1.md`.
- Retained verifier emitted `ARC1_G6_RETAINED_RECEIPT_VERIFIED`.

## G7

- Freeze: package freeze-v11, SHA-256 `cb4377e5ad7788d72487598ac154bdc3ceb8116865dcdc8cdc5f4996355bddf0`.
- Run: `20261009T211922Z-876e2b22e0`; receipt SHA-256 `a8dfb48065c54c307097d3d4ff3ea9e64d3d1cab325d0be370b1964445f9a3e6`.
- Result: 11,694 Julia assertions across 330 summaries; 682 required-live R assertions across seven files; `R CMD check` `Status: OK` with zero package errors, warnings, or notes; docs passed with output hash `63a15d5a2cc912b69300732a48f7eb78e448a2a159a2f4b212d91223ff2284d0`. Total 6,397.152 seconds.
- Independent review: `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g7-source-freeze-20261009-v11/g7-run-review-v1.md`, SHA-256 `23edfab356e7f41aeb43a488c6458cdf642aa616bddde337d9dff829c1bd36fe`.
- Retained verifier emitted `ARC1_G7_RETAINED_RECEIPT_VERIFIED`.

These engineering checks provide no scientific calibration or study evidence. G2-G5 and G8 remain open; capability remains experimental and covered count remains seven. Full details and known warnings are in `docs/dev-log/after-task/2026-10-09-g1-g6-g7-source-refresh.md` and the Arc 1 checkpoint.

# Baseline reviewed-repair composition

Date: 2026-09-30. Verdict: PASS for isolated composition and its focused checks. This checkpoint precedes the separately approved h2 descriptor addition.

## 1. Goal

Compose the approved Julia repairs against the current dirty candidate, preserving its runner and weak-direction work.

## 2. Base

Snapshot HEAD 3d6d7ffc961b65fa5a44ce277a7d1168ba69b6fe; source tree d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a. Current dirty files were copied directly. Generated docs build/cache directories were excluded. Project/Manifest, src/test/tools/docs, sim and comparator inputs were retained.

## 3. Changes

Twelve pinned patch inputs composed into 21 changed files. Source changes are confined to eight files. Both coefficient-field and maternal-label schema changes are included. R reader repair stays separate.

## 4. Overlap

The descriptor patch conflicted with the GLLVM input patch at two entrypoints. Both now run the record-family guard followed by the mode-input guard. Other hunks merged unchanged. Every later patch applied cleanly.

## 5. Tests

The two invalid GaussianResponse(Inf) factories moved out of the tuple into constructor exception assertions, changing the C1/C4 total from 50 to 48. Seven standalone files are registered; six module includes were added, with the existing coefficient include preserved once. Approved marker tests remain in their existing testset.

## 6. Runtime evidence

Estimate before launch: 10-20 minutes including compilation. One Julia and one BLAS thread, offline package mode, no full package suite. focused-checks.log records 481/481 assertions passed, exit zero: syntax16, status2, GLLVM48+50, coefficient74, RR41, data29, flat35, ingress141, marker45. Testset execution times range from 0.0 to 3.6 seconds. No FA recovery rerun occurred.

## 7. Preservation

FA source multivariate.jl, campaign driver, Project/Manifest and weak-direction test are byte-identical. The original dirty runner is exactly reconstructible with only the approved coefficient/marker edits plus registration. Ledger title/ID/status fields and runtime status sets are unchanged.

## 8. Replay

Combined apply-check passed on the dirty snapshot and current live candidate. Replay reproduced all 21 changed-file hashes. No live application occurred.

## 9. Pins

Baseline combined patch SHA256 a963144788ba80e5313320f2bd8f54f30615db0962cabd1ac7d0fd58e7137c62. Composed source tree 0683697c6f17c1d650982be1ce30a2f8a1ae888816f415a8a51f3abe4d288853. Payload parser 9d389444008a25ddfb3ba140836bab5a3d2c8ebfb94052424d8d1ac6c0c5a3e9. Runner af8681e54ae7ac6582042ef848ddc0d7b29f66cd0e81b2c5504bf5ea23e939b1. Full original/result/input/test pins are in baseline-composition-inventory.json.

## 10. Ownership and remaining work

Only the named composition scratch directory was changed. Parent-announced source-neutral checkpoint advanced live HEAD to 6271cfd58651e69cd27a64dcf02cb8960a29e260; live source/schema/runner remain unchanged. Source integration, independent composition review, full package checks and A2 panel remain separate. No gate flip or release action occurred.

## 11. Handoff

This checkpoint preserves the first composed state and its raw test log. The approved h2 patch and required prose corrections will be added as a separate delta, tested against this composed state, and included in the final receipt.

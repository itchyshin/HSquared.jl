# 2026-09-29 FA ordinary-start driver repair

## 1. Goal

Repair the Gaussian FA ordinary-start recovery driver so nullable diagnostics and setup failures cannot corrupt the measured recovery outcome, then validate the exact amended driver on a short development seed.

## 2. Implemented

- Nullable diagnostics serialize as `NA` instead of converting valid fits into exception rows.
- DGP construction and truth-objective evaluation are inside retained-failure handling. Fit time is only counted after fitting begins.
- Output includes uniqueness-floor distance, a near-floor flag, start disagreement, better-nonconverged-start status, per-start diagnostics, and elapsed fit time.
- Provenance distinguishes the deterministic source-tree hash from the driver hash.
- `Sockets` is a test-only dependency with a Julia 1.10 compat bound so the package suite can include the driver.
- A dated additive amendment and row-level Totoro receipt preserve the new development evidence without editing the frozen primary method or seeds.

## 3a. Decisions and Rejected Alternatives

- Kept the frozen four-trait, rank-one DGP, ordinary starts, 5,000-iteration cap, thresholds, and primary seeds `20261200:20261399` unchanged.
- Used a new development seed, 20261406, outside the primary stream.
- Repeated the seed under Julia 1.10.12 after the Totoro default Julia 1.12.6 run revealed a runtime-version mismatch with prior receipts. The 1.12.6 output is superseded and excluded.
- Retained the 200-seed campaign as an explicit-approval gate because its measured 2x estimate remains over three hours.

## 4. Files Touched

- `Project.toml`
- `sim/fa_ordinary_start_recovery_20260928.jl`
- `test/runtests.jl`
- `test/test_fa_ordinary_start_driver.jl`
- `docs/dev-log/recovery-checkpoints/2026-09-29-fa-ordinary-start-driver-amendment.md`
- `docs/dev-log/recovery-checkpoints/2026-09-29-fa-ordinary-start-driver-prerun.tsv`
- `docs/dev-log/check-log.d/2026-09-29-fa-driver-fix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-fa-driver-fix.md`

## 5. Checks Run

- Focused driver regression: 16/16 passed.
- Full Julia `Pkg.test()` with four Julia threads and one BLAS thread: passed; final output ended `Testing HSquared tests passed`.
- Totoro development pre-run, Julia 1.10.12, four Julia threads, one BLAS thread, CPU only: seed 20261406 recovered in 49.6087 fit seconds. Both starts converged; balanced selected.
- Output SHA-256: `9979e3f8105521f1fa9c59ed147ddba7fe6cc9fcec036383ac812ec8e59c1b15`.
- Source-tree SHA-256: `75b3a76d324476bf01aca3a8fc34c5ab951f6d209fdeac37a2d61448bf430f3c`; driver SHA-256: `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`.
- `git diff --check`, `bash tools/preamble_cap.sh` (11,024/14,000 bytes), after-task structure validation, and prose lint passed after report edits.

## 6. Tests of the Tests

- The focused new tests caught nullable-diagnostic and setup-failure retention regressions before the driver changes.
- The first full suite caught the missing `Sockets` test extra. The next run caught the missing compat bound through Aqua. The final full suite passed after both corrections.
- Rose's read-only claim audit found the needed hash reconciliation and check-log entry; both are now recorded. The audit confirmed no public capability promotion is implied.

## 7a. Issue Ledger

- Fixed: `nothing` in `objective_range` could abort serialization and turn a valid fit into a false failed row.
- Fixed: DGP and truth-objective errors could escape the per-seed failure-retention path.
- Fixed: output discarded diagnostics needed to interpret floor proximity and restart disagreement.
- Fixed: provenance previously used ambiguous hash labels.
- Open: primary 200-seed recovery estimate, approval, full FA validation gates, GLLVM validation gates, and source-review waves.

## 8. Consistency Audit

- The amendment distinguishes the old source archive hash, old driver hash, historical `src/multivariate.jl` hash, and new source-tree/driver hashes. The historical `68f1ec…` file hash is not represented as current; current `src/multivariate.jl` is `a28d88c349412d08d480c505032201dcde5c0b8ab237bf819dbf07ad692cb474`.
- The Totoro source-tree mismatch was traced to AppleDouble sidecars created on extraction. After removing only those metadata sidecars, the source-tree hash matched the candidate. All tracked Julia source files matched by checksum.
- The driver repair does not change the estimator or pre-registered primary outcome criteria.

## 9. What Did Not Go Smoothly

- The initial full suite stopped because the newly included driver imports `Sockets`, which was absent from test extras. Aqua then required the standard-library compat entry. Both were corrected and the final suite passed.
- The first remote run used Totoro's default Julia 1.12.6 and included metadata sidecars in its source hash. It was excluded; the source copy was corrected and the same development seed was rerun under Julia 1.10.12.
- The lane-lease registry initially denied a sandboxed write; the elevated lease operation then succeeded before report files were edited.

## 10. Known Residuals

- Seven Julia 1.10-series development fits average 72.15 seconds. With a 2x margin, the 200-seed run is estimated at approximately 8.1 hours plus startup. It remains unstarted pending explicit approval.
- One recovered seed does not estimate a recovery proportion, establish broad FA reliability, identify uniqueness, validate intervals, or promote a capability.
- R-Julia parity, same-model external comparison across the target cell, full Rose evidence audit of the overall programme, remaining source-review spans, docs/CI, and all other acceptance gates remain open.
- No GPU execution, CRAN submission, Julia registry submission, release tag, merge, or capability status change occurred.

### Exact-current replay addendum, 2026-09-29

After later edits to `src/multivariate.jl`, development seed 20261406 was rerun against current source-tree SHA-256 `ba890556104f44f8d6b7c54d90c0962beb0816b90753de9a9f01ec4ab25f00d1`; driver SHA-256 remained `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`. Julia 1.10.0, four Julia threads, one BLAS thread, CPU only. The seed recovered under the frozen diagnostic rules in 94.169 seconds. Default and balanced starts both converged; balanced was selected. Relative G/R errors were 0.37677/0.20937, fit-minus-truth objective was 8.32515, and minimum uniqueness was 0.14764. Output SHA-256 `20e8229e9e03577b1be2e2e0d25ba0ab7d222c3be4a1b0769c1352f075c09dc4`; retained at `docs/dev-log/recovery-checkpoints/2026-09-29-fa-exact-current-replay.tsv`. This single development replay verifies current-candidate execution/provenance only. It is not a recovery-rate estimate or broad reliability evidence. The frozen 200-seed primary remains unstarted and held for explicit approval.

## 11. Team Learning

- Astra's independent FA review found the `nothing` serialization path and incomplete exception retention before a long run was approved. Gauss and Hopper identified separate carried review findings; this repair does not close those lanes. Rose confirmed this patch remains status-safe and required explicit provenance reconciliation.
- Explicitly naming different hash artifacts and retaining diagnostic fields prevents operational failures from being mistaken for model failures.

## 12. Cross-Product Coverage

Covers the Julia FA ordinary-start simulation driver, its tests, test-only dependency declaration, and one development pre-run. This slice does NOT cover the R public route, broad FA inference or reliability, GLLVM completion, whole-source review signoff, GPU, a primary simulation campaign, capability promotion, CI, merge, release submission, registry submission, or public tag.

# H3 seed match audit: Fir HSquared result store, 2026-10-04

## 1. Goal

Check the known H3 screen seed IDs against the existing Fir HSquared result store, without running compute or allocating seeds.

## 2. Implemented

- Queried only `/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results` through the existing Fir ControlMaster socket.
- The top level contained 156 files totaling 52,322,029 bytes; the full directory tree occupied 133,916,458 bytes. No H3-named result file was present.
- Searched the directory for the known H3 seed IDs `20260903`, `21270914`, `24270923`, `95050029` through `95050033`, and `95060036` through `95060040`. Four result files contained a match; every match was the numeric seed `21270914`.
- The matched rows identify H2 interval-coverage cells such as `tiny|h2=0.2|level=0.95`, with targets `h2` or `sigma_a2` and H2 interval methods, distinct from the H3 genetic-correlation screen. The seed was already excluded from future H3 allocations by the earlier H3 audit.
- Repeated the exact known-seed and H3-filename searches in the existing Narval and Tamia result paths. Neither contained matches. The Narval path had 20 top-level files; its full tree occupied 75,942 bytes. The Tamia path had 19 files totaling 76,665 bytes. The expected result path was absent on Nibi, Rorqual, Trillium, Killarney, and Vulcan.
- Targeted ignored-store review found only gate/plan markdown in the inspected `h2-fixer`, `h2-test-campaign`, `post366-arc`, `237-mv-permanent`, and `coverage-366` ledgers, plus the inspected H2 history ledgers. Searches for all 13 known H3 seed IDs returned no matches there or in the current Arc 1 seed-manifest validation log.
- The frozen #366 seed list `docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-seeds.txt` still has SHA-256 `c35170cc047008835af7e854b54cf7b4f5a73a209b1401b7b067646782aa098c`; an exact search found none of the 13 known H3 seed IDs in it.
- Hashed all four matching result files and retained the current local ref/worktree exclusion inventory. No source, remote result, or seed allocation was changed.

## 3a. Decisions and Rejected Alternatives

Classified `21270914` as a cross-study numeric seed collision, not as another H3 attempt, because the result rows name H2 heritability or additive-variance interval targets and their corresponding interval methods. Kept it excluded from future H3 allocation. Did not interpret the absence of H3-named files as proof that every remote store or historical source was inspected.

## 4. Files Touched

- Created `docs/dev-log/source-review/2026-10-04-h3-fir-seed-match-audit.md`.
- Created the local exclusion-inventory snapshot `/private/tmp/h2-nongpu-h3-seed-inventory-20261004.json`, SHA-256 `d46efcf7980fe5b09e0a8a4d705f734e7d8c5248181cd9f40b38d34054079c37`.
- No Julia/R source or test file changed. No remote file changed.

## 5. Checks Run

- Julia lane preflight: exit 0. It reported two active foreign Cursor lanes and required work to avoid their paths. The changed paths of both branches were inspected; this audit report has a path-scoped lease.
- H3 local exclusion inventory: `python3 -B tools/mv_h3_rg_seed_audit.py --output /private/tmp/h2-nongpu-h3-seed-inventory-20261004.json`, exit 0. It recorded 374 refs, 53 worktrees, 204 unresolved sources, `freshness_verified=false`, and `execution_authorized=false`. Unresolved categories: 189 ignored inventories not descended, 6 missing ref objects, 6 unavailable ref trees, 1 remote not queried, 1 out-of-root historical result store, and the cited sister-R document.
- Local H3 smoke files matched prior audit hashes: `c1ext-smoke-rg-replicates.tsv` SHA-256 `0cd0ae8a6da17159324aad0cfd50b8a486b56d52c760fae3f0bff515ad441a50`; `c1ext-smoke-all-replicates.tsv` SHA-256 `e8ca0ebd071088baf04b38065e8a7f3489202da3cccd9028cf75211ed1ff5d53`.
- On Fir, `find` found no H3-named file in the bounded result directory. The exact-seed search returned four coverage-result files. Target/method inspection classified their rows as H2 interval coverage, with target `h2` or `sigma_a2` and matching H2 interval methods.
- On Narval (`~/projects/def-snakagaw/HSquared.jl/sim/drac/results`) and Tamia (`/project/aip-snakagaw/HSquared.jl/sim/drac/results`), recursive searches found neither H3-named files nor any of the known H3 seed IDs. The no-match `grep` commands returned 1, as expected. The analogous paths were absent on Nibi, Rorqual, Trillium, Killarney, and Vulcan.
- Exact seed searches over the selected ignored `h2-fixer`, `h2-test-campaign`, `post366-arc`, `237-mv-permanent`, `coverage-366`, `pr355-rebase`, `h1two`, `s10`, and `s9a4` ledgers and the named current Arc 1 seed-validation log returned no matches. The other ignored inventory entries remain unreviewed.
- Exact search in the frozen #366 seed list returned no matches for the 13 known H3 IDs. Its recorded hash is unchanged.
- Fir result hashes: `cov_delta_profile_46853279-replicates.tsv` `970e62ad606391da6646d0cccea9aae63cbe0d20e9f45f1388c1930135de759d`; `cov_boot_full_47870067_0-replicates.tsv` `da5b2ea7aee6adb984c1fa39db77234035accee8841419428d6e827302c8f778`; `cov_boot_full_47870067_1-replicates.tsv` `2cd7b6e21215d76eeb61af7c620a63e952101fe621a584a913283cf7e6d879a4`; `cov_boot_full_47870067_2-replicates.tsv` `e6716d8c26aba5c0930b6e08efc09a6c4f25c704a0b61a2744ef6bf5ff8b78ce`.
- `git diff --check -- docs/dev-log/source-review/2026-10-04-h3-fir-seed-match-audit.md`: passed. `slop_check.py` reported zero findings.
- `check-after-task.R` reported that this report's structure passed, then stopped because the Arc 1, automatic FA-rank, and H2 non-GPU acceptance ledgers still have unmet gates. `closeout.py check` therefore did not promote this partial audit as a finished project task.

## 6. Tests of the Tests

No test or checker changed. No negative-control test was run. The row classification was checked against the result-table headers and the target, method, seed, and scenario fields in the matching rows.

## 7a. Issue Ledger

- Confirmed seed `21270914` is also used by unrelated H2 interval-coverage rows on Fir. It remains excluded from new H3 allocations, as already required by the retained H3 audit.
- H3 seed freshness remains unverified. The local inventory still has 204 unresolved sources; this check covers only the bounded Fir, Narval, and Tamia result paths and selected ignored ledgers.
- No new H3 fit or screen attempt was found in this Fir directory.

## 8. Consistency Audit

The two local H3 smoke-result files have the same hashes as the earlier Totoro/source review. Fir rows with the matching seed identify H2 `h2` and `sigma_a2` targets, rather than the H3 correlation-screen route. This is consistent with retaining the seed as globally spent while not classifying these rows as H3 attempts.

## 9. What Did Not Go Smoothly

The first default-sandbox SSH attempt could not access the existing local control socket. Repeating the bounded read-only commands through the existing Fir ControlMaster with the approved sandbox escalation succeeded. One initial exact-seed command did not return a terminal status; the same bounded search was repeated and completed with exit 0. The shared `closeout.py new` helper initially resolved a relative path against the brain repository and attempted to use that repository's file inventory; rerunning it with the absolute HSquared path fixed the destination, and this report replaces the unrelated template file list.

## 10. Known Residuals

This audit does not establish H3 seed freshness or authorize a screen. It did not inspect every ignored directory, unavailable Git object, cluster-specific path outside the existing Fir/Narval/Tamia result directories, out-of-root result store, or the sister-R predeclaration. The project-wide goal remains open, including Arc 1 G0-G8 and non-GPU project H1-H9 gates.

## 11. Team Learning

Memory receipt: `route.py` found no LOAD-FIRST manifest for this checkout. I used the repository instructions, Graft source graph, H3 preflight records, and current H0/H1 gate records. Their relevant boundary was to treat seed-number matches as evidence to classify, not as proof that the same model route ran. No sibling project was scouted.

Golden Set: not run. This was a read-only provenance audit and changed no implementation or test behavior.

## 12. Cross-Product Coverage

Covers: provenance classification for known H3 seed IDs in the inspected Julia/Fir, Julia/Narval, and Julia/Tamia HSquared result paths and selected ignored ledgers.

Does NOT cover: H3 model fitting, screen execution, calibration, seed freshness across all hosts/stores, R-Julia parity, package checks, any capability-status change, or release readiness.

# H3/#366 retained Totoro result audit

## 1. Goal

Inspect the retained Totoro outputs that could affect freshness of the predeclared H3 genetic-correlation screen. Do not run jobs or allocate seeds.

## 2. Implemented

Read the existing runner, result tables, replicate-level rows, status file, and timing log through the existing Totoro ControlMaster socket. The run records one H3 genetic-correlation smoke attempt at seed `24270923`, plus ten timing attempts at seeds `95050029` through `95050033` and `95060036` through `95060040`. All carry `claim_eligible=false`; the log labels both outputs `GATE PATH_ONLY`, including the five-replicate invocation whose mode argument was `confirm`.

The smoke seed `24270923` equals replicate 1 of the 48-replicate H3 stream in the 2026-09-03 predeclaration: `20260903 + 1_000_003*4 + 10_007*1 + 1`. It must be excluded from a future fresh allocation. The ten timing seeds use a distinct master seed and do not overlap the 2,000 numeric seeds in the #366 locked list. The timing outputs are not screen or confirmation evidence.

The H3 run receipts are now found on Totoro, but the full historical seed inventory remains unresolved. No source, result, allocation, status row, or remote file was changed.

The supplemental audit also found two H3 RG smoke rows in the registered `09-h1-h3` worktree's ignored `tmp/`: seed `21270914` in `c1ext-smoke-rg-replicates.tsv` (SHA-256 `0cd0ae8a6da17159324aad0cfd50b8a486b56d52c760fae3f0bff515ad441a50`) and seed `24270923` in `c1ext-smoke-all-replicates.tsv` (SHA-256 `e8ca0ebd071088baf04b38065e8a7f3489202da3cccd9028cf75211ed1ff5d53`). The rows are output-file claims with `fit_converged=false`; neither is screen or confirmation evidence. Across this worktree and the inspected Totoro runner, the distinct H3 RG seeds to exclude are `21270914`, `24270923`, `95050029..95050033`, and `95060036..95060040`.

## 3a. Decisions and Rejected Alternatives

- Classify the `mode=confirm` command from its full receipt. It used five replicates, and the log says `PATH_ONLY`, `not_a_claim`, and `confirm_tier_not_run`.
- Exclude every H3 seed in the located smoke and timing outputs from any later allocation. Do not count their coverage as validation for the planned screen.
- Do not infer freshness from absence in the #366 seed lock alone. That lock is a separate 2,000-seed list and does not exhaust H3 history.

## 4. Files Touched

- `docs/dev-log/source-review/2026-10-04-h3-totoro-results-audit.md` (created)

The initial sandboxed lease attempt could not write the shared lease registry. A path-scoped lease was then granted through the authorized helper before this file was created. No other repository file was edited.

## 5. Checks Run

- `bash /Users/z3437171/shinichi-brain/tools/lane_preflight.sh /Users/z3437171/.codex/worktrees/b9ae/HSquared.jl`: current Codex branch confirmed; three other path-scoped leases were present and were not overlapped.
- `python3 /Users/z3437171/shinichi-brain/tools/route.py HSquared.jl`: loaded the project manifest, which prioritizes coverage calibration issue #366.
- `git cat-file -t 3762eff09144f1da88de4f83ba872ffff7507d80`: returned `commit`. The source file at that commit, `sim/phase1_interval_coverage_ext.jl`, hashes to `60225d56dffffec004f2985d67134938ea8b7469ce9508d901135ec858c5afe5` and contains the recorded seed formula and campaign ordering.
- `git ls-remote --heads origin | awk '$2 ~ /(h3|366|arc1|coverage)/ {print}'` completed read-only on 2026-10-04 and returned two relevant heads: `cursor/09-h1-h3-harness-20260903` at `b0f645eebe244176114df79b837affa947b5bbb8` and `feat/2026-07-03-interval-coverage` at `c0a33d60b8e947f42c66cf6ebaebaaacc4c690c0`. This refreshed the public branch list; it did not inspect remote job stores or PR refs.
- Read-only SSH through `/Users/z3437171/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22` verified the remote checkout HEAD `3762eff09144f1da88de4f83ba872ffff7507d80`, runner SHA-256 `92116fbbf1c1d6019fc482c1ceeb0de5bbd13bdd34318bae2b9414c72cca0be3`, and historical run receipts. The runner started 2026-09-04, completed both stages with exit 0, and recorded a 3m31s timing run.
- Remote receipt hashes: runner `13f9a42143f78162bd2ae24a6c529bd3a97670964d7da4e784e87f615adce7a4`; smoke summary `99f4550a97af47d65ffb6ac26df1db5bb0da1377ed421be6e23df9f028f5f019`; smoke rows `8e02b95cd88d2fbbe60dc49352b49ec872eaf57fcd70a929fb081f4679d009bf`; smoke log `ad97f347ff3cc36d1cc5ef76903ce5a1adecd0622367c32465d52fd198cf8e71`; timing summary `4caf9fa6f43b1cb64e139b95a8008997252cc1049c78f0b6f195b0e18ed48d2d`; timing rows `1f28fc451329c9578212b94f3b1832114de380df19cff38d71917e5903b34a21`; timing log `c8dbbc07ed7cb6bd354750eedfac24383e767200856423882469d35c465455ed`; timing record `1b0e716f589b39aa1d9cfd640f16ad92ac315254418a3406c107e7d90d6a6031`; status `a4710139472a3654e683b26c2f3ea2053b1d2f509bcdfd8fb0650c93a93df506`; nohup output `1332938f091aa48f1488dca3645888fee676bd148929c77bef4738c3c196cef6`.
- A path-and-name search of the Totoro `HSquared.jl` checkout found only those `c1ext-totoro-*` files. The three additionally inspected logs duplicate the smoke/timing commands and `PATH_ONLY` status; they contain no extra attempts.
- The remote run log reports `GATE PATH_ONLY` for smoke and timing. The smoke H3 RG row is `fit_success=true`, `fit_converged=false`, `interval_success=true`, `covered=true`. In the timing rows, all ten H3 RG intervals formed; nine of ten fits were nonconverged, and the reported boundary coverage was 4/5. These small, non-claim runs do not establish calibration.
- `shasum -a 256 docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-seeds.txt` matched the audit receipt hash `c35170cc047008835af7e854b54cf7b4f5a73a209b1401b7b067646782aa098c`. A numeric-line check found 2,000 unique seeds and no overlap with the 12 H3 RG seeds located in the registered worktree and Totoro outputs.
- `git status --short --branch` on the Totoro checkout showed unrelated untracked F0/F5 outputs. They were left untouched.
- `Rscript "/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R" docs/dev-log/source-review/2026-10-04-h3-totoro-results-audit.md` from this worktree passed the report-structure check, then failed closed because the old `.unlazy/auto-fa-rank-implementation-20261001/GATES.md` points to the absent `/private/tmp/hsquared-auto-fa-r-20261001` R checkout. The current acceptance ledger remains unreadable until that stale carried-over gate is reconciled.

No model fit, simulation, seed generation, package test, or campaign was run in this audit. The first local SSH attempt was denied by the sandbox; the read-only commands succeeded after approved access through the existing socket.

## 6. Tests of the Tests

No test code changed and no test suite was run for this audit. The result classification was cross-checked against the retained run log, summary rows, and replicate-level rows. The existing H3 audit harness tests are reported separately in `docs/dev-log/after-task/2026-10-04-h3-screen-preflight-contract.md`; they do not authenticate these Totoro outputs.

## 7a. Issue Ledger

- **Found:** seed `24270923` was already used by the earlier smoke and is also replicate 1 of the predeclared H3 stream. Exclude it from future H3 allocation and revise the allocation/predeclaration before any run that would otherwise reuse it.
- **Found:** ten further H3 RG timing attempts exist at seeds `95050029..95050033` and `95060036..95060040`. Preserve them in the historical exclusion inventory; do not use their results for coverage claims.
- **Still open:** current remote origin state, DRAC result stores, other remote historical stores, and seven unavailable internal turn-diff ref objects. H3 seed freshness remains unverified.

## 8. Consistency Audit

The local predeclaration at `docs/dev-log/recovery-checkpoints/2026-09-03-c1-ext-h1-h3-ademp-predeclaration.md` records master seed `20260903`, the same seed formula, a 48-replicate directional screen, and a separate confirmation that was not run in that slice. The remote run log matches the remote runner's commands and status. The #366 2,000-seed list is a distinct allocation. The R pre-registration `hsquared/docs/design/34-interval-recovery-pre-registration.md` was found by the supplemental read-only audit; it is not execution evidence.

The remote checkout is detached at the run's recorded commit and has unrelated untracked results. No capability status, public covered count, R bridge, or release evidence changes follow from this audit.

## 9. What Did Not Go Smoothly

The first SSH attempt was blocked by the filesystem/network sandbox despite the existing socket. The narrow read-only query succeeded after sandbox escalation. The first `closeout.py new` call used a relative path that resolved against the brain repository and was denied; it created no file there. Retrying with the explicit worktree path created this report. The hub `closeout.py check` still uses the brain repository as its root, so its embedded project check is not a valid HSquared check. The direct structural R check passed; its evidence gate then exposed the stale carried-over R path. The shared lease helper likewise required escalation to write its registry; the path-scoped grant was confirmed before editing.

## 10. Known Residuals

The accessible Totoro store has been checked only at the exact existing runner and output paths. This does not inventory every Totoro directory or any DRAC result store. The fresh origin query covered named Git heads only, not PR refs or remote job stores. Seven internal refs lack readable objects, and unrelated ignored stores were not globally descended. A stale nested automatic-FA ledger also prevents project evidence-gate verification because its R checkout path no longer exists. Therefore no fresh H3 seed allocation or execution is authorized by this audit, and no planned calibration gate passes.

## 11. Team Learning

Include the historical runner's actual output directory (`~/hsq_work/HSquared.jl/tmp/`) in seed-source audits; checking only `sim/drac/results` misses it. Classify runs from their complete receipts and gate marker; a `--mode=confirm` argument alone does not establish confirmation. The unresolved source inventory remains a hold.

Memory receipt: loaded the `HSquared.jl` LOAD-FIRST manifest and used its #366 priority and compute boundaries. `lane_preflight` identified three active non-overlapping leases. No external literature or sister implementation was scouted.

Golden Set: not run because no fitting or numerical-method change was in scope.

## 12. Cross-Product Coverage

Covers: read-only provenance and seed-exclusion evidence for the Julia H3 genetic-correlation screen stream.

Does NOT cover: fitted H3 calibration or confirmation, current remote seed freshness, the broader Julia or R H2 routes, R-Julia runtime parity, package checks, capability promotion, or release/publication status.

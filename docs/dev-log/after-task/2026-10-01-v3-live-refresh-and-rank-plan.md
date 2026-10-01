# V3 live reconciliation and automatic FA-rank plan

## 1. Goal

Reconcile the incoming 2026-10-01 handover with live GitHub, finish only the owed bounded V3 records, preserve other lanes, and prepare the next automatic FA-rank design and coordination plan.

## 2. Implemented

Verified that Julia PR #402 already merged at `570f49bab59cb337b06d32331bc4a14012164f3b`, with head `d7d50e9bd124666300d0ca577dfd9f8246f0484c`. Four Julia jobs and documentation passed on that head. Post-merge CI `36859311408` and Documenter `36859311323` passed at the merge SHA. Implementation PR #401 had already landed candidate `365f173f` through `829e86ce`; its four package jobs and Documenter also passed. Paired R PR #259 landed at `e82f5c95`, with R CMD check `36792219254` and pkgdown `36792696953` passing there.

Retained current GitHub JSON receipts, source/protection hashes, independent review and sibling contract records. Repaired the stale main phase snapshot and source-disposition introduction, and added a current roadmap pointer. Drafted the next design-only arc. No model source or tests changed.

## 3a. Decisions and Rejected Alternatives

V3 closure is limited to the approved fixed-rank Gaussian FA T4/K1 and Poisson-log genetic GLLVM T3/K2 routes, their reviewed bridge and ordinary landing. The covered count stays seven. Existing FA failures remain in the frozen 200-attempt campaign; no rerun or new threshold was introduced.

The next proposed arc resolves diagonal-versus-one-factor candidate meaning, likelihood/criterion, failed-candidate rules and conditional uncertainty before implementation. The GLLVM BIC site penalty and Binomial ridge do not become HSquared defaults. Rank zero with positive genetic uniqueness means a diagonal genetic covariance; a no-genetic-signal boundary needs its own witness.

## 4. Files Touched

`AGENTS.md`, `ROADMAP.md`, `GATES.md`, `docs/design/auto-fa-rank-follow-on.md`, the new `docs/design/auto-fa-rank-design-plan-20261001.md`, `docs/dev-log/phase-snapshot-archive.md`, `docs/dev-log/source-review/2026-09-30-final-integrated-source-dispositions.md`, `docs/dev-log/coordination-board.md`, `docs/dev-log/check-log.md`, this report, the final independent receipt, and `docs/dev-log/check-log.d/2026-10-01-v3-live-refresh/`. The old main snapshot was archived verbatim. The incoming handover remains preserved on its original `a10cafe0` ref.

## 5. Checks Run

Live read-only GitHub queries succeeded after sandbox network escalation. Retained commands, timestamps and results identify exact commits and runs. Independently recomputed source aggregate `59d4a803e4d290a840927b4bce26ea4722f4404c009c171d173ba0c300c7d76e` and runner `27b7adbfe0b1c8d397e9041710fe713410d6692d9ef8ebf50af4354a0429adf3`. Tracked source/test/Project diff from candidate `365f173f` is empty.

Fresh read-only artifact attestation passes all three modes: `HSQ_FINAL_JULIA_PASS`, `HSQ_FINAL_DOCS_PASS` and `HSQ_FINAL_R_BRIDGE_DOCS_PASS`. These validate retained successful runs and their source/environment/render pins; they execute no Julia or R fits. The numerical candidate retains its original ignored environment files. Matching ignored root and documentation Manifest snapshots were copied into the new documentation checkout for its own read-only V1/V2 attestation; no environment installation or build was run. The vanished R scratch checkout was replaced only for attestation by a temporary export of exact landed R commit `e82f5c95`, which matches every required source pin. Machine-readable attestation results are retained.

Documentation whitespace, prose and preamble checks pass. Task-local after-task structure and acceptance-ledger checks pass, with all 11 gates met; V1/V2 were reverified by artifact attestation. The shared closeout compiler still fails because it runs acceptance checking in the brain root instead of this task checkout. That separate root was not changed. Results and commands are retained in this task's verification receipt. No new numerical test, build or simulation was needed for documentation-only changes. Final independent audit is `docs/dev-log/source-review/2026-10-01-v3-live-refresh-independent.md`.

## 6. Tests of the Tests

The first R attestation refused because the old temporary candidate path no longer contained its source. Exporting the exact landed commit allowed its source pins to be checked without rewriting the checker or manifest. The existing checker has retained independent refusal controls; this task did not alter its oracle. Source equality was verified independently of the PR's green checks.

## 7a. Issue Ledger

V3 technical landing was already complete. The initial independent refresh found that the final hosted-landing audit had not been retained despite a closure claim. This task records that initial finding, current positive hosted evidence and the final independent receipt. Current status pointers now agree with the exact landed state. The final reviewer listed missing navigation/report files at its inspection time; these were then supplied and verified by the independent Luna mechanical receipt `mechanical-resolution.md`.

Automatic FA-rank contract tickets R0/C0/F0/B0 remain proposed design work. The design plan asks for approval of a 60 to 90 minute design-only arc. No implementation or scientific selection criterion was frozen here.

## 8. Consistency Audit

The initial reviewer confirmed source/test hashes and the documentation-only PR #402 delta. Current source and test files still match candidate `365f173f`. Both route statuses remain experimental; capability and validation-debt files are unchanged. The original candidate's two protected config changes and the main checkout's unrelated untracked paths were retained and rechecked against the recorded protection snapshot.

Actual read-only Luna scouts refreshed GLLVM and gllvmTMB under separate ownership. Julia main `7b2f1554` contains its selector. gllvmTMB PR #1337 merged only into protected `claude/lane-auto-d-r-20260926` at `0039fe737`, with an empty check array; main remains `0cf373d55`. Its lane simulation claims were reported as conditional records and were not independently reanalysed or transferred to HSquared.

## 9. What Did Not Go Smoothly

Default network access failed; scoped escalated reads succeeded. The already merged PR branch had been deleted, so fetching it failed; fetching main supplied the merged history. Worktree Git metadata required scoped write escalation. A prose check given relative paths initially looked in the brain root; the absolute-path rerun checked the actual files. The broad handoff gate reported unrelated unpushed refs and acceptance checks that had not been approved in the new checkout. The artifact oracles were read, then explicitly approved for this checkout and rerun. The initial compiler and handoff failures are retained; no other lane was altered to silence them.

## 10. Known Residuals

FA ordinary-start recovery, interval calibration and uniqueness-floor unit dependence remain recorded limitations. Broader families, missingness, genomic scaling, unusual inheritance, generic bridge production and automatic ranks remain separate. Local evidence attestation preserves the original environment scope; hosted checks establish only their tested OS/runtime matrix. The documentation branch is local and has no new hosted checks or publication approval.

CARRIED-OVER: `codex/h2-v3-refresh-auto-rank-plan-20261001`, documentation reconciliation and proposed design plan, pending any owner-approved publication. Resume in `/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl`; read this report and the design plan first. Do not rerun the campaign or edit protected siblings. The next design arc requires explicit approval. No push or merge was made for this documentation branch. Its local publication state is separate from the already-merged numerical programme.

## 11. Team Learning

Actual Luna medium scouts supplied sibling contract and protected-lane receipts. Actual Sol high independently reviewed V3 evidence and the plan, with one bounded follow-up. Role names were review lenses, not claims of additional agents. Native dispatch selected these models explicitly; no tiered CLI enforcement is claimed.

Memory receipt: the supplied operating contract, LOAD-FIRST manifest, Codex memory registry scope and brain search were read before sibling discovery. Brain search returned no task-specific automatic-rank decision. The existing follow-on note and fresh sibling receipts form the reusable repository record. Golden Set: no new fixture was required for a documentation-only reconciliation; no general numerical regression claim follows. No private memory files were edited.

## 12. Cross-Product Coverage

This task covers live Julia/R landing evidence, source-bound attestation, retained final independent closure audit, current-pointer repair and a proposed design-only automatic FA-rank arc. It does NOT cover new automatic-rank code, new R grammar, selection recovery, inference calibration, protected sibling promotion, GPU execution, releases, submissions, tags or any covered-status change. The plan is ready for owner review; it has not run.

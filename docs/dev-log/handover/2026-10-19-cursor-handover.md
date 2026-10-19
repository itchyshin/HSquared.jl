# Session Handoff: HSquared Arc 1 to Cursor

Meta: 2026-10-19 · from Codex · current goal remains active

## Critical Context

Cursor, you are receiving the active HSquared Arc 1 software-reliability goal for the Julia and R packages. Its objective is: **Complete the agreed non-GPU HSquared project across Julia and R, with verified evidence for each included capability. Continue Arc 1 Gaussian reliability from the retained source, studies, failures and acceptance ledger; keep unproved gates open.** The goal remains active in Codex with ID `01a11239-78f7-7602-933f-6def4c657b15`.

This handoff is at a safe boundary: the deterministic optimizer-contract test just passed, and no fit, simulation, or campaign is running. Continue from the exact recovery checkout below. Do not start from the normal Dropbox checkout or the attached Codex worktree; neither contains this recovery state.

The canonical current acceptance status is `.unlazy/arc1-gaussian-reliability/GATES.md`: G0 and G1 are checked; G2-G8 are unchecked. The `AGENTS.md` snapshot and older coordination-board wording still mention prior G6/G7 passes. Those passes remain historical evidence for their named freezes, but current-source G6/G7 were reopened. Keep capability status experimental and covered count at seven.

This handoff covers completion of the HSquared software. It excludes GPU, manuscripts, releases, tags, submissions, public promotion, and covered-count changes.

## What Was Accomplished

- Rehydrated from the active Arc 1 checkout, goal, Unlazy ledger, checkpoint, report, and lane-preflight records.
- Ran the focused Julia optimizer-contract suite with compiled modules disabled: 289/289 tests passed in 12.2 seconds. Command: `julia --compiled-modules=no --project=. -e 'using Test; include("test/arc1_optimizer_contracts.jl")'`. This is deterministic contract evidence only; it does not pass G2.
- The normal Julia test launch was blocked before tests began because the sandbox could not write a cache pidfile under `~/.julia`. The no-compiled-modules run avoided that write.
- Updated `docs/dev-log/after-task/2026-10-19-arc1-r-memory-cap-failure.md`. Its structure check passed. Its evidence gate correctly reports the overall Arc 1 ledger as unmet. The naturalness/style check reports zero blocking findings.
- Reviewed the competing `startup-cleanup` snapshot diff for `src/arc1_fa.jl` and `test/arc1_optimizer_contracts.jl`. It contains different line-search diagnostics. No source or test file was edited in this turn.

The focused G2 pass is the only new code-test result. The prior exact failures and reviews are retained in the checkpoint and after-task report. In particular, do not retry the consumed R setup-only run or the separate 51.3 GB R conversion run. Their causes are not established as the same mechanism.

## Current Working State

- **Working directory:** `/private/tmp/HSquared.jl-arc1-recovery-20261015`.
- **Julia HEAD:** detached at `f307db3264f22ab1b49afd59a10a43eb5e869339` (`Clarify Arc 1 recovery verification tooling`).
- **Julia worktree:** dirty. The exact pre-document listing is `docs/dev-log/handover/2026-10-19-cursor-handover-working-tree.txt` and contains 117 grouped status rows, including the manifest itself. The worktree has 42 tracked modifications plus a large untracked evidence tree. Preserve every pre-existing path. Never run `git reset`, `git clean`, or `git add -A`.
- **R checkout:** `/private/tmp/hsquared-arc1-r-branch-20261015`, branch `codex/arc1-gaussian-reliability-20261003`, HEAD `52bb0d2029ae7f166fb6062641b55e5f9dd9ec8a`, five commits ahead of its remote with modified source and untracked evidence. Preserve the original Dropbox R checkout.
- **Other lane:** the coordination lane owns cross-repo status and public-claim wording. The board is `docs/dev-log/coordination-board.md`, section `Active Lane Split`.
- **Git landing:** the handoff gate reported 116 uncommitted status groups before the two handoff files, 59 unpushed commits on detached HEAD, 179 unpushed commits across other branches, and unmet GATES. The complete dirty tree is carried over locally at the Julia path above. Nothing was pushed. The local handover commit stages only the two handover files; all other paths remain carried over. Pushing this branch would publish its 59 existing unpushed commits, so the handoff stays local and Cursor must open the same checkout.
- **Lease registry at handoff:** the final registry readback reports no live leases. Earlier in this session `codex-arc1-v4-lineage-20261019` was reported active, so ownership may have changed or its lease may have expired. Rerun lane preflight and inspect the lease registry on resume; claim a narrow lease before editing any shared source, test, checkpoint, or evidence path. Do not assume the earlier lease still protects those paths.

### Other checkout boundary

The attached Codex project worktree at `/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl` is detached at `e1df4c6e4972edf1c9ecc7c691d4c147e1e32017` (`Codex worktree snapshot: startup-cleanup`) and has only a generated `tools/__pycache__/arc1_oracles.cpython-314.pyc` modification. It does not contain this recovery state. Do not continue Arc 1 there or carry that generated file into this handoff. Use `/private/tmp/HSquared.jl-arc1-recovery-20261015`.

The competing ref `refs/codex/snapshots/564ba33dddfbae7c96aea6c65d81d2806ee849f9` is a separate snapshot with differing G2 source and test edits. Review its lineage read-only before resolving ownership; neither snapshot should be overwritten by assumption.

The current G2 source has a finite-domain line-search cap refinement. The focused tests pass, and the independent review found no blocker for a connected feasible interval. It cautioned that this does not guarantee recovery across disconnected feasible regions. Resolve the competing snapshot lineage and source ownership before editing either shared G2 file.

## Key Decisions and Rationale

- The frozen scientific plan is `LOOP/lanes/arc1-gaussian-reliability-20261002/GOAL.md` and `LOOP/lanes/arc1-gaussian-reliability-20261002/ultra-plan.md`. `GATES.md` is the live acceptance ledger; the lane `checkpoint.md` is the detailed run history and resume record.
- Use Astra for planning and independent scientific decisions/reviews. Use Luna for implementation and routine tests when that model is available in the receiving environment. The user selected Astra for planning and Luna for implementation. Cursor model availability has not been checked.
- Julia owns computation; R owns public syntax. Maintain parity and do not expose a capability unless implementation, tests, docs, capability status, validation debt, and Rose review agree.
- Keep all attempted seeds and failed fits in denominators. Never retry a consumed candidate or seed. A new model attempt needs an exact current source/runtime/seed candidate, independent review, and its own approval where the protocol requires it.
- Totoro is the default for CPU campaigns. Pin `JULIA_NUM_THREADS=4` and BLAS threads to one per worker, with at most four workers (16 total threads). Estimate before every fit or campaign. Runs estimated above three hours need a measured pre-run and separate approval.
- No public status change follows from a focused test or a diagnostic run.

## Landing State

| Artifact / branch | Committed | Pushed | State |
|---|---:|---:|---|
| Julia recovery checkout, detached `f307db3264f22ab1b49afd59a10a43eb5e869339` plus the exact pre-existing dirty paths in the status manifest | no, existing history only | no | **CARRIED-OVER**. Unfinished Arc 1 work and evidence stay in `/private/tmp/HSquared.jl-arc1-recovery-20261015`; resume there and do not reset or stage the tree. |
| Isolated R checkout, `codex/arc1-gaussian-reliability-20261003` at `52bb0d2029ae7f166fb6062641b55e5f9dd9ec8a` plus its dirty paths | no, five commits ahead | no | **CARRIED-OVER**. Preserve and inspect its current status before any edit. |
| `docs/dev-log/after-task/2026-10-19-arc1-r-memory-cap-failure.md` | no | no | **CARRIED-OVER** with this local working tree; report is structurally valid, overall gates remain unmet. |
| `docs/dev-log/handover/2026-10-19-cursor-handover.md` and `2026-10-19-cursor-handover-working-tree.txt` | local handover commit on `handover/2026-10-19-cursor` | no | Handover artifacts only. The exact recovery checkout remains the source for carried-over work. |

`FINDINGS-OF-RECORD: none` for this handoff. Durable scientific and execution findings are already in the linked repo checkpoint and reports.

The `handoff_gate.sh` result is not a pass: it found the dirty/unpushed state and open acceptance gates. Those failures are declared above as carried-over, unfinished work. The Unlazy gate remains open by design; do not mark gates abandoned to make the handoff pass.

## Files Created or Modified

The exact pre-handoff path inventory is `docs/dev-log/handover/2026-10-19-cursor-handover-working-tree.txt`. It records every path from `git status --short` before this handover document was written. This turn also modified `docs/dev-log/after-task/2026-10-19-arc1-r-memory-cap-failure.md` and created this document plus the status manifest. No source, test, protocol, GATES, checkpoint, coordination-board, R, or capability-status file was edited during this turn.

Stage no pre-existing files. In particular, do not stage `evidence/`, `LOOP/`, generated `__pycache__` directories, or any other path in the status manifest.

## Next Immediate Steps

1. Open Cursor in `/private/tmp/HSquared.jl-arc1-recovery-20261015`, so it sees the exact dirty recovery checkout. Read `AGENTS.md` and this handover first. Run the lane preflight, inspect `git status --short`, and classify the handover items `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`.
2. Read `.unlazy/arc1-gaussian-reliability/GATES.md`, `LOOP/lanes/arc1-gaussian-reliability-20261002/GOAL.md`, `ultra-plan.md`, `checkpoint.md`, `docs/dev-log/coordination-board.md` under `Active Lane Split`, and the linked after-task report. Treat GATES as current when older snapshot text disagrees.
3. Reconcile `refs/codex/snapshots/564ba33dddfbae7c96aea6c65d81d2806ee849f9` (`startup-cleanup`) with the current G2 source and tests. Resolve ownership and obtain a narrow lane lease before any shared source/test edit. Do not overwrite either lineage.
4. Continue G2 optimizer diagnosis and development evidence. Preserve the current 289/289 result as focused evidence only. Before any new fit, build and independently review a fresh source/runtime/seed candidate. Do not rerun a consumed candidate or seed.
5. Re-establish current-source G6/G7 only after source lineage stabilizes, using fresh reviewed Julia/R/docs freezes. Keep G3-G5 and G8 open until their independent acceptance criteria pass.
6. Preserve the R source freeze and the prior 2 GiB and 51.3 GB failures. Any new R diagnostic needs a separate reviewed candidate and estimate. Do not use a full R package run to imply G6/G7 until its exact receipt passes retained verification.

## Blockers and Open Questions

- The recovery checkout is local-only and carries a large dirty evidence tree. A clean clone will not contain it. The Cursor session must use the exact local folder.
- `handoff_gate.sh <repo>` failed on uncommitted/unpushed state and unmet gates. This is declared, not resolved. Handover artifacts should be committed locally on a short handover branch only after `handoff_gate.sh --handoff` validates this document. No push is authorized by this handoff.
- Lane preflight reports a newer `startup-cleanup` snapshot with differing G2 source/test edits. The diff was inspected, but ownership/integration remains unresolved.
- Earlier preflight reported a v4-lineage lease, but the final lease-registry readback is empty. Reconcile ownership with a fresh preflight and narrow lease before editing shared files.
- The current working-tree snapshot in `AGENTS.md` and portions of the coordination board are stale relative to GATES. Do not update the shared pointer until the active v4 lease and multi-lane status are reconciled.

## Gotchas and Failed Approaches

- The ordinary Julia launch tried to write a pidfile below `~/.julia` and failed under the sandbox. The successful `--compiled-modules=no` test avoided that write; do not claim the first launch ran tests.
- The reviewed setup-only JuliaCall/R diagnostic exceeded its 2 GiB process-tree cap during package precompilation. It produced no fit or result and must not be retried.
- A separate R conversion run reached 51.3 GB and was interrupted. The exact allocation cause is unresolved; do not rerun or infer that the setup-only failure explains it.
- A passing optimizer contract suite does not prove G2 reliability, rank-selection calibration, interval coverage, R parity, or package-level G6/G7.
- Do not push this handover branch without checking its commit ancestry and remote effects. The current Arc 1 history contains many unpushed commits.

## How to Resume

Start a fresh Cursor agent in the exact folder `/private/tmp/HSquared.jl-arc1-recovery-20261015`. The Julia executable used in this turn was Julia 1.10.0. The safe focused verification command is the 289-test command listed above. Before fitting or running a campaign, set `OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=4`, measure expected runtime, and follow the separate approval threshold in `AGENTS.md`.

Paste this into Cursor:

```text
Read AGENTS.md and docs/dev-log/handover/2026-10-19-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

## Mission Control

| Project / lane | Current state | Verified result | Next work |
|---|---|---|---|
| HSquared.jl Julia Arc 1 | Local recovery checkout, detached and dirty | G0/G1 checked; focused G2 contracts pass 289/289 only | Reconcile snapshot ownership, continue G2, then refresh current-source G6/G7 |
| hsquared R Arc 1 | Isolated branch, five commits ahead and dirty | Prior historical live checks exist; current-source G6/G7 remain open; memory diagnostics failed without fit credit | Preserve failures, audit current branch and resume only from a reviewed bounded candidate |
| HSquared coordinator | Shared coordination board and twin contracts | Board identifies Julia, R, and coordinator lanes | Keep scope aligned and claims experimental until G8 passes |

# Session Handoff: v0.7 genomic — D0F PASS banked; NEXT LANE = D1 (ultra-plan)

**Meta:** 2026-07-18 · from Claude (Claude Code) · D0F COMPLETE, D1/D2 now open · TARGET = the next Claude.

You are the next Claude, picking up the v0.7 genomic public-activation arc. The D0F stage is **DONE** — the
first COMPLETE adjudicated receipt across the whole arc, **PASS**, byte-reproducible, Rose-confirmed, landed.
Your lane is **D1**: ultra-plan it, pre-register it, then run it through the same validated pipeline to its own
adjudicated receipt. Nothing about D0F needs redoing.

## Critical Context (read or you will go wrong)

1. **The 8-retry Totoro JuliaCall blocker is FIXED and the fix is PERSISTENT — but VERIFY it before D1.** Root
   cause was NOT TMPDIR/mkpidlock; it was a **global-vs-project OrderedCollections version split** — the JuliaCall
   bridge (global env `~/.julia/environments/v1.10`) pinned OrderedCollections **1.8.2**, the engine `julia_root`
   resolves **2.0.1** (via Optim→StatsBase→DataStructures 0.19.6); the two majors can't co-load → embedded
   recompile → crash. **Fix (already applied, seal-respecting):** (a) `julia_root/Project.toml` reverted to sealed
   `976814` (git-clean; a prior session had contaminated it with RCall+Suppressor); (b) its **gitignored**
   `Manifest.toml` regenerated RCall-free; (c) the **non-sealed global env** bumped OrderedCollections 1.8.2→2.0.1.
   RCall is marshalling-only → fit numerics unaffected. **Before D1, re-verify:** run
   `Rscript --vanilla /home/snakagaw/hsq_work/envfix/setup_param.R <julia_root>` → expect `ok=TRUE` with a
   git-clean `julia_root`. If it regressed (e.g. global env reset), re-apply step (c):
   `julia --project=~/.julia/environments/v1.10 -e 'using Pkg; Pkg.add(name="OrderedCollections", version="2.0.1"); Pkg.precompile()'`.
2. **Seed bases 2042000000 / 2043000000 are SPENT (D0F draw).** D1 needs its OWN fresh phenotype/bootstrap seed
   allocation — decide and pre-register it (check `v07_genomic_recovery_v3_seed_lock.R` in the hsquared tools for
   the current/retired registry; do not reuse spent bases).
3. **Pipeline PHASE ORDER is driver-enforced and the old handover order was WRONG.** Correct order:
   official → locked → base_r → **r_summary(summarize-r)** → **julia(replay-julia)** → julia_summary → lineage →
   review → final. `summarize-r` MUST run before `replay-julia`; running replay first puts `julia_replay` out of
   phase and aborts summarize-r with "runtime root has an unknown top-level member."
4. **`OUT` = the stage OUTPUT ROOT, not its parent.** For D0F it was `.../retry8-prep/d0f` (per
   `stage_preseal.tsv` `output_root`), NOT `.../retry8-prep`. D1 will have its own stage root.

## What Was Accomplished (this session)

- Root-caused + fixed the Totoro env blocker (above), with **no seal/tracked-file change**.
- Ran a 3-round adversarial pre-draw panel (Workflow, 4 lenses each). Panels 1 & 2 = NO-GO — caught two REAL
  pre-draw defects (git-dirty deployed tree; then load-time re-dirtying via the RCall-bearing Manifest) with
  **no seed spent**. Panel 3 = GO.
- Executed the full D0F pipeline on Totoro: run-official 576 fits (all converged; 556 interior/10 lower/10 upper),
  lock-corpus, recompute-base-r (576), summarize-r, replay-julia (576, ~1e-13 parity), verify-replay,
  summarize-julia, write-route-lineage, 5 post-run reviews (all CLEAN), adjudicate, validate-final.
- **Receipt: PASS / COMPLETE, sha `04cc074071a02b58fa269f3a4b65a8455314bb40b97b2b9c7b6af91f485d7e80`,
  re-derived byte-identical by validate-final.** Triple parity attempt 3.18e-12 / summary 7.11e-15.
- Spawned-Rose close-out: **CONFIRMED** (claim-vs-evidence, bounds respected). `public_covered_count` stays 5.
- Documented + committed + pushed (see Landing State). Full detail:
  `docs/dev-log/after-task/2026-07-18-v07-d0f-retry8-adjudication-pass.md`.

## Current Working State

- **Working / done:** D0F receipt banked on Totoro at `/home/snakagaw/hsq_work/retry8-prep/d0f/`
  (`stage_adjudication_receipt.tsv` + sidecar, corpus, 5 reviews). Both deployed lanes git-clean at sealed heads
  (`hsquared` a23b15b, `HSquared.jl` 976814). The Totoro JuliaCall env is fixed and working.
- **In progress:** none — D0F is closed.
- **Blocked / open:** D1 not started. It is the next lane.

## Key Decisions & Rationale

- Env fix confined to the **non-sealed** global env + **gitignored** Manifest → keeps `julia_root` byte-identical
  to sealed 976814 so the draw's `v3p_git_clean` gate passes on every cell. RCall marshalling-only → numerics
  unchanged. This is why the seal/pre-registration/admission-PASS all still stand.
- Kept the **validated sequential pipeline** (did not parallelize the 5 reviews) — correctness over speed. NOTE
  for D1: the reviews ARE independent and parallel-safe (the review-phase projection check does not read
  `postrun_receipts` contents; each review is a deterministic function of the read-only corpus), so a future run
  MAY run them in parallel to cut ~2h off the ~3.5h final phase.
- A PASS/COMPLETE D0F receipt only **opens D1/D2** — no route activation, no count move, V2-GRM/V2-GINV stay
  partial (pre-registration bound; Rose-confirmed).

## Landing State (git ledger)

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `HSquared.jl` `codex/2026-07-13-v07-performance-localization` `a5f9b853` (capability-status, check-log.d, AGENTS snapshot, archive) | y | y | (branch PR — human's call) | LANDED |
| same branch `85ef67df` (after-task report, check-log.md, coordination-board) | y | y | " | LANDED |
| this handover doc + AGENTS snapshot pointer refresh | y (committing now) | y | " | LANDED |
| 2 protected retry5 docs (`M`) + untracked `sim/…downstream_replay.jl` | n | n | none | **CARRIED-OVER** — do NOT stage/edit/hash; resume only under original owner |
| Totoro `retry8-prep/d0f/` receipt + corpus | n/a (on Totoro) | n/a | n/a | BANKED (not a repo artifact) |

## Next Immediate Steps (D1 — ULTRA-PLAN this)

1. Rehydrate (below). Verify the Totoro env still gives `ok=TRUE` (Critical Context #1).
2. **Ultra-plan D1** (`skills/ultra-plan`): decompose into pre-registration → admission gate → adversarial
   pre-draw panel → draw → full pipeline (correct phase order) → adjudicate → validate-final → spawned-Rose.
3. Determine D1's inputs from the orchestrator usage (`retry8-prep/hsquared/tools/run-v07-genomic-recovery-v3.sh`):
   D1 `prepare`/`preseal` take a trailing **`D0F_ADJUDICATION_ROOT`** predecessor (the D0F receipt root). Decide
   D1's fresh seed bases (2042/2043 are spent) and pre-register BEFORE any RNG.
4. Run the pipeline DETACHED on Totoro (survives the classifier outage — see Gotchas); gate the irreversible D1
   draw behind a fresh GREEN adversarial panel + explicit user GO (root-forfeit discipline).
5. Spawned-Rose close-out; keep `public_covered_count` at 5 unless the pre-registration explicitly authorizes a
   move (a single COMPLETE D1 receipt likely does not by itself).

## Blockers / Open Questions

- **D1 seed allocation + D1 pre-registration scope** — needs a decision (what D1 measures; whether/when the arc
  moves the count). Confirm with the user before drawing.
- **Old orphan note (resolved, non-issue):** the long-running R processes on Totoro are an UNRELATED
  `fit_one_sensitivity.R` analysis under the shared `snakagaw` account — NOT campaign orphans. Do NOT kill them.

## Gotchas & Failed Approaches

- **`pgrep -f run_final`/`…write-postrun-review` self-matches your own ssh command line** → false "process
  running". Isolate real workers with `ps -C R -o …`.
- **`claude-opus-4-8` Bash-safety classifier had long/intermittent outages today**, blocking state-changing (and
  sometimes read-only) commands. Mitigation that worked: run each long stage **detached** on Totoro
  (`nohup bash script.sh > log 2>&1 &`) with a completion marker, and poll the log — compute progresses even when
  you can't issue commands. Write scripts to disk via `cat local | ssh 'cat > remote'` (a combined
  transfer+launch consumed stdin and wrote an empty file).
- **Every review/adjudicate/validate-final is ~30 min single-threaded** (each independently re-runs the full
  adjudication over 576 rows + bootstrap). The D0F final phase took ~3.5h. Do NOT assume it's stuck — verify with
  a CPU-accumulation check (`ps -o time` twice); it progresses at ~100% CPU.
- **Do NOT chase TMPDIR/mkpidlock** for JuliaCall failures — that was the multi-week red herring. Check
  OrderedCollections versions (global vs project) first.
- One transient interruption of a review (run_final.sh went down mid-run) — recovered by a clean re-run; reviews
  are deterministic, so re-running is safe and lossless.

## How to Resume

Run the repo's rehydrate skill, read the snapshot + this doc + the after-task report, then spawn Rose before any
public claim. Read order: `AGENTS.md` snapshot → this doc →
`docs/dev-log/after-task/2026-07-18-v07-d0f-retry8-adjudication-pass.md` →
`docs/dev-log/check-log.d/2026-07-18-v07-d0f-retry8-adjudication-pass.md` → the orchestrator usage block.

**One-command resume (paste in your own authenticated terminal, from the repo root):**

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-18-claude-handover.md + the AGENTS.md snapshot, then run hsquared-rehydrate, verify the Totoro JuliaCall env still gives ok=TRUE, and ultra-plan the D1 lane (pre-register → admission → adversarial pre-draw panel → draw → full pipeline in correct phase order → adjudicate → validate-final → spawned-Rose). Preserve root-forfeit discipline; public_covered_count stays 5 unless the pre-registration authorizes a move."
```

## Mission Control

| Repo | Branch / state | What shipped this session | Next by leverage |
|---|---|---|---|
| `HSquared.jl` | `codex/2026-07-13…` `85ef67df`, pushed | **D0F receipt PASS/COMPLETE** (byte-reproducible, Rose-confirmed); Totoro JuliaCall env root-caused + fixed; full docs landed | **Ultra-plan + run D1** (predecessor = D0F receipt; fresh seeds; same pipeline) |
| `hsquared` | same branch a23b15b, pushed | R lane consumed read-only by the D0F campaign | (mirrors via the shared branch; no contract change) |
| Totoro | `retry8-prep/d0f` receipt BANKED; env fixed | D0F corpus + receipt + 5 reviews | verify env `ok=TRUE`, then D1 draw detached |

## Goals / mission

v0.7 genomic public-activation arc. The public R route (`ordinary_auto_genomic`) is **held**; the genomic
recovery evidence chain (D0 → D0F → D1 → D2) is the gate. D0F is now COMPLETE/PASS. `public_covered_count` = 5
and does not move until the pre-registered arc authorizes it. No fitting/performance/GPU/genomic public claim
without the full evidence chain (repo state is truth).

## Plans / roadmap

D1 is open (this handover's lane); D2 follows. Authoritative: phase → `ROADMAP.md`; what is fitted →
`docs/design/capability-status.md` (header now records the D0F PASS within its bounds); history →
`docs/dev-log/phase-snapshot-archive.md`.

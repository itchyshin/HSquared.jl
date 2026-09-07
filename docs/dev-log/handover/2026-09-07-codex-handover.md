# Session Handoff: Path FULL 0.9 finish — Julia twin pointer (Cursor → Codex)

Meta: 2026-09-07 (Denver) · from Cursor (Claude, AUTHOR=claude) · TARGET=codex · owner
STOPPED the Cursor "Path FULL continuous" goal at this point.

**You are Codex, picking up the `HSquared.jl` (Julia engine) lane.** This doc is a **pointer**,
not the full narrative — the whole-campaign story (what Path FULL 0.9 is, why the pins are
0.8.0/count-7, the full ordered critical-path chain, and every receipt) lives in the R twin's
handover:

**Read first:** `hsquared/docs/dev-log/handover/2026-09-07-codex-handover.md` (sibling repo,
same Dropbox parent — `../hsquared/docs/dev-log/handover/2026-09-07-codex-handover.md` from
here). That doc also answers the "which repo does Codex run" question in full; the short
version: **one Codex session = one repo checkout.** R `hsquared` is the primary resume line
for this campaign; run this Julia lane as a **second Codex thread**, or switch checkouts by
hand after the R slice lands. Do not try to drive both repos from one session/context.

---

## What Julia still owes (this session's job)

Everything below is **CARRIED-OVER**, verified live via `gh`/`git` at handover time — not
invented from the scratch notes, which had gone stale by the time of writing (see the R
handover's Gotchas section for the general staleness warning; it applies here too).

1. **Julia FA/SS status honesty** — drafted, **not pushed, no PR**. Commit `2b1ad22` on
   `~/local-scratch/HSquared.jl-09-post191/`, branch `scratch/fa-ss-status-honesty` (3 files).
   Twin-aligns with the R FA/SS honesty draft (`0c02f57` in the R scratch clone) — R's version
   should land first (or in parallel) so the wording matches; neither is a covered flip, both
   are `engine-covered ≠ R-public-covered` fencing language only.
   - Resume: `cd ~/local-scratch/HSquared.jl-09-post191 && git fetch origin main && git rebase
     origin/main` (base was `b571184a` — Julia's `main` has not moved since, per live `gh`, so
     this should be a no-op rebase), then open a PR, wait for green CI, merge.
2. **Julia bridge production fences** — drafted, **not pushed, no PR**. Commit `d47aa3f` on
   the same scratch clone, branch `scratch/bridge-production-fences` (1 file). Twin-aligns with
   the R bridge-fences draft (`ef06f0e`).
3. **Merge Julia #313** ("Gate-6 Rose evidence mirror, not 0.9.0") — **OPEN, MERGEABLE, CLEAN,
   checks SUCCESS/SKIPPED, NOT merged.** Mirrors R #194's coordination-board refresh onto the
   Julia board. Re-verify CI is still green, then merge-when-green.
4. **Fresh local checks on live `main`** after the above land:
   ```sh
   julia --project=. -e 'using Pkg; Pkg.test()'
   julia --project=docs docs/make.jl
   bash tools/preamble_cap.sh
   ```
   Record exact commands and outcomes in `docs/dev-log/check-log.md` — the check-log tail on
   live `main` currently ends **2026-08-04**; there is no entry yet for today's #191/#192/
   Gate-6-Rose landing on the R twin, and Julia's own check-log needs a matching entry once
   #313 + the FA/SS + bridge-fences PRs land.
5. **After-task report** for this landing (mirrors the check-log entry), in
   `docs/dev-log/after-task/`.
6. **Do NOT authorize 0.9.0, bump `Project.toml`, tag, or flip any `capability-status.md` row
   from this Julia lane either.** Same hard fence as the R twin: version stays **0.8.0**, count
   stays **7**, next version after 0.9 is **0.10.x** not **1.0**.
7. **G10 hold on `V1-MATFREE-REML` stays in force** — owner paste banked at
   `~/local-scratch/receipts/g10/HOLD-V1-MATFREE-REML-2026-09-07.receipt` ("G10 no — hold
   V1-MATFREE-REML; the evidence packet is not sufficient for an experimental→covered flip").
   S5's frozen pre-declaration (`33ab68f6`) stays frozen; do not run it or promote it without a
   fresh owner G10 paste.

## Not this session's job (pre-existing, off critical path)

- **Julia #267** ("0.1 honesty engine: single-source ledger accessor…") — OPEN, but its CI
  checks show a **FAILURE** at handover time, and it predates this campaign
  (`feat/2026-07-09-v01-honesty-engine`). Isolated per the coordination board's own framing
  ("PR #267 honesty-engine remains isolated"). Leave it unless separately asked.
- **Julia #265** ("archive the superseded snapshot entry") — OPEN, chore, unrelated to Path
  FULL 0.9. Optional cleanup.
- **The Julia lane's "Live Phase Snapshot" block in `AGENTS.md`** has been refreshed as part of
  this same handover commit (see below) — you do not need to redo that.

## Standing drift found while refreshing the snapshot (flag to owner, do not silently fix)

`AGENTS.md`'s Live Phase Snapshot on live `main` had been stuck at a **2026-07-08** entry
(plotting/AlgebraOfGraphics migration, PR #264) since commit `e6bf8a17` (2026-07-12) — **almost
two months** of untouched pointer while `main` advanced through the entire Szymek arc, the
2026-08-04 G10/S5 saga, and the September #294–#313 stack, all via ordinary merged PRs that
never happened to touch this block. If you were expecting to find a 2026-08-04 "Szymek handed
the lane to Shinichi" entry here — **that narrative was never on `main`.** It exists only on
the abandoned branch `codex/2026-07-13-v07-performance-localization` (tip `853bcc12`, "hand the
lane to Szymek"), which was never merged and is the same foreign branch the Dropbox working
tree is currently, dirtily, checked out on (see Gotchas above). This handover archives the real
2026-07-08 `main` entry verbatim to `docs/dev-log/phase-snapshot-archive.md` and replaces it
with a fresh 2026-09-07 entry. **This is a finding, not a fix of the underlying cause** — the
process gap that let the snapshot go stale for two months (no PR touched it because no PR
author knew it existed / was theirs to update) is still open and worth a short standing-rule
fix (e.g. a lint step that fails a PR touching `docs/design/capability-status.md` without also
touching the snapshot date) — that is a process-improvement suggestion, not something this
handover implements.

## Landing State (Julia lane only — see R handover for the full twin ledger)

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| Julia #313 Gate-6 evidence mirror | y | y | [#313](https://github.com/itchyshin/HSquared.jl/pull/313) OPEN, CLEAN, checks green | **CARRIED-OVER** — merge-when-green owed |
| Julia FA/SS honesty (`2b1ad22`) | y (scratch clone) | **n** | none | **CARRIED-OVER** — resume: `cd ~/local-scratch/HSquared.jl-09-post191 && git checkout scratch/fa-ss-status-honesty` |
| Julia bridge production fences (`d47aa3f`) | y (scratch clone) | **n** | none | **CARRIED-OVER** — same clone, branch `scratch/bridge-production-fences` |
| Julia #267 (honesty-engine accessor) | y | y | [#267](https://github.com/itchyshin/HSquared.jl/pull/267) OPEN, CI FAILURE | **CARRIED-OVER (not this session's)** — pre-existing, isolated |
| Julia #265 (chore) | y | y | [#265](https://github.com/itchyshin/HSquared.jl/pull/265) OPEN | **CARRIED-OVER (not this session's)** — chore, optional |
| This handover doc + AGENTS.md snapshot refresh | committing now | pending this session | opening now | see Commit section below |
| Dropbox `HSquared.jl` foreign-branch debris (`codex/2026-07-13-…`) | n/a (pre-existing) | n/a | n/a | **CARRIED-OVER (not this session's to resolve)** — see Gotchas |

`main` tip verified live: `b571184a2b2d2d1275e82b2c3bfbfb7c05e90267` (unchanged since the
2026-09-05 board-status merge; no Julia-lane merges happened during today's continuous run —
all of today's landings were R-lane except #313, which is still open).

## Gotchas

- **Do not work inside the Dropbox `HSquared.jl` checkout directly without checking
  `git status --short --branch` first.** It is on `codex/2026-07-13-v07-performance-localization`
  with 3 uncommitted files (including an untracked `.claude/agents/shannon.md` and an untracked
  `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`) and ~6 unpushed sibling branches —
  smaller than the R twin's debris pile but the same class of pre-existing, unrelated leftover.
  This handover's own commit was made from a disposable worktree off `origin/main`
  (`~/local-scratch/HSquared.jl-codex-handover-2026-09-07`, branch
  `handover/2026-09-07-codex-handover`) to avoid touching it.
- **Re-verify PR/CI state with live `gh` before acting** — same warning as the R handover.
  The scratch notes under `~/local-scratch/h2-09-finish-*.md` were written earlier in the same
  day and some claims (e.g. "#191 OPEN") are already stale by the time you read this.
- **The Julia `main` tip did not move during the R-lane merges** (`b571184a` before and after
  #191/#192 landed on the R side) — this is expected; the two repos merge independently. Don't
  assume a Julia-side action happened just because the R side did.

## How to Resume

```sh
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
# AGENTS.md is native to Codex — it is read automatically; the Live Phase Snapshot
# block now points here.
git status --short --branch   # confirm you are NOT on the dirty foreign branch
git fetch origin main && git log --oneline -5 origin/main
gh pr list --state open
```

Live-toolchain checks Codex should run (once on a clean branch off `main`):

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
bash tools/preamble_cap.sh
```

Then work through "What Julia still owes" above, re-verifying `gh` state before every merge,
and coordinate with the R lane via the coordination board + the R handover doc — not by
editing both Dropbox trees in one session.

---

## Mission-control summary

| Repo | Branch/main | CI | What shipped today | Plan by leverage |
| --- | --- | --- | --- | --- |
| `HSquared.jl` (Julia, **this repo**) | `main` @ `b571184a` | Green on merged PRs | Nothing merged today on this lane; #313 open/clean | Merge #313, then FA/SS honesty + bridge fences, then `Pkg.test()`/`docs/make.jl`/`preamble_cap.sh` + check-log/after-task |
| `hsquared` (R, sibling — full narrative) | `main` @ `fc7230c2` | Green on merged PRs | Layer B honesty (#191, #192) merged; #193/#194 open/clean | See `hsquared/docs/dev-log/handover/2026-09-07-codex-handover.md` |

**Both twins:** version **0.8.0**, `public_covered_count` **7**, **0.9.0 NOT authorized**, next
version after 0.9 is **0.10.x**, not **1.0**. No Registrator/CRAN.

Made with Cursor (Claude, Sonnet 5) · handed to Codex.

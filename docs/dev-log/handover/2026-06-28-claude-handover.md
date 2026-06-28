# Session Handoff: session-handover tooling + autonomous-resume + the live Codex interval branch
Meta: 2026-06-28 · from Claude Code · same-platform (Claude → Claude)

**You are the next Claude session.** Repository state is truth; this is the map. Most of this
session was *meta* work (building handover tooling) — the HSquared.jl/hsquared **program** is
unchanged since #190/#112. Read **Critical Context** first.

---

## Critical Context (read or it will go wrong)
1. **Codex is live in HSquared.jl on branch `codex/small-sample-interval-calibration`** — 2 commits
   on top of main #190 (`d7effc79 docs: bank small-sample interval calibration debt`,
   `6581828f sim: make interval calibration harness resumable`). This is Codex acting on the
   t-calibration finding surfaced this session. **Do NOT disturb that branch or commit onto it;
   coordinate.** `main` is `5f378a8d` (#190). This handover was committed from an isolated **git
   worktree** off main so the Codex checkout was never touched — do the same if you must commit
   while Codex holds the working tree.
2. **`~/.claude/settings.json` gained a scoped `permissions` block this session** (NEW): `allow`
   = Read/Edit/Write + read-only git (`git status/diff/log/show/branch`); `deny` = `git push`,
   `gh pr merge`, `rm`. It is **global** — it changes *every* session now (file edits no longer
   prompt; `rm`/push/merge are hard-denied, which can block your own commands — that is why a
   `rm -rf` failed this session).
3. **Two foreign untracked files in HSquared.jl — NEVER commit them**:
   `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`,
   `sim/phase6_nongaussian_interval_coverage.tsv`. Stage explicit paths.

## Goals / Mission
- **Primary (unchanged):** finish the twin packages — `HSquared.jl` (engine) + `hsquared` (R).
  Covered = v0.1 univariate Gaussian only; nothing promoted without the full evidence chain.
- **Emergent this session:** smooth, **lossless session handovers** in both directions
  (Claude↔Codex) — now built as skills (below).

## Plans / Roadmap
- Engine: Track B GPU (G1 Float32 → G2–G5), **external-comparator evidence** (the only gate to a
  covered promotion), and **small-sample t-calibration for intervals** — Codex is on it now.
- Handover tooling: verify the Codex side loads the prompts; optional conclusive autonomous-resume
  re-test; clean up the smoke-test artifacts.

## What Was Accomplished (this session)
- **Earlier (all merged):** D `preconditioner=:ichol` (#188), R-twin `em_warmup` parity (#111),
  greened hsquared CI (#112, the non-ASCII em-dash), Codex handover (#190). See the
  `2026-06-24-*-handover.md` docs for that detail.
- **Built 4 session-handover skills + 1 shared protocol** (generalisable; GREEN-tested on a
  *drmTMB* mock, so it does not hardcode this program):
  - Claude (auto-trigger by description **or** `/name`): `~/.agents/skills/handover-to-claude/`,
    `~/.agents/skills/handover-to-codex/` (symlinked into `~/.claude/skills/`).
  - Codex (manual `/name` only): `~/.codex/prompts/handover-to-claude.md`, `handover-to-codex.md`.
  - Shared op protocol: `~/shinichi-brain/protocols/handover-skill.md` (extends the existing
    `~/shinichi-brain/protocols/handoff.md` template). **This doc was produced by that skill.**
- **One-command resume** (protocol Step 5b) + **scheduled autonomous resume** (Step 5c):
  prototyped + TESTED. A scheduled task fires, authenticates (in-app, unlike a sandboxed
  `claude -p` which **401s**), spawns a fresh session, reads the handover doc — but **pauses at the
  first permission prompt** unattended. The §Critical-Context-2 permissions block is the fix.
- **t-calibration finding:** HSquared.jl intervals are **all asymptotic** — normal-z Wald/delta +
  χ²₁ profile (`q = z*z`, `src/likelihood.jl:1491`); no `qt`/df anywhere; the parametric bootstrap
  (C6) is the only finite-sample path. Codex is implementing this on its branch.
- This handover doc + the `AGENTS.md` snapshot bullet (this commit).

## Current Working State
- **Working:** both repos green — HSquared.jl `main` #190, hsquared `main` #112. The 4 handover
  skills installed + loaded (Claude side verified; Codex side **placed but unverified-by-launch**).
  `~/.claude/settings.json` is valid (JSON checked).
- **In progress (Codex, not me):** `codex/small-sample-interval-calibration` (+2 commits) — not yet
  PR'd to main as far as I can see.
- **Open / not done:**
  - Codex prompt discovery UNVERIFIED — couldn't launch `codex` here (it's the plugin runtime, not
    a PATH CLI). A verification message was drafted for the user to paste into a Codex session.
  - The `/handover-*` skills don't appear in the Claude `/` menu until a **restart** (the menu is
    built at startup); they DO auto-trigger by description and are invocable now.
  - Autonomous resume proven only up to the permission gate; the conclusive re-test (now that
    writes are allowed) is OPTIONAL/pending.
  - Smoke-test artifacts still present (cleanup-pending):
    `~/.claude/scheduled-tasks/resume-smoke-test` + `~/.claude/scheduled-tasks/_resume-smoke`.

## Key Decisions & Rationale
- Handover skills: **global** (reusable across repos), 4 thin entry points over **1 shared
  protocol** (DRY), widget **optional** (the markdown table always lives in the doc; the widget is
  ephemeral chat).
- Permissions: scoped allow-list, **global**, push/merge/rm denied — an autonomous resume can do
  work but nothing irreversible/outward. `git add`/`git commit` deliberately NOT allowed (still
  prompt), so a fully-unattended resume that commits would still pause — extend only on request.
- This handover committed via a **worktree off main** (not Codex's branch, not main directly).

## Files Created / Modified (every path)
- Global tooling (NEW): `~/.agents/skills/handover-to-claude/SKILL.md`,
  `~/.agents/skills/handover-to-codex/SKILL.md`, `~/.codex/prompts/handover-to-claude.md`,
  `~/.codex/prompts/handover-to-codex.md`, `~/shinichi-brain/protocols/handover-skill.md`;
  symlinks `~/.claude/skills/handover-to-{claude,codex}`.
- Config (MODIFIED): `~/.claude/settings.json` (added `permissions`).
- This commit (branch `handover/2026-06-28-claude`): `docs/dev-log/handover/2026-06-28-claude-handover.md`
  (new) + `AGENTS.md` (snapshot bullet).
- NOT mine — leave alone: `shinichi-brain/memory/LEARNINGS.md` (user/linter-edited); the 2 foreign
  untracked files (Critical Context 3).

## Next Immediate Steps
1. **Verify the Codex side** — the user is pasting the drafted verification message into a Codex
   session; fix whatever it reports (wrong dir/format, or a Claude-only assumption).
2. **Coordinate with Codex** on `codex/small-sample-interval-calibration` (the t-calibration work);
   when its PR lands, review with the Fisher + Curie + Mrode + Rose lenses.
3. (Optional) Conclusive autonomous-resume re-test now writes are allowed → then clean up the
   smoke-test task + fixtures.
4. (Optional) Restart Claude Code so `/handover-*` show in the `/` menu.
5. Resume the engine roadmap (Track B GPU / external comparators) per `AGENTS.md`.

## Blockers / Open Questions
- Does Codex actually auto-discover `~/.codex/prompts/*.md`? (unverified.)
- Add `git add`/`git commit` to the allow-list so a fully-autonomous resume can commit-on-a-branch
  (push stays denied)? — user's call.

## Gotchas & Failed Approaches
- A sandboxed `claude -p` child **401s** (no auth propagation) — you cannot fork an authed session
  from inside one. Use the in-app scheduler, or the one-command resume in the user's terminal.
- The scheduler wall-clock skews ~minutes from Bash `date` — trust the scheduler's clock for `fireAt`.
- `Bash(rm *)` is now globally denied — your own `rm` commands will be blocked; use alternatives.
- Don't commit onto Codex's live branch; don't touch the 2 foreign untracked files.

## How to Resume (pasteable, from the HSquared.jl repo root)
```sh
# Read order: this doc → AGENTS.md snapshot → the Codex interval branch → AGENTS.md doc set
git -C "/Users/z3437171/Dropbox/Github Local/HSquared.jl" log --oneline -3 codex/small-sample-interval-calibration
```
Run the `hsquared-rehydrate` skill, read the `AGENTS.md` snapshot + this doc, and spawn **Rose**
before any public claim. One-command resume (your authenticated terminal, repo root):
```sh
claude "Rehydrate from docs/dev-log/handover/2026-06-28-claude-handover.md and the AGENTS.md snapshot, then continue: verify the Codex-side handover prompts and coordinate on the codex/small-sample-interval-calibration branch."
# autonomous variant: claude -p "<same prompt>" --max-budget-usd 2
```

## Mission control
| repo | branch | CI | shipped this session | next |
| --- | --- | --- | --- | --- |
| HSquared.jl | `main` `5f378a8d` (#190); Codex on `codex/small-sample-interval-calibration` (+2) | green | (program unchanged) — interval finding handed to Codex | review Codex's interval PR; Track B GPU; external comparators |
| hsquared | `main` `8c5c886` (#112) | green | (unchanged) | — |
| tooling (global) | n/a | — | 4 handover skills + protocol; one-command + scheduled resume; permissions allow-list | verify Codex side; cleanup smoke test |

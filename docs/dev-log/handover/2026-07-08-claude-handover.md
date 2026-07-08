# Session Handoff: AoG plotting-layer migration — recovered, fixed, VERIFIED, awaiting merge

**Meta:** 2026-07-08 · from **Claude** (Opus 4.8) · to **Claude** (fresh session)
**Repos touched:** `HSquared.jl` (Julia lane) · `hsquared` (R lane — **untouched, clean**)
**Branch:** `feat/2026-07-08-plotting-aog` · base `main` @ `a2fc7625`
**Commits:** `fe93273c` → `5ebd7119` → `e6f27ac8`

You are Claude, picking up a finished-but-unmerged slice. The work is **done and verified**.
What remains is a merge decision and two follow-ups the maintainer may or may not want.

---

## Critical Context

**Two things, or you will waste the session:**

1. **`julia` is NOT on the default `PATH` in a Claude Code shell.** It lives at
   `~/.juliaup/bin/julia`. Earlier in this session I concluded "cannot verify, hand it to
   Codex" — that was **wrong**, and it produced a whole handover doc built on a false premise
   (now superseded). Before you ever declare a toolchain unavailable:
   `ls ~/.juliaup/bin/julia`, `ls /Applications/Julia*.app`. `export PATH="$HOME/.juliaup/bin:$PATH"`
   and Julia works fine from this environment, including `Pkg.test()` and CairoMakie rasterization.

2. **A green `Pkg.test()` is ZERO evidence about the plotting layer.** The stub test asserts
   `isempty(methods(hsquared_figure))` with Makie/AoG deliberately out of CI — so it passes
   **precisely when the extension fails to load**. Four real defects lived in this code while CI
   was green. **Three of the four were also invisible to plot-object assertions** and surfaced
   only when the figure was rendered to PNG and *looked at*. If you touch the drawing layer,
   render it and look.

---

## What Was Accomplished

Five plotting files had sat uncommitted for two days (mtime 2026-07-06) — an **unfinished
mid-conversion** of `HSquaredMakieExt` to AlgebraOfGraphics, never committed on any ref
(`git log --all -S "AlgebraOfGraphics"` was empty), with no check-log, no after-task report.

Four defect classes found and fixed, then verified live:

| # | Defect | Caught by | Fix |
| --- | --- | --- | --- |
| 1 | Every marker drawn **twice** — AoG's `visual(Scatter,…)` draws the points, then a manual `scatter!` re-drew them to restore z-order after the whiskers overpainted | reading | AoG owns the single marker layer; whiskers pushed behind with `translate!(w,0,0,-1)` |
| 2 | `_axes_by_panel` pattern-matched `Label`s out of `fig.content` and index-zipped to axes (two undocumented internals) | reading | AoG's supported `FigureGrid.grid` accessor + shape guard |
| 3 | Full term list forced onto **every** facet's yticks | reading | per-facet ticks |
| 4 | Title/subtitle **once per facet**; `ylabel="rank"` leaked the mapped variable; x/y scales **linked across facets** (h² on `[0,1]` crushed against a `0–40` variance scale); `[0,1] boundary` annotation **clipped** at the data limit | **rendering the PNG and looking** | figure-level title; `ylabel=""`; `facet=(; linkxaxes=:none, linkyaxes=:none)`; `xautolimitmargin` bump on annotated axes only |

**Verification (all green, one machine):**

- Compat pin **resolves**: `AlgebraOfGraphics v0.13.0` + `Makie v0.24.13` + `CairoMakie v0.15.13`, Julia 1.10.0.
- `HSquared → HSquaredMakieExt` **precompiles and loads**.
- **9/9** kinds draw a `Makie.Figure`, explicit *and* inferred `kind`.
- On the drawn object: `Scatter=1` per axis (no double-draw); `NaN` whisker draws nothing; whisker `z = -1.0`; `[0,1]` boundary `Text=1` on the h² axis, `Text=0` on the variance axis; **control payload** (h² strictly inside `[0,1]`) draws no annotation and no headroom bump.
- The **facet-order assumption HOLDS** on AoG 0.13.0: `grid[1,1]` = `"heritability"`, `grid[2,1]` = `"variance components"`.
- Both AoG figures **rasterize** to PNG and were visually inspected.
- `Pkg.test()` **green** dependency-free; CI posture unchanged.

Evidence: `docs/dev-log/check-log.d/2026-07-08-plotting-aog.md`.

---

## Current Working State

- **Working:** everything on the branch. Verified against a live draw.
- **In progress:** nothing.
- **Blocked:** nothing.
- **Awaiting:** a maintainer merge decision (see Next Steps), and an after-task report.

---

## Landing State ledger

| Repo | Branch | State |
| --- | --- | --- |
| `hsquared` | `main` | **CLEAN**, synced with `origin/main`. Not touched this session. |
| `HSquared.jl` | `main` | **UNTOUCHED** @ `a2fc7625`. |
| `HSquared.jl` | `feat/2026-07-08-plotting-aog` | 3 commits, **pushed**, PR open. **CARRIED-OVER: not merged** — awaiting maintainer merge + after-task report. |

Pre-existing unpushed state in `HSquared.jl`, **not from this session, not mine to land**:
`claude/kind-kirch-b8bbee` (ahead 1), `feat/2026-06-30-v04-broaderdgp-recovery` (ahead 12),
`feat/2026-07-01-v06-ordinal-liability-h2` (ahead 3), plus several local-only `worktree-agent-*`
and `claude/*` branches. Flagged, deliberately untouched.

---

## Key Decisions & Rationale

- **Did not merge to `main`.** The slice is verified, but the Definition of Done also wants a Rose
  audit and an after-task report, and `handoff.md` says the human merges. PR opened, not merged.
- **Did not revert the AoG migration** despite it being marginal for `_forest` (see Open Questions).
  Re-architecting was never the mandate.
- **Superseded rather than deleted** the earlier `2026-07-08-codex-handover.md`. It was written on a
  false premise; deleting it would erase the record of the mistake. It carries a SUPERSEDED banner.
- **Wrote evidence to `check-log.d/`, not `check-log.md`** — the latter is frozen as of 2026-06-19.

---

## Files Created / Modified

Branch `feat/2026-07-08-plotting-aog`:

- `Project.toml` — `AlgebraOfGraphics` in `[weakdeps]`/`[compat]` (`"0.13"`); `HSquaredMakieExt = ["AlgebraOfGraphics", "Makie"]`
- `ext/HSquaredMakieExt.jl` — `_forest`, `_caterpillar`, `_axes_by_panel` rewritten; `_aog_axes` removed
- `src/plotting_ext.jl` — docstring: extension needs Makie **and** AoG
- `test/runtests.jl` — stub-test comments updated
- `docs/design/13-plotting-layer.md` — AoG described; verification + CI-blind-spot note recorded
- `docs/dev-log/check-log.d/2026-07-08-plotting-aog.md` — **new**, the evidence
- `docs/dev-log/handover/2026-07-08-codex-handover.md` — **new**, then SUPERSEDED
- `docs/dev-log/handover/2026-07-08-claude-handover.md` — **new**, this file
- `AGENTS.md` — Live Phase Snapshot bullet

---

## Next Immediate Steps

1. **Rose audit** (`.claude/agents/rose-systems-auditor.md`) on the public-claim surface. Nothing
   is promoted, so this should be short: confirm `public_covered_count` **5**, rows **55**, covered
   **13** are unchanged, and that `13-plotting-layer.md` claims exactly what the check-log shows.
2. **After-task report** → `docs/dev-log/after-task/2026-07-08-plotting-aog.md` (11 sections;
   validate with `tools/check-after-task.R`). This is the last open Definition-of-Done item.
3. **Merge the PR** (maintainer's call), then update the coordination board.
4. *(Optional, worth raising)* **Strengthen the stub test.** Today it is satisfied by the extension
   *failing to load*. A cheap opt-in job — `CairoMakie` + AoG behind an env flag, off by default —
   would turn a whole class of silent breakage into a red build. Cost-discipline tradeoff.

---

## Blockers / Open Questions

- **OPEN — is AoG earning its place in `_forest`?** After the migration the function still draws
  whiskers, ticks, vlines and the boundary annotation by hand, unlinks both facet scales, blanks the
  ylabel, and reaches into `fg.grid` for the axes. AoG contributes faceting and one `Scatter`. A raw
  Makie `Figure` with two `Axis`es would be simpler and would drop both the compat pin and the
  facet-order assumption. `_caterpillar` (single axis, no faceting) is genuinely clean under AoG.
  **Maintainer's call — I deliberately did not answer it.**
- **OPEN — version fragility.** `_axes_by_panel` assumes facet rows lay out in `sort(unique(panels))`
  order. Confirmed empirically on AoG 0.13.0; the shape guard catches a facet-*count* mismatch but
  **not a re-ordering**. On any AoG bump, re-render the forest and check the ticks. CI will not.
- **NOTE — lane discipline.** `hsquared/CLAUDE.md` assigns `HSquared.jl` to the Julia lane; this work
  was done from an R-lane session on explicit maintainer instruction. The coordination board was
  **not** updated — do that if the branch merges.
- **NOTE — verified on one machine, one version set** (Julia 1.10.0, macOS/arm64). Not a
  cross-version or cross-platform claim.

---

## Gotchas & Failed Approaches

- **Do not conclude "no Julia" from `which julia`.** It is not on `PATH`; it exists. This cost a
  whole handover doc.
- **Do not "simplify" the double-scatter by deleting the manual `scatter!` alone.** The original order
  was `AoG scatter → whiskers → manual scatter`; the second scatter put markers back on top. Deleting
  it without the `translate!` leaves whiskers painted over markers.
- **Do not restore `_axes_by_panel`'s label-matching.** `String(t.text[])` on a Makie `Label` is not
  robust, and `fig.content` ordering is not part of AoG's API.
- **`axis = (; title = …)` in `draw()` applies to EVERY facet axis.** Figure-level title/subtitle must
  go in `figure = (; title = …, subtitle = …)`.
- **Text extent does not enter Makie's autolimits**, so an annotation anchored at a data limit clips.
- **Do not append to `docs/dev-log/check-log.md`** — frozen 2026-06-19. Use `check-log.d/`.
- **`d.panel` holds plain `String`s** (`src/likelihood.jl:2658`). There is no Symbol-comparison bug;
  don't go hunting for one.

---

## Mission control

| Item | State |
| --- | --- |
| `hsquared` (R lane) | `main` clean, synced. Untouched. |
| `HSquared.jl` `main` | `a2fc7625` — untouched, green |
| Branch | `feat/2026-07-08-plotting-aog` (3 commits) — **pushed, PR open, NOT merged** |
| Shipped | drawing layer only: AoG migration, 4 defect classes fixed, verified live |
| Verification | AoG 0.13.0 + Makie 0.24.13 + CairoMakie 0.15.13 · 9/9 kinds draw · `Pkg.test()` green |
| Coverage | `public_covered_count` **5** · rows **55** · covered **13** — ALL UNCHANGED |
| Highest leverage | Rose audit + after-task report → merge |
| Second | decide whether AoG earns its place in `_forest` |
| Watch | facet-order assumption on any AoG version bump |

---

## How to Resume

```sh
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
git checkout feat/2026-07-08-plotting-aog
export PATH="$HOME/.juliaup/bin:$PATH"      # julia is NOT on the default PATH
```

Re-run the verification any time (takes ~2 min after the first precompile):

```sh
julia --project=. -e 'import Pkg; Pkg.test()'          # dependency-free; proves nothing about drawing
# live draw (the only thing that proves the drawing layer):
#   Pkg.develop the repo into a scratch env, Pkg.add CairoMakie + AlgebraOfGraphics,
#   then hsquared_figure(payload; kind = …) for all nine kinds and SAVE A PNG AND LOOK AT IT.
```

Read in this order:

1. `AGENTS.md` — Live Phase Snapshot (top bullet)
2. **this file**
3. `docs/dev-log/check-log.d/2026-07-08-plotting-aog.md` — the evidence
4. `ext/HSquaredMakieExt.jl` — `_forest`, `_caterpillar`, `_axes_by_panel`
5. `docs/design/13-plotting-layer.md` — the claim surface

One-command resume (paste in your own authenticated terminal, from the repo root):

```
claude "Rehydrate from docs/dev-log/handover/2026-07-08-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps: Rose audit, after-task report, then propose the merge. Note julia is at ~/.juliaup/bin, not on PATH, and a green Pkg.test() proves nothing about the drawing layer."
```

**Routing.** This is now planning/audit/prose work — Claude's lane. Nothing here needs Codex: the
live toolchain ran fine from Claude Code once `PATH` was set.

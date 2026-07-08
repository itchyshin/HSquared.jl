> ## ⚠️ SUPERSEDED — do not action this document
>
> Written earlier the same day on the false premise that the live Julia toolchain was
> unavailable. **It was available** (`~/.juliaup/bin/julia`, simply not on `PATH`). The nine-kind
> `CairoMakie + AlgebraOfGraphics` draw this document hands to Codex **has since been run and
> passed**, the compat pin resolves, and a fourth defect class was found and fixed.
>
> **Treat the ENTIRE body below as historical fiction, not repo state.** In particular these are
> all now FALSE: "NOT PUSHED" / "local only" (the branch is pushed, PR #264 open); "Nothing has
> ever been run" and "reviewed not tested" (the nine-kind live draw passed); "three defects"
> (there are four); "UNVERIFIED"; every "BLOCKER"; "Codex owns the live draw"; and every
> reference to a "RE-VERIFICATION OWED" banner in `docs/design/13-plotting-layer.md` (that banner
> was removed once the draw passed; the phrase now survives only in this file and in the two
> documents that describe its removal). Kept for the audit trail only.
> **Do not follow the "Next Immediate Steps" or the "How to Resume" prompt below.**
>
> **Current handover:** `docs/dev-log/handover/2026-07-08-claude-handover.md`
> **Evidence:** `docs/dev-log/check-log.d/2026-07-08-plotting-aog.md`
> **Driver:** `docs/dev-log/scripts/2026-07-08-plotting-aog-livedraw.jl`

# [SUPERSEDED] Session Handoff: AlgebraOfGraphics plotting-layer migration — fixed, UNVERIFIED, needs a live draw

**Meta:** 2026-07-08 · from **Claude** (Opus 4.8, R-lane session in the `hsquared` twin) · to **Codex**
**Branch:** `feat/2026-07-08-plotting-aog` (local only — **NOT PUSHED**) · base `main` @ `a2fc7625`
**Work commit:** `fe93273c`

You are Codex, picking up an AlgebraOfGraphics migration of the `HSquaredMakieExt` drawing
layer. The code is written and three real defects are fixed. **Nothing has ever been run.**
Your job is the live draw, the evidence, and the merge decision.

---

## Critical Context

**Two things, or this goes wrong:**

1. **The test suite cannot validate this work.** `test/runtests.jl` asserts
   `isempty(methods(hsquared_figure))` with Makie/AoG deliberately kept out of CI (cost
   discipline). That assertion **passes precisely when the extension fails to load**. A green
   `Pkg.test()` is therefore *zero evidence* that the AoG extension loads, resolves, or draws
   correctly. Do not read CI green as validation here.

2. **`AlgebraOfGraphics` has never existed on any ref.** `git log --all -S "AlgebraOfGraphics"`
   returned nothing before this branch. There is no Manifest, no check-log entry, no after-task
   report, no `docs/dev-log/` mention. `AlgebraOfGraphics = "0.13"` against `Makie = "0.24"` is
   an **unverified compat pin**.

---

## What Was Accomplished

The five files had sat uncommitted in the working tree for two days (mtime 2026-07-06 05:36–05:42).
They were an **unfinished mid-conversion**, not finished work awaiting a commit.

Reviewed by reading (no execution possible — see Blockers). Three defects found and fixed:

| # | Defect | Fix |
| --- | --- | --- |
| 1 | **Every marker drawn twice.** AoG's `visual(Scatter, …)` already draws the points; the manual `scatter!` that followed re-drew them — it was restoring z-order after the whiskers overpainted the markers, not pure redundancy. | AoG now owns the **single** marker layer; whiskers are pushed behind with `translate!(w, 0, 0, -1)`. Applied to both `_forest` and `_caterpillar`. |
| 2 | **`_axes_by_panel` reached into internals.** It scanned `fig.content` for `Label`s whose text matched a panel name, then zipped `labels[i] => axes[i]` **by position** — depending on both AoG's facet-label rendering and `fig.content` ordering. Could throw `ArgumentError` at draw time. | Replaced with AoG's **supported** `FigureGrid.grid` accessor (`Matrix{AxisEntries}`, each carrying `.axis`), plus a facet-grid shape guard. `_aog_axes` was orphaned by this and removed. |
| 3 | **Full term list forced onto every facet's yticks.** `ys = n:-1:1` ranks *all* terms across both panels; `ax.yticks[] = (ys, string.(d.term))` was applied to every axis, so each panel labelled terms it does not contain. On an honest-status figure. | Per-facet ticks: `idx = sort(findall(==(panel), panels); by = i -> ys[i])`, then `(ys[idx], terms[idx])`. |

Also added a **RE-VERIFICATION OWED** banner to `docs/design/13-plotting-layer.md`. The diff
had silently upgraded that doc to claim "AoG-backed" figures and "Makie/AoG" verification of all
nine kinds — but the recorded verification was run **2026-06-22 against raw Makie**. Landing that
claim with no evidence is exactly what Rose blocks.

**Checked and found NOT a bug:** `d.panel` is `["variance components", "variance components",
"heritability"]` (plain `String`s, `src/likelihood.jl:2658`), so the pre-existing
`d.panel[i] == "heritability"` comparison was sound. The stringification in the rewrite is a
no-op there, not a fix. Don't go looking for a Symbol-comparison bug; there isn't one.

---

## Current Working State

- **Working:** nothing new can be asserted to work. `main` @ `a2fc7625` is untouched and green.
- **In progress:** `feat/2026-07-08-plotting-aog` @ `fe93273c` — AoG migration, defects fixed, **unverified**.
- **Blocked:** the nine-kind live draw. `julia` is not on `PATH` in the authoring environment.

---

## Key Decisions & Rationale

- **Did not commit to `main`.** The work fails the repo's Definition of Done on four counts:
  local checks not run, public claims ahead of capability, no check-log entry, no after-task
  report. Branch-only preserves two days of work without landing an unsupported claim.
- **Did commit (rather than leave dirty).** Uncommitted work is fragile; the maintainer flagged
  it precisely because it had been sitting loose. The commit message states UNVERIFIED explicitly.
- **Kept the AoG refactor** rather than reverting to raw Makie. The forest arguably gains little
  from AoG (whiskers, ticks, vlines and annotations are all still drawn manually), but
  re-architecting was not the mandate. Flagging the question, not answering it — see Open Questions.
- **Not pushed.** No push authorization was given. **This branch exists only on the maintainer's
  machine. If the checkout is lost, the work is lost.**

---

## Files Created / Modified

Committed in `fe93273c` on `feat/2026-07-08-plotting-aog`:

- `Project.toml` — `AlgebraOfGraphics` added to `[weakdeps]`, `[compat]` (`"0.13"`); extension becomes `HSquaredMakieExt = ["AlgebraOfGraphics", "Makie"]`
- `ext/HSquaredMakieExt.jl` — `_forest`, `_caterpillar`, `_axes_by_panel` rewritten; `_aog_axes` removed
- `src/plotting_ext.jl` — docstring: extension now needs Makie **and** AoG in scope
- `test/runtests.jl` — stub-test comments updated for the AoG weak-dep
- `docs/design/13-plotting-layer.md` — AoG described; **RE-VERIFICATION OWED** banner added

Written by this handover:

- `docs/dev-log/handover/2026-07-08-codex-handover.md` (this file)
- `AGENTS.md` — Live Phase Snapshot bullet prepended

---

## Next Immediate Steps

Ordered. Steps 1–2 are the whole point of the handoff.

1. **Resolve the compat pin.** In the repo env, confirm `AlgebraOfGraphics@0.13` and
   `Makie@0.24` co-resolve with a `CairoMakie` backend. If they don't, that alone blocks the
   branch — fix the pin before anything else.

2. **Run the nine-kind live draw.** With `using CairoMakie, AlgebraOfGraphics`, draw all nine
   `kind`s (inferred + explicit) and assert each returns a `Makie.Figure`. Then **eyeball the two
   AoG-backed figures specifically**:
   - `:variance_components` — do the h² panel and the variance-components panel each show
     **only their own** term labels? Are whiskers **behind** the markers? Is the `[0,1] boundary`
     annotation on the **h² panel only**?
   - `:breeding_values` — whiskers behind markers, single marker layer, no double-draw.

3. **Kill the residual assumption.** `_axes_by_panel` assumes row facets lay out in
   `sort(unique(panels))` order — i.e. `"heritability"` (row 1) before `"variance components"`
   (row 2). The shape guard catches a facet-*count* mismatch but **not a re-ordering**, which
   would silently swap the two panels' ticks and annotations. **Verify against the live AoG
   version.** If AoG exposes the row scale's level order on the `AxisEntries`, prefer reading it
   over assuming a sort.

4. **Bank evidence** in `docs/dev-log/check-log.md`: exact commands, AoG + Makie + CairoMakie
   versions, the nine-kind result, and the facet-order finding from step 3.

5. **Flip the doc.** Only once 2–4 pass, remove the RE-VERIFICATION OWED banner from
   `docs/design/13-plotting-layer.md` and let the nine-kind claim stand for the AoG layer.

6. **Rose audit** (`.codex/agents/rose-systems-auditor.toml`, mandatory) on the public-claim
   surface, then write the after-task report. Only then propose the merge.

**Do not merge before step 5.** Nothing here promotes coverage: `public_covered_count` stays
**5**, engine rows stay **55** / covered **13**. This is a drawing layer.

---

## Blockers / Open Questions

- **BLOCKER — no Julia toolchain in the authoring session.** `julia: command not found`. Every
  claim in this handover about runtime behaviour is derived from **reading the code**, not
  running it. Treat the three fixes as *reviewed*, not *tested*.
- **BLOCKER — branch is unpushed.** Push it or it lives on one machine only.
- **OPEN — is AoG earning its place in `_forest`?** After the migration the function still draws
  whiskers, yticks, vlines and the boundary annotation by hand, and reaches into `fg.grid` for
  the axes. AoG contributes the faceting and the scatter. A raw-Makie `Figure` + two `Axis`es
  might be simpler and would drop both the compat pin and the facet-order assumption. Maintainer's
  call — not re-architected here.
- **OPEN — should the CI stub test be strengthened?** It is currently satisfied by the extension
  *failing to load*. A cheap opt-in job (`CairoMakie` + AoG, `JULIA_LOAD_PATH` gated) would turn
  a whole class of silent breakage into a red build. Cost-discipline tradeoff; worth a decision.
- **NOTE — lane discipline.** `hsquared/CLAUDE.md` assigns `HSquared.jl` to the Julia lane; this
  work was done from an R-lane session on explicit maintainer instruction. Coordination board not
  updated — do that if the branch survives.

---

## Gotchas & Failed Approaches

- **Do not "simplify" the double-scatter by deleting the manual `scatter!` alone.** The original
  ordering was `AoG scatter → whiskers → manual scatter`; the second scatter existed to put markers
  back on top. Deleting it without the `translate!` fix leaves whiskers painted over the markers.
  That is why the fix moves the whiskers rather than dropping a loop.
- **Do not restore `_axes_by_panel`'s label-matching.** `String(t.text[])` on a Makie `Label` is not
  robust (rich text), and `fig.content` ordering is not part of AoG's API.
- **`Pkg.test()` green means nothing here.** See Critical Context #1. Do not close this out on CI.
- **`only(fg.grid)`** in `_caterpillar` assumes a 1×1 grid (no faceting). That holds today; it will
  throw loudly rather than mislabel if it ever stops holding. Intentional.

---

## Mission control

| Item | State |
| --- | --- |
| Repo | `HSquared.jl` (Julia engine twin of `hsquared`) |
| `main` | `a2fc7625` — untouched, green, CI green |
| Branch | `feat/2026-07-08-plotting-aog` @ `fe93273c` — **local only, unpushed, unverified** |
| Shipped | nothing. Drawing-layer refactor, reviewed not tested |
| Coverage | `public_covered_count` **5** · rows **55** · covered **13** — ALL UNCHANGED |
| Highest leverage | the nine-kind `CairoMakie + AlgebraOfGraphics` draw (Next Step 2) |
| Second | facet-order assumption (Next Step 3) — silent panel-swap risk |
| Merge gate | check-log evidence + Rose audit + doc banner removed |

---

## How to Resume

Codex reads `AGENTS.md` natively. From the repo root:

```sh
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
git checkout feat/2026-07-08-plotting-aog
export PATH="$HOME/.juliaup/bin:$PATH"     # julia was NOT on PATH in the authoring session
julia --project=. -e 'import Pkg; Pkg.instantiate()'
```

Confirm the compat pin resolves, then the live draw (this is the deliverable):

```sh
julia --project=. -e '
  import Pkg; Pkg.add(["CairoMakie", "AlgebraOfGraphics"])   # local only; keep OUT of CI
  using CairoMakie, AlgebraOfGraphics, HSquared
  # draw all nine kinds; assert each returns a Makie.Figure
  # then EYEBALL :variance_components (per-facet ticks, whiskers behind markers,
  # [0,1] annotation on the h2 panel only) and :breeding_values
'
```

Read in this order:

1. `AGENTS.md` — Live Phase Snapshot (top bullet points here)
2. **this file**
3. `docs/design/13-plotting-layer.md` — note the RE-VERIFICATION OWED banner
4. `ext/HSquaredMakieExt.jl` — `_forest`, `_caterpillar`, `_axes_by_panel`
5. `docs/dev-log/check-log.md` — where your evidence goes

One-paste resume prompt:

> Rehydrate from `docs/dev-log/handover/2026-07-08-codex-handover.md` + the `AGENTS.md`
> snapshot, then continue with the Next Immediate Steps. The branch
> `feat/2026-07-08-plotting-aog` carries an UNVERIFIED AlgebraOfGraphics migration of the
> plotting layer: run the nine-kind CairoMakie+AoG draw, settle the facet-order assumption in
> `_axes_by_panel`, bank the evidence in `check-log.md`, run the Rose audit, and only then
> remove the RE-VERIFICATION OWED banner and propose the merge. `Pkg.test()` green proves
> nothing here — the CI stub test passes when the extension fails to load.

**Routing.** Codex owns everything above (live Julia toolchain: resolve, draw, render, bank).
Claude owns nothing further until the draw is banked — then it can review the diff and audit
the public claims.

# After-task: AlgebraOfGraphics plotting-layer migration (recovered, fixed, verified)

**Date:** 2026-07-08 · **Agent:** Claude (Opus 4.8), solo · **Lane:** Julia (`HSquared.jl`),
entered from an R-lane session on explicit maintainer instruction
**Branch:** `feat/2026-07-08-plotting-aog` · base `main` @ `a2fc7625` · PR
[#264](https://github.com/itchyshin/HSquared.jl/pull/264)
**Active lenses:** Rose (real subagent), Florence (visual), Karpinski (Julia), Grace (CI)
**Spawned subagents:** yes — `rose-systems-auditor`

## 1. Goal

The maintainer flagged "five uncommitted plotting-layer files" and asked me to check and commit
them. Goal as executed: establish what they actually were, decide whether they were safe to land,
and land them honestly.

They turned out to be an **unfinished mid-conversion** of the `HSquaredMakieExt` package
extension to AlgebraOfGraphics (AoG) for the two tabular figure kinds
(`:variance_components`, `:breeding_values`), uncommitted for two days (mtime 2026-07-06). AoG
had **never existed on any ref** (`git log --all -S "AlgebraOfGraphics"` was empty): no Manifest,
no check-log entry, no after-task report, no `docs/dev-log/` mention.

Scope: drawing layer only. No estimation, no engine computation, nothing promoted.

## 2. Implemented

Four defect classes found and fixed, then verified against a live draw.

| # | Defect | Caught by | Fix |
| --- | --- | --- | --- |
| 1 | Every marker drawn **twice**. AoG's `visual(Scatter, …)` already draws the points; the manual `scatter!` that followed re-drew them — it was restoring z-order after the whiskers overpainted, not pure redundancy. | reading | AoG owns the single marker layer; whiskers pushed behind with `translate!(w, 0, 0, -1)`. Both `_forest` and `_caterpillar`. |
| 2 | `_axes_by_panel` scanned `fig.content` for `Label`s whose text matched a panel name and index-zipped them to axes — depending on AoG's facet-label rendering *and* `fig.content` ordering, two undocumented internals. Could `ArgumentError` at draw time. | reading | AoG's supported `FigureGrid.grid` accessor (`Matrix{AxisEntries}`, each carrying `.axis`) + a facet-grid shape guard. `_aog_axes` orphaned and removed. |
| 3 | `ax.yticks[] = (ys, string.(d.term))` applied to **every** facet axis, where `ys` ranks all terms across both panels — so each panel labelled terms it does not contain. | reading | Per-facet ticks: `idx = sort(findall(==(panel), panels); by = i -> ys[i])`. |
| 4 | Title + subtitle rendered **once per facet** (`axis=(…)` applies to every facet axis); `ylabel` leaked the mapped variable `"rank"`; x and y scales **linked across facets**, crushing h² on `[0,1]` into an invisible sliver against a variance scale of `0–40`; the `[0,1] boundary` annotation **clipped** at the right data limit. | **rendering the PNG and looking at it** | Title/subtitle → `figure = (; title, subtitle)`; `ylabel = ""`; `facet = (; linkxaxes = :none, linkyaxes = :none)`; `xautolimitmargin[] = (0.05, 0.35)` + `autolimits!` on annotated axes **only**. |

Also: `Project.toml` gains `AlgebraOfGraphics` in `[weakdeps]`/`[compat]` (`"0.13"`), extension
becomes `HSquaredMakieExt = ["AlgebraOfGraphics", "Makie"]`; `/src` stays dependency-free.

## 3. Decisions

- Kept the AoG migration rather than reverting to raw Makie (re-architecting was not the mandate).
- Committed to a **feature branch**, never to `main`; opened a PR; did not merge.
- Wrote evidence to `check-log.d/`, not the frozen `check-log.md`.

## 3a. Decisions and Rejected Alternatives

- **Rejected: commit to `main` as asked.** The work failed the Definition of Done on four counts
  (local checks not run, public claims ahead of capability, no check-log, no after-task report).
  Raised this and got maintainer agreement to fix-then-verify instead.
- **Rejected: delete the manual `scatter!` as "redundant".** That is the naive fix and it is wrong —
  the second scatter existed to restore z-order. Deleting it alone leaves whiskers painted over
  markers. Moved the whiskers instead (`translate!`).
- **Rejected: keep `_axes_by_panel`'s label-matching as a cross-check on `fg.grid` ordering.**
  Over-engineering; two fragile assumptions are not better than one documented one.
- **Rejected: hand the live draw to Codex.** Initially concluded the Julia toolchain was
  unavailable (`which julia` → not found) and wrote a full Codex handover on that premise. **This
  was wrong** — Julia is at `~/.juliaup/bin/julia`, merely off `PATH`. Superseded that doc rather
  than deleting it.
- **Rejected: re-architect `_forest` back to raw Makie.** Defensible (see §10) but a design call
  for the maintainer, not a defect fix.
- **Rejected: strengthening the CI stub test in this slice.** Correct to do, but it is a
  cost-discipline decision about CI spend, not a drawing-layer fix. Raised, not taken.

## 4. Files Touched

- `Project.toml` — AoG weakdep/compat; extension key becomes a 2-element vector
- `ext/HSquaredMakieExt.jl` — `_forest`, `_caterpillar`, `_axes_by_panel` rewritten; `_aog_axes` removed
- `src/plotting_ext.jl` — docstring: extension requires Makie **and** AoG
- `test/runtests.jl` — stub-test comments updated for the AoG weak dep
- `docs/design/13-plotting-layer.md` — AoG described; verification recorded; CI-blind-spot note added
- `docs/dev-log/check-log.d/2026-07-08-plotting-aog.md` — **new**, the evidence
- `docs/dev-log/handover/2026-07-08-codex-handover.md` — **new**, then SUPERSEDED (false premise)
- `docs/dev-log/handover/2026-07-08-claude-handover.md` — **new**
- `docs/dev-log/after-task/2026-07-08-plotting-aog.md` — **new**, this file
- `AGENTS.md` — Live Phase Snapshot bullet prepended

`hsquared` (R lane): **not touched**, `main` clean and synced.

## 5. Checks Run

`julia` is **not on `PATH`** in a Claude Code shell; it lives at `~/.juliaup/bin/julia`.

```sh
export PATH="$HOME/.juliaup/bin:$PATH"       # julia 1.10.0
```

| Check | Command | Result |
| --- | --- | --- |
| Compat pin resolves | `Pkg.add` AoG `0.13` + Makie `0.24` + CairoMakie in a scratch env | **PASS** — `AlgebraOfGraphics v0.13.0`, `Makie v0.24.13`, `CairoMakie v0.15.13` |
| Extension loads | `Pkg.develop` repo + add weak deps | **PASS** — `✓ HSquared → HSquaredMakieExt` precompiled |
| Nine-kind draw | `hsquared_figure(payload; kind)` × 9, explicit **and** inferred | **PASS** — 9/9 return a `Makie.Figure` |
| Rasterization | `save("forest.png", …)`, `save("caterpillar.png", …)` | **PASS** — 104,318 B / 69,769 B, both visually inspected |
| Dependency-free suite | `julia --project=. -e 'import Pkg; Pkg.test()'` | **PASS** — `Testing HSquared tests passed` |
| After-task structure | `Rscript -e 'source("~/shinichi-brain/tools/check-after-task.R"); main_check_after_task("<this file>")'` | **PASS** — see caveat below |

> **The documented validator invocation does not work.** `Rscript ~/shinichi-brain/tools/check-after-task.R <path>`
> exits **0 unconditionally** — the script defines `main_check_after_task()` and never calls it. Verified:
> it exits 0 for a file containing only `# nothing`, and for a path that does not exist. This report was
> therefore validated by `source()`-ing the script and calling the function explicitly, with a negative
> control (a bogus file correctly exits 1 and lists all 11 missing headers). **Every past "validated by
> `check-after-task.R`" claim made via the documented CLI was vacuous.** Filed as a separate task; the
> sibling validators in `~/shinichi-brain/tools/` should be swept for the same defect.

Assertions on the drawn object (payload `term=[sigma_a2, sigma_e2, h2]`, `lo=[5.0, NaN, -0.05]`,
`hi=[35.0, NaN, 0.72]`):

```
axis[1] ticks=[1.0]      labels=["h2"]                    | Scatter=1 Lines=1 Text=1
axis[2] ticks=[2.0,3.0]  labels=["sigma_e2","sigma_a2"]   | Scatter=1 Lines=1 Text=0
axis[1] Lines z-translation = -1.0
axis[2] Lines z-translation = -1.0
axis titles = ["", ""]   ylabels = ["", ""]
figure Labels = ["estimate", "heritability", "variance components",
                 "estimated; delta intervals (NOT coverage-calibrated)",
                 "Variance components & heritability"]
```

Full evidence: `docs/dev-log/check-log.d/2026-07-08-plotting-aog.md`.

## 6. Tests of the Tests

The decisive finding of this slice is that **the existing test cannot fail for the right reason**.

`test/runtests.jl` asserts `isempty(methods(hsquared_figure))` with Makie/AoG deliberately kept
out of CI (cost discipline). That assertion **passes precisely when the extension fails to load**.
A green `Pkg.test()` is therefore *zero evidence* about the drawing layer. All four defect classes
lived in this code while CI was green.

So the checks above were designed to be falsifiable, and each was given a negative control:

- **Double-draw:** `Scatter == 1` per axis would read `2` if either marker layer were duplicated.
  It read `2` before fix 1 (which is how the fix was confirmed, not assumed).
- **NaN whisker:** the `sigma_e2` row carries `lo = hi = NaN`. `Lines == 1` (not 2) on the variance
  panel proves no whisker was fabricated.
- **Z-order:** `Lines` `z-translation == -1.0` on every whisker; a value of `0.0` would mean
  whiskers paint over markers.
- **h²-panel-only boundary flag:** `Text == 1` on the h² axis and `Text == 0` on the variance axis.
  A variance whisker crossing 0 is expected and honest — flagging it would be the bug.
- **Control case (the important one):** a second payload with h² = 0.4, CI `[0.2, 0.6]`, strictly
  inside `[0,1]`, draws **no annotation and no headroom bump**. Without this, an always-on
  annotation would have passed every assertion above.
- **Facet order:** rather than trusting the `sort(unique(panels))` assumption, the ticks were read
  back off the drawn axes — `axis[1] → ["h2"]`, `axis[2] → ["sigma_e2","sigma_a2"]` — which would
  expose a panel swap directly.

Three of the four defect classes were nonetheless **invisible to plot-object assertions**. They
were caught only by rasterizing the figure and looking at it. That is now recorded as standing
guidance in `13-plotting-layer.md`.

**The driver is mutation-tested.** After Rose's audit the live-draw checks were committed as
`docs/dev-log/scripts/2026-07-08-plotting-aog-livedraw.jl`, and — applying this section's own
lesson to the new tool — three mutants were injected into `ext/HSquaredMakieExt.jl` to confirm it
can fail:

| Mutant | Expected catch | Result |
| --- | --- | --- |
| Reintroduce the manual `scatter!` (defect 1) | `Scatter == 1` | exit 1, `axis[1] double-draws markers` |
| Drop the `panels[i] == "heritability"` gate | `Text == 0` on variance panel **and** the control payload | exit 1, `variance panel must NOT be flagged` |
| `reverse(sort(unique(panels)))` — swap facet order | tick labels per facet | exit 1, `axis[1] should be the h² facet, got ["sigma_e2","sigma_a2"]` |

The third mutant matters most: it proves the driver catches the exact residual risk the facet-grid
shape guard **cannot** see (a re-ordering, as opposed to a count mismatch). The risk in §10 is now
detectable rather than merely disclosed.

## 7. Issue Ledger

No issue numbers were opened or closed by this slice. Related: #93 (plotting-layer contract).

## 7a. Issue Ledger

- **Opened:** none.
- **Closed:** none.
- **Referenced:** #93 (the `*_plot_data` honest-status drawing contract this layer consumes).
- **PR:** [#264](https://github.com/itchyshin/HSquared.jl/pull/264) — open, **not merged**, with the
  Rose audit and this after-task report as the declared merge gate.

## 8. Consistency Audit

Walked the neighbourhood after the fix:

- **`src/validation_status.jl` — untouched.** `public_covered_count` **5**, engine rows **55**,
  covered **13**. Nothing promoted. This is a drawing layer.
- **`d.panel` element type checked, not assumed.** It is `["variance components", "variance
  components", "heritability"]` — plain `String`s (`src/likelihood.jl:2658`) — so the pre-existing
  `d.panel[i] == "heritability"` comparison was already sound. **No Symbol-comparison bug exists**;
  recorded so a future reader does not hunt for one.
- **`_caterpillar` audited for the same class as `_forest`** (fix-the-class discipline): it had the
  same double-draw, fixed the same way. It is single-axis, so it does *not* have the per-facet title,
  ylabel, or linked-scale defects — verified by inspection of the rendered PNG, not by assumption.
- **The other seven figure kinds** were left on raw Makie and re-drawn to confirm the migration did
  not regress them: 9/9 draw.
- **Stale-doc sweep.** The diff had silently upgraded `13-plotting-layer.md` to claim "AoG-backed"
  figures verified across all nine kinds, when the recorded verification was run 2026-06-22 against
  **raw Makie**. Corrected. The `2026-07-08-codex-handover.md` I wrote earlier became false the moment
  the draw succeeded; it carries a SUPERSEDED banner rather than being deleted.
- **Frozen-file check.** `docs/dev-log/check-log.md` is frozen as of 2026-06-19; evidence went to
  `check-log.d/`. Nearly appended to the frozen file — caught by reading its header first.
- **Coordination board:** **not** updated (see §10).

## 9. What Did Not Go Smoothly

- **I declared the Julia toolchain unavailable on the strength of `which julia`.** It was not on
  `PATH`; it was on disk at `~/.juliaup/bin/julia`. On that false premise I concluded the work could
  not be verified, wrote a complete Codex handover assigning the live draw to Codex, and told the
  maintainer "I can't verify this." One `ls` would have prevented it. The cost was a wasted handover
  doc and a wrong statement to the user.
- **My first three fixes passed every assertion and the figure was still broken.** `Scatter=1`,
  `z=-1.0`, `Text=1` on the h² axis — all green, and the forest was unreadable: duplicated titles,
  a `"rank"` ylabel, h² crushed against a 0–40 variance axis, and a clipped annotation. Object
  introspection is not visual verification. I only found this because I rendered the PNG.
- **I initially mis-read the double-scatter as pure redundancy.** It was z-order restoration. Had I
  "simplified" it in one line, I would have shipped whiskers painted over the markers while every
  count still read correctly.

## 10. Known Residuals

- **Verified on one machine, one version set** — Julia 1.10.0, AoG 0.13.0, Makie 0.24.13,
  CairoMakie 0.15.13, macOS/arm64. Not a cross-version or cross-platform claim.
- **`_axes_by_panel` assumes facet rows lay out in `sort(unique(panels))` order.** Empirically
  confirmed on AoG 0.13.0 by reading the ticks back off the drawn axes. The shape guard throws on a
  facet-**count** mismatch but would **not** catch a re-ordering. On any AoG bump: re-render the
  forest and check the ticks. CI will not tell you.
- **The nine-kind draw is local-only and not in CI**, by design (heavy plotting stack). It must be
  re-run by hand on any Makie/AoG version bump.
- **Open design question — is AoG earning its place in `_forest`?** The function still draws
  whiskers, ticks, vlines and the boundary annotation by hand, unlinks both facet scales, blanks the
  ylabel, and reaches into `fg.grid`. AoG contributes faceting and one `Scatter`. Raw Makie with two
  `Axis`es would be simpler and would drop both the compat pin and the facet-order assumption.
  `_caterpillar` (single axis) is genuinely clean under AoG. **Maintainer's call — deliberately not
  answered here.**
- **The CI stub test should arguably be strengthened** (an opt-in CairoMakie+AoG job behind an env
  flag). Cost-discipline tradeoff; raised, not taken.
- **Coordination board not updated.** This was a Julia-lane slice run from an R-lane session on
  maintainer instruction; `docs/dev-log/coordination-board.md` still reads "Julia lane: this
  repository". If PR #264 merges, update the board.
- **Only the forest's honest-status behaviours are asserted.** The other seven kinds are asserted
  to return a `Makie.Figure`; their subtitle caveats rest on the 2026-06-22 raw-Makie verification,
  which the AoG migration did not touch.
- **Merge gate:** Rose audit (DONE) + this report (DONE). PR #264 is **not** merged.

## 10a. Rose Audit

A real `rose-systems-auditor` subagent audited the branch. **Verdict: PROMOTE-WITH-CHANGES.**
Coverage pins confirmed against ground truth (`tools/status_cache.json:2-7`,
`tools/gen_status_json.jl:64,109`), not self-report: `validation_status.jl` untouched,
`public_covered_count` 5, rows 55, covered 13. All 8 required changes applied:

1. **A false evidence pointer, authored by me.** `test/runtests.jl:9266` read "verified locally
   with CairoMakie + AlgebraOfGraphics (see the after-task report **2026-06-22**)". No 2026-06-22
   report mentions AoG — AoG did not exist on any ref until this branch. I edited that comment and
   committed it without noticing I was attributing AoG verification to a report written sixteen days
   before AoG entered the repository. **This is exactly the drift Rose exists to block, and I
   introduced it.** Fixed: the comment now cites the raw-Makie report for the raw-Makie kinds, this
   slice's evidence for the AoG path, and states the CI trap *at the trap site*.
2. `13-plotting-layer.md` — the pre-existing verification paragraph now explicitly attributed to the
   2026-06-22 raw-Makie era (CairoMakie 0.15.11), not the AoG path.
3. **The evidence was unreproducible.** Steps (b)–(e) of the check-log — the entire evidentiary basis
   — sat under a "Commands run" heading with no commands, in a scratch env that no longer exists,
   while the same document demanded a re-run on every AoG bump. Fixed by committing the driver.
4. The SUPERSEDED banner retracted three strings while the body asserted six more falsehoods
   ("NOT PUSHED", "Nothing has ever been run", "three defects", "reviewed not tested", "UNVERIFIED",
   and references to a RE-VERIFICATION OWED banner that had since been removed). Banner widened.
5–6. `AGENTS.md` — stale commit id; the forest-payload assertions were phrased so they read as
   applying to all nine kinds; the one-machine/one-version boundary was missing.
7. `ext/HSquaredMakieExt.jl` — the source comment said the facet-order assumption was *still owed*
   while the check-log said it was confirmed. Under-claiming, but it would have sent the next agent
   to redo banked work.
8. (Stale by the time Rose reported: the after-task report was untracked at her snapshot `3629031f`;
   committed at `25a3a289`.)

Accepted nit with teeth: `vlines!`/`hlines!` were drawn *after* the whiskers were pushed to `z=-1`,
so the dashed zero line painted **over** the AoG markers — a term with `estimate ≈ 0` got a line
through its marker. Same as `main`, so not a regression, but "markers on top" was incidental rather
than invariant. Both are now `translate!`d to `z=-1` and the driver asserts it on every line layer.

## 11. Team Learning

- **"Command not found" ≠ "tool not installed."** Before declaring a toolchain unavailable, check
  the install locations (`~/.juliaup/bin`, `/Applications/Julia*.app`). This one false negative
  produced a whole handover document premised on a capability I actually had. Added to the handover
  doc and the AGENTS.md snapshot so the next session cannot repeat it.
- **A test that asserts absence passes when the thing is broken.** `isempty(methods(f))` with the
  extension's deps excluded is satisfied *by the extension failing to load*. Any "stub is method-less"
  test has this shape. When you meet one, ask what a green run actually proves — here, nothing.
- **For visual output, assertions on the plot object are necessary but not sufficient.** Three of
  four defect classes here were invisible to `Scatter=1` / `z=-1.0` / `Text=1` and visible instantly
  in a PNG. **Render it and look at it.** (Florence's lens — under-used on this repo.)
- **A "redundant" line in someone's unfinished refactor is often load-bearing.** The duplicate
  `scatter!` was z-order restoration. Read *why* before deleting.
- **Check that your checker can fail.** `Rscript tools/check-after-task.R <path>` exits 0 for a
  nonexistent file — it defines a main function and never calls it. I only noticed because I ran a
  negative control on the validator itself before trusting its green. The same instinct that exposed
  the CI stub-test blind spot in §6 exposed this. **A gate that cannot fail is not a gate**, and
  *three* of this slice's gates turned out to be that (the CI stub test, the report validator, and —
  until it was mutation-tested — the live-draw driver itself). Run the negative control on the tool,
  not just the code.
- **A verifying agent can still author the drift it verifies.** I found the double-draw, the fragile
  axis mapping, the mislabelled ticks, and four rendering defects — and in the same breath committed
  `test/runtests.jl` citing a 2026-06-22 report as evidence for a package that did not exist on any
  ref at the time. Rose caught it; I did not. **Being the person who found the bugs is not evidence
  you did not add one.** Independent audit is not ceremony.
- **"Nothing promoted" must be proved against the pin files, not asserted.** Rose confirmed
  `public_covered_count` against `tools/status_cache.json` and `tools/gen_status_json.jl` and the
  empty `git diff` of `src/validation_status.jl` — not against my say-so. That is the standard.
- **Uncommitted-for-days work is usually mid-refactor, not finished.** Treat "please commit these"
  as "please find out what these are."
- **Recall before scouting:** no cross-repo scouting was needed for this slice (self-contained
  drawing layer), so no `/ask-brain` recall was performed and no cross-team note was owed.
- **Memory receipt.** Hub guards that actually shaped this work: *the Rose principle* (fix the class
  — drove the `_caterpillar` sweep and the stale-doc sweep); *honesty over agreement* (declined the
  literal "check and commit" instruction and said why); *never hand one sub-agent a broad multi-file
  task* (Rose was scoped to 6 named files, forbidden to delegate); *state the negative space* (the
  `covers ✓ / does NOT cover ✗` boundary is in §10 and the check-log claim boundary); *repo rules
  override the hub* (`Co-Authored-By` **is** used in `HSquared.jl`, unlike `hsquared`).

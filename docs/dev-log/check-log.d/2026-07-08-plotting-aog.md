# 2026-07-08 — AlgebraOfGraphics plotting-layer migration (recovered, fixed, verified)

**Slice.** Recover five uncommitted plotting files (mtime 2026-07-06, unfinished mid-conversion
of `HSquaredMakieExt` to AlgebraOfGraphics), fix the defects, and verify with a live draw.

**Branch.** `feat/2026-07-08-plotting-aog` (base `main` @ `a2fc7625`).

---

## Goal

Route the two tabular figure kinds (`:variance_components`, `:breeding_values`) through
AlgebraOfGraphics while keeping bespoke scientific layouts on raw Makie; keep `/src`
dependency-free; keep `public_covered_count` unchanged. Drawing layer only — no estimation,
no engine computation, nothing promoted.

## The CI blind spot (why this needed a live draw at all)

`test/runtests.jl` asserts `isempty(methods(hsquared_figure))` with Makie/AoG deliberately out
of the default CI. **That assertion passes precisely when the extension fails to load.** A green
`Pkg.test()` is therefore zero evidence about the drawing layer. Every defect below was invisible
to the default CI by construction. Per the `Detected by` column: defects 1–3 were found by reading
the code, and defect 4 only by **rendering the figure and looking at it** — as was defect 5, added
in the post-merge-review addendum, which had also *passed* a plot-object assertion. Two of five.

> Corrected 2026-07-08 (second session): this paragraph previously read "three of the four were
> invisible to plot-object assertions," which the table below does not support. An opt-in
> `plotting` CI job now runs the live-draw driver and uploads the figures; the *default* CI still
> sees none of this.

## Defects found and fixed

| # | Defect | Detected by | Fix |
| --- | --- | --- | --- |
| 1 | Every marker drawn **twice** — AoG's `visual(Scatter, …)` draws the points, then a manual `scatter!` re-drew them to restore z-order after the whiskers overpainted | reading | AoG owns the single marker layer; whiskers pushed behind with `translate!(w, 0, 0, -1)` |
| 2 | `_axes_by_panel` pattern-matched `Label`s out of `fig.content` and index-zipped them to axes (two undocumented internals; could `ArgumentError` at draw time) | reading | AoG's supported `FigureGrid.grid` accessor (`Matrix{AxisEntries}`, each carrying `.axis`) + facet-grid shape guard |
| 3 | Full term list forced onto **every** facet's yticks, so each panel labelled terms it does not contain (`ys` is a rank over all terms) | reading | per-facet ticks: `idx = sort(findall(==(panel), panels); by = i -> ys[i])` |
| 4 | Title + subtitle rendered **once per facet**; `ylabel = "rank"` leaked the mapped variable; x/y scales **linked across facets**, crushing h² (`[0,1]`) against a variance scale of `0–40` into an unreadable sliver; the `[0,1] boundary` annotation **clipped** at the right axis limit | **rendering the PNG and looking at it** | title/subtitle moved to figure level; `ylabel = ""`; `facet = (; linkxaxes = :none, linkyaxes = :none)`; `xautolimitmargin[] = (0.05, 0.35)` + `autolimits!` on annotated axes only |

## Commands run

Environment (`julia` is NOT on the default `PATH` — it lives at `~/.juliaup/bin`):

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
julia --version                                    # 1.10.0
```

**Steps (b)–(e) are re-runnable as a committed driver**, not an archaeology exercise:

```sh
mkdir -p /tmp/aog-livedraw && cd /tmp/aog-livedraw
julia --project=. -e 'import Pkg
    Pkg.develop(path="<repo>"); Pkg.add(["CairoMakie", "AlgebraOfGraphics"])'
julia --project=. <repo>/docs/dev-log/scripts/2026-07-08-plotting-aog-livedraw.jl
```

The driver exits non-zero on any failed invariant and writes `forest.png` / `caterpillar.png`.
It was **mutation-tested** on 2026-07-08 — reintroducing the double-draw, dropping the
h²-panel-only annotation gate, and reversing the facet level order each make it exit 1 with the
specific assertion message. It can fail, which is the only reason its passing means anything.

**(a) Compat pin resolves — standalone.** The `AlgebraOfGraphics = "0.13"` / `Makie = "0.24"`
pin was unverified (no Manifest). Resolved in a scratch env **without HSquared's own
dependencies** — it is step (b)'s `Pkg.develop` that proves the pin resolves *in the repo
environment*:

```sh
julia --project=aogcheck -e 'import Pkg; Pkg.add([
  Pkg.PackageSpec(name="AlgebraOfGraphics", version="0.13"),
  Pkg.PackageSpec(name="Makie", version="0.24"),
  Pkg.PackageSpec(name="CairoMakie")]); Pkg.status()'
```

→ `AlgebraOfGraphics v0.13.0` · `Makie v0.24.13` · `CairoMakie v0.15.13`. **RESOLVED.**

**(b) Extension loads.** `Pkg.develop` the repo + add the two weak deps:

→ `✓ HSquared → HSquaredMakieExt` precompiled. **LOADS.**

**(c) Nine-kind live draw**, explicit and inferred `kind`, `using CairoMakie, AlgebraOfGraphics`:

```
variance_components    explicit=true inferred=true
breeding_values        explicit=true inferred=true
g_geometry             explicit=true inferred=true
genetic_correlation    explicit=true inferred=true
manhattan              explicit=true inferred=true
qq                     explicit=true inferred=true
rr_variance            explicit=true inferred=true
rr_surface             explicit=true inferred=true
rr_eigenfunctions      explicit=true inferred=true
NINE-KIND RESULT: 9/9 draw a Makie.Figure (explicit + inferred)
```

**(d) Honest-status behaviours asserted on the drawn object** (payload:
`term=[sigma_a2, sigma_e2, h2]`, `lo=[5.0, NaN, -0.05]`, `hi=[35.0, NaN, 0.72]`):

```
axis[1] ticks=[1.0] labels=["h2"]                  | Scatter=1 Lines=1  Text=1
axis[2] ticks=[2.0, 3.0] labels=["sigma_e2","sigma_a2"] | Scatter=1 Lines=1  Text=0
axis[1] Lines z-translation = -1.0
axis[2] Lines z-translation = -1.0
axis titles (must be empty): ["", ""]
ylabels  (must be empty): ["", ""]
figure Labels: ["estimate", "heritability", "variance components",
                "estimated; delta intervals (NOT coverage-calibrated)",
                "Variance components & heritability"]
```

- `Scatter = 1` per axis → **no double-draw**.
- `Lines = 1` on the variance panel → the **`NaN` whisker on `sigma_e2` draws nothing** (raw, never fabricated).
- `z-translation = -1.0` → **whiskers behind markers**.
- `Text = 1` on the h² axis, `Text = 0` on the variance axis → the **`[0,1]` boundary flag is h²-panel-only**; a variance whisker crossing 0 is expected/honest and is NOT flagged.
- axis titles / ylabels empty, title+subtitle appear **once** at figure level.
- **Control case** (h² = 0.4, CI `[0.2, 0.6]`, strictly inside `[0,1]`): no red annotation drawn, no headroom bump applied.

**(e) Rasterization.** `save("forest.png", …)` / `save("caterpillar.png", …)` → 104,318 B and
69,769 B. Both figures visually inspected: single title, per-facet ticks correct, independent
x scales, annotation fully legible, marker on top of whisker.

**(f) Dependency-free test suite** (the repo's standard check, Makie/AoG absent):

```sh
julia --project=. -e 'import Pkg; Pkg.test()'
```

→ `Testing HSquared tests passed`. **GREEN.** The stub testset still asserts the method-less
generic function, so the CI posture (Makie/AoG out of CI, cost discipline) is unchanged.

## Claim boundary

- Drawing layer **only**. No estimation, no engine computation in the extension.
- **Nothing promoted.** `public_covered_count` **5**, engine rows **55**, covered **13** — all
  unchanged. `validation_status()` untouched.
- Verified on **one machine, one version set** (Julia 1.10.0, AoG 0.13.0, Makie 0.24.13,
  CairoMakie 0.15.13, macOS/arm64). Not a cross-version or cross-platform claim.
- `_axes_by_panel` assumes row facets lay out in `sort(unique(panels))` order. **This was
  confirmed empirically** on AoG 0.13.0 (`axis[1]` is `"heritability"`, `axis[2]` is
  `"variance components"`), and a facet-grid shape guard throws on a count mismatch — but a
  future AoG re-ordering would not be caught by that guard. It **is** caught by the driver's
  `forest_invariants()` (mutation-tested: reversing the level order exits 1). Re-run the driver
  on any AoG bump.
- The nine-kind draw is **not run by the default CI**. Re-run it by hand on any Makie/AoG version
  bump, or dispatch the opt-in `plotting` job (`run_plotting = true`), which runs the same driver
  and uploads the figures. The default CI will not tell you. *(Added 2026-07-08, second session:
  the job did not exist when this line first read "local-only".)*
- The `[0,1] boundary` annotation and the tick/whisker geometry are asserted; the **subtitle
  text of the other seven kinds is not** — those kinds are asserted only to return a
  `Makie.Figure`. Their honest-status subtitles rest on the 2026-06-22 raw-Makie verification,
  which the AoG migration did not touch.

## Post-audit addendum (Rose, PROMOTE-WITH-CHANGES)

A real `rose-systems-auditor` subagent audited the branch. Coverage pins confirmed against
ground truth (`tools/status_cache.json`, `tools/gen_status_json.jl`), not self-report:
`validation_status.jl` untouched, `public_covered_count` 5, rows 55, covered 13. Required
changes applied:

1. **False evidence pointer removed.** `test/runtests.jl` cited "after-task report 2026-06-22"
   next to "CairoMakie + AlgebraOfGraphics". No 2026-06-22 report mentions AoG — AoG did not
   exist on any ref until this branch. The comment now cites the raw-Makie report for the
   raw-Makie kinds and this entry (plus the driver) for the AoG path, and states the CI trap
   *at the trap site*.
2. **`13-plotting-layer.md`** — the pre-existing verification paragraph is now explicitly
   attributed to the 2026-06-22 raw-Makie era (CairoMakie 0.15.11), not to the AoG path.
3. **Evidence made reproducible** — the live-draw driver is committed and mutation-tested.
4. **Superseded Codex handover** — banner widened; its body asserted six further falsehoods
   ("NOT PUSHED", "Nothing has ever been run", "three defects", a RE-VERIFICATION OWED banner
   that no longer exists anywhere else) that the original three-string retraction did not cover.
5. **`AGENTS.md`** — stale commit id; drawn-object assertions re-scoped to the forest payload
   rather than reading as if they applied to all nine kinds; one-machine/one-version boundary added.
6. **Zero line behind the markers.** Rose's nit: `vlines!`/`hlines!` were drawn after the
   whiskers were pushed to `z = -1`, so the dashed zero line painted *over* the AoG markers — a
   term with `estimate ≈ 0` got a dashed line through it. Same as `main`, so not a regression,
   but "markers on top" was incidental rather than invariant. Both are now `translate!`d to
   `z = -1`, and the driver asserts it on every line layer in both figures.

## Post-merge-review addendum (2026-07-08, second Claude session)

Rehydrated from `handover/2026-07-08-claude-handover.md`. Re-ran the driver before trusting the
handover's green.

**Why the handover was not taken on faith.** It states (Critical Context (c)) that the two dead
R honesty gates in the `shinichi-brain` hub were "fixed and pushed" at `3468312`. Running the
negative control showed that claim was half wrong: `Rscript rose-pattern-scan.R <nonexistent>`
still exited **0**. Restoring the script's missing `main()` invocation made it *run*, but
`rose_pattern_scan()` never guarded its root, and `list.files()` returns `character(0)` for a
missing directory with no error and no warning — so a typo'd path scanned zero files, found zero
problems, and printed `Rose pattern scan passed`. Two layers, one defect. Fixed out-of-repo:
`shinichi-brain@d85299f` (root guard), `@bbc1c34` (locale-independent matching); the lesson is
banked at `@58a2936`. Since the handover's account of a gate it had itself declared fixed was
wrong, its account of *this* branch was re-verified from scratch rather than believed — which is
how defect 5 below was found.

### Fifth defect: the `[0,1]` flag was anchored at the wrong end

`_forest` annotated every boundary crossing at `d.hi[i]`, but the gate fires on
`lo <= 0 || hi >= 1`. For the driver's own adversarial payload (`lo = -0.05, hi = 0.72`) the
flag rendered at `x = 0.72` — the one end the interval respects — and the `xautolimitmargin`
bump `(0.05, 0.35)` added headroom on the wrong side. Confirmed at the object level before
fixing: `p[1][] == [[0.72, 1.0]]`, `p.align[] == (:left, :center)`.

It survived the whole prior session because the driver asserted `nplots(ax, M.Text) == 1` —
it counted the annotation and never asked **where** it was. Found by rendering `forest.png`
and looking at it, exactly as this document's own CI-blind-spot note prescribes.

**Fix.** Flag anchored at the crossed end: `lo` (right-aligned) when `lo <= 0`, `hi`
(left-aligned) when `hi >= 1`, **both** when the interval crosses both; headroom added on the
flagged side(s) only.

**Driver strengthened.** `forest_invariants()` now asserts anchor **position and alignment**,
plus axis headroom, for three payloads: `vc` (lo-crossing), `vc_hi` (hi-crossing, new), and
`vc_both` (both ends, new). Counting is not checking.

### Commands (Julia 1.10.0, macOS/arm64; `export PATH="$HOME/.juliaup/bin:$PATH"`)

| Cell | Command | Result |
| --- | --- | --- |
| live draw | `julia --project=. .../2026-07-08-plotting-aog-livedraw.jl` | `ALL LIVE-DRAW CHECKS PASSED`; 9/9 kinds; `flag_placement = "ok (lo / hi / both)"` |
| versions | `Pkg.status` | AoG 0.13.0 · Makie 0.24.13 · CairoMakie 0.15.13 |
| visual | opened `forest.png`, `caterpillar.png` | flag now at the crossed end, unclipped |
| mutation — double-draw | re-add the manual `scatter!` after the whisker loop | exit 1, `axis[1] double-draws markers` |
| mutation — annotation gate | replace the `d.lo[i] <= 0.0` condition with `true` (the `lo` branch only) | exit 1, `annotation fired on the control payload` |
| mutation — **anchor** | regress the `lo` branch to anchor at `d.hi[i]`, left-aligned | exit 1, `lo-crossing flag anchored at 0.72, not lo` |

Each mutation is named for **exactly one** branch of the two-branch gate. Dropping *both* range
conditions instead trips `h² panel missing the [0,1] boundary flag` first (the `vc` h² panel then
carries two `Text` plots), so the row above would not reproduce — the mutation must be stated
precisely or the evidence is not re-runnable. All three were applied to a **copy** of the package
(`Project.toml` + `src/` + `ext/` dev'd into a scratch env); the repository working tree was never
dirtied to run them.

### Opt-in CI

`.github/workflows/CI.yml` gains a `plotting` job: `workflow_dispatch` input `run_plotting`
(default `false`), installs CairoMakie + AlgebraOfGraphics, runs the driver, and **uploads the
rendered PNGs as an artifact**. `inputs` is empty on `pull_request`, so the job is skipped by
default — the dependency-free CI posture is unchanged. A green there is still not visual
verification; download the artifact and look.

**Exercised, not merely written.** On PR #264 the job reported `skipping` while both `test` jobs
passed (off-by-default, confirmed empirically rather than by reading the `if:` expression). After
merge it was dispatched once on `main` — run
[28960736583](https://github.com/itchyshin/HSquared.jl/actions/runs/28960736583), `ubuntu-latest`,
**green**, artifact `live-draw-figures` 116,138 bytes. The figures were downloaded and inspected,
and are **byte-identical** to the macOS/arm64 renders (`forest` `89d15dfdd47f`, `caterpillar`
`99a7382b92f1`) — so on this version set the raster is reproducible across ubuntu-x86_64 and
macOS-arm64. Still uncovered: no *failing* run has been observed on GitHub, so
`if-no-files-found: error` has never faced the case it was written for (verified locally only).

### Not covered

One machine, one version set (Julia 1.10.0, macOS/arm64). No cross-version or cross-platform
claim. The facet-order assumption (`sort(unique(panel))`) is still empirical, and the driver's
shape guard still cannot see a re-ordering — only a facet-count mismatch.

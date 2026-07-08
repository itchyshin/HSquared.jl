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
of CI. **That assertion passes precisely when the extension fails to load.** A green
`Pkg.test()` is therefore zero evidence about the drawing layer. Every defect below was
invisible to CI by construction; three of the four were invisible to plot-object assertions
too, and surfaced only when the figure was **rendered and looked at**.

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

**(a) Compat pin resolves.** The `AlgebraOfGraphics = "0.13"` / `Makie = "0.24"` pin was
unverified (no Manifest). Resolved in a scratch env:

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
  future AoG re-ordering would not be caught by that guard. Re-check the ticks on any AoG bump.
- The nine-kind draw is **local-only** and is not run in CI. It must be re-run by hand on any
  Makie/AoG version bump; CI will not tell you.

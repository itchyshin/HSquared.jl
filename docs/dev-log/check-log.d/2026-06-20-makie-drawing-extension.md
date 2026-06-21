# 2026-06-20 HSquaredMakieExt — Julia drawing extension (plotting layer §8)

- **Goal:** build the Julia drawing HALF of the plotting layer (the §1 runway item) —
  a Makie weak-dep package extension that draws the set B/C `*_plot_data` preparers
  with the R-twin's #93 honest-status behaviors rendered ON the figure. The "solo
  item" the user authorized for this window.
- **Active lenses:** Florence (figures) + Hopper (R-contract parity) + Karpinski
  (weak-dep wiring / `/src`-clean) + Grace (CI cost discipline) + Rose (claims).
- **What landed:**
  - `Project.toml`: `Makie` in `[weakdeps]`/`[extensions]`, pinned `[compat] Makie = "0.24"`.
  - `src/plotting_ext.jl`: exported method-less STUB `hsquared_figure(data; kind, …)`
    + the honest-status drawing contract docstring. `/src` stays dependency-free.
  - `ext/HSquaredMakieExt.jl`: the drawing methods. One dispatcher infers `kind`
    from the carried fields (`:variance_components` / `:breeding_values` /
    `:g_geometry`); `_forest` / `_caterpillar` / `_scree` render the behaviors.
  - `src/HSquared.jl`: `include("plotting_ext.jl")` + export `hsquared_figure`.
- **Honest-status behaviors verified rendered ON the figure (the #93 contract):**
  raw whiskers never clamped (a VC whisker crossing 0 is expected/honest); the
  `[0,1]` crossing annotated on the **h² panel only**; `NaN` → no whisker;
  supplied/estimated + `interval_status` ("NOT coverage-calibrated") in the subtitle;
  EBV ± `√PEV` with the `pev_scale = "validation"` caveat; the G view is the
  eigenvalue **scree only**, gated on `is_eigenstructure_not_loadings` (a loadings
  biplot throws `ArgumentError` — FA rotation convention); a non-PD `G` draws the
  bar but **suppresses** %-variance labels.
- **CI test (`test/runtests.jl`, +4 assertions):** the stub is a method-less
  `Function` and throws `MethodError` until a backend activates the extension.
  Makie is deliberately OUT of default CI (heavy GL/Cairo stack — cost discipline),
  so CI gates the STUB contract, not the draw.
- **LOCAL draw verification (CairoMakie 0.15.11 / Makie 0.24.11, scratch env
  `/tmp/hsq_makie_env`):**
  - the extension precompiles (`HSquared → HSquaredMakieExt` ✓) and
    `Base.get_extension` resolves it once `using CairoMakie`;
  - all three `kind`s return a `Makie.Figure` (inferred AND explicit `kind`);
  - the supplied-branch, all-`NaN`-whisker, and forced `[0,1]`-boundary forest
    paths each draw without error;
  - the loadings-biplot guard throws `ArgumentError`; the non-PD-`G`
    label-suppression path draws; an unrelated NamedTuple → `ArgumentError`;
  - the variance-components forest **rasterizes to a 60,935-byte PNG** with
    CairoMakie (`save(...)`), visually confirmed (raw whiskers cross 0, the
    "NOT coverage-calibrated" caveat in the subtitle).
- **Checks:** `julia --project=. -e 'using Pkg; Pkg.test()'` GREEN (incl. the new
  4-assertion stub testset); `julia --project=docs docs/make.jl` GREEN
  (`hsquared_figure` added to `docs/src/api.md`, docstring resolves, no missing-docs
  warning); `git diff --check` clean.
- **Docs / status:** `docs/design/13-plotting-layer.md` §8 added + status line updated;
  capability-status row added (experimental); validation-debt row `V-PLOT-DRAW` added
  (partial). `validation_status()` UNCHANGED (41 rows) — a drawing capability promotes
  NO statistical claim, so it correctly gets no validation row.
- **Honest status:** DRAWING only — no estimation, no engine computation, no
  statistical/performance/fitting claim promoted. The draw is locally attested, NOT
  CI-gated (the recorded debt). Nothing moved to `covered`.

# Drawing-layer entry point. The METHOD lives in the `HSquaredMakieExt` package
# extension (`ext/HSquaredMakieExt.jl`), which loads only when `Makie` (e.g.
# `using CairoMakie`) is in scope — so `/src` stays dependency-free. This is just the
# stub + the honest-status drawing contract; no engine computation happens here.

"""
    hsquared_figure(data; kind = <inferred>, kwargs...)

Draw an HSquared plotting-layer figure from a `*_plot_data` NamedTuple. **STUB:** the
drawing method is provided by the `HSquaredMakieExt` package extension, which activates
only when a Makie backend is loaded (`using CairoMakie` / `GLMakie`). Without one,
calling this throws a `MethodError` asking you to load Makie.

Supported `kind`s (each consumes the matching preparer and renders the R-twin's
honest-status drawing behaviors ON the figure — #93):

- `:variance_components` ← [`variance_components_plot_data`](@ref) — the VC + h² forest.
  Whiskers are RAW (never clamped); a whisker crossing the `[0,1]` boundary is annotated
  on the **h² panel only** (a variance-component whisker crossing 0 is expected/honest,
  not flagged); `NaN` whiskers draw no whisker.
- `:breeding_values` ← [`breeding_values_plot_data`](@ref) — the EBV caterpillar
  (sorted EBV ± `√PEV`); the `pev_scale = "validation"` caveat is rendered in the subtitle.
- `:g_geometry` ← [`genetic_pca_plot_data`](@ref) — the eigenvalue **scree only**, NEVER
  a loadings biplot (gated on `is_eigenstructure_not_loadings`); on a non-PD `G` a
  negative eigenvalue bar is drawn but the %-variance labels are suppressed and a
  "non-positive-definite G" note is added (a ">100% variance share" is the trap).

The honest-status caveat is always rendered on the figure (subtitle), sourced from the
SAME flags the preparer carries — this is the drawing-layer half of the plotting
layer's "subtitle drop is the only guardrail" defense (`docs/design/13-plotting-layer.md`).
Drawing only — no estimation, no engine computation.
"""
function hsquared_figure end

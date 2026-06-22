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
- `:genetic_correlation` ← [`genetic_correlation_plot_data`](@ref) — the rotation-invariant
  `D⁻¹GD⁻¹` correlation **heatmap** (unit diagonal, off-diagonals in `[-1,1]`), NEVER raw
  loadings (gated on `rotation_invariant`); when `heritabilities` are supplied, low-h²
  (imprecise) traits are flagged in the subtitle.
- `:manhattan` ← [`marker_manhattan_data`](@ref) — chromosome-coloured scatter of
  cumulative `plot_positions` vs `-log10(p)`, with a VISUAL-ONLY Bonferroni guide line;
  the subtitle states the p-values are nominal Wald and **NOT genome-wide calibrated**
  (#48), so the line is guidance only.
- `:qq` ← [`marker_qq_data`](@ref) — observed vs expected `-log10(p)` with the `y = x`
  uniform-null line; the subtitle carries the same NOT-genome-wide-calibrated caveat.
  λGC is **intentionally not** recomputed in the drawing layer (the preparer carries no
  χ²; recomputing would duplicate `/src` numerics and risk an uncalibrated read).
- `:rr_variance` ← [`rr_genetic_variance_plot_data`](@ref) — the genetic-variance
  trajectory `v_g(t)`, plus an `h²(t)` panel ONLY when a residual was supplied; the
  subtitle flags it as supplied-`K_g` descriptive and that `h²(t)` can overstate without
  a permanent-environment term.
- `:rr_surface` ← [`rr_covariance_surface_plot_data`](@ref) — the genetic
  covariance/correlation surface heatmap (diverging RdBu centred at 0); the correlation
  surface uses a fixed `(-1, 1)` colorrange, the covariance surface a data-driven
  symmetric-about-0 range (a fixed `(-1, 1)` would clip).
- `:rr_eigenfunctions` ← [`rr_eigenfunctions_plot_data`](@ref) — one covariance-function
  eigenfunction per line with a per-axis variance-explained legend; the subtitle states
  it is rotation-invariant, signs are arbitrary, and the span is ambiguous under repeated
  eigenvalues.

The honest-status caveat is always rendered on the figure (subtitle), sourced from the
SAME flags the preparer carries — this is the drawing-layer half of the plotting
layer's "subtitle drop is the only guardrail" defense (`docs/design/13-plotting-layer.md`).
Drawing only — no estimation, no engine computation.
"""
function hsquared_figure end

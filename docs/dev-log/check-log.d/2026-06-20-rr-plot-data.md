# 2026-06-20 Random-regression plot-data preparers (#54, plotting layer)

- **Goal:** land the FIRST slice of the ratified plotting layer
  (`docs/design/13-plotting-layer.md`) — the engine `*_plot_data` preparers for the
  random-regression figure set, feeding the R `autoplot.R` + the future
  `HSquaredMakieExt`. Data already exists (PR #88); the slice is thin, deterministic,
  backend-free, honest-status-flagged.
- **Active lenses:** Florence (figures/diagnostics) + Hopper (R↔Julia plot-data
  contract) + Rose (claims). Ultracode design pass (DRM.jl/GLLVM.jl/ecosystem scout →
  Florence synthesis) produced the design.
- **What landed (exported):** `rr_eigenfunctions_plot_data(K_g, ts)`,
  `rr_genetic_variance_plot_data(K_g, ts; residual)`,
  `rr_covariance_surface_plot_data(K_g, ts; correlation)` — thin wrappers that
  re-shape the existing RR descriptors into the `marker_*_data` `*_plot_data`
  NamedTuple convention + carry honest-status flags (`supplied`,
  `rotation_invariant`). Guards delegated to the underlying descriptors.
- **TDD:** test-first; the 3 functions did not exist (`UndefVarError`). New testset
  `Phase 3 random-regression plot-data preparers (#54, plotting layer)` = **18/18 Pass**;
  full `Pkg.test()` green (`TESTS_EXIT=0`).
- **Gates:** delegation equality to `rr_eigenfunctions`/`rr_genetic_variance`/
  `rr_genetic_covariance_surface`/`rr_genetic_correlation_surface`; the
  `propertynames` shape; honest-status flags (`rotation_invariant === true`,
  `supplied === true`); residual→`h²` path; non-PSD `K_g` + `|t|>1` guards delegate.
- **Docs:** docstrings carry the Florence caveats (SUPPLIED/descriptive,
  rotation-invariant, sign/span ambiguity); `docs/src/api.md` rows added;
  `docs/design/13-plotting-layer.md` persists the full plotting contract; `docs/make.jl`.
- **Honest status:** plot-DATA only — NO backend/drawing claim, NO estimation claim,
  nothing promoted to covered. `validation_status()` unchanged at 38 rows.
- **Cross-lane:** the R lane already has `hsquared/R/autoplot.R` (autoplot.hsquared_fit
  + hs_gwas Manhattan + theme_hsquared + the hsquared_meta/hsquared_data attr pattern);
  these preparers feed it. The plotting contract is staged for a cross-lane note.

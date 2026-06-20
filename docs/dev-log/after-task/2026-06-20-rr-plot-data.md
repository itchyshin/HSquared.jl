# After-task — Random-regression plot-data preparers (#54, plotting layer)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/rr-plot-data`. First slice of the ratified plotting layer
(`docs/design/13-plotting-layer.md`).

## Summary

Landed the first engine `*_plot_data` preparers — `rr_eigenfunctions_plot_data`,
`rr_genetic_variance_plot_data`, `rr_covariance_surface_plot_data` (all exported) —
thin, deterministic, backend-free wrappers re-shaping the existing RR descriptors
(PR #88) into the `marker_*_data` NamedTuple convention with honest-status flags
(`supplied`, `rotation_invariant`). They feed the R `autoplot.R` ggplot2 layer and
the planned `HSquaredMakieExt`. Plot-DATA only — no drawing, no estimation.

## Definition of Done

- implementation — 3 preparers in `src/random_regression.jl`; exported.
- tests — "Phase 3 random-regression plot-data preparers (#54, plotting layer)"
  (18 assertions): delegation equality, `propertynames` shape, honest-status flags,
  residual→`h²`, delegated guards. **18/18 Pass; full suite green.**
- documentation — docstrings with Florence caveats; `docs/src/api.md`;
  `docs/design/13-plotting-layer.md` (the full plotting contract).
- example / not-public note — plot-DATA only, no backend/estimation claim.
- check-log — `docs/dev-log/check-log.d/2026-06-20-rr-plot-data.md`.
- after-task — this file.
- capability-status row — added (RR plot-data preparers).
- validation-debt row — `V3-RR-DESC` register note extended; `validation_status()`
  unchanged at 38 rows.
- Rose audit — see below.
- clean local checks — `Pkg.test()` green; `docs/make.jl`.
- clean CI — gated on the PR.

## Design provenance

Ultracode design pass (`hsquared-plotting-design` workflow): scouted DRM.jl
(`src/visualization.jl`) + GLLVM.jl + drmTMB/gllvmTMB/`hsquared/R/autoplot.R` + the
quant-gen viz ecosystem; Florence synthesized the plot-data API + Makie-extension
plan + R ggplot2 contract + the binding honest-status figure contract. Architecture
user-ratified: engine plot-data → R ggplot2 + Julia Makie ext; all 4 figure sets;
Makie-extension confirmed (sisters use docs-scripts, but plotting is first-class here).

## Claim boundary

Plot-DATA preparers only — deterministic re-shaping of supplied-`K_g` descriptors;
no drawing backend, no estimation, rotation-invariant. Nothing promoted to covered.
The remaining preparers (B variance-components, C genetic-correlation + G-geometry,
already-existing D GWAS), the `HSquaredMakieExt`, and the R-side autoplot types are
the runway (see `13-plotting-layer.md`).

## Next

Plotting set C `genetic_pca_plot_data` is the most honest-status-critical (the HARD
rotation-invariance contract: G eigenstructure only, never raw loadings) — strong
next slice. Then set B (variance-components forest) + the `HSquaredMakieExt`. The
genetic-GLLVM descriptors slice (#50, design pending) remains the other open build.

# After-task — G-geometry plot-data preparers (set C, plotting layer)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/g-geometry-plot-data`. Plotting-layer set C (the rotation-invariant
G-geometry figures); follows set A (RR plot-data, PR #91).

## Summary

Landed `genetic_pca_plot_data(G; n_axes)` and `genetic_correlation_plot_data(G;
traits, heritabilities)` (both exported, in `src/evolvability.jl`) — backend-free
`*_plot_data` preparers for the G-geometry figure set. The eigen preparer surfaces
only the rotation-INVARIANT eigenstructure of `G` (eigenvalues, principal axes,
biplot `loadings_scaled = eigenvectors·√λ`); the correlation preparer returns the
`D⁻¹GD⁻¹` heatmap data + trait labels. The single most honest-status-critical
plotting slice: it enforces the FA rotation convention at the plotting boundary —
a covariance `G` is the only input, raw factor-analytic loadings `Λ` are never
accepted or returned.

## Definition of Done

- implementation — 2 preparers in `src/evolvability.jl`; exported.
- tests — "G-geometry plot-data preparers (#54 plotting, rotation-invariant)":
  delegation-equality, `variance_explained` sums to 1, `loadings_scaled = V·√λ`,
  **rotation-invariance** (`G=ΛΛᵀ` vs `ΛQ` → identical eigenvalues), `:loadings`
  absent, `n_axes`/label/indefinite-`G` guards. Full suite green.
- documentation — docstrings (HARD-CONTRACT note); `docs/src/api.md`;
  `docs/design/13-plotting-layer.md` set C → landed; `docs/make.jl`.
- check-log — `docs/dev-log/check-log.d/2026-06-20-g-geometry-plot-data.md`.
- after-task — this file.
- capability-status row — "Plot-data preparers (plotting layer)" extended.
- validation-debt — `validation_status()` unchanged (38 rows); plotting tracked in
  capability-status + `13-plotting-layer.md`.
- Rose audit — see below.
- clean local checks — `Pkg.test()` + `docs/make.jl`.
- clean CI — gated on the PR.

## Claim boundary

Plot-DATA only — deterministic re-shaping of a supplied covariance `G` into its
rotation-invariant functionals; no drawing backend, no estimation. Nothing promoted
to covered. Sets A + C of the plotting layer are now landed; set B
(variance-components forest), the GWAS set D (already exists), the `HSquaredMakieExt`,
and the R-side autoplot types remain the runway (`13-plotting-layer.md`).

## Next

Set B `variance_components_plot_data(fit; level)` (forest/caterpillar, asymptotic
intervals — carries the "EXPERIMENTAL, not coverage-calibrated" caveat); then the
`HSquaredMakieExt` extension + the cross-lane plotting coordination note. The
genetic-GLLVM descriptors slice (#50) remains the other open build.

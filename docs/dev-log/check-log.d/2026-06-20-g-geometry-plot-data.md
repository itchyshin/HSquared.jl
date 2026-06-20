# 2026-06-20 G-geometry plot-data preparers (set C, plotting layer)

- **Goal:** land plotting-layer set C — the rotation-invariant G-geometry preparers.
  The most honest-status-critical plotting slice: enforces the FA rotation
  convention at the plotting boundary (G eigenstructure in, NEVER raw loadings out).
- **Active lenses:** Kirkpatrick (genetic axes) + Florence (figures) + Rose (claims).
- **What landed (exported):** `genetic_pca_plot_data(G; n_axes)` — rotation-invariant
  eigenstructure (eigenvalues, variance_explained, sign-canonicalized eigenvectors,
  biplot `loadings_scaled = eigenvectors·√λ`, axis_labels, flags
  `rotation_invariant`/`is_eigenstructure_not_loadings`); `genetic_correlation_plot_data(G;
  traits, heritabilities)` — `D⁻¹GD⁻¹` heatmap data + trait labels. Thin delegations
  to `genetic_pca` / `genetic_correlation` (evolvability.jl).
- **HARD CONTRACT:** the input is a covariance `G`; raw factor-analytic loadings `Λ`
  are never accepted or returned. The eigen preparer surfaces only the rotation-
  invariant eigenstructure (`:loadings` is absent from `propertynames`).
- **TDD:** test-first (`UndefVarError` RED). New testset `G-geometry plot-data
  preparers (#54 plotting, rotation-invariant)` green; full `Pkg.test()` green.
- **Gates (`test/runtests.jl`):** delegation-equality to `genetic_pca`/
  `genetic_correlation`; `variance_explained` sums to 1; `loadings_scaled = V·√λ`;
  **rotation-invariance** — low-rank `G=ΛΛᵀ` and rotated `ΛQ` give identical
  eigenvalues; `:loadings`-absent shape; `n_axes`/label/indefinite-`G` guards.
- **Docs:** docstrings with the HARD-CONTRACT note; `docs/src/api.md`;
  `docs/design/13-plotting-layer.md` set C → landed; `docs/make.jl`.
- **Honest status:** plot-DATA only — no backend, no estimation, rotation-invariant;
  capability-status "Plot-data preparers (plotting layer)" row extended;
  `validation_status()` unchanged at 38 rows; nothing covered-promoted.

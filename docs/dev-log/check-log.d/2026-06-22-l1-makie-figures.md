# 2026-06-22 L1 — HSquaredMakieExt figure kinds (set D markers + set A RR)

- Goal: extend the `HSquaredMakieExt` weak-dep drawing extension with 5 new
  `kind`s (`:manhattan`, `:qq`, `:rr_variance`, `:rr_surface`,
  `:rr_eigenfunctions`) consuming already-exported `*_plot_data` preparers.
  Drawing-only — NO new `src/` numerics, NO new export, NO `Project.toml` change.
- Starting point: HSquared.jl `main` at `2e8f15da` (after #166); branch
  `claude/l1-makie-figures`.
- Files changed:
  - `ext/HSquaredMakieExt.jl` — 5 drawing methods (`_manhattan`, `_qq`,
    `_reaction_norm`, `_rr_surface`, `_eigenfunctions`) + 5 `_infer_kind` cases
    + 5 dispatcher branches + the 9-kind ArgumentError lists.
  - `src/plotting_ext.jl` — stub docstring extended with the 5 new kinds (still
    a method-less stub; no `/src` code).
  - `test/runtests.jl` — the `hsquared_figure drawing stub` testset extended
    from 5 → 11 total assertions (the `@test_throws MethodError` payloads 3 → 9,
    one per dispatched kind incl. the previously-uncovered `:g_geometry`).
  - `docs/design/validation-debt-register.md` (`V-PLOT-DRAW`), `docs/design/13-plotting-layer.md` (§8 table + counts).
- Checks run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` (thread-capped):
    **"Testing HSquared tests passed"** — the expanded 10-assertion stub testset
    + full suite green.
  - **LOCAL draw verification** (CairoMakie 0.15.11 / Makie 0.24.x, scratch env
    `/tmp/hsq_makie_env`; `/tmp/l1_verify.jl`): **ALL 30 checks PASS** —
    - `_infer_kind` routes all 5 new kinds correctly AND the eigenvalues-collision
      guard holds (`genetic_pca_plot_data` → `:g_geometry`,
      `rr_eigenfunctions_plot_data` → `:rr_eigenfunctions`);
    - all 5 kinds draw a `Makie.Figure` inferred + explicit (10 draws);
    - honest-status branches fire: Manhattan/QQ "NOT genome-wide calibrated"
      subtitles; reaction-norm 2 panels with residual / 1 without; rr_surface
      correlation colorrange `(-1,1)` vs covariance data-driven (`≠ (-1,1)`);
      eigenfunctions "signs arbitrary" subtitle;
    - all 6 figures rasterize to PNG (`/tmp/l1_*.png`).
- Status: DRAWING capability only — no estimation, no statistical claim promoted;
  `validation_status()` rows UNCHANGED (the drawing extension has no
  `ValidationStatusRow`, tracked in the debt register + design-doc §8, the PR #121
  precedent); nothing promoted to covered; public-default covered count UNCHANGED.
- Retained debt: the draw under CI or a reproducible docs-render; R `autoplot.R`
  ↔ `hsquared_figure` per-figure drawing-parity snapshots; a Makie-compat pinned
  render-diff guard — before any "Julia plots" public claim.

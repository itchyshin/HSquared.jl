# 2026-06-20 HSquaredMakieExt — genetic-correlation heatmap kind (set C)

- **Goal:** round out the `HSquaredMakieExt` drawing extension (PR #117) with the
  set-C genetic-correlation **heatmap** kind — the natural pair to the G-eigenvalue
  scree already drawn. Drawing-only; the preparer `genetic_correlation_plot_data`
  already exists.
- **Active lenses:** Florence (figures) + Kirkpatrick (G-matrix / rotation) + Rose (claims).
- **What landed (`ext/HSquaredMakieExt.jl`):** a `:genetic_correlation` kind +
  `_heatmap(d)` — a `D⁻¹GD⁻¹` heatmap (diverging `:RdBu` colormap, `colorrange=(-1,1)`,
  unit diagonal, `yreversed` conventional layout, per-cell value annotation, colorbar).
  Honest-status (#93 set-C contract): gated on `rotation_invariant` (a non-invariant /
  raw-loadings payload throws `ArgumentError` — the FA rotation convention); when
  `heritabilities` are supplied, low-h² (`< 0.1`) traits are FLAGGED in the subtitle
  ("⚠ low-h² (imprecise) trait(s): …"). `_infer_kind` gains the `genetic_correlations`
  field; the dispatcher + stub docstring updated.
- **CI test (`test/runtests.jl`, stub testset now 5 assertions):** added the
  `genetic_correlations` payload shape to the method-less-stub `MethodError` check
  (the kind is in the ext, which is not loaded in CI — Makie stays OUT of default CI).
- **LOCAL draw verification (CairoMakie, scratch env):** inferred + explicit
  `:genetic_correlation` → `Makie.Figure`; the no-h² path draws; the
  non-rotation-invariant payload is rejected (`ArgumentError`); the figure rasterizes
  to PNG (visually confirmed: unit diagonal, symmetric off-diagonals, the "wing"
  low-h² flag in the subtitle).
- **Florence review (figure-honesty subagent):** confirmed the rotation-invariant gate
  is genuinely enforced (plots `D⁻¹GD⁻¹`, never `Λ`), the fixed `colorrange=(-1,1)` is
  honest (weak correlations not auto-exaggerated), RdBu is colorblind-safe, and the
  zero/near-zero-variance NaN trap is caught UPSTREAM (`genetic_correlation` throws on a
  non-positive diagonal). CAUGHT one real honesty gap: a **NaN heritability was silently
  not flagged** (`NaN < 0.1` is false) — FIXED (`!isfinite(h) || h < low_h2`, so a missing/
  NaN h² is treated as maximally imprecise; locally verified the NaN trait is now flagged).
  Also surfaced the threshold in the caveat (`<0.1`). Deferred (acceptable for this slice,
  noted): per-cell visual imprecision cue (the flag is a subtitle trait list, not a cell
  grey-out).
- **Checks:** `Pkg.test()` GREEN (the +1 stub assertion); `docs/make.jl` GREEN
  (`13-plotting-layer.md` §8 table + the stub docstring updated). `validation_status()`
  UNCHANGED (41 — drawing capability, no statistical claim).
- **Honest status:** DRAWING only — no estimation, no statistical claim promoted; the
  draw is LOCAL-verified (Makie out of CI), per the existing `V-PLOT-DRAW` debt.
  Nothing promoted to `covered`.

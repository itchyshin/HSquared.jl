# After-task — HSquaredMakieExt genetic-correlation heatmap (set C)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/makie-genetic-correlation`. A bounded follow-on to the `HSquaredMakieExt`
drawing extension (PR #117), rounding out set C with the genetic-correlation heatmap
— the natural pair to the G-eigenvalue scree already drawn.

## Summary

Added a `:genetic_correlation` figure kind to `HSquaredMakieExt`: `_heatmap(d)` draws
the rotation-invariant `D⁻¹GD⁻¹` genetic-correlation matrix as a heatmap (diverging
`:RdBu` colormap centred at 0, `colorrange = (-1, 1)`, unit diagonal, conventional
`yreversed` layout, per-cell value annotation, colorbar) from the existing
`genetic_correlation_plot_data` preparer. Honest-status behaviors (#93 set-C
contract) rendered ON the figure: gated on `rotation_invariant` (a raw-loadings /
non-invariant payload is rejected with `ArgumentError` — the FA rotation convention),
and when `heritabilities` are supplied the low-h² (imprecise) traits are flagged in
the subtitle. `/src` stays dependency-free (the method lives in the ext).

## Definition of Done

- implementation — `ext/HSquaredMakieExt.jl`: `_heatmap` + the `_infer_kind` /
  dispatcher cases; `src/plotting_ext.jl` stub docstring updated.
- tests — `test/runtests.jl` stub testset extended (now 5 assertions; the new payload
  shape also throws `MethodError` without a backend). The full draw is LOCAL-verified
  with CairoMakie (inferred + explicit kind, the no-h² path, the rotation-invariant
  guard, PNG rasterization) — Makie stays OUT of CI (cost discipline).
- documentation — stub docstring; `13-plotting-layer.md` §8 table row; the
  capability-status drawing-extension row + the `V-PLOT-DRAW` debt row updated
  (four kinds, 5 stub assertions). `docs/make.jl` clean.
- check-log — `docs/dev-log/check-log.d/2026-06-20-makie-genetic-correlation-heatmap.md`.
- after-task — this file.
- review — Florence (figure-honesty subagent): confirmed the rotation-invariant gate,
  the honest fixed `colorrange`, colorblind-safe RdBu, and the upstream NaN-trap guard;
  CAUGHT a silent NaN-h² flag gap — FIXED (`!isfinite(h) || h < low_h2`) + the threshold
  surfaced in the caveat. Deferred (noted): a per-cell imprecision cue.
- clean local checks — `Pkg.test()` + `docs/make.jl` GREEN; local CairoMakie draw + PNG.
- clean CI — gated on the PR (CI runs the stub contract only, by design).

## Honest status

DRAWING capability only — no estimation, no statistical claim promoted. The draw is
locally attested (Makie out of CI), per the recorded `V-PLOT-DRAW` debt.
`validation_status()` UNCHANGED (41 rows); nothing promoted to `covered`.

## Next

Remaining HSquaredMakieExt follow-on kinds: GWAS Manhattan + QQ (set D —
`marker_manhattan_data` / `marker_qq_data` already exist), and the RR set-A figures
(reaction-norm / eigenfunctions / surface). None gates this slice.

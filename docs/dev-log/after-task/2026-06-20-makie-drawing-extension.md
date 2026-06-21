# After-task — HSquaredMakieExt (Julia drawing extension, plotting layer §8)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/makie-drawing-extension`. The "solo item" the user authorized for this
window: build the Julia drawing HALF of the plotting layer now that all the set
B/C `*_plot_data` preparers are landed and the R-twin's #93 drawing-behavior
checklist is in hand.

## Summary

Landed `HSquaredMakieExt`, the Makie weak-dependency package extension that draws
the engine's `*_plot_data` preparers. Architecture (per `13-plotting-layer.md` §1):
`/src` stays dependency-free — it carries only an exported, method-less STUB
`hsquared_figure(data; kind, …)` (`src/plotting_ext.jl`) plus the honest-status
drawing contract docstring; the drawing METHODS live in `ext/HSquaredMakieExt.jl`
(`Makie` in `[weakdeps]`/`[extensions]`, pinned `[compat] = "0.24"`), which Julia
loads only when a Makie backend is in scope (`using CairoMakie` / `GLMakie`).

One dispatcher consumes the set B/C preparers and infers `kind` from the carried
fields (override: `:variance_components` / `:breeding_values` / `:g_geometry`),
rendering the R-twin's #93 honest-status behaviors ON the figure:

- **VC + h² forest** (`variance_components_plot_data`): RAW whiskers, never clamped
  (a VC whisker crossing 0 is expected/honest); the `[0,1]` crossing annotated on the
  **h² panel ONLY**; `NaN` → no whisker; supplied/estimated + `interval_status`
  ("NOT coverage-calibrated") in the subtitle.
- **EBV caterpillar** (`breeding_values_plot_data`): sorted EBV ± `√PEV`; the
  `pev_scale = "validation"` caveat (dense `inv(Ainv)`, not production reliability)
  in the subtitle.
- **G-geometry scree** (`genetic_pca_plot_data`): eigenvalue **scree only**, gated on
  `is_eigenstructure_not_loadings` — a loadings biplot is REJECTED (`ArgumentError`,
  the FA rotation convention); a non-PD `G` (negative eigenvalue) draws the bar but
  SUPPRESSES the %-variance labels.

This is the drawing-layer half of the plotting layer's "subtitle drop is the only
guardrail" defense (§5.2): the caveat is sourced from the SAME flags the preparer
carries.

## Definition of Done

- implementation — `Project.toml` weak-dep wiring; `src/plotting_ext.jl` stub +
  docstring; `ext/HSquaredMakieExt.jl` drawing methods; `src/HSquared.jl` include +
  export. `/src` remains dependency-free.
- tests — "hsquared_figure drawing stub (HSquaredMakieExt weak-dep, #93)": 4
  assertions (stub is a method-less `Function`; `MethodError` until a backend loads —
  two payload shapes). Full suite green. The full DRAW is verified LOCALLY (Makie out
  of CI — cost discipline), not in CI.
- documentation — the contract docstring on the stub; `docs/src/api.md`;
  `13-plotting-layer.md` §8 (new) + status line; the capability-status row;
  the `V-PLOT-DRAW` validation-debt row.
- check-log — `docs/dev-log/check-log.d/2026-06-20-makie-drawing-extension.md`
  (incl. the local CairoMakie draw-and-rasterize evidence).
- after-task — this file.
- Rose audit — inline below.
- clean local checks — `Pkg.test()` + `docs/make.jl` GREEN; local CairoMakie draw of
  all three kinds + a 60 KB PNG rasterization.
- clean CI — gated on the PR (CI runs the stub contract only, by design).

## Rose claim-vs-evidence audit (inline): CLEAN

- **No over-claim.** This is a DRAWING capability only — no estimation, no engine
  computation in the extension, no statistical/performance/fitting claim promoted.
  `validation_status()` is UNCHANGED (41 rows): a drawing capability correctly gets
  no validation row.
- **Honest-status surfaced, not hidden.** Every honest-status caveat the preparers
  carry (`supplied`, `interval_status`, `pev_scale`, `is_eigenstructure_not_loadings`)
  is rendered ON the figure; the loadings-biplot guard and non-PD-`G` label
  suppression are enforced in the draw, matching the §4 figure contract.
- **CI vs local boundary stated, not blurred.** The capability-status row and the
  `V-PLOT-DRAW` debt row BOTH say plainly: CI exercises only the stub; the draw is
  verified locally only (Makie out of CI); the draw is NOT a CI-gated claim. The
  recorded debt (CI-gate the draw OR a reproducible docs-render; R drawing parity;
  Makie-compat-churn guard) is honest about what remains.
- **Cost discipline honored** (user's CLAUDE.md): the heavy Makie stack is kept out
  of the default test/CI environment via the weak-dep extension; local checks did the
  verification.

## Cross-lane note (NOT posted — outward posting is the user's call)

The R lane's #93 drawing-behavior checklist is now IMPLEMENTED on the Julia side
(`hsquared_figure`). When R wires `autoplot.R` to consume the bridge `*_plot_data`
payloads (today it recomputes), a future `autoplot.R` ↔ `hsquared_figure` drawing
parity test is the guardrail — recorded as debt, not posted. Still-open #61
Binomial-payload question and the already-fixed #38 remain for the user on the
outward/coordination side.

## Next

CI-gate the draw (or a reproducible docs-render figure) so the draw is gated, not
just locally attested; follow-on figure kinds (reaction-norm / RR eigenfunctions /
RR surface from set A, Manhattan/QQ from set D, genetic-correlation heatmap from set
C); the live RR parity test; per-record `n_trials` for the Binomial bridge if R
confirms it.

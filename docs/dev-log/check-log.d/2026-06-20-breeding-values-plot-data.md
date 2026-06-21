# 2026-06-20 breeding_values_plot_data (last #93 live-parity preparer)

- **Goal:** close the last live-parity plot-data gap the R twin flagged on #93 —
  surfaced by a cross-lane ISSUE CHECK during CI wait-time (user suggestion).
- **Active lenses:** Florence (figures) + Hopper (R contract) + Rose (claims).
- **What landed (exported, `src/likelihood.jl`):**
  `breeding_values_plot_data(fit::AnimalModelFit; trait = 1)` → tidy
  `(id, trait, value, pev, pev_scale = "validation")` — EBV as `value`, validation-scale
  PEV, shaped for R's `autoplot.R` caterpillar plot (exact R-column convention, #93).
- **Doc fix:** `13-plotting-layer.md` §7 stale "h² rows clamped to `[0,1]`" → logit-delta
  interval in `(0,1)` by construction (raw + annotate, no clamp) — R-flagged on #93.
- **TDD:** new testset green (7 assertions: shape, value==EBV, pev==PEV, pev_scale flag,
  trait kwarg); full `Pkg.test()` green.
- **Docs:** docstring; `docs/src/api.md`; capability-status plot-data row extended;
  `13-plotting-layer.md` updated; `docs/make.jl` clean.
- **Honest status:** plot-DATA only (no drawing/estimation); `pev_scale = "validation"`
  carries the PEV caveat; delegates to validated extractors. `validation_status()`
  unchanged (41); nothing covered.
- **Rose audit:** CLEAN (inline). Honest flags present; no over-claim; the cross-lane
  intel (#61 binomial-payload Q, #38-already-fixed) recorded for the user, NOT posted.

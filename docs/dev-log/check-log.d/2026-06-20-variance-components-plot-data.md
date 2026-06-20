# 2026-06-20 Variance-component forest plot-data (set B, plotting layer)

- **Goal:** land plotting-layer set B — `variance_components_plot_data(fit; level)`,
  shaped (per the R-twin alignment, #93) to drop directly into R's `hs_gg_forest`.
- **Active lenses:** Florence (figures) + Fisher (intervals) + Hopper (R contract) +
  Rose (claims).
- **What landed (exported):** `variance_components_plot_data(fit::AnimalModelFit;
  level = 0.95)` → `(term, estimate, lo, hi, panel, level, interval_method,
  interval_status, supplied = false)`. VC rows carry asymptotic `estimate ± z·SE`
  (NOT clamped — asymptotic CI may cross 0, surfaced); the `h2` row carries the
  logit-delta `heritability_interval` (in (0,1)); `lo`/`hi` are `NaN` where the
  interval is unavailable (no fabricated whiskers); `interval_status` is
  `experimental_asymptotic` (not coverage-calibrated) when present, else `none`;
  `supplied = false` is the honest-status hinge vs the descriptive supplied-`K_g`/`G`
  sets. Degrades gracefully (try/catch) when the REML SE machinery is unavailable.
- **TDD:** test-first (`UndefVarError` RED). New testset `Variance-component forest
  plot-data (#54 set B, R hs_gg_forest)` green; full `Pkg.test()` green.
- **Gates:** tidy shape + `propertynames`; estimate-equality to `variance_components`/
  `heritability`; REML interval-consistency vs `heritability_interval` (h2 row in
  (0,1)); VC-row normal-Wald whiskers pinned to `variance_component_standard_errors`
  (`estimate ± z·SE`, unclamped); ML graceful-degrade (REML-only SEs → points-only,
  all-NaN whiskers, status `none`); `level ∉ (0,1)` guard.
- **Rose audit:** independent `rose-systems-auditor` pass at takeover → CLEAN-WITH-NITS,
  no blockers; 3 nits fixed in-PR (docstring "REML fits only" reworded to intervals-only;
  `interval_method` roll-up documented; VC-row whisker assertion added). All
  honest-status flags confirmed backed; `validation.jl` untouched (38 rows).
- **Docs:** docstring (honest-status caveats); `docs/src/api.md`;
  `docs/design/13-plotting-layer.md` set B → landed; capability-status row extended;
  `docs/make.jl`.
- **Honest status:** plot-DATA only — no drawing backend; `supplied = false`
  (estimated); intervals asymptotic/uncalibrated (flagged). `validation_status()`
  unchanged at 38 rows; nothing covered-promoted.
- **Cross-lane:** consumes the R `hs_gg_forest` tidy contract (term/estimate/lo/hi/
  panel) directly, per the #93 alignment. Sets A+B+C+D of the plotting layer now have
  engine plot-data.

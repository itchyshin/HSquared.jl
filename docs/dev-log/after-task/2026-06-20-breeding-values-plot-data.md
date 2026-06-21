# After-task — breeding_values_plot_data (the last #93 live-parity preparer)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/breeding-values-plot-data`. Surfaced by a cross-lane ISSUE CHECK (the user
suggested using wait-time to check issues): the R lane's #93 reply spec'd the one
missing plot-data preparer and flagged a stale doc line.

## Summary

Landed `breeding_values_plot_data(fit::AnimalModelFit; trait = 1)` (exported,
`src/likelihood.jl`) — the EBV "caterpillar" plot-data preparer, the LAST live-parity
gap the R twin flagged on issue #93. Tidy parallel vectors
`(id, trait, value, pev, pev_scale = "validation")`, shaped to drop directly into R's
`autoplot.R` breeding-value plot: `value` is the EBV (`breeding_values(fit)`),
`pev` the prediction error variance (`prediction_error_variance(fit)`, dense path),
and `pev_scale = "validation"` is the honest-status flag (the PEV denominator forms
the dense `inv(Ainv)` — validation-scale, NOT a production reliability claim). The R
column convention (EBV as `value`) is followed exactly.

Also fixed the stale `13-plotting-layer.md` §7 wording R flagged: "h² rows clamped to
`[0,1]`" → the logit-delta `heritability_interval` is in `(0,1)` BY CONSTRUCTION (raw +
annotate, NOT clamped — per the #93 resolution).

## Definition of Done

- implementation — `breeding_values_plot_data` in `src/likelihood.jl`; exported.
- tests — "breeding_values_plot_data (#54 set B, EBV caterpillar, #93 parity)": 7
  assertions (`propertynames`, `value`==`breeding_values`, `pev`==`prediction_error_variance`,
  the `pev_scale` flag, the `trait` kwarg). Full suite green.
- documentation — docstring (honest caveats); `docs/src/api.md`; the plot-data-preparers
  capability-status row extended; `13-plotting-layer.md` §7 stale-clamp wording fixed +
  the preparer noted.
- check-log — `docs/dev-log/check-log.d/2026-06-20-breeding-values-plot-data.md`.
- after-task — this file.
- Rose audit — inline: CLEAN. Plot-DATA only (no drawing, no estimation); the
  `pev_scale = "validation"` flag carries the validation-scale PEV caveat honestly; it
  delegates to the validated `breeding_values`/`prediction_error_variance` extractors;
  `validation_status()` unchanged (plotting tracked in capability-status). Nothing covered.
- clean local checks — `Pkg.test()` + `docs/make.jl`.
- clean CI — gated on the PR.

## Cross-lane note (from the issue check, NOT posted — outward posting is the user's call)

The #93 R-lane reply also delivered: (a) confirmation the engine preparers were ~90%
drop-in (the plotting contract is effectively ratified); (b) a Makie drawing-behavior
checklist for the future `HSquaredMakieExt` (drawing-layer, no engine change); (c) on
#61, the non-Gaussian method-string contract (`laplace`/`va` + aliases) is resolved
R-side, with an open question on the Binomial bridge payload (R proposes passing
`(y = successes, n_trials = total)` to `fit_laplace_reml` — which matches the engine's
`BinomialResponse(n_trials)`, though the engine currently takes a SCALAR `n_trials`, so
per-record trials would be a future engine slice); (d) #38 (the 250-animal AI-matrix
claim) is ALREADY fixed on `main` (stale issue). These are recorded for the user to act
on the outward/coordination side.

## Next

The `HSquaredMakieExt` drawing extension (now that all preparers incl.
`breeding_values_plot_data` are landed and the R drawing-behavior checklist is in hand);
the live RR parity test (the #93 discipline); per-record `n_trials` for the Binomial
bridge (if R confirms it needs it).

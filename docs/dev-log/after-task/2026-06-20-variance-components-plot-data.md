# After-task — Variance-component forest plot-data (set B, plotting layer)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/variance-components-plot-data`. Plotting-layer set B, shaped to the R-twin
alignment (#93).

## Summary

Landed `variance_components_plot_data(fit::AnimalModelFit; level = 0.95)` (exported,
`src/likelihood.jl`) — the variance-component + heritability forest plot-data, tidy
parallel vectors `(term, estimate, lo, hi, panel, level, interval_method,
interval_status, supplied = false)` designed to drop directly into R's `hs_gg_forest`
(per the #93 R-twin alignment). VC rows carry asymptotic `estimate ± z·SE` (unclamped);
the `h2` row the logit-delta interval (in (0,1)); `NaN` whiskers when intervals are
unavailable; graceful degrade when the REML SE machinery is absent. `supplied = false`
is the honest-status hinge — these are ESTIMATED, unlike sets A/C.

## Definition of Done

- implementation — `variance_components_plot_data` in `src/likelihood.jl`; exported.
- tests — "Variance-component forest plot-data (#54 set B, R hs_gg_forest)": tidy
  shape + `propertynames`, estimate-equality, REML interval-consistency vs
  `heritability_interval` (h2 in (0,1)), the VC-row normal-Wald whiskers
  (`estimate ± z·SE`, unclamped, pinned to `variance_component_standard_errors`),
  ML graceful-degrade (points-only), `level` guard. Full suite green.
- documentation — docstring (honest caveats); `docs/src/api.md`;
  `docs/design/13-plotting-layer.md` set B → landed; capability-status row extended.
- check-log — `docs/dev-log/check-log.d/2026-06-20-variance-components-plot-data.md`.
- after-task — this file.
- capability-status row — "Plot-data preparers (plotting layer)" extended (set B).
- validation-debt — `validation_status()` unchanged (38 rows); plotting tracked in
  capability-status + `13-plotting-layer.md`.
- Rose audit — see below.
- clean local checks — `Pkg.test()` + `docs/make.jl`.
- clean CI — gated on the PR.

## Rose audit (claim-vs-evidence)

An independent `rose-systems-auditor` pass ran at session takeover: **CLEAN-WITH-NITS,
no blockers**. It confirmed every load-bearing honest-status claim is backed by
code + a test assertion (`supplied = false`, `interval_status`, NaN whiskers, ML
graceful-degrade via `variance_component_covariance` throwing for non-REML), nothing
promoted to covered, and `validation.jl` untouched (38 rows hold). Three nits were
fixed in-PR before merge:

1. Docstring said "REML fits only", contradicting the function's own ML-fit test —
   reworded to "intervals are REML-only; a non-REML fit degrades to points-only".
2. `interval_method = "asymptotic_reml"` is a coarse roll-up over two constructions
   (normal-Wald VC rows, logit-delta h²) — docstring now says so explicitly.
3. The headline VC-row whisker claim (`estimate ± z·SE`, unclamped) was prose-only,
   not asserted — added four assertions pinning `pd.lo/hi[1:2]` to
   `variance_component_standard_errors`.

## Claim boundary

Plot-DATA only — deterministic re-shaping of a fitted model's VC/h² estimates +
asymptotic intervals into R's forest contract; `supplied = false` (estimated);
intervals asymptotic / NOT coverage-calibrated (flagged `experimental_asymptotic`).
No drawing backend. Univariate `AnimalModelFit` only (multivariate per-trait h² is a
follow-up per the alignment). Nothing promoted to covered.

## Next

Plotting sets A+B+C+D now all have engine plot-data. Remaining plotting runway: the
`HSquaredMakieExt` weak-dep extension (Julia drawing), the R-side autoplot adoption +
the field-rename/melt/meta decisions (held on #93), and the live parity test. The
genetic-GLLVM #50 descriptors slice remains the other open engine build.

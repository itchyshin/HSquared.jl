# Marker Significance Summary Scout

Date: 2026-06-14

## Question

How should `HSquared.jl` expose threshold-like marker-scan summaries without
claiming calibrated GWAS/QTL/eQTL significance?

## Sources Checked

- Local `gllvmTMB/R/diagnose.R`: diagnostic tables carry explicit status,
  threshold, message, and action fields; warnings are framed as interpretation
  aids, not truth claims.
- Local `gllvmTMB/R/confint-inspect.R`: threshold geometry is exposed as
  `excess_over_threshold` and `in_ci`, making the comparison visible instead of
  hidden inside prose.
- Local `drmTMB/R/check.R`: diagnostic threshold wording is conservative and
  routes users to model-health interpretation rather than capability promotion.
- Existing `HSquared.jl` Phase 5 helpers: `marker_qq_data`,
  `marker_genomic_inflation`, `marker_region_data`, and `marker_scan_table`
  consistently prepare deterministic direct-Julia data while blocking public
  formula, plotting, calibration, and comparator claims.

## Lesson

Threshold-adjacent outputs should be returned as explicit diagnostic data:
thresholds, flags, counts, marker IDs, and original scan indices. Public text
must say the summaries are nominal over the returned marker set and do not
define calibrated correlated-marker genome-wide significance thresholds.

## HSquared Action

Add `marker_significance_summary(scan; alpha)` as a direct Julia summary helper
over already-computed scan fields. Keep it out of the R formula grammar and
bridge payload. Record it under the existing partial `V5-MARKER-FIXED` row,
not as a new covered QTL/GWAS capability.

## Claim Wording Risk

The word "significance" is familiar to users but risky. Allowed wording:
"nominal raw-p, Bonferroni, and BH flags/counts over the returned marker set."
Blocked wording: "calibrated GWAS threshold", "genome-wide significant QTL",
"validated QTL/eQTL scan", or "fine-mapped region".

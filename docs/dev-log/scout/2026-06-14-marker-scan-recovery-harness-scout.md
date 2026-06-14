# Marker-Scan Recovery Harness Scout

Date: 2026-06-14

## Question

How should `HSquared.jl` record seeded marker-signal recovery for the direct
fixed, supplied-variance mixed, and supplied LOCO marker-scan helpers without
claiming calibrated GWAS/QTL/eQTL validation?

## Sources Checked

- Existing `HSquared.jl` recovery harnesses:
  `sim/phase4_multivariate_reml_recovery.jl` and
  `sim/phase4b_structured_covariance_recovery.jl` keep stochastic recovery
  outside CI, accept explicit seed lists, print per-case summaries, and keep
  broad calibration claims separate from smoke evidence.
- Existing `HSquared.jl` Phase 5 marker helpers:
  `single_marker_scan`, `mixed_model_marker_scan`,
  `loco_relationship_precisions`, `loco_mixed_model_marker_scan`,
  `marker_scan_table`, `marker_significance_summary`,
  `marker_qq_data`, and `marker_genomic_inflation` are direct Julia utilities
  with explicit no-R-syntax/no-calibration boundaries.
- Local sister process pattern from `drmTMB` and `gllvmTMB`: validation and
  diagnostic claims are split into implemented, partial, planned, and blocked
  rows before public wording changes.
- Project scout map `quantgen-scout/references/packages.md`: JWAS, sommer,
  BLUPF90, and related tools remain future comparator anchors; they are not
  evidence for this internal harness.

## Relevant Lesson

The harness should test a deliberately simple known-causal-marker scenario and
write exact seed/output evidence, but it should not become a genome-wide
threshold, p-value-calibration, QTL/eQTL, or comparator-parity claim. Stochastic
recovery belongs in `sim/` and `docs/dev-log/recovery-checkpoints/`, while CI
should keep deterministic tests over helper fields and status boundaries.

## HSquared.jl Action

Add `sim/phase5_marker_scan_recovery.jl` as an opt-in harness over existing
direct scan helpers. Record default-seed output in
`docs/dev-log/recovery-checkpoints/`, mention the evidence in validation/status
ledgers, and keep the status at `partial`.

## Claim Wording Risk

Allowed wording: "opt-in marker-scan recovery smoke outside CI" and "seeded
known-causal-marker recovery for direct Julia helper paths."

Blocked wording: "validated GWAS", "calibrated genome-wide threshold",
"QTL/eQTL validation", "fine mapping", "public R marker_scan support", or
"comparator parity."

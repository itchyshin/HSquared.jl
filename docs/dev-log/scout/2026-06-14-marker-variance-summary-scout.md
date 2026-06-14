# Marker-Variance Contribution Summary Scout

## Question

Can the Julia lane expose a direct marker-variance summary without implying a
validated genome-wide PVE, model R2, or comparator-backed QTL claim?

## Decision

Use a narrow deterministic convention:

```text
marker_variance = 2p(1-p) * effect^2
```

where `effect` and `p` come from the already-computed direct marker-scan result.
If the caller supplies a positive finite `total_variance`, report
`proportion_variance_explained = marker_variance / total_variance`.

## Boundary

This is a marker-level contribution summary, not a calibrated PVE workflow. It
does not estimate marker-scan variance components, choose a denominator,
calibrate p-values, correct test statistics, account for correlated markers,
choose genome-wide thresholds, draw plots, or create a bridge payload.

## R Twin Coordination

The R twin already reserves `marker_variance_explained()` as output vocabulary.
This Julia helper uses that name for direct scan summaries only. R-facing
activation still requires a separate bridge-contract slice and issue-level
coordination.

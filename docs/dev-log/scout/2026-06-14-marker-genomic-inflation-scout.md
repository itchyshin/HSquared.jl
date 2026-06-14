# Scout: Marker Genomic-Inflation Diagnostic

## Question

Should `HSquared.jl` add a small marker-scan inflation diagnostic before adding
any p-value calibration or genome-wide threshold machinery?

## Sources Checked

- Devlin and Roeder, 1999, "Genomic Control for Association Studies",
  Biometrics 55:997-1004. PubMed: https://pubmed.ncbi.nlm.nih.gov/11315092/
- Local Phase 5 scan utilities in `src/genomic.jl`:
  `single_marker_scan`, `mixed_model_marker_scan`,
  `loco_mixed_model_marker_scan`, `marker_manhattan_data`, and
  `marker_qq_data`.

## Relevant Lesson

The useful first diagnostic is the genomic-control-style inflation factor:

```text
lambda_GC = median(observed chi-square statistics) /
            median(chi-square distribution with 1 degree of freedom)
```

For the current direct Julia utilities, this belongs beside QQ plot data as an
honesty diagnostic over already-returned scan statistics. It should not adjust
the statistics, calibrate p-values, estimate effective marker counts, or choose
thresholds yet.

## hsquared / HSquared.jl Action

Add `marker_genomic_inflation(scan; expected_median)` as a direct Julia helper
that consumes scan-like outputs with a `chisq` field and returns
`lambda_gc`, `median_chisq`, `expected_median`, `n_markers`, and `target`.

## Claim Risk

Allowed: direct diagnostic summary.

Blocked: genomic-control correction, calibrated p-values, genome-wide
thresholds, effective-marker-count estimation, R `marker_scan()` activation,
bridge payload changes, and comparator parity.

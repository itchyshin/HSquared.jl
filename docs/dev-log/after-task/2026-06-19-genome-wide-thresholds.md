# After-task — #48 Genome-wide significance threshold machinery (2026-06-19)

Overnight autonomous runway run (Ada). BT3 validation slice — the gate before any
genome-wide-significance claim.

## Goal

Deliver #48: a calibrated genome-wide significance threshold that accounts for
marker correlation/LD, gating the R `gwas()` significance wording.

## Design decision

Kept the package RNG-free (project pattern + dependency stability): the committed,
CI-tested layer is the deterministic threshold machinery
(`genome_wide_threshold_from_null`, `genome_wide_pvalue`, `_scan_max_statistic`,
`_empirical_upper_quantile`); the RNG-heavy null generation (phenotype permutation)
is the opt-in `sim/phase5_threshold_calibration.jl` harness. The threshold is
correlation/LD-aware because it uses the distribution of the MAXIMUM over the
jointly-scanned markers (less conservative than Bonferroni under LD).

## What landed

- Exported `genome_wide_threshold_from_null` + `genome_wide_pvalue` (+ internal
  max-statistic / type-7 quantile helpers) in `src/genomic.jl`.
- Opt-in `sim/phase5_threshold_calibration.jl` (residual permutation conditional on
  `X`, Bonferroni contrast, empirical type-I smoke).
- Deterministic CI testset; capability-status + validation-debt + `validation_status`
  `V5-MARKER-THRESHOLD` rows (count 34 → 35).

## Review (adversarial workflow)

(Recorded after the workflow returns — Curie/Fisher, Gauss, Rose.)

## Local checks

- `Pkg.test()` → exit 0 (threshold testset).
- `docs/make.jl` → exit 0.

## Claim boundary

Deterministic machinery + add-one genome-wide p-value only — NOT a production
genome-wide-significance claim (the #48 gate holds the R `gwas()` significance
wording until a realistic-LD/design calibration lands). Permutation driver +
calibration evidence are opt-in / outside CI; depends on #45; no external
comparator. No capability moved to covered.

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

## Review (adversarial workflow) + fast-follow (PR #69 merged, then a follow-up)

Curie/Fisher + Gauss both **pass_with_nits** (no blocker; Curie confirmed the
max(T) permutation methodology and the Phipson–Smyth add-one p are statistically
sound). PR #69 was merged on the user's "merge them" directive; the should_fix
items were then addressed in a **fast-follow** (branch `julia/s48b-threshold-followup`):

- **Honesty (Curie+Gauss should_fix):** the `(1-alpha)` type-7 quantile threshold
  and the add-one `genome_wide_pvalue` are DIFFERENT estimators that agree only
  asymptotically — the quantile threshold is mildly anti-conservative at small
  `n_null` (add-one p `6/101 ≈ 0.059` at the `n=100` threshold). Replaced the
  "consistency" claim (docstring + capability-status + validation-debt +
  validation_status) with the honest asymptotic framing; the test now pins the
  ACTUAL add-one p at the threshold and adds an `n=1000` convergence case.
- **Finite guards (Gauss should_fix + nit):** `_scan_max_statistic` and
  `genome_wide_pvalue` now throw on non-finite inputs instead of silently
  propagating NaN; tests added.
- **Harness honesty (Curie should_fix + Gauss nit):** documented that residual
  permutation is a no-op under the committed intercept-only `X` (and only
  approximately exchangeable under a non-trivial design — Freedman–Lane/ter Braak
  are exact), and the type-I smoke now draws fresh markers per replicate.

## Local checks

- `Pkg.test()` → exit 0 (threshold testset).
- `docs/make.jl` → exit 0.

## Claim boundary

Deterministic machinery + add-one genome-wide p-value only — NOT a production
genome-wide-significance claim (the #48 gate holds the R `gwas()` significance
wording until a realistic-LD/design calibration lands). Permutation driver +
calibration evidence are opt-in / outside CI; depends on #45; no external
comparator. No capability moved to covered.

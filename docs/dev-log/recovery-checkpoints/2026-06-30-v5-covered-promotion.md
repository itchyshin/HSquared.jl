# Covered promotion — V5 genome-wide significance (SCOPED, validation-scale, opt-in)

Date: 2026-06-30. Maintainer-directed (`/goal` "finish all of v0.5"). Promotes `V5-MARKER-THRESHOLD`
**`partial → covered`** for the genome-wide-significance MACHINERY, SCOPED to the validated path, via the
doc-33 substitutable gate. This is NOT a public-default change: public-covered FITTING stays **1** (the v0.1
univariate Gaussian animal model); genome-wide significance is an opt-in, experimental-engine capability now
covered at validation scale — the same posture as V2-GREML and V4-MV-REML.

## The covered claim (exactly what "covered" means here)

The engine correctly implements **genome-wide significance for a fixed-effect single-marker scan via the EXACT
per-dataset add-one permutation rule** — `genome_wide_marker_scan` (Julia) / `gwas(..., genome_wide = TRUE)`
(R). For each analysis the permutation null is rebuilt from the analysed phenotype (`y` permuted conditional on
`X`, re-scanned `n_permutations` times) and the genome-wide p is the add-one
`(1 + #{null max ≥ observed})/(n_permutations + 1)` (significant when `genome_wide_p ≤ α`). "Covered" means this
rule **controls family-wise type-I at α** on the validated designs — NOT that it is powerful, coverage-accurate,
or valid outside the fenced scope.

## The substitutable gate (doc-33) — what was pre-registered and passed

1. **Pre-registered type-I gates, PASSED** (the recovery-gate analog for a type-I-control estimand):
   - Validation scale: the add-one gate (#203, single design) + the design-grid sweep (#204, 3 designs) — PASS,
     after the `(1-α)` quantile rule was banked NEGATIVE (#202, anti-conservative).
   - **Production scale: the per-dataset REBUILD gate (#207)** — PASS at (500,2000)+(1000,2000), mean type-I
     **0.0542 / 0.0504** at α=0.05 (the exact rule, right at nominal). The REUSE-shortcut production gate FAILED
     and was banked NEGATIVE + diagnosed (the fixed-null-reuse simulation shortcut is mildly anti-conservative;
     the per-dataset rule that real `gwas()` uses is what is covered).
2. **External comparator, EXECUTED** (#205): PLINK 1.9 `--assoc --mperm 2000` (an INDEPENDENT implementation —
   estimated-variance OLS + own RNG) reproduces `genome_wide_pvalue` across 5 datasets β=0→0.8: SAME top marker
   ×5, genome-wide p agreeing to MC error, per-marker χ²/T² cor 0.998-1.000.
3. **R activation, LIVE-VERIFIED** (hsquared #113): `gwas(..., genome_wide = TRUE)` calls the engine rule, with
   the calibration-metadata contract (`permutation_addone`, `empirical_type1 = NA` + a required
   `validation_reference`); element-wise parity vs a direct engine call; `R CMD check` 0/0/0.
4. **Real Rose audits** — every slice PROMOTE (the engine entry point, the production gate, the R activation).

## SCOPE OF VALIDITY (where the covered claim is asserted to hold)

- **Fixed-effect / intercept-only** single-marker scan (the validated calibration). The exact per-dataset
  add-one rule, NOT the `(1-α)` quantile rule and NOT the fixed-null-reuse shortcut.
- The tested LD architecture (`_simulate_markers`: shared latent factors + allele-freq gradient) and the
  designs n ∈ {300,500,1000,2000}, m ∈ {100…10000} at which type-I control was gated.
- **Type-I CONTROL only.**

## FENCED OUT (explicitly NOT covered)

- The **relatedness-corrected mixed-model / LOCO** genome-wide null (a different, unvalidated calibration;
  `gwas(genome_wide = TRUE)` rejects `method = "mixed"`/`"loco"`).
- **Power / coverage**, **broader LD architectures**, **covariate-adjusted** GWAS (Freedman–Lane / ter Braak).
- The documented **reuse-shortcut anti-conservatism** (a simulation caveat, not the covered rule).
- This is NOT the public-default fitting path; NOT a production GWAS pipeline (no map-annotated formula
  `marker_scan()`/`qtl_scan()`, no fine-mapping).

## Standing debt (covered does NOT retire it)

A 2nd external comparator (GCTA/statgenGWAS), mixed-model genome-wide calibration, broader-LD/covariate-adjusted
designs, coverage characterization, and the map-annotated formula-level scan API remain owed.

## Surfaces flipped (atomic, both twins)

- Julia: `validation_status()` V5-MARKER-THRESHOLD `partial → covered` (covered 7→8; total 48 UNCHANGED; the
  status-partition + debt-tracker invariants hold); `capability-status.md`; `validation-debt-register.md`;
  test pin (`test/runtests.jl`).
- R (hsquared): `capability-status.md` + `validation-debt-register.md` gwas rows `partial → covered` (scoped),
  NEWS.
- public-covered FITTING = **1** UNCHANGED; the public default is untouched.

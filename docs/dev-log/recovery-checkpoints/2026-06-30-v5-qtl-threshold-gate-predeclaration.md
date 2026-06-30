# Pre-declaration — V5 QTL genome-wide threshold CALIBRATION gate (the #48 gate)

Status: **PRE-DECLARED, to be committed BEFORE the run** (no post-hoc relaxation; 2026-06-14 rule).
This is the substitutable-gate candidate for a "calibrated genome-wide threshold" covered claim — the
**#48 gate** that holds the R `gwas()` significance wording. Mirrors the V2/V3 recovery-gate
predeclarations, but the estimand is **type-I error control**, not parameter recovery.

## Machinery + DGP

`genome_wide_threshold_from_null` (the (1−α) quantile of the per-scan-MAX chi-square from an LD-aware
**permutation null**) over `single_marker_scan`. Harness: `sim/phase5_qtl_threshold_gate.jl` (reuses
`run_threshold_calibration` from `sim/phase5_threshold_calibration.jl` verbatim, adds a fixed verdict).

- **NULL DGP** (no marker signal): n=300 records, m=200 **correlated** markers (LD via shared latent
  factors + an allele-frequency gradient — `_simulate_markers`), intercept-only `X`, σ²e=1.
- Per seed: a residual-permutation null (**nperm=2000**) builds the (1−α) genome-wide threshold; then
  **type1_reps=1000** INDEPENDENT no-signal scans on the SAME fixed panel give the empirical type-I (the
  fraction whose per-scan max exceeds the threshold).
- **α = 0.05.**

## Seeds (UNSEEN at declaration)

20 cold-start seeds **20260900 .. 20260919** — disjoint from the existing mini-smoke seeds (20260620…)
and the V2/V3 gate seeds. No calibration result is observed before this gate is fixed.

## PASS criteria (ALL required; fixed here, not adjustable after seeing results)

1. **Completion:** 20/20 seed runs complete.
2. **Calibration:** `|mean(empirical_type1) − α| ≤ 2·MCSE`, where the mean is over the 20 seeds and
   `MCSE = sd(per-seed empirical_type1)/√20`. **TWO-SIDED** (type-I ≈ α — a CALIBRATED threshold, neither
   anti-conservative nor over-conservative).

## Interpretation (declared in advance)

- **PASS** = NO DETECTABLE mis-calibration of the permutation threshold at α — a low-power non-rejection,
  read as "consistent with a calibrated threshold," NEVER "exactly calibrated."
- **FAIL** = a banked NEGATIVE. The most likely failure mode is **anti-conservatism** (mean type-I > α):
  the (1−α) EMPIRICAL quantile from a finite nperm is mildly biased low, so the threshold is a touch too
  permissive. That is an honest, expected result — it would mean the permutation threshold needs more
  permutations (or a conservative correction), the **V5 covered claim does NOT proceed**, and the R
  `gwas()` significance wording stays held. NO relaxation of α, nperm, or the tolerance after the fact.
- Either way: `validation_status()` count, public-covered fitting = 1, and the marker-scan machinery's
  `experimental` status are unaffected by the gate OUTCOME; only a PASS + Rose + (if it gates an R wording
  change) maintainer G10 would move the threshold row toward covered.

## Honest scope (declared up front)

- This calibrates the **intercept-only null** (residual permutation = permuting `y`); covariate-adjusted
  GWAS needs the exact Freedman–Lane / ter Braak nulls (not in scope — an upgrade path).
- One design point (n=300, m=200, one LD scheme). A covered claim would still owe broader n/m/LD-architecture
  designs and an external comparator (PLINK `max(T)` / GenABEL). This gate is the FIRST calibrated-type-I
  evidence, not the whole covered close.

## RESULT (run 2026-06-30, AFTER the predeclaration commit `55acc6ef`) — **GATE: FAIL (anti-conservative)**

`sim/phase5_qtl_threshold_gate.jl`, 20 seeds 20260900..20260919, julia 1.10.0, single-threaded:

| quantity | value |
|---|---|
| mean empirical type-I | **0.0689** |
| target α | 0.050 |
| bias | **+0.0189** |
| MCSE | 0.0078 |
| \|bias\|/MCSE | **2.42** |
| per-seed type-I range | [0.0220, 0.1310] |
| perm threshold < Bonferroni | 12/20 seeds |

20/20 runs completed, but `|mean type-I − α| = 0.0189 > 2·MCSE = 0.0156` → **GATE FAIL** in the
**anti-conservative** direction: the permutation threshold is too permissive, family-wise type-I ≈ 0.069
(~38% above the nominal 0.05).

**Diagnosis (the expected failure mode, declared in advance).** The (1−α) type-7 EMPIRICAL quantile of a
finite `nperm = 2000` permutation null is biased low, so the genome-wide threshold is a touch too small and
over-rejects. This **confirms and quantifies** the anti-conservatism the capability-status row already
flagged ("the type-7 quantile threshold is mildly anti-conservative at small `n_null`").

**Consequence — banked NEGATIVE, no relaxation.** The V5 "calibrated genome-wide threshold" covered claim
does **NOT** proceed on the quantile threshold; the R `gwas()` significance wording **STAYS HELD**. The
calibrated path is the package's CONSERVATIVE add-one permutation p-value rule (`genome_wide_pvalue`, exact
by the `(1 + #{null ≥ obs})/(nperm + 1)` construction — a valid exact permutation test controlling type-I
at ≤ α), and/or a much larger `nperm` to debias the quantile. A future V5 slice should pre-declare a
calibration gate on the add-one rule **and** add an external comparator (PLINK `max(T)` / GenABEL). Nothing
promoted; `validation_status()` count, public-covered fitting = 1, and the threshold row's `experimental`
status are unchanged by this FAIL.

# 2026-06-30 · V5 QTL genome-wide threshold calibration gate — FAIL (banked negative)

A pre-declared calibration gate for the permutation genome-wide threshold. **GATE FAILED
(anti-conservative); banked as a NEGATIVE. Nothing promoted — V5-MARKER-THRESHOLD stays
`partial`/`experimental`, `gwas()` wording stays held.**

## What ran

- Predeclaration `docs/dev-log/recovery-checkpoints/2026-06-30-v5-qtl-threshold-gate-predeclaration.md`
  committed `55acc6ef` BEFORE the run (no post-hoc relaxation). Harness
  `sim/phase5_qtl_threshold_gate.jl` (reuses `run_threshold_calibration` from the existing
  `sim/phase5_threshold_calibration.jl`).
- NULL DGP: n=300, m=200 correlated markers (LD), intercept-only X. Per seed: nperm=2000 permutation
  threshold + type1_reps=1000 independent null scans → empirical type-I. α=0.05, 20 seeds 20260900..919.

## RESULT — GATE FAIL

`JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia sim/phase5_qtl_threshold_gate.jl`:

```
empirical type-I: mean=0.0689  target=0.050  bias=+0.0189  MCSE=0.0078  |bias|/MCSE=2.42
per-seed range=[0.0220, 0.1310];  perm<Bonferroni in 12/20 seeds
GATE: FAIL  (|mean type-I − α| ≤ 2·MCSE = 0.0156; anti-conservative direction)
```

`|mean type-I − α| = 0.0189 > 2·MCSE = 0.0156` → FAIL. The `(1−α)` empirical-quantile permutation
threshold is **anti-conservative** at finite nperm (type-I ≈ 0.069, ~38% above nominal). This confirms +
quantifies the anti-conservatism the row already flagged. Calibrated path: the conservative add-one
`genome_wide_pvalue` rule (exact by construction) and/or much larger nperm.

## Surfaces updated (evidence APPENDED; status UNCHANGED)

- `src/validation_status.jl` (V5-MARKER-THRESHOLD evidence), `docs/design/validation-debt-register.md`,
  `docs/design/capability-status.md` — each cites the gate FAIL; the row stays `partial`/`experimental`.

## Checks

- `Pkg.test()` → **"Testing HSquared tests passed"** (exit 0); `validation_status()` = **48 rows /
  covered 7 / partial 37 — UNCHANGED** (evidence-string APPEND, no status flip); count-guard green.
- Real Rose audit → banked-negative honesty (no overclaim; `gwas()` held).

## Honesty

`validation_status()` = 48 rows UNCHANGED; covered = 7 UNCHANGED; public-covered FITTING = 1. NOTHING
promoted — a FAIL is the conservative, honest outcome (it prevents shipping an anti-conservative threshold).
v0.5 covered still owes: a calibrated (add-one / higher-nperm) threshold gate + an external comparator
(PLINK max(T)) + the R `marker_scan()`/`gwas()` activation (R-lane).

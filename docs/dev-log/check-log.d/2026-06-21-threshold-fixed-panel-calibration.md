# 2026-06-21 Fixed-panel threshold calibration smoke (#48)

- **Goal:** harden the opt-in genome-wide-threshold calibration harness and
  record a narrow fixed-marker-panel type-I smoke without promoting #48.
- **Lenses:** Curie (simulation smoke), Fisher (permutation/type-I target),
  Rose (claim boundary), Grace (checks).
- **Spawned subagents:** none.

## Commands

- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_threshold_calibration.jl --seeds=20260621,20260622,20260623 --n=240 --markers=120 --n-permutations=300 --type1-reps=200 --type1-marker-mode=fixed --out=docs/dev-log/recovery-checkpoints/2026-06-21-threshold-fixed-panel-calibration.tsv`
  — passed. Empirical type-I by seed: 0.015, 0.065, 0.050 (mean 0.043; target
  0.05). Threshold-vs-Bonferroni direction was mixed (1/3 below), so no
  "less conservative than Bonferroni" claim.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed. The Phase 5
  genome-wide threshold machinery testset is now 57/57 after adding harness
  contract tests. First run exposed an exact-float assertion (`0.07500000000000001
  == 0.075`); fixed with approximate equality and reran.
- `julia --project=docs docs/make.jl` — passed, with existing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, and npm audit output.

## Boundary

Validation-scale fixed-panel smoke only. This is not a realistic-LD production
calibration, not an external PLINK/GenABEL comparator, not R `gwas()`
significance activation, and not a covered-status promotion.

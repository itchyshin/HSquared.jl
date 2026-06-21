# After-Task Report: Fixed-panel threshold calibration smoke (#48)

## Live Phase Snapshot

As of this report, Julia `main` before the slice was `4526481` after the
AI-matrix claim cleanup (#133), with post-merge CI, Documenter, and Pages green.
This branch is `codex/threshold-calibration-fixed-panel`. Covered public status
is unchanged: v0.1 univariate Gaussian animal-model support only; Phase 5 marker
threshold work remains `partial` / `experimental`.

## 1. Goal

Strengthen the #48 opt-in genome-wide-threshold calibration harness so it can
record fixed-marker-panel type-I smoke evidence in a reproducible, machine-
readable way, while keeping the public significance gate held.

## 2. Implemented

- Refactored `sim/phase5_threshold_calibration.jl` into reusable helpers:
  `run_threshold_calibration`, multi-seed parsing, fixed/fresh type-I marker
  panel selection, result summarization, and TSV writing.
- Changed the harness default type-I smoke to a fixed marker panel, matching the
  usual "this observed marker set" genome-wide calibration target. The previous
  fresh-panel behavior remains available through `--type1-marker-mode=fresh`.
- Added deterministic CI tests for the harness contract: seed parsing, marker
  mode validation, summary arithmetic, and TSV output shape.
- Recorded a three-seed fixed-panel mini-smoke at
  `docs/dev-log/recovery-checkpoints/2026-06-21-threshold-fixed-panel-calibration.tsv`.
- Updated `validation_status()`, capability status, validation debt, genomics
  docs, and the coordination board with the new evidence and the still-held
  boundary.

## 3a. Decisions and Rejected Alternatives

- Used fixed-panel type-I as the default because threshold calibration is
  conditional on the observed marker set; fresh marker panels are useful as a
  sensitivity smoke, but answer a different question.
- Did not claim the permutation threshold should always be below Bonferroni. In
  the mini-smoke only 1/3 finite runs was below Bonferroni, so the wording now
  says correlation-aware rather than always less conservative.
- Did not wire thresholds into `marker_scan_table()` or R `gwas()` output. The
  current evidence is too small and too synthetic for public significance
  wording.

## 4. Files Touched

- `sim/phase5_threshold_calibration.jl`
- `test/runtests.jl`
- `src/genomic.jl`
- `src/validation_status.jl`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-threshold-fixed-panel-calibration.md`
- `docs/dev-log/recovery-checkpoints/2026-06-21-threshold-fixed-panel-calibration.tsv`
- `docs/dev-log/after-task/2026-06-21-threshold-fixed-panel-calibration.md`

## 5. Checks Run

- `julia --project=. -e 'include("sim/phase5_threshold_calibration.jl"); r = run_threshold_calibration(1; n=20, m=5, nperm=5, type1_reps=5); @show r; @show _summarize_threshold_calibration_results([r])'`
  — passed; confirmed the refactored harness loads without executing on include.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. sim/phase5_threshold_calibration.jl --seeds=20260621,20260622,20260623 --n=240 --markers=120 --n-permutations=300 --type1-reps=200 --type1-marker-mode=fixed --out=docs/dev-log/recovery-checkpoints/2026-06-21-threshold-fixed-panel-calibration.tsv`
  — passed; empirical type-I 0.015/0.065/0.050, mean 0.043 at alpha 0.05.
- `julia --project=. -e 'using Pkg; Pkg.test()'`
  — first run failed on exact floating equality in the new test; after fixing to
  approximate equality, rerun passed. The #48 testset reports 57/57.
- `julia --project=docs docs/make.jl`
  — passed with existing local warnings: 20 omitted internal docstrings, skipped
  deployment detection, default Vitepress assets, no logo/favicon, and npm audit
  output.

## 6. Tests of the Tests

- The first full `Pkg.test()` run failed on the new harness summary assertion,
  proving the new test block is active in CI. The failure was a brittle exact
  comparison of `0.07500000000000001` to `0.075`; approximate equality fixed the
  test without weakening the contract.
- The validation-status tests now assert that the #48 row names the fixed-panel
  type-I smoke, TSV evidence, observed empirical type-I values, mixed
  Bonferroni direction, and still-missing realistic-LD/design calibration.

## 7a. Issue Ledger

- Advances #48 by adding reproducible fixed-panel calibration-smoke evidence and
  a reusable multi-seed TSV harness.
- Does not close #48. Remaining issue bullets still stand: realistic-LD/design
  type-I control, possible effective-number/FDR workflow, output wiring, and an
  external comparator.

## 8. Consistency Audit

- Searched neighbouring threshold wording and removed the over-simple "fresh
  markers per type-I replicate" status claim.
- Reworded the Bonferroni contrast from "expected under LD" to a finite-run
  observation because the recorded evidence is mixed.
- Confirmed the R lane is untouched; this is Julia engine/harness evidence only.

## 9. What Did Not Go Smoothly

- The recorded smoke was not uniformly below Bonferroni, which is a useful
  reminder that finite empirical thresholds plus this synthetic marker generator
  should not be sold as a tidy effective-test-count story.
- The first test run caught a fragile exact-float assertion in the new summary
  test.

## 10. Known Residuals

- No realistic-LD design calibration.
- No PLINK max(T), GenABEL, qvalue, or equivalent external comparator.
- No FDR/effective-number workflow.
- No `marker_scan_table()` threshold column and no R `gwas()` significance
  wording activation.
- The fixed-panel smoke is small: 3 seeds, 300 permutations, 200 type-I
  replicates per seed.

## 11. Team Learning

For #48, prefer fixed-marker-panel type-I smoke as the default calibration
question, keep fresh-panel runs as sensitivity, and treat Bonferroni comparison
as an observed finite-run diagnostic rather than a guaranteed direction.

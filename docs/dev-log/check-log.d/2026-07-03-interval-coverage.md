# Check-log — interval coverage calibration (last owed doc-25 leg) (2026-07-03)

**Slice:** empirical coverage of the shipped h²/σ²a intervals (`:delta` / `:profile`). Branch
`feat/2026-07-03-interval-coverage`. Closes doc-25.

## Key result (DRAC fir job 46853279, 500 reps/cell, nominal 95%)

- **The shipped intervals OVER-COVER at small n** (`:delta` = 100% at n=36, h²≥0.4) — conservative,
  never under-cover (`heritability_interval` `:delta`/`:profile` + `variance_component_interval`
  `:profile`; floor ~0.926 ≈ 2·MCSE). A harness-internal σ²a Wald probe (NOT shipped) does dip to
  ~0.90, which is why `variance_component_interval` ships `:profile`-only.
- **Converge to nominal as n grows** (n=36 → 120 → 240); `:profile` faster.
- **`:profile` > `:delta`** for calibration (medium n=240: `:profile` 0.938–0.959 ≈ nominal, `:delta`
  0.934–0.976).

## Evidence

- Harness `sim/phase1_small_sample_interval_calibration.jl` (`--bootstrap=false`, delta+profile arms).
- Artifact (tracked): `sim/drac/results/cov_delta_profile_46853279.tsv`. Checkpoint
  `2026-07-03-interval-coverage.md`.
- `V1-HERIT-CI` row updated. `Pkg.test()` GREEN (count 55 UNCHANGED).

## Honesty

A characterization, not a coverage guarantee. No default/API change; no covered flip;
`public_covered_count` UNCHANGED (5). The bootstrap arm + ratio/matrix-free/MV/non-Gaussian coverage
remain unmeasured. doc-25 fully closed.

# 2026-07-09 — bootstrap-arm interval coverage (DRAC job 47870067)

Closes the bootstrap leg the delta/profile run (job 46853279) turned off
(`--bootstrap=false`), and maps every method the driver emits across the grid.

## Run

- Driver: `sim/phase1_small_sample_interval_calibration.jl` @ `main` (50131e69).
- DRAC **fir**, 3-task array `47870067_[0-2]` (one design per task), `def-snakagaw_cpu`,
  4 CPU / 12 G, `julia/1.10.10`. Elapsed 19 / 30 / 42 min; MaxRSS ~730 M. All `exit=0`.
- Grid: designs `tiny(4:8:24, n=36)` / `small(8:16:96, n=120)` / `medium(16:32:192, n=240)`
  × `h2 ∈ {0.2,0.4,0.6,0.8}` × levels `{0.90, 0.95}` × **reps=500** × **nboot=200**.
- Evidence: `sim/drac/results/cov_boot_full_47870067_merged.tsv` (264 rows).
- Re-run: `sbatch sim/drac/cov_boot_full.sbatch`.

## Coverage at nominal 0.95, by method (mean over designs × h2)

| target | delta_z | t(residual df) | t(family df, g−1) | profile χ² | bootstrap | Satterthwaite |
| --- | --- | --- | --- | --- | --- | --- |
| **h²** | 0.980 | 0.981 | 0.984 | 0.965 | 0.962 | — |
| **σ²a** | 0.926 | 0.928 | 0.938 | **0.962** | 0.948 | **0.901** |

h² `delta_z` by design: n=36 **0.997** → n=120 0.978 → n=240 **0.964**.
σ²a `delta_z` by design: n=36 0.939 → n=120 0.922 → n=240 0.917.

## Findings (feed the interval-honesty label + the coverage-driver design)

1. **h² over-covers (conservative) at small n and converges to nominal with n** — the raw
   ±1.96·SE and both t-widenings sit at 0.96–0.98. The "conservative" label is earned **for h²**.
2. **The raw variance-component SE is ≈ nominal**, if anything slightly anti-conservative
   (`delta_z` σ²a ≈ 0.92, not improving with n). **It is NOT conservative** — so the earlier
   blanket "conservative" VC label was an over-claim, corrected in both `01-v0.1-contract.md`
   copies and the R surfaces (hsquared) this session.
3. **Per-target, not per-axis** (the brain's small-sample-VC-interval map, confirmed): the best
   method differs by target — **profile** is best for σ²a (0.962); the **adaptive-Satterthwaite**
   probe *under*-covers σ²a (0.901), i.e. the leading candidate width is the *worst* here.
4. **Bootstrap is well-calibrated** (h² 0.962, σ²a 0.948) — the newly-run arm is the most nearly
   nominal single method for both targets.

## Claim level (Fisher's three-tier)

500 reps (MCSE ≈ ±1% at 1 SE) licenses a **directional** claim only, target-specific as above —
**not** a point-coverage number. A point claim needs the ~2000-rep grid (deferred).

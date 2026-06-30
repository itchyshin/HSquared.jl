# W1 Campaign 1 — interval coverage characterization: results + interpretation

Run: fir SLURM array `46236262`, 20 tasks × 50 reps = 1000 reps/cell (independent master seeds),
tiny (q=36) + small (q=120), h² ∈ {0.1,0.3,0.5,0.7}, levels {0.90,0.95}, n_boot=99; branch
`w1/2026-06-29-evidence-week-setup` @ `132ecfcb`, julia 1.10.10. Full per-cell coverage table:
`2026-06-29-w1-c1-interval-coverage.tsv` (176 cells). **CHARACTERIZATION ONLY — t/Satterthwaite df
stays BLOCKED (`V1-HERIT-TCAL` planned); the t-/SW-probe methods are descriptive, never a covered claim.
Coverage is on `interval_success`, NOT reps.** 176,001 replicate rows total.

## Interpretability first (the boundary problem)

The `:delta` h² interval throws at the 0/1 boundary, so reps drop from the coverage denominator —
worst exactly where it matters. **Tiny-design and small-h²=0.1 cells are NON-INTERPRETABLE**
(`interval_success` 57–86% of reps): coverage there is on a *selected, non-boundary subsample* and is
not a clean estimate of the marginal procedure. The **interpretable** regime is **small design, h² ≥ 0.3**
(`interval_success` 93–100%).

## Headline coverage (level 0.95, interpretable cells; nominal = 0.95)

| method | small h²=0.3 | small h²=0.5 | small h²=0.7 | reading |
|---|---|---|---|---|
| h² delta-z | 0.960 | 1.000 (over) | 0.971 (over) | conservative / over-covers at high h² |
| h² profile-LRT | 0.924 (under) | 0.942 (ok) | 0.971 (over) | best-calibrated of the three |
| h² bootstrap | 0.881 (under) | 0.855 (under) | 0.942 | under-covers at moderate h² |
| **σ²a delta-z** | **0.855 (under)** | **0.842 (under)** | **0.915 (under)** | **normal-Wald too narrow — the core finding** |
| σ²a profile-LRT | 0.902 (under) | 0.949 (ok) | 0.971 (over) | best-calibrated |
| σ²a bootstrap | 0.907 (under) | 0.865 (under) | 0.931 (under) | under-covers |

## Findings (honest)

1. **The asymptotic σ²a delta/Wald interval under-covers at small sample** (≈0.84–0.92 vs 0.95) — the
   normal-z interval for the additive variance is too narrow. This is exactly the small-sample
   mis-calibration that `V1-HERIT-TCAL` (planned) names; **this run confirms it, it does not fix it.**
2. **Profile-LRT is the best-calibrated existing method** for both h² and σ²a (closest to nominal in
   the interpretable regime), though it too under-covers slightly at h²=0.3.
3. **The parametric bootstrap does not rescue coverage** — it under-covers at small/moderate h²
   (≈0.85–0.93). So the opt-in bootstrap is finite-sample-aware but not finite-sample-*calibrated*.
4. **The tiny / low-h² regime is boundary-dominated** and largely non-interpretable — any future
   calibration method must handle the 0/1 boundary, not just the df.
5. The t-residual/family-df and σ²a Satterthwaite-χ² **probes remain characterization-only** (the SW
   probe was already known unstable in low-h² small designs); none is a calibrated method.

## Conclusion (no promotion)

This characterizes the existing interval methods at small sample: **delta/Wald under-covers σ²a;
profile-LRT is the safest existing default; bootstrap under-covers; the boundary makes tiny/low-h²
un-assessable.** It strengthens the case for the **planned** `V1-HERIT-TCAL` small-sample calibration
(and suggests profile-LRT as the better existing default), but **implements no calibration** and changes
no default. `V1-HERIT-TCAL` stays `planned`; `validation_status()` unchanged (48 rows); public-covered = 1.
Deferred to a follow-up: the medium (q=240) design and larger n_boot. Any status-row update is for
Rose + maintainer.

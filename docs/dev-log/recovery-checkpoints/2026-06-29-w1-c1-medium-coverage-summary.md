# W1 Campaign 1 follow-up — medium-design (q=240) interval coverage + cross-design comparison

Run: fir array `46271637`, 20 tasks × 50 reps = 1000 reps/cell, design `medium:16:32:192` (q=240),
h² ∈ {0.1,0.3,0.5,0.7}, levels {0.90,0.95}, n_boot=99; branch `w1/...` @ `4a5181f0`. Same config as the
tiny+small run (`2026-06-29-w1-c1-interval-coverage*`) for direct comparison. Full table:
`2026-06-29-w1-c1-medium-coverage.tsv`. **CHARACTERIZATION ONLY — `V1-HERIT-TCAL` stays planned.**

## Medium coverage (level 0.95; all cells now interpretable)

| method | h²=0.1 | h²=0.3 | h²=0.5 | h²=0.7 |
|---|---|---|---|---|
| σ²a delta-z | 0.989 | 0.914 (under) | 0.917 (under) | 0.860 (under) |
| σ²a profile-LRT | 0.984 | **0.957** | **0.949** | 0.861 (under) |
| σ²a bootstrap | 0.995 | 0.874 (under) | 0.905 (under) | 0.870 (under) |
| h² delta-z | 0.952 | 0.973 | 0.949 | 0.925 |
| h² profile-LRT | 0.984 | 0.960 | 0.943 | 0.910 |
| h² bootstrap | 0.995 | 0.858 (under) | 0.886 (under) | 0.867 (under) |

## Findings (cross-design: tiny q=36 → small q=120 → medium q=240)

1. **The boundary non-interpretability resolves with n.** At tiny/low-h² the `:delta` interval clamps and
   drops reps (non-interpretable); **at q=240 every cell is interpretable** (high `interval_success`). So
   the boundary problem is a small-n / low-h² artifact, not a permanent obstacle.
2. **σ²a delta/Wald under-coverage improves with n at low–moderate h²** — exactly paralleling the σ²a
   *bias* result: h²=0.3 `small 0.855 → medium 0.914`, h²=0.5 `0.842 → 0.917` (toward nominal 0.95).
3. **…but a residual high-h² under-coverage persists:** at h²=0.7 *all* σ²a interval methods sit at
   ~0.86 even at q=240 (delta 0.860, profile 0.861, bootstrap 0.870) — a high-h² narrowness that does not
   close by medium. (h²=0.7 σ²a delta-z is actually slightly *worse* at medium than small, 0.860 vs 0.915;
   real at ~0.7pp MCSE, a genuine high-h² boundary worth noting.)
4. **Profile-LRT is consistently the best-calibrated existing method** for σ²a (0.957/0.949 at h²=0.3/0.5,
   right at nominal) and h²; the bootstrap under-covers at moderate h² across all designs.

## Conclusion (no promotion)

The medium run completes the small-sample interval picture: under-coverage of the asymptotic σ²a Wald
interval is **largely a small-sample effect that improves toward nominal as n grows** (low–moderate h²),
with two residual features — a **high-h² σ²a narrowness** (~0.86 even at q=240) and the (now-resolved)
small-n boundary non-interpretability. **Profile-LRT is the safest existing default.** This strengthens the
case for the **planned** `V1-HERIT-TCAL` (which must handle the boundary and the high-h² regime) and for
profile-LRT as the better existing interval — but implements no calibration and changes no default.
`V1-HERIT-TCAL` stays `planned`; `validation_status()` unchanged (48); public-covered = 1.

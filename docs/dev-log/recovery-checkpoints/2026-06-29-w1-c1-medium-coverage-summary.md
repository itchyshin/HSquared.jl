# W1 Campaign 1 follow-up — medium-design (q=240) interval coverage + cross-design comparison

Run: fir array `46271637`, 20 tasks × 50 reps = 1000 reps/cell, design `medium:16:32:192` (q=240),
h² ∈ {0.1,0.3,0.5,0.7}, levels {0.90,0.95}, n_boot=99; branch `w1/...`. Same config as the tiny+small run
for direct comparison. Full table: `2026-06-29-w1-c1-medium-coverage.tsv`. **CHARACTERIZATION ONLY —
`V1-HERIT-TCAL` stays planned.**

> **Correction (2026-06-29, Rose-caught):** an earlier version of this table reported level-LUMPED numbers
> (a bug in the first ingest grouped coverage by `(method, h²)` without separating the 90%/95% levels). The
> numbers below are re-derived directly from the committed level-separated TSV. The tiny+small summary +
> both TSVs were unaffected; only this medium summary table was wrong.

## Medium coverage (level 0.95, from the committed TSV)

| method | h²=0.1 | h²=0.3 | h²=0.5 | h²=0.7 |
|---|---|---|---|---|
| σ²a delta-z | 1.000 (over†) | **0.944 (ok)** | 0.925 (under) | 0.870 (under) |
| σ²a profile-LRT | 1.000 (over†) | 0.984 (over) | 0.965 (over) | 0.882 (under) |
| σ²a bootstrap | 1.000 (over†) | 0.884 (under) | 0.919 (under) | 0.870 (under) |
| h² delta-z | 0.989 (over) | 0.991 (over) | 0.965 (over) | 0.980 (over) |
| h² profile-LRT | 1.000 (over†) | 0.964 (over) | 0.953 (ok) | 0.939 (ok) |
| h² bootstrap | 1.000 (over†) | 0.888 (under) | 0.918 (under) | 0.888 (under) |

† h²=0.1 cells are near the σ²a→0 boundary even at q=240 (coverage 1.000) — treat as marginal.

## Findings (cross-design: tiny q=36 → small q=120 → medium q=240)

1. **σ²a delta/Wald under-coverage improves toward nominal with n** (the small-sample effect): h²=0.3
   `small 0.855 → medium 0.944`, h²=0.5 `0.842 → 0.925`. By the medium design the delta σ²a interval is
   near-nominal at low–moderate h².
2. **…but a residual high-h² under-coverage persists:** h²=0.7 σ²a sits at ~0.87 for *all three* methods
   even at q=240 (delta 0.870, profile 0.882, bootstrap 0.870) — a high-h² narrowness that does not close.
3. **The failure modes differ by method, and that is the key point:** delta/Wald **under-covers** σ²a at
   small n (anti-conservative) but **over-covers** h² (conservative); **profile-LRT is the more conservative**
   method — at medium it *over*-covers σ²a (0.984/0.965 at h²=0.3/0.5) while staying near-nominal for h²
   (0.953/0.939). Profile's worst case is over-coverage; delta's worst case (small-n σ²a) is under-coverage.
4. **The boundary non-interpretability resolves with n** — tiny/low-h² cells are boundary-dominated; by
   q=240 the designs are interpretable (h²=0.1 still marginal).
5. **Bootstrap under-covers** at moderate h² across all designs — finite-sample-aware but not calibrated.

## Conclusion (no promotion)

The medium run completes the small-sample interval picture: the σ²a delta/Wald under-coverage is **largely
a small-sample effect that improves toward nominal with n** at low–moderate h² (residual high-h² narrowness
~0.87 across methods). The methods differ in **failure mode**: delta is anti-conservative for σ²a at small
n; profile-LRT is conservative (over-covers σ²a at medium, near-nominal h²). This strengthens the case for
the **planned** `V1-HERIT-TCAL` (which must handle the boundary + high-h² regime) and frames the existing-
default question (delta vs profile) as **anti-conservative vs conservative**, not "which is closer to
nominal" (see `2026-06-29-w2-profile-lrt-default-proposal.md`). No calibration implemented; no default
change; `V1-HERIT-TCAL` stays `planned`; `validation_status()` unchanged (48); public-covered = 1.

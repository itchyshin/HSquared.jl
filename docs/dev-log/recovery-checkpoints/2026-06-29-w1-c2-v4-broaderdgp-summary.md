# W1 Campaign 2 — broader-DGP V4-MV-REML recovery: results + interpretation

Run: fir SLURM array `46235637`, 8 pre-declared cells × 50 cold-start seeds, branch
`w1/2026-06-29-evidence-week-setup` @ `73bde652`, julia 1.10.10. Gate = aggregate
`|bias| ≤ 2·MCSE` on all six G0/R0 entries (doc-33 path-b). Predeclaration:
`2026-06-29-w1-drac-ademp-predeclaration.md`. Raw per-cell aggregates:
`2026-06-29-w1-c2-v4-broaderdgp-results.txt`. **TRIAGE evidence — no promotion without Rose + G10.**

## Per-cell gate

| cell | scope | r_g | records | design | gate | note |
|---|---|---|---|---|---|---|
| base_inside | **inside** | 0.42 | 3 | 8/16/56 | **PASS** | all 6 within 2·MCSE — covered scope reproduces |
| h2_asym | new | 0.30 | 3 | 8/16/56 | PASS | asymmetric per-trait h² recovers |
| records_1 | new | 0.42 | 1 | 8/16/56 | PASS | single-record at base r_g recovers |
| rg_low | new | 0.10 | 3 | 8/16/56 | PASS | |
| rg_high | new | 0.70 | 3 | 8/16/56 | PASS | |
| size_med | new | 0.42 | 3 | 16/32/112 | FAIL | only G[1,1] misses (see below) |
| rg_low_rec1 | new | 0.10 | 1 | 8/16/56 | FAIL | single-record × extreme r_g |
| rg_high_rec1 | new | 0.70 | 1 | 8/16/56 | FAIL | single-record × extreme r_g |

**5/8 pass; 3/8 fail.** Convergence was 50/50 on every cell (no optimizer failures).

## R9 covered-claim regression check — CLEAN

`base_inside` (which reproduces the already-covered `V4-MV-REML` scope) **PASSED** all six
parameters within 2·MCSE. **No regression** — the existing covered claim stands. (R9 would have
required a STOP-and-ask only on a `base_inside` failure.)

## What the three failures mean (honest boundaries, not breakdowns)

1. **`size_med` — the known small σ²a bias, now statistically detectable.** Only `G[1,1]` misses
   (bias −0.0548 vs 2·MCSE 0.0362); the other five are within, convergence 50/50, EBV accuracy
   0.90/0.91. The ~5% downward bias in the trait-1 additive variance is the SAME bias present in
   `base_inside` (−0.0472) — there it is within 2·MCSE only because the smaller design has a larger
   MCSE (0.0375). With more data, MCSE shrinks and the persistent bias becomes detectable. This
   **confirms** the documented `V4-MV-REML` G[1,1] caveat ("never 'unbiased'"); it is a small bias
   made visible, not a recovery breakdown.
2. **`rg_low_rec1` / `rg_high_rec1` — single-record × extreme-r_g identifiability boundary.** With
   one record per animal the genetic and residual covariances are weakly separable; at extreme r_g
   the genetic covariance `G[1,2]` is attenuated (rg_high_rec1: bias −0.095 vs 2·MCSE 0.091), per-seed
   pass-rate collapses (2–4%), and EBV accuracy drops to ~0.74. A **genuine boundary** of the
   estimator at single-record extreme-correlation designs. (`records_1` at base r_g still passes, so
   it is the *interaction* of 1 record with extreme r_g that breaks, not single records alone.)

## Conclusion (for Rose + maintainer; NOT an autonomous promotion)

- The estimator recovers within ±2·MCSE on the **covered scope + balanced/moderate broader cells**
  (asymmetric h², base-r_g single record, r_g ∈ {0.10, 0.42, 0.70} at 3 records).
- Two honest boundaries are now characterized: (a) a small persistent **σ²a (G[1,1]) downward bias**
  that becomes detectable at larger n; (b) a **single-record × extreme-r_g** identifiability limit.
- This is **mixed** broader-DGP evidence — it does NOT support a clean "recovers everywhere" claim.
  It informs either a **scoped** finish of `V4-MV-REML` (claim the regime where recovery holds, with
  the G[1,1] bias + single-record×extreme-rg boundary documented) **or** a follow-up (e.g., does the
  G[1,1] bias shrink with a bias-correction or more iterations; is size_med purely the MCSE-detectability
  effect). Either path requires a **real Rose audit + maintainer G10 sign-off** before any covered move.
- `V1-HERIT-TCAL` stays planned; public-covered fitting stays 1; nothing promoted by this run.

# 2026-07-09 — broader-DGP multivariate REML recovery (C8, DRAC job 47889484)

Banks the evidence for the ADEMP-predeclared W1 broader-DGP `V4-MV-REML` recovery
(`docs/dev-log/recovery-checkpoints/2026-06-29-w1-drac-ademp-predeclaration.md`),
which had been run but whose outputs were never committed (DRAC `/scratch` purge gap).
**Characterization only — nothing promoted** (R4: the ±2·MCSE band is fixed, no post-hoc
relaxation; `public_covered_count` 5, `V4-MV-REML` already covered).

## Run

- Driver `sim/phase4_multivariate_reml_recovery.jl`, array `sim/drac/phase4_v4_recovery.sbatch`
  over the 8 pre-declared cells in `sim/drac/phase4_v4_cells.tsv`. DRAC **fir**,
  `def-snakagaw_cpu`, 2 CPU / 8 G, `julia/1.10.10`, **50 cold-start seeds/cell**.
- Smoke `47889251_[1]` then full `47889484_[1-8]`. **All 8 COMPLETED, ~1–1.5 min each,
  50/50 seeds converged in every cell.** Evidence: `sim/drac/results/w1_v4/*_47889484_*.out`.
- Gate metric: `aggregate_within_2mcse` (per-parameter |bias| ≤ 2·MCSE across seeds).

## Result — 5 / 8 within band

| cell | records | rg | gate | flagged parameter (bias, MCSE) |
| --- | --- | --- | --- | --- |
| `base_inside` (covered scope) | 3 | 0.42 | **pass** | — |
| `rg_low` | 3 | 0.10 | **pass** | — |
| `rg_high` | 3 | 0.70 | **pass** | — |
| `h2_asym` | 3 | asym | **pass** | — |
| `records_1` | 1 | 0.42 | **pass** | — |
| `rg_low_rec1` | 1 | 0.10 | fail | G[1,1] −0.128 (0.060) |
| `rg_high_rec1` | 1 | 0.70 | fail | G[1,2] −0.095 (0.046) |
| `size_med` (16/32/112) | 3 | 0.42 | fail | G[1,1] −0.055 (0.018) |

## Finding — a small downward bias in the additive genetic (co)variance

One consistent signal across the failing cells: the **additive genetic (co)variance G is
recovered with a mild DOWNWARD bias**, while the residual **R0 is well-recovered everywhere**
(|bias| ≤ ~0.03, all within band). Interpretation:

- **Single-record designs (records = 1) at extreme rg are the sharp failures** — `rg_low_rec1`
  (G[1,1] −0.128) and `rg_high_rec1` (G[1,2] −0.095). With one record per individual the additive
  genetic variance is weakly identified against the residual, so the genetic (co)variance is
  under-estimated. Note `records_1` at the *base* rg (0.42) passes — it is records=1 **combined
  with extreme rg** that breaks, not single records alone.
- **`size_med` is a marginal, honest fail**: G[1,1] is under by only −0.055, but at the larger
  design the MCSE tightens to 0.018, so a small genuine bias becomes statistically detectable
  (per-seed pass-rate 0.90, 45/50). This is the REML small-sample genetic-variance bias surfacing
  once the noise is small enough to see it, not a gross failure.

## Claim boundary (feeds the covered-MV surface)

- The **covered scope (`base_inside`) reproduces**; moderate cells pass. The covered `V4-MV-REML`
  claim is unaffected.
- **Add a caveat**: single-record multivariate designs at extreme genetic correlation
  **under-recover the genetic covariance**, and the additive genetic (co)variance carries a mild
  downward bias generally (largest where identification is weak). This should surface in the
  multivariate claim boundary and the R user docs when the surface is promoted to R.
- **Screening tier**: 50 seeds/cell (MCSE ≈ what is printed). The pre-declared full campaign is
  2000 reps/cell; these 50-seed runs are TRIAGE, sufficient to flag the direction, not to set a
  calibrated bias magnitude. Re-run: `sbatch sim/drac/phase4_v4_recovery.sbatch`.

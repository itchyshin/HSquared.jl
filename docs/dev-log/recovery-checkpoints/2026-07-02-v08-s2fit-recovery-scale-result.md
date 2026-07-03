# Post-run checkpoint — v0.8-S2-FIT matrix-free MC-EM-REML recovery gate + scale feasibility

**Date:** 2026-07-02 · **Decision: BOTH legs PASS.** Pre-declaration:
`2026-07-02-v08-s2fit-recovery-scale-predeclaration.md` (PREDECL `66ac9521`, committed BEFORE the
run). Harness byte-identity verified on-node (`git show 66ac9521:sim/v08_s2fit_recovery_scale.jl`
== the harness that ran). Compute: **DRAC fir** (`julia-1.10.10`, 1 core), SLURM job 46725575
(recovery node fc30346-class; scale node fc30611). Raw: `sim/drac/results/s2fit_recovery_46725575.tsv`,
`s2fit_scale_46725575.tsv`.

## R1 — recovery gate (48 seeds, K=3, q=960): PASS

**PRIMARY criterion (the claim):** all 48 seeds converged AND `max|MC − EXACT|/EXACT = 2.64e-2 ≤
0.05` → **PASS**. The matrix-free MC-EM-REML fit **reproduces** the exact
`fit_sparse_multi_effect_aireml` (the covered `V3-NEFFECT-REML` estimator) on identical data across
all 48 seeds. The Monte-Carlo approximation does not distort the estimate.

**SECONDARY (informational — a joint estimator+DGP property the EXACT fit shares):**

| component | truth | mc_mean | bias | MCSE | \|bias\|/MCSE | ex_mean |
|---|---|---|---|---|---|---|
| σ²a | 1.0 | 1.0281 | +0.0281 | 0.0235 | 1.195 | 1.0297 |
| σ²_e1 | 0.5 | 0.4839 | −0.0161 | 0.0161 | 1.000 | 0.4841 |
| σ²_e2 | 0.5 | 0.4987 | −0.0013 | 0.0218 | 0.058 | 0.4988 |
| σ²e | 1.0 | 0.9934 | −0.0066 | 0.0165 | 0.400 | 0.9924 |

All four `|bias| ≤ 2·MCSE` (max 1.195), and `mc_mean ≈ ex_mean` throughout — the residual scatter
is the estimator's, not the MC approximation's. (The secondary criterion was NOT the gate, but it
also passes here.)

## R2 — scale feasibility (K=3, nprobe=48, 1 seed/size): FEASIBLE to q=200,000

| q (= n) | converged | EM iters | wall (s) | σ̂²a |
|---|---|---|---|---|
| 10,000 | ✓ | 14 | 11.5 | 1.007 |
| 50,000 | ✓ | 48 | 251.8 | 1.025 |
| 100,000 | ✓ | 33 | 392.2 | 1.011 |
| 200,000 | ✓ | 23 | 585.6 | 1.005 |

The matrix-free FIT **converges at every size to q=200,000** — where the direct multi-effect
AI-REML is fill-limited (Phase 5: K=3 direct is ~quadratic by q≈50k, infeasible past ~10⁵). This
extends the S2 SOLVE feasibility (shown to q=10⁶) to the FIT. Machine-specific measurement on DRAC
fir; single core. Wall-clock is dominated by the trace estimation (`nprobe·K = 144` matrix-free
solves per EM iteration) × the EM-iteration count — so total time reflects both (the per-iteration
cost is matrix-free/near-linear; the iteration counts vary 14–48). This motivates the trace
variance-reduction slice (V8.2: the K×-cheaper shared-probe estimator) in doc-25. A q=10⁶ FIT is
feasible-but-hours by the solve cost and was NOT attempted here (not claimed).

## Scope fence

Machine-specific. The matrix-free FIT is a supplied-machinery estimator that RECOVERS the exact
AI-REML VCs within MC error; it is NOT more accurate than exact (it approximates it), has NO
`loglik` / calibrated intervals (owed: V8.1/V8.3), and is NOT the public default. No external
comparator through this path yet (owed: V8.4). Same DGP as Phase 5 / V3-NEFFECT-REML gate (K=3,
pedigree-independent environmental factors).

## Status impact

No covered flip. `validation_status()` rows / covered / `public_covered_count` UNCHANGED except a
NEW `partial` row `V3-NEFFECT-MATFREE-FIT` documenting the matrix-free fit estimator (Slices A/B/C +
`:auto` dispatch) with this recovery+scale evidence and its owed items — an experimental engine
capability, not a covered claim, `public_covered_count` **5** UNCHANGED.

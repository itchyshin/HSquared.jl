# Post-run checkpoint — v0.8-S2 matrix-free-PCG vs direct-Cholesky multi-effect SOLVE

**Date:** 2026-07-02 · **Decision: GO (positive).** Pre-declaration:
`2026-07-02-v08-s2-matfree-pcg-predeclaration.md` (PREDECL `cad28efb`). Harness byte-identity:
`git show cad28efb:sim/v08_s2_matfree_pcg_benchmark.jl` == the harness that ran (verified on the
node before the run). Compute: **DRAC fir** (node `fc30564`, `julia-1.10.10`, 1 core,
`OPENBLAS_NUM_THREADS=1`), SLURM job 46705208. Raw: `sim/drac/results/s2_fc30564_46705208.tsv`.

## Result (K=3 multi-effect MME; supplied-variance SOLVE)

| q | matfree_min (s) | PCG iters | direct_min (s) | speedup | same-solution |
|---|---|---|---|---|---|
| 2000 | 0.0012 | 42 | 0.0035 | 2.9× | 1.9e-6 |
| 5000 | 0.0026 | 41 | 0.0099 | 3.8× | 7.2e-6 |
| 10000 | 0.0050 | 40 | 0.0242 | 4.8× | 9.3e-6 |
| 20000 | 0.0102 | 40 | 0.0741 | 7.3× | 1.1e-5 |
| 50000 | 0.0270 | 39 | 0.5126 | **19×** | 2.0e-5 |
| 100000 | 0.0758 | 38 | cap-excluded | — | — |
| 200000 | 0.1801 | 38 | cap-excluded | — | — |
| 500000 | 0.4072 | 37 | cap-excluded | — | — |
| **1000000** | **0.7728** | **36** | cap-excluded | — | — |

All cells `converged=true`, relres ≤ 1e-8. Direct path `nnz(L)`-cap-excluded (`>60M`) past q=50k.

## Pre-declared claims (all conditions met)

- **C2 (feasibility frontier — headline):** the matrix-free multi-effect solve remains feasible
  (`converged=true`, relres ≤ tol) to **q = 1,000,000** on `fc30564`, where the direct Cholesky is
  cap-excluded (`nnz(L) > 60M`) and not attempted. Direct's largest completed cell is q=50k
  (`nnz(L)=11.5M`). *The run demonstrates matrix-free feasibility; it does not measure direct
  infeasibility (no direct fit attempted above q=50k).*
- **C1 (scaling — descriptive):** matrix-free wall-clock log-log **OLS** slope ≈ **1.08**
  (R² ≈ 0.996) over the 9 median points q∈[2000,1e6] (min-time endpoints 0.0012→0.7728 s, 644×
  over 500×) — **near-linear**, well below the Phase 5 direct-K=3 exponent (~2.25).
  Machine-specific measurement on `fc30564`.
- **C3 (within-cluster crossover — descriptive):** on the overlap grid matrix-free is faster at
  every q, growing **2.9× → 19×** (q=2k→50k), with same-solution ≤ 2.0e-5 (≤ the 1e-4 gate) and
  PCG iterations recorded — so the speed difference is disclosed as iterative-Jacobi-vs-exact,
  not attributed to linear algebra alone.
- **C4 (iteration count — mandatory framing):** median PCG iterations **DECREASE** with q
  (42→36 as q grows 500×). Jacobi conditioning does not degrade at scale — this is why the
  matrix-free advantage holds; the advantage is contingent on this bounded-iteration behaviour,
  which held on this DGP/host.

## Scope fence (carried from the pre-declaration)

Machine-specific measurement on `fc30564`. This is a single **supplied-variance SOLVE**, NOT a
full REML fit (the AI-REML score needs a Takahashi selected inverse / a factor; a matrix-free
FIT route is a stochastic-trace/EM scheme, owed). NOT a GPU claim; NOT "faster than package Y";
NOT an accuracy/recovery claim; NO cross-machine absolute-time comparison; NOT a portable
guarantee. Same DGP as Phase 5 (half-sib pedigree + pedigree-independent environmental groups).

## Status impact

No covered flip. `validation_status()` rows **53** / covered **13** / `public_covered_count` **5**
UNCHANGED. `V1-PCG` (which now covers `solve_multi_effect_pcg`) gains this performance MEASUREMENT
on its evidence, staying `partial`. This closes the doc-23 v0.8-S2 "matrix-free MME operator —
the actual large-scale enabler beyond direct Cholesky at q→10⁶" as MEASURED: the solve reaches
q=10⁶ with flat iterations and near-linear scaling, where direct is fill-limited.

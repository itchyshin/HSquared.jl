# Phase 5 sparse-vs-dense AI-REML benchmark — RESULT (2026-07-02)

Post-run companion to the pre-declaration
`docs/dev-log/recovery-checkpoints/2026-07-02-phase5-sparse-benchmark-predeclaration.md`
(pre-declaration commit `PREDECL` = `662663ed`, committed BEFORE the run). **Decision: GO**
(the pre-declared claims C1/C2/C3 are supported; not a banked negative). This is a
**machine-specific measurement banked as evidence** on the `partial` row
`V3-NEFFECT-SPARSE` — **no covered flip, no count change, no `public_covered_count` change.**

## Manifest (Phase-7 packet)

- **Host:** `totoro` (384-core shared lab server), `julia 1.10.10`, `OPENBLAS_NUM_THREADS=1`,
  `JULIA_NUM_THREADS=1` (single core), BLAS `LBTConfig([ILP64] libopenblas64_.so)`.
- **Memory at start:** 386.9 GB free / 1007.3 GB total; `loadavg1` ≈ 92–96 (co-tenant load on
  other cores; the 1-core serial job contends with nothing meaningful).
- **Repo:** checked out to `PREDECL` (`662663ed`) on `main`; harness byte-identical to that
  commit's blob (see §Byte-identity).
- **Committed evidence:** `sim/phase5_sparse_benchmark_K3.tsv`, `sim/phase5_sparse_benchmark_K1.tsv`
  (raw per-`(q,path,seed,trial)` rows). Declared-grid attempt log preserved on Totoro as
  `~/hsq_work/r3_bench_declared_attempt.log`.
- **Protocol:** sparse `trials=5`, `nseeds=5`; dense `dense_trials=3`, `dense_seeds=2`;
  `dense_cap=4e6`; `base_seed=20260702`; warm-up excluded (global + per-cell); GC suppressed
  in the timed region; **min over trials** (co-tenant-noise robust) + **median over seeds**.

## Byte-identity (no post-hoc relaxation)

The harness `sim/phase5_sparse_aireml_benchmark.jl` that ran is byte-identical to its blob in
`PREDECL` (the run checked out `662663ed`; no post-`PREDECL` harness edit). The doc-16
no-relaxation invariant holds.

## Declared-grid deviation (transparent)

The pre-declaration §2 locked the K=3 sparse-only grid to `{2000,5000,10000,20000,50000}`. The
**initial declared-grid run** (evidence: `r3_bench_declared_attempt.log`) reached
`q=200…10000` for K=3 but **did not complete a single `q=20000` fit** in ~26 min before it was
stopped — the multi-effect sparse solve scales super-quadratically (q=10000 already ~23 s/fit;
q=20000 projected ~200 s/fit, q=50000 projected days), making `q≥20000` **infeasible in the
session budget**. This is itself a first-class finding (see §Headline). The reported run
therefore **caps K=3 at the feasible range `{…,10000}`** and runs **K=1 the full declared grid
`{…,50000}`** (K=1 scales fine — the contrast is the finding). This is a documented deviation
of the RUN, not a harness change (byte-identity holds); the C2 feasibility claim is reported on
the completed ranges, and `q≥20000` (K=3) is a banked feasibility-ceiling result, not hidden.

## Results — K=3 (multi-effect, headline)

min over trials, median over seeds; sparse `converged=true` and dense `converged=true` at all
reported cells.

| q | sparse min (s) | sparse med | sparse iters | dense min (s) | dense med | dense f_calls | speedup (min) |
|---|---|---|---|---|---|---|---|
| 200 | 0.0031 | 0.0059 | 11 | 0.383 | 0.450 | 250 | **122×** |
| 500 | 0.0119 | 0.0159 | 10 | 3.435 | 3.872 | 260 | **288×** |
| 800 | 0.0235 | 0.0267 | 9 | 14.63 | 14.93 | 276 | **624×** |
| 1000 | 0.0373 | 0.0409 | 9 | 25.81 | 26.93 | 270 | **692×** |
| 2000 | 0.2323 | 0.2586 | 8 | — (cap-excluded) | | | — |
| 5000 | 1.6725 | 1.8326 | 8 | — | | | — |
| 10000 | 20.87 | 23.53 | 8 | — | | | — |

- **sparse log-log slope:** 2.25 (R²=0.975) over q=200…10000; **2.67** (R²=0.989) over the
  tail q≥1000.
- **same-optimum:** max |σ_sparse − σ_dense| across overlap cells = **3.3e-5** (gate ≤0.01 → PASS).

## Results — K=1 (pure additive animal model, reference)

| q | sparse min (s) | sparse iters | dense min (s) | dense f_calls | speedup (min) |
|---|---|---|---|---|---|
| 200 | 0.0009 | 13 | 0.047 | 54 | 52× |
| 500 | 0.0016 | 9 | 0.896 | 64 | 558× |
| 800 | 0.0026 | 7 | 2.369 | 57 | 918× |
| 1000 | 0.0030 | 7 | 4.844 | 58 | **1596×** |
| 2000 | 0.0047 | 7 | — | | — |
| 5000 | 0.0148 | 5 | — | | — |
| 10000 | 0.0264 | 5 | — | | — |
| 20000 | 0.0737 | 5 | — | | — |
| 50000 | 0.2249 | 5 | — | | — |

- **sparse log-log slope:** **1.01** (R²=0.986) over q=200…50000; 1.12 (R²=0.991) tail.
- **same-optimum:** max |σ_sparse − σ_dense| = **1.8e-5** (PASS).

## Pre-declared claims — verdict

- **C1 (sparse scaling, descriptive — LICENSED):** on `totoro`, sparse wall-clock scales with an
  empirical exponent **≈1.0 for K=1** (near-linear to q=50000) and **≈2.25 for K=3** (full grid;
  ≈2.67 in the tail). Both are **below the dense O(n³) exponent**; K=1 is the near-linear regime,
  K=3 is super-linear (see §Headline). Reported as a measured slope + R², **not** a pass/fail
  gate.
- **C2 (crossover + feasibility — LICENSED):** sparse min-time ≤ dense min-time at **every**
  overlap size (X=200, monotone dominance above, sign-stable across all dense seeds; dense
  `converged=true` so the comparison is fair, not dense-running-unproductively). Sparse remains
  feasible (`converged=true`, bounded wall-clock) to **q=50000 for K=1** and to **q=10000 for
  K=3**; K=3 `q≥20000` is **cap-excluded/infeasible in-budget** (declared-attempt evidence),
  not "dense infeasibility" (no dense fit is attempted above q=1000).
- **C3 (confound decomposition — reported):** sparse converges in **~8–11 AI/Newton iterations**;
  dense runs **~250–276 NelderMead objective evaluations** (`f_calls`), each an O(n³) dense-V
  Cholesky. The speed gap is **both** far fewer iterations **and** far cheaper per iteration
  (sparse `O(nnz(L))` Cholesky + Takahashi selinv vs dense `O(n³)`). Per-unit costs are not
  independently observed (descriptive, not arithmetic division).

## Headline finding (the K=1-vs-K=3 contrast)

K=1 sparse scales **linearly** (slope 1.01) to q=50000, but K=3 sparse scales
**~quadratically** (slope 2.25). Since the only difference is the two i.i.d. environmental-effect
blocks, the super-linear degradation is **specifically attributable to the multi-effect
environmental-group columns** (high-degree, low-count columns that induce Cholesky fill-in
without a fill-reducing ordering). The pedigree/additive part scales fine; the multi-effect
structure is the scale bottleneck. This is consistent with the Wave-F note that a fill-reducing
ordering (METIS) is not implemented, and identifies it as the concrete next scale enabler.

## Honesty fences (all held)

- **Machine-specific measurement on `totoro`**, never a portable/competitive/absolute guarantee.
- **Estimator-vs-estimator** (AI-Newton vs NelderMead) end-to-end; the confound is disclosed via
  the iteration/f_call counts (C3). **NO** isolated-linear-algebra, GPU, production-hardening, or
  accuracy claim (timing ≠ correctness — the exact reduction to the dense optimum is separately
  gated in `test/runtests.jl`).
- **Same-optimum verified** on the variance components (σ agree ≤3.3e-5 ≪ 0.01) — the timing is
  a comparison of two estimators that reach the same optimum.
- **No promotion:** `V3-NEFFECT-SPARSE` stays `partial`; `validation_status()` rows = 53
  UNCHANGED; `public_covered_count` = 5 UNCHANGED.

## Owed (unchanged by this measurement)

A pre-declared bias/MCSE recovery gate for the sparse code path; a same-estimand external
comparator run *through* the sparse path at scale; a fill-reducing ordering (METIS) to recover
near-linear K≥2 scaling (the concrete enabler this benchmark identifies); the R multi-term
`(1|g)` bridge to the sparse estimator.

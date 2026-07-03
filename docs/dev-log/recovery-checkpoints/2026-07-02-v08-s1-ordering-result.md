# Post-run checkpoint — v0.8-S1 METIS-vs-AMD ordering (BANKED NEGATIVE, as pre-declared)

**Date:** 2026-07-02 · **Decision: BANK-NEGATIVE** (the pre-declared expected outcome).
Pre-declaration: `2026-07-02-v08-s1-ordering-predeclaration.md` (PREDECL `cad28efb`). Harness
byte-identical (`sim/v08_s1_ordering_benchmark.jl`). Compute: **DRAC fir** (node `fc30346`,
`julia-1.10.10`, `OPENBLAS_NUM_THREADS=1`), SLURM job 46705016. Metis is BENCHMARK-ONLY (a
throwaway env; NOT added to `Project.toml`). Raw: `sim/drac/results/s1_ordering_46705016.tsv`.

## Result (multi-effect MME coefficient matrix `C`)

| q | K | nnz(L) AMD | nnz(L) METIS | fill gain | t_AMD (s) | t_METIS (s) | speed gain |
|---|---|---|---|---|---|---|---|
| 2000 | 1 | 7761 | 7681 | 1.01× | 0.0003 | 0.0002 | 1.53× |
| 2000 | 3 | 86068 | 48365 | 1.78× | 0.0027 | 0.0019 | 1.45× |
| 5000 | 3 | 281470 | 195697 | 1.44× | 0.0083 | 0.0062 | 1.35× |
| 10000 | 3 | 802580 | 776091 | 1.03× | 0.0219 | 0.0190 | 1.16× |
| 20000 | 3 | 2404054 | 2382707 | 1.01× | 0.0691 | 0.0700 | **0.99×** |
| **50000** | **3** | **11518369** | **28473828** | **0.40×** | **0.4979** | **1.5820** | **0.31×** |
| 50000 | 1 | 194001 | 192001 | 1.01× | 0.0089 | 0.0066 | 1.34× |

## Pre-declared decision rule → BANK-NEGATIVE

ADOPT-METIS required METIS to reduce BOTH nnz(L) AND factorization time vs AMD **at every tested
(q, K) by ≥ 1.2×**. FAILED decisively: METIS helps at small/moderate q (K=3 q≤10k) but at
**q=50k K=3 produces 2.5× MORE fill and is 3.2× SLOWER** (crossover to worse already at q=20k,
speed 0.99×). K=1 is a wash (AMD near-optimal, consistent with Phase 5 "K=1 already near-linear").
Nested dissection degrades on the environmental-group columns at scale — a static reordering does
not cleanly separate them. **Decision: retain CHOLMOD AMD, add NO Metis dependency.** Reproduces
the local Mac measurement (METIS 3.3× slower at q=50k K=3).

## Consequence

This negative is *why* v0.8 pivoted to the matrix-free multi-effect PCG (S2), which never
forms/factors `C` and so bypasses the fill entirely — validated to q=10⁶ (see the S2 result
checkpoint). No status flip; `V3-NEFFECT-SPARSE` `owed`-note records the finding. Machine-specific
measurement; the claim is only "METIS is not a robust fill-reducing enabler for this multi-effect
structure", NOT "AMD is optimal".

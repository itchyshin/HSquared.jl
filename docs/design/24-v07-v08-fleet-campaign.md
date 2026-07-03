# doc-24 — v0.7 + v0.8 fleet compute campaign

**Authored:** 2026-07-02 (Claude, execution session). **Status:** PLAN — awaiting the maintainer's
pre-compute checkpoint (per the standing "checkpoint before any compute run" rule). Predecessor:
doc-23 (programme plan). All three benchmarks are pre-declared + frozen; the code is implemented
and locally correctness-gated. This doc is the compute-orchestration layer: which cluster runs
which frozen harness, and the honesty discipline for aggregating across machines.

## The idea (why a fleet, not one box)

v0.7 (GPU) and v0.8 (CPU-sparse) run on **disjoint hardware** → two fully parallel streams, zero
contention. Within each stream we **replicate the byte-identical frozen harness across several
machines at once**, so the whole scaling/feasibility curve is covered in one wall-clock window
instead of serially. The honest cost of using many machines is that **absolute wall-clock is not
comparable across different CPUs/GPUs** — so we never make a cross-machine time claim. What the
fleet buys is (a) the **feasibility frontier** (the largest q that completes anywhere), (b)
**cross-machine robustness** of the qualitative scaling, and (c) for the GPU stream,
**cross-architecture agreement** (the CPU↔GPU numerics must hold on H200 *and* H100 *and* A100).

## The fleet (8 DRAC + Totoro)

| Cluster | Type | Account | Role in this campaign |
|---|---|---|---|
| **tamIA** | GPU H200-141GB | `aip-snakagaw` | v0.7 G-A headline (largest q; `gpu_env` already set up from G1) |
| **Killarney** | GPU H100 | `aip-snakagaw` | v0.7 G-A cross-device agreement replicate |
| **Vulcan** | GPU H100 | `aip-snakagaw` | v0.7 G-A cross-device agreement replicate (alt to Killarney) |
| **Narval** | GPU A100 | `def-snakagaw` | v0.7 G-A third architecture (single-GPU dev-friendly) |
| **Fir** | CPU | `def-snakagaw_cpu` | v0.8 S2 full grid (F0 env already set up) |
| **Nibi** | CPU | `def-snakagaw_cpu` | v0.8 S2 full grid (large-RAM node → q=1M frontier) |
| **Rorqual** | CPU | `def-snakagaw_cpu` | v0.8 S2 full grid (cross-machine robustness) |
| **Trillium** | CPU | `def-snakagaw_cpu` | v0.8 S2 full grid (large-RAM node → q=1M frontier) |
| **Totoro** | CPU 384-core | (no SLURM) | v0.8 S1 banked-negative ordering + S2 replicate (no queue → fast turnaround) |

*(Narval has both A100 GPUs on `def-` and CPU nodes; used here for GPU. The GPU replicates only
need to CONFIRM the agreement gate + report per-device timing — one job each, ≤1 h.)*

## Stream A — v0.7 GPU (device-resident GBLUP, G-A)

- **Harness:** `sim/drac/g_a_device_gblup.jl` · **sbatch:** `sim/drac/g_a_gpu.sbatch` (tamia
  default; edit `--account`/module/paths for Killarney/Vulcan/Narval).
- **Pre-declaration:** `docs/dev-log/recovery-checkpoints/2026-07-02-v07-ga-device-gblup-predeclaration.md`.
- **What each job does:** HARD-GATE CPU↔GPU agreement (β + GEBV vs `fit_gblup`, `:vanraden1/2` +
  weighted) then benchmark end-to-end GBLUP CPU vs GPU across q. A clean run == agreement holds.
- **Fleet logic:** the agreement gate must pass on **every** GPU architecture (H200/H100/A100) —
  that is the cross-device confidence. Timing is reported **per device**, never compared across
  devices. tamia (biggest memory) establishes the largest-q end-to-end number.
- **Setup (one-time, login node):** the G1 `gpu_env` on `/project/aip-snakagaw` already has CUDA
  bound; `Pkg.develop` HSquared at `PREDECL` + `Pkg.precompile` so `HSquaredCUDAExt` resolves.

## Stream B — v0.8 CPU sparse (matrix-free PCG, S2)

- **Harness:** `sim/v08_s2_matfree_pcg_benchmark.jl` · **sbatch:** `sim/drac/s2_cpu.sbatch`
  (def- account; edit paths per cluster).
- **Pre-declaration:** `docs/dev-log/recovery-checkpoints/2026-07-02-v08-s2-matfree-pcg-predeclaration.md`.
- **What each job does:** matrix-free PCG vs direct-Cholesky SOLVE of the K=3 multi-effect MME,
  overlap grid q∈{2k..50k} (both paths, same-solution + PCG-iters recorded) + matrix-free-only
  grid q∈{100k..1M} (direct `nnz(L)`-capped). Single core, BLAS pinned.
- **Fleet logic:** every CPU box runs the **whole byte-identical grid up to its RAM**. The
  large-RAM nodes (Nibi, Trillium, `--mem=249G`) push the q=1M feasibility cells; the others give
  cross-machine robustness of the near-linear scaling + within-machine crossover. **Within a
  machine**, matrix-free-vs-direct is a fair comparison; **across machines** we aggregate only the
  feasibility frontier + the internal ratios, never absolute times.
- **Setup (one-time, login node):** checkout HSquared.jl to `PREDECL` under `/project`,
  `Pkg.instantiate()` against the `/project` julia_depot (NEVER `/scratch`).

## Stream C — v0.8 S1 banked-negative ordering (Totoro / one CPU node)

- **Harness:** `sim/v08_s1_ordering_benchmark.jl` (Metis is BENCHMARK-ONLY; throwaway env).
- **Pre-declaration:** `docs/dev-log/recovery-checkpoints/2026-07-02-v08-s1-ordering-predeclaration.md`.
- One quick job formalizes the METIS-vs-AMD finding on a recorded manifest (local Mac already
  shows METIS 3.3× slower at q=50k K=3 → expected BANK-NEGATIVE, AMD retained, no dependency).

## Honesty rail (carried from Phase 5 / doc-23, non-negotiable)

1. Every perf/scale claim is pre-declared (committed BEFORE the run), harness byte-identical,
   machine-specific, with a bank-a-negative clause and a real Rose audit before any status edit.
2. **No cross-machine absolute-time comparison.** Fleet aggregation = feasibility frontier +
   within-machine ratios + cross-device agreement only.
3. No covered flip. `validation_status()` rows **53**, covered **13**, `public_covered_count`
   **5** UNCHANGED. These are engine performance/scale/agreement measurements, not new estimands
   or a public default change.
4. Compute golden rules: never a login-node run (sbatch/salloc); `/project` not `/scratch`; name
   the GPU model + set `--time`/`--account`; pin `OPENBLAS_NUM_THREADS=1`; ≤100 cores on Totoro.

## Sequencing at the checkpoint

On GO: (1) push `PREDECL` (the frozen harnesses + pre-declarations + implemented code); (2)
one-time setup per cluster (login-node `Pkg.instantiate`/`develop` at `PREDECL`); (3) submit
Stream A (3–4 GPU jobs) + Stream B (4 CPU jobs) + Stream C (1 job) — all independent, all at once;
(4) ingest the TSVs from `sim/drac/results/`; (5) per-stream post-run checkpoint + Rose audit;
(6) evidence-only status edits (no covered flip).

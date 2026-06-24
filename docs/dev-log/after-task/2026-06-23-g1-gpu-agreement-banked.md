# After-task — Wave F G1 close-out: GPU agreement + benchmark banked (tamia) — 2026-06-23

## Task goal

Finish C: run the authored G1 GPU genomic path (#184) on the tamia cluster, ingest the
CPU↔GPU agreement + benchmark, and flip the `V2-GRM-GPU` rows from "run pending" to
"GPU-agreed + benchmarked". `[JL]`; experimental; **no `covered` promotion**.

## What landed

- The run executed on tamia (4× H100, CUDA 12.6, job **352612**, exit 0, 1:47). The CPU↔GPU
  agreement PASSED across all variants (GPU `G` vanraden1/2/weighted + ridge `Ginv` ≡ CPU to
  **~1e-14**; the `(G+rI)·Ginv ≈ I` true-inverse check holds). Benchmark: `G` GEMM **1.3×→~5×**
  (m=2000→40000), ridge `Ginv` **~2.9×** (end-to-end Float64, n=4000).
- Committed: `sim/drac/results/g1_gpu_352612.tsv`, the checkpoint
  `docs/dev-log/recovery-checkpoints/2026-06-23-g1-gpu-agreement-benchmark.md`, the corrected
  `sim/drac/g1_tamia.sbatch` (matches what ran), and the three flipped status rows.

## Setup notes (for the next cluster run — earned this session)

- `gpu_env` is a Julia **project** (CUDA + `LocalPreferences` `local=true 12.6`), NOT a depot;
  the depot is `/project/aip-snakagaw/julia_depot`. The G0 project had CUDA but not HSquared —
  `Pkg.develop`'d HSquared into it (login node, internet) so the `HSquaredCUDAExt` extension
  resolves + precompiles. Module order on tamia matters: `julia/1.10.10` (x86-64-v3/Core)
  BEFORE `cuda/12.6`, and **never pipe `module load`** (the pipe runs it in a subshell → env
  lost). No `--partition` needed (`--gpus-per-node=h100:4` routes it). All documented in the
  sbatch header + the cross-project DRAC runbook should get this delta.

## Checks run and exact outcomes

- Full `Pkg.test()` green ("Testing HSquared tests passed"; Phase 0 363/363, count 48; GPU
  stubs 7/7). `docs/make.jl` green.
- Real `rose-systems-auditor`: **CLEAN** (no blocking changes). Recomputed every speedup +
  agreement figure from the committed `.tsv`/checkpoint, confirmed count 48 + no `covered`
  promotion + sbatch fidelity + no stale "pending". Took its one precision note (Ginv "~2.9×"
  → "~2.7×–2.9×" with the transient dip to 2.1× disclosed).

## Public claim audit (Rose) — honesty hinges

The flip asserts NEW evidence (agreement + speedups). Every number traces to the committed
`.tsv` + the run output (job 352612). The agreement is stated as "~1e-14" (matching the
measured 8.9e-16–8.5e-14); the speedups are framed as a **machine-specific MEASUREMENT, NOT a
competitive claim** (single H100 vs single-thread OpenBLAS, end-to-end incl. transfer, Float64).
GPU = acceleration, same estimand (confirmed by the agreement); **nothing promoted to `covered`**
(rows stay `partial`/`experimental`).

## Next actions

1. ✅ Real `rose-systems-auditor` CLEAN (recorded above); commit + push + PR (CI gates suite + docs).
2. G1 is now fully banked. Track B next: **G2 (GBLUP/GREML on GPU)** → G3 (marker scan) → G4
   (low-rank) → G5 (bank), each CUDA port + CPU↔GPU agreement + benchmark. Plus the deferred
   G1 follow-ups (device-resident `G` for G2 chaining, a Float32 path, a real-marker panel).

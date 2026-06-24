# Recovery checkpoint — G1 GPU VanRaden G/Ginv: CPU↔GPU agreement + benchmark (tamia run)

**2026-06-23 · Wave F Track B, G1 close-out.** The authored G1 GPU genomic path (#184) is now
RUN on hardware: the CPU↔GPU agreement gate passed and the benchmark is recorded. This banks
the evidence the #184 rows owed; `V2-GRM-GPU` flips from "run pending" to "GPU-agreed +
benchmarked". `[JL]` engine; experimental; **no `covered` promotion** (GPU = acceleration, not
a new estimand).

## Run provenance

- **Cluster/GPU:** tamia (PAICE), **NVIDIA H100 80GB HBM3**, CUDA **12.6.0**, 79.2 GiB.
  Whole-node `--gpus-per-node=h100:4` (G1 uses one GPU), `aip-snakagaw`.
- **Job:** SLURM **352612**, state COMPLETED (exit 0:0), elapsed **00:01:47**, node tg11305.
- **Julia:** 1.10.10. Depot `/project/aip-snakagaw/julia_depot`; project
  `/project/aip-snakagaw/gpu_env` (CUDA bound via `LocalPreferences.toml`
  `CUDA_Runtime_jll local=true version=12.6`, with HSquared `Pkg.develop`'d into it so the
  `HSquaredCUDAExt` extension loads). Modules `julia/1.10.10 cuda/12.6` (julia first).
- **Script:** `sim/drac/g1_gpu_genomic.jl` (committed). Output `.tsv` committed at
  `sim/drac/results/g1_gpu_352612.tsv`. Launcher `sim/drac/g1_tamia.sbatch`.

## CPU↔GPU agreement — PASS (the script hard-fails on any mismatch; exit 0 confirms)

`AGREEMENT n=400 m=2000 ridge=0.01` — every variant matched the CPU twin to floating-point
round-off:

| check | maxΔ | relΔ |
|---|---|---|
| `G` vanraden1 | 8.882e-16 | 8.006e-16 |
| `G` vanraden2 | 8.882e-16 | 8.032e-16 |
| `G` weighted | 1.110e-15 | 1.011e-15 |
| `Ginv` (from CPU `G`) | 2.220e-15 | 1.342e-15 |
| `Ginv` (end-to-end GPU) | 8.527e-14 | 5.152e-14 |
| `(G+ridge·I)·Ginv_gpu ≈ I` (true inverse) | 3.664e-15 | 3.664e-15 |

So the GPU VanRaden `G` (all three constructions) and the ridge `Ginv` are **numerically
identical to the CPU path to ~1e-14** — confirming the "GPU = acceleration, not a new estimand"
fence by measurement.

## Benchmark — end-to-end (incl. H2D/D2H transfer), Float64, n=4000

| m | cpu_G (s) | gpu_G (s) | G speedup | cpu_Ginv (s) | gpu_Ginv (s) | Ginv speedup | maxΔ G | maxΔ Ginv |
|---|---|---|---|---|---|---|---|---|
| 2000 | 0.590 | 0.455 | 1.30× | 0.983 | 0.358 | 2.75× | 5.6e-15 | 3.3e-12 |
| 5000 | 1.232 | 0.584 | 2.11× | 0.993 | 0.348 | 2.86× | 5.6e-15 | 2.1e-14 |
| 10000 | 2.373 | 0.595 | 3.99× | 1.012 | 0.345 | 2.94× | 8.7e-15 | 3.3e-15 |
| 20000 | 4.348 | 0.878 | 4.95× | 1.008 | 0.482 | 2.09× | 9.5e-15 | 2.2e-15 |
| 40000 | 8.611 | 1.850 | 4.65× | 1.005 | 0.345 | 2.91× | 1.6e-14 | 1.8e-15 |

**Honest read (Phase-7 packet):** the **`G` GEMM** wins more as marker count `m` grows
(1.3× at m=2000 → ~5× at m=20000–40000 — the GPU GEMM amortises the H2D/D2H transfer as
compute grows); the **ridge Cholesky `Ginv`** is **~2.7×–2.9×** (n-bound, m-independent — 4 of 5 m at ~2.9×, one transient dip to 2.09× at m=20000; see the per-row table above).
These are END-TO-END (include transfer), Float64, single H100 vs single-thread OpenBLAS on this
node — a **machine-specific MEASUREMENT, not a competitive/marketing claim**. Larger speedups
are available in Float32 and by keeping `G` device-resident across G1→G2 (both deferred).

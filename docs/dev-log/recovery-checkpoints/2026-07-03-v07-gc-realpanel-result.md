# v0.7-G-C large / realistic-panel genomic-G benchmark — RESULT (2026-07-03)

The committed tamia run of the pre-declared `sim/drac/g_c_realpanel.jl`. Benchmarks
`gpu_genomic_relationship_matrix` at realistic genomic-panel dimensions + device-memory profile.
Predeclaration: `2026-07-03-v07-gc-realpanel-predeclaration.md`.

- **Run:** tamia SLURM job **360812**, node tg11205, **NVIDIA H100 80GB HBM3**, CUDA 13.0 driver /
  CUDA.jl runtime 12.6, Julia 1.10.10, 2026-07-03. Artifacts:
  `sim/drac/results/g_c_realpanel_360812.tsv`, `.../v07_gc_panel_360812.out`. LARGE SIMULATED panel
  (biallelic {0,1,2}, MAF 0.05–0.95) — not a specific real dataset.

## Agreement gate — PASSED

At n=4000/m=20000 (CPU reference feasible): `max|GPU_f64 − CPU| = 1.35e-14` — the GPU `G` matches
the CPU `genomic_relationship_matrix` to BLAS round-off at scale.

## Benchmark + device-memory profile

| n | m | f64 s | f32 s | speedup | W (GiB) | G (GiB) | peak alloc (GiB) | GPU mem % |
|---|---|---|---|---|---|---|---|---|
| 10000 | 50000 | 6.52 | 6.76 | 0.96 | 3.73 | 0.75 | 5.22 | 5.6 |
| 10000 | 100000 | 12.24 | 10.56 | 1.16 | 7.45 | 0.75 | 8.94 | 10.4 |
| 10000 | 200000 | 24.41 | 21.61 | 1.13 | 14.90 | 0.75 | 16.39 | 19.8 |
| 20000 | 50000 | 15.12 | 13.75 | 1.10 | 7.45 | 2.98 | 13.41 | 13.2 |
| 20000 | 100000 | 28.11 | 24.46 | 1.15 | 14.90 | 2.98 | 20.86 | 22.6 |
| 10000 | 300000 | 40.97 | 29.61 | 1.38 | 22.35 | 0.75 | 23.84 | 29.2 |

## Honest findings

- **The GPU path HANDLES realistic genomic-panel dimensions:** up to **n=20,000 individuals ×
  m=300,000 SNPs** on a single H100, the largest cell using **~24 GB (29% of 80 GB)**. The **n×m
  marker matrix `W` DOMINATES device memory** (up to 22.35 GB) as predicted — the n×n `G` is only
  0.75–3 GB. Realistic panels fit comfortably on one H100. This is the point of the slice: a memory
  envelope + feasibility record.
- **The Float32 speedup stays MODEST even at panel scale: 0.96×–1.38×** (m=50000 is even slightly
  SLOWER in Float32) — consistent with G-B (H100) and the A100 cross-device run. TF32 not engaged.
- The **absolute `G`-build times (6–41 s) are dominated by the CPU-side `centered_markers` +
  the H2D transfer of the large `W`** (up to 22 GB up), NOT the GEMM (which is sub-second on an H100
  at these sizes). So the reported "speedup" is end-to-end (transfer-bound); the modest Float32 win
  reflects that transfer + CPU prep dilute any GEMM gain at these sizes. The best Float32 case (1.38×,
  m=300000) is the most GEMM-heavy. Honest: this is a feasibility + memory-envelope measurement, NOT
  a speed headline.

## Scope

Machine-specific H100 measurement; LARGE SIMULATED panel (not a real genotype dataset); no
competitive/portable-performance claim; GPU = acceleration, return always `Matrix{Float64}`,
same estimand. `V2-GRM-GPU` stays `partial`; NO covered flip; `public_covered_count` UNCHANGED.

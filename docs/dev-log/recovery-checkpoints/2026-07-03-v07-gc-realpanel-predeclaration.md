# v0.7-G-C large / realistic-panel genomic-G benchmark — PRE-DECLARATION (2026-07-03)

Pre-declares the G-C run BEFORE submitting to tamia. The G-A/G-B runs benchmarked modest panels
(n≤4000, m≤80k). G-C benchmarks `gpu_genomic_relationship_matrix` at REALISTIC genomic-panel
dimensions and profiles device memory.

## What runs (`sim/drac/g_c_realpanel.jl` + `sim/drac/g_c_tamia.sbatch`)

A LARGE SIMULATED panel (biallelic {0,1,2}, MAF 0.05–0.95 — not a specific real dataset, but at
realistic scale): n ∈ {10k, 20k} genotyped individuals × m ∈ {50k, 100k, 200k, 300k} SNPs. Cells are
sized so the n×m marker matrix `W` (n·m·8 bytes, Float64 — which DOMINATES device memory at scale,
not the n×n `G`) fits an 80 GB H100 with headroom; oversized cells self-SKIP.

Per (n, m):
- **HARD AGREEMENT gate** (smallest cell, n=4000/m=20000 where the CPU reference is feasible):
  `precision = Float64` GPU `G` ≡ CPU `genomic_relationship_matrix` to < 1e-10. `error()`s otherwise.
- **`G`-build time** Float64 and the opt-in Float32, + the Float32 speedup.
- **Device-memory profile:** measured peak allocation (`CUDA.@allocated`) vs the theoretical W + G
  bytes and the % of GPU memory.

## Pre-declared expectations (honest)

- The AGREEMENT gate PASSES (numerical-equivalence property, already shown at G-A/G-B scale).
- The Float32 speedup stays MODEST (~1.1–1.4×, as measured at G-B scale on H100 + A100; TF32 not
  engaged) — the large panel is NOT expected to change that unless the GEMM becomes compute-bound
  enough to expose the SGEMM-vs-DGEMM 2× (report honestly whatever it is).
- The memory profile shows `W` (n·m·8) dominating — the point of the slice is to confirm the GPU
  path HANDLES realistic panel dimensions + to record the memory envelope, NOT a speed headline.

## Honesty fences (pre-committed)

- LARGE SIMULATED panel, not a real genotype dataset (honest framing on every surface). Machine-
  specific H100 timings, NO competitive/portable-performance claim. GPU = acceleration, not a new
  estimand; return always `Matrix{Float64}`.
- `V2-GRM-GPU` stays `partial`; NO covered flip; `public_covered_count` UNCHANGED.
- Claim empty until the committed tamia run lands its `.tsv`. Binaries/generated git-ignored; the
  harness + sbatch + this predeclaration + the ingested `.tsv` are tracked.

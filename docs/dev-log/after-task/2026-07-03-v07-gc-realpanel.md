# After-task — v0.7-G-C: large / realistic-panel genomic-G benchmark (2026-07-03)

**Owner:** Claude solo (Opus), autonomous (goal: finish doc-25). **Branch:**
`feat/2026-07-03-v73-realpanel` off `main` @ `7da69f5a`. **Counts:** rows **55**, covered **13**,
`public_covered_count` **5** — NO covered flip.

## Headline

Benchmarked `gpu_genomic_relationship_matrix` at realistic genomic-panel dimensions on a tamia H100
and profiled the device memory: **the GPU handles n=20,000 × m=300,000 on one H100** (largest cell
~24 GB = 29% of 80 GB; the n×m marker matrix `W` dominates memory, not the n×n `G`), the agreement
gate holds at scale (1.35e-14), and the Float32 speedup stays **modest (0.96×–1.38×)** — a
feasibility + memory-envelope record, not a speed headline.

## What landed

- **`sim/drac/g_c_realpanel.jl` + `sim/drac/g_c_tamia.sbatch`** — the pre-declared large-panel
  harness (agreement gate + G-build time Float64/Float32 + device-memory profile via `CUDA.@allocated`).
- **Evidence (tracked):** `sim/drac/results/g_c_realpanel_360812.tsv` + `v07_gc_panel_360812.out`.
  Pre-declaration + result checkpoints.
- **Status sweep:** `V2-GRM-GPU` (owed "real-marker-panel benchmark" → delivered), capability-status
  GPU row, doc-25 V7.3 → DONE.

## Evidence (tamia H100, job 360812)

- Agreement gate (n=4000/m=20000): `max|GPU_f64 − CPU| = 1.35e-14`.
- 6 cells n∈{10k,20k}×m∈{50k..300k}: largest `W` 22.35 GB, peak alloc 23.84 GB (29% of 80 GB); the
  panel fits comfortably on one H100. Float32 speedup 0.96×–1.38× (m=50000 slightly slower);
  transfer-bound (CPU centering + H2D of `W` dominate the 6–41 s times, not the sub-second GEMM).

## Honesty pins

- LARGE SIMULATED panel, NOT a real genotype dataset (stated on every surface). Machine-specific
  H100 measurement; no competitive/portable claim. GPU = acceleration, same estimand, return always
  `Matrix{Float64}`. `V2-GRM-GPU` stays `partial`; NO covered flip; `public_covered_count` UNCHANGED.
  `Pkg.test()` GREEN (55).

## Next (finish doc-25)

V7.5 (G-E close-out — Rose + `V2-GRM-GPU` consolidation + `status_cache` refresh) is the last V7
numbered slice. Then the owed legs: V8.4 at-scale comparator + coverage-calibrated intervals.

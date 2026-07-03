# Check-log — v0.7-G-C large-panel genomic-G benchmark (2026-07-03)

**Slice:** benchmark `gpu_genomic_relationship_matrix` at realistic panel dimensions + a
device-memory profile. Branch `feat/2026-07-03-v73-realpanel`.

## Key result (tamia H100, job 360812)

- Agreement gate PASSED: `max|GPU_f64 − CPU| = 1.35e-14` (n=4000/m=20000).
- GPU HANDLES **n=20,000 × m=300,000** on one H100 (largest cell ~24 GB = 29% of 80 GB; the n×m
  marker matrix `W` dominates memory, up to 22 GB, not the n×n `G`).
- Float32 speedup MODEST even at scale (0.96×–1.38×; transfer-bound — CPU centering + H2D of the huge
  `W` dominate the 6–41 s build times, not the sub-second GEMM).

## Evidence

- Harness `sim/drac/g_c_realpanel.jl` + `sim/drac/g_c_tamia.sbatch` (pre-declared before the run).
- Artifacts (tracked): `sim/drac/results/g_c_realpanel_360812.tsv`, `v07_gc_panel_360812.out`.
- Result checkpoint `2026-07-03-v07-gc-realpanel-result.md`.
- `Pkg.test()` GREEN (count 55 UNCHANGED); `V2-GRM-GPU` stays `partial`.

## Honesty

LARGE SIMULATED panel (not a real dataset); machine-specific, no competitive claim; feasibility +
memory-envelope record. No covered flip; `public_covered_count` UNCHANGED.

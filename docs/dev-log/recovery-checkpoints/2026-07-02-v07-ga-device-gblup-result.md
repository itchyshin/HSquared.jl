# Post-run checkpoint — v0.7 G-A device-resident GBLUP (agreement PASSED; benchmark on feasible range)

**Date:** 2026-07-02 · **Decision: agreement gate PASSED (correctness headline).** Pre-declaration:
`2026-07-02-v07-ga-device-gblup-predeclaration.md` (PREDECL `cad28efb`, committed BEFORE the run).
Harness byte-identical (`sim/drac/g_a_device_gblup.jl`, verified on the node). Compute: **DRAC
tamia** GPU node `tg11304`, **NVIDIA H100 80GB HBM3**, CUDA 12.6, `julia-1.10.10`. SLURM job
360583 (agreement + first benchmark), job 360589 (benchmark rerun on the feasible range).

## A1 — CPU↔GPU agreement (HARD GATE, PASSED)

The device-resident GBLUP (`gpu_fit_gblup`: `G = W·Wᵀ/k` GEMM → `Ginv = inv(G+ridge·I)` →
dense Henderson MME solve, all on-device) matches the CPU pipeline
`genomic_relationship_matrix → genomic_relationship_inverse → fit_gblup` to floating-point
tolerance on every agreement cell (q=400, m=2000, ridge=0.01):

| quantity | method | maxΔ | relΔ |
|---|---|---|---|
| β | vanraden1 | 1.78e-15 | 3.54e-16 |
| GEBV | vanraden1 | 3.86e-15 | 2.89e-15 |
| β | vanraden2 | 2.67e-15 | 5.31e-16 |
| GEBV | vanraden2 | 3.89e-15 | 2.87e-15 |
| β | weighted | 1.16e-15 | 2.31e-16 |
| GEBV | weighted | 3.89e-15 | 2.90e-15 |

**`# agreement OK`** (the harness HARD-FAILS on any mismatch, so a clean run == agreement holds).
Device-resident GBLUP is numerically identical to the CPU `fit_gblup` on H100. This corroborates
the pre-run CPU-mirror validation (device assembly reproduced `fit_gblup` to ~1e-15 on CPU).
Raw: `sim/drac/results/v07_ga_gpu_360583.out`.

## B1 — end-to-end GPU-vs-CPU benchmark (feasible q-range)

Declared-grid deviation (transparent, per the Phase 5 pattern): the first run's benchmark
OOM-killed on the **q=32000 CPU reference** cell (a 32k×32k dense CPU Cholesky-inverse + MME
exceeded host RAM, MaxRSS 67G > the 64G request) — the GPU side (80 GB HBM) was fine. The
**agreement gate had already PASSED** before the OOM. The benchmark was re-run (job 360589) with
the grid capped at the feasible range **q ∈ {2000, 4000, 8000, 16000}** (m=5000), harness
byte-identical — only the grid arg + SLURM memory differ (infrastructure the harness
parameterizes). q=32000 is a documented CPU-reference-infeasibility cap, NOT a claim relaxation.

End-to-end GBLUP (G build + ridge inverse + MME solve), CPU vs device-resident GPU, on H100
`tg11306` (m=5000 markers; q = genotyped population; job 360589, COMPLETED):

| q | CPU (s) | GPU (s) | speedup | maxΔβ | maxΔGEBV |
|---|---|---|---|---|---|
| 2000 | 0.988 | 0.189 | **5.2×** | 3.7e-14 | 2.0e-14 |
| 4000 | 3.746 | 0.292 | **12.8×** | 1.8e-14 | 1.8e-14 |
| 8000 | 16.542 | 0.950 | **17.4×** | 3.3e-14 | 1.3e-13 |
| 16000 | 76.883 | 3.337 | **23.0×** | 5.3e-14 | 2.1e-13 |

The device-resident speedup grows with q (dense GBLUP is O(q³), so the GPU advantage compounds):
5.2× at q=2000 → 23× at q=16000. CPU↔GPU agreement holds through the benchmark too (β/GEBV maxΔ ≤
2.1e-13, consistent with the A1 gate's ~1e-15 at q=400 — the modest growth is float accumulation
at larger q, still negligible vs the O(1) values). Raw: `sim/drac/results/g_a_gblup_360589.tsv`.

Machine-specific measurement on H100 `tg11304`; end-to-end includes H2D marker transfer + D2H
result transfer. NOT a competitive/"faster than package Y" claim; NOT a REML-fit claim (this is a
supplied-variance solve); NOT a Float32 claim (that is G-B). Raw:
`sim/drac/results/g_a_gblup_360589.tsv`.

## Status impact

No covered flip. `validation_status()` rows **53** / covered **13** / `public_covered_count` **5**
UNCHANGED. Row `V2-GRM-GPU` gains the device-resident agreement + benchmark evidence, staying
`partial`. Closes the doc-23 v0.7-G-A "device-resident GBLUP solve keeping G on-device" as
AGREEMENT-verified on H100 (the correctness headline); the benchmark is a machine-specific
speedup measurement on the feasible q-range.

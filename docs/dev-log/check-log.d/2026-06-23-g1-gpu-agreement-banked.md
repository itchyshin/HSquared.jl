# Check log — Wave F G1 close-out: GPU CPU↔GPU agreement + benchmark BANKED (tamia run)

**2026-06-23 · Wave F Track B, G1 (#184) close-out.** `[JL]` engine/infra; experimental; **no
`covered` promotion**.

## What landed

The authored G1 GPU path (#184) is now RUN on hardware; the owed evidence is banked and the
`V2-GRM-GPU` rows flip from "run pending" to "GPU-agreed + benchmarked".

- **The run:** tamia, 4× NVIDIA H100 80GB, CUDA 12.6, julia 1.10.10; SLURM job **352612**
  COMPLETED (exit 0), 1:47. Depot `/project/aip-snakagaw/julia_depot`; project `gpu_env`
  (CUDA bound `local=true 12.6`, HSquared `Pkg.develop`'d in so `HSquaredCUDAExt` loads).
- **Committed artifacts:** `sim/drac/results/g1_gpu_352612.tsv` (the benchmark) +
  `docs/dev-log/recovery-checkpoints/2026-06-23-g1-gpu-agreement-benchmark.md` (full numbers +
  provenance). `sim/drac/g1_tamia.sbatch` CORRECTED to the incantation that actually ran
  (depot `julia_depot`, project `gpu_env`, module `julia/1.10.10 cuda/12.6` julia-first; the
  one-time `Pkg.develop` setup documented in its header).
- **Rows flipped:** capability-status (AI-REML→GPU row), validation-debt `V2-GRM-GPU`,
  `validation_status()` `V2-GRM-GPU` (count stays 48 — string edits, no new row).

## The evidence (script hard-fails on mismatch; job exit 0 ⇒ agreement passed)

- **CPU↔GPU agreement (n=400, m=2000):** GPU `G` vanraden1/2/weighted maxΔ 8.9e-16–1.1e-15;
  `Ginv` from CPU `G` 2.2e-15; end-to-end GPU `Ginv` 8.5e-14; `(G+rI)·Ginv ≈ I` 3.7e-15 — all
  OK. **GPU ≡ CPU to ~1e-14**, confirming "acceleration, not a new estimand" by measurement.
- **Benchmark (end-to-end Float64, n=4000):** `G` GEMM 1.3×→~5× as m grows (2000→40000); ridge
  `Ginv` ~2.9×. Machine-specific MEASUREMENT, NOT a competitive claim.

## Checks run and exact outcomes

- **Full `Pkg.test()` green** (julia 1.10.0, "Testing HSquared tests passed"); Phase 0 scaffold
  363/363 (`validation_status()` count **48**, unchanged); GPU stubs 7/7.
- **`docs/make.jl` green**.
- Real `rose-systems-auditor`: **CLEAN**. Independently recomputed every speedup from the
  committed `.tsv` (build 1.30/2.11/3.99/4.95/4.65×; inv mean 2.71×, one dip to 2.09× at
  m=20000) and the agreement range, confirmed `validation_status()` stays 48 + no `covered`
  promotion + the sbatch matches the run + no stale "pending"/"owed" residue anywhere. One
  precision note (Ginv "~2.9×" → "~2.7×–2.9×" with the transient-dip disclosed) — applied.
  No blocking changes.

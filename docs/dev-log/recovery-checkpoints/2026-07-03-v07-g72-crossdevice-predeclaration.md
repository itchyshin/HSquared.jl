# v0.7-G-7.2 cross-device GPU agreement replicate (Narval A100) — PRE-DECLARATION (2026-07-03)

Pre-declares the cross-device replicate BEFORE the Narval run. The existing GPU evidence (G-A
device-resident GBLUP, G-B Float32) is from a SINGLE architecture (tamia H100). V7.2 re-runs the
SAME committed harnesses on a DIFFERENT architecture (NVIDIA A100, Narval) to confirm the CPU↔GPU
agreement + the Float64 gate are architecture-portable, and to characterize Float32 on A100.

## What runs (unchanged committed harnesses — no new code)

- `sim/drac/g_a_device_gblup.jl` — device-resident GBLUP CPU↔GPU agreement (HARD-FAIL gate) +
  end-to-end benchmark. Already RUN + PASSED on tamia H100 (~1e-15, jobs 360583/360589).
- `sim/drac/g_b_float32.jl` — Float64 gate + Float32 accuracy fence + speedup. Already RUN on tamia
  H100 (gate 7.3e-15, Float32 GEBV ~1e-6, modest ~1.2× speedup; job 360780).
- sbatch: `sim/drac/g_ab_narval.sbatch` (account `def-snakagaw`, `--gpus-per-node=a100:1`).

## Pre-declared gates / expectations

- **G-A agreement (HARD gate):** the device-resident GBLUP β/GEBV must match the CPU pipeline to
  ~1e-13 on the A100 (the harness `error()`s otherwise). Expectation: PASSES — the agreement is a
  numerical-equivalence property of the algorithm, not architecture-specific.
- **G-B Float64 gate (HARD):** `precision = Float64` GPU `G` ≡ CPU to < 1e-10 on the A100.
  Expectation: PASSES.
- **G-B Float32 (characterize):** the Float32 accuracy + speedup on A100. A100 also has TF32 tensor
  cores; it is an open question (characterized, not gated) whether A100's default math mode engages
  TF32 for this GEMM (tamia H100's did not — default==pedantic FP32). Report both modes honestly.
- **Benchmark:** machine-specific A100 timings; NO cross-architecture competitive claim (A100 vs
  H100 timings are NOT a fair head-to-head — different silicon, different run).

## Honesty fences (pre-committed)

- This is a PORTABILITY replicate: it confirms the AGREEMENT + Float64 gate hold on a 2nd
  architecture. It is NOT a new estimand, NOT a covered flip, NOT a competitive H100-vs-A100
  benchmark. `V2-GRM-GPU` stays `partial`; `public_covered_count` UNCHANGED.
- If the A100 Float32 speedup differs from H100's modest ~1.2× (e.g. TF32 engages), that is REPORTED
  honestly as an architecture-dependent measurement, not a headline.
- The claim is empty until the committed Narval run lands its `.tsv` artifacts (Wave F execution
  model). Binaries/generated files git-ignored; only the harnesses (already committed) + sbatch +
  this predeclaration + the ingested `.tsv` are tracked.

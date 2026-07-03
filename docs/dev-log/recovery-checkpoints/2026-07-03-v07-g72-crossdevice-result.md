# v0.7-G-7.2 cross-device GPU agreement replicate (Narval A100) — RESULT (2026-07-03)

The committed Narval run of the SAME committed G-A + G-B harnesses on a 2nd GPU architecture
(NVIDIA A100), confirming the CPU↔GPU agreement + the Float64 gate are architecture-portable.
Predeclaration: `2026-07-03-v07-g72-crossdevice-predeclaration.md`.

- **Run:** Narval SLURM job **64637092**, node ng20202, **NVIDIA A100-SXM4-40GB**, CUDA 13.0 driver /
  CUDA.jl runtime 12.6, Julia 1.10.10, 2026-07-03. Artifacts:
  `sim/drac/results/g_a_narval_64637092.tsv`, `.../g_b_narval_64637092.tsv`,
  `.../v07_g72_narval_64637092.out`.

## G-A device-resident GBLUP — cross-device AGREEMENT (HARD gate) PASSED

| check | maxΔ (A100 vs CPU) |
|---|---|
| β (vanraden1 / vanraden2 / weighted) | 1.4e-15 – 2.7e-15 |
| GEBV (vanraden1 / vanraden2 / weighted) | 3.8e-15 – 4.3e-15 |

`# agreement OK` — the device-resident GBLUP β/GEBV match the CPU pipeline to **~1e-15 on the A100**,
identical in kind to the tamia H100 run (jobs 360583/360589). **The GPU numerical agreement is
architecture-portable (H100 → A100).**

Benchmark (device-resident GBLUP, m=5000, dense O(q³), A100-40GB → q≤16000): **5.9× → 46.7×** (q=2k→16k;
maxΔ holds ≤2e-13 through the benchmark). A machine-specific A100 measurement — NOT a competitive
A100-vs-H100 claim (different silicon, different node/run).

## G-B Float32 — cross-device consistency

- **Float64 gate PASSED:** `precision = Float64` GPU `G` ≡ CPU to **3.0e-15** on the A100.
- **Float32 accuracy:** maxabs `G` ~5e-7–3.5e-6, GEBV impact ~1e-6 (rel L2 ~4–7e-7) — FP32-level,
  the SAME story as H100. `default` and `pedantic_fp32` accuracy columns are IDENTICAL → **TF32 not
  engaged on the A100 default either** (consistent with H100; no TF32-vs-FP32 contrast on either
  architecture).
- **Float32 speedup:** modest ~1.0–1.2× (pedantic), a noisy 3.07× at m=2000 default (warm-up
  artifact) — same modest picture as H100. Float32 remains a minor optimization, not a headline.

## Honest headline + scope

- **The portability question is answered: the CPU↔GPU agreement (device-resident GBLUP ~1e-15,
  Float64 gate ~3e-15) holds on a 2nd GPU architecture (A100).** The GPU path is a
  numerically-portable acceleration, not a one-machine artifact.
- Float32 behaves the same on A100 as H100 (FP32-level, TF32 not engaged, modest speedup).
- `V2-GRM-GPU` stays `partial`; NO covered flip; `public_covered_count` UNCHANGED. GPU =
  acceleration, machine-specific, no competitive/portable-performance claim (agreement IS portable;
  timings are per-machine).
- Owed still: the real-marker-panel benchmark (G-C), the backend dispatcher (G-D), the close-out
  (G-E). A TF32/tensor-core path (larger Float32 speedup) remains unrealized on both architectures.

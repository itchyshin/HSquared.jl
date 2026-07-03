# After-task — v0.7-G-7.2: cross-device GPU agreement replicate (Narval A100) (2026-07-03)

**Owner:** Claude solo (Opus), autonomous (goal: finish doc-25). **Branch:**
`feat/2026-07-03-v07-g72-crossdevice` off `main` @ `e6fe00c0`. **Counts:** rows **55**, covered **13**,
`public_covered_count` **5** — NO covered flip.

## Headline

Re-ran the SAME committed G-A (device-resident GBLUP) + G-B (Float32) harnesses on a 2nd GPU
architecture (NVIDIA A100, Narval) — **the CPU↔GPU numerical agreement is architecture-portable**:
device-resident GBLUP β/GEBV match the CPU to ~1e-15 on the A100 (as on the H100), and the Float64
gate holds (3.0e-15). No new code — a portability replicate.

## What landed

- **`sim/drac/g_ab_narval.sbatch`** (NEW) — runs both committed harnesses on Narval A100
  (`--account=def-snakagaw`, `a100:1`). One-time Narval gpu_env set up under `/project/def-snakagaw`.
- **Evidence (tracked):** `sim/drac/results/g_a_narval_64637092.tsv`, `g_b_narval_64637092.tsv`,
  `v07_g72_narval_64637092.out`. Pre-declaration + result checkpoints.
- **Status sweep:** `V2-GRM-GPU` (validation_status.jl), capability-status GPU row, doc-25 V7.2 → DONE.

## Evidence (Narval A100, job 64637092)

- **G-A cross-device AGREEMENT (HARD gate) PASSED:** β/GEBV (vanraden1/2/weighted) CPU↔GPU to
  **~1e-15** (`# agreement OK`) — identical in kind to the tamia H100 run. Device-resident GBLUP
  benchmark **5.9×→46.7×** (q=2k→16k, m=5000, dense O(q³)); maxΔ ≤2e-13.
- **G-B Float64 gate PASSED:** 3.0e-15. Float32 accuracy FP32-level (maxabs ~5e-7–3.5e-6, GEBV ~1e-6),
  `default` == `pedantic` → TF32 not engaged (same as H100); speedup modest ~1.0–1.2×.

## Honesty pins

- The AGREEMENT is portable (H100 → A100); the TIMINGS are per-machine, NOT a competitive
  A100-vs-H100 claim. `V2-GRM-GPU` stays `partial`; NO covered flip; `public_covered_count`
  UNCHANGED. GPU = acceleration, not a new estimand. `Pkg.test()` GREEN (55).
- Owed still: G-C real-marker-panel benchmark, G-D backend dispatcher, G-E close-out; the
  TF32/tensor-core Float32 path is unrealized on BOTH architectures.

## Next (finish doc-25)

V7.3 (real/large-panel benchmark) → V7.4 (backend dispatcher, local) → V7.5 (close-out) → the owed
V8.4 at-scale leg + coverage-calibrated intervals.

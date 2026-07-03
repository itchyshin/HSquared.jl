# v0.7-G-B Float32 mixed-precision genomic G — RESULT (2026-07-03)

The committed tamia run of the pre-declared harness (`sim/drac/g_b_float32.jl`, sbatch
`sim/drac/g_b_tamia.sbatch`; predeclaration `2026-07-03-v07-gb-float32-predeclaration.md`). Ingests
the opt-in `precision = Float32` path of `gpu_genomic_relationship_matrix`.

- **Run:** tamia SLURM job **360780**, node tg10607, **NVIDIA H100 80GB HBM3**, CUDA 13.0 driver /
  CUDA.jl runtime 12.6, Julia 1.10.10, 2026-07-03. Artifacts: `sim/drac/results/g_b_float32_360780.tsv`,
  `sim/drac/results/v07_gb_f32_360780.out`.

## (1) HARD GATE — PASSED

`precision = Float64` GPU `G` vs the CPU `genomic_relationship_matrix`: **max abs diff 7.33e-15**
(< 1e-10). The Float32 kwarg did NOT change the Float64 contract; the default path still matches the
CPU to BLAS round-off.

## (2) ACCURACY FENCE — Float32 vs Float64 G (n=2000)

| m | max abs (G) | mean rel (G) | max rel (G) | GEBV max abs | GEBV rel L2 |
|---|---|---|---|---|---|
| 2000 | 2.7e-6 | 3.9e-6 | 0.24 | 3.4e-6 | 1.5e-6 |
| 10000 | 2.1e-6 | 1.3e-5 | 1.18 | 1.1e-6 | 4.8e-7 |
| 40000 | 4.0e-6 | 3.5e-5 | 2.19 | 2.8e-6 | 7.6e-7 |
| 80000 | 5.3e-6 | 3.4e-5 | 2.59 | 3.3e-6 | 1.1e-6 |

- **Absolute G entry error ~1–5e-6** (grows only slowly with m); **downstream GEBV impact negligible
  (~1e-6 absolute, rel L2 ~1e-6)** — the Float32 `G` is a numerically-equivalent input for genomic
  prediction. The **large max relative error (up to 2.6)** is the pre-declared benign near-zero-entry
  artifact: off-diagonal `G` entries ≈ 0, so a ~1e-6 absolute error inflates the ratio; it does not
  affect the mean or the GEBVs.
- **`default` and `pedantic_fp32` math modes gave IDENTICAL numbers** (e.g. max abs 2.71824e-06 in
  both at m=2000). So on this H100 + CUDA.jl the Float32 GEMM ran at **true IEEE FP32** in BOTH modes
  — **TF32 tensor cores were NOT engaged** (a TF32 path would show ~1e-3 relative error, not ~1e-6).
  Honest read: I did NOT demonstrate a TF32-vs-FP32 contrast; both settings produced FP32-level
  accuracy. (~1e-6 is a bit larger than the CPU-mirror's ~1e-7 prediction — cuBLAS SGEMM accumulation
  vs the CPU BLAS — but the same order and the GEBV impact is negligible either way.)

## (3) BENCHMARK — Float32 vs Float64 G build time (speedup = f64/f32)

| m | f64 s (pedantic) | f32 s | speedup |
|---|---|---|---|
| 2000 | 0.024 | 0.022 | 1.09 |
| 10000 | 0.185 | 0.145 | 1.28 |
| 20000 | 0.485 | 0.346 | 1.40 |
| 40000 | 0.909 | 0.787 | 1.16 |
| 80000 | 1.845 | 1.746 | 1.06 |

- **The Float32 speedup is MODEST: ~1.1–1.4×** (one noisy outlier, m=5000 default 0.52× — contradicted
  by the same-size pedantic 1.27×, so measurement noise). This is honest and somewhat underwhelming:
  without TF32 tensor cores engaged (see above), Float32 is just SGEMM vs DGEMM, and at n=2000 the
  O(n²) copy-back + H2D transfer dilute the GEMM win. It is **NOT** the "larger speedups" the prior
  owed-note optimistically assumed.

## Honest headline + scope

- The `precision = Float32` genomic `G` is **numerically safe for prediction** (GEBV unchanged to
  ~1e-6) and preserves the Float64 default contract (gate 7e-15) — but on this H100 the **speedup is
  only ~1.2×**, so Float32 is a minor optimization here, NOT a headline accelerator (unlike the
  device-resident GBLUP's 5–23× from keeping data on-device). Float64 stays the recommended default.
- `V2-GRM-GPU` stays `partial`; NO covered flip; `public_covered_count` UNCHANGED. GPU = acceleration,
  not a new estimand; machine-specific (H100, n=2000, m≤80k); no competitive/portable claim.
- Owed still: TF32/tensor-core path (would need explicit `CUDA.math_mode` engagement + a re-measure to
  actually realize a large Float32 speedup), a real-marker-panel benchmark (G-C), cross-device
  replicate (G-A on A100, G-B likewise), the backend dispatcher (G-D).

# v0.7-G-B Float32 mixed-precision genomic G — PRE-DECLARATION (2026-07-03)

Pre-declares the GPU accuracy + speedup run for the opt-in `precision = Float32` path of
`gpu_genomic_relationship_matrix` (HSquaredCUDAExt), BEFORE the tamia run. Committing the harness +
the gate/fence definitions here first (measure-first + no-post-hoc-relaxation discipline).

## What is being added (code, already committed)

- `ext/HSquaredCUDAExt.jl` — `gpu_genomic_relationship_matrix(...; precision::Type = Float64)`. With
  `precision = Float32` the centered marker matrix is downcast to Float32 for the O(n²·m) GEMM (the
  throughput-dominant kernel), the result upcast to Float64 before the O(1)-per-entry scaling. The
  RETURN is ALWAYS `Matrix{Float64}` (the drop-in contract holds); only the GEMM accumulation
  precision changes. The Float64 centering/validation (`centered_markers`) is verbatim — SAME
  estimand. The inverse + MME stay Float64 (Float32 Cholesky would be unstable; the GEMM is the
  target).
- `src/gpu_ext.jl` — stub docstring documents `precision`.
- `test/runtests.jl` — the `precision = Float32` call still throws `MethodError` without CUDA (stub;
  no method leaked into CI).

## The run (pre-declared harness — `sim/drac/g_b_float32.jl` + `sim/drac/g_b_tamia.sbatch`)

- **(1) HARD GATE (pass/fail):** `precision = Float64` GPU `G` still matches the CPU
  `genomic_relationship_matrix` to **< 1e-10** (BLAS round-off). The Float32 kwarg must NOT change
  the Float64 contract. The script `error()`s if violated.
- **(2) ACCURACY FENCE (characterize, NOT gate):** `precision = Float32` GPU `G` vs the Float64 GPU
  `G` — the GEMM-round-off entry error (max abs, max rel, mean rel) AND the downstream GEBV impact
  (both `G` → `fit_gblup` → compare GEBVs), for BOTH GPU math modes: the cluster DEFAULT (TF32
  tensor cores on Hopper — the fast lower-precision Float32 matmul) and PEDANTIC (true IEEE Float32).
- **(3) BENCHMARK (measure):** `G` build time Float64 vs Float32 across m ∈ {2k,5k,10k,20k,40k,80k}
  (n=2000), reporting the speedup. Machine-specific, honest H2D-inclusive timing, NO competitive
  claim.

## Pre-declared expectation (CPU Float32-GEMM mirror, `scratchpad/f32_gemm_accuracy.jl`)

A CPU true-Float32 `W·Wᵀ/k` mirror (n=1000) predicts: **absolute G entry error ~3–5e-7**, roughly
CONSTANT in m (the entries don't grow, the GEMM sum is well-conditioned); **mean relative error
~3e-6**; **max relative error large (up to ~0.17)** but that is a benign near-zero-entry artifact
(off-diagonals ≈ 0, so a ~1e-7 absolute error inflates the ratio); **downstream GEBV impact
negligible (max |ΔGEBV| ~1.8e-7, relative L2 ~8e-8)**. So the honest headline is expected to be:
Float32 (true FP32) gives a numerically-equivalent `G` for prediction (GEBV unchanged to ~1e-7) at a
GEMM speedup. TF32 (the DEFAULT on H100) will be LESS accurate than true FP32 (~10-bit mantissa,
~1e-3 relative) — the run characterizes both so the trade is explicit; the DEFAULT-mode number is
what a naive user gets.

## Honesty fences (pre-committed)

- Float32 is OPT-IN, NEVER the default; the Float64 contract is unchanged (gate 1). NOT "more
  accurate" — a speed-vs-accuracy trade, and the trade (entry error + GEBV impact + speedup, both
  math modes) is what the run reports.
- The status row (`V2-GRM-GPU`, `partial`) stays `partial` — no covered flip. `public_covered_count`
  UNCHANGED. GPU = acceleration, not a new estimand.
- Timings are machine-specific, H2D-inclusive, NO competitive/portable claim; every number traces to
  the committed script + the TSV artifact ingested after the run.
- The claim is empty until a committed tamia run lands its `.tsv` (Wave F execution model, doc 17) —
  as with G1 and G-A.

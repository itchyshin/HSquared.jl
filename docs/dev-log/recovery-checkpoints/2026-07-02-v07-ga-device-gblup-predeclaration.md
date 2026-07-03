# Pre-declaration — v0.7 G-A device-resident GBLUP agreement + benchmark

**Date:** 2026-07-02 · **Lane:** Julia engine (`HSquared.jl`) · **Author:** Claude (solo).
**Predecessor:** Wave-F G1 (GPU VanRaden `G`/`Ginv`, RAN on tamia job 352612, CPU↔GPU ~1e-14).
G-A extends the GPU path from `G`/`Ginv` to the full GBLUP GEBV solve, keeping `G`/`Ginv`/`C`
**on-device across `G → Ginv → MME solve`** (avoiding host round-trips).

## 0. What this is (and is NOT)

`gpu_fit_gblup(y, X, Z, markers, σ²a, σ²e; ridge, method, weights)` (NEW this session, stub in
`src/gpu_ext.jl`, method in `ext/HSquaredCUDAExt.jl`) runs the device-resident genomic BLUP: `G =
W·Wᵀ/k` (GEMM) → `Ginv = inv(G + ridge·I)` (Cholesky + solve) → dense Henderson MME
`C·[β;u]=rhs` solve — all on the device, only markers up + `(β, u)` down. It is a NUMERICAL
ACCELERATION of the CPU pipeline `genomic_relationship_matrix → genomic_relationship_inverse →
fit_gblup`, NOT a new estimand: the marker centering/validation is the validated CPU
`centered_markers` verbatim, and the returned `(beta, breeding_values)` equal the CPU
`fit_gblup` result to floating-point tolerance.

**This is a measurement + a CUDA-numerics agreement gate, not a promotion.** No covered flip. Row
`V2-GRM-GPU` stays `partial` (evidence extended); `validation_status()` count **53 UNCHANGED**;
`public_covered_count` **5**. `σ²a`/`σ²e` are SUPPLIED, not estimated.

## 1. Algorithm already CPU-mirror-validated (de-risk)

Before any GPU run, the device-resident ASSEMBLY (G build → ridge-on-diagonal → Ginv → dense MME
solve) was reproduced on CPU byte-for-byte in assembly order and checked against
`fit_gblup(y, X, Z, genomic_relationship_inverse(genomic_relationship_matrix(markers; method),
ridge), σ²a, σ²e)`: **β err ~1.3e-15, GEBV err ~1.4e-15, GEBV corr 1.0** (q=60, m=200,
`sim/`-shaped markers; scratch validation, 2026-07-02). So the ALGORITHM is correct independent
of CUDA; the GPU run confirms only that CUDA's GEMM/Cholesky/solve numerics agree (which G1
already showed for `G`/`Ginv` at ~1e-14). The CI stub test pins `gpu_fit_gblup` as a method-less
generic function that throws `MethodError` without CUDA (parity with the G1 stubs).

## 2. Fixed experimental design (frozen)

- **Harness:** `sim/drac/g_a_device_gblup.jl`, requires `CUDA.functional()`, OUT of CI, frozen
  byte-identical by the pre-declaration commit `PREDECL`.
- **Data:** deterministic biallelic markers (genotypes {0,1,2}, MAF ∈ (0.05,0.95) so no
  monomorphic column — `:vanraden2` needs polymorphic); deterministic phenotypes; `Z = I`
  (standard GBLUP layout, record = genotyped animal); 2-column fixed-effect design. Seeds fixed.
- **Agreement cell:** q=400, m=2000, ridge=0.01; `:vanraden1`, `:vanraden2`, and weighted VR1 —
  β + GEBV each vs the CPU pipeline.
- **Benchmark grid:** q ∈ {2000, 4000, 8000, 16000, 32000}, m=5000 markers (q = genotyped
  population; end-to-end GBLUP is dense O(q³); q sized to GPU memory). tamia H200-141GB reaches
  the largest q.

## 3. Timing protocol (frozen)

Warm-up discarded (JIT + CUBLAS/CUSOLVER init); `GC.gc()` before each timed call; timings are
**END-TO-END** (G build + ridge inverse + MME solve) including H2D marker transfer + D2H result
transfer — the honest user-visible cost. `Float64` throughout (matches the CPU contract).

## 4. Machine/version manifest

Recorded in the TSV: host, GPU name, CUDA runtime, GPU total memory, `VERSION`. Compute: DRAC GPU
clusters — **tamia** (aip-, H200-141GB, headline) primary; a replicate on a second GPU cluster
(Killarney/Vulcan H100, or Narval A100) for cross-device agreement confidence (see doc-24).

## 5. Pre-declared claims + decision rule

- **A1 (agreement — HARD GATE):** the script errors out unless, on every agreement cell, the
  device-resident β and GEBV match the CPU pipeline to `rtol=1e-6, atol=1e-9`. A clean run ==
  agreement holds. This is the CORRECTNESS gate; it is SEPARATE from timing.
- **B1 (end-to-end speedup — descriptive):** report the CPU-vs-GPU end-to-end GBLUP wall-clock
  ratio per (q, m) on `<GPU>`, tagged machine-specific. State it descriptively (e.g. "device-
  resident GBLUP is X× the CPU end-to-end time at q=… on <GPU>"). No competitive/portable claim;
  timing includes transfer; the speedup grows with q (dense O(q³)).
- **B2 (device-residency framing — mandatory):** the benchmark measures the device-resident path
  end-to-end vs the CPU path end-to-end. The stated benefit of keeping `G`/`Ginv`/`C` on-device
  is the avoided host round-trips of the q×q matrices; this is an ARCHITECTURAL property of the
  implementation, reported alongside the end-to-end number, not measured as an isolated
  transfer-saving figure.

**Forbidden regardless of results:** any "faster than package Y"; any REML-fit claim (this is a
supplied-variance solve); any accuracy claim beyond the CPU-agreement gate; any Float32 claim
(that is G-B, separate); any portable/absolute guarantee. Every timing tagged
**machine-specific measurement on <GPU>**.

## 6. Bank-a-negative clause

If the CPU↔GPU agreement fails (A1), the run HARD-FAILS and NOTHING is banked as agreement — the
mismatch is investigated (it would contradict the CPU-mirror validation, so it would indicate a
CUDA-numerics or an assembly-order bug, not a design flaw). If agreement holds but the GPU is not
faster end-to-end at the tested sizes (small q, transfer-dominated), that is a **BANKED result**:
`V2-GRM-GPU` gains "device-resident GBLUP agrees CPU↔GPU; end-to-end speedup only above q≈<X>",
no speedup overclaim. Harness not modified post-hoc (byte-identity, §2).

## 7. GO / NO-GO

- **GO** to run once: (a) this pre-declaration + `gpu_fit_gblup` stub/method/export + the CI stub
  test + the harness are committed as `PREDECL`; (b) `Pkg.test()` green (count 53, stub test
  passes) — **confirmed green 2026-07-02**; (c) the tamia `gpu_env` depot has HSquared dev'd +
  precompiled at `PREDECL` (the HSquaredCUDAExt extension resolves); (d) `CUDA.functional()` on
  the node (the sbatch fails fast otherwise).
- After the run: write the post-run checkpoint with the manifest, the agreement maxΔ, the
  end-to-end speedup table, and the decision per §5/§6; then a real Rose audit before any status
  edit.

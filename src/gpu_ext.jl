# GPU execution entry points. The METHODS live in the `HSquaredCUDAExt` package
# extension (`ext/HSquaredCUDAExt.jl`), which loads only when `CUDA` (i.e.
# `using CUDA`) is in scope — so `/src` stays GPU-dependency-free and CI never
# touches a GPU (cost discipline; the same posture as `HSquaredMakieExt`). These
# are stubs + the GPU contract only; no GPU work happens in `/src`.
#
# Wave F, Track B (genomic GPU): `docs/design/17-wave-F-foundation-and-genomic-gpu.md`.

"""
    gpu_genomic_relationship_matrix(markers; allele_frequencies = nothing,
                                    method = :vanraden1, weights = nothing,
                                    precision = Float64)

GPU-accelerated VanRaden genomic relationship matrix `G` — the device twin of
[`genomic_relationship_matrix`](@ref). **STUB:** the method is provided by the
`HSquaredCUDAExt` package extension, which activates only when CUDA is loaded
(`using CUDA`). Without a CUDA backend in scope, calling this throws a
`MethodError` asking you to load CUDA.

It is a NUMERICAL ACCELERATION, not a new estimand: it reuses the validated CPU
centering and validation (`centered_markers`) verbatim — same allele frequencies,
same VanRaden scale `k`, same input guards — and runs only the dense `W·Wᵀ / k`
GEMM (and the `:vanraden2` / weighted variants) on the device, returning a CPU
`Matrix{Float64}` identical (to floating-point tolerance) to the CPU result. The
accepted keywords match [`genomic_relationship_matrix`](@ref) exactly, plus
`precision`.

`precision = Float64` (default) runs the GEMM in Float64 and matches the CPU result
to BLAS round-off. `precision = Float32` (v0.7-G-B) is an OPT-IN mixed-precision
path: the centered marker matrix is downcast to Float32 for the O(n²·m) GEMM (where
H100 Float32/TF32 throughput dominates) and the result is upcast to Float64 before
the scaling — so the return is ALWAYS `Matrix{Float64}` (the drop-in contract
holds), only the GEMM accumulation precision changes. Float32 is a speed-vs-accuracy
trade: the Float32 `G` differs from the Float64 `G` by the GEMM round-off (absolute
error ~Float32-eps scale, characterized on-device), NOT more accurate and NOT the
default. The CPU↔GPU agreement test and the Float32 accuracy + speedup benchmark are
opt-in cluster scripts (`sim/drac/g1_gpu_genomic.jl`, `sim/drac/g_b_float32.jl`), run
on a CUDA device — never in CI. No performance or agreement claim holds until a
committed run lands its artifact (Wave F execution model, doc 17).
"""
function gpu_genomic_relationship_matrix end

"""
    gpu_genomic_relationship_inverse(G; ridge = 0.01)

GPU-accelerated regularized inverse of a genomic relationship matrix `G` — the
device twin of [`genomic_relationship_inverse`](@ref). **STUB:** the method is
provided by the `HSquaredCUDAExt` package extension (loads on `using CUDA`);
without a CUDA backend in scope this throws a `MethodError`.

Mirrors the CPU contract exactly: forms `regularized = G + ridge·I`, runs the
dense Cholesky factorization + inverse on the device (CUSOLVER), and returns a CPU
`Matrix{Float64}` equal (to tolerance) to `inv(Symmetric(G + ridge·I))`. A non
positive-definite regularized `G` throws the same `ArgumentError` as the CPU twin
("increase ridge"). Float64 throughout; agreement/benchmark are opt-in cluster
scripts (see [`gpu_genomic_relationship_matrix`](@ref)), never CI.
"""
function gpu_genomic_relationship_inverse end

"""
    gpu_fit_gblup(y, X, Z, markers, sigma_a2, sigma_e2; ridge = 0.01,
                  method = :vanraden1, allele_frequencies = nothing, weights = nothing)

DEVICE-RESIDENT genomic BLUP (GBLUP) at supplied variance components — the GPU twin
of the CPU pipeline [`genomic_relationship_matrix`](@ref) →
[`genomic_relationship_inverse`](@ref) → [`fit_gblup`](@ref), run **end-to-end on
the device** (v0.7 slice G-A). **STUB:** the method is provided by the
`HSquaredCUDAExt` package extension (loads on `using CUDA`); without a CUDA backend
in scope this throws a `MethodError`.

The genomic relationship `G = W·Wᵀ/k` (GEMM), its ridge-regularized inverse
`Ginv = inv(G + ridge·I)` (Cholesky + solve), and the dense Henderson mixed-model
equations `C·[β; u] = rhs`
(`C = [[X'X/σe²  X'Z/σe²]; [Z'X/σe²  Z'Z/σe² + Ginv/σa²]]`) are built and solved on
the device, keeping the `q×q` matrices `G`/`Ginv`/`C` ON-DEVICE across all three
stages — only the marker matrix goes up and the fixed effects `β` + genomic
breeding values `u` come back. This is a NUMERICAL ACCELERATION of the CPU GBLUP,
NOT a new estimand: the marker centering/validation is the validated CPU
[`centered_markers`](@ref) verbatim (same `p`, `k`, guards), and the returned
`(beta, breeding_values)` equal (to floating-point tolerance) the CPU
`fit_gblup(y, X, Z, genomic_relationship_inverse(genomic_relationship_matrix(markers;
method), ridge), sigma_a2, sigma_e2)`. `sigma_a2`/`sigma_e2` are SUPPLIED, not
estimated. Float64 throughout.

Returns a `NamedTuple` `(beta, breeding_values = (ids, values), converged)`. The
CPU↔GPU agreement test and the end-to-end benchmark are opt-in cluster scripts
(`sim/drac/g_a_device_gblup.jl`), run on a CUDA device — never in CI. No
performance or agreement claim holds until a committed run lands its artifact.
"""
function gpu_fit_gblup end

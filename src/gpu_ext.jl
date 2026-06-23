# GPU execution entry points. The METHODS live in the `HSquaredCUDAExt` package
# extension (`ext/HSquaredCUDAExt.jl`), which loads only when `CUDA` (i.e.
# `using CUDA`) is in scope — so `/src` stays GPU-dependency-free and CI never
# touches a GPU (cost discipline; the same posture as `HSquaredMakieExt`). These
# are stubs + the GPU contract only; no GPU work happens in `/src`.
#
# Wave F, Track B (genomic GPU): `docs/design/17-wave-F-foundation-and-genomic-gpu.md`.

"""
    gpu_genomic_relationship_matrix(markers; allele_frequencies = nothing,
                                    method = :vanraden1, weights = nothing)

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
accepted keywords match [`genomic_relationship_matrix`](@ref) exactly.

Float64 throughout (matches the CPU contract). The CPU↔GPU agreement test and the
GPU benchmark are opt-in cluster scripts (`sim/drac/g1_gpu_genomic.jl`), run on a
CUDA device — never in CI. No performance or agreement claim holds until a
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

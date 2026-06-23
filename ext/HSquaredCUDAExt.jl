module HSquaredCUDAExt

# CUDA execution extension for HSquared's genomic relationship ops (Wave F, Track B, G1).
# Loads only when CUDA is in scope (`using CUDA`), so `/src` stays GPU-dependency-free and
# CI never touches a GPU (cost discipline — the same posture as `HSquaredMakieExt`). Plan:
# `docs/design/17-wave-F-foundation-and-genomic-gpu.md`.
#
# These methods are a NUMERICAL ACCELERATION of the CPU twins
# (`genomic_relationship_matrix` / `genomic_relationship_inverse`), NOT a new estimand: the
# centering/validation is the validated CPU `centered_markers` verbatim (same allele
# frequencies, same VanRaden scale `k`, same guards); only the dense `W·Wᵀ/k` GEMM and the
# ridge-regularized Cholesky inverse run on the device. The result is copied back to a CPU
# `Matrix{Float64}`, so it is a drop-in for the CPU result and a CPU↔GPU check is a direct
# `≈`. Float64 throughout (matches the CPU contract); agreement is to BLAS round-off, not
# bit-exact.

using HSquared
using CUDA
using LinearAlgebra
import HSquared: gpu_genomic_relationship_matrix, gpu_genomic_relationship_inverse

function gpu_genomic_relationship_matrix(
    markers::AbstractMatrix;
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
    method::Symbol = :vanraden1,
    weights::Union{Nothing,AbstractVector} = nothing,
)
    CUDA.functional() || throw(
        ErrorException(
            "gpu_genomic_relationship_matrix requires a functional CUDA GPU (CUDA.functional() == false)",
        ),
    )
    # Reuse the CPU centering + validation verbatim: identical p, k, and input guards, so
    # the device result is the SAME estimand. Only the GEMM below runs on the GPU.
    cm = HSquared.centered_markers(markers; allele_frequencies = allele_frequencies)
    Wd = CuArray(cm.W)
    if weights !== nothing
        method === :vanraden1 || throw(
            ArgumentError("per-marker weights are supported with method = :vanraden1 only"),
        )
        length(weights) == size(cm.W, 2) ||
            throw(ArgumentError("weights must have one entry per marker"))
        all(>=(0), weights) || throw(ArgumentError("weights must be non-negative"))
        w = Float64.(weights)
        scale = sum(w .* 2 .* cm.p .* (1 .- cm.p))
        scale > 0 || throw(ArgumentError("weighted genomic scaling is zero"))
        # W·diag(w)·Wᵀ = (W .* wᵀ)·Wᵀ — a column scale (broadcast, device-friendly) + GEMM,
        # algebraically identical to the CPU `W * Diagonal(w) * transpose(W)`.
        Gd = ((Wd .* CuArray(reshape(w, 1, :))) * Wd') ./ scale
        return Matrix{Float64}(Array(Gd))
    elseif method === :vanraden1
        Gd = (Wd * Wd') ./ cm.k
        return Matrix{Float64}(Array(Gd))
    elseif method === :vanraden2
        scale = 2 .* cm.p .* (1 .- cm.p)
        all(>(0), scale) || throw(
            ArgumentError(
                "method = :vanraden2 requires every marker polymorphic (0 < p < 1); a monomorphic marker cannot be standardized",
            ),
        )
        # Standardize columns on the device (W ./ sqrt(scale)ᵀ), then GEMM / m — the same
        # column scaling the CPU path applies.
        sd = CuArray(reshape(sqrt.(scale), 1, :))
        Zsd = Wd ./ sd
        Gd = (Zsd * Zsd') ./ size(cm.W, 2)
        return Matrix{Float64}(Array(Gd))
    else
        throw(ArgumentError("method must be :vanraden1 or :vanraden2"))
    end
end

function gpu_genomic_relationship_inverse(G::AbstractMatrix; ridge::Real = 0.01)
    CUDA.functional() || throw(
        ErrorException(
            "gpu_genomic_relationship_inverse requires a functional CUDA GPU (CUDA.functional() == false)",
        ),
    )
    n = size(G, 1)
    size(G, 2) == n || throw(ArgumentError("G must be square"))
    ridge >= 0 || throw(ArgumentError("ridge must be non-negative"))
    # Form the ridge-regularized matrix on the CPU (O(n²), negligible) so it is exactly the
    # CPU twin's `Matrix{Float64}(G) + ridge*I`, then move the dense O(n³) factorization +
    # inverse to the GPU. (Adding `ridge*I` to a CuMatrix would force disallowed scalar
    # indexing on the diagonal.)
    regularized = Matrix{Float64}(G) + ridge * I
    Rd = CuArray(regularized)
    # Cholesky on the device (CUSOLVER) is both the PD check and the factorization. A non-PD
    # regularized G throws PosDefException → rethrow the SAME ArgumentError the CPU twin
    # raises from its `isposdef` guard, so the GPU contract matches the CPU contract.
    chol = try
        cholesky(Hermitian(Rd))
    catch err
        err isa LinearAlgebra.PosDefException &&
            throw(ArgumentError("regularized G is not positive definite; increase ridge"))
        rethrow(err)
    end
    Ginv_d = chol \ CuArray(Matrix{Float64}(I, n, n))   # CUSOLVER solve against the identity
    return Matrix{Float64}(Array(Ginv_d))
end

end # module

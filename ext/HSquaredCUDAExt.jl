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
using SparseArrays
import HSquared: gpu_genomic_relationship_matrix, gpu_genomic_relationship_inverse, gpu_fit_gblup

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

# Build `G = W·Wᵀ/k` on the device and KEEP it there (the device twin of the CPU
# `genomic_relationship_matrix`, returning the CuArray rather than copying back). Reuses the
# validated CPU `centered_markers` verbatim, so the device `G` is the SAME estimand.
function _device_G(markers; allele_frequencies, method, weights)
    cm = HSquared.centered_markers(markers; allele_frequencies = allele_frequencies)
    Wd = CuArray(cm.W)
    if weights !== nothing
        method === :vanraden1 ||
            throw(ArgumentError("per-marker weights are supported with method = :vanraden1 only"))
        length(weights) == size(cm.W, 2) ||
            throw(ArgumentError("weights must have one entry per marker"))
        all(>=(0), weights) || throw(ArgumentError("weights must be non-negative"))
        w = Float64.(weights)
        scale = sum(w .* 2 .* cm.p .* (1 .- cm.p))
        scale > 0 || throw(ArgumentError("weighted genomic scaling is zero"))
        return ((Wd .* CuArray(reshape(w, 1, :))) * Wd') ./ scale
    elseif method === :vanraden1
        return (Wd * Wd') ./ cm.k
    elseif method === :vanraden2
        scale = 2 .* cm.p .* (1 .- cm.p)
        all(>(0), scale) ||
            throw(ArgumentError("method = :vanraden2 requires every marker polymorphic (0 < p < 1)"))
        Zsd = Wd ./ CuArray(reshape(sqrt.(scale), 1, :))
        return (Zsd * Zsd') ./ size(cm.W, 2)
    else
        throw(ArgumentError("method must be :vanraden1 or :vanraden2"))
    end
end

function gpu_fit_gblup(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    markers::AbstractMatrix,
    sigma_a2::Real,
    sigma_e2::Real;
    ridge::Real = 0.01,
    method::Symbol = :vanraden1,
    allele_frequencies::Union{Nothing,AbstractVector} = nothing,
    weights::Union{Nothing,AbstractVector} = nothing,
    ids = nothing,
)
    CUDA.functional() || throw(
        ErrorException("gpu_fit_gblup requires a functional CUDA GPU (CUDA.functional() == false)"),
    )
    sigma_a2 > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    ridge >= 0 || throw(ArgumentError("ridge must be non-negative"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Z, 1) == n || throw(ArgumentError("Z must have one row per record"))
    q = size(Z, 2)
    q == size(markers, 1) ||
        throw(ArgumentError("Z columns ($q) must match the number of genotyped individuals (rows of `markers`, $(size(markers, 1)))"))
    p = size(X, 2)
    p < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    # STAGE 1: G on device (GEMM). STAGE 2: ridge-regularized inverse on device (Cholesky +
    # solve). The ridge is added to the diagonal by a VECTORIZED range-index broadcast
    # (`diagind` linear indices) — no per-element scalar indexing, no host round-trip.
    Gd = _device_G(markers; allele_frequencies = allele_frequencies, method = method, weights = weights)
    size(Gd, 1) == q ||
        throw(ArgumentError("genomic relationship dimension $(size(Gd, 1)) must match Z columns $q"))
    Rd = copy(Gd)
    Rd[diagind(Rd)] .+= Float64(ridge)
    cholG = try
        cholesky(Hermitian(Rd))
    catch err
        err isa LinearAlgebra.PosDefException &&
            throw(ArgumentError("regularized G is not positive definite; increase ridge"))
        rethrow(err)
    end
    Ginv_d = cholG \ CuArray(Matrix{Float64}(I, q, q))

    # STAGE 3: assemble the dense Henderson MME on the device and solve — G/Ginv/C never leave
    # the device between stages. C = [[X'X/σe²  X'Z/σe²]; [Z'X/σe²  Z'Z/σe² + Ginv/σa²]].
    Xd = CuArray(Matrix{Float64}(X))
    Zd = CuArray(Matrix{Float64}(Z))
    yd = CuArray(Vector{Float64}(y))
    rp = inv(Float64(sigma_e2))
    ra = inv(Float64(sigma_a2))
    XtX = rp .* (Xd' * Xd)
    XtZ = rp .* (Xd' * Zd)
    ZtZ = rp .* (Zd' * Zd) .+ ra .* Ginv_d
    Cd = [XtX XtZ; XtZ' ZtZ]
    rhs = vcat(rp .* (Xd' * yd), rp .* (Zd' * yd))
    sol = cholesky(Hermitian(Cd)) \ rhs
    solh = Vector{Float64}(Array(sol))

    beta = solh[1:p]
    u = solh[(p + 1):(p + q)]
    idvec = ids === nothing ? collect(1:q) : collect(ids)
    length(idvec) == q || throw(ArgumentError("ids length must match the number of genotyped individuals ($q)"))
    return (beta = beta, breeding_values = (ids = idvec, values = u), converged = true)
end

end # module

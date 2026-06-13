# Takahashi selected inverse for sparse positive-definite matrices.
#
# PROVENANCE
# ----------
# Adapted (near-verbatim) from the MIT-licensed sibling package DRM.jl
# (`DRM.jl/src/takahashi_selinv.jl`, Copyright 2026 Shinichi Nakagawa), reused
# here under the MIT License with attribution. HSquared.jl uses it to compute
# the diagonal of the Henderson mixed-model-equation coefficient-matrix inverse
# `C⁻¹` for per-animal prediction error variance (PEV) and reliability.
#
# WHY
# ---
# PEV is `diag` of `C⁻¹` for the random-effect equations. Forming `C⁻¹` densely
# costs O(p³); the Takahashi (1973) / Erisman–Tinney (1975) recursion gives the
# entries of `C⁻¹` at the sparsity pattern of `L + Lᵀ` in `O(nnz(L))`.
#
# IMPORTANT CAVEAT (read before using)
# ------------------------------------
# The selected inverse is EXACT only at entries in the `L + Lᵀ` sparsity
# pattern. Entries of `C⁻¹` outside that pattern are NOT zero in general and are
# NOT computed. The DIAGONAL is always in pattern, so PEV (the diagonal) is
# exact; arbitrary off-pattern covariances are not available from this routine.
#
# THE MATH (column-oriented recursion)
# ------------------------------------
# Let `P C Pᵀ = L Lᵀ` (Julia CHOLMOD convention: `C[ch.p, ch.p] == L * Lᵀ`).
# We compute `Z = (P C Pᵀ)⁻¹` at the symmetric `L + Lᵀ` pattern; `C⁻¹` is then
# recovered by `Z[invperm(ch.p), invperm(ch.p)]`. From `Lᵀ Z = L⁻¹`:
#
#   Z[j, r] = -1/L[j, j] · Σ_{k > j, L[k, j] ≠ 0} L[k, j] · Z[k, r]   (r > j)
#   Z[j, j] = 1/L[j, j]² - 1/L[j, j] · Σ_{k > j, L[k, j] ≠ 0} L[k, j] · Z[k, j].

# Binary search for row `i` in column `j` of a CSC sparse matrix; returns the
# nzval index if found, -1 otherwise. CSC row indices are sorted increasing.
@inline function _csc_rowidx(colptr::Vector{Int}, rowval::Vector{Int},
                              j::Int, i::Int)
    lo = colptr[j]; hi = colptr[j + 1] - 1
    @inbounds while lo <= hi
        m = (lo + hi) >>> 1
        rm = rowval[m]
        if rm == i
            return m
        elseif rm < i
            lo = m + 1
        else
            hi = m - 1
        end
    end
    return -1
end

"""
    takahashi_selinv(ch::SparseArrays.CHOLMOD.Factor{Float64}) -> SparseMatrixCSC

Compute the Takahashi selected inverse of the matrix `C` whose sparse Cholesky
factor is `ch` (`P · C · Pᵀ = L · Lᵀ`). Returns a `SparseMatrixCSC` holding
`C⁻¹` (in the ORIGINAL un-permuted ordering) at the union sparsity of
`Pᵀ (L + Lᵀ) P`. Entries outside that pattern are NOT computed (and are NOT zero
in general). Adapted from DRM.jl (MIT).
"""
function takahashi_selinv(ch::SparseArrays.CHOLMOD.Factor{Float64})
    L = sparse(ch.L)
    perm = ch.p
    n = size(L, 1)
    colptr = L.colptr
    rowval = L.rowval
    Lvals = L.nzval

    Zvals = zeros(Float64, length(Lvals))

    @inbounds for j in n:-1:1
        cs = colptr[j]; ce = colptr[j + 1] - 1
        Ljj = Lvals[cs]
        invLjj = 1.0 / Ljj

        for off_r in ce:-1:(cs + 1)
            r = rowval[off_r]
            s = 0.0
            for off_k in (cs + 1):ce
                k = rowval[off_k]
                Lkj = Lvals[off_k]
                if k == r
                    z_kr = Zvals[colptr[r]]
                elseif k < r
                    idx = _csc_rowidx(colptr, rowval, k, r)
                    z_kr = idx == -1 ? 0.0 : Zvals[idx]
                else
                    idx = _csc_rowidx(colptr, rowval, r, k)
                    z_kr = idx == -1 ? 0.0 : Zvals[idx]
                end
                s += Lkj * z_kr
            end
            Zvals[off_r] = -s * invLjj
        end

        s = 0.0
        for off_k in (cs + 1):ce
            Lkj = Lvals[off_k]
            Z_kj = Zvals[off_k]
            s += Lkj * Z_kj
        end
        Zvals[cs] = invLjj * invLjj - s * invLjj
    end

    nnz_out = 2 * length(Lvals) - n
    I_out = Vector{Int}(undef, nnz_out)
    J_out = Vector{Int}(undef, nnz_out)
    V_out = Vector{Float64}(undef, nnz_out)
    idx = 0
    @inbounds for j in 1:n
        cs = colptr[j]; ce = colptr[j + 1] - 1
        idx += 1
        I_out[idx] = perm[j]; J_out[idx] = perm[j]; V_out[idx] = Zvals[cs]
        for off in (cs + 1):ce
            r = rowval[off]
            v = Zvals[off]
            idx += 1
            I_out[idx] = perm[r]; J_out[idx] = perm[j]; V_out[idx] = v
            idx += 1
            I_out[idx] = perm[j]; J_out[idx] = perm[r]; V_out[idx] = v
        end
    end
    return sparse(I_out, J_out, V_out, n, n)
end

"""
    takahashi_diag(ch::SparseArrays.CHOLMOD.Factor{Float64}) -> Vector{Float64}

Return ONLY `diag(C⁻¹)` (length-n, in the ORIGINAL ordering) via the Takahashi
recursion, in `O(nnz(L))` and without materialising the full sparse output. The
diagonal is always in the `L + Lᵀ` pattern, so it is exact. Adapted from
DRM.jl (MIT).
"""
function takahashi_diag(ch::SparseArrays.CHOLMOD.Factor{Float64})
    L = sparse(ch.L)
    perm = ch.p
    n = size(L, 1)
    colptr = L.colptr
    rowval = L.rowval
    Lvals = L.nzval

    Zvals = zeros(Float64, length(Lvals))

    @inbounds for j in n:-1:1
        cs = colptr[j]; ce = colptr[j + 1] - 1
        Ljj = Lvals[cs]
        invLjj = 1.0 / Ljj

        for off_r in ce:-1:(cs + 1)
            r = rowval[off_r]
            s = 0.0
            for off_k in (cs + 1):ce
                k = rowval[off_k]
                Lkj = Lvals[off_k]
                if k == r
                    z_kr = Zvals[colptr[r]]
                elseif k < r
                    idx = _csc_rowidx(colptr, rowval, k, r)
                    z_kr = idx == -1 ? 0.0 : Zvals[idx]
                else
                    idx = _csc_rowidx(colptr, rowval, r, k)
                    z_kr = idx == -1 ? 0.0 : Zvals[idx]
                end
                s += Lkj * z_kr
            end
            Zvals[off_r] = -s * invLjj
        end

        s = 0.0
        for off_k in (cs + 1):ce
            Lkj = Lvals[off_k]
            Z_kj = Zvals[off_k]
            s += Lkj * Z_kj
        end
        Zvals[cs] = invLjj * invLjj - s * invLjj
    end

    d = Vector{Float64}(undef, n)
    @inbounds for j in 1:n
        d[perm[j]] = Zvals[colptr[j]]
    end
    return d
end

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
# entries of `C⁻¹` at the sparsity pattern of `L + Lᵀ` WITHOUT ever forming the
# dense inverse — a real memory saving. Its own FLOP cost is NOT `O(nnz(L))`:
# the column recursion below (`_selinv_zvals`) is `Θ(Σⱼ |L[:,j]|²)`, the same
# order as the Cholesky factorization itself, not linear in `nnz(L)`. That
# `O(nnz(L))` figure was an unevidenced claim in this file until it was measured
# (Karpinski review, 2026-09); keep this comment in sync with the actual
# inner-loop structure.
#
# The `Θ(Σⱼ|L[:,j]|²)` term is unavoidable for this algorithm, but its CONSTANT
# is not. As first written, each of those pair terms cost a binary search into
# another column — branchy and cache-hostile — which profiling found to be
# ~98.6% of one AI-REML iteration at n=100,000, and 233x-1780x the wall time of
# `cholesky(Symmetric(C))` on the SAME matrix. `6bb10c97` replaced the searches with
# a dense per-clique block, but only for cliques up to 2000 wide (the block is
# `m²` floats); wider cliques kept the searches, and on high-fill pedigrees those are
# most of the work (q=20,000, fill 471: 86.8% of `Σⱼ|L[:,j]|²` sits in cliques wider
# than 2000), so the gain fell from 6.6x-10x at moderate fill to 1.1x at fill 474.
# `_selinv_zvals` now walks each clique member's own column once and SCATTERS both
# symmetric contributions into a length-`m` accumulator: no search, no `m×m` block,
# no width cap, and the same per-entry summation order (see its own comment), so the
# output stays BIT-IDENTICAL to the original per-pair recursion.
# Measured on one thread (Mac Studio M1 Ultra), f0adv adversarial pedigrees, full MME,
# bit-identical output, against the capped dense-block kernel (see the check-log):
#   q=5,000  fill 107-151   1.7x-1.8x
#   q=10,000 fill 262       4.2x
#   q=20,000 fill 471       28x   (416.8 s -> 14.9 s per selected-inverse pass)
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

# Shared Takahashi recursion, reused by takahashi_selinv, takahashi_diag, and
# selinv_trace_against. Returns the selected-inverse values `Zvals` aligned to the
# CSC structure of `L = sparse(ch.L)` (permuted ordering; column `j`'s diagonal is
# at `colptr[j]`, off-diagonals at the following nonzero offsets), plus the CSC
# arrays and permutation to map back to the original ordering. Cost is
# `Θ(Σⱼ|L[:,j]|²)` (see the WHY block above), NOT `O(nnz(L))`; the
# `L + Lᵀ` pattern entries are exact regardless of that cost.
function _selinv_zvals(ch::SparseArrays.CHOLMOD.Factor{Float64}; per_pair::Bool = false)
    L = sparse(ch.L)
    perm = ch.p
    n = size(L, 1)
    colptr = L.colptr
    rowval = L.rowval
    Lvals = L.nzval

    Zvals = zeros(Float64, length(Lvals))
    if per_pair
        _selinv_zvals_per_pair!(Zvals, colptr, rowval, Lvals, n)
        return Zvals, colptr, rowval, perm, n
    end

    # PERFORMANCE. Column `j` needs, for each of its clique rows `i_q` (its row pattern
    # below the diagonal, `i_1 < … < i_m`), the sum `s_q = Σ_p L[i_p, j] · Z[i_p, i_q]`
    # over ALL clique members `p`, accumulated in ascending `p`. `Z[i_p, i_q]` with
    # `p < q` is stored in column `i_p` at row `i_q` (entries live at column
    # `min(row, col)`), and by the Cholesky fill-path property every clique row after
    # `i_p` IS in column `i_p`'s pattern. So walk `p = 1…m` once: at step `p`, add the
    # diagonal term to `s_p`, then merge column `i_p`'s rows with the clique tail
    # `i_{p+1}…i_m`; each match `v = Z[i_p, i_q]` contributes `L[i_q, j]·v` to `s_p` and
    # `L[i_p, j]·v` to `s_q`. Every `s_q` therefore receives its terms in exactly
    # ascending `p` — the order of the original per-pair recursion — so the output is
    # BIT-IDENTICAL to it (`test/runtests.jl` pins this). Structurally absent entries
    # (the per-pair path adds `L·0.0`) are skipped: `s + ±0.0 == s` for every `s`
    # reachable here, because an accumulator that starts at `+0.0` can never become
    # `-0.0`. Scratch is one length-`maxm` vector; there is no clique-width cap.
    maxm = 0
    @inbounds for c in 1:n
        mc = colptr[c + 1] - colptr[c] - 1
        mc > maxm && (maxm = mc)
    end
    acc = zeros(Float64, maxm)

    @inbounds for j in n:-1:1
        cs = colptr[j]; ce = colptr[j + 1] - 1
        invLjj = 1.0 / Lvals[cs]
        m = ce - cs

        if m == 0
            Zvals[cs] = invLjj * invLjj
            continue
        end

        for q in 1:m
            acc[q] = 0.0
        end
        for p in 1:m
            ip = rowval[cs + p]
            lp = Lvals[cs + p]
            pcs = colptr[ip]; pce = colptr[ip + 1] - 1
            sp = acc[p] + lp * Zvals[pcs]               # p == q: Z[i_p, i_p]
            ntail = m - p
            if ntail > 0
                if (pce - pcs) <= 11 * ntail
                    # linear merge of two ascending row lists
                    a = pcs + 1
                    q = p + 1
                    while q <= m && a <= pce
                        iq = rowval[cs + q]
                        ra = rowval[a]
                        if ra == iq
                            v = Zvals[a]
                            sp += Lvals[cs + q] * v
                            acc[q] += lp * v
                            a += 1; q += 1
                        elseif ra < iq
                            a += 1
                        else
                            q += 1
                        end
                    end
                else
                    # column i_p is long relative to the tail we want: search per entry
                    for q in (p + 1):m
                        idx = _csc_rowidx(colptr, rowval, ip, rowval[cs + q])
                        if idx != -1
                            v = Zvals[idx]
                            sp += Lvals[cs + q] * v
                            acc[q] += lp * v
                        end
                    end
                end
            end
            acc[p] = sp
        end
        for q in 1:m
            Zvals[cs + q] = -acc[q] * invLjj
        end

        s = 0.0
        for off_k in (cs + 1):ce
            s += Lvals[off_k] * Zvals[off_k]
        end
        Zvals[cs] = invLjj * invLjj - s * invLjj
    end

    return Zvals, colptr, rowval, perm, n
end

# The original per-pair recursion (one binary search per clique pair), kept as the
# bitwise reference `_selinv_zvals(ch; per_pair = true)` that the tests pin the
# scatter path against. Not used on any production path.
function _selinv_zvals_per_pair!(Zvals, colptr, rowval, Lvals, n)
    @inbounds for j in n:-1:1
        cs = colptr[j]; ce = colptr[j + 1] - 1
        invLjj = 1.0 / Lvals[cs]
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
            s += Lvals[off_k] * Zvals[off_k]
        end
        Zvals[cs] = invLjj * invLjj - s * invLjj
    end
    return Zvals
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
    Zvals, colptr, rowval, perm, n = _selinv_zvals(ch)

    nnz_out = 2 * length(Zvals) - n
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
recursion, without materialising the full sparse output (a real memory saving;
the recursion's own FLOP cost is `Θ(Σⱼ|L[:,j]|²)`, comparable to the Cholesky
factorization itself, NOT `O(nnz(L))` — see the file header). The diagonal is
always in the `L + Lᵀ` pattern, so it is exact. Adapted from DRM.jl (MIT).
"""
function takahashi_diag(ch::SparseArrays.CHOLMOD.Factor{Float64})
    Zvals, colptr, _, perm, n = _selinv_zvals(ch)
    d = Vector{Float64}(undef, n)
    @inbounds for j in 1:n
        d[perm[j]] = Zvals[colptr[j]]
    end
    return d
end

"""
    selinv_trace_against(ch, Ainv, nfixed) -> Float64

Accumulate `tr(Ainv · C⁻¹[uu]) = Σ Ainv[i,j] · C⁻¹[nfixed+i, nfixed+j]` over the
nonzeros of the random-effect precision `Ainv`, using the Takahashi selected
inverse of the MME coefficient matrix `C` (factor `ch`) WITHOUT materialising the
full selected-inverse sparse matrix. `Ainv`'s sparsity pattern is a subset of the
random block of `C`, hence of the `L + Lᵀ` pattern, so every entry looked up is
in-pattern (exact). Numerically identical (up to summation order) to
`sum(Ainv .* takahashi_selinv(ch)[(nfixed+1):end, (nfixed+1):end])`, and without
the `O(nnz)` output allocation of materialising that matrix — but this function's
own cost is dominated by `_selinv_zvals`'s `Θ(Σⱼ|L[:,j]|²)` recursion (NOT
`O(nnz(L))`; see the file header), not by the cheap summation loop below. This is
the REML score trace term `tr(A⁻¹ C^uu)` in [`fit_ai_reml`](@ref), called ONCE
PER AI-REML ITERATION, and profiling (Karpinski review, 2026-09) found it to be
the DOMINANT per-iteration cost of `fit_ai_reml` at scale — ≈98.6% of one
iteration's wall time at n=100,000, and 233x-1780x the `cholesky(Symmetric(C))`
factorization it reuses — rather than the sparse assembly or factorization.
`_selinv_zvals`'s clique scatter cut that constant with bit-identical output
(the capped dense-block version of 2026-09-19 took end-to-end `fit_ai_reml` from
56.77 s to 6.87 s at n=8,000; the cap-free scatter removes the clique-width limit that
left high-fill pedigrees on the search path). It remains the largest single term here,
so further work (a blocked/supernodal selected inverse) belongs in `_selinv_zvals`, not
in the summation loop below. Adapted from DRM.jl (MIT).
"""
function selinv_trace_against(ch::SparseArrays.CHOLMOD.Factor{Float64},
                              Ainv::SparseMatrixCSC, nfixed::Integer)
    Zvals, colptr, rowval, perm, n = _selinv_zvals(ch)
    iperm = invperm(perm)            # original index -> permuted index
    rows = rowvals(Ainv)
    vals = nonzeros(Ainv)
    trace = 0.0
    @inbounds for jcol in 1:size(Ainv, 2)
        vp = iperm[nfixed + jcol]
        for k in nzrange(Ainv, jcol)
            up = iperm[nfixed + rows[k]]
            if up == vp
                z = Zvals[colptr[up]]
            else
                lo = up < vp ? up : vp
                hi = up < vp ? vp : up
                idx = _csc_rowidx(colptr, rowval, lo, hi)
                z = idx == -1 ? 0.0 : Zvals[idx]
            end
            trace += vals[k] * z
        end
    end
    return trace
end

"""
    selinv_block_traces(ch, Ainvs, offsets) -> Vector{Float64}

Multi-block generalization of [`selinv_trace_against`](@ref). For each block `b`,
accumulate the REML score trace term `tr(Ainvs[b] · C⁻¹[block_b, block_b]) =
Σ Ainvs[b][i,j] · C⁻¹[offsets[b]+i, offsets[b]+j]`, where block `b` occupies the
contiguous global indices `offsets[b] .+ (1:size(Ainvs[b],1))` in the matrix `C`
whose sparse Cholesky factor is `ch`. `C⁻¹[block_b, block_b]` is the `b`-th diagonal
block of the FULL inverse (it accounts for every other effect jointly), which is
exactly what the K-component REML score for component `b` requires.

Computes the Takahashi selected inverse ONCE (cost `Θ(Σⱼ|L[:,j]|²)`, NOT
`O(nnz(L))`; see the file header) and reuses it across all `K = length(Ainvs)`
blocks, so the whole score-trace sweep pays that dominant cost once rather than
`K` times. Each `Ainvs[b]` pattern is a subset of `C`'s block-`b`
diagonal block, hence of the `L + Lᵀ` pattern, so every entry looked up is
in-pattern (exact). This is the `[tr(A₁⁻¹ C^{u₁u₁}), …, tr(A_K⁻¹ C^{u_Ku_K})]`
vector used by [`fit_sparse_multi_effect_aireml`](@ref).
"""
function selinv_block_traces(ch::SparseArrays.CHOLMOD.Factor{Float64},
                             Ainvs::AbstractVector, offsets::AbstractVector)
    length(Ainvs) == length(offsets) ||
        throw(ArgumentError("Ainvs and offsets must have the same length"))
    Zvals, colptr, rowval, perm, _ = _selinv_zvals(ch)
    iperm = invperm(perm)            # original index -> permuted index
    K = length(Ainvs)
    traces = zeros(Float64, K)
    @inbounds for b in 1:K
        Ainv = Ainvs[b]
        off = offsets[b]
        rows = rowvals(Ainv)
        vals = nonzeros(Ainv)
        t = 0.0
        for jcol in 1:size(Ainv, 2)
            vp = iperm[off + jcol]
            for k in nzrange(Ainv, jcol)
                up = iperm[off + rows[k]]
                if up == vp
                    z = Zvals[colptr[up]]
                else
                    lo = up < vp ? up : vp
                    hi = up < vp ? vp : up
                    idx = _csc_rowidx(colptr, rowval, lo, hi)
                    z = idx == -1 ? 0.0 : Zvals[idx]
                end
                t += vals[k] * z
            end
        end
        traces[b] = t
    end
    return traces
end

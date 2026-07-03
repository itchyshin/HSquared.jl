# Iterative (conjugate-gradient) solve of the animal-model MME — the ITERATIVE companion
# of the direct `henderson_mme` factorization. PCG solves the IDENTICAL sparse SPD system
# `C·[β; u] = rhs` (from `_sparse_mme_system`) without forming a Cholesky factor; it is the
# algorithmic primitive the production large-pedigree path needs. Correctness-validated
# (matches the direct solve to a tight tolerance); NOT a production-scale performance claim.

# Preconditioned conjugate gradient for a symmetric positive-definite operator. `applyC`
# is a callable `v ↦ C·v` (a matrix's `*`, or a matrix-free operator). `applyMinv` is a
# callable `r ↦ M⁻¹·r` (the preconditioner solve): `identity` for plain CG, `r ↦ Minv .* r`
# for Jacobi, or the IC(0) back/forward triangular solve for `:ichol`. `x0 = 0`, so the
# initial residual is `b`. Returns `(x, iterations, relative_residual)`.
function _pcg_solve(applyC, b::Vector{Float64}; tol::Float64, maxiter::Int, applyMinv)
    x = zeros(length(b))
    r = copy(b)
    bnorm = norm(b)
    bnorm == 0 && return x, 0, 0.0
    z = applyMinv(r)
    p = copy(z)
    rz = dot(r, z)
    iters = 0
    relres = norm(r) / bnorm
    for k in 1:maxiter
        Cp = applyC(p)
        pCp = dot(p, Cp)
        pCp > 0 ||
            throw(ArgumentError("PCG hit non-positive curvature (pᵀCp = $(pCp)); the system is not positive definite"))
        alpha = rz / pCp
        @. x += alpha * p
        @. r -= alpha * Cp
        iters = k
        relres = norm(r) / bnorm
        relres <= tol && break
        z = applyMinv(r)
        rz_new = dot(r, z)
        beta = rz_new / rz
        @. p = z + beta * p
        rz = rz_new
    end
    # Report the TRUE residual at the returned x (one extra matvec), not the
    # recursively-accumulated `r` — so `relative_residual`/`converged` are exactly
    # ‖b − Cx‖/‖b‖ regardless of any recursive-residual drift on ill-conditioned input.
    relres = norm(b - applyC(x)) / bnorm
    return x, iters, relres
end

# Incomplete Cholesky IC(0): the lower factor `L` with the SAME sparsity pattern as
# `tril(A)` such that `L·Lᵀ ≈ A`, computed by right-looking Cholesky that DROPS any fill
# outside that pattern. Returns `L` (lower-triangular `SparseMatrixCSC`), or `nothing` on a
# non-positive pivot (breakdown) so the caller can retry with a diagonal shift. `A` must be
# SPD with every diagonal entry stored (true for the Henderson MME coefficient matrix). A
# cheaper, often stronger preconditioner than Jacobi for the sparse MME.
function _ichol0_factor(A::SparseMatrixCSC{Float64})
    L = copy(tril(A))
    n = size(L, 1)
    cp, rv, nz = L.colptr, L.rowval, L.nzval
    rowpos = zeros(Int, n)                                # row → position-in-column-j map
    for j in 1:n
        d = cp[j]
        (d < cp[j + 1] && rv[d] == j) ||
            throw(ArgumentError("IC(0): missing stored diagonal at column $j"))
        nz[d] > 0 || return nothing                       # non-positive pivot → breakdown
        Ljj = sqrt(nz[d]); nz[d] = Ljj
        for q in (d + 1):(cp[j + 1] - 1)                  # scale + index column j's sub-diagonal
            nz[q] /= Ljj
            rowpos[rv[q]] = q
        end
        for q in (d + 1):(cp[j + 1] - 1)                  # right-looking rank-1 update,
            k = rv[q]; Lkj = nz[q]                         # restricted to the existing pattern
            for t in cp[k]:(cp[k + 1] - 1)
                rp = rowpos[rv[t]]
                rp == 0 || (nz[t] -= nz[rp] * Lkj)
            end
        end
        for q in (d + 1):(cp[j + 1] - 1)                  # clear the map for the next column
            rowpos[rv[q]] = 0
        end
    end
    return L
end

# Matrix-free apply of the animal-model MME coefficient matrix `C·v` WITHOUT forming `C`:
#   C = [[X'X/σe²  X'Z/σe²]; [Z'X/σe²  Z'Z/σe² + Ainv/σa²]]
# so with v = [v_β; v_u], `common = X·v_β + Z·v_u` and
#   top    = X'·common / σe²
#   bottom = Z'·common / σe² + Ainv·v_u / σa²
# Only sparse `X`, `Z`, `Ainv` matvecs (O(nnz)); no `C` assembly.
function _mme_matvec(X, Xt, Z, Zt, Ainv, inv_se2::Float64, inv_sa2::Float64, p::Int, v::Vector{Float64})
    vbeta = view(v, 1:p)
    vu = view(v, (p + 1):length(v))
    common = X * vbeta .+ Z * vu
    top = inv_se2 .* (Xt * common)
    bottom = inv_se2 .* (Zt * common) .+ inv_sa2 .* (Ainv * vu)
    return vcat(top, bottom)
end

# Diagonal of the MME coefficient matrix, matrix-free: `diag(X'X)/σe²` for the fixed block
# and `diag(Z'Z)/σe² + diag(Ainv)/σa²` for the random block. Used as the Jacobi
# preconditioner without forming `C`.
function _mme_diag(X, Z, Ainv, inv_se2::Float64, inv_sa2::Float64)
    dX = vec(sum(abs2, X; dims = 1)) .* inv_se2
    dZ = vec(sum(abs2, Z; dims = 1)) .* inv_se2 .+ Vector{Float64}(diag(Ainv)) .* inv_sa2
    return vcat(dX, dZ)
end

"""
    solve_animal_model_pcg(spec, sigma_a2, sigma_e2; tol = 1e-10, maxiter = 1000,
                           preconditioner = :jacobi, matrix_free = false)

Solve the supplied-variance Gaussian animal-model mixed-model equations by
**preconditioned conjugate gradient** — the ITERATIVE companion of the direct
[`henderson_mme`](@ref) factorization. It solves the SAME sparse symmetric
positive-definite system `C·[β; u] = rhs` as `henderson_mme` iteratively, never forming a
Cholesky factor. `preconditioner = :jacobi` (default) uses the diagonal preconditioner
`M⁻¹ = 1/diag(C)`; `:ichol` uses an incomplete-Cholesky IC(0) factor of the assembled `C`
(a stronger, still-sparse preconditioner, with a diagonal-shift fallback on breakdown —
requires `matrix_free = false`); `:none` is plain CG.

`matrix_free = false` (default) assembles `C` once (`_sparse_mme_system`) and applies it.
`matrix_free = true` applies `C·v` directly from the sparse `X`, `Z`, `Ainv` matvecs
(`common = X·v_β + Z·v_u`; `top = X'·common/σe²`; `bottom = Z'·common/σe² + Ainv·v_u/σa²`)
and uses a matrix-free Jacobi diagonal — `C` is NEVER assembled. Both paths return the
SAME solution (validated bit-for-bit close); the matrix-free path removes the `C`-assembly
memory, the foundation for a future large-pedigree solver. Still no performance claim
(no benchmark recorded).

Returns a `NamedTuple`:

  - `beta` — fixed effects (`1:nfixed` of the solution);
  - `breeding_values = (ids, values)` — EBVs (`pedigree.ids` order);
  - `iterations` — CG iterations taken;
  - `relative_residual` — `‖rhs − C·x‖ / ‖rhs‖` at the returned solution;
  - `converged` — whether `relative_residual ≤ tol`;
  - `preconditioner`.

EXPERIMENTAL. This is a CORRECTNESS primitive: it is validated to recover the direct
[`henderson_mme`](@ref) solution (β and EBVs) to a tight tolerance on the tiny,
Mrode9-shaped, and larger validation fixtures, and the Jacobi preconditioner is validated
to reach the same solution (in no more iterations than plain CG). It makes NO
performance / large-pedigree scaling claim — `_sparse_mme_system` still assembles `C`
explicitly — and is not the default fit path. It is the iterative-solver foundation the
production sparse path will build on. `sigma_a2`/`sigma_e2` are SUPPLIED, not estimated.
"""
function solve_animal_model_pcg(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real;
                                tol::Real = 1e-10, maxiter::Integer = 1000,
                                preconditioner::Symbol = :jacobi, matrix_free::Bool = false)
    sigma_a2 > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    tol > 0 || throw(ArgumentError("tol must be positive"))
    maxiter >= 1 || throw(ArgumentError("maxiter must be >= 1"))
    preconditioner in (:jacobi, :none, :ichol) ||
        throw(ArgumentError("preconditioner must be :jacobi, :ichol, or :none"))
    (preconditioner === :ichol && matrix_free) &&
        throw(ArgumentError(":ichol preconditioner requires matrix_free = false (it factorizes the assembled C)"))
    nfixed = size(spec.X, 2)

    if matrix_free
        inv_se2 = inv(Float64(sigma_e2))
        inv_sa2 = inv(Float64(sigma_a2))
        X = sparse(Float64.(spec.X))
        Z = sparse(Float64.(spec.Z))
        Ainv = sparse(Float64.(spec.Ainv))
        Xt = transpose(X)
        Zt = transpose(Z)
        y = Float64.(spec.y)
        rhs = vcat(inv_se2 .* (Xt * y), inv_se2 .* (Zt * y))
        d = _mme_diag(X, Z, Ainv, inv_se2, inv_sa2)
        applyC = v -> _mme_matvec(X, Xt, Z, Zt, Ainv, inv_se2, inv_sa2, nfixed, v)
    else
        lhs, rhs, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)
        d = Vector{Float64}(diag(lhs))
        applyC = v -> lhs * v
    end
    all(>(0), d) ||
        throw(ArgumentError("MME diagonal has a non-positive entry; system is not positive definite"))
    applyMinv = if preconditioner === :jacobi
        invd = 1.0 ./ d
        r -> invd .* r
    elseif preconditioner === :ichol
        # IC(0) of the assembled C (matrix_free = false is enforced above). On a non-positive
        # pivot, retry with an increasing Manteuffel diagonal shift — IC(0)(C + s·I) is still a
        # valid SPD preconditioner for C (it never changes the system PCG solves).
        L = _ichol0_factor(lhs)
        if L === nothing
            base = maximum(d)
            for s in (1e-4, 1e-3, 1e-2, 1e-1, 1.0)
                L = _ichol0_factor(lhs + (s * base) * I)
                L === nothing || break
            end
            L === nothing &&
                throw(ArgumentError(":ichol IC(0) broke down even with a diagonal shift; use :jacobi"))
        end
        Lt = sparse(transpose(L))
        r -> UpperTriangular(Lt) \ (LowerTriangular(L) \ r)
    else
        identity
    end

    x, iters, relres = _pcg_solve(applyC, Vector{Float64}(rhs);
                                  tol = Float64(tol), maxiter = Int(maxiter), applyMinv = applyMinv)
    return (
        beta = Vector{Float64}(x[1:nfixed]),
        breeding_values = (ids = collect(spec.ids), values = Vector{Float64}(x[(nfixed + 1):end])),
        iterations = iters,
        relative_residual = relres,
        converged = relres <= tol,
        preconditioner = preconditioner,
        matrix_free = matrix_free,
    )
end

# Matrix-free apply of the MULTI-effect MME coefficient matrix `C·v` WITHOUT forming `C`,
# for `K` INDEPENDENT random effects (the coefficient matrix of `_sparse_multi_lhs_rhs`):
#   C = [[X'X/σe²      X'Z/σe²                        ];
#        [Z'X/σe²      Z'Z/σe² + blockdiag(Aᵢ⁻¹/σᵢ²)  ]],   Z = hcat(Zᵢ).
# With v = [v_β; v_{u₁}; …; v_{u_K}], `common = X·v_β + Σᵢ Zᵢ·v_{uᵢ}` (a single record-space
# vector shared by every block) and
#   top     = X'·common / σe²
#   bottomᵢ = Zᵢ'·common / σe² + Aᵢ⁻¹·v_{uᵢ} / σᵢ².
# Only the sparse per-block `X`, `Zᵢ`, `Aᵢ⁻¹` matvecs (O(Σnnz)); `C` is NEVER assembled — so
# the quadratic Cholesky fill-in of the environmental-group columns (the Phase 5 K≥2 scale
# wall) is bypassed entirely. `offs[i]` is the global offset of block `i` in `[β; u]`.
function _multi_mme_matvec(X, Xt, Zs, Zts, Ainvs, inv_se2::Float64,
                           inv_sigmas::Vector{Float64}, p::Int, offs::Vector{Int}, qs::Vector{Int},
                           v::Vector{Float64})
    common = X * view(v, 1:p)
    @inbounds for i in eachindex(Zs)
        common .+= Zs[i] * view(v, (offs[i] + 1):(offs[i] + qs[i]))
    end
    out = Vector{Float64}(undef, length(v))
    out[1:p] .= inv_se2 .* (Xt * common)
    @inbounds for i in eachindex(Zs)
        rng = (offs[i] + 1):(offs[i] + qs[i])
        out[rng] .= inv_se2 .* (Zts[i] * common) .+ inv_sigmas[i] .* (Ainvs[i] * view(v, rng))
    end
    return out
end

# Diagonal of the multi-effect MME coefficient matrix, matrix-free: `diag(X'X)/σe²` for the
# fixed block and `diag(Zᵢ'Zᵢ)/σe² + diag(Aᵢ⁻¹)/σᵢ²` for each random block. Jacobi
# preconditioner without forming `C`.
function _multi_mme_diag(X, Zs, Ainvs, inv_se2::Float64, inv_sigmas::Vector{Float64},
                         p::Int, offs::Vector{Int}, qs::Vector{Int}, ntot::Int)
    d = Vector{Float64}(undef, ntot)
    d[1:p] .= inv_se2 .* vec(sum(abs2, X; dims = 1))
    @inbounds for i in eachindex(Zs)
        rng = (offs[i] + 1):(offs[i] + qs[i])
        d[rng] .= inv_se2 .* vec(sum(abs2, Zs[i]; dims = 1)) .+
                  inv_sigmas[i] .* Vector{Float64}(diag(Ainvs[i]))
    end
    return d
end

"""
    solve_multi_effect_pcg(y, X, effects, sigmas, sigma_e2; tol = 1e-10, maxiter = 1000,
                           preconditioner = :jacobi, matrix_free = true, ids = nothing)

Solve the supplied-variance `K`-INDEPENDENT-random-effect mixed-model equations by
**preconditioned conjugate gradient**, matrix-free — the multi-effect generalization of
[`solve_animal_model_pcg`](@ref) and the ITERATIVE companion of the direct multi-effect
Cholesky in [`fit_sparse_multi_effect_aireml`](@ref) / [`sparse_multi_reml_loglik`](@ref).
It solves the SAME sparse SPD system `C·[β; u₁; …; u_K] = rhs` as the direct factorization
(the coefficient matrix of `_sparse_multi_lhs_rhs`), never forming `C`.

`effects` is a vector of `(Zᵢ, Aᵢ⁻¹)` pairs (same contract as
[`fit_sparse_multi_effect_aireml`](@ref)); `sigmas` are the `K` SUPPLIED random-effect
variances and `sigma_e2` the SUPPLIED residual variance (this is a supplied-variance SOLVE,
not a REML fit — it does not estimate variance components).

`matrix_free = true` (default) applies `C·v` directly from the per-block sparse `X`, `Zᵢ`,
`Aᵢ⁻¹` matvecs (`common = X·v_β + Σᵢ Zᵢ·v_{uᵢ}`; `top = X'·common/σe²`;
`bottomᵢ = Zᵢ'·common/σe² + Aᵢ⁻¹·v_{uᵢ}/σᵢ²`) with a matrix-free Jacobi diagonal — `C` is
NEVER assembled, so the quadratic Cholesky fill-in of the environmental-group columns (the
Phase 5 K≥2 scale bottleneck) is bypassed. `matrix_free = false` assembles `C` once
(`_sparse_multi_lhs_rhs`) and applies it, enabling `preconditioner = :ichol`; both paths
return the SAME solution.

`preconditioner = :jacobi` (default) uses `M⁻¹ = 1/diag(C)`; `:ichol` (assembled only) an
IC(0) factor with a diagonal-shift fallback; `:none` plain CG.

Returns a `NamedTuple`:

  - `beta` — fixed effects (`1:p` of the solution);
  - `effects` — length-`K` vector of `(ids, values)` per random block, in `[u₁; …; u_K]`
    order (block `i`'s `ids` default to `1:qᵢ`, or the supplied `ids[i]`);
  - `iterations` — CG iterations taken;
  - `relative_residual` — `‖rhs − C·x‖ / ‖rhs‖` at the returned solution;
  - `converged` — whether `relative_residual ≤ tol`;
  - `preconditioner`, `matrix_free`.

EXPERIMENTAL — a CORRECTNESS primitive: validated to recover the direct multi-effect solve
(β and per-block BLUPs) to a tight tolerance. It makes NO performance / large-`q` scaling
claim (no benchmark is asserted here); it is the matrix-free iterative foundation the
production sparse multi-effect path builds on. NOT the default fit path.
"""
function solve_multi_effect_pcg(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector,
    sigmas::AbstractVector,
    sigma_e2::Real;
    tol::Real = 1e-10,
    maxiter::Integer = 1000,
    preconditioner::Symbol = :jacobi,
    matrix_free::Bool = true,
    ids = nothing,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    length(sigmas) == K || throw(ArgumentError("sigmas length must match number of effects"))
    all(s -> s > 0, sigmas) || throw(ArgumentError("all sigmas must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    tol > 0 || throw(ArgumentError("tol must be positive"))
    maxiter >= 1 || throw(ArgumentError("maxiter must be >= 1"))
    preconditioner in (:jacobi, :none, :ichol) ||
        throw(ArgumentError("preconditioner must be :jacobi, :ichol, or :none"))
    (preconditioner === :ichol && matrix_free) &&
        throw(ArgumentError(":ichol preconditioner requires matrix_free = false (it factorizes the assembled C)"))

    n = length(y)
    yv = Float64.(y)
    Xs = sparse(Float64.(X))
    size(Xs, 1) == n || throw(ArgumentError("X must have one row per record"))
    p = size(Xs, 2)
    p < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(Zs, sparse(Float64.(Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        push!(qs, qi)
    end

    if ids === nothing
        eids = [collect(1:qs[i]) for i in 1:K]
    else
        length(ids) == K || throw(ArgumentError("ids must be a length-$K vector of per-effect id vectors"))
        eids = [collect(ids[i]) for i in 1:K]
        for i in 1:K
            length(eids[i]) == qs[i] ||
                throw(ArgumentError("ids[$i] length must match Ainv[$i] dimensions"))
        end
    end

    ss = Float64.(collect(sigmas))
    se2 = Float64(sigma_e2)
    inv_se2 = inv(se2)
    inv_sigmas = inv.(ss)

    offs = Vector{Int}(undef, K)
    acc = p
    for i in 1:K
        offs[i] = acc
        acc += qs[i]
    end
    ntot = acc

    Xt = transpose(Xs)
    Zts = [transpose(Zs[i]) for i in 1:K]
    rhs = Vector{Float64}(undef, ntot)
    rhs[1:p] .= inv_se2 .* (Xt * yv)
    for i in 1:K
        rhs[(offs[i] + 1):(offs[i] + qs[i])] .= inv_se2 .* (Zts[i] * yv)
    end

    if matrix_free
        d = _multi_mme_diag(Xs, Zs, Ainvs, inv_se2, inv_sigmas, p, offs, qs, ntot)
        applyC = v -> _multi_mme_matvec(Xs, Xt, Zs, Zts, Ainvs, inv_se2, inv_sigmas, p, offs, qs, v)
        lhs = nothing
    else
        Zf = reduce(hcat, Zs)
        Zft = transpose(Zf)
        XtX = sparse(Xt * Xs); XtZ = sparse(Xt * Zf)
        ZtX = sparse(Zft * Xs); ZtZ = sparse(Zft * Zf)
        Xty = Vector(Xt * yv); Zty = Vector(Zft * yv)
        lhs, _ = _sparse_multi_lhs_rhs(XtX, XtZ, ZtX, ZtZ, Xty, Zty, Ainvs, ss, se2)
        d = Vector{Float64}(diag(lhs))
        applyC = v -> lhs * v
    end
    all(>(0), d) ||
        throw(ArgumentError("MME diagonal has a non-positive entry; system is not positive definite"))

    applyMinv = if preconditioner === :jacobi
        invd = 1.0 ./ d
        r -> invd .* r
    elseif preconditioner === :ichol
        L = _ichol0_factor(lhs)
        if L === nothing
            base = maximum(d)
            for s in (1e-4, 1e-3, 1e-2, 1e-1, 1.0)
                L = _ichol0_factor(lhs + (s * base) * I)
                L === nothing || break
            end
            L === nothing &&
                throw(ArgumentError(":ichol IC(0) broke down even with a diagonal shift; use :jacobi"))
        end
        Lt = sparse(transpose(L))
        r -> UpperTriangular(Lt) \ (LowerTriangular(L) \ r)
    else
        identity
    end

    x, iters, relres = _pcg_solve(applyC, rhs; tol = Float64(tol), maxiter = Int(maxiter),
                                  applyMinv = applyMinv)
    effects_out = [(ids = eids[i], values = Vector{Float64}(x[(offs[i] + 1):(offs[i] + qs[i])]))
                   for i in 1:K]
    return (
        beta = Vector{Float64}(x[1:p]),
        effects = effects_out,
        iterations = iters,
        relative_residual = relres,
        converged = relres <= tol,
        preconditioner = preconditioner,
        matrix_free = matrix_free,
    )
end

"""
    mc_reml_block_traces(X, effects, sigmas, sigma_e2; nprobe = 64, tol = 1e-9,
                         maxiter = 2000, seed = 0)

MATRIX-FREE stochastic (Hutchinson) estimator of the `K` REML score-trace terms
`tr(Aᵢ⁻¹·C⁻¹[uᵢ,uᵢ])` of the `K`-INDEPENDENT-effect mixed-model equations — the building
block for a matrix-free Monte-Carlo REML FIT (v0.8-S2 follow-on) at `q → 10⁶`, where the
EXACT `selinv_block_traces` (a Takahashi selected inverse of the sparse Cholesky
factor, used by [`fit_sparse_multi_effect_aireml`](@ref)) is factorization-limited by the
K≥2 environmental-group Cholesky fill-in.

`effects` is the vector of `(Zᵢ, Aᵢ⁻¹)` pairs; `sigmas`/`sigma_e2` are the SUPPLIED variance
components at which the trace is evaluated (the same `C` as `solve_multi_effect_pcg`). For
each block `b`: draw Rademacher probes `z ∈ {±1}^{qᵦ}`, embed into the full `[β; u]` space,
solve `C·x = ẑ` MATRIX-FREE (the `solve_multi_effect_pcg` operator — `C` is never assembled
or factorized), extract the `b`-block `xᵦ = C⁻¹[uᵦ,uᵦ]·z`, and accumulate the probe sample
`zᵀ·Aᵦ⁻¹·xᵦ`. Since `E[z zᵀ] = I`, the probe MEAN is an UNBIASED estimate of the trace
(`E[zᵀ M z] = tr(M)`, `M = Aᵦ⁻¹C⁻¹[uᵦ,uᵦ]`).

Returns `(traces, mcse)` — each a length-`K` vector: the trace estimate and its Monte-Carlo
standard error (probe SD / √nprobe; the honest noise band, `∝ 1/√nprobe`).

`shared_probes` (default `false`): with `false`, each block gets its own `nprobe` probes
(`nprobe·K` solves). With `true` (v0.8 V8.2 variance reduction), one FULL-random probe over the
whole random block per solve yields ALL `K` block traces (`nprobe` solves total — `K×` fewer),
unbiased because `E[z_b z_{b'}ᵀ] = δ_{bb'} I`; at equal solve budget it is as tight or tighter than
the per-block estimator (each trace sees `K×` more probes).

EXPERIMENTAL — a stochastic-trace PRIMITIVE, NOT a fit. At validation scale the EXACT
`selinv_block_traces` / `fit_sparse_multi_effect_aireml` is preferred (exact, no MC noise, few
iterations); this exists ONLY for the large-`q` regime the direct factorization cannot reach.
Deterministic given `seed`. No performance/scaling claim here (that is the pre-declared
benchmark's job).
"""
function mc_reml_block_traces(
    X::AbstractMatrix,
    effects::AbstractVector,
    sigmas::AbstractVector,
    sigma_e2::Real;
    nprobe::Integer = 64,
    tol::Real = 1e-9,
    maxiter::Integer = 2000,
    seed::Integer = 0,
    shared_probes::Bool = false,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    length(sigmas) == K || throw(ArgumentError("sigmas length must match number of effects"))
    all(s -> s > 0, sigmas) || throw(ArgumentError("all sigmas must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    nprobe >= 1 || throw(ArgumentError("nprobe must be >= 1"))

    Xs = sparse(Float64.(X))
    n = size(Xs, 1)
    p = size(Xs, 2)
    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(Zs, sparse(Float64.(Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        push!(qs, qi)
    end

    offs = Vector{Int}(undef, K)
    acc = p
    for i in 1:K
        offs[i] = acc
        acc += qs[i]
    end
    ntot = acc

    ss = Float64.(collect(sigmas))
    se2 = Float64(sigma_e2)
    inv_se2 = inv(se2)
    inv_sig = inv.(ss)
    Xt = transpose(Xs)
    Zts = [transpose(Zs[i]) for i in 1:K]
    d = _multi_mme_diag(Xs, Zs, Ainvs, inv_se2, inv_sig, p, offs, qs, ntot)
    all(>(0), d) ||
        throw(ArgumentError("MME diagonal has a non-positive entry; system is not positive definite"))
    invd = 1.0 ./ d
    applyC = v -> _multi_mme_matvec(Xs, Xt, Zs, Zts, Ainvs, inv_se2, inv_sig, p, offs, qs, v)
    applyMinv = r -> invd .* r

    rng = MersenneTwister(seed)
    traces = zeros(Float64, K)
    mcse = zeros(Float64, K)
    meanmcse(samples) = (m = sum(samples) / length(samples);
        (m, length(samples) > 1 ? sqrt(sum(abs2, samples .- m) / (length(samples) - 1) / length(samples)) : NaN))

    if shared_probes
        # SHARED probes (V8.2): one FULL-random Rademacher probe over the whole random block per
        # solve yields ALL K block traces (nprobe solves total, not nprobe·K). Unbiased because
        # `E[z_b z_{b'}ᵀ] = δ_{bb'} I`, so `E[z_bᵀ Aᵦ⁻¹ (C⁻¹ ẑ)_b] = tr(Aᵦ⁻¹ C⁻¹[u_b,u_b])`.
        nrand = ntot - p
        samples = [Vector{Float64}(undef, nprobe) for _ in 1:K]
        zhat = zeros(Float64, ntot)
        for k in 1:nprobe
            fill!(zhat, 0.0)
            @views zhat[(p + 1):ntot] .= rand(rng, (-1.0, 1.0), nrand)   # Rademacher over all random effects
            x, _, _ = _pcg_solve(applyC, copy(zhat); tol = Float64(tol),
                                 maxiter = Int(maxiter), applyMinv = applyMinv)
            for b in 1:K
                rng_b = (offs[b] + 1):(offs[b] + qs[b])
                zb = @view zhat[rng_b]
                samples[b][k] = dot(zb, Ainvs[b] * (@view x[rng_b]))
            end
        end
        for b in 1:K
            traces[b], mcse[b] = meanmcse(samples[b])
        end
    else
        # PER-BLOCK probes: nprobe probes embedded in block b -> nprobe·K solves.
        zhat = zeros(Float64, ntot)
        for b in 1:K
            rng_b = (offs[b] + 1):(offs[b] + qs[b])
            samples = Vector{Float64}(undef, nprobe)
            for k in 1:nprobe
                z = rand(rng, (-1.0, 1.0), qs[b])                 # Rademacher ±1
                fill!(zhat, 0.0)
                @views zhat[rng_b] .= z
                x, _, _ = _pcg_solve(applyC, copy(zhat); tol = Float64(tol),
                                     maxiter = Int(maxiter), applyMinv = applyMinv)
                xb = @view x[rng_b]                               # C⁻¹[u_b,u_b]·z
                samples[k] = dot(z, Ainvs[b] * xb)                # zᵀ Aᵦ⁻¹ C⁻¹[u_b,u_b] z
            end
            traces[b], mcse[b] = meanmcse(samples)
        end
    end
    return traces, mcse
end

"""
    fit_multi_effect_mc_reml(y, X, effects; nprobe = 64, tol = 1e-4, iterations = 200,
                             seed = 0, pcg_tol = 1e-9, pcg_maxiter = 2000,
                             initial = nothing, ids = nothing)

MATRIX-FREE Monte-Carlo EM-REML fit of the `K`-INDEPENDENT-effect Gaussian mixed model
`y = Xβ + Σᵢ Zᵢuᵢ + e`, `uᵢ ~ N(0, σᵢ²Aᵢ)`, `e ~ N(0, σ²e I)` — the FIT companion of the
matrix-free solve [`solve_multi_effect_pcg`](@ref) and the estimator that lifts v0.8-S2 from a
SOLVE to a FIT. It NEVER forms or factorizes the MME coefficient matrix `C`: each EM step is a
matrix-free PCG solve plus the matrix-free Hutchinson trace [`mc_reml_block_traces`](@ref), so
it is not limited by the K≥2 environmental-group Cholesky fill-in that caps the direct/sparse
AI-REML.

Uses the SAME closed-form EM-REML update as `fit_sparse_multi_effect_aireml`'s warmup —
`σᵢ²_new = (ûᵢ'Aᵢ⁻¹ûᵢ + tr(Aᵢ⁻¹C⁻¹[uᵢ,uᵢ]))/qᵢ`, `σ²e_new = ê'ê/(n−p−Σqᵢ + Σ trᵢ/σᵢ²)` — but
with the trace terms MC-estimated. A FIXED probe `seed` is reused across EM iterations
(correlated sampling), so the EM map is deterministic and convergent; its fixed point is the
exact REML optimum perturbed by the MC error (`∝ 1/√nprobe`).

Returns a `NamedTuple` `(variance_components = (sigmas, sigma_e2), ratios, beta, effects, trace_mcse,
converged, iterations, estimator)`. `trace_mcse` is the final block-trace Monte-Carlo standard
error — the honest noise band on the gradient.

EXPERIMENTAL. The returned `NamedTuple` carries no `loglik` field; the matrix-free REML
log-likelihood is available separately via [`matrix_free_reml_loglik`](@ref) (stochastic
log-determinant, V8.1). At validation scale the EXACT `fit_sparse_multi_effect_aireml` is preferred
(exact, no MC noise, fewer iterations); this exists for the large-`q` regime the direct factorization cannot
reach. It RECOVERS the exact AI-REML optimum within MC error (`test/runtests.jl`); a pre-declared
bias/MCSE recovery gate at scale + an external comparator are OWED before any covered claim.
"""
function fit_multi_effect_mc_reml(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector;
    nprobe::Integer = 64,
    tol::Real = 1e-4,
    iterations::Integer = 200,
    seed::Integer = 0,
    pcg_tol::Real = 1e-9,
    pcg_maxiter::Integer = 2000,
    initial = nothing,
    ids = nothing,
    shared_probes::Bool = false,
    compute_loglik::Bool = false,
    slq_probes::Integer = 20,
    slq_steps::Integer = 40,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    n = length(y)
    yv = Float64.(y)
    Xs = sparse(Float64.(X))
    size(Xs, 1) == n || throw(ArgumentError("X must have one row per record"))
    p = size(Xs, 2)
    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        push!(Zs, sparse(Float64.(Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        push!(qs, qi)
    end
    nrand = sum(qs)
    p < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    if initial === nothing
        sigmas = ones(Float64, K)
        sigma_e2 = 1.0
    else
        length(initial) == K + 1 ||
            throw(ArgumentError("initial must have length K+1 = $(K + 1)"))
        all(s -> s > 0, initial) || throw(ArgumentError("initial variance components must be positive"))
        sigmas = Float64.(collect(initial[1:K]))
        sigma_e2 = Float64(initial[K + 1])
    end

    converged = false
    iters = 0
    trace_mcse = fill(NaN, K)
    local last_effects
    for it in 1:iterations
        iters = it
        sol = solve_multi_effect_pcg(yv, Xs, effects, sigmas, sigma_e2;
                                     tol = pcg_tol, maxiter = pcg_maxiter, matrix_free = true, ids = ids)
        us = [e.values for e in sol.effects]
        last_effects = sol.effects
        e = yv .- Xs * sol.beta
        for i in 1:K
            e .-= Zs[i] * us[i]
        end
        uAu = [dot(us[i], Ainvs[i] * us[i]) for i in 1:K]
        traces, trace_mcse = mc_reml_block_traces(Xs, effects, sigmas, sigma_e2;
                                                  nprobe = nprobe, tol = pcg_tol,
                                                  maxiter = pcg_maxiter, seed = seed,
                                                  shared_probes = shared_probes)
        newsig = [(uAu[i] + traces[i]) / qs[i] for i in 1:K]
        dfe = n - p - nrand + sum(traces[i] / sigmas[i] for i in 1:K)
        newe = dfe > 0 ? dot(e, e) / dfe : -1.0
        (all(>(0), newsig) && newe > 0) || break
        rel = max(maximum(abs.(newsig .- sigmas) ./ sigmas), abs(newe - sigma_e2) / sigma_e2)
        sigmas = newsig
        sigma_e2 = newe
        if rel < tol
            converged = true
            break
        end
    end

    total = sum(sigmas) + sigma_e2
    beta_final, effects_final = if @isdefined(last_effects)
        # one final solve at the converged variances for clean BLUPs
        s = solve_multi_effect_pcg(yv, Xs, effects, sigmas, sigma_e2;
                                   tol = pcg_tol, maxiter = pcg_maxiter, matrix_free = true, ids = ids)
        s.beta, s.effects
    else
        zeros(p), [(ids = collect(1:qs[i]), values = zeros(qs[i])) for i in 1:K]
    end
    # Optional matrix-free REML loglik (V8.1, stochastic) at the converged estimate — makes the
    # result shape-compatible with the exact estimators (and the payload-v2 bridge). NaN when off.
    loglik = NaN
    loglik_mcse = NaN
    if compute_loglik
        loglik, loglik_mcse = matrix_free_reml_loglik(yv, Xs, effects, sigmas, sigma_e2;
                                                      slq_probes = slq_probes, slq_steps = slq_steps,
                                                      seed = seed, pcg_tol = pcg_tol, pcg_maxiter = pcg_maxiter)
    end
    return (
        variance_components = (sigmas = sigmas, sigma_e2 = sigma_e2),
        ratios = sigmas ./ total,
        beta = beta_final,
        effects = effects_final,
        loglik = loglik,
        loglik_mcse = loglik_mcse,
        boundary = [s / total < 1e-6 for s in sigmas],
        trace_mcse = trace_mcse,
        converged = converged,
        iterations = iters,
        estimator = :matrix_free_mc_em_reml,
    )
end

# Stochastic Lanczos quadrature (SLQ) for one Rademacher probe: k Lanczos steps on `applyC`
# (matrix-free `C·v`) build a k×k symmetric-tridiagonal `T`; the quadrature `Σ ωⱼ log θⱼ`
# (θ = eigenvalues of T, ω = squared first components of its eigenvectors) estimates
# `z_unitᵀ log(C) z_unit`. Full re-orthogonalization for stability at small k. Returns that
# scalar (per unit vector); the caller multiplies by `‖z‖² = N` for the Rademacher trace.
function _lanczos_logquad(applyC, z::Vector{Float64}, k::Int)
    N = length(z)
    V = zeros(Float64, N, k)
    alpha = zeros(Float64, k)
    beta = zeros(Float64, max(k - 1, 0))
    v = z ./ norm(z)
    @views V[:, 1] .= v
    w = applyC(v)
    a = dot(w, v); alpha[1] = a
    @. w = w - a * v
    kk = k
    for j in 2:k
        b = norm(w)
        if b < 1e-12
            kk = j - 1
            break
        end
        beta[j - 1] = b
        vprev = @view V[:, j - 1]
        v = w ./ b
        for i in 1:(j - 1)                                  # full re-orthogonalization
            @views v .-= dot(v, V[:, i]) .* V[:, i]
        end
        v ./= norm(v)
        @views V[:, j] .= v
        w = applyC(v)
        a = dot(w, v); alpha[j] = a
        @. w = w - a * v - b * vprev
    end
    T = SymTridiagonal(alpha[1:kk], beta[1:(kk - 1)])
    E = eigen(T)
    all(>(0), E.values) || return NaN                       # C must be PD (log of a non-PD ⇒ NaN)
    return sum((E.vectors[1, :] .^ 2) .* log.(E.values))
end

"""
    matrix_free_reml_loglik(y, X, effects, sigmas, sigma_e2; slq_probes = 20, slq_steps = 40,
                            seed = 0, pcg_tol = 1e-9, pcg_maxiter = 2000)

MATRIX-FREE Gaussian REML log-likelihood of the `K`-independent-effect model at the SUPPLIED
variance components — the loglik companion of [`fit_multi_effect_mc_reml`](@ref) (v0.8 V8.1). It
never forms or factorizes the MME coefficient matrix `C`: the only determinant term that needs
`C`, `log|C|`, is estimated by **stochastic Lanczos quadrature** (SLQ) — `slq_probes` Rademacher
probes, `slq_steps` matrix-free Lanczos steps each — while the other REML terms are exact/cheap:

`ℓ = −½[(n−p)·log(2π) + n·log(σ²e) + Σᵢ(qᵢ·log(σᵢ²) − log|Aᵢ⁻¹|) + log|C| + yᵀPy]`,

with `log|Aᵢ⁻¹|` from a one-time sparse Cholesky of each `Aᵢ⁻¹` (the pedigree/identity precision —
far cheaper than `C`; an `O(q)` Mendelian route is a future scale optimization) and `yᵀPy` from a
matrix-free MME solve. It uses the SAME full-constant convention as `sparse_multi_reml_loglik`, so
the two agree up to the SLQ Monte-Carlo error on `log|C|`.

Returns `(loglik, loglik_mcse)` — the estimate and its Monte-Carlo standard error (the SLQ noise on
`log|C|`, scaled by ½; `∝ 1/√slq_probes`).

EXPERIMENTAL. This is the term that unlocks LRTs / interval machinery for the matrix-free fit. It
is STOCHASTIC (the loglik carries MC noise); at validation scale the exact
`sparse_multi_reml_loglik` is preferred. Requires a positive-definite `C` (returns `NaN` loglik
otherwise).
"""
function matrix_free_reml_loglik(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector,
    sigmas::AbstractVector,
    sigma_e2::Real;
    slq_probes::Integer = 20,
    slq_steps::Integer = 40,
    seed::Integer = 0,
    pcg_tol::Real = 1e-9,
    pcg_maxiter::Integer = 2000,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    length(sigmas) == K || throw(ArgumentError("sigmas length must match number of effects"))
    all(s -> s > 0, sigmas) || throw(ArgumentError("all sigmas must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    slq_probes >= 1 || throw(ArgumentError("slq_probes must be >= 1"))
    slq_steps >= 2 || throw(ArgumentError("slq_steps must be >= 2"))

    n = length(y)
    yv = Float64.(y)
    Xs = sparse(Float64.(X))
    p = size(Xs, 2)
    p < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))
    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        push!(Zs, sparse(Float64.(Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        push!(qs, size(Ainvi, 1))
    end
    ss = Float64.(collect(sigmas)); se2 = Float64(sigma_e2)
    inv_se2 = inv(se2); inv_sig = inv.(ss)
    offs = Vector{Int}(undef, K); acc = p
    for i in 1:K; offs[i] = acc; acc += qs[i]; end
    ntot = acc

    Xt = transpose(Xs); Zts = [transpose(Zs[i]) for i in 1:K]
    applyC = v -> _multi_mme_matvec(Xs, Xt, Zs, Zts, Ainvs, inv_se2, inv_sig, p, offs, qs, v)

    # log|R| + log|G|
    logdetR = n * log(se2)
    logdetG = 0.0
    for i in 1:K
        logdetG += qs[i] * log(ss[i])
        chAinv = cholesky(Symmetric(Ainvs[i]); check = true)   # one-time; pedigree/identity, cheaper than C
        logdetG -= logdet(chAinv)                              # log|Aᵢ⁻¹|
    end

    # yᵀPy = (1/σ²e)·yᵀy − rhsᵀ·C⁻¹·rhs (the sparse MME identity), matrix-free.
    rhs = Vector{Float64}(undef, ntot)
    rhs[1:p] .= inv_se2 .* (Xt * yv)
    for i in 1:K
        rhs[(offs[i] + 1):(offs[i] + qs[i])] .= inv_se2 .* (Zts[i] * yv)
    end
    d = _multi_mme_diag(Xs, Zs, Ainvs, inv_se2, inv_sig, p, offs, qs, ntot)
    invd = 1.0 ./ d
    sol, _, _ = _pcg_solve(applyC, copy(rhs); tol = Float64(pcg_tol),
                           maxiter = Int(pcg_maxiter), applyMinv = r -> invd .* r)
    quad = inv_se2 * dot(yv, yv) - dot(rhs, sol)

    # log|C| by SLQ (matrix-free).
    rng = MersenneTwister(seed)
    contribs = Float64[]
    for _ in 1:slq_probes
        z = rand(rng, (-1.0, 1.0), ntot)                      # Rademacher, ‖z‖²=ntot
        c = _lanczos_logquad(applyC, z, Int(slq_steps))
        isnan(c) && return (NaN, NaN)
        push!(contribs, ntot * c)
    end
    logdetC = sum(contribs) / slq_probes
    logdetC_mcse = slq_probes > 1 ?
        sqrt(sum(abs2, contribs .- logdetC) / (slq_probes - 1) / slq_probes) : NaN

    loglik = -0.5 * ((n - p) * log(2 * pi) + logdetR + logdetG + logdetC + quad)
    loglik_mcse = 0.5 * logdetC_mcse
    return (loglik, loglik_mcse)
end

"""
    fit_multi_effect(y, X, effects; method = :auto, direct_max_n = 200_000, nprobe = 64,
                     verbose = true, kwargs...)

Fit the `K`-INDEPENDENT-effect Gaussian mixed model, automatically choosing the solver by
feasibility. This is the single entry point over the two multi-effect REML engines:

  - **exact** [`fit_sparse_multi_effect_aireml`](@ref) — sparse AI-REML, exact gradient (a
    Cholesky selected inverse each iteration). The default where feasible; limited by the K≥2
    environmental-group Cholesky fill-in at large `N`.
  - **matrix-free** [`fit_multi_effect_mc_reml`](@ref) — Monte-Carlo EM-REML, never forms or
    factorizes `C` (matrix-free solves + Hutchinson trace). Feasible where the exact path is
    fill-limited, at the cost of Monte-Carlo noise in the gradient (`trace_mcse`).

`method`:
  - `:auto` (default) — route on feasibility: `:exact` for a single random effect (`K = 1`, the
    animal-model MME stays sparse-feasible to very large `q`) OR when `N = p + Σqᵢ ≤ direct_max_n`;
    otherwise `:matrix_free`, with a `@info` message (unless `verbose = false`) noting the switch
    and that estimates carry a Monte-Carlo standard error.
  - `:exact` / `:matrix_free` — force the engine (may OOM / accept MC noise respectively).

The `:auto` `direct_max_n` threshold is a **coarse, machine-agnostic heuristic** calibrated to the
measured K≥2 factorization cost (Phase 5 / v0.8-S2 benchmarks: the direct multi-effect Cholesky is
already ~quadratic by `q ≈ 50k` and infeasible past `~10⁵`–`10⁶`). It is deliberately conservative
and ALWAYS overridable; a precise symbolic-fill predictor is future work. Because the exact and
matrix-free result shapes differ (matrix-free has `trace_mcse`, no `loglik`), the returned
`NamedTuple` is the chosen engine's own, with an added `dispatch` field (`:exact` | `:matrix_free`)
recording which ran.

EXPERIMENTAL. `nprobe` and other keywords forward to the chosen engine.
"""
function fit_multi_effect(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector;
    method::Symbol = :auto,
    direct_max_n::Integer = 200_000,
    nprobe::Integer = 64,
    verbose::Bool = true,
    shared_probes::Bool = false,
    compute_loglik::Bool = false,
    slq_probes::Integer = 20,
    slq_steps::Integer = 40,
    kwargs...,
)
    method in (:auto, :exact, :matrix_free) ||
        throw(ArgumentError("method must be :auto, :exact, or :matrix_free"))
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    p = size(X, 2)
    N = p + sum(size(pair[2], 1) for pair in effects)

    chosen = if method === :exact
        :exact
    elseif method === :matrix_free
        :matrix_free
    else
        (K == 1 || N <= direct_max_n) ? :exact : :matrix_free
    end

    if chosen === :exact
        res = fit_sparse_multi_effect_aireml(y, X, effects; kwargs...)
        return merge(res, (dispatch = :exact,))
    else
        if verbose
            @info("fit_multi_effect: problem exceeds the direct-factorization budget " *
                  "(N=$N, K=$K > direct_max_n=$direct_max_n) — using matrix-free Monte-Carlo REML; " *
                  "estimates carry a Monte-Carlo standard error (see `trace_mcse`). " *
                  "Override with method=:exact to force the exact (fill-limited) path.")
        end
        res = fit_multi_effect_mc_reml(y, X, effects; nprobe = nprobe, shared_probes = shared_probes,
                                       compute_loglik = compute_loglik, slq_probes = slq_probes,
                                       slq_steps = slq_steps, kwargs...)
        return merge(res, (dispatch = :matrix_free,))
    end
end

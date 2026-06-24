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

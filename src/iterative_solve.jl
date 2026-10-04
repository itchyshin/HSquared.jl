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
# Convergence uses the true residual; a misleading recursive residual triggers a
# restart within maxiter. Unsupported range throws; finite unconverged iterates return.
function _pcg_solve(applyC, b::Vector{Float64}; tol::Float64, maxiter::Int, applyMinv)
    _require_finite_matrix_free_result("PCG right-hand side", b)
    x = zeros(length(b))
    r = copy(b)
    bnorm = norm(b)
    _require_finite_matrix_free_result("PCG right-hand-side norm", bnorm)
    bnorm == 0 && return x, 0, 0.0
    z = applyMinv(r)
    _require_finite_matrix_free_result("PCG preconditioned residual", z)
    p = copy(z)
    rz = dot(r, z)
    isfinite(rz) && rz > 0 ||
        throw(ArgumentError("PCG residual inner product is outside the supported positive Float64 range"))
    iters = 0
    relres = norm(r) / bnorm
    for k in 1:maxiter
        Cp = applyC(p)
        _require_finite_matrix_free_result("PCG operator product", Cp)
        pCp = dot(p, Cp)
        _require_finite_matrix_free_result("PCG curvature", pCp)
        pCp > 0 ||
            throw(ArgumentError("PCG hit non-positive curvature (pᵀCp = $(pCp)); the system is not positive definite"))
        alpha = rz / pCp
        isfinite(alpha) && alpha > 0 ||
            throw(ArgumentError("PCG step is outside the supported positive Float64 range"))
        @. x += alpha * p
        @. r -= alpha * Cp
        iters = k
        relres = norm(r) / bnorm
        if relres <= tol
            # Roundoff can put the recursive residual below tol before the true
            # residual is small enough. Verify before stopping, then restart PCG
            # from b-Cx if needed, using only the remaining iteration budget.
            r = b - applyC(x)
            _require_finite_matrix_free_result("PCG true residual", r)
            relres = norm(r) / bnorm
            _require_finite_matrix_free_result("PCG relative residual", relres)
            relres <= tol && break
            z = applyMinv(r)
            _require_finite_matrix_free_result("PCG preconditioned residual", z)
            rz = dot(r, z)
            isfinite(rz) && rz > 0 ||
                throw(ArgumentError("PCG residual inner product is outside the supported positive Float64 range"))
            p .= z
            continue
        end
        z = applyMinv(r)
        rz_new = dot(r, z)
        isfinite(rz_new) && rz_new > 0 ||
            throw(ArgumentError("PCG residual inner product is outside the supported positive Float64 range"))
        beta = rz_new / rz
        _require_finite_matrix_free_result("PCG direction update", beta)
        @. p = z + beta * p
        rz = rz_new
    end
    # Report the TRUE residual at the returned x (one extra matvec), not the
    # recursively-accumulated `r` — so `relative_residual`/`converged` are exactly
    # ‖b − Cx‖/‖b‖ regardless of any recursive-residual drift on ill-conditioned input.
    relres = norm(b - applyC(x)) / bnorm
    _require_finite_matrix_free_result("PCG solution", x)
    _require_finite_matrix_free_result("PCG relative residual", relres)
    return x, iters, relres
end

# Validate the supplied data independently of structural zeros in later products.
function _matrix_free_float64_data(name::AbstractString, values::AbstractArray)
    all(isfinite, values) || throw(ArgumentError("$name must contain only finite values"))
    converted = Float64.(values)
    all(isfinite, converted) ||
        throw(ArgumentError("$name must contain only finite values after Float64 conversion"))
    return converted
end

function _require_finite_matrix_free_result(name::AbstractString, values)
    all(isfinite, values) ||
        throw(ArgumentError("$name exceeded the supported Float64 arithmetic range; no finite result is reported"))
    return nothing
end

# Scale finite probe samples before their mean and sample-MCSE arithmetic.
function _matrix_free_probe_summary(samples::AbstractVector{<:Real})
    n = length(samples)
    n > 0 || throw(ArgumentError("at least one probe sample is required"))
    _require_finite_matrix_free_result("probe samples", samples)
    scale = maximum(abs, samples)
    scale == 0 && return (0.0, n > 1 ? 0.0 : NaN)
    scaled = samples ./ scale
    mean_scaled = sum(scaled) / n
    m = scale * mean_scaled
    mcse = n > 1 ? scale * sqrt(sum(abs2, scaled .- mean_scaled) / (n - 1) / n) : NaN
    _require_finite_matrix_free_result("probe mean", m)
    n > 1 && _require_finite_matrix_free_result("probe Monte-Carlo standard error", mcse)
    return m, mcse
end

# A fit, likelihood, or information matrix may consume a PCG solution only after
# its true residual meets the requested tolerance. Public standalone solvers keep
# returning their convergence diagnostics, so callers can inspect a failed solve.
function _require_pcg_convergence(relative_residual::Real, tol::Real)
    (isfinite(relative_residual) && isfinite(tol) && 0 < tol && relative_residual <= tol) ||
        throw(ArgumentError("PCG did not reach the requested tolerance: relative residual = $(relative_residual), tolerance = $(tol); increase pcg_maxiter/maxiter or improve conditioning"))
    return nothing
end

# Sparse QR rejects rank-deficient fixed-effect blocks without densifying X.
function _require_full_fixed_effect_rank(X::SparseMatrixCSC)
    size(X, 2) == 0 && return nothing
    rank(qr(X)) == size(X, 2) ||
        throw(ArgumentError("fixed-effect design matrix X must have full column rank for a unique fixed-effect/MME solution"))
    return nothing
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

function _require_finite_positive_mme_diag(d)
    all(x -> isfinite(x) && x > 0, d) ||
        throw(ArgumentError("MME diagonal must contain only finite positive entries"))
    return nothing
end

function _finite_positive_float64(name::AbstractString, value::Real)
    converted = Float64(value)
    (isfinite(converted) && converted > 0) ||
        throw(ArgumentError("$name must be finite and positive after conversion to Float64"))
    return converted
end

function _finite_positive_variance_float64(name::AbstractString, value::Real)
    converted = _finite_positive_float64(name, value)
    isfinite(inv(converted)) ||
        throw(ArgumentError("$name is too small to have a finite Float64 precision"))
    return converted
end

@inline _finite_positive_variance_update(sigmas, sigma_e2) =
    all(s -> isfinite(s) && s > 0 && isfinite(inv(s)), sigmas) &&
    isfinite(sigma_e2) && sigma_e2 > 0 && isfinite(inv(sigma_e2))

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
    sigma_a2 = _finite_positive_variance_float64("sigma_a2", sigma_a2)
    sigma_e2 = _finite_positive_variance_float64("sigma_e2", sigma_e2)
    tol = _finite_positive_float64("tol", tol)
    maxiter >= 1 || throw(ArgumentError("maxiter must be >= 1"))
    preconditioner in (:jacobi, :none, :ichol) ||
        throw(ArgumentError("preconditioner must be :jacobi, :ichol, or :none"))
    (preconditioner === :ichol && matrix_free) &&
        throw(ArgumentError(":ichol preconditioner requires matrix_free = false (it factorizes the assembled C)"))
    nfixed = size(spec.X, 2)
    y_input = _matrix_free_float64_data("y", spec.y)
    X_input = _matrix_free_float64_data("X", spec.X)
    Z_input = _matrix_free_float64_data("Z", spec.Z)
    _require_full_fixed_effect_rank(sparse(X_input))

    if matrix_free
        inv_se2 = inv(sigma_e2)
        inv_sa2 = inv(sigma_a2)
        X = sparse(X_input)
        Z = sparse(Z_input)
        Ainv = sparse(Float64.(spec.Ainv))
        Ainv, _ = _validate_matrix_free_precision(Ainv, 1)
        Xt = transpose(X)
        Zt = transpose(Z)
        y = y_input
        rhs = vcat(inv_se2 .* (Xt * y), inv_se2 .* (Zt * y))
        d = _mme_diag(X, Z, Ainv, inv_se2, inv_sa2)
        applyC = v -> _mme_matvec(X, Xt, Z, Zt, Ainv, inv_se2, inv_sa2, nfixed, v)
    else
        Ainv = sparse(Float64.(spec.Ainv))
        Ainv, _ = _validate_matrix_free_precision(Ainv, 1)
        validated_spec = AnimalModelSpec(y_input, X_input, Z_input, Ainv, spec.ids,
                                         spec.family, spec.method, spec.relationship_diag)
        lhs, rhs, _ = _sparse_mme_system(validated_spec, sigma_a2, sigma_e2)
        d = Vector{Float64}(diag(lhs))
        applyC = v -> lhs * v
    end
    _require_finite_positive_mme_diag(d)
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
                                  tol = tol, maxiter = Int(maxiter), applyMinv = applyMinv)
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

# Check and canonicalize a sparse relationship precision without densifying it.
# The tolerance is 100*q*eps(Float64)*||Ainv||∞, accounting for sparse
# accumulation roundoff while staying scale-relative. Accepted noise is
# averaged so all downstream products use the matrix whose SPD is assessed.
function _canonicalize_matrix_free_precision(Ainv::SparseMatrixCSC{Float64,Ti}, i::Int) where {Ti<:Integer}
    size(Ainv, 1) == size(Ainv, 2) ||
        throw(ArgumentError("Ainv[$i] must be square"))
    all(isfinite, nonzeros(Ainv)) ||
        throw(ArgumentError("Ainv[$i] must contain only finite values"))
    scale = opnorm(Ainv, Inf)
    isfinite(scale) || throw(ArgumentError("Ainv[$i] has a non-finite matrix norm"))
    scale = max(scale, floatmin(Float64))
    symmetry_error = opnorm(Ainv - transpose(Ainv), Inf)
    symmetry_error <= 100 * eps(Float64) * max(size(Ainv, 1), 1) * scale ||
        throw(ArgumentError("Ainv[$i] must be symmetric"))
    # Canonicalize tolerated roundoff asymmetry so every later matvec and
    # quadratic uses the same symmetric matrix whose definiteness is checked.
    # Scale before adding: `Ainv + Ainv'` can overflow even when both
    # symmetric entries are finite and their average is representable.
    Ainv_symmetric = sparse(0.5 .* Ainv + 0.5 .* transpose(Ainv))
    return Ainv_symmetric
end

# Positive MME curvature does not prove that its supplied prior precision is a
# valid covariance model, especially when a zero RHS makes PCG return early.
function _validate_matrix_free_precision(Ainv::SparseMatrixCSC{Float64,Ti}, i::Int) where {Ti<:Integer}
    Ainv_symmetric = _canonicalize_matrix_free_precision(Ainv, i)
    try
        return Ainv_symmetric, cholesky(Symmetric(Ainv_symmetric); check = true)
    catch err
        if err isa PosDefException || err isa SingularException
            throw(ArgumentError("Ainv[$i] must be positive definite"))
        end
        rethrow()
    end
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
    return _solve_multi_effect_pcg(y, X, effects, sigmas, sigma_e2;
        tol = tol, maxiter = maxiter, preconditioner = preconditioner,
        matrix_free = matrix_free, ids = ids, validate_precision = true)
end

function _solve_multi_effect_pcg(
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
    validate_precision::Bool,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    length(sigmas) == K || throw(ArgumentError("sigmas length must match number of effects"))
    ss = Float64.(collect(sigmas))
    all(s -> isfinite(s) && s > 0 && isfinite(inv(s)), ss) ||
        throw(ArgumentError("all sigmas must be finite, positive, and have finite Float64 precisions"))
    se2 = _finite_positive_variance_float64("sigma_e2", sigma_e2)
    tol = _finite_positive_float64("tol", tol)
    maxiter >= 1 || throw(ArgumentError("maxiter must be >= 1"))
    preconditioner in (:jacobi, :none, :ichol) ||
        throw(ArgumentError("preconditioner must be :jacobi, :ichol, or :none"))
    (preconditioner === :ichol && matrix_free) &&
        throw(ArgumentError(":ichol preconditioner requires matrix_free = false (it factorizes the assembled C)"))

    n = length(y)
    yv = _matrix_free_float64_data("y", y)
    Xs = sparse(_matrix_free_float64_data("X", X))
    size(Xs, 1) == n || throw(ArgumentError("X must have one row per record"))
    p = size(Xs, 2)
    _require_full_fixed_effect_rank(Xs)

    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(Zs, sparse(_matrix_free_float64_data("Z[$i]", Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        if validate_precision
            Ainvs[end], _ = _validate_matrix_free_precision(Ainvs[end], i)
        end
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
    _require_finite_positive_mme_diag(d)

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
With one probe, `mcse` is undefined (`NaN`). Probe summaries are scaled to avoid
intermediate overflow; unsupported nonfinite arithmetic throws an `ArgumentError`.

`shared_probes` (default `false`): with `false`, each block gets its own `nprobe` probes
(`nprobe·K` solves). With `true`, one full-random probe over the whole random block yields all
`K` block traces in `nprobe` solves. Both estimators are unbiased under exact solves. Shared probes
can be cheaper, but cross-block terms contribute to their sampling variance, so they are not
uniformly more precise at an equal solve budget. The returned `mcse` measures probe sampling
variation and excludes PCG solve error.

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
    return _mc_reml_block_traces(X, effects, sigmas, sigma_e2;
        nprobe = nprobe, tol = tol, maxiter = maxiter, seed = seed,
        shared_probes = shared_probes, validate_precision = true)
end

function _mc_reml_block_traces(
    X::AbstractMatrix,
    effects::AbstractVector,
    sigmas::AbstractVector,
    sigma_e2::Real;
    nprobe::Integer = 64,
    tol::Real = 1e-9,
    maxiter::Integer = 2000,
    seed::Integer = 0,
    shared_probes::Bool = false,
    validate_precision::Bool,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    length(sigmas) == K || throw(ArgumentError("sigmas length must match number of effects"))
    ss = Float64.(collect(sigmas))
    all(s -> isfinite(s) && s > 0 && isfinite(inv(s)), ss) ||
        throw(ArgumentError("all sigmas must be finite, positive, and have finite Float64 precisions"))
    se2 = _finite_positive_variance_float64("sigma_e2", sigma_e2)
    tol = _finite_positive_float64("tol", tol)
    nprobe >= 1 || throw(ArgumentError("nprobe must be >= 1"))
    maxiter >= 1 || throw(ArgumentError("maxiter must be >= 1"))

    Xs = sparse(_matrix_free_float64_data("X", X))
    n = size(Xs, 1)
    p = size(Xs, 2)
    p < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))
    _require_full_fixed_effect_rank(Xs)
    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(Zs, sparse(_matrix_free_float64_data("Z[$i]", Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        if validate_precision
            Ainvs[end], _ = _validate_matrix_free_precision(Ainvs[end], i)
        end
        push!(qs, qi)
    end

    offs = Vector{Int}(undef, K)
    acc = p
    for i in 1:K
        offs[i] = acc
        acc += qs[i]
    end
    ntot = acc

    inv_se2 = inv(se2)
    inv_sig = inv.(ss)
    Xt = transpose(Xs)
    Zts = [transpose(Zs[i]) for i in 1:K]
    d = _multi_mme_diag(Xs, Zs, Ainvs, inv_se2, inv_sig, p, offs, qs, ntot)
    _require_finite_positive_mme_diag(d)
    invd = 1.0 ./ d
    applyC = v -> _multi_mme_matvec(Xs, Xt, Zs, Zts, Ainvs, inv_se2, inv_sig, p, offs, qs, v)
    applyMinv = r -> invd .* r

    rng = MersenneTwister(seed)
    traces = zeros(Float64, K)
    mcse = zeros(Float64, K)

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
            x, _, relres = _pcg_solve(applyC, copy(zhat); tol = Float64(tol),
                                      maxiter = Int(maxiter), applyMinv = applyMinv)
            _require_pcg_convergence(relres, tol)
            for b in 1:K
                rng_b = (offs[b] + 1):(offs[b] + qs[b])
                zb = @view zhat[rng_b]
                samples[b][k] = dot(zb, Ainvs[b] * (@view x[rng_b]))
            end
        end
        for b in 1:K
            traces[b], mcse[b] = _matrix_free_probe_summary(samples[b])
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
                x, _, relres = _pcg_solve(applyC, copy(zhat); tol = Float64(tol),
                                          maxiter = Int(maxiter), applyMinv = applyMinv)
                _require_pcg_convergence(relres, tol)
                xb = @view x[rng_b]                               # C⁻¹[u_b,u_b]·z
                samples[k] = dot(z, Ainvs[b] * xb)                # zᵀ Aᵦ⁻¹ C⁻¹[u_b,u_b] z
            end
            traces[b], mcse[b] = _matrix_free_probe_summary(samples)
        end
    end
    return traces, mcse
end

"""
    fit_multi_effect_mc_reml(y, X, effects; nprobe = 64, tol = 1e-4, iterations = 200,
                             seed = 0, pcg_tol = 1e-9, pcg_maxiter = 2000,
                             initial = nothing, ids = nothing)

MATRIX-FREE Monte-Carlo REML fixed-point fit of the `K`-INDEPENDENT-effect Gaussian mixed model
`y = Xβ + Σᵢ Zᵢuᵢ + e`, `uᵢ ~ N(0, σᵢ²Aᵢ)`, `e ~ N(0, σ²e I)` — the FIT companion of the
matrix-free solve [`solve_multi_effect_pcg`](@ref) and the estimator that lifts v0.8-S2 from a
SOLVE to a FIT. It NEVER forms or factorizes the MME coefficient matrix `C`: each iteration is a
matrix-free PCG solve plus the matrix-free Hutchinson trace [`mc_reml_block_traces`](@ref), so
it is not limited by the K≥2 environmental-group Cholesky fill-in that caps the direct/sparse
AI-REML.

Uses REML score fixed-point updates with the form used by `fit_sparse_multi_effect_aireml`'s warmup —
`σᵢ²_new = (ûᵢ'Aᵢ⁻¹ûᵢ + tr(Aᵢ⁻¹C⁻¹[uᵢ,uᵢ]))/qᵢ`, `σ²e_new = ê'ê/(n−p−Σqᵢ + Σ trᵢ/σᵢ²)` — but
with the trace terms MC-estimated. A FIXED probe `seed` is reused across iterations
(correlated sampling), so the iteration is reproducible for a given seed. This is a stochastic
REML fixed-point iteration, not an EM ascent guarantee; `converged` reports small relative changes
in variance components and does not establish a unique or global optimum.

Returns a `NamedTuple` containing the fitted variance components, ratios, `beta`, random effects,
and convergence diagnostics. `trace_mcse` is the Monte-Carlo standard error of the final trace
estimate at the returned variance components. It is not a gradient, variance-component, or
log-likelihood standard error, and it excludes PCG solve error. The accompanying
`trace_evaluation_variance_components` records the variance components used for that diagnostic.

EXPERIMENTAL. The returned `NamedTuple` includes `loglik`; it is `NaN` unless
`compute_loglik = true`, in which case [`matrix_free_reml_loglik`](@ref) supplies a stochastic
REML log-likelihood estimate using SLQ for the log determinant (V8.1). At validation scale the
EXACT `fit_sparse_multi_effect_aireml` is preferred (exact, no MC noise, fewer iterations); this
exists for the large-`q` regime the direct factorization cannot reach. Current tests include a
bounded exact AI-REML comparison (`test/runtests.jl`); they do not establish recovery rates. A
pre-declared bias/MCSE recovery gate at scale + an external comparator are OWED before any covered claim.
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
    tol = _finite_positive_float64("tol", tol)
    pcg_tol = _finite_positive_float64("pcg_tol", pcg_tol)
    iterations >= 1 || throw(ArgumentError("iterations must be at least 1"))
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    n = length(y)
    yv = _matrix_free_float64_data("y", y)
    Xs = sparse(_matrix_free_float64_data("X", X))
    size(Xs, 1) == n || throw(ArgumentError("X must have one row per record"))
    p = size(Xs, 2)
    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        push!(Zs, sparse(_matrix_free_float64_data("Z[$i]", Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        push!(qs, qi)
    end
    precision_logdetAinv = zeros(Float64, K)
    for i in eachindex(Ainvs)
        Ainvs[i], factor = _validate_matrix_free_precision(Ainvs[i], i)
        if compute_loglik
            precision_logdetAinv[i] = logdet(factor)
        end
    end
    validated_effects = [(Zs[i], Ainvs[i]) for i in eachindex(Ainvs)]
    nrand = sum(qs)
    p < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))
    _require_full_fixed_effect_rank(Xs)

    if initial === nothing
        sigmas = ones(Float64, K)
        sigma_e2 = 1.0
    else
        length(initial) == K + 1 ||
            throw(ArgumentError("initial must have length K+1 = $(K + 1)"))
        initial_float = Float64.(collect(initial))
        all(s -> isfinite(s) && s > 0 && isfinite(inv(s)), initial_float) ||
            throw(ArgumentError("initial variance components must be finite, positive, and have finite Float64 precisions"))
        sigmas = initial_float[1:K]
        sigma_e2 = initial_float[K + 1]
    end

    converged = false
    iters = 0
    trace_mcse = fill(NaN, K)
    local last_effects
    for it in 1:iterations
        iters = it
        sol = _solve_multi_effect_pcg(yv, Xs, validated_effects, sigmas, sigma_e2;
                                      tol = pcg_tol, maxiter = pcg_maxiter, matrix_free = true,
                                      ids = ids, validate_precision = false)
        _require_pcg_convergence(sol.relative_residual, pcg_tol)
        us = [e.values for e in sol.effects]
        last_effects = sol.effects
        e = yv .- Xs * sol.beta
        for i in 1:K
            e .-= Zs[i] * us[i]
        end
        uAu = [dot(us[i], Ainvs[i] * us[i]) for i in 1:K]
        traces, trace_mcse = _mc_reml_block_traces(Xs, validated_effects, sigmas, sigma_e2;
            nprobe = nprobe, tol = pcg_tol, maxiter = pcg_maxiter, seed = seed,
            shared_probes = shared_probes, validate_precision = false)
        newsig = [(uAu[i] + traces[i]) / qs[i] for i in 1:K]
        dfe = n - p - nrand + sum(traces[i] / sigmas[i] for i in 1:K)
        newe = dfe > 0 ? dot(e, e) / dfe : -1.0
        _finite_positive_variance_update(newsig, newe) || break
        rel = max(maximum(abs.(newsig .- sigmas) ./ sigmas), abs(newe - sigma_e2) / sigma_e2)
        sigmas = newsig
        sigma_e2 = newe
        if rel < tol
            converged = true
            break
        end
    end

    # Re-evaluate the trace diagnostic at the variance components that will
    # actually be returned. The traces inside the last update were evaluated
    # at the preceding components.
    _, trace_mcse = _mc_reml_block_traces(Xs, validated_effects, sigmas, sigma_e2;
        nprobe = nprobe, tol = pcg_tol, maxiter = pcg_maxiter, seed = seed,
        shared_probes = shared_probes, validate_precision = false)
    trace_evaluation_variance_components = (sigmas = copy(sigmas), sigma_e2 = sigma_e2)

    # Ratios can be finite even when the sum of finite variances overflows.
    scale = max(maximum(sigmas), sigma_e2)
    scaled_sigmas = sigmas ./ scale
    scaled_total = sum(scaled_sigmas) + sigma_e2 / scale
    ratios = scaled_sigmas ./ scaled_total
    _require_finite_matrix_free_result("variance ratios", ratios)
    beta_final, effects_final = if @isdefined(last_effects)
        # one final solve at the converged variances for clean BLUPs
        s = _solve_multi_effect_pcg(yv, Xs, validated_effects, sigmas, sigma_e2;
                                    tol = pcg_tol, maxiter = pcg_maxiter, matrix_free = true,
                                    ids = ids, validate_precision = false)
        _require_pcg_convergence(s.relative_residual, pcg_tol)
        s.beta, s.effects
    else
        zeros(p), [(ids = collect(1:qs[i]), values = zeros(qs[i])) for i in 1:K]
    end
    # Optional matrix-free REML loglik (V8.1, stochastic) at the returned estimate — makes the
    # result shape-compatible with the exact estimators (and the payload-v2 bridge). NaN when off.
    loglik = NaN
    loglik_mcse = NaN
    if compute_loglik
        loglik, loglik_mcse = _matrix_free_reml_loglik(yv, Xs, validated_effects, sigmas, sigma_e2;
            slq_probes = slq_probes, slq_steps = slq_steps, seed = seed,
            pcg_tol = pcg_tol, pcg_maxiter = pcg_maxiter,
            precision_logdetAinv = precision_logdetAinv)
    end
    return merge((
        variance_components = (sigmas = sigmas, sigma_e2 = sigma_e2),
        ratios = ratios,
        beta = beta_final,
        effects = effects_final,
        loglik = loglik,
        loglik_mcse = loglik_mcse,
        boundary = [r < 1e-6 for r in ratios],
        trace_mcse = trace_mcse,
        trace_evaluation_variance_components = trace_evaluation_variance_components,
        converged = converged,
        iterations = iters,
        estimator = :matrix_free_mc_em_reml,
    ), loglik_convention_fields(LOGLIK_CONVENTION_FULL, n, p))
end

# Stochastic Lanczos quadrature (SLQ) for one Rademacher probe: k Lanczos steps on `applyC`
# (matrix-free `C·v`) build a k×k symmetric-tridiagonal `T`; the quadrature `Σ ωⱼ log θⱼ`
# (θ = eigenvalues of T, ω = squared first components of its eigenvectors) estimates
# `z_unitᵀ log(C) z_unit`. Full re-orthogonalization for stability at small k. Returns that
# scalar (per unit vector); the caller multiplies by `‖z‖² = N` for the Rademacher trace.
function _lanczos_logquad(applyC, z::Vector{Float64}, k::Int)
    N = length(z)
    N > 0 || throw(ArgumentError("Lanczos requires a non-empty starting vector"))
    k > 0 || throw(ArgumentError("Lanczos steps must be positive"))
    nsteps = min(k, N)
    V = zeros(Float64, N, nsteps)
    alpha = zeros(Float64, nsteps)
    beta = zeros(Float64, max(nsteps - 1, 0))
    znorm = norm(z)
    isfinite(znorm) && znorm > 0 ||
        throw(ArgumentError("Lanczos starting vector must be finite and non-zero"))
    v = z ./ znorm
    @views V[:, 1] .= v
    w = Float64.(applyC(v))
    length(w) == N || throw(DimensionMismatch("Lanczos operator returned a vector of the wrong length"))
    all(isfinite, w) || return NaN
    a = dot(w, v); alpha[1] = a
    lanczos_scale = max(norm(w), abs(a))
    @. w = w - a * v
    kk = 1
    for j in 2:nsteps
        # Re-orthogonalize the residual before measuring its norm. In exact
        # arithmetic it is already orthogonal to the previous basis; finite
        # precision can leave a tiny component that becomes a spurious new
        # direction when divided by its norm. A second pass stabilizes the
        # test at exact and near Krylov breakdown.
        for _ in 1:2
            for i in 1:(j - 1)
                vi = @view V[:, i]
                w .-= dot(vi, w) .* vi
            end
        end
        b = norm(w)
        breakdown_tol = max(N, nsteps) * eps(Float64) * lanczos_scale
        if !isfinite(b)
            return NaN
        elseif b <= breakdown_tol
            kk = j - 1
            break
        end
        beta[j - 1] = b
        vprev = @view V[:, j - 1]
        v = w ./ b
        @views V[:, j] .= v
        kk = j
        w = Float64.(applyC(v))
        length(w) == N || throw(DimensionMismatch("Lanczos operator returned a vector of the wrong length"))
        all(isfinite, w) || return NaN
        a = dot(w, v); alpha[j] = a
        lanczos_scale = max(lanczos_scale, norm(w), abs(a))
        @. w = w - a * v - b * vprev
    end
    T = SymTridiagonal(alpha[1:kk], beta[1:(kk - 1)])
    all(isfinite, T.dv) && all(isfinite, T.ev) || return NaN
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
probes, `slq_steps` matrix-free Lanczos steps each — while `log|R|` and `log|G|` are exact/cheap:

`ℓ = −½[(n−p)·log(2π) + n·log(σ²e) + Σᵢ(qᵢ·log(σᵢ²) − log|Aᵢ⁻¹|) + log|C| + yᵀPy]`,

with `log|Aᵢ⁻¹|` from a one-time sparse Cholesky of each `Aᵢ⁻¹` (the pedigree/identity precision —
far cheaper than `C`; an `O(q)` Mendelian route is a future scale optimization). The `log|C|`
term uses SLQ and `yᵀPy` uses a matrix-free PCG solve. It uses the SAME full-constant convention as
`sparse_multi_reml_loglik`, but has both SLQ approximation error and PCG solve error.

Returns `(loglik, loglik_mcse)` — the estimate and the between-probe Monte-Carlo standard error
for `log|C|`, scaled by ½ (`∝ 1/√slq_probes`). This MCSE does not measure finite-Lanczos
quadrature bias or PCG solve error, so it does not alone quantify total likelihood error or support
likelihood-ratio inference.

EXPERIMENTAL. The loglik is approximate and stochastic. At validation scale the exact
`sparse_multi_reml_loglik` is preferred. Requires a positive-definite `C`; failed
SLQ or nonfinite arithmetic throws an `ArgumentError` instead of reporting a
numeric likelihood. With one probe, the probe MCSE remains undefined (`NaN`).
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
    return _matrix_free_reml_loglik(y, X, effects, sigmas, sigma_e2;
        slq_probes = slq_probes, slq_steps = slq_steps, seed = seed,
        pcg_tol = pcg_tol, pcg_maxiter = pcg_maxiter,
        precision_logdetAinv = nothing)
end

function _matrix_free_reml_loglik(
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
    precision_logdetAinv,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    length(sigmas) == K || throw(ArgumentError("sigmas length must match number of effects"))
    ss = Float64.(collect(sigmas))
    all(s -> isfinite(s) && s > 0 && isfinite(inv(s)), ss) ||
        throw(ArgumentError("all sigmas must be finite, positive, and have finite Float64 precisions"))
    se2 = _finite_positive_variance_float64("sigma_e2", sigma_e2)
    pcg_tol = _finite_positive_float64("pcg_tol", pcg_tol)
    slq_probes >= 1 || throw(ArgumentError("slq_probes must be >= 1"))
    slq_steps >= 2 || throw(ArgumentError("slq_steps must be >= 2"))
    pcg_maxiter >= 1 || throw(ArgumentError("pcg_maxiter must be >= 1"))

    n = length(y)
    yv = _matrix_free_float64_data("y", y)
    Xs = sparse(_matrix_free_float64_data("X", X))
    size(Xs, 1) == n || throw(ArgumentError("X must have one row per record"))
    p = size(Xs, 2)
    p < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))
    _require_full_fixed_effect_rank(Xs)
    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    logdet_Ainv = precision_logdetAinv === nothing ? zeros(Float64, K) : precision_logdetAinv
    length(logdet_Ainv) == K || throw(ArgumentError("precision log-determinants length must match effects"))
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(Zs, sparse(_matrix_free_float64_data("Z[$i]", Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        if precision_logdetAinv === nothing
            Ainvs[end], factor = _validate_matrix_free_precision(Ainvs[end], i)
            logdet_Ainv[i] = logdet(factor)
        end
        push!(qs, qi)
    end
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
        logdetG += qs[i] * log(ss[i]) - logdet_Ainv[i]
    end

    # yᵀPy = (1/σ²e)·yᵀy − rhsᵀ·C⁻¹·rhs (the sparse MME identity), matrix-free.
    rhs = Vector{Float64}(undef, ntot)
    rhs[1:p] .= inv_se2 .* (Xt * yv)
    for i in 1:K
        rhs[(offs[i] + 1):(offs[i] + qs[i])] .= inv_se2 .* (Zts[i] * yv)
    end
    d = _multi_mme_diag(Xs, Zs, Ainvs, inv_se2, inv_sig, p, offs, qs, ntot)
    _require_finite_positive_mme_diag(d)
    invd = 1.0 ./ d
    sol, _, relres = _pcg_solve(applyC, copy(rhs); tol = Float64(pcg_tol),
                                maxiter = Int(pcg_maxiter), applyMinv = r -> invd .* r)
    _require_pcg_convergence(relres, pcg_tol)
    # Evaluate the minimized joint quadratic from fitted residuals and random
    # effects to avoid subtracting two large, nearly equal intercept terms.
    residual = yv - Xs * sol[1:p]
    quad = 0.0
    for i in 1:K
        ui = sol[(offs[i] + 1):(offs[i] + qs[i])]
        residual .-= Zs[i] * ui
        quad += dot(ui, Ainvs[i] * ui) / ss[i]
    end
    quad += inv_se2 * dot(residual, residual)
    _require_finite_matrix_free_result("REML quadratic", quad)

    # log|C| by SLQ (matrix-free).
    rng = MersenneTwister(seed)
    contribs = Float64[]
    for _ in 1:slq_probes
        z = rand(rng, (-1.0, 1.0), ntot)                      # Rademacher, ‖z‖²=ntot
        c = _lanczos_logquad(applyC, z, Int(slq_steps))
        isfinite(c) || throw(ArgumentError("SLQ could not produce a finite log determinant; check conditioning and arithmetic range"))
        push!(contribs, ntot * c)
    end
    logdetC, logdetC_mcse = _matrix_free_probe_summary(contribs)

    loglik = -0.5 * ((n - p) * log(2 * pi) + logdetR + logdetG + logdetC + quad)
    loglik_mcse = 0.5 * logdetC_mcse
    _require_finite_matrix_free_result("REML log likelihood", loglik)
    return (loglik, loglik_mcse)
end

"""
    matrix_free_reml_information(y, X, effects, sigmas, sigma_e2; pcg_tol = 1e-11, pcg_maxiter = 5000)

MATRIX-FREE average-information (AI) matrix of the `K`-independent-effect REML fit at the SUPPLIED
variance components — the `(K+1)×(K+1)` information over `[σ²₁, …, σ²_K, σ²e]` used for asymptotic
variance-component standard errors + ratio/`h²` intervals (v0.8 V8.3). It is EXACT (not stochastic):
unlike the score's trace term, the AI matrix `0.5·WᵀPW` is built purely from working-variate
`P`-projections (`W = [Z₁û₁/σ₁², …, Z_Kû_K/σ_K², ê/σ²e]`, with `W ∈ ℝ^{n × (K+1)}`, and `P·w` an MME re-solve), so it needs only matrix-free
solves — NO Hutchinson trace. It reproduces the exact Cholesky-factor AI matrix
(`fit_sparse_multi_effect_aireml`'s `information`) to the PCG tolerance.

Returns the `Symmetric` `(K+1)×(K+1)` AI matrix.
Nonfinite final information caused by unsupported arithmetic range throws an
`ArgumentError`; finite information is not a conditioning or calibration guarantee.
"""
function matrix_free_reml_information(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector,
    sigmas::AbstractVector,
    sigma_e2::Real;
    pcg_tol::Real = 1e-11,
    pcg_maxiter::Integer = 5000,
)
    K = length(effects)
    K >= 1 || throw(ArgumentError("at least one random effect is required"))
    length(sigmas) == K || throw(ArgumentError("sigmas length must match number of effects"))
    ss = Float64.(collect(sigmas))
    all(s -> isfinite(s) && s > 0 && isfinite(inv(s)), ss) ||
        throw(ArgumentError("all sigmas must be finite, positive, and have finite Float64 precisions"))
    se2 = _finite_positive_variance_float64("sigma_e2", sigma_e2)
    pcg_tol = _finite_positive_float64("pcg_tol", pcg_tol)
    pcg_maxiter >= 1 || throw(ArgumentError("pcg_maxiter must be >= 1"))
    n = length(y)
    yv = _matrix_free_float64_data("y", y)
    Xs = sparse(_matrix_free_float64_data("X", X))
    size(Xs, 1) == n || throw(ArgumentError("X must have one row per record"))
    p = size(Xs, 2)
    p < n || throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))
    _require_full_fixed_effect_rank(Xs)
    Zs = SparseMatrixCSC{Float64,Int}[]
    Ainvs = SparseMatrixCSC{Float64,Int}[]
    qs = Int[]
    for (i, pair) in enumerate(effects)
        Zi, Ainvi = pair
        size(Zi, 1) == n || throw(ArgumentError("Z[$i] must have one row per record"))
        qi = size(Ainvi, 1)
        size(Ainvi, 2) == qi || throw(ArgumentError("Ainv[$i] must be square"))
        size(Zi, 2) == qi || throw(ArgumentError("Z[$i] columns must match Ainv[$i] dimensions"))
        push!(Zs, sparse(_matrix_free_float64_data("Z[$i]", Zi)))
        push!(Ainvs, sparse(Float64.(Ainvi)))
        push!(qs, qi)
    end
    for i in eachindex(Ainvs)
        Ainvs[i], _ = _validate_matrix_free_precision(Ainvs[i], i)
    end
    inv_se2 = inv(se2); inv_sig = inv.(ss)
    offs = Vector{Int}(undef, K); acc = p
    for i in 1:K; offs[i] = acc; acc += qs[i]; end
    ntot = acc
    Xt = transpose(Xs); Zts = [transpose(Zs[i]) for i in 1:K]
    applyC = v -> _multi_mme_matvec(Xs, Xt, Zs, Zts, Ainvs, inv_se2, inv_sig, p, offs, qs, v)
    d = _multi_mme_diag(Xs, Zs, Ainvs, inv_se2, inv_sig, p, offs, qs, ntot)
    _require_finite_positive_mme_diag(d)
    invd = 1.0 ./ d
    applyMinv = r -> invd .* r

    # matrix-free solve of the RHS system for [β; u], then the residual e
    solve_rhs(w) = begin
        rr = Vector{Float64}(undef, ntot)
        rr[1:p] .= inv_se2 .* (Xt * w)
        for i in 1:K
            rr[(offs[i] + 1):(offs[i] + qs[i])] .= inv_se2 .* (Zts[i] * w)
        end
        xw, _, relres = _pcg_solve(applyC, rr; tol = Float64(pcg_tol), maxiter = Int(pcg_maxiter),
                                   applyMinv = applyMinv)
        _require_pcg_convergence(relres, pcg_tol)
        xw
    end
    sol = solve_rhs(yv)
    beta = sol[1:p]
    us = [sol[(offs[i] + 1):(offs[i] + qs[i])] for i in 1:K]
    e = yv .- Xs * beta
    for i in 1:K; e .-= Zs[i] * us[i]; end

    # working variates and their P-projections (P·w = (w − Xβ_w − Σ Zᵢu_{w,i})/σ²e)
    W = Matrix{Float64}(undef, n, K + 1)
    for i in 1:K; W[:, i] = (Zs[i] * us[i]) ./ ss[i]; end
    W[:, K + 1] = e ./ se2
    PW = Matrix{Float64}(undef, n, K + 1)
    for j in 1:(K + 1)
        w = @view W[:, j]
        xw = solve_rhs(Vector(w))
        pw = Vector(w) .- Xs * xw[1:p]
        for i in 1:K; pw .-= Zs[i] * xw[(offs[i] + 1):(offs[i] + qs[i])]; end
        PW[:, j] = pw ./ se2
    end
    information = 0.5 .* (transpose(W) * PW)
    _require_finite_matrix_free_result("REML average information", information)
    return Symmetric(information)
end

"""
    matrix_free_ratio_intervals(y, X, effects, sigmas, sigma_e2; level = 0.95,
                                boundary_tol = 1e-6, pcg_tol = 1e-11, pcg_maxiter = 5000)

Asymptotic delta-method variance-ratio intervals for the matrix-free `K`-effect fit (v0.8 V8.3) —
one per random effect (the animal-block ratio is narrow-sense `h²`; the others are
variance-explained proportions). Builds the matrix-free AI matrix
([`matrix_free_reml_information`](@ref)) at the supplied estimate and applies the same logit
delta-method (`_ratio_delta_ci`) as the exact `multi_effect_ratio_interval`. AI-based, ASYMPTOTIC,
NOT coverage-calibrated; boundary components (`σᵢ/total ≤ boundary_tol`) are flagged. Returns a
length-`K` vector of `(estimate, lower, upper, se, lower_clamped, upper_clamped, boundary)`.
"""
function matrix_free_ratio_intervals(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector,
    sigmas::AbstractVector,
    sigma_e2::Real;
    level::Real = 0.95,
    boundary_tol::Real = 1e-6,
    pcg_tol::Real = 1e-11,
    pcg_maxiter::Integer = 5000,
)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    boundary_tol = _validate_boundary_tol(boundary_tol)
    K = length(effects)
    info = matrix_free_reml_information(y, X, effects, sigmas, sigma_e2;
                                        pcg_tol = pcg_tol, pcg_maxiter = pcg_maxiter)
    theta = vcat(Float64.(collect(sigmas)), Float64(sigma_e2))
    return [_ratio_delta_ci(info, theta, i, level, boundary_tol) for i in 1:K]
end

"""
    fit_matrix_free_reml(spec; nprobe = 64, tol = 1e-4, iterations = 200, seed = 0,
                         pcg_tol = 1e-9, pcg_maxiter = 2000, initial = nothing,
                         shared_probes = false, compute_loglik = true)

MATRIX-FREE Monte-Carlo REML fixed-point fit of the SINGLE-effect Gaussian animal model (F6) — the
`AnimalModelFit`-returning single-effect face of [`fit_multi_effect_mc_reml`](@ref), for the
one regime where the exact sparse [`fit_ai_reml`](@ref) is measured-infeasible and the
eigen-once rescue is unavailable: **high fill-in AND `n` past the dense eigen cap**.

The mechanism it avoids is specific. `fit_ai_reml`'s per-iteration cost is dominated NOT by
the sparse Cholesky (cheap even at high fill — 0.35 s at q=20 000) but by the **Takahashi
selected inverse** that supplies its exact score trace `tr(A⁻¹C^uu)`, which scales with
`nnz(L)` and is recomputed every iteration (381 s per call at q=20 000, fill 471 — so the
whole fit walls at ~25 min; `docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`).
This fitter replaces that exact trace with the matrix-free Hutchinson estimator
[`mc_reml_block_traces`](@ref) and the MME solve with matrix-free PCG, so `C` is NEVER
assembled or factorized during the fit and the fill-in never materializes.

The estimator is therefore **STOCHASTIC**. A fixed probe `seed` is reused across iterations,
so the iteration is reproducible for a given seed. This wrapper returns an
`AnimalModelFit` and does not expose the low-level `trace_mcse` field. Use
[`fit_multi_effect_mc_reml`](@ref) to inspect trace Monte-Carlo error; that error is not a
gradient or variance-component standard error and excludes PCG solve error.

`compute_loglik = true` (default) evaluates the EXACT [`sparse_reml_loglik`](@ref) ONCE at the
returned estimate. That costs two sparse Choleskys and NO selected inverse — cheap relative
to the fit it just replaced — so the returned log-likelihood is exact, not stochastic. Set
`compute_loglik = false` (loglik `NaN`) to skip the final exact-likelihood
factorizations. The fit still validates each supplied relationship precision
as positive definite, which requires sparse Cholesky factorization.

Returns the standard [`AnimalModelFit`](@ref) (`target = :matrix_free_reml`), so the ordinary
extractors and the result payload work unchanged.

EXPERIMENTAL, REML-only, two-component, Gaussian-only. Ledger row `V1-MATFREE-REML`
(`validation_status()`, status `partial`) — read it before quoting any number from this fitter.

The pre-declared tail-scale known-truth recovery gate PASSED on 2026-09-01 at q = 25,000
(48/48 converged, mean relative error against generating truth 0.0016/0.0007 against a bound of
0.05; `docs/dev-log/recovery-checkpoints/2026-09-01-f6-matfree-tail-recovery-result.md`). That is
recovery-to-truth for the frozen gate fixture at that one scale — not at any other. The external
same-estimand REML comparator (ASReml-R 4.2.0.482,
`docs/dev-log/recovery-checkpoints/2026-07-28-asreml-matfree-comparator.md`) ran at q = 2000, below
the measured crossover, so an at-scale comparator in the high-fill tail is still **OWED** before
any covered claim.

**OPT-IN ONLY.** On this branch the fitter is reachable only by calling it directly:
`fit_animal_model` accepts `:variance_components`, `:sparse_reml`, `:ai_reml`, and
`:henderson_mme`, and there is no `:auto` REML router, so nothing can select this estimator on a
user's behalf. That is deliberate — the regime a route would serve is largely the one in which
this fitter has not been measured — and it is PINNED IN CI by the testset
`V1-MATFREE-REML opt-in fence`, so re-wiring a route in fails loudly rather than silently. That
fence covers this animal-model target router only; [`fit_multi_effect`](@ref)'s `:auto` is a
different estimator and does route to a matrix-free engine.
"""
function fit_matrix_free_reml(
    spec::AnimalModelSpec;
    nprobe::Integer = 64,
    tol::Real = 1e-4,
    iterations::Integer = 200,
    seed::Integer = 0,
    pcg_tol::Real = 1e-9,
    pcg_maxiter::Integer = 2000,
    initial = nothing,
    shared_probes::Bool = false,
    compute_loglik::Bool = true,
)
    spec.method == :REML ||
        throw(ArgumentError("fit_matrix_free_reml requires spec.method == :REML"))
    iterations >= 1 || throw(ArgumentError("iterations must be at least 1"))
    canonical_Ainv = _canonicalize_matrix_free_precision(sparse(Float64.(spec.Ainv)), 1)
    validated_spec = animal_model_spec(spec.y, spec.X, spec.Z, canonical_Ainv;
        ids = spec.ids, family = spec.family, method = spec.method,
        relationship_diag = spec.relationship_diag)
    n = length(spec.y)
    p = size(spec.X, 2)
    p < n ||
        throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    # The single-effect animal model is the K = 1 case of the matrix-free multi-effect
    # estimator; `initial` is translated from the animal-model (sigma_a2, sigma_e2) naming.
    mf_initial = initial === nothing ? nothing :
        begin
            sa2, se2 = _coerce_supplied_variance_components(initial)
            [sa2, se2]
        end
    fit = fit_multi_effect_mc_reml(validated_spec.y, validated_spec.X,
                                   [(validated_spec.Z, validated_spec.Ainv)];
                                   nprobe = nprobe, tol = tol, iterations = iterations,
                                   seed = seed, pcg_tol = pcg_tol, pcg_maxiter = pcg_maxiter,
                                   initial = mf_initial, ids = [collect(spec.ids)],
                                   shared_probes = shared_probes)
    sigma_a2 = fit.variance_components.sigmas[1]
    sigma_e2 = fit.variance_components.sigma_e2

    # Exact REML loglik at the returned estimate: two sparse Choleskys, NO selected inverse —
    # affordable precisely because the selinv (not the factorization) was the wall.
    likelihood = if compute_loglik && sigma_a2 > 0 && sigma_e2 > 0
        sparse_reml_loglik(validated_spec, sigma_a2, sigma_e2)
    else
        GaussianLikelihoodResult(NaN, Float64.(fit.beta), Float64(sigma_a2), Float64(sigma_e2),
                                 :REML, n, p)
    end

    return AnimalModelFit(
        validated_spec,
        likelihood,
        (sigma_a2 = Float64(sigma_a2), sigma_e2 = Float64(sigma_e2)),
        fit.converged,
        fit.converged ? "converged" : "not_converged",
        fit.iterations,
        :matrix_free_reml,
        false,
        true,
        :estimated_matrix_free_mc_reml,
    )
end

function _unused_exact_route_keywords(nprobe, shared_probes, compute_loglik, slq_probes, slq_steps, verbose)
    unused = String[]
    nprobe === nothing || push!(unused, "nprobe")
    shared_probes === nothing || push!(unused, "shared_probes")
    compute_loglik === nothing || push!(unused, "compute_loglik")
    slq_probes === nothing || push!(unused, "slq_probes")
    slq_steps === nothing || push!(unused, "slq_steps")
    verbose === nothing || push!(unused, "verbose")
    return unused
end

"""
    fit_multi_effect(y, X, effects; method = :auto, direct_max_n = 200_000, nprobe = 64,
                     verbose = true, kwargs...)

Fit the `K`-INDEPENDENT-effect Gaussian mixed model, automatically choosing the solver by
feasibility. This is the single entry point over the two multi-effect REML engines:

  - **exact** [`fit_sparse_multi_effect_aireml`](@ref) — sparse AI-REML, exact gradient (a
    Cholesky selected inverse each iteration). The default where feasible; limited by the K≥2
    environmental-group Cholesky fill-in at large `N`.
  - **matrix-free** [`fit_multi_effect_mc_reml`](@ref) — Monte-Carlo REML fixed-point iteration, never forms or
    factorizes `C` (matrix-free solves + Hutchinson trace). Feasible where the exact path is
    fill-limited, with Monte-Carlo error in the trace estimates (`trace_mcse`). This is not a
    variance-component standard error.

`method`:
  - `:auto` (default) — route on feasibility: `:exact` for a single random effect (`K = 1`, the
    animal-model MME stays sparse-feasible to very large `q`) OR when `N = p + Σqᵢ ≤ direct_max_n`;
    otherwise `:matrix_free`, with a `@info` message (unless `verbose = false`) noting the switch
    and that the trace estimates carry a Monte-Carlo standard error.
  - `:exact` / `:matrix_free` — force the engine (may OOM / accept MC noise respectively).

The `:auto` `direct_max_n` threshold is a **coarse, machine-agnostic heuristic** calibrated to the
measured K≥2 factorization cost (Phase 5 / v0.8-S2 benchmarks: the direct multi-effect Cholesky is
already ~quadratic by `q ≈ 50k` and infeasible past `~10⁵`–`10⁶`). It is deliberately conservative
and ALWAYS overridable; a precise symbolic-fill predictor is future work. Both engines return
`loglik`; it is exact for `:exact`, and `NaN` unless requested for `:matrix_free`, where it is a
stochastic estimate. The matrix-free result also returns `trace_mcse` for trace-estimation error.
The chosen engine's `NamedTuple` gains a `dispatch` field (`:exact` | `:matrix_free`) recording which ran.

EXPERIMENTAL. The multi-effect matrix-free result includes `loglik` (`NaN` unless requested,
stochastic when enabled) and `trace_mcse` for trace-estimation error. These describe different
quantities. `nprobe`, `shared_probes`, `compute_loglik`, `slq_probes`, `slq_steps`, and
`verbose` are used only on the matrix-free route; supplying one of them on the `:exact`
route is an error that names the unused keyword.
"""
function fit_multi_effect(
    y::AbstractVector,
    X::AbstractMatrix,
    effects::AbstractVector;
    method::Symbol = :auto,
    direct_max_n::Integer = 200_000,
    nprobe::Union{Nothing,Integer} = nothing,
    verbose::Union{Nothing,Bool} = nothing,
    shared_probes::Union{Nothing,Bool} = nothing,
    compute_loglik::Union{Nothing,Bool} = nothing,
    slq_probes::Union{Nothing,Integer} = nothing,
    slq_steps::Union{Nothing,Integer} = nothing,
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
        unused = _unused_exact_route_keywords(
            nprobe, shared_probes, compute_loglik, slq_probes, slq_steps, verbose,
        )
        isempty(unused) ||
            throw(ArgumentError("the :exact route does not use $(join(unused, ", "))"))
        res = fit_sparse_multi_effect_aireml(y, X, effects; kwargs...)
        return merge(res, (dispatch = :exact,))
    else
        nprobe_val = something(nprobe, 64)
        verbose_val = something(verbose, true)
        shared_probes_val = something(shared_probes, false)
        compute_loglik_val = something(compute_loglik, false)
        slq_probes_val = something(slq_probes, 20)
        slq_steps_val = something(slq_steps, 40)
        if verbose_val
            @info("fit_multi_effect: problem exceeds the direct-factorization budget " *
                  "(N=$N, K=$K > direct_max_n=$direct_max_n) — using matrix-free Monte-Carlo REML; " *
                  "trace estimates carry Monte-Carlo standard errors, not variance-component uncertainty. " *
                  "Override with method=:exact to force the exact (fill-limited) path.")
        end
        res = fit_multi_effect_mc_reml(y, X, effects; nprobe = nprobe_val, shared_probes = shared_probes_val,
                                       compute_loglik = compute_loglik_val, slq_probes = slq_probes_val,
                                       slq_steps = slq_steps_val, kwargs...)
        return merge(res, (dispatch = :matrix_free,))
    end
end

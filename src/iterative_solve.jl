# Iterative (conjugate-gradient) solve of the animal-model MME — the ITERATIVE companion
# of the direct `henderson_mme` factorization. PCG solves the IDENTICAL sparse SPD system
# `C·[β; u] = rhs` (from `_sparse_mme_system`) without forming a Cholesky factor; it is the
# algorithmic primitive the production large-pedigree path needs. Correctness-validated
# (matches the direct solve to a tight tolerance); NOT a production-scale performance claim.

# Preconditioned conjugate gradient for a symmetric positive-definite `C`. `Minv` is the
# Jacobi (diagonal) preconditioner as a vector of `1/diag(C)`, or `nothing` for plain CG.
# `x0 = 0`, so the initial residual is `b`. Returns `(x, iterations, relative_residual)`.
function _pcg_solve(C, b::Vector{Float64}; tol::Float64, maxiter::Int,
                    Minv::Union{Nothing,Vector{Float64}})
    x = zeros(length(b))
    r = copy(b)
    bnorm = norm(b)
    bnorm == 0 && return x, 0, 0.0
    z = Minv === nothing ? copy(r) : Minv .* r
    p = copy(z)
    rz = dot(r, z)
    iters = 0
    relres = norm(r) / bnorm
    for k in 1:maxiter
        Cp = C * p
        pCp = dot(p, Cp)
        pCp > 0 ||
            throw(ArgumentError("PCG hit non-positive curvature (pᵀCp = $(pCp)); the system is not positive definite"))
        alpha = rz / pCp
        @. x += alpha * p
        @. r -= alpha * Cp
        iters = k
        relres = norm(r) / bnorm
        relres <= tol && break
        z = Minv === nothing ? r : Minv .* r
        rz_new = dot(r, z)
        beta = rz_new / rz
        @. p = z + beta * p
        rz = rz_new
    end
    # Report the TRUE residual at the returned x (one extra matvec), not the
    # recursively-accumulated `r` — so `relative_residual`/`converged` are exactly
    # ‖b − Cx‖/‖b‖ regardless of any recursive-residual drift on ill-conditioned input.
    relres = norm(b - C * x) / bnorm
    return x, iters, relres
end

"""
    solve_animal_model_pcg(spec, sigma_a2, sigma_e2; tol = 1e-10, maxiter = 1000,
                           preconditioner = :jacobi)

Solve the supplied-variance Gaussian animal-model mixed-model equations by
**preconditioned conjugate gradient** — the ITERATIVE companion of the direct
[`henderson_mme`](@ref) factorization. It assembles the SAME sparse symmetric
positive-definite coefficient matrix `C` and right-hand side as `henderson_mme`
(`_sparse_mme_system`) and solves `C·[β; u] = rhs` iteratively, never forming a Cholesky
factor. `preconditioner = :jacobi` (default) uses the diagonal preconditioner
`M⁻¹ = 1/diag(C)`; `:none` is plain CG.

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
                                preconditioner::Symbol = :jacobi)
    sigma_a2 > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    tol > 0 || throw(ArgumentError("tol must be positive"))
    maxiter >= 1 || throw(ArgumentError("maxiter must be >= 1"))
    preconditioner in (:jacobi, :none) ||
        throw(ArgumentError("preconditioner must be :jacobi or :none"))

    lhs, rhs, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)
    d = Vector{Float64}(diag(lhs))
    all(>(0), d) ||
        throw(ArgumentError("MME diagonal has a non-positive entry; system is not positive definite"))
    Minv = preconditioner === :jacobi ? (1.0 ./ d) : nothing

    x, iters, relres = _pcg_solve(lhs, Vector{Float64}(rhs);
                                  tol = Float64(tol), maxiter = Int(maxiter), Minv = Minv)
    nfixed = size(spec.X, 2)
    return (
        beta = Vector{Float64}(x[1:nfixed]),
        breeding_values = (ids = collect(spec.ids), values = Vector{Float64}(x[(nfixed + 1):end])),
        iterations = iters,
        relative_residual = relres,
        converged = relres <= tol,
        preconditioner = preconditioner,
    )
end

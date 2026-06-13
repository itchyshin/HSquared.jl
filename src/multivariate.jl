# Multivariate (multi-trait) Gaussian animal model — Phase 4 start.
#
# Supplied-(co)variance Henderson MME for the balanced multi-trait animal model,
# the multivariate analogue of `henderson_mme` / `two_effect_mme`. It does NOT
# estimate the genetic/residual covariance matrices (that is a separate REML/EM
# slice). Experimental, validation-scale, engine-internal.

"""
    genetic_correlation(C::AbstractMatrix)
    genetic_correlation(result)

Convert a symmetric covariance matrix `C` (e.g. the additive genetic covariance
`G0` or residual covariance `R0`) into the corresponding correlation matrix
`D⁻¹ C D⁻¹`, with `D = diag(sqrt.(diag(C)))`. Diagonal entries are exactly `1`.

The second method extracts `genetic_correlation` from a
[`multivariate_mme`](@ref) result `NamedTuple`. Requires positive diagonal
variances.
"""
function genetic_correlation(C::AbstractMatrix)
    n = size(C, 1)
    size(C, 2) == n || throw(ArgumentError("C must be square"))
    d = diag(C)
    all(>(0), d) || throw(ArgumentError("covariance diagonal must be positive"))
    s = sqrt.(d)
    R = Matrix{Float64}(undef, n, n)
    @inbounds for j in 1:n, i in 1:n
        R[i, j] = C[i, j] / (s[i] * s[j])
    end
    for i in 1:n
        R[i, i] = 1.0
    end
    return R
end

genetic_correlation(result::NamedTuple) = result.genetic_correlation

function _check_covariance(M, name, t)
    size(M, 1) == t && size(M, 2) == t ||
        throw(ArgumentError("$name must be $t×$t (one row/column per trait)"))
    Mf = Float64.(Matrix(M))
    isapprox(Mf, transpose(Mf); atol = 1e-10) ||
        throw(ArgumentError("$name must be symmetric"))
    Ms = Symmetric(Mf)
    isposdef(Ms) || throw(ArgumentError("$name must be positive definite"))
    return Ms
end

# A trait record is "missing" if it is `missing` or a NaN float; everything else
# (including integers) is an observed value.
_is_present(x) = !(ismissing(x) || (x isa AbstractFloat && isnan(x)))

# Dense marginal-GLS reference for the balanced multivariate animal model
# (records ordered individual-major, trait fastest):
#   V = Z_full·(A ⊗ G0)·Z_full' + (I_n ⊗ R0),  A = Ainv⁻¹.
# Returns (beta_vec, u_vec) — the independent check on the MME assembly below.
function _multivariate_dense(yvec, Xfull, Zfull, A, G0, R0, n, t)
    AkG = kron(A, Matrix(G0))
    V = Symmetric(Zfull * AkG * transpose(Zfull) .+ kron(Matrix(1.0I, n, n), Matrix(R0)))
    Vf = cholesky(V)
    ViX = Vf \ Matrix(Xfull)
    XtViX = cholesky(Symmetric(transpose(Xfull) * ViX))
    beta = XtViX \ (transpose(Xfull) * (Vf \ yvec))
    r = yvec .- Xfull * beta
    u = AkG * (transpose(Zfull) * (Vf \ r))
    return Vector{Float64}(beta), Vector{Float64}(u)
end

"""
    multivariate_mme(Y, X, Z, Ainv, G0, R0; ids = nothing, traits = nothing)

Supplied-(co)variance Henderson solve of the **multi-trait** Gaussian animal
model. For `t` traits, `n` records, and `q` related animals:

    Y[i, :] = (X·B)[i, :] + (Z·U)[i, :] + E[i, :],
    vec(Uᵀ) ~ N(0, A ⊗ G0),   E[i, S_i] ~ N(0, R0[S_i, S_i]),

where `Y` is `n×t`, the shared fixed-effect design `X` is `n×p`, the shared
record→animal incidence `Z` is `n×q`, `Ainv = A⁻¹` is the `q×q` relationship
inverse, `G0` is the `t×t` additive genetic covariance, and `R0` is the `t×t`
residual covariance. Records are ordered individual-major with trait fastest, so
the mixed-model equations carry the genetic precision `Ainv ⊗ G0⁻¹` on the random
block and the residual precision `R⁻¹` (block-diagonal over individuals) on the
data:

    [ X'R⁻¹X    X'R⁻¹Z              ] [vec(Bᵀ)]   [ X'R⁻¹·y ]
    [ Z'R⁻¹X    Z'R⁻¹Z + Ainv⊗G0⁻¹ ] [vec(Uᵀ)] = [ Z'R⁻¹·y ]

**Unbalanced / missing-trait records** are supported: an entry of `Y` that is
`missing` or `NaN` marks an unobserved trait for that record. Such observations
are dropped from the data and individual `i`'s residual precision uses only the
observed-trait submatrix `inv(R0[S_i, S_i])` (where `S_i` is its observed-trait
set). With every trait observed this reduces to the balanced model with residual
precision `I_n ⊗ R0⁻¹`.

This is the Phase-4 (multivariate Gaussian) supplied-variance engine slice: an
MME solve that does **not** estimate `G0` / `R0` (covariance-matrix estimation is
a separate REML slice), the multi-trait analogue of [`henderson_mme`](@ref). It
assumes a fixed-effect / incidence design shared across traits; per-trait designs
are not covered. Experimental, dense/validation-scale, engine-internal — there is
no R-facing multivariate model-spec yet.

Returns a `NamedTuple`:

  - `beta` — `p×t` fixed effects (column `k` = trait `k`);
  - `breeding_values` — `(ids, traits, values)` with `values` the `q×t` EBV matrix
    (column `k` = trait `k`);
  - `genetic_covariance`, `residual_covariance` — the supplied `G0`, `R0`;
  - `genetic_correlation`, `residual_correlation` — derived `t×t` correlations;
  - `traits` — the trait labels.
"""
function multivariate_mme(
    Y::AbstractMatrix,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix,
    G0::AbstractMatrix,
    R0::AbstractMatrix;
    ids = nothing,
    traits = nothing,
)
    n = size(Y, 1)
    t = size(Y, 2)
    t >= 1 || throw(ArgumentError("Y must have at least one trait column"))
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Z, 1) == n || throw(ArgumentError("Z must have one row per record"))
    q = size(Ainv, 1)
    size(Ainv, 2) == q || throw(ArgumentError("Ainv must be square"))
    size(Z, 2) == q || throw(ArgumentError("Z columns must match Ainv dimensions"))
    G0s = _check_covariance(G0, "G0", t)
    R0s = _check_covariance(R0, "R0", t)
    aids = ids === nothing ? collect(1:q) : collect(ids)
    length(aids) == q || throw(ArgumentError("ids length must match Ainv dimensions"))
    tlabels = traits === nothing ? collect(1:t) : collect(traits)
    length(tlabels) == t || throw(ArgumentError("traits length must match Y columns"))

    p = size(X, 2)
    # observed-record mask (handles unbalanced / missing-trait records).
    Ym = Matrix(Y)
    present = falses(n, t)
    @inbounds for i in 1:n, k in 1:t
        present[i, k] = _is_present(Ym[i, k])
    end
    any(present) || throw(ArgumentError("Y has no observed (non-missing) entries"))
    Yfull = zeros(Float64, n, t)
    @inbounds for i in 1:n, k in 1:t
        present[i, k] && (Yfull[i, k] = Float64(Ym[i, k]))
    end

    It = sparse(1.0I, t, t)
    # individual-major (trait fastest) vectorization: vec of the transpose.
    Xfull = kron(sparse(Float64.(Matrix(X))), It)
    Zfull = kron(sparse(Float64.(Matrix(Z))), It)
    yvec = vec(permutedims(Yfull))
    Ginv_block = kron(sparse(Float64.(Matrix(Ainv))), sparse(inv(G0s)))

    if all(present)
        # balanced: a single Kronecker residual precision I_n ⊗ R0⁻¹.
        Rinv = kron(sparse(1.0I, n, n), sparse(inv(R0s)))
    else
        # unbalanced: keep observed rows; residual precision is block-diagonal
        # over individuals with individual i's block inv(R0[S_i, S_i]).
        maskvec = vec(permutedims(present))
        Xfull = Xfull[maskvec, :]
        Zfull = Zfull[maskvec, :]
        yvec = yvec[maskvec]
        blocks = SparseMatrixCSC{Float64,Int}[]
        for i in 1:n
            Si = findall(@view present[i, :])
            isempty(Si) && continue
            push!(blocks, sparse(inv(R0s[Si, Si])))
        end
        Rinv = blockdiag(blocks...)
    end

    Xt = transpose(Xfull)
    Zt = transpose(Zfull)
    XtRi = Xt * Rinv
    ZtRi = Zt * Rinv
    lhs = [
        XtRi * Xfull  XtRi * Zfull
        ZtRi * Xfull  ZtRi * Zfull + Ginv_block
    ]
    rhs = vcat(XtRi * yvec, ZtRi * yvec)
    solution = lhs \ rhs

    nfixed = p * t
    betavec = Vector{Float64}(solution[1:nfixed])
    uvec = Vector{Float64}(solution[(nfixed + 1):(nfixed + q * t)])
    # invert the trait-fastest vectorization back to (level × trait) matrices.
    beta = permutedims(reshape(betavec, t, p))
    ebv = permutedims(reshape(uvec, t, q))

    return (
        beta = beta,
        breeding_values = (ids = aids, traits = tlabels, values = ebv),
        genetic_covariance = Matrix(G0s),
        residual_covariance = Matrix(R0s),
        genetic_correlation = genetic_correlation(Matrix(G0s)),
        residual_correlation = genetic_correlation(Matrix(R0s)),
        traits = tlabels,
    )
end

# Pack/unpack a t×t PD covariance as an unconstrained vector through its lower
# Cholesky factor `L` (`cov = L·Lᵀ`), with log-diagonal entries so the diagonal
# stays positive. Length `t(t+1)/2`, column-major lower-triangular order.
function _chol_params_to_cov(v, t)
    L = zeros(eltype(v), t, t)
    idx = 1
    for j in 1:t, i in j:t
        L[i, j] = i == j ? exp(v[idx]) : v[idx]
        idx += 1
    end
    return L * transpose(L)
end

function _cov_to_chol_params(M::AbstractMatrix, t)
    L = cholesky(Symmetric(Matrix(Float64.(M)))).L
    v = Vector{Float64}(undef, t * (t + 1) ÷ 2)
    idx = 1
    for j in 1:t, i in j:t
        v[idx] = i == j ? log(L[i, j]) : L[i, j]
        idx += 1
    end
    return v
end

# Build the observed-data design for the multivariate model in trait-fastest
# order, dropping `missing`/`NaN` records. Returns the observed response `yvec`,
# the dense expanded `Xfull` (N×p·t) and `Zfull` (N×q·t), the per-individual
# `(row-range, observed-trait-set)` list `indiv` for the block-diagonal residual,
# and the observed count `N`.
function _mv_observed(Y, X, Z, n, t, q, p)
    Ym = Matrix(Y)
    present = falses(n, t)
    @inbounds for i in 1:n, k in 1:t
        present[i, k] = _is_present(Ym[i, k])
    end
    rows = [(i, k) for i in 1:n for k in 1:t if present[i, k]]
    N = length(rows)
    N > 0 || throw(ArgumentError("Y has no observed (non-missing) entries"))
    Xfull = zeros(N, p * t)
    Zfull = zeros(N, q * t)
    yvec = zeros(N)
    for (r, (i, k)) in enumerate(rows)
        yvec[r] = Float64(Ym[i, k])
        for j in 1:p
            Xfull[r, (j - 1) * t + k] = Float64(X[i, j])
        end
        for a in 1:q
            Zfull[r, (a - 1) * t + k] = Float64(Z[i, a])
        end
    end
    indiv = Tuple{UnitRange{Int},Vector{Int}}[]
    rstart = 0
    for i in 1:n
        Si = findall(@view present[i, :])
        isempty(Si) && continue
        m = length(Si)
        push!(indiv, (rstart + 1:rstart + m, Si))
        rstart += m
    end
    return yvec, Xfull, Zfull, indiv, N
end

# Cholesky factor of the marginal covariance `V = Zfull·(A⊗G0)·Zfull' + R`,
# with `R` block-diagonal over individuals (block `i` = `R0[Sᵢ, Sᵢ]`). `V` is PD
# whenever `R0` is PD, even if `G0` is only positive semidefinite (a boundary
# REML optimum), so this stays well-defined at the boundary.
function _mv_build_Vchol(Zfull, A, indiv, N, G0, R0)
    Vg = Zfull * kron(A, G0) * transpose(Zfull)
    R = zeros(N, N)
    for (rng, Si) in indiv
        R[rng, rng] = R0[Si, Si]
    end
    return cholesky(Symmetric(Vg .+ R))
end

# REML log-likelihood (up to an additive constant) at supplied `G0`, `R0`.
function _mv_reml_loglik_core(yvec, Xfull, Zfull, A, indiv, N, G0, R0)
    Vf = _mv_build_Vchol(Zfull, A, indiv, N, G0, R0)
    ViX = Vf \ Xfull
    XtViX = cholesky(Symmetric(transpose(Xfull) * ViX))
    beta = XtViX \ (transpose(Xfull) * (Vf \ yvec))
    r = yvec .- Xfull * beta
    return -0.5 * (logdet(Vf) + logdet(XtViX) + dot(r, Vf \ r))
end

# GLS fixed effects and BLUP breeding values at supplied `G0`, `R0`. Uses the
# marginal-model form `u = (A⊗G0)·Zfull'·V⁻¹·(y − Xβ̂)`, which equals the MME
# solution when `G0` is PD but also works when `G0` is singular (boundary).
function _mv_gls_blup(yvec, Xfull, Zfull, A, indiv, N, G0, R0, t, p, q)
    Vf = _mv_build_Vchol(Zfull, A, indiv, N, G0, R0)
    ViX = Vf \ Xfull
    XtViX = cholesky(Symmetric(transpose(Xfull) * ViX))
    betavec = XtViX \ (transpose(Xfull) * (Vf \ yvec))
    r = yvec .- Xfull * betavec
    uvec = kron(A, G0) * (transpose(Zfull) * (Vf \ r))
    return permutedims(reshape(betavec, t, p)), permutedims(reshape(uvec, t, q))
end

# Convenience: multivariate REML log-likelihood directly from model inputs at
# supplied covariances (rebuilds the observed structures). Used in validation.
function _multivariate_reml_loglik(Y, X, Z, Ainv, G0, R0)
    n = size(Y, 1); t = size(Y, 2); q = size(Ainv, 1); p = size(X, 2)
    A = inv(Symmetric(Matrix(Float64.(Matrix(Ainv)))))
    yvec, Xfull, Zfull, indiv, N = _mv_observed(Y, X, Z, n, t, q, p)
    return _mv_reml_loglik_core(yvec, Xfull, Zfull, A, indiv, N,
                                Matrix(Float64.(Matrix(G0))), Matrix(Float64.(Matrix(R0))))
end

"""
    fit_multivariate_reml(Y, X, Z, Ainv; initial = nothing, iterations = 2000,
                          ids = nothing, traits = nothing)

Estimate the genetic and residual covariance matrices `G0`, `R0` of the
multi-trait animal model by **dense REML**. Inputs match [`multivariate_mme`](@ref)
(balanced or with `missing`/`NaN` trait records); the marginal model is

    y ~ N(X·β, V),   V = Z_full·(A ⊗ G0)·Z_full' + R,

with `R` block-diagonal over individuals (individual `i`'s block `R0[Sᵢ, Sᵢ]`).
The REML log-likelihood `-½(log|V| + log|X'V⁻¹X| + (y−Xβ̂)'V⁻¹(y−Xβ̂))` is
maximized by Nelder–Mead over an unconstrained log-Cholesky parameterization of
`G0` and `R0` (which keeps both positive definite). At the optimum the breeding
values and fixed effects are obtained from [`multivariate_mme`](@ref) at the
estimated covariances.

Experimental, dense/validation-scale, REML-only, Gaussian. The REML estimator is
validated by deterministic self-consistency checks (the `t = 1` reduction recovers
the univariate REML estimate; the multivariate REML log-likelihood matches the
univariate one up to a constant; the optimum beats a coarse grid). Known-truth
covariance recovery for `t ≥ 2` is exercised only by one-off simulations (the test
suite is RNG-free) and has **not** had external-comparator (sommer / ASReml /
JWAS) parity or independent adversarial review yet — treat multi-trait variance
estimates as experimental. There is no R-facing multivariate model-spec.

Returns a `NamedTuple`:

  - `genetic_covariance`, `residual_covariance` — estimated `G0`, `R0` (`t×t`);
  - `genetic_correlation`, `residual_correlation` — derived `t×t` correlations;
  - `heritability` — per-trait `h² = diag(G0)/(diag(G0)+diag(R0))`;
  - `beta`, `breeding_values` — fixed effects and EBVs at the estimate;
  - `loglik`, `converged`, `iterations`, `traits`.
"""
function fit_multivariate_reml(
    Y::AbstractMatrix,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix;
    initial = nothing,
    iterations::Integer = 2_000,
    ids = nothing,
    traits = nothing,
)
    n = size(Y, 1)
    t = size(Y, 2)
    t >= 1 || throw(ArgumentError("Y must have at least one trait column"))
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Z, 1) == n || throw(ArgumentError("Z must have one row per record"))
    q = size(Ainv, 1)
    size(Ainv, 2) == q || throw(ArgumentError("Ainv must be square"))
    size(Z, 2) == q || throw(ArgumentError("Z columns must match Ainv dimensions"))

    p = size(X, 2)
    A = inv(Symmetric(Matrix(Float64.(Matrix(Ainv)))))
    yvec, Xfull, Zfull, indiv, N = _mv_observed(Y, X, Z, n, t, q, p)

    nG = t * (t + 1) ÷ 2

    function negloglik(params)
        G0 = _chol_params_to_cov(@view(params[1:nG]), t)
        R0 = _chol_params_to_cov(@view(params[nG + 1:end]), t)
        try
            return -_mv_reml_loglik_core(yvec, Xfull, Zfull, A, indiv, N, G0, R0)
        catch err
            err isa PosDefException && return Inf
            rethrow()
        end
    end

    if initial === nothing
        Ym = Matrix(Y)
        phen = ones(t)
        for k in 1:t
            vals = [Float64(Ym[i, k]) for i in 1:n if _is_present(Ym[i, k])]
            if length(vals) >= 2
                mu = sum(vals) / length(vals)
                v = sum(abs2, vals .- mu) / (length(vals) - 1)
                v > 0 && (phen[k] = v)
            end
        end
        G0_start = Matrix(Diagonal(0.5 .* phen))
        R0_start = Matrix(Diagonal(0.5 .* phen))
    else
        G0_start = Matrix(Float64.(Matrix(initial.G0)))
        R0_start = Matrix(Float64.(Matrix(initial.R0)))
    end
    params0 = vcat(_cov_to_chol_params(G0_start, t), _cov_to_chol_params(R0_start, t))

    result = optimize(negloglik, params0, NelderMead(), Optim.Options(iterations = iterations))
    phat = Optim.minimizer(result)
    G0hat = Matrix(Symmetric(_chol_params_to_cov(phat[1:nG], t)))
    R0hat = Matrix(Symmetric(_chol_params_to_cov(phat[nG + 1:end], t)))

    # EBVs via the GLS form (robust to a singular G0 at a boundary optimum).
    beta, ebv = _mv_gls_blup(yvec, Xfull, Zfull, A, indiv, N, G0hat, R0hat, t, p, q)
    aids = ids === nothing ? collect(1:q) : collect(ids)
    length(aids) == q || throw(ArgumentError("ids length must match Ainv dimensions"))
    tlabels = traits === nothing ? collect(1:t) : collect(traits)
    length(tlabels) == t || throw(ArgumentError("traits length must match Y columns"))
    hsq = [G0hat[k, k] / (G0hat[k, k] + R0hat[k, k]) for k in 1:t]

    return (
        genetic_covariance = G0hat,
        residual_covariance = R0hat,
        genetic_correlation = genetic_correlation(G0hat),
        residual_correlation = genetic_correlation(R0hat),
        heritability = hsq,
        beta = beta,
        breeding_values = (ids = aids, traits = tlabels, values = ebv),
        loglik = -Optim.minimum(result),
        converged = Optim.converged(result),
        iterations = Optim.iterations(result),
        traits = tlabels,
    )
end

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

Supplied-(co)variance Henderson solve of the **balanced multi-trait** Gaussian
animal model. For `t` traits, `n` records, and `q` related animals:

    Y[i, :] = (X·B)[i, :] + (Z·U)[i, :] + E[i, :],
    vec(Uᵀ) ~ N(0, A ⊗ G0),   vec(Eᵀ) ~ N(0, I_n ⊗ R0),

where `Y` is `n×t`, the shared fixed-effect design `X` is `n×p`, the shared
record→animal incidence `Z` is `n×q`, `Ainv = A⁻¹` is the `q×q` relationship
inverse, `G0` is the `t×t` additive genetic covariance, and `R0` is the `t×t`
residual covariance. Records are ordered individual-major with trait fastest, so
the mixed-model equations carry the genetic precision `Ainv ⊗ G0⁻¹` on the random
block and the residual precision `I_n ⊗ R0⁻¹` throughout:

    [ X'(I⊗R0⁻¹)X    X'(I⊗R0⁻¹)Z              ] [vec(Bᵀ)]   [ X'(I⊗R0⁻¹)·vec(Yᵀ) ]
    [ Z'(I⊗R0⁻¹)X    Z'(I⊗R0⁻¹)Z + Ainv⊗G0⁻¹ ] [vec(Uᵀ)] = [ Z'(I⊗R0⁻¹)·vec(Yᵀ) ]

This is the first Phase-4 (multivariate Gaussian) engine slice: a supplied-variance
MME solve that does **not** estimate `G0` / `R0`, the multi-trait analogue of
[`henderson_mme`](@ref). It assumes **balanced** data (every individual measured on
every trait) and a fixed-effect / incidence design shared across traits; unbalanced
/ missing-trait records, per-trait designs, and covariance-matrix estimation are not
covered. Experimental, dense/validation-scale, engine-internal — there is no R-facing
multivariate model-spec yet.

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
    It = sparse(1.0I, t, t)
    # individual-major (trait fastest) vectorization: vec of the transpose.
    yvec = vec(permutedims(Float64.(Matrix(Y))))
    Xfull = kron(sparse(Float64.(Matrix(X))), It)
    Zfull = kron(sparse(Float64.(Matrix(Z))), It)
    Rinv = kron(sparse(1.0I, n, n), sparse(inv(R0s)))
    Ginv_block = kron(sparse(Float64.(Matrix(Ainv))), sparse(inv(G0s)))

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

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
    isapprox(C, transpose(C)) || throw(ArgumentError("C must be symmetric"))
    d = diag(C)
    all(>(0), d) || throw(ArgumentError("covariance diagonal must be positive"))
    # allow rank-deficient PSD (e.g. low-rank G); reject only indefinite inputs
    eigmin(Symmetric(Matrix(Float64.(C)))) >= -1e-8 ||
        throw(ArgumentError("C must be positive semidefinite"))
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

function _require_multivariate_result(result::NamedTuple)
    ok = hasproperty(result, :genetic_covariance) &&
         hasproperty(result, :residual_covariance) &&
         hasproperty(result, :beta) &&
         hasproperty(result, :breeding_values)
    ok ||
        throw(ArgumentError("result is not a multivariate HSquared result"))
    return result
end

"""
    variance_components(result::NamedTuple)

Return the genetic and residual covariance matrices from a multivariate
`HSquared` result as `(genetic_covariance, residual_covariance)`.
"""
function variance_components(result::NamedTuple)
    r = _require_multivariate_result(result)
    return (
        genetic_covariance = copy(r.genetic_covariance),
        residual_covariance = copy(r.residual_covariance),
    )
end

"""
    fixed_effects(result::NamedTuple)

Return the fixed-effect matrix from a multivariate `HSquared` result.
"""
function fixed_effects(result::NamedTuple)
    return copy(_require_multivariate_result(result).beta)
end

"""
    breeding_values(result::NamedTuple)

Return the multivariate breeding-value metadata from a multivariate `HSquared`
result as `(ids, traits, values)`.
"""
function breeding_values(result::NamedTuple)
    bv = _require_multivariate_result(result).breeding_values
    ok = hasproperty(bv, :ids) && hasproperty(bv, :traits) && hasproperty(bv, :values)
    ok ||
        throw(ArgumentError("multivariate breeding_values metadata must contain ids, traits, and values"))
    return (
        ids = collect(bv.ids),
        traits = collect(bv.traits),
        values = copy(bv.values),
    )
end

"""
    heritability(result::NamedTuple)

Return the per-trait heritability vector from a multivariate REML result.
"""
function heritability(result::NamedTuple)
    r = _require_multivariate_result(result)
    hasproperty(r, :heritability) ||
        throw(ArgumentError("multivariate result does not contain heritability"))
    return copy(collect(r.heritability))
end

function _require_structured_genetic_metadata(result::NamedTuple)
    r = _require_multivariate_result(result)
    ok = hasproperty(r, :genetic_structure) &&
         hasproperty(r, :genetic_rank) &&
         hasproperty(r, :genetic_loadings) &&
         hasproperty(r, :genetic_uniqueness)
    ok ||
        throw(ArgumentError("multivariate result does not contain structured genetic metadata"))
    return r
end

"""
    genetic_structure(result::NamedTuple)

Return structured genetic covariance metadata from a multivariate REML result as
`(structure, rank)`.
"""
function genetic_structure(result::NamedTuple)
    r = _require_structured_genetic_metadata(result)
    return (structure = r.genetic_structure, rank = r.genetic_rank)
end

"""
    genetic_loadings(result::NamedTuple)

Return a copy of the structured genetic loading matrix from a low-rank or
factor-analytic multivariate REML result. Returns `nothing` when the fitted
structure has no loading matrix.
"""
function genetic_loadings(result::NamedTuple)
    L = _require_structured_genetic_metadata(result).genetic_loadings
    return isnothing(L) ? nothing : copy(L)
end

"""
    genetic_uniqueness(result::NamedTuple)

Return a copy of the structured genetic uniqueness vector from a multivariate
REML result. Returns `nothing` when the fitted structure has no uniqueness
metadata.
"""
function genetic_uniqueness(result::NamedTuple)
    ψ = _require_structured_genetic_metadata(result).genetic_uniqueness
    return isnothing(ψ) ? nothing : copy(collect(ψ))
end

"""
    multivariate_result_payload(result)

Bridge-ready, "boring" result payload (a `NamedTuple` of scalars / arrays /
nested `NamedTuple`s — Julia structs stay Julia-side) for a multivariate REML
fit from [`fit_multivariate_reml`](@ref). It mirrors [`result_payload`](@ref) for
the univariate animal model so the R twin can marshal one shape across traits.

Exposed only for the **rotation-free** genetic structures `:unstructured` and
`:diagonal`. `:lowrank` / `:factor_analytic` are rejected on purpose: their
loadings are rotation-nonidentified, so surfacing them across the bridge needs a
rotation/interpretation convention first. The payload carries the estimated
`G0`/`R0`, the per-trait genetic variances `diag(G0)`, the genetic/residual
correlations, the REML `loglik`, the genetic parameter count `n_genetic_params`
(so a `:diagonal`-vs-`:unstructured` LRT `df` is just the difference of the two
fits' counts), the fixed effects, breeding values, per-trait heritabilities, and
`converged`. It deliberately omits `genetic_loadings` / `genetic_uniqueness`.
"""
function multivariate_result_payload(result)
    s = getproperty(result, :genetic_structure)
    s in (:unstructured, :diagonal) || throw(ArgumentError(
        "multivariate_result_payload is bridge-exposed only for :unstructured and " *
        ":diagonal; :lowrank/:factor_analytic loadings are rotation-nonidentified " *
        "and gated on a rotation/interpretation convention"))
    G0 = Matrix(result.genetic_covariance)
    R0 = Matrix(result.residual_covariance)
    t = size(G0, 1)
    n_genetic_params = s == :diagonal ? t : t * (t + 1) ÷ 2
    bv = result.breeding_values
    return (
        engine = "HSquared.jl",
        target = "multivariate_reml",
        genetic_structure = String(s),
        n_traits = t,
        traits = collect(result.traits),
        genetic_covariance = G0,
        genetic_variances = diag(G0),
        residual_covariance = R0,
        genetic_correlation = Matrix(result.genetic_correlation),
        residual_correlation = Matrix(result.residual_correlation),
        heritability = copy(collect(result.heritability)),
        fixed_effects = Matrix(result.beta),
        breeding_values = (ids = bv.ids, traits = bv.traits, values = Matrix(bv.values)),
        loglik = result.loglik,
        n_genetic_params = n_genetic_params,
        converged = result.converged,
    )
end

"""
    structured_genetic_payload(result)

Bridge-ready, rotation-INVARIANT result payload for a `:lowrank` or
`:factor_analytic` multivariate REML fit from [`fit_multivariate_reml`](@ref) —
the rotation-gated companion of [`multivariate_result_payload`](@ref) (which serves
the rotation-free `:unstructured` / `:diagonal` structures).

The factor loadings of a low-rank / factor-analytic `G` are rotation-NONidentified
(`Λ` and `ΛQ` give the same `G`), so they are NEVER surfaced. Instead this exposes
only rotation-INVARIANT functionals of the estimated genetic covariance `G` (the FA
rotation convention, `docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`):
the reconstructed `G`, per-trait genetic variances / correlations, the genetic
eigenstructure ([`genetic_pca`](@ref): descending eigenvalues + sign-canonicalized
principal axes), `mean_evolvability`, and — for `:factor_analytic` — the specific
variances `Ψ` (`genetic_uniqueness`, which IS identified). Fixed effects, breeding
values, per-trait heritabilities, the REML `loglik`, and `converged` are
rotation-invariant and carried through. It deliberately OMITS `genetic_loadings`;
`rotation_invariant = true` and `loadings_excluded = true` make that self-describing.
"""
function structured_genetic_payload(result)
    hasproperty(result, :genetic_structure) ||
        throw(ArgumentError("structured_genetic_payload needs a multivariate REML result"))
    s = result.genetic_structure
    s in (:lowrank, :factor_analytic) || throw(ArgumentError(
        "structured_genetic_payload is for the rotation-gated :lowrank / " *
        ":factor_analytic structures; use multivariate_result_payload for " *
        ":unstructured / :diagonal"))
    r = _require_structured_genetic_metadata(result)
    G0 = Matrix(r.genetic_covariance)
    t = size(G0, 1)
    pca = genetic_pca(G0)
    ψ = r.genetic_uniqueness
    bv = r.breeding_values
    return (
        engine = "HSquared.jl",
        target = "multivariate_reml_structured",
        genetic_structure = String(s),
        genetic_rank = r.genetic_rank,
        n_traits = t,
        traits = collect(r.traits),
        genetic_covariance = G0,
        genetic_variances = diag(G0),
        genetic_correlation = Matrix(r.genetic_correlation),
        residual_covariance = Matrix(r.residual_covariance),
        residual_correlation = Matrix(r.residual_correlation),
        genetic_eigenvalues = pca.values,
        genetic_principal_axes = pca.vectors,
        mean_evolvability = mean_evolvability(G0),
        genetic_uniqueness = isnothing(ψ) ? nothing : copy(collect(ψ)),
        heritability = copy(collect(r.heritability)),
        fixed_effects = Matrix(r.beta),
        breeding_values = (ids = bv.ids, traits = bv.traits, values = Matrix(bv.values)),
        loglik = r.loglik,
        converged = r.converged,
        rotation_invariant = true,
        loadings_excluded = true,
    )
end

function _check_finite_matrix(M, name)
    Mf = Float64.(Matrix(M))
    all(isfinite, Mf) || throw(ArgumentError("$name must not contain Inf or NaN"))
    return Mf
end

function _check_covariance(M, name, t)
    size(M, 1) == t && size(M, 2) == t ||
        throw(ArgumentError("$name must be $t×$t (one row/column per trait)"))
    Mf = _check_finite_matrix(M, name)
    isapprox(Mf, transpose(Mf); atol = 1e-10) ||
        throw(ArgumentError("$name must be symmetric"))
    Ms = Symmetric(Mf)
    isposdef(Ms) || throw(ArgumentError("$name must be positive definite"))
    return Ms
end

"""
    diagonal_covariance(variances)

Build a diagonal trait covariance matrix from positive variance components.
This is the direct Julia engine utility for the Phase-4B `diag` genetic
covariance structure. It is a matrix builder only; it does not change the R
formula contract.
"""
function diagonal_covariance(variances)
    v = Float64.(collect(variances))
    !isempty(v) || throw(ArgumentError("variances must not be empty"))
    all(isfinite, v) || throw(ArgumentError("variances must not contain Inf or NaN"))
    all(>(0), v) || throw(ArgumentError("variances must be positive"))
    return Matrix(Diagonal(v))
end

"""
    lowrank_covariance(loadings)

Build a low-rank covariance matrix `ΛΛ'` from a `traits × rank` loading matrix
`Λ`. The result is positive semidefinite and may be singular when
`rank < traits`.
"""
function lowrank_covariance(loadings::AbstractMatrix)
    L = _check_finite_matrix(loadings, "loadings")
    size(L, 1) >= 1 || throw(ArgumentError("loadings must have at least one trait row"))
    size(L, 2) >= 1 || throw(ArgumentError("loadings must have at least one factor column"))
    C = L * transpose(L)
    all(>(0), diag(C)) || throw(ArgumentError("each trait must have positive low-rank genetic variance"))
    return C
end

"""
    factor_analytic_covariance(loadings, uniqueness)

Build a factor-analytic covariance matrix `ΛΛ' + Ψ`, where `Λ` is a
`traits × rank` loading matrix and `Ψ` is a positive diagonal uniqueness vector.
This is the direct Julia engine utility for the Phase-4B `fa(K)` covariance
structure.
"""
function factor_analytic_covariance(loadings::AbstractMatrix, uniqueness)
    L = _check_finite_matrix(loadings, "loadings")
    ψ = Float64.(collect(uniqueness))
    size(L, 1) >= 1 || throw(ArgumentError("loadings must have at least one trait row"))
    size(L, 2) >= 1 || throw(ArgumentError("loadings must have at least one factor column"))
    size(L, 1) == length(ψ) ||
        throw(ArgumentError("uniqueness length must match the number of loading rows"))
    all(isfinite, ψ) || throw(ArgumentError("uniqueness must not contain Inf or NaN"))
    all(>(0), ψ) || throw(ArgumentError("uniqueness values must be positive"))
    return L * transpose(L) + Diagonal(ψ)
end

function _canonicalize_loadings(loadings::AbstractMatrix)
    L = _check_finite_matrix(loadings, "loadings")
    size(L, 1) >= 1 || throw(ArgumentError("loadings must have at least one trait row"))
    size(L, 2) >= 1 || throw(ArgumentError("loadings must have at least one factor column"))
    for j in axes(L, 2)
        imax = firstindex(L, 1)
        maxabs = -Inf
        @inbounds for i in axes(L, 1)
            a = abs(L[i, j])
            if a > maxabs
                maxabs = a
                imax = i
            end
        end
        if L[imax, j] < 0
            @inbounds for i in axes(L, 1)
                L[i, j] = -L[i, j]
            end
        end
    end
    return L
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
precision `I_n ⊗ R0⁻¹`. A non-finite *observed* phenotype (`Inf` — only `missing`
/ `NaN` mark an unobserved trait), a non-finite `X`/`Z`/`Ainv`, or a trait with no
observed records is rejected with a clear `ArgumentError`.

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
    all(isfinite, Float64.(Matrix(Ainv))) || throw(ArgumentError("Ainv must not contain Inf or NaN"))
    _mv_validate_inputs(present, Ym, X, Z, tlabels)
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

function _validate_genetic_structure(genetic_structure::Symbol, rank, t)
    genetic_structure in (:unstructured, :diagonal, :lowrank, :factor_analytic) ||
        throw(ArgumentError("genetic_structure must be :unstructured, :diagonal, :lowrank, or :factor_analytic"))
    if genetic_structure in (:lowrank, :factor_analytic)
        rank === nothing && throw(ArgumentError("rank is required for $genetic_structure"))
        rank isa Integer || throw(ArgumentError("rank must be an integer"))
        1 <= rank <= t || throw(ArgumentError("rank must be between 1 and the number of traits"))
        return Int(rank)
    end
    rank === nothing || throw(ArgumentError("rank is only used for :lowrank and :factor_analytic"))
    return 0
end

function _structured_genetic_params_to_cov(params, t, genetic_structure::Symbol, rank::Int)
    if genetic_structure == :unstructured
        return _chol_params_to_cov(params, t), nothing, nothing
    elseif genetic_structure == :diagonal
        G0 = diagonal_covariance(exp.(params))
        return G0, nothing, diag(G0)
    elseif genetic_structure == :lowrank
        L = _canonicalize_loadings(reshape(collect(params), t, rank))
        # pure low-rank G = ΛΛ' has no specific (uniqueness) variance — signal that
        # with `nothing` rather than a misleading estimated-zero vector.
        return lowrank_covariance(L), L, nothing
    else
        nload = t * rank
        L = _canonicalize_loadings(reshape(collect(@view(params[1:nload])), t, rank))
        ψ = exp.(params[(nload + 1):end])
        return factor_analytic_covariance(L, ψ), L, ψ
    end
end

function _structured_genetic_params0(G0_start, genetic_structure::Symbol, rank::Int, t, initial)
    if genetic_structure == :unstructured
        return _cov_to_chol_params(G0_start, t)
    elseif genetic_structure == :diagonal
        return log.(diag(G0_start))
    end

    L = if initial !== nothing && hasproperty(initial, :loadings)
        L0 = _check_finite_matrix(initial.loadings, "initial.loadings")
        size(L0) == (t, rank) ||
            throw(ArgumentError("initial.loadings must be $t×$rank"))
        L0
    else
        L0 = zeros(t, rank)
        d = sqrt.(max.(diag(G0_start), eps(Float64)))
        for k in 1:t
            L0[k, ((k - 1) % rank) + 1] = d[k]
        end
        L0
    end

    if genetic_structure == :lowrank
        return vec(L)
    end

    ψ = if initial !== nothing && hasproperty(initial, :uniqueness)
        ψ0 = Float64.(collect(initial.uniqueness))
        length(ψ0) == t || throw(ArgumentError("initial.uniqueness length must match the number of traits"))
        all(isfinite, ψ0) || throw(ArgumentError("initial.uniqueness must not contain Inf or NaN"))
        all(>(0), ψ0) || throw(ArgumentError("initial.uniqueness values must be positive"))
        ψ0
    else
        max.(0.5 .* diag(G0_start), eps(Float64))
    end
    return vcat(vec(L), log.(ψ))
end

# Validate the observed data. `present` is the n×t observed mask. Throws a clear
# ArgumentError on a non-finite observed phenotype (e.g. Inf — only missing/NaN
# mark an unobserved trait), a non-finite entry of `X`/`Z`, or a trait with no
# observed records (which would otherwise surface as an opaque SingularException /
# PosDefException downstream). `tlabels` is used only for the message.
function _mv_validate_inputs(present, Ym, X, Z, tlabels)
    n, t = size(present)
    @inbounds for i in 1:n, k in 1:t
        if present[i, k] && !isfinite(Float64(Ym[i, k]))
            throw(ArgumentError(
                "Y[$i, $k] (trait $(tlabels[k])) is not finite; mark unobserved traits with `missing` or `NaN`, not Inf"))
        end
    end
    all(isfinite, Float64.(Matrix(X))) || throw(ArgumentError("X must not contain Inf or NaN"))
    all(isfinite, Float64.(Matrix(Z))) || throw(ArgumentError("Z must not contain Inf or NaN"))
    for k in 1:t
        any(@view present[:, k]) ||
            throw(ArgumentError("trait $(tlabels[k]) has no observed records; drop it before fitting"))
    end
    return nothing
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
    any(present) || throw(ArgumentError("Y has no observed (non-missing) entries"))
    _mv_validate_inputs(present, Ym, X, Z, 1:t)
    rows = [(i, k) for i in 1:n for k in 1:t if present[i, k]]
    N = length(rows)
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

# Full REML log-likelihood at supplied `G0`, `R0`, INCLUDING the `(N − p')·log(2π)`
# constant (`p' = ncol(Xfull)`), so it is on the same scale as `gaussian_loglik`
# and `sparse_reml_loglik` and is safe to compare across the package (LRT/AIC).
function _mv_reml_loglik_core(yvec, Xfull, Zfull, A, indiv, N, G0, R0)
    Vf = _mv_build_Vchol(Zfull, A, indiv, N, G0, R0)
    ViX = Vf \ Xfull
    XtViX = cholesky(Symmetric(transpose(Xfull) * ViX))
    beta = XtViX \ (transpose(Xfull) * (Vf \ yvec))
    r = yvec .- Xfull * beta
    nfix = size(Xfull, 2)
    return -0.5 * ((N - nfix) * log(2π) + logdet(Vf) + logdet(XtViX) + dot(r, Vf \ r))
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
                          ids = nothing, traits = nothing,
                          genetic_structure = :unstructured, rank = nothing)

Estimate the genetic and residual covariance matrices `G0`, `R0` of the
multi-trait animal model by **dense REML**. Inputs match [`multivariate_mme`](@ref)
(balanced or with `missing`/`NaN` trait records); the marginal model is

    y ~ N(X·β, V),   V = Z_full·(A ⊗ G0)·Z_full' + R,

with `R` block-diagonal over individuals (individual `i`'s block `R0[Sᵢ, Sᵢ]`).
The REML log-likelihood is maximized by Nelder–Mead. The default
`:unstructured` fit uses a log-Cholesky parameterization for both `G0` and `R0`;
structured fits constrain only the additive genetic covariance and keep `R0`
unstructured positive definite. At the optimum the breeding values and fixed
effects are computed from the marginal GLS BLUP form, which remains defined for
low-rank genetic covariances.

The additive genetic covariance can be constrained with `genetic_structure`:

  - `:unstructured` (default) — full positive-definite `G0`;
  - `:diagonal` — independent trait-specific genetic variances;
  - `:lowrank` — `G0 = ΛΛ'`, requiring `rank`;
  - `:factor_analytic` — `G0 = ΛΛ' + Ψ`, requiring `rank` and positive diagonal
    uniquenesses.

For structured fits, `initial` may supply `G0`, `R0`, `loadings`
(`traits × rank`), and `uniqueness` for `:factor_analytic`; omitted fields use
deterministic phenotypic-scale defaults.

Returned `genetic_loadings` use a deterministic sign convention: for each factor
column, the largest-absolute loading is non-negative. This removes arbitrary
sign flips from returned metadata but does not impose a rotation or
lower-triangular identification constraint; for `rank > 1`, loadings remain
rotation-nonunique and should not be interpreted as uniquely identified factors.

Experimental, dense/validation-scale, REML-only, Gaussian. The REML estimator is
validated by deterministic self-consistency checks (the `t = 1` reduction
recovers the univariate REML estimate; the multivariate REML log-likelihood is on
the same full-constant scale as the univariate one; the optimum beats a coarse
grid). Known-truth covariance recovery for `t ≥ 2` is exercised only by one-off
simulations (the test suite is RNG-free), and external-comparator (sommer /
ASReml / JWAS) parity is still missing — treat multi-trait variance estimates as
experimental. There is no R-facing multivariate model-spec.

Returns a `NamedTuple`:

  - `genetic_covariance`, `residual_covariance` — estimated `G0`, `R0` (`t×t`);
  - `genetic_correlation`, `residual_correlation` — derived `t×t` correlations;
  - `heritability` — per-trait `h² = diag(G0)/(diag(G0)+diag(R0))`;
  - `beta`, `breeding_values` — fixed effects and EBVs at the estimate;
  - `genetic_structure`, `genetic_rank`, `genetic_loadings`,
    `genetic_uniqueness` — structure metadata (`nothing` where not applicable);
  - `loglik` — the full REML log-likelihood at the estimate, including the
    `(N − p')·log(2π)` constant, so it is on the same scale as
    [`gaussian_loglik`](@ref) / [`sparse_reml_loglik`](@ref) (safe for LRT/AIC);
  - `converged`, `iterations`, `traits`.

Non-finite or empty-trait inputs are rejected up front (see
[`multivariate_mme`](@ref)), so the optimizer never returns plausible-looking
covariances from `Inf`/`NaN` data; check `converged` for genuine boundary cases.
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
    genetic_structure::Symbol = :unstructured,
    rank = nothing,
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
    all(isfinite, Float64.(Matrix(Ainv))) || throw(ArgumentError("Ainv must not contain Inf or NaN"))
    A = inv(Symmetric(Matrix(Float64.(Matrix(Ainv)))))
    yvec, Xfull, Zfull, indiv, N = _mv_observed(Y, X, Z, n, t, q, p)

    grank = _validate_genetic_structure(genetic_structure, rank, t)
    ngen = if genetic_structure == :unstructured
        t * (t + 1) ÷ 2
    elseif genetic_structure == :diagonal
        t
    elseif genetic_structure == :lowrank
        t * grank
    else
        t * grank + t
    end

    function negloglik(params)
        G0, _, _ = _structured_genetic_params_to_cov(@view(params[1:ngen]), t, genetic_structure, grank)
        R0 = _chol_params_to_cov(@view(params[ngen + 1:end]), t)
        try
            return -_mv_reml_loglik_core(yvec, Xfull, Zfull, A, indiv, N, G0, R0)
        catch err
            (err isa PosDefException || err isa ArgumentError) && return Inf
            rethrow()
        end
    end

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

    if initial === nothing
        G0_start = Matrix(Diagonal(0.5 .* phen))
        R0_start = Matrix(Diagonal(0.5 .* phen))
    else
        G0_start = hasproperty(initial, :G0) ? Matrix(Float64.(Matrix(initial.G0))) : Matrix(Diagonal(0.5 .* phen))
        R0_start = hasproperty(initial, :R0) ? Matrix(Float64.(Matrix(initial.R0))) : Matrix(Diagonal(0.5 .* phen))
    end
    _check_covariance(R0_start, "initial.R0", t)
    if genetic_structure in (:unstructured, :diagonal) ||
            (initial !== nothing && hasproperty(initial, :G0))
        _check_covariance(G0_start, "initial.G0", t)
    end
    params0 = vcat(
        _structured_genetic_params0(G0_start, genetic_structure, grank, t, initial),
        _cov_to_chol_params(R0_start, t),
    )

    result = optimize(negloglik, params0, NelderMead(), Optim.Options(iterations = iterations))
    phat = Optim.minimizer(result)
    G0raw, Lhat, ψhat = _structured_genetic_params_to_cov(phat[1:ngen], t, genetic_structure, grank)
    G0hat = Matrix(Symmetric(G0raw))
    R0hat = Matrix(Symmetric(_chol_params_to_cov(phat[ngen + 1:end], t)))

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
        genetic_structure = genetic_structure,
        genetic_rank = genetic_structure in (:lowrank, :factor_analytic) ? grank : nothing,
        genetic_loadings = Lhat,
        genetic_uniqueness = ψhat,
        loglik = -Optim.minimum(result),
        converged = Optim.converged(result),
        iterations = Optim.iterations(result),
        traits = tlabels,
    )
end

# ---------------------------------------------------------------------------
# Covariance standard errors + likelihood-ratio tests (V4-MV-REML / V4-FA gap)
# ---------------------------------------------------------------------------
# Asymptotic, observed-information + delta-method standard errors for the
# unstructured multivariate REML estimate, and a likelihood-ratio test for
# nested genetic-covariance structures. Both are dense/validation-scale and
# REML-based; the SEs are computed from a finite-difference observed-information
# matrix on the log-Cholesky parameterization (the same scale the optimizer
# uses), mirroring the univariate V1-HERIT-CI machinery.

# Lanczos log-gamma (g = 7); valid for real x. Used only for the chi-square
# survival function below (the package avoids a SpecialFunctions dependency).
function _loggamma(x::Real)
    g = 7.0
    c = (0.99999999999980993, 676.5203681218851, -1259.1392167224028,
         771.32342877765313, -176.61502916214059, 12.507343278686905,
         -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7)
    if x < 0.5
        return log(π / sin(π * x)) - _loggamma(1 - x)
    end
    x -= 1
    a = c[1]
    tt = x + g + 0.5
    @inbounds for i in 2:9
        a += c[i] / (x + (i - 1))
    end
    return 0.5 * log(2π) + (x + 0.5) * log(tt) - tt + log(a)
end

# Regularized lower incomplete gamma P(a, x) by series (x < a + 1).
function _reg_gamma_p_series(a::Real, x::Real)
    ap = a
    del = 1.0 / a
    s = del
    @inbounds for _ in 1:1000
        ap += 1.0
        del *= x / ap
        s += del
        abs(del) < abs(s) * 1e-15 && break
    end
    return s * exp(-x + a * log(x) - _loggamma(a))
end

# Regularized upper incomplete gamma Q(a, x) by continued fraction (x >= a + 1).
function _reg_gamma_q_cf(a::Real, x::Real)
    tiny = 1e-300
    b = x + 1.0 - a
    cc = 1.0 / tiny
    d = 1.0 / b
    h = d
    @inbounds for i in 1:1000
        an = -i * (i - a)
        b += 2.0
        d = an * d + b
        abs(d) < tiny && (d = tiny)
        cc = b + an / cc
        abs(cc) < tiny && (cc = tiny)
        d = 1.0 / d
        del = d * cc
        h *= del
        abs(del - 1.0) < 1e-15 && break
    end
    return exp(-x + a * log(x) - _loggamma(a)) * h
end

# Upper-tail (survival) of the chi-square distribution: P(χ²_k > x).
function _chisq_sf(x::Real, k::Real)
    k > 0 || throw(ArgumentError("degrees of freedom must be positive"))
    x <= 0 && return 1.0
    a = k / 2
    z = x / 2
    return z < a + 1 ? 1.0 - _reg_gamma_p_series(a, z) : _reg_gamma_q_cf(a, z)
end

"""
    nested_lrt(loglik_constrained, loglik_full; df, boundary_df = 0, label = "LRT")

Fit-agnostic likelihood-ratio test helper. The statistic is
`2·(loglik_full − loglik_constrained)`; the reference distribution depends on
`boundary_df`, the number of constrained parameters lying ON a boundary of the
full parameter space under the null:

- `boundary_df = 0` (interior null): plain `χ²_df` tail — exact asymptotics.
- `boundary_df = 1` (one parameter on its boundary, e.g. a variance fixed at 0):
  the 50:50 chi-bar-squared mixture `½·χ²_df + ½·χ²_{df−1}` (Self & Liang 1987;
  Stram & Lee 1994) — anti-conservative relative to the naive `χ²_df`.
- `boundary_df ≥ 2`: no closed-form chi-bar weights, so the naive `χ²_df` p-value
  is returned and flagged conservative (`mixture = :chisq_conservative`).

Returns `(statistic, df, boundary_df, pvalue, boundary, mixture, note)`. Asymptotic
theory only — the single-boundary mixture is textbook, not recovery-calibrated.
"""
function nested_lrt(loglik_constrained::Real, loglik_full::Real; df::Integer,
                    boundary_df::Integer = 0, label::AbstractString = "LRT")
    df > 0 ||
        throw(ArgumentError("`full` must have more parameters than `constrained` (df = $df)"))
    0 <= boundary_df <= df ||
        throw(ArgumentError("boundary_df must be in 0:df (got boundary_df = $boundary_df, df = $df)"))
    statistic = 2 * (Float64(loglik_full) - Float64(loglik_constrained))
    s = max(statistic, 0.0)
    # χ² tail with the df = 0 edge as a point mass at 0 (tail 0 for s>0, 1 for s==0)
    chisq_tail(x, k) = k == 0 ? (x > 0 ? 0.0 : 1.0) : _chisq_sf(x, k)
    if boundary_df == 0
        pvalue = _chisq_sf(s, df)
        mixture = :chisq
    elseif boundary_df == 1
        pvalue = 0.5 * chisq_tail(s, df) + 0.5 * chisq_tail(s, df - 1)
        mixture = :chibar_5050
    else
        pvalue = _chisq_sf(s, df)
        mixture = :chisq_conservative
    end
    note = if statistic < -1e-6
        "$label: negative statistic ($(round(statistic, digits = 6))): `full` did not dominate `constrained` — check nesting and convergence"
    elseif boundary_df == 0
        "$label: interior null; χ²_$df asymptotics apply"
    elseif boundary_df == 1
        "$label: one boundary parameter; 50:50 chi-bar-squared mixture (Self & Liang 1987; Stram & Lee 1994)"
    else
        "$label: $boundary_df-parameter boundary null has no closed-form chi-bar weights; reported χ²_$df p-value is conservative"
    end
    return (statistic = statistic, df = df, boundary_df = boundary_df, pvalue = pvalue,
            boundary = boundary_df > 0, mixture = mixture, note = note)
end

# Central finite-difference Hessian of a scalar function.
function _fd_hessian(f, x::AbstractVector; h::Real = 1e-4)
    n = length(x)
    H = zeros(n, n)
    f0 = f(x)
    @inbounds for i in 1:n
        xp = collect(float.(x)); xp[i] += h
        xm = collect(float.(x)); xm[i] -= h
        H[i, i] = (f(xp) - 2 * f0 + f(xm)) / h^2
    end
    @inbounds for i in 1:n, j in (i + 1):n
        xpp = collect(float.(x)); xpp[i] += h; xpp[j] += h
        xpm = collect(float.(x)); xpm[i] += h; xpm[j] -= h
        xmp = collect(float.(x)); xmp[i] -= h; xmp[j] += h
        xmm = collect(float.(x)); xmm[i] -= h; xmm[j] -= h
        H[i, j] = (f(xpp) - f(xpm) - f(xmp) + f(xmm)) / (4 * h^2)
        H[j, i] = H[i, j]
    end
    return H
end

# Central finite-difference Jacobian of a vector-valued function.
function _fd_jacobian(g, x::AbstractVector; h::Real = 1e-4)
    n = length(x)
    g0 = g(x)
    m = length(g0)
    J = zeros(m, n)
    @inbounds for j in 1:n
        xp = collect(float.(x)); xp[j] += h
        xm = collect(float.(x)); xm[j] -= h
        J[:, j] = (g(xp) .- g(xm)) ./ (2 * h)
    end
    return J
end

# Flattened quantities of interest from a log-Cholesky parameter vector:
# [G0 lower-triangle; R0 lower-triangle; genetic-corr strict-lower;
#  residual-corr strict-lower; per-trait h²].
function _mv_quantities(θ::AbstractVector, t::Int, ng::Int)
    G = _chol_params_to_cov(@view(θ[1:ng]), t)
    R = _chol_params_to_cov(@view(θ[ng + 1:end]), t)
    rg = genetic_correlation(Matrix(G))
    rr = genetic_correlation(Matrix(R))
    out = Float64[]
    for j in 1:t, i in j:t; push!(out, G[i, j]); end
    for j in 1:t, i in j:t; push!(out, R[i, j]); end
    for j in 1:t, i in (j + 1):t; push!(out, rg[i, j]); end
    for j in 1:t, i in (j + 1):t; push!(out, rr[i, j]); end
    for k in 1:t; push!(out, G[k, k] / (G[k, k] + R[k, k])); end
    return out
end

"""
    multivariate_covariance_standard_errors(fit, Y, X, Z, Ainv; fd_step = 1e-4)

Asymptotic standard errors for an **unstructured** multivariate REML fit
([`fit_multivariate_reml`](@ref)). Pass the same `Y, X, Z, Ainv` used for the
fit. Standard errors come from the observed-information matrix (a central
finite-difference Hessian of the REML log-likelihood on the log-Cholesky
parameterization, the scale the optimizer uses) propagated through the delta
method to the genetic/residual covariances, the derived correlations, and the
per-trait heritabilities.

Returns a `NamedTuple` of `t×t` SE matrices `genetic_covariance`,
`residual_covariance`, `genetic_correlation`, `residual_correlation`
(correlation-SE diagonals are `0`), the length-`t` `heritability` SE vector, and
the raw `information` matrix.

Experimental, asymptotic, dense/validation-scale, REML-only. SEs are
finite-difference approximations and are wide/unreliable at small `n`; not
coverage-calibrated. Throws if the observed information is not finite
positive-definite (a flat or boundary optimum). Structured/factor-analytic fits
are **not** supported — their loadings are rotation-nonidentified.
"""
function multivariate_covariance_standard_errors(fit, Y, X, Z, Ainv; fd_step::Real = 1e-4)
    getproperty(fit, :genetic_structure) == :unstructured ||
        throw(ArgumentError("covariance standard errors are implemented for the :unstructured fit only; structured/factor-analytic loadings are rotation-nonidentified"))
    G0 = Matrix(Float64.(Matrix(fit.genetic_covariance)))
    R0 = Matrix(Float64.(Matrix(fit.residual_covariance)))
    t = size(G0, 1)
    ng = t * (t + 1) ÷ 2
    phat = vcat(_cov_to_chol_params(G0, t), _cov_to_chol_params(R0, t))
    loglik(θ) = _multivariate_reml_loglik(Y, X, Z, Ainv,
        _chol_params_to_cov(@view(θ[1:ng]), t),
        _chol_params_to_cov(@view(θ[ng + 1:end]), t))
    H = -_fd_hessian(loglik, phat; h = fd_step)
    Hsym = Symmetric((H + transpose(H)) / 2)
    (all(isfinite, H) && isposdef(Hsym)) ||
        throw(ArgumentError("observed information is not finite positive-definite at the estimate (flat/boundary optimum); standard errors are unavailable"))
    Σθ = inv(Hsym)
    J = _fd_jacobian(θ -> _mv_quantities(θ, t, ng), phat; h = fd_step)
    Σg = J * Σθ * transpose(J)
    se = sqrt.(max.(diag(Σg), 0.0))

    seG = zeros(t, t); seR = zeros(t, t); seRG = zeros(t, t); seRR = zeros(t, t)
    idx = 1
    for j in 1:t, i in j:t; seG[i, j] = se[idx]; seG[j, i] = se[idx]; idx += 1; end
    for j in 1:t, i in j:t; seR[i, j] = se[idx]; seR[j, i] = se[idx]; idx += 1; end
    for j in 1:t, i in (j + 1):t; seRG[i, j] = se[idx]; seRG[j, i] = se[idx]; idx += 1; end
    for j in 1:t, i in (j + 1):t; seRR[i, j] = se[idx]; seRR[j, i] = se[idx]; idx += 1; end
    seh2 = se[idx:idx + t - 1]

    return (
        genetic_covariance = seG,
        residual_covariance = seR,
        genetic_correlation = seRG,
        residual_correlation = seRR,
        heritability = collect(seh2),
        information = Matrix(Hsym),
    )
end

function _mv_nparams(fit)
    t = size(Matrix(fit.genetic_covariance), 1)
    s = getproperty(fit, :genetic_structure)
    r = getproperty(fit, :genetic_rank)
    ngen = if s == :unstructured
        t * (t + 1) ÷ 2
    elseif s == :diagonal
        t
    elseif s == :lowrank
        t * Int(r)
    elseif s == :factor_analytic
        t * Int(r) + t
    else
        throw(ArgumentError("unknown genetic_structure $s"))
    end
    return ngen + t * (t + 1) ÷ 2  # R0 is always unstructured
end

"""
    covariance_structure_lrt(constrained, full)

Likelihood-ratio test comparing a nested constrained genetic-covariance fit
against the `full` (less-constrained) fit, both from
[`fit_multivariate_reml`](@ref) on the **same data**. Returns a `NamedTuple`
with the LRT `statistic` `= 2(ℓ_full − ℓ_constrained)`, the parameter-count
difference `df`, the asymptotic χ²`df` `pvalue`, a `boundary` flag, and a `note`.

The χ²`df` reference is exact only for an **interior** null — testing whether the
off-diagonal genetic covariances are zero (`:diagonal` nested in
`:unstructured`), where the constrained parameters lie in the interior of the
full space (`boundary = false`). For **rank/PSD-boundary** nulls
(`:lowrank`/`:factor_analytic` nested in `:unstructured`), the true null
distribution is a χ² mixture, so the reported χ²`df` p-value is asymptotically
**conservative** (`boundary = true`). Experimental, asymptotic,
dense/validation-scale.
"""
function covariance_structure_lrt(constrained, full)
    npc = _mv_nparams(constrained)
    npf = _mv_nparams(full)
    df = npf - npc
    df > 0 ||
        throw(ArgumentError("`full` must have more covariance parameters than `constrained` (df = $df); call as covariance_structure_lrt(constrained, full)"))
    sc = getproperty(constrained, :genetic_structure)
    sf = getproperty(full, :genetic_structure)
    interior = sc == :diagonal && sf == :unstructured
    # interior (:diagonal in :unstructured) -> χ²_df; rank/PSD boundary
    # (:lowrank/:factor_analytic) -> flagged-conservative naive χ² (multi-parameter
    # boundary, no closed-form chi-bar weights). Delegates the statistic + tail to
    # `nested_lrt`; both arms reproduce the previous output bit-for-bit.
    res = nested_lrt(constrained.loglik, full.loglik; df = df,
                     boundary_df = interior ? 0 : df, label = "covariance_structure_lrt")
    stat = res.statistic
    boundary = !interior
    note = if stat < -1e-6
        "negative statistic ($(round(stat, digits = 6))): `full` did not dominate `constrained` — check they are nested and both converged"
    elseif boundary
        "rank/PSD-boundary null: the χ²_$df p-value is asymptotically conservative (true null is a χ² mixture)"
    else
        "interior null (off-diagonal genetic covariances = 0): χ²_$df asymptotics apply"
    end
    return (statistic = stat, df = df, pvalue = res.pvalue, boundary = boundary, note = note)
end

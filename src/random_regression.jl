# Random regression / reaction norms (Phase 3, #54). All SUPPLIED-covariance,
# EXPERIMENTAL, validation-scale — `K_g` and `σ²e` are SUPPLIED, never estimated.
#
# Slice 1 (DESCRIPTORS). Given a SUPPLIED k×k genetic covariance matrix `K_g` among
# an animal's random-regression coefficients over a normalized-Legendre basis on a
# standardized covariate t ∈ [-1, 1], the descriptors report the quantitative-genetic
# interpretation a breeder/evolutionary user reads off a reaction norm: the
# per-covariate additive genetic variance trajectory v_g(t) = φ(t)ᵀ K_g φ(t), the
# genetic covariance/correlation SURFACE G(t,t') = φ(t)ᵀ K_g φ(t'), and (only when a
# residual variance is supplied) the heritability trajectory h²(t). These build NO
# mixed-model equations and make NO selection-response prediction (descriptive
# transforms on a supplied K_g, like `genetic_correlation`/`evolvability` on a G).
#
# Slice 2 (SUPPLIED-COVARIANCE MME). `random_regression_mme` solves the Henderson MME
# for the polynomial RR animal model at a SUPPLIED `K_g`/`σ²e` (genetic precision
# `Ainv ⊗ inv(K_g)`, i.e. coefficient covariance `A ⊗ K_g`), returning per-animal
# coefficient vectors. Still supplied-covariance — no estimation.
#
# Slice 3 (REML). `fit_random_regression_reml` ESTIMATES `K_g`/`σ²e` by dense
# log-Cholesky REML on the marginal `V = W(A⊗K_g)Wᵀ + σ²e I` (analogue of
# `fit_multivariate_reml`). Still dense/validation-scale, homogeneous residual.
#
# Slice 4 (EIGEN-FUNCTIONS). `rr_eigenfunctions` decomposes a SUPPLIED `K_g` into the
# Kirkpatrick (Lofsvold & Bulmer 1990) covariance-function eigenfunctions
# ψ_j(t) = φ(t)ᵀ v_j (eigenvectors v_j of `K_g` via `genetic_pca`), reporting the
# eigenvalues, eigen-coefficients, evaluated eigenfunctions, and variance explained.
# Rotation-invariant and DESCRIPTIVE — still supplied-covariance, no estimation.
#
# DEFERRED to later slices: PEV of curve-valued EBVs, heterogeneous residual +
# permanent-environment term, the R-facing model-spec / bridge payload, and any
# WOMBAT/ASReml/JWAS comparator. Basis
# convention is FIXED to normalized Legendre on standardized t ∈ [-1, 1]
# (Kirkpatrick/Meyer/Schaeffer); `K_g` values are not comparable across normalization
# conventions.

"""
    legendre_basis(t, order)

Normalized Legendre basis vector `φ(t) = [φ_0(t), …, φ_{order-1}(t)]` at a
standardized covariate `t ∈ [-1, 1]`, where `φ_n(t) = sqrt((2n+1)/2)·P_n(t)` and
`P_n` are the ordinary Legendre polynomials (Bonnet recurrence). The basis is
orthonormal on `[-1, 1]` (`∫_{-1}^{1} φ_m φ_n = δ_mn`). `order = k` is the number of
random-regression coefficients. Use [`standardize_covariate`](@ref) to map a raw
covariate onto `[-1, 1]` first (this function throws if `|t| > 1`).
"""
function legendre_basis(t::Real, order::Integer)
    order >= 1 || throw(ArgumentError("order must be >= 1"))
    isfinite(t) || throw(ArgumentError("t must be finite"))
    -1 - 1e-10 <= t <= 1 + 1e-10 ||
        throw(ArgumentError("t must be in [-1, 1]; standardize the covariate first " *
                            "(see standardize_covariate), got t = $t"))
    tt = clamp(Float64(t), -1.0, 1.0)
    P = Vector{Float64}(undef, order)       # ordinary Legendre P_0..P_{order-1}
    P[1] = 1.0
    order >= 2 && (P[2] = tt)
    @inbounds for n in 2:(order - 1)         # (n)P_n = (2n-1) t P_{n-1} - (n-1) P_{n-2}
        P[n + 1] = ((2n - 1) * tt * P[n] - (n - 1) * P[n - 1]) / n
    end
    φ = similar(P)
    @inbounds for n in 0:(order - 1)
        φ[n + 1] = sqrt((2n + 1) / 2) * P[n + 1]
    end
    return φ
end

"""
    standardize_covariate(a; lower = minimum(a), upper = maximum(a))

Affinely map a raw covariate vector `a` (e.g. age/time) onto `t ∈ [-1, 1]` by
`t = 2(a - lower)/(upper - lower) - 1` (so `lower → -1`, `upper → +1`, midpoint
`→ 0`). Returns a `Vector{Float64}`. Throws if `lower == upper`.
"""
function standardize_covariate(a::AbstractVector; lower::Real = minimum(a), upper::Real = maximum(a))
    all(isfinite, a) || throw(ArgumentError("covariate must contain only finite values"))
    upper > lower || throw(ArgumentError("upper ($upper) must exceed lower ($lower)"))
    return Float64.(2 .* (a .- lower) ./ (upper - lower) .- 1)
end

# m×k design Φ whose row i is φ(ts[i]); ts already standardized to [-1, 1].
function _rr_design(ts::AbstractVector, order::Integer)
    Φ = Matrix{Float64}(undef, length(ts), order)
    @inbounds for i in eachindex(ts)
        Φ[i, :] .= legendre_basis(ts[i], order)
    end
    return Φ
end

# Validate the coefficient genetic covariance: square, symmetric, finite, PSD
# (reuses the evolvability scale-relative PSD guard). The basis order is DERIVED
# from size(K_g, 1), so there is no separate order to match.
function _check_kg(K_g::AbstractMatrix)
    return _check_symmetric_psd_G(K_g)   # square + symmetric + finite + scale-relative PSD
end

"""
    rr_genetic_variance(K_g, ts)

Per-covariate additive genetic variance trajectory `v_g(t_i) = φ(t_i)ᵀ K_g φ(t_i)`
for a supplied `k×k` random-regression coefficient genetic covariance `K_g` and
standardized covariate points `ts ∈ [-1, 1]` (`k = size(K_g, 1)`). Returns
`(covariate = ts, values)`. Descriptive only — `K_g` is supplied, not estimated.
"""
function rr_genetic_variance(K_g::AbstractMatrix, ts::AbstractVector)
    S = _check_kg(K_g)
    Φ = _rr_design(ts, size(S, 1))
    values = [max(0.0, dot(view(Φ, i, :), S * view(Φ, i, :))) for i in axes(Φ, 1)]
    return (covariate = collect(Float64, ts), values = values)
end

"""
    rr_genetic_covariance_surface(K_g, ts)

Genetic covariance surface `G(t_i, t_j) = φ(t_i)ᵀ K_g φ(t_j)` across the
standardized covariate points `ts`, i.e. `Φ K_g Φᵀ` (`m×m`, symmetric, PSD whenever
`K_g` is PSD). Returns `(covariate = ts, values)`. Its diagonal is
[`rr_genetic_variance`](@ref) — exactly for a positive-definite `K_g`; for a
reduced-rank (PSD) `K_g` the surface diagonal may carry a tiny negative roundoff at
a near-zero-variance point, whereas `rr_genetic_variance` clamps such values to 0.
"""
function rr_genetic_covariance_surface(K_g::AbstractMatrix, ts::AbstractVector)
    S = _check_kg(K_g)
    Φ = _rr_design(ts, size(S, 1))
    G = Φ * S * transpose(Φ)
    return (covariate = collect(Float64, ts), values = 0.5 .* (G .+ transpose(G)))  # symmetrize roundoff
end

"""
    rr_genetic_correlation_surface(K_g, ts)

Genetic correlation surface across the standardized covariate points: the
correlation matrix of [`rr_genetic_covariance_surface`](@ref) (`D⁻¹ G D⁻¹`, unit
diagonal). Reuses [`genetic_correlation`](@ref), so it throws if any covariate
point has non-positive genetic variance. Returns `(covariate = ts, values)`.
"""
function rr_genetic_correlation_surface(K_g::AbstractMatrix, ts::AbstractVector)
    surf = rr_genetic_covariance_surface(K_g, ts)
    return (covariate = surf.covariate, values = genetic_correlation(surf.values))
end

"""
    rr_heritability(K_g, residual, ts)

Heritability trajectory `h²(t_i) = v_g(t_i) / (v_g(t_i) + σ²_e(t_i))` for a supplied
coefficient genetic covariance `K_g` and supplied residual variance `residual` —
either a positive scalar (homoscedastic) or a length-`m` positive vector
(heteroscedastic across the covariate). `K_g` and `σ²_e` are SUPPLIED, not estimated.
Returns `(covariate = ts, values)`.

The supplied `residual` is treated as the TOTAL non-additive-genetic phenotypic
variance at each covariate point. In the canonical repeated-records random-regression
model (test-day, growth curves) a permanent-environment effect is essentially always
present, so to avoid OVERSTATING `h²(t)` you must supply `v_pe(t) + σ²_e(t)` here, not
the residual alone (the permanent-environment term is a later slice).
"""
function rr_heritability(K_g::AbstractMatrix, residual, ts::AbstractVector)
    vg = rr_genetic_variance(K_g, ts)
    m = length(vg.values)
    σe2 = residual isa Real ? fill(Float64(residual), m) : Float64.(collect(residual))
    length(σe2) == m ||
        throw(ArgumentError("residual must be a scalar or a length-$(m) vector"))
    all(>(0), σe2) || throw(ArgumentError("residual variance(s) must be positive"))
    return (covariate = vg.covariate, values = vg.values ./ (vg.values .+ σe2))
end

"""
    rr_eigenfunctions(K_g, ts)

Eigen-function (covariance-function) decomposition of a supplied `k×k`
random-regression coefficient genetic covariance `K_g` (Kirkpatrick, Lofsvold &
Bulmer 1990). Eigen-decomposes `K_g = Σ_j λ_j v_j v_jᵀ` (descending `λ_j ≥ 0`, via
[`genetic_pca`](@ref)) and evaluates the corresponding eigenFUNCTIONS
`ψ_j(t) = φ(t)ᵀ v_j` — the orthonormal genetic principal curves of the reaction
norm — at the standardized covariate points `ts ∈ [-1, 1]` (`k = size(K_g, 1)`).

Returns `(covariate, eigenvalues, eigen_coefficients, eigenfunctions,
variance_explained)`:
- `eigenvalues` — `λ_j` descending (the genetic variance carried by each
  eigenfunction);
- `eigen_coefficients` — `k×k`, column `j` is the Legendre-coefficient eigenvector
  `v_j`, sign-canonicalized as in [`genetic_pca`](@ref);
- `eigenfunctions` — `length(ts)×k`, column `j` is `ψ_j` evaluated at `ts`
  (`= Φ v_j`, `Φ = legendre_design(ts, k)`);
- `variance_explained` — `λ_j / Σλ` (zeros if `K_g` is the zero matrix).

The eigenfunctions are orthonormal on `[-1, 1]` (`∫ ψ_i ψ_j = δ_ij`) and the
covariance surface reconstructs spectrally as `Φ K_g Φᵀ = Σ_j λ_j ψ_j ψ_jᵀ`.
Rotation-invariant and DESCRIPTIVE — `K_g` is SUPPLIED, not estimated (like
[`genetic_pca`](@ref) / [`evolvability`](@ref) on a `G`). Under repeated
eigenvalues the individual eigenfunctions are span-ambiguous (as in
[`genetic_pca`](@ref)); the eigenvalues, variance explained, and the spectral
reconstruction remain well-defined.
"""
function rr_eigenfunctions(K_g::AbstractMatrix, ts::AbstractVector)
    pca = genetic_pca(_check_kg(K_g))
    k = length(pca.values)
    Φ = _rr_design(ts, k)
    Ψ = Φ * pca.vectors
    total = sum(pca.values)
    prop = total > 0 ? pca.values ./ total : zeros(k)
    return (covariate = collect(Float64, ts),
            eigenvalues = pca.values,
            eigen_coefficients = pca.vectors,
            eigenfunctions = Ψ,
            variance_explained = prop)
end

"""
    legendre_design(ts, order)

Build the `n × order` random-regression design matrix `Φ` whose row `i` is
`legendre_basis(ts[i], order)` for standardized covariate points `ts ∈ [-1, 1]`
(use [`standardize_covariate`](@ref) first). The columns are the normalized
Legendre basis functions.
"""
legendre_design(ts::AbstractVector, order::Integer) = _rr_design(ts, order)

# Random-regression random-effect incidence W (n × q·k): record r contributes
# Phi[r,:] (scaled by Z[r,a]) into animal a's k-column block. This is the row-wise
# Khatri–Rao (face-splitting) product of Z and Phi — NOT kron(Z, I_k). Column
# (a-1)k + c ↔ animal a, coefficient c (coefficient-fastest, animal-outer), matching
# the kron(Ainv, inv(K_g)) genetic precision ordering.
function _rr_random_design(Phi::AbstractMatrix, Z::AbstractMatrix)
    n, k = size(Phi)
    q = size(Z, 2)
    W = zeros(Float64, n, q * k)
    @inbounds for r in 1:n, a in 1:q
        z = Z[r, a]
        z == 0 && continue
        for c in 1:k
            W[r, (a - 1) * k + c] = z * Phi[r, c]
        end
    end
    return W
end

"""
    random_regression_mme(y, X, Phi, Z, Ainv, K_g, sigma_e2; ids = nothing)

Solve the SUPPLIED-covariance Henderson mixed-model equations for the polynomial
random-regression animal model with a homogeneous scalar residual variance:

    y_r = x_rᵀ β + φ(s_r)ᵀ a_{a(r)} + e_r,  e_r ~ N(0, sigma_e2),
    vec(a) ~ N(0, A ⊗ K_g),  A = Ainv⁻¹,

where `Phi` (`n × k`) holds the per-record basis rows `φ(s_r)ᵀ` (see
[`legendre_design`](@ref)), `Z` (`n × q`) is the record→animal incidence, `Ainv`
(`q × q`) the relationship precision, `K_g` (`k × k`, positive definite) the
supplied genetic covariance among the `k` random-regression coefficients, and
`sigma_e2 > 0`. The genetic precision block is `Ainv ⊗ inv(K_g)` (animal-outer,
coefficient-fastest ordering, matching the random design `W = face-splitting(Z, Phi)`).

Returns `(beta, random_coefficients = (ids, values), variance_components =
(K_g, sigma_e2), basis = (ncoef,))`, where `values` is the `q × k` matrix of
per-animal coefficient vectors (row = animal, column = Legendre coefficient `0..k-1`).

EXPERIMENTAL, dense/validation-scale, SUPPLIED-covariance: `K_g`/`sigma_e2` are NOT
estimated here — use [`fit_random_regression_reml`](@ref) to estimate them by REML.
There is no R-facing model-spec or bridge payload, and homogeneous residual variance
only.
"""
function random_regression_mme(y::AbstractVector, X::AbstractMatrix, Phi::AbstractMatrix,
                               Z::AbstractMatrix, Ainv::AbstractMatrix, K_g::AbstractMatrix,
                               sigma_e2::Real; ids = nothing)
    n = length(y)
    k = size(Phi, 2)
    q = size(Ainv, 1)
    size(Phi, 1) == n || throw(ArgumentError("Phi must have one row per record (n = $n)"))
    size(X, 1) == n || throw(ArgumentError("X must have one row per record (n = $n)"))
    size(Z, 1) == n || throw(ArgumentError("Z must have one row per record (n = $n)"))
    size(Z, 2) == q || throw(ArgumentError("Z columns must match Ainv dimension (q = $q)"))
    size(Ainv, 2) == q || throw(ArgumentError("Ainv must be square (q × q)"))
    size(K_g, 1) == k && size(K_g, 2) == k ||
        throw(ArgumentError("K_g must be $k×$k (k = number of basis columns in Phi)"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    Ksym = Symmetric(Matrix{Float64}(K_g))
    isposdef(Ksym) || throw(ArgumentError("K_g must be positive definite"))
    yv = Float64.(y)
    Xm = Matrix{Float64}(X)
    all(isfinite, yv) || throw(ArgumentError("y must contain only finite values"))
    all(isfinite, Xm) || throw(ArgumentError("X must contain only finite values"))
    all(isfinite, Float64.(Matrix(Phi))) || throw(ArgumentError("Phi must be finite"))
    all(isfinite, Float64.(Matrix(Ainv))) || throw(ArgumentError("Ainv must be finite"))

    W = _rr_random_design(Matrix{Float64}(Phi), Matrix{Float64}(Z))
    Ginv = kron(sparse(Float64.(Matrix(Ainv))), sparse(inv(Ksym)))   # q·k × q·k precision
    p = size(Xm, 2)
    # MME scaled by sigma_e2 (residual precision I/sigma_e2):
    #   [X'X  X'W;  W'X  W'W + sigma_e2·(Ainv⊗K_g⁻¹)] [β; a] = [X'y; W'y]
    Wt = transpose(W)
    lhs = [Xm' * Xm      Xm' * W
           Wt * Xm       Wt * W + sigma_e2 .* Matrix(Ginv)]
    rhs = vcat(Xm' * yv, Wt * yv)
    solution = Symmetric(lhs) \ rhs
    beta = Vector{Float64}(solution[1:p])
    avec = Vector{Float64}(solution[(p + 1):(p + q * k)])
    coeffs = permutedims(reshape(avec, k, q))                         # q × k (animal × coefficient)
    aids = ids === nothing ? collect(1:q) : collect(ids)
    return (
        beta = beta,
        random_coefficients = (ids = aids, values = coeffs),
        variance_components = (K_g = Matrix(Ksym), sigma_e2 = Float64(sigma_e2)),
        basis = (ncoef = k,),
    )
end

# --- REML estimation of K_g / σ²e (slice 3, #54) ----------------------------

# Cholesky of the marginal covariance V = W·(A ⊗ K_g)·Wᵀ + σ²e·I (n×n). PD for
# σ²e > 0 even when K_g is only positive semidefinite (a boundary optimum),
# mirroring the multivariate `_mv_build_Vchol`.
function _rr_build_Vchol(W, A, K_g, sigma_e2, n)
    Vg = W * kron(A, K_g) * transpose(W)
    return cholesky(Symmetric(Vg + sigma_e2 * I))
end

# Full REML log-likelihood at supplied (K_g, σ²e), INCLUDING the (n−p)·log(2π)
# constant, so it is on the same scale as `sparse_reml_loglik` /
# `_mv_reml_loglik_core` (LRT/AIC-safe). The k=1 reduction with K_g = [2σ²a]
# equals the univariate `sparse_reml_loglik` (φ_0² = 1/2).
function _rr_reml_loglik_core(yv, Xm, W, A, K_g, sigma_e2, n, p)
    Vf = _rr_build_Vchol(W, A, K_g, sigma_e2, n)
    ViX = Vf \ Xm
    XtViX = cholesky(Symmetric(transpose(Xm) * ViX))
    beta = XtViX \ (transpose(Xm) * (Vf \ yv))
    r = yv .- Xm * beta
    return -0.5 * ((n - p) * log(2π) + logdet(Vf) + logdet(XtViX) + dot(r, Vf \ r))
end

# GLS fixed effects + BLUP coefficient vectors at supplied (K_g, σ²e), via the
# marginal form a = (A⊗K_g)·Wᵀ·V⁻¹·(y − Xβ̂) — equals the MME solution for a PD
# K_g and stays defined at a singular boundary K_g. Returns (β, q×k coefficients).
function _rr_gls_blup(yv, Xm, W, A, K_g, sigma_e2, n, q, k)
    Vf = _rr_build_Vchol(W, A, K_g, sigma_e2, n)
    ViX = Vf \ Xm
    XtViX = cholesky(Symmetric(transpose(Xm) * ViX))
    betavec = XtViX \ (transpose(Xm) * (Vf \ yv))
    r = yv .- Xm * betavec
    avec = kron(A, K_g) * (transpose(W) * (Vf \ r))
    coeffs = permutedims(reshape(avec, k, q))   # q × k (animal × coefficient)
    return betavec, coeffs
end

"""
    fit_random_regression_reml(y, X, Phi, Z, Ainv; initial = nothing,
                               iterations = 2000, ids = nothing)

Estimate the random-regression coefficient genetic covariance `K_g` (`k×k`) and
the homogeneous residual variance `σ²e` of the polynomial random-regression
animal model by **dense REML**. Inputs match [`random_regression_mme`](@ref)
(`Phi` the `n×k` basis design from [`legendre_design`](@ref), `Z` the `n×q`
record→animal incidence, `Ainv` the `q×q` relationship precision), but here
`K_g`/`σ²e` are ESTIMATED rather than supplied. The marginal model is

    y ~ N(X·β, V),   V = W·(A ⊗ K_g)·Wᵀ + σ²e·I,

with `A = Ainv⁻¹` and `W = ` face-splitting(`Z`, `Phi`) (animal-outer,
coefficient-fastest — see [`random_regression_mme`](@ref)). The REML
log-likelihood is maximized by Nelder–Mead over a log-Cholesky parameterization
of `K_g` and `log σ²e` (so `K_g` stays positive definite and `σ²e` positive). At
the optimum the coefficient BLUPs and `β` come from the marginal GLS BLUP form.

`initial` may supply `K_g` and/or `sigma_e2`; omitted fields use
phenotypic-scale defaults. Returns a `NamedTuple`:

  - `variance_components = (K_g, sigma_e2)` — estimated `k×k` covariance + residual;
  - `beta` — fixed effects at the estimate;
  - `random_coefficients = (ids, values)` — `q×k` per-animal coefficient BLUPs
    (row = animal, column = Legendre coefficient `0..k-1`);
  - `loglik` — full REML log-likelihood at the estimate (same scale as
    [`sparse_reml_loglik`](@ref); the `k = 1` reduction with `K_g = [2σ²a]` equals
    the univariate REML log-likelihood);
  - `converged`, `iterations`, `basis = (ncoef = k,)`.

EXPERIMENTAL, dense/validation-scale, REML-only, Gaussian, homogeneous residual
variance, no permanent-environment term. Validated by deterministic
self-consistency: the `k = 1` reduction recovers the univariate `fit_sparse_reml`
optimum (`K_g[1,1] = 2σ²a`, equal `σ²e`, equal log-likelihood); the reported
log-likelihood matches an independent marginal oracle and beats off-optimum
points; the BLUPs reproduce [`random_regression_mme`](@ref) at the estimate.
Known-truth `K_g` recovery and any WOMBAT/ASReml/JWAS comparator are not yet
exercised, and there is no R-facing model-spec or bridge payload. As a dense GLS
path, `V`'s conditioning degrades as `O(1/σ²e)` toward the residual boundary, so a
near-noiseless optimum (`σ²e → 0`) is conditioning-limited at this validation scale.
"""
function fit_random_regression_reml(y::AbstractVector, X::AbstractMatrix, Phi::AbstractMatrix,
                                    Z::AbstractMatrix, Ainv::AbstractMatrix;
                                    initial = nothing, iterations::Integer = 2_000,
                                    ids = nothing)
    n = length(y)
    k = size(Phi, 2)
    q = size(Ainv, 1)
    p = size(X, 2)
    size(Phi, 1) == n || throw(ArgumentError("Phi must have one row per record (n = $n)"))
    size(X, 1) == n || throw(ArgumentError("X must have one row per record (n = $n)"))
    size(Z, 1) == n || throw(ArgumentError("Z must have one row per record (n = $n)"))
    size(Z, 2) == q || throw(ArgumentError("Z columns must match Ainv dimension (q = $q)"))
    size(Ainv, 2) == q || throw(ArgumentError("Ainv must be square (q × q)"))
    p < n || throw(ArgumentError("REML requires fewer fixed-effect columns than records"))
    yv = Float64.(y)
    Xm = Matrix{Float64}(X)
    all(isfinite, yv) || throw(ArgumentError("y must contain only finite values"))
    all(isfinite, Xm) || throw(ArgumentError("X must contain only finite values"))
    all(isfinite, Float64.(Matrix(Phi))) || throw(ArgumentError("Phi must be finite"))
    all(isfinite, Float64.(Matrix(Ainv))) || throw(ArgumentError("Ainv must be finite"))

    W = _rr_random_design(Matrix{Float64}(Phi), Matrix{Float64}(Z))
    A = inv(Symmetric(Matrix{Float64}(Matrix(Ainv))))

    mu = sum(yv) / n
    vp = n > 1 ? sum(abs2, yv .- mu) / (n - 1) : 1.0
    vp > 0 || (vp = 1.0)

    if initial !== nothing && hasproperty(initial, :K_g)
        K_g_start = Matrix(Float64.(Matrix(initial.K_g)))
        size(K_g_start) == (k, k) || throw(ArgumentError("initial.K_g must be $k×$k"))
        isposdef(Symmetric(K_g_start)) || throw(ArgumentError("initial.K_g must be positive definite"))
    else
        K_g_start = Matrix(Diagonal(fill(0.5 * vp, k)))
    end
    sigma_e2_start = if initial !== nothing && hasproperty(initial, :sigma_e2)
        s = Float64(initial.sigma_e2)
        s > 0 || throw(ArgumentError("initial.sigma_e2 must be positive"))
        s
    else
        0.5 * vp
    end

    nkg = k * (k + 1) ÷ 2
    function negloglik(params)
        K_g = _chol_params_to_cov(@view(params[1:nkg]), k)
        sigma_e2 = exp(params[nkg + 1])
        try
            # cholesky(Symmetric(V)) does not throw on a non-finite V (logdet → Inf
            # without error), so screen the objective: any non-finite value maps to
            # the +Inf reject sentinel rather than feeding NaN into the simplex.
            val = -_rr_reml_loglik_core(yv, Xm, W, A, K_g, sigma_e2, n, p)
            return isfinite(val) ? val : Inf
        catch err
            (err isa PosDefException || err isa ArgumentError) && return Inf
            rethrow()
        end
    end

    params0 = vcat(_cov_to_chol_params(K_g_start, k), log(sigma_e2_start))
    result = optimize(negloglik, params0, NelderMead(), Optim.Options(iterations = iterations))
    phat = Optim.minimizer(result)
    K_ghat = Matrix(Symmetric(_chol_params_to_cov(phat[1:nkg], k)))
    sigma_e2hat = exp(phat[nkg + 1])

    beta, coeffs = _rr_gls_blup(yv, Xm, W, A, K_ghat, sigma_e2hat, n, q, k)
    aids = ids === nothing ? collect(1:q) : collect(ids)
    length(aids) == q || throw(ArgumentError("ids length must match Ainv dimension (q = $q)"))
    return (
        variance_components = (K_g = K_ghat, sigma_e2 = sigma_e2hat),
        beta = beta,
        random_coefficients = (ids = aids, values = coeffs),
        loglik = -Optim.minimum(result),
        converged = Optim.converged(result),
        iterations = Optim.iterations(result),
        basis = (ncoef = k,),
    )
end

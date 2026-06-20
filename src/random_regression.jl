# Random regression / reaction norms — covariance-function descriptors (Phase 3, #54).
#
# DESCRIPTIVE, SUPPLIED-covariance layer (slice 1). Given a SUPPLIED k×k genetic
# covariance matrix `K_g` among an animal's random-regression coefficients over a
# normalized-Legendre basis on a standardized covariate t ∈ [-1, 1], this reports
# the quantitative-genetic interpretation a breeder/evolutionary user reads off a
# reaction norm: the per-covariate additive genetic variance trajectory
# v_g(t) = φ(t)ᵀ K_g φ(t), the genetic covariance/correlation SURFACE across
# covariate points G(t,t') = φ(t)ᵀ K_g φ(t'), and (only when a residual variance is
# supplied) the heritability trajectory h²(t). This mirrors how the multivariate
# lane began — descriptive transforms on a supplied G (`genetic_correlation`,
# `evolvability`) BEFORE any estimation.
#
# EXPERIMENTAL, validation-scale, descriptive only. It does NOT estimate `K_g`,
# builds NO mixed-model equations, makes NO selection-response prediction, and has
# NO R-facing model-spec or bridge payload. The supplied-covariance random-regression
# MME solve (Henderson Kronecker `A⁻¹ ⊗ K_g⁻¹`), REML estimation of `K_g`, the
# eigen-function (covariance-function) decomposition, PEV of curve-valued EBVs, and
# any WOMBAT/ASReml comparator are DEFERRED to later slices. Basis convention is
# FIXED to normalized Legendre on standardized t ∈ [-1, 1] (Kirkpatrick/Meyer/
# Schaeffer); `K_g` values are not comparable across normalization conventions.

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

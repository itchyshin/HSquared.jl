# Phase 6 foundation: Laplace-approximate marginal log-likelihood for the
# non-Gaussian animal model. EXPERIMENTAL, dense / validation-scale.
#
# Model:  η = Xβ + Zu,  u ~ N(0, A·σ²a)  with supplied A⁻¹ = `Ainv`; the response
# is conditionally exponential-family given η (a `ResponseFamily`). The
# marginal integrates out the joint mode [β (flat prior); u] by Laplace's method
# (penalized IRLS / Newton on the joint objective, then a Gaussian integral at
# the mode). β is integrated (flat prior), so for a Gaussian family this is the
# REML-type marginal and reduces EXACTLY to `sparse_reml_loglik`.
#
# This is the `:LA` marginal; the `:VA` (variational) marginal reuses the
# per-family kernels here (architecture adapted from the MIT DRM.jl
# `src/variational.jl` :LA/:VA dispatch). Families currently: Gaussian (identity
# link, exact), Poisson (log link, closed-form VA via the log-normal MGF),
# Bernoulli (logit link; the VA expected kernels use Gauss–Hermite quadrature
# because the logistic log-partition has no closed-form Gaussian expectation),
# and Binomial (logit link, `n_trials` successes — a common scalar denominator or a
# per-record vector; Bernoulli is `n_trials = 1`).
#
# The fitters `fit_laplace_reml` / `laplace_reml_interval` are exported
# (experimental); the marginal-loglik kernels and `ResponseFamily` types stay
# internal. Not wired into the R formula `fit_*` path; no R model-spec.
# Validation: Gaussian reduces to `sparse_reml_loglik` to machine
# precision; the Poisson mode solves the penalized score equation (∇ = 0); the
# per-family score/weight match finite differences of the conditional loglik.

abstract type ResponseFamily end

"""Gaussian family with identity link and residual variance `sigma_e2`."""
struct GaussianResponse <: ResponseFamily
    sigma_e2::Float64
    function GaussianResponse(sigma_e2::Real)
        sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
        return new(Float64(sigma_e2))
    end
end

"""Poisson family with log link (`μ = exp(η)`)."""
struct PoissonResponse <: ResponseFamily end

"""Bernoulli family with logit link (`p = logistic(η)`) for binary 0/1 traits."""
struct BernoulliResponse <: ResponseFamily end

"""
Binomial family with logit link for counts of successes out of a common number of
trials `n_trials` (`y ∈ 0:n_trials`, `p = logistic(η)`). Generalises
`BernoulliResponse` (= `n_trials = 1`); more trials per record make the data more
informative, so the Laplace variance bias shrinks.
"""
struct BinomialResponse <: ResponseFamily
    n_trials::Int
    function BinomialResponse(n_trials::Integer)
        n_trials >= 1 || throw(ArgumentError("n_trials must be >= 1"))
        return new(Int(n_trials))
    end
end

"""
Binomial family with logit link and a PER-RECORD number of trials `n_trials[i]`
(`y[i] ∈ 0:n_trials[i]`). The general `cbind(successes, failures)` GLMM where the
trial denominator varies by observation; `BinomialResponse(m::Int)` is the common-
denominator special case. Internal: the fitter / bridge accept a scalar or vector
`n_trials` and construct the right type. The per-record kernels are resolved to the
matching scalar `BinomialResponse(n_trials[i])` via `_fam_record`, so the family
math is shared and the scalar path is untouched.
"""
struct BinomialVectorResponse <: ResponseFamily
    n_trials::Vector{Int}
    function BinomialVectorResponse(n_trials::AbstractVector{<:Integer})
        isempty(n_trials) && throw(ArgumentError("n_trials must be non-empty"))
        all(n -> n >= 1, n_trials) || throw(ArgumentError("every n_trials[i] must be >= 1"))
        return new(Vector{Int}(n_trials))
    end
end

# Per-record family resolution. For every family without per-record state this is
# the identity (compiles away; zero overhead in the per-observation comprehensions).
# For the per-record Binomial it returns the SCALAR `BinomialResponse` for record
# `i` — a bitstype (one `Int` field), so this is allocation-free, and it reuses the
# existing scalar Binomial kernels unchanged.
@inline _fam_record(f::ResponseFamily, ::Integer) = f
@inline _fam_record(f::BinomialVectorResponse, i::Integer) = BinomialResponse(f.n_trials[i])

# Resolve a single-variance-component family (:poisson / :bernoulli / :binomial) and
# its `n_trials` (scalar OR per-record vector; integer-valued reals already validated
# by the caller) to the `ResponseFamily` object the kernels consume. Shared by
# `fit_laplace_reml` and `laplace_reml_interval` so the two never drift.
function _resolve_single_family(family::Symbol, n_trials)
    family === :poisson && return PoissonResponse()
    family === :bernoulli && return BernoulliResponse()
    if family === :binomial
        n_trials isa AbstractVector && return BinomialVectorResponse(Int.(n_trials))
        # scalar: accept an integer-valued real (the R bridge marshals doubles) with a
        # clean error on a genuinely non-integer count, mirroring the vector contract.
        (n_trials isa Real && isinteger(n_trials)) ||
            throw(ArgumentError("n_trials must be an integer trial count (or a per-record integer vector)"))
        return BinomialResponse(Int(n_trials))
    end
    throw(ArgumentError("unsupported single-component family :$family"))
end

# Marginal-method dispatch (architecture mirrors the MIT DRM.jl :LA/:VA idea).
# The engine keeps the `marginal::Symbol` keyword/field (:laplace / :variational);
# this dispatch type is the canonical mapping the bridge payload uses to emit the
# R-facing method name ("laplace" / "va"), and it also accepts the DRM-style
# :LA / :VA spellings. Value-preserving: it does NOT change fit_laplace_reml
# numerics or the stored NonGaussianFit.marginal symbol.
abstract type MarginalMethod end
struct Laplace <: MarginalMethod end
struct Variational <: MarginalMethod end

_marginal_method(m::MarginalMethod) = m
function _marginal_method(s::Symbol)
    t = Symbol(uppercase(String(s)))
    (t === :LAPLACE || t === :LA) && return Laplace()
    (t === :VARIATIONAL || t === :VA) && return Variational()
    throw(ArgumentError("marginal must be :laplace/:LA or :variational/:VA, got :$s"))
end
_marginal_method_symbol(::Laplace) = :laplace
_marginal_method_symbol(::Variational) = :variational
# R-facing method token. Kept unabbreviated (matching the stored :variational
# symbol and the rest of the codebase, and the "laplace" sibling) — the exact
# on-the-wire token is pending R-lane agreement before it is a frozen contract.
_marginal_method_string(::Laplace) = "laplace"
_marginal_method_string(::Variational) = "variational"

# numerically stable logistic and log(1 + exp η)
_logistic(η) = η >= 0 ? 1.0 / (1.0 + exp(-η)) : (e = exp(η); e / (1.0 + e))
_log1pexp(η) = η > 0 ? η + log1p(exp(-η)) : log1p(exp(η))
_logbinom(m, y) = _logfactorial(m) - _logfactorial(y) - _logfactorial(m - y)

# per-observation conditional log-density ℓ(y|η), score dℓ/dη, working weight -d²ℓ/dη²
_fam_loglik(f::GaussianResponse, y, η) = -0.5 * ((y - η)^2 / f.sigma_e2 + log(2π * f.sigma_e2))
_fam_score(f::GaussianResponse, y, η) = (y - η) / f.sigma_e2
_fam_weight(f::GaussianResponse, y, η) = 1.0 / f.sigma_e2

_fam_loglik(::PoissonResponse, y, η) = y * η - exp(η) - _logfactorial(y)
_fam_score(::PoissonResponse, y, η) = y - exp(η)
_fam_weight(::PoissonResponse, y, η) = exp(η)

_fam_loglik(::BernoulliResponse, y, η) = y * η - _log1pexp(η)
_fam_score(::BernoulliResponse, y, η) = y - _logistic(η)
_fam_weight(::BernoulliResponse, y, η) = (p = _logistic(η); p * (1.0 - p))

_fam_loglik(f::BinomialResponse, y, η) = y * η - f.n_trials * _log1pexp(η) + _logbinom(f.n_trials, Int(round(y)))
_fam_score(f::BinomialResponse, y, η) = y - f.n_trials * _logistic(η)
_fam_weight(f::BinomialResponse, y, η) = (p = _logistic(η); f.n_trials * p * (1.0 - p))

function _logfactorial(y)
    k = Int(round(y))
    s = 0.0
    @inbounds for i in 2:k
        s += log(i)
    end
    return s
end

# Validate the response data against the family. Poisson (log link) requires
# non-negative integer counts; the per-record kernels would otherwise mix a
# raw-y score with a round(y) log-factorial and silently misreport the loglik.
_check_counts(::ResponseFamily, yv) = nothing
function _check_counts(::PoissonResponse, yv)
    all(y -> isinteger(y) && y >= 0, yv) ||
        throw(ArgumentError("PoissonResponse requires non-negative integer counts"))
    return nothing
end
function _check_counts(::BernoulliResponse, yv)
    all(y -> y == 0 || y == 1, yv) ||
        throw(ArgumentError("BernoulliResponse requires binary 0/1 responses"))
    return nothing
end
function _check_counts(f::BinomialResponse, yv)
    all(y -> isinteger(y) && 0 <= y <= f.n_trials, yv) ||
        throw(ArgumentError("BinomialResponse requires integer counts in 0:n_trials"))
    return nothing
end
function _check_counts(f::BinomialVectorResponse, yv)
    length(f.n_trials) == length(yv) ||
        throw(ArgumentError("n_trials must have one entry per record (length(n_trials) == length(y))"))
    all(i -> isinteger(yv[i]) && 0 <= yv[i] <= f.n_trials[i], eachindex(yv)) ||
        throw(ArgumentError("BinomialVectorResponse requires integer counts with 0 <= y[i] <= n_trials[i]"))
    return nothing
end

"""
    laplace_marginal_loglik(y, X, Z, Ainv, sigma_a2, family; tol = 1e-10, maxiter = 100)

Laplace-approximate marginal log-likelihood of the non-Gaussian animal model,
integrating the random effect `u ~ N(0, A·σ²a)` (and `β` under a flat prior).
Returns `(loglik, beta, u, converged, gradient_norm, iterations)`.

Experimental, dense, validation-scale. For a `GaussianResponse` it is exact and
equals `sparse_reml_loglik`.
"""
function laplace_marginal_loglik(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                                 Ainv::AbstractMatrix, sigma_a2::Real,
                                 family::ResponseFamily;
                                 tol::Real = 1e-10, maxiter::Integer = 100)
    sigma_a2 > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    yv = Float64.(y)
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    Ai = Matrix{Float64}(Ainv)
    n = length(yv)
    p = size(Xd, 2)
    q = size(Zd, 2)
    size(Xd, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Zd, 1) == n || throw(ArgumentError("Z must have one row per record"))
    size(Ai, 1) == q == size(Ai, 2) || throw(ArgumentError("Ainv must be q×q with q = size(Z,2)"))
    _check_counts(family, yv)

    beta = zeros(p)
    u = zeros(q)
    gnorm = Inf
    iters = 0
    converged = false
    local H
    for it in 1:maxiter
        iters = it
        η = Xd * beta .+ Zd * u
        s = [_fam_score(_fam_record(family, i), yv[i], η[i]) for i in 1:n]
        w = [_fam_weight(_fam_record(family, i), yv[i], η[i]) for i in 1:n]
        grad = vcat(transpose(Xd) * s, transpose(Zd) * s .- (Ai * u) ./ sigma_a2)
        gnorm = norm(grad)
        WX = w .* Xd
        WZ = w .* Zd
        H = [transpose(Xd)*WX transpose(Xd)*WZ
             transpose(Zd)*WX (transpose(Zd)*WZ .+ Ai ./ sigma_a2)]
        step = Symmetric(H) \ grad
        beta .+= step[1:p]
        u .+= step[(p + 1):end]
        if gnorm < tol
            converged = true
            break
        end
    end

    η = Xd * beta .+ Zd * u
    w = [_fam_weight(_fam_record(family, i), yv[i], η[i]) for i in 1:n]
    WX = w .* Xd
    WZ = w .* Zd
    H = [transpose(Xd)*WX transpose(Xd)*WZ
         transpose(Zd)*WX (transpose(Zd)*WZ .+ Ai ./ sigma_a2)]
    cond = sum(_fam_loglik(_fam_record(family, i), yv[i], η[i]) for i in 1:n)
    quad_u = dot(u, Ai * u) / sigma_a2
    logdet_Ainv = logdet(cholesky(Symmetric(Ai)))
    logdet_H = logdet(cholesky(Symmetric(H)))
    loglik = cond - 0.5 * quad_u - 0.5 * q * log(sigma_a2) + 0.5 * logdet_Ainv +
             0.5 * p * log(2π) - 0.5 * logdet_H
    return (loglik = converged ? loglik : NaN, beta = beta, u = u, converged = converged,
            gradient_norm = gnorm, iterations = iters)
end

# Expected conditional loglik / score / weight under the variational posterior
# q, where η ~ N(η̄, v). Closed forms: Gaussian (identity link) and Poisson
# (log link, via the log-normal MGF E[exp η] = exp(η̄ + v/2)).
_fam_expected_loglik(f::GaussianResponse, y, ηbar, v) = _fam_loglik(f, y, ηbar) - 0.5 * v / f.sigma_e2
_fam_expected_score(f::GaussianResponse, y, ηbar, v) = (y - ηbar) / f.sigma_e2
_fam_expected_weight(f::GaussianResponse, ηbar, v) = 1.0 / f.sigma_e2

_fam_expected_loglik(::PoissonResponse, y, ηbar, v) = y * ηbar - exp(ηbar + 0.5 * v) - _logfactorial(y)
_fam_expected_score(::PoissonResponse, y, ηbar, v) = y - exp(ηbar + 0.5 * v)
_fam_expected_weight(::PoissonResponse, ηbar, v) = exp(ηbar + 0.5 * v)

# Gauss–Hermite rule (Golub–Welsch), built once at load time, for families whose
# Gaussian expectation E_{η~N(η̄,v)}[g(η)] has no closed form (e.g. Bernoulli logit).
const _GH_NODES, _GH_WEIGHTS = let m = 20
    E = eigen(SymTridiagonal(zeros(m), [sqrt(k / 2) for k in 1:(m - 1)]))
    (E.values, sqrt(π) .* (E.vectors[1, :] .^ 2))
end
# E[g(η)] with η ~ N(η̄, v): change of variables η = η̄ + √(2v)·x against e^{-x²}.
function _gh_expect(g, ηbar, v)
    s = sqrt(2.0 * v)
    acc = 0.0
    @inbounds for k in eachindex(_GH_NODES)
        acc += _GH_WEIGHTS[k] * g(ηbar + s * _GH_NODES[k])
    end
    return acc / sqrt(π)
end

# Bernoulli (logit): no closed-form Gaussian expectation, so integrate the log
# partition and its η̄-derivatives by Gauss–Hermite. Using the SAME nodes makes
# `_fam_expected_score`/`_fam_expected_weight` exactly the η̄-derivatives of
# `_fam_expected_loglik`, so the VA Newton step stays consistent with the ELBO.
_fam_expected_loglik(::BernoulliResponse, y, ηbar, v) = y * ηbar - _gh_expect(_log1pexp, ηbar, v)
_fam_expected_score(::BernoulliResponse, y, ηbar, v) = y - _gh_expect(_logistic, ηbar, v)
_fam_expected_weight(::BernoulliResponse, ηbar, v) =
    _gh_expect(η -> (p = _logistic(η); p * (1.0 - p)), ηbar, v)

_fam_expected_loglik(f::BinomialResponse, y, ηbar, v) =
    y * ηbar - f.n_trials * _gh_expect(_log1pexp, ηbar, v) + _logbinom(f.n_trials, Int(round(y)))
_fam_expected_score(f::BinomialResponse, y, ηbar, v) = y - f.n_trials * _gh_expect(_logistic, ηbar, v)
_fam_expected_weight(f::BinomialResponse, ηbar, v) =
    f.n_trials * _gh_expect(η -> (p = _logistic(η); p * (1.0 - p)), ηbar, v)

# Self-consistent variational covariance S = (Zᵀ W̃ Z + P0)⁻¹ and per-record
# marginal variances v = diag(Z S Zᵀ), with W̃ depending on (η̄, v). Fixed-point.
function _va_covariance(family, Zd, P0, ηbar, v0, n, tol, covariance)
    v = copy(v0)
    local S
    for _ in 1:200
        w = [_fam_expected_weight(_fam_record(family, i), ηbar[i], v[i]) for i in 1:n]
        Huu = transpose(Zd) * (w .* Zd) .+ P0
        S = covariance === :diagonal ? Diagonal(1.0 ./ diag(Huu)) : inv(Symmetric(Huu))
        ZS = Zd * S
        vnew = [dot(view(ZS, i, :), view(Zd, i, :)) for i in 1:n]
        change = maximum(abs.(vnew .- v))
        v = vnew
        change < tol && break
    end
    return S, v
end

"""
    variational_marginal_loglik(y, X, Z, Ainv, sigma_a2, family;
                                covariance = :full, tol = 1e-10, maxiter = 100)

Gaussian-variational (VA / ELBO) marginal for the non-Gaussian animal model — a
sibling of [`laplace_marginal_loglik`](@ref) that maximises the evidence lower
bound over a Gaussian variational posterior `q(u) = N(m, S)` for the correlated
random effect `u ~ N(0, A·σ²a)`, with `β` integrated under a flat prior.

`covariance = :full` (the validated foundation) profiles `S` to the closed-form
`S* = (Zᵀ W̃ Z + Ainv/σ²a)⁻¹` — the FULL joint covariance, which preserves the
pedigree relatedness (a diagonal / mean-field `S` would discard it and would not
be REML-exact). Returns
`(elbo, beta, m, S, converged, gradient_norm, iterations, covariance)`.

`elbo` is a LOWER BOUND on `log p(y)`, and is tight — equal to
[`laplace_marginal_loglik`](@ref) and to `sparse_reml_loglik` — for the Gaussian
family (the optimal full-covariance `q` is the exact Gaussian posterior, so the
KL vanishes). EXPERIMENTAL, dense, validation-scale; not exported, not wired into
fitting, no R model-spec. Architecture follows the MIT DRM.jl `:LA`/`:VA` idea;
the correlated-prior kernel is reimplemented here. Meaningful only when
`converged == true`.
"""
function variational_marginal_loglik(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                                     Ainv::AbstractMatrix, sigma_a2::Real,
                                     family::ResponseFamily;
                                     covariance::Symbol = :full,
                                     tol::Real = 1e-10, maxiter::Integer = 100)
    sigma_a2 > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    covariance in (:full, :diagonal) ||
        throw(ArgumentError("covariance must be :full or :diagonal"))
    yv = Float64.(y)
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    Ai = Matrix{Float64}(Ainv)
    n = length(yv)
    p = size(Xd, 2)
    q = size(Zd, 2)
    size(Xd, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Zd, 1) == n || throw(ArgumentError("Z must have one row per record"))
    size(Ai, 1) == q == size(Ai, 2) || throw(ArgumentError("Ainv must be q×q with q = size(Z,2)"))
    _check_counts(family, yv)
    P0 = Ai ./ sigma_a2

    beta = zeros(p)
    m = zeros(q)
    v = zeros(n)
    S = Matrix{Float64}(undef, q, q)
    gnorm = Inf
    iters = 0
    converged = false
    for outer_it in 1:maxiter
        iters = outer_it
        ηbar = Xd * beta .+ Zd * m
        S, v = _va_covariance(family, Zd, P0, ηbar, v, n, tol, covariance)
        w = [_fam_expected_weight(_fam_record(family, i), ηbar[i], v[i]) for i in 1:n]
        g = [_fam_expected_score(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n]
        grad = vcat(transpose(Xd) * g, transpose(Zd) * g .- P0 * m)
        gnorm = norm(grad)
        WX = w .* Xd
        WZ = w .* Zd
        H = [transpose(Xd)*WX transpose(Xd)*WZ
             transpose(Zd)*WX (transpose(Zd)*WZ .+ P0)]
        step = Symmetric(H) \ grad
        beta .+= step[1:p]
        m .+= step[(p + 1):end]
        if gnorm < tol
            converged = true
            break
        end
    end

    # ELBO and gradient at the returned mode
    ηbar = Xd * beta .+ Zd * m
    S, v = _va_covariance(family, Zd, P0, ηbar, v, n, tol, covariance)
    g = [_fam_expected_score(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n]
    gnorm = norm(vcat(transpose(Xd) * g, transpose(Zd) * g .- P0 * m))
    Ell = sum(_fam_expected_loglik(_fam_record(family, i), yv[i], ηbar[i], v[i]) for i in 1:n)
    logdet_Ainv = logdet(cholesky(Symmetric(Ai)))
    logdet_S = covariance === :diagonal ? sum(log, diag(S)) : logdet(cholesky(Symmetric(S)))
    kl = 0.5 * ((dot(m, Ai * m) + tr(Ai * S)) / sigma_a2 + q * log(sigma_a2) -
                logdet_Ainv - logdet_S - q)
    # β integrated under a flat prior (Laplace over β): the Schur-complement
    # curvature X'W̃X − X'W̃Z S Z'W̃X (= X'V⁻¹X for Gaussian) gives the REML-type
    # correction that makes the Gaussian ELBO tight (== sparse_reml_loglik).
    beta_term = 0.0
    if p > 0
        w = [_fam_expected_weight(_fam_record(family, i), ηbar[i], v[i]) for i in 1:n]
        XtWZ = transpose(Xd) * (w .* Zd)
        schur = Symmetric(transpose(Xd) * (w .* Xd) .- XtWZ * S * transpose(XtWZ))
        beta_term = 0.5 * p * log(2π) - 0.5 * logdet(cholesky(schur))
    end
    elbo = converged ? (Ell - kl + beta_term) : NaN
    return (elbo = elbo, beta = beta, m = m, S = S, converged = converged,
            gradient_norm = gnorm, iterations = iters, covariance = covariance)
end

"""
    NonGaussianFit

Experimental fitted-object container for the non-Gaussian animal model returned by
[`fit_laplace_reml`](@ref). Fields: `variance_components`, `marginal_loglik`,
`beta`, `breeding_values` (the posterior-mode random effect), `ids`, `converged`,
`family`, `marginal`, and `n_trials` (the Binomial trials denominator for
`family = :binomial` — a scalar common denominator or a per-record `Vector{Int}`;
`nothing` for every other family). Use the extractor
functions [`breeding_values`](@ref) (→ `BreedingValues(ids, values)`),
[`variance_components`](@ref), and [`fixed_effects`](@ref) for the same access
contract as [`AnimalModelFit`](@ref); this is a distinct type so its extractors do
not collide with the multivariate `NamedTuple` extractors.
"""
struct NonGaussianFit
    variance_components::NamedTuple
    marginal_loglik::Float64
    beta::Vector{Float64}
    breeding_values::Vector{Float64}
    ids::Vector
    converged::Bool
    family::Symbol
    marginal::Symbol
    n_trials::Union{Int,Vector{Int},Nothing}
end

variance_components(fit::NonGaussianFit) = fit.variance_components
fixed_effects(fit::NonGaussianFit) = fit.beta
breeding_values(fit::NonGaussianFit) = BreedingValues(fit.ids, fit.breeding_values)
EBV(fit::NonGaussianFit) = breeding_values(fit)

"""
    nongaussian_result_payload(fit::NonGaussianFit)

Bridge-ready, "boring" result payload (a `NamedTuple` of scalars / arrays /
nested `NamedTuple`s — Julia structs stay Julia-side) for a non-Gaussian
animal-model fit from [`fit_laplace_reml`](@ref). It mirrors the top-level shape
of [`multivariate_result_payload`](@ref) (the univariate [`result_payload`](@ref)
predates this convention and nests `method`/diagnostics differently) so the R twin
can marshal one shape and the R non-Gaussian family-acceptance can fire.

Fields: `engine`, `target = "nongaussian_reml"`, `family`
(`"gaussian"`/`"poisson"`/`"bernoulli"`/`"binomial"`), `n_trials` (the Binomial
trials denominator — a scalar common denominator or a per-record integer vector;
`nothing` for other families — so a binomial payload is self-describing on the data
scale), `method` (`"laplace"`/`"variational"`,
resolved through the internal `MarginalMethod` dispatch from the stored marginal
symbol), `variance_components`, `fixed_effects`, `breeding_values = (ids, values)`,
`loglik`, and `converged`.

The payload shape is deliberately **family-uniform** and therefore carries NO
`heritability` field: a `NonGaussianFit` computes none, and h² is left to the
consumer (it is derivable from `variance_components` for the Gaussian family, but
on the liability scale the logit/log-link families have no residual-variance scale
on which a single h² is defined here — surfacing one would be an unbacked claim).
EXPERIMENTAL: the fitter is not the public default, not wired into the R formula
path, and has no external comparator; the Bernoulli single-trial variance is
downward-biased (an information effect). The R-facing `method` token
(`"laplace"`/`"variational"`) and family-acceptance shape are pending R-lane
agreement before this is treated as a frozen contract.
"""
function nongaussian_result_payload(fit::NonGaussianFit)
    return (
        engine = "HSquared.jl",
        target = "nongaussian_reml",
        family = String(fit.family),
        n_trials = fit.n_trials isa AbstractVector ? copy(fit.n_trials) : fit.n_trials,
        method = _marginal_method_string(_marginal_method(fit.marginal)),
        variance_components = fit.variance_components,
        fixed_effects = copy(fit.beta),
        breeding_values = (ids = copy(fit.ids), values = copy(fit.breeding_values)),
        loglik = fit.marginal_loglik,
        converged = fit.converged,
    )
end

"""
    fit_laplace_reml(y, X, Z, Ainv; family = :gaussian, marginal = :laplace,
                     initial = nothing, ids = nothing, iterations = 200)

Estimate the variance component(s) of the non-Gaussian animal model by maximising
the marginal log-likelihood (`marginal = :laplace`) or the ELBO
(`marginal = :variational`) over the variance components. `family = :gaussian`
estimates `(sigma_a2, sigma_e2)` (NelderMead); `family = :poisson`,
`family = :bernoulli`, and `family = :binomial` (which requires the `n_trials`
keyword — a common scalar denominator OR a per-record integer vector of length
`length(y)`, the general `cbind(successes, failures)` GLMM) estimate the single
`sigma_a2` (Brent). Returns a [`NonGaussianFit`](@ref)
with fields `variance_components`, `marginal_loglik`, `beta`, `breeding_values`,
`ids`, `converged`, `family`, `marginal`, and the extractor methods
`breeding_values(fit)` / `variance_components(fit)` / `fixed_effects(fit)`.

Binary `:bernoulli` data carries little variance information at small scale, so
`sigma_a2` is prone to running to a search-bound boundary; `:binomial` with more
trials per record is more informative and recovers `sigma_a2` far better (see
`sim/phase6_binomial_recovery.jl`).

EXPERIMENTAL, dense/validation-scale — the first *fitted* non-Gaussian step.
For the Gaussian family the objective is the exact REML log-likelihood, so this
recovers the same estimate as [`fit_sparse_reml`](@ref). Exported as an
experimental fitter; not the public default, not wired into the R formula path,
no R model-spec, no external comparator.
"""
function fit_laplace_reml(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                          Ainv::AbstractMatrix; family::Symbol = :gaussian,
                          marginal::Symbol = :laplace, initial = nothing,
                          n_trials = nothing, ids = nothing, iterations::Integer = 200)
    family in (:gaussian, :poisson, :bernoulli, :binomial) ||
        throw(ArgumentError("family must be :gaussian, :poisson, :bernoulli, or :binomial"))
    family === :binomial && n_trials === nothing &&
        throw(ArgumentError("family = :binomial requires the n_trials keyword"))
    # `n_trials` may be a common scalar denominator OR a per-record integer vector
    # (the general cbind(successes, failures) GLMM). A vector must match the data and
    # carry integer counts; integer-valued reals are accepted (the R bridge marshals
    # doubles) but genuinely non-integer entries get a clean error, not a MethodError.
    if family === :binomial && n_trials isa AbstractVector
        length(n_trials) == length(y) ||
            throw(ArgumentError("a per-record n_trials vector must have length(n_trials) == length(y)"))
        all(isinteger, n_trials) ||
            throw(ArgumentError("a per-record n_trials vector must contain integer trial counts"))
    end
    # Resolve the marginal through the MarginalMethod dispatch (accepts the engine
    # :laplace/:variational and the DRM-style :LA/:VA spellings; throws otherwise),
    # then store the canonical symbol. Value-preserving for :laplace/:variational.
    mm = _marginal_method(marginal)
    marginal = _marginal_method_symbol(mm)
    margfun = mm isa Variational ? variational_marginal_loglik : laplace_marginal_loglik
    val(r) = mm isa Variational ? r.elbo : r.loglik
    aids = ids === nothing ? collect(1:size(Z, 2)) : collect(ids)
    if family === :gaussian
        sa0, se0 = initial === nothing ? (1.0, 1.0) :
                   (Float64(initial.sigma_a2), Float64(initial.sigma_e2))
        (sa0 > 0 && se0 > 0) || throw(ArgumentError("initial variances must be positive"))
        obj(p) = -val(margfun(y, X, Z, Ainv, exp(p[1]), GaussianResponse(exp(p[2]))))
        res = optimize(obj, log.([sa0, se0]), NelderMead(), Optim.Options(iterations = iterations))
        sa2, se2 = exp.(Optim.minimizer(res))
        fit = margfun(y, X, Z, Ainv, sa2, GaussianResponse(se2))
        return NonGaussianFit((sigma_a2 = sa2, sigma_e2 = se2), val(fit), fit.beta,
                              marginal === :variational ? fit.m : fit.u, aids,
                              Optim.converged(res) && fit.converged, :gaussian, marginal, nothing)
    else
        # single-variance-component families: Poisson (log link), Bernoulli/Binomial (logit)
        fam = _resolve_single_family(family, n_trials)
        sa0 = initial === nothing ? 1.0 : Float64(initial.sigma_a2)
        sa0 > 0 || throw(ArgumentError("initial sigma_a2 must be positive"))
        res = optimize(s -> -val(margfun(y, X, Z, Ainv, exp(s), fam)),
                       log(sa0) - 6.0, log(sa0) + 6.0)
        sa2 = exp(Optim.minimizer(res))
        fit = margfun(y, X, Z, Ainv, sa2, fam)
        stored_n = family !== :binomial ? nothing :
                   n_trials isa AbstractVector ? Vector{Int}(n_trials) : Int(n_trials)
        return NonGaussianFit((sigma_a2 = sa2,), val(fit), fit.beta,
                              marginal === :variational ? fit.m : fit.u, aids,
                              Optim.converged(res) && fit.converged, family, marginal,
                              stored_n)
    end
end

"""
    laplace_reml_interval(y, X, Z, Ainv; family = :poisson, marginal = :laplace,
                          level = 0.95, initial = nothing, n_trials = nothing)

Profile likelihood-ratio confidence interval for the single-variance-component
non-Gaussian animal-model `sigma_a2`, by inverting the marginal LRT
`2·(ℓ̂ − ℓ(sigma_a2)) ≤ χ²₁,level`. Returns
`(sigma_a2, lower, upper, level, lower_clamped, upper_clamped, converged)` — the
`*_clamped` flags report whether an endpoint reached the search bound (the profile
did not cross the χ² threshold within range) so a non-crossing endpoint is NOT a
confidence limit, and `converged` echoes the point-fit convergence; both make a
degenerate interval self-describing rather than a silent finite triple.

Supports the single-variance-component families `family = :poisson`,
`family = :bernoulli`, and `family = :binomial` (which requires `n_trials` — a
scalar common denominator or a per-record integer vector, the same contract as
[`fit_laplace_reml`](@ref)). The Gaussian two-component case needs nuisance
profiling and is future work.

This is a profile-LIKELIHOOD-ratio interval, so `marginal = :laplace` is required:
the variational `:VA` objective is the ELBO (a lower bound), not the marginal
log-likelihood, so `2·(ELBÔ − ELBO(σ²a))` is not χ²₁-calibrated — `:variational`
throws rather than return an uncalibrated quantity dressed as a CI.

EXPERIMENTAL, asymptotic, single-component only, NO coverage calibration. Whether
the interval is two-sided depends on where `σ̂²a` sits relative to the flat
near-zero region of the profile, NOT on the family alone: a Binomial fit whose
`σ̂²a` is clear of zero gives two interior LRT roots, but a small `σ̂²a` (or binary
`:bernoulli` data, which is uninformative about the latent variance) leaves a flat
profile so an endpoint reaches the search bound (flagged via `*_clamped`) — honest
but not a confidence limit (the same information effect that biases binary
`sigma_a2`). Reuses `_profile_root`.
"""
function laplace_reml_interval(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                               Ainv::AbstractMatrix; family::Symbol = :poisson,
                               marginal::Symbol = :laplace, level::Real = 0.95,
                               initial = nothing, n_trials = nothing)
    family in (:poisson, :bernoulli, :binomial) ||
        throw(ArgumentError("laplace_reml_interval supports family = :poisson, :bernoulli, or :binomial"))
    family === :binomial && n_trials === nothing &&
        throw(ArgumentError("family = :binomial requires the n_trials keyword"))
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    _marginal_method(marginal) isa Laplace ||
        throw(ArgumentError("laplace_reml_interval is a profile-LIKELIHOOD-ratio interval and requires marginal = :laplace; the variational ELBO is a lower bound, not a χ²₁-calibrated LRT statistic"))
    if family === :binomial && n_trials isa AbstractVector
        length(n_trials) == length(y) ||
            throw(ArgumentError("a per-record n_trials vector must have length(n_trials) == length(y)"))
        all(isinteger, n_trials) ||
            throw(ArgumentError("a per-record n_trials vector must contain integer trial counts"))
    end
    fam = _resolve_single_family(family, n_trials)
    fit = fit_laplace_reml(y, X, Z, Ainv; family = family, marginal = :laplace,
                           initial = initial, n_trials = n_trials)
    sa2hat = fit.variance_components.sigma_a2
    llhat = fit.marginal_loglik
    z = _standard_normal_quantile((1 + level) / 2)
    q = z * z
    target(sa2) = 2 * (llhat - laplace_marginal_loglik(y, X, Z, Ainv, sa2, fam).loglik) - q
    lo_bound = sa2hat * 1e-4
    up_bound = sa2hat * 1e4
    lower = _profile_root(target, lo_bound, sa2hat)
    upper = _profile_root(target, up_bound, sa2hat)
    # a clamp is exactly `_profile_root`'s non-crossing condition: the deviance never
    # reached the χ² threshold within the search range (so the endpoint is the bound).
    lower_clamped = target(lo_bound) <= 0
    upper_clamped = target(up_bound) <= 0
    return (sigma_a2 = sa2hat, lower = lower, upper = upper, level = level,
            lower_clamped = lower_clamped, upper_clamped = upper_clamped,
            converged = fit.converged)
end

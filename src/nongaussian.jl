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
# This is the `:LA` marginal; the `:VA` (variational) marginal is planned and
# will reuse the per-family kernels here (architecture adapted from the MIT
# DRM.jl `src/variational.jl` :LA/:VA dispatch). Families currently: Gaussian
# (identity link, exact) and Poisson (log link).
#
# NOT exported into the public/bridge surface; not wired into `fit_*`; no R
# model-spec. Validation: Gaussian reduces to `sparse_reml_loglik` to machine
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

# per-observation conditional log-density ℓ(y|η), score dℓ/dη, working weight -d²ℓ/dη²
_fam_loglik(f::GaussianResponse, y, η) = -0.5 * ((y - η)^2 / f.sigma_e2 + log(2π * f.sigma_e2))
_fam_score(f::GaussianResponse, y, η) = (y - η) / f.sigma_e2
_fam_weight(f::GaussianResponse, y, η) = 1.0 / f.sigma_e2

_fam_loglik(::PoissonResponse, y, η) = y * η - exp(η) - _logfactorial(y)
_fam_score(::PoissonResponse, y, η) = y - exp(η)
_fam_weight(::PoissonResponse, y, η) = exp(η)

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
        s = [_fam_score(family, yv[i], η[i]) for i in 1:n]
        w = [_fam_weight(family, yv[i], η[i]) for i in 1:n]
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
    w = [_fam_weight(family, yv[i], η[i]) for i in 1:n]
    WX = w .* Xd
    WZ = w .* Zd
    H = [transpose(Xd)*WX transpose(Xd)*WZ
         transpose(Zd)*WX (transpose(Zd)*WZ .+ Ai ./ sigma_a2)]
    cond = sum(_fam_loglik(family, yv[i], η[i]) for i in 1:n)
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

# Self-consistent variational covariance S = (Zᵀ W̃ Z + P0)⁻¹ and per-record
# marginal variances v = diag(Z S Zᵀ), with W̃ depending on (η̄, v). Fixed-point.
function _va_covariance(family, Zd, P0, ηbar, v0, n, tol, covariance)
    v = copy(v0)
    local S
    for _ in 1:200
        w = [_fam_expected_weight(family, ηbar[i], v[i]) for i in 1:n]
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
        w = [_fam_expected_weight(family, ηbar[i], v[i]) for i in 1:n]
        g = [_fam_expected_score(family, yv[i], ηbar[i], v[i]) for i in 1:n]
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
    g = [_fam_expected_score(family, yv[i], ηbar[i], v[i]) for i in 1:n]
    gnorm = norm(vcat(transpose(Xd) * g, transpose(Zd) * g .- P0 * m))
    Ell = sum(_fam_expected_loglik(family, yv[i], ηbar[i], v[i]) for i in 1:n)
    logdet_Ainv = logdet(cholesky(Symmetric(Ai)))
    logdet_S = covariance === :diagonal ? sum(log, diag(S)) : logdet(cholesky(Symmetric(S)))
    kl = 0.5 * ((dot(m, Ai * m) + tr(Ai * S)) / sigma_a2 + q * log(sigma_a2) -
                logdet_Ainv - logdet_S - q)
    # β integrated under a flat prior (Laplace over β): the Schur-complement
    # curvature X'W̃X − X'W̃Z S Z'W̃X (= X'V⁻¹X for Gaussian) gives the REML-type
    # correction that makes the Gaussian ELBO tight (== sparse_reml_loglik).
    beta_term = 0.0
    if p > 0
        w = [_fam_expected_weight(family, ηbar[i], v[i]) for i in 1:n]
        XtWZ = transpose(Xd) * (w .* Zd)
        schur = Symmetric(transpose(Xd) * (w .* Xd) .- XtWZ * S * transpose(XtWZ))
        beta_term = 0.5 * p * log(2π) - 0.5 * logdet(cholesky(schur))
    end
    elbo = converged ? (Ell - kl + beta_term) : NaN
    return (elbo = elbo, beta = beta, m = m, S = S, converged = converged,
            gradient_norm = gnorm, iterations = iters, covariance = covariance)
end

"""
    fit_laplace_reml(y, X, Z, Ainv; family = :gaussian, marginal = :laplace,
                     initial = nothing, iterations = 200)

Estimate the variance component(s) of the non-Gaussian animal model by maximising
the marginal log-likelihood (`marginal = :laplace`) or the ELBO
(`marginal = :variational`) over the variance components. `family = :gaussian`
estimates `(sigma_a2, sigma_e2)` (NelderMead); `family = :poisson` estimates
`sigma_a2` (Brent). Returns
`(variance_components, marginal_loglik, beta, converged, family, marginal)`.

EXPERIMENTAL, dense/validation-scale — the first *fitted* non-Gaussian step.
For the Gaussian family the objective is the exact REML log-likelihood, so this
recovers the same estimate as [`fit_sparse_reml`](@ref). Not exported, not the
public default, no R model-spec, no external comparator.
"""
function fit_laplace_reml(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                          Ainv::AbstractMatrix; family::Symbol = :gaussian,
                          marginal::Symbol = :laplace, initial = nothing,
                          iterations::Integer = 200)
    family in (:gaussian, :poisson) ||
        throw(ArgumentError("family must be :gaussian or :poisson"))
    marginal in (:laplace, :variational) ||
        throw(ArgumentError("marginal must be :laplace or :variational"))
    margfun = marginal === :variational ? variational_marginal_loglik : laplace_marginal_loglik
    val(r) = marginal === :variational ? r.elbo : r.loglik
    if family === :gaussian
        sa0, se0 = initial === nothing ? (1.0, 1.0) :
                   (Float64(initial.sigma_a2), Float64(initial.sigma_e2))
        (sa0 > 0 && se0 > 0) || throw(ArgumentError("initial variances must be positive"))
        obj(p) = -val(margfun(y, X, Z, Ainv, exp(p[1]), GaussianResponse(exp(p[2]))))
        res = optimize(obj, log.([sa0, se0]), NelderMead(), Optim.Options(iterations = iterations))
        sa2, se2 = exp.(Optim.minimizer(res))
        fit = margfun(y, X, Z, Ainv, sa2, GaussianResponse(se2))
        return (variance_components = (sigma_a2 = sa2, sigma_e2 = se2),
                marginal_loglik = val(fit), beta = fit.beta,
                breeding_values = (marginal === :variational ? fit.m : fit.u),
                converged = Optim.converged(res) && fit.converged,
                family = :gaussian, marginal = marginal)
    else
        sa0 = initial === nothing ? 1.0 : Float64(initial.sigma_a2)
        sa0 > 0 || throw(ArgumentError("initial sigma_a2 must be positive"))
        res = optimize(s -> -val(margfun(y, X, Z, Ainv, exp(s), PoissonResponse())),
                       log(sa0) - 6.0, log(sa0) + 6.0)
        sa2 = exp(Optim.minimizer(res))
        fit = margfun(y, X, Z, Ainv, sa2, PoissonResponse())
        return (variance_components = (sigma_a2 = sa2,),
                marginal_loglik = val(fit), beta = fit.beta,
                breeding_values = (marginal === :variational ? fit.m : fit.u),
                converged = Optim.converged(res) && fit.converged,
                family = :poisson, marginal = marginal)
    end
end

"""
    laplace_reml_interval(y, X, Z, Ainv; family = :poisson, marginal = :laplace,
                          level = 0.95, initial = nothing)

Profile likelihood-ratio confidence interval for the Poisson animal-model
variance component `sigma_a2`, by inverting the marginal LRT
`2·(ℓ̂ − ℓ(sigma_a2)) ≤ χ²₁,level`. Returns `(sigma_a2, lower, upper, level)`;
endpoints that reach the search bounds are clamped. EXPERIMENTAL, asymptotic,
Poisson only (a single variance component — the Gaussian two-component case needs
nuisance profiling and is future work). Reuses `_profile_root`.
"""
function laplace_reml_interval(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
                               Ainv::AbstractMatrix; family::Symbol = :poisson,
                               marginal::Symbol = :laplace, level::Real = 0.95, initial = nothing)
    family === :poisson ||
        throw(ArgumentError("laplace_reml_interval currently supports family = :poisson only"))
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    marginal in (:laplace, :variational) ||
        throw(ArgumentError("marginal must be :laplace or :variational"))
    margfun = marginal === :variational ? variational_marginal_loglik : laplace_marginal_loglik
    val(r) = marginal === :variational ? r.elbo : r.loglik
    fit = fit_laplace_reml(y, X, Z, Ainv; family = :poisson, marginal = marginal, initial = initial)
    sa2hat = fit.variance_components.sigma_a2
    llhat = fit.marginal_loglik
    z = _standard_normal_quantile((1 + level) / 2)
    q = z * z
    target(sa2) = 2 * (llhat - val(margfun(y, X, Z, Ainv, sa2, PoissonResponse()))) - q
    lower = _profile_root(target, sa2hat * 1e-4, sa2hat)
    upper = _profile_root(target, sa2hat * 1e4, sa2hat)
    return (sigma_a2 = sa2hat, lower = lower, upper = upper, level = level)
end

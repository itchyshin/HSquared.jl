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
    return (loglik = loglik, beta = beta, u = u, converged = converged,
            gradient_norm = gnorm, iterations = iters)
end

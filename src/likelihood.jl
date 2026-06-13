"""
    GaussianLikelihoodResult

Result from evaluating the Gaussian animal-model log-likelihood at supplied
variance components.
"""
struct GaussianLikelihoodResult
    loglik::Float64
    beta::Vector{Float64}
    sigma_a2::Float64
    sigma_e2::Float64
    method::Symbol
    nobs::Int
    nfixed::Int
end

"""
    gaussian_loglik(spec, sigma_a2, sigma_e2; method = spec.method)

Evaluate the Gaussian ML or REML log-likelihood at supplied variance
components.

This Phase 1 evaluator is deliberately conservative: it forms dense matrices
from the validated `AnimalModelSpec` so the likelihood can be tested before the
production sparse solver lands. It does not optimize variance components and
does not return a fitted model.
"""
function gaussian_loglik(
    spec::AnimalModelSpec,
    sigma_a2::Real,
    sigma_e2::Real;
    method = spec.method,
)
    sigma_a2 > 0 ||
        throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 ||
        throw(ArgumentError("sigma_e2 must be positive"))

    normalized_method = _coerce_method(method)
    normalized_method in (:ML, :REML) ||
        throw(ArgumentError("method must be :ML or :REML"))

    y = Float64.(spec.y)
    X = Matrix{Float64}(spec.X)
    Z = Matrix{Float64}(spec.Z)
    Ainv = Matrix{Float64}(spec.Ainv)

    n = length(y)
    p = size(X, 2)
    normalized_method == :REML && p >= n &&
        throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    A = inv(Symmetric(Ainv))
    V = Symmetric(sigma_a2 * Z * A * transpose(Z) + sigma_e2 * I(n))
    cholV = cholesky(V; check = true)

    Vinv_y = cholV \ y
    Vinv_X = cholV \ X
    XtVinvX = Symmetric(transpose(X) * Vinv_X)
    cholXtVinvX = cholesky(XtVinvX; check = true)
    beta = cholXtVinvX \ (transpose(X) * Vinv_y)

    residual = y - X * beta
    quad = dot(residual, cholV \ residual)
    logdetV = logdet(cholV)

    loglik = if normalized_method == :ML
        -0.5 * (n * log(2 * pi) + logdetV + quad)
    else
        logdetXtVinvX = logdet(cholXtVinvX)
        -0.5 * ((n - p) * log(2 * pi) + logdetV + logdetXtVinvX + quad)
    end

    return GaussianLikelihoodResult(
        loglik,
        beta,
        Float64(sigma_a2),
        Float64(sigma_e2),
        normalized_method,
        n,
        p,
    )
end

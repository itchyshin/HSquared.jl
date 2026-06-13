const DEFAULT_MAX_DENSE_CELLS = 1_000_000

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
    AnimalModelFit

Experimental low-level Gaussian animal-model fit object.

This is returned only for validated [`AnimalModelSpec`](@ref) inputs. It uses
the current dense likelihood evaluator and a conservative optimizer path.
"""
struct AnimalModelFit{TS<:AnimalModelSpec}
    spec::TS
    likelihood::GaussianLikelihoodResult
    variance_components::NamedTuple{(:sigma_a2, :sigma_e2),Tuple{Float64,Float64}}
    converged::Bool
    optimizer_status::String
    iterations::Int
end

"""
    BreedingValues

Experimental low-level container for animal-effect BLUPs/EBVs.
"""
struct BreedingValues{TID<:AbstractVector}
    ids::TID
    values::Vector{Float64}
end

"""
    HendersonMMEResult

Result from solving Henderson's mixed-model equations at supplied variance
components.

This is a Phase 1 engine utility. It uses sparse design and relationship
precision matrices, but it does not estimate variance components and is not a
production sparse fitting claim by itself.
"""
struct HendersonMMEResult{TS<:AnimalModelSpec,TID<:AbstractVector}
    spec::TS
    beta::Vector{Float64}
    animal_effects::BreedingValues{TID}
    sigma_a2::Float64
    sigma_e2::Float64
end

"""
    gaussian_loglik(spec, sigma_a2, sigma_e2; method = spec.method,
                    max_dense_cells = 1_000_000)

Evaluate the Gaussian ML or REML log-likelihood at supplied variance
components.

This Phase 1 evaluator is deliberately conservative: it forms dense matrices
from the validated `AnimalModelSpec` so the likelihood can be tested before the
production sparse solver lands. It does not optimize variance components and
does not return a fitted model. `max_dense_cells` is a safety guard for this
temporary dense path.
"""
function gaussian_loglik(
    spec::AnimalModelSpec,
    sigma_a2::Real,
    sigma_e2::Real;
    method = spec.method,
    max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS,
)
    sigma_a2 > 0 ||
        throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 ||
        throw(ArgumentError("sigma_e2 must be positive"))

    normalized_method = _coerce_method(method)
    normalized_method in (:ML, :REML) ||
        throw(ArgumentError("method must be :ML or :REML"))
    _check_dense_validation_size(spec, max_dense_cells)

    y = Float64.(spec.y)
    X = Matrix{Float64}(spec.X)
    Z = Matrix{Float64}(spec.Z)
    Ainv = Matrix{Float64}(spec.Ainv)

    n = length(y)
    p = size(X, 2)
    normalized_method == :REML && p >= n &&
        throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    A = inv(Symmetric(Ainv))
    V = _dense_marginal_covariance(Z, A, sigma_a2, sigma_e2)
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

"""
    sparse_reml_loglik(spec, sigma_a2, sigma_e2)

Evaluate the Gaussian REML log-likelihood at supplied positive variance
components using the sparse Henderson mixed-model-equation identity.

This is a Phase 1 validation bridge toward the production sparse optimizer. It
does not estimate variance components and it only evaluates REML.
"""
function sparse_reml_loglik(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    sigma_a2 > 0 ||
        throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 ||
        throw(ArgumentError("sigma_e2 must be positive"))

    n = length(spec.y)
    p = size(spec.X, 2)
    p < n ||
        throw(ArgumentError("REML requires fewer fixed-effect columns than observations"))

    lhs, rhs, y_precision_y = _sparse_mme_system(spec, sigma_a2, sigma_e2)
    lhs_factor = cholesky(Symmetric(lhs); check = true)
    solution = lhs_factor \ rhs

    q = size(spec.Ainv, 1)
    Ainv = sparse(Float64.(spec.Ainv))
    Ainv_factor = cholesky(Symmetric(Ainv); check = true)

    logdetR = n * log(Float64(sigma_e2))
    logdetG = q * log(Float64(sigma_a2)) - logdet(Ainv_factor)
    logdetC = logdet(lhs_factor)
    quad = y_precision_y - dot(rhs, solution)
    loglik = -0.5 * ((n - p) * log(2 * pi) + logdetR + logdetG + logdetC + quad)

    return GaussianLikelihoodResult(
        loglik,
        Vector{Float64}(solution[1:p]),
        Float64(sigma_a2),
        Float64(sigma_e2),
        :REML,
        n,
        p,
    )
end

"""
    fit_variance_components(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
                            method = spec.method, iterations = 1_000,
                            max_dense_cells = 1_000_000)

Optimize the dense Gaussian ML/REML objective over positive variance
components.

The optimizer works on log-variance parameters and uses `Optim.NelderMead()`.
This is an experimental Phase 1 path for tiny validation examples. It is not
AI-REML and is not the production sparse solver.
"""
function fit_variance_components(
    spec::AnimalModelSpec;
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    method = spec.method,
    iterations::Integer = 1_000,
    max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS,
)
    sigma_a2_start, sigma_e2_start = _coerce_initial_variances(initial)
    sigma_a2_start > 0 ||
        throw(ArgumentError("initial sigma_a2 must be positive"))
    sigma_e2_start > 0 ||
        throw(ArgumentError("initial sigma_e2 must be positive"))

    normalized_method = _coerce_method(method)
    _check_dense_validation_size(spec, max_dense_cells)
    objective(logtheta) = -gaussian_loglik(
        spec,
        exp(logtheta[1]),
        exp(logtheta[2]);
        method = normalized_method,
        max_dense_cells = max_dense_cells,
    ).loglik

    result = optimize(
        objective,
        log.([sigma_a2_start, sigma_e2_start]),
        NelderMead(),
        Optim.Options(iterations = iterations),
    )

    sigma_a2, sigma_e2 = exp.(Optim.minimizer(result))
    likelihood = gaussian_loglik(
        spec,
        sigma_a2,
        sigma_e2;
        method = normalized_method,
        max_dense_cells = max_dense_cells,
    )
    converged = Optim.converged(result)
    status = converged ? "converged" : "not_converged"

    return AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        converged,
        status,
        Optim.iterations(result),
    )
end

"""
    henderson_mme(spec, sigma_a2, sigma_e2)

Solve Henderson's mixed-model equations for fixed effects and animal-effect
BLUPs/EBVs at supplied positive variance components.

This forms the sparse equation system
`[X'R^-1X  X'R^-1Z; Z'R^-1X  Z'R^-1Z + Ainv / sigma_a2]` with
`R = sigma_e2 I`. It is a supplied-variance solver and does not optimize
variance components.
"""
function henderson_mme(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    sigma_a2 > 0 ||
        throw(ArgumentError("sigma_a2 must be positive"))
    sigma_e2 > 0 ||
        throw(ArgumentError("sigma_e2 must be positive"))

    lhs, rhs, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)

    solution = lhs \ rhs
    nfixed = size(spec.X, 2)
    beta = Vector{Float64}(solution[1:nfixed])
    animal_effects = BreedingValues(
        collect(spec.ids),
        Vector{Float64}(solution[(nfixed + 1):end]),
    )

    return HendersonMMEResult(
        spec,
        beta,
        animal_effects,
        Float64(sigma_a2),
        Float64(sigma_e2),
    )
end

function fit_animal_model(spec::AnimalModelSpec; kwargs...)
    return fit_variance_components(spec; kwargs...)
end

function fit_animal_model(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix;
    ids = nothing,
    family = GaussianFamily(),
    method = :REML,
    kwargs...,
)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ids, family = family, method = method)
    return fit_variance_components(spec; method = spec.method, kwargs...)
end

"""
    variance_components(fit)

Return the additive and residual variance components from an experimental
low-level [`AnimalModelFit`](@ref).
"""
function variance_components(fit::AnimalModelFit)
    return fit.variance_components
end

"""
    fixed_effects(fit)

Return the fixed-effect estimates from an experimental low-level
[`AnimalModelFit`](@ref).
"""
function fixed_effects(fit::AnimalModelFit)
    return copy(fit.likelihood.beta)
end

function fixed_effects(result::HendersonMMEResult)
    return copy(result.beta)
end

"""
    breeding_values(fit)

Return dense animal-effect BLUPs/EBVs for an experimental low-level
[`AnimalModelFit`](@ref).

The current implementation uses the dense Gaussian covariance equations:
`u_hat = sigma_a2 * A * Z' * V^-1 * (y - X * beta)`. It is for tiny validation
examples, not production sparse solves.
"""
function breeding_values(fit::AnimalModelFit)
    spec = fit.spec
    sigma_a2 = fit.variance_components.sigma_a2
    sigma_e2 = fit.variance_components.sigma_e2

    y = Float64.(spec.y)
    X = Matrix{Float64}(spec.X)
    Z = Matrix{Float64}(spec.Z)
    A = inv(Symmetric(Matrix{Float64}(spec.Ainv)))

    V = _dense_marginal_covariance(Z, A, sigma_a2, sigma_e2)
    residual = y - X * fit.likelihood.beta
    values = sigma_a2 * A * transpose(Z) * (cholesky(V; check = true) \ residual)

    return BreedingValues(collect(spec.ids), Vector{Float64}(values))
end

function breeding_values(result::HendersonMMEResult)
    return BreedingValues(result.animal_effects.ids, copy(result.animal_effects.values))
end

"""
    fitted_values(fit; include_random = true)

Return fitted values for an experimental low-level [`AnimalModelFit`](@ref).
"""
function fitted_values(fit::AnimalModelFit; include_random::Bool = true)
    spec = fit.spec
    X = Matrix{Float64}(spec.X)
    fitted = X * fit.likelihood.beta

    if include_random
        Z = Matrix{Float64}(spec.Z)
        fitted = fitted + Z * breeding_values(fit).values
    end

    return Vector{Float64}(fitted)
end

function fitted_values(result::HendersonMMEResult; include_random::Bool = true)
    spec = result.spec
    fitted = Matrix{Float64}(spec.X) * result.beta

    if include_random
        fitted = fitted + Matrix{Float64}(spec.Z) * result.animal_effects.values
    end

    return Vector{Float64}(fitted)
end

"""
    heritability(fit)

Return simple narrow-sense heritability for the Phase 1 univariate Gaussian
animal model: `sigma_a2 / (sigma_a2 + sigma_e2)`.
"""
function heritability(fit::AnimalModelFit)
    vc = fit.variance_components
    return vc.sigma_a2 / (vc.sigma_a2 + vc.sigma_e2)
end

"""
    prediction_error_variance(fit)

Return dense prediction error variances for animal-effect BLUPs/EBVs from an
experimental low-level [`AnimalModelFit`](@ref).

The current implementation forms and inverts the dense mixed-model-equation
coefficient matrix. It is a validation-path extractor for tiny examples, not a
production sparse reliability calculation.
"""
function prediction_error_variance(fit::AnimalModelFit)
    block = _dense_mme_random_inverse_block(
        fit.spec,
        fit.variance_components.sigma_a2,
        fit.variance_components.sigma_e2,
    )
    return (ids = collect(fit.spec.ids), values = Vector{Float64}(diag(block)))
end

"""
    prediction_error_variance(result::HendersonMMEResult)

Return dense prediction error variances for a supplied-variance Henderson MME
result.

This uses the same dense inverse of the mixed-model-equation coefficient matrix
as [`prediction_error_variance(::AnimalModelFit)`](@ref). It is a tiny
validation-path extractor, not production sparse selected inversion.
"""
function prediction_error_variance(result::HendersonMMEResult)
    block = _dense_mme_random_inverse_block(
        result.spec,
        result.sigma_a2,
        result.sigma_e2,
    )
    return (ids = collect(result.spec.ids), values = Vector{Float64}(diag(block)))
end

"""
    reliability(fit)

Return dense animal-level reliability values for the Phase 1 univariate animal
model.

Reliability is computed as `1 - PEV_i / (sigma_a2 * A_ii)` using the dense
relationship matrix implied by `Ainv`. Values are not clipped; small examples
can expose weakly informed animals directly.
"""
function reliability(fit::AnimalModelFit)
    pev = prediction_error_variance(fit)
    A = inv(Symmetric(Matrix{Float64}(fit.spec.Ainv)))
    animal_variance = fit.variance_components.sigma_a2 .* diag(A)

    all(>(0), animal_variance) ||
        throw(ArgumentError("animal-level additive variances must be positive"))

    return (
        ids = pev.ids,
        values = Vector{Float64}(1 .- pev.values ./ animal_variance),
    )
end

function reliability(result::HendersonMMEResult)
    pev = prediction_error_variance(result)
    A = inv(Symmetric(Matrix{Float64}(result.spec.Ainv)))
    animal_variance = result.sigma_a2 .* diag(A)

    all(>(0), animal_variance) ||
        throw(ArgumentError("animal-level additive variances must be positive"))

    return (
        ids = pev.ids,
        values = Vector{Float64}(1 .- pev.values ./ animal_variance),
    )
end

"""
    result_payload(fit)

Return a bridge-facing result payload with field names aligned to the R
`hsquared_fit` contract.

This is a dense experimental payload. It is intended to make the R-Julia result
shape explicit before live bridge execution is wired.
"""
function result_payload(fit::AnimalModelFit)
    vc = variance_components(fit)
    beta = fixed_effects(fit)
    bv = breeding_values(fit)
    predictions = fitted_values(fit)

    return (
        variance_components = vc,
        heritability = heritability(fit),
        breeding_values = (ids = bv.ids, values = bv.values),
        fixed_effects = beta,
        random_effects = (animal = (ids = bv.ids, values = bv.values),),
        loglik = fit.likelihood.loglik,
        df = fit.likelihood.nfixed + length(vc),
        nobs = fit.likelihood.nobs,
        predictions = predictions,
        diagnostics = (
            converged = fit.converged,
            optimizer_status = fit.optimizer_status,
            iterations = fit.iterations,
            method = fit.likelihood.method,
            dense_validation_path = true,
        ),
        converged = fit.converged,
    )
end

function _coerce_initial_variances(initial::NamedTuple)
    haskey(initial, :sigma_a2) ||
        throw(ArgumentError("initial must include sigma_a2"))
    haskey(initial, :sigma_e2) ||
        throw(ArgumentError("initial must include sigma_e2"))
    return Float64(initial.sigma_a2), Float64(initial.sigma_e2)
end

function _coerce_initial_variances(initial::Tuple)
    length(initial) == 2 ||
        throw(ArgumentError("initial must contain two variance components"))
    return Float64(initial[1]), Float64(initial[2])
end

function _coerce_initial_variances(initial::AbstractVector)
    length(initial) == 2 ||
        throw(ArgumentError("initial must contain two variance components"))
    return Float64(initial[1]), Float64(initial[2])
end

function _coerce_initial_variances(initial)
    throw(ArgumentError("initial must be a NamedTuple, tuple, or vector"))
end

function _dense_marginal_covariance(Z::AbstractMatrix, A::AbstractMatrix, sigma_a2, sigma_e2)
    n = size(Z, 1)
    return Symmetric(sigma_a2 * Z * A * transpose(Z) + sigma_e2 * I(n))
end

function _sparse_mme_system(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    y = Float64.(spec.y)
    X = sparse(Float64.(spec.X))
    Z = sparse(Float64.(spec.Z))
    Ainv = sparse(Float64.(spec.Ainv))

    residual_precision = inv(Float64(sigma_e2))
    relationship_precision = inv(Float64(sigma_a2))

    Xt = transpose(X)
    Zt = transpose(Z)
    lhs = [
        residual_precision * (Xt * X) residual_precision * (Xt * Z)
        residual_precision * (Zt * X) residual_precision * (Zt * Z) + relationship_precision * Ainv
    ]
    rhs = [
        residual_precision * (Xt * y);
        residual_precision * (Zt * y)
    ]

    return lhs, rhs, residual_precision * dot(y, y)
end

function _check_dense_validation_size(spec::AnimalModelSpec, max_dense_cells::Integer)
    max_dense_cells > 0 ||
        throw(ArgumentError("max_dense_cells must be a positive integer"))

    nobs = length(spec.y)
    nanimals = size(spec.Ainv, 1)
    dense_cells = nobs * nobs + nanimals * nanimals
    dense_cells <= max_dense_cells ||
        throw(
            ArgumentError(
                "dense validation path would allocate at least $(dense_cells) dense covariance/relationship cells; increase max_dense_cells for tiny validation work or wait for the sparse production solver",
            ),
        )

    return dense_cells
end

function _dense_mme_random_inverse_block(
    spec::AnimalModelSpec,
    sigma_a2::Real,
    sigma_e2::Real,
)
    X = Matrix{Float64}(spec.X)
    Z = Matrix{Float64}(spec.Z)
    Ainv = Matrix{Float64}(spec.Ainv)

    residual_precision = inv(sigma_e2)
    relationship_precision = Ainv / sigma_a2

    lhs = [
        residual_precision * transpose(X) * X residual_precision * transpose(X) * Z
        residual_precision * transpose(Z) * X residual_precision * transpose(Z) * Z + relationship_precision
    ]
    inverse_lhs = inv(Symmetric(lhs))
    nfixed = size(X, 2)
    return inverse_lhs[(nfixed + 1):end, (nfixed + 1):end]
end

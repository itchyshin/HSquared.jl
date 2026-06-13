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
the current dense likelihood evaluator or sparse REML validation objective and
a conservative optimizer path.
"""
struct AnimalModelFit{TS<:AnimalModelSpec}
    spec::TS
    likelihood::GaussianLikelihoodResult
    variance_components::NamedTuple{(:sigma_a2, :sigma_e2),Tuple{Float64,Float64}}
    converged::Bool
    optimizer_status::String
    iterations::Int
    target::Symbol
    dense_validation_path::Bool
    sparse_mme_path::Bool
    variance_components_source::Symbol
end

function AnimalModelFit(
    spec::AnimalModelSpec,
    likelihood::GaussianLikelihoodResult,
    variance_components::NamedTuple{(:sigma_a2, :sigma_e2),Tuple{Float64,Float64}},
    converged::Bool,
    optimizer_status::AbstractString,
    iterations::Integer,
)
    return AnimalModelFit(
        spec,
        likelihood,
        variance_components,
        converged,
        String(optimizer_status),
        Int(iterations),
        :variance_components,
        true,
        false,
        :estimated_dense_validation,
    )
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
    fit_sparse_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
                    iterations = 1_000)

Optimize the sparse Gaussian REML validation objective over positive variance
components.

The optimizer works on log-variance parameters and uses
[`sparse_reml_loglik`](@ref) as the objective. This is a Phase 1 validation
path toward sparse fitting. It is REML-only, not AI-REML, not the default
fitting path, and not a production sparse solver.
"""
function fit_sparse_reml(
    spec::AnimalModelSpec;
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 1_000,
)
    spec.method == :REML ||
        throw(ArgumentError("fit_sparse_reml requires spec.method == :REML"))
    sigma_a2_start, sigma_e2_start = _coerce_initial_variances(initial)
    sigma_a2_start > 0 ||
        throw(ArgumentError("initial sigma_a2 must be positive"))
    sigma_e2_start > 0 ||
        throw(ArgumentError("initial sigma_e2 must be positive"))

    function objective(logtheta)
        try
            return -sparse_reml_loglik(
                spec,
                exp(logtheta[1]),
                exp(logtheta[2]),
            ).loglik
        catch err
            err isa PosDefException && return Inf
            rethrow()
        end
    end

    result = optimize(
        objective,
        log.([sigma_a2_start, sigma_e2_start]),
        NelderMead(),
        Optim.Options(iterations = iterations),
    )

    sigma_a2, sigma_e2 = exp.(Optim.minimizer(result))
    likelihood = sparse_reml_loglik(spec, sigma_a2, sigma_e2)
    converged = Optim.converged(result)
    status = converged ? "converged" : "not_converged"

    return AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        converged,
        status,
        Optim.iterations(result),
        :sparse_reml,
        false,
        true,
        :estimated_sparse_reml_validation,
    )
end

"""
    fit_ai_reml(spec; initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
                iterations = 100, tol = 1e-8)

Estimate the Phase 1 Gaussian animal-model variance components by
average-information (AI) REML.

Each iteration solves the sparse Henderson mixed-model equations, reads the
variance-component score from the BLUP solution and the Takahashi selected
inverse (the `tr(Ainv * C^uu)` term), forms the average-information matrix from
two working-variate re-solves that reuse the same Cholesky factor, and takes an
AI/Newton step with step-halving to keep the variance components positive.

REML-only and experimental: it is validated to recover the same optimum as the
dense and sparse NelderMead optimizers, but is not yet checked against external
comparators or hardened for boundary/large-pedigree cases. The AI form is exact
for the *Gaussian* linear mixed model (the information matrix uses the data
directly, so it matches the observed information); it does NOT transfer to
Laplace-approximated / non-Gaussian models, where observed-information Newton is
required instead.
"""
function fit_ai_reml(
    spec::AnimalModelSpec;
    initial = (sigma_a2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 100,
    tol::Real = 1e-8,
)
    spec.method == :REML ||
        throw(ArgumentError("fit_ai_reml requires spec.method == :REML"))
    sigma_a2, sigma_e2 = _coerce_initial_variances(initial)
    sigma_a2 > 0 || throw(ArgumentError("initial sigma_a2 must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("initial sigma_e2 must be positive"))

    X = Float64.(spec.X)
    Z = sparse(Float64.(spec.Z))
    Ainv = sparse(Float64.(spec.Ainv))
    y = Float64.(spec.y)
    nfixed = size(X, 2)
    nrandom = size(Z, 2)
    nobs = length(y)

    converged = false
    iters = 0
    for it in 1:iterations
        iters = it
        lhs, rhs, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)
        factor = cholesky(Symmetric(lhs); check = true)
        solution = factor \ rhs
        beta = solution[1:nfixed]
        u = solution[(nfixed + 1):end]
        e = y .- X * beta .- Z * u
        trace_AC =
            sum(Ainv .* takahashi_selinv(factor)[(nfixed + 1):end, (nfixed + 1):end])
        uAu = dot(u, Ainv * u)

        score_a = -0.5 / sigma_a2^2 * (nrandom * sigma_a2 - trace_AC - uAu)
        score_e =
            -0.5 / sigma_e2^2 *
            (sigma_e2 * (nobs - nfixed - nrandom + trace_AC / sigma_a2) - dot(e, e))
        if hypot(score_a, score_e) < tol
            converged = true
            break
        end

        wa = (Z * u) ./ sigma_a2
        we = e ./ sigma_e2
        Pwa = _reml_project(factor, X, Z, wa, sigma_e2, nfixed)
        Pwe = _reml_project(factor, X, Z, we, sigma_e2, nfixed)
        information = 0.5 .* [dot(wa, Pwa) dot(wa, Pwe); dot(we, Pwa) dot(we, Pwe)]
        step = _ai_newton_step(information, [score_a, score_e])

        a_new = sigma_a2 + step[1]
        e_new = sigma_e2 + step[2]
        halvings = 0
        while (a_new <= 0 || e_new <= 0) && halvings < 60
            step = step ./ 2
            a_new = sigma_a2 + step[1]
            e_new = sigma_e2 + step[2]
            halvings += 1
        end
        (a_new > 0 && e_new > 0) || throw(
            ErrorException(
                "fit_ai_reml could not keep variance components positive; try a different start",
            ),
        )
        sigma_a2, sigma_e2 = a_new, e_new
    end

    likelihood = sparse_reml_loglik(spec, sigma_a2, sigma_e2)
    status = converged ? "converged" : "not_converged"
    return AnimalModelFit(
        spec,
        likelihood,
        (sigma_a2 = sigma_a2, sigma_e2 = sigma_e2),
        converged,
        status,
        iters,
        :ai_reml,
        false,
        true,
        :estimated_ai_reml,
    )
end

# Apply the REML projection P to a vector via an MME re-solve that reuses
# `factor`: P w = (w - X b_w - Z u_w) / sigma_e2, where [b_w; u_w] solves the
# mixed-model equations with `w` in place of `y`.
function _reml_project(factor, X, Z, w, sigma_e2, nfixed)
    solution =
        factor \ vcat(transpose(X) * w ./ sigma_e2, transpose(Z) * w ./ sigma_e2)
    return (w .- X * solution[1:nfixed] .- Z * solution[(nfixed + 1):end]) ./ sigma_e2
end

# AI/Newton step for the 2x2 average-information matrix (symmetric PSD); ridge
# slightly if it is near-singular so the solve stays stable near a boundary.
function _ai_newton_step(information, score)
    detinfo = information[1, 1] * information[2, 2] - information[1, 2]^2
    scale = abs(information[1, 1]) * abs(information[2, 2]) + 1.0
    matrix = if detinfo <= 1e-12 * scale
        Symmetric(information + 1e-8 * (tr(information) / 2 + 1) * Matrix{Float64}(I, 2, 2))
    else
        Symmetric(information)
    end
    return matrix \ score
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

"""
    fit_animal_model(spec; target = :variance_components, ...)

Fit or solve the Phase 1 Gaussian animal-model engine target for a validated
[`AnimalModelSpec`](@ref).

The default `target = :variance_components` dispatches to
[`fit_variance_components`](@ref), the experimental dense validation optimizer.
`target = :sparse_reml` dispatches to [`fit_sparse_reml`](@ref), the
experimental sparse REML validation optimizer.
`target = :henderson_mme` requires supplied `variance_components` and returns a
[`HendersonMMEResult`](@ref). The Henderson target solves mixed-model equations
at supplied variance components; it does not estimate them and does not return
log-likelihood, AIC, `df`, or optimizer diagnostics.
"""
function fit_animal_model(
    spec::AnimalModelSpec;
    target = :variance_components,
    variance_components = nothing,
    kwargs...,
)
    normalized_target = _coerce_fit_target(target)

    if normalized_target == :variance_components
        variance_components === nothing ||
            throw(ArgumentError("variance_components is only used when target = :henderson_mme"))
        return fit_variance_components(spec; kwargs...)
    end

    if normalized_target == :sparse_reml
        variance_components === nothing ||
            throw(ArgumentError("variance_components is not used when target = :sparse_reml"))
        return fit_sparse_reml(spec; kwargs...)
    end

    if normalized_target == :ai_reml
        variance_components === nothing ||
            throw(ArgumentError("variance_components is not used when target = :ai_reml"))
        return fit_ai_reml(spec; kwargs...)
    end

    isempty(kwargs) ||
        throw(ArgumentError("target = :henderson_mme does not accept optimizer keyword arguments"))
    sigma_a2, sigma_e2 = _coerce_supplied_variance_components(variance_components)
    return henderson_mme(spec, sigma_a2, sigma_e2)
end

function fit_animal_model(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix;
    ids = nothing,
    family = GaussianFamily(),
    method = :REML,
    target = :variance_components,
    variance_components = nothing,
    kwargs...,
)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ids, family = family, method = method)
    return fit_animal_model(
        spec;
        target = target,
        variance_components = variance_components,
        kwargs...,
    )
end

"""
    variance_components(fit)

Return the additive and residual variance components from an experimental
low-level [`AnimalModelFit`](@ref).
"""
function variance_components(fit::AnimalModelFit)
    return fit.variance_components
end

function variance_components(result::HendersonMMEResult)
    return (sigma_a2 = result.sigma_a2, sigma_e2 = result.sigma_e2)
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
    fit_diagnostics(fit)

Return compact status metadata for an experimental low-level fit result.

This is an extractor over fields already stored on the result object. It does
not refit a model, run an optimizer, compute PEV/reliability, or change the
bridge-facing [`result_payload`](@ref) contract.
"""
function fit_diagnostics(fit::AnimalModelFit)
    vc = variance_components(fit)

    return (
        engine = :julia,
        result_type = :animal_model_fit,
        target = fit.target,
        method = fit.likelihood.method,
        family = :gaussian,
        converged = fit.converged,
        optimizer_status = fit.optimizer_status,
        iterations = fit.iterations,
        loglik = fit.likelihood.loglik,
        df = fit.likelihood.nfixed + length(vc),
        nobs = fit.likelihood.nobs,
        dense_validation_path = fit.dense_validation_path,
        sparse_mme_path = fit.sparse_mme_path,
        variance_components_source = fit.variance_components_source,
    )
end

function fit_diagnostics(result::HendersonMMEResult)
    return (
        engine = :julia,
        result_type = :henderson_mme,
        target = :henderson_mme,
        method = result.spec.method,
        family = :gaussian,
        converged = true,
        optimizer_status = "not_applicable",
        iterations = 0,
        loglik = nothing,
        df = nothing,
        nobs = length(result.spec.y),
        dense_validation_path = false,
        sparse_mme_path = true,
        variance_components_source = :supplied,
    )
end

"""
    breeding_values(fit)

Return animal-effect BLUPs/EBVs for an experimental low-level
[`AnimalModelFit`](@ref).

The current implementation solves Henderson's mixed-model equations at the
fit's variance components and returns the animal-effect block. Variance
component estimation is still the experimental dense path; this only changes
the EBV/BLUP extraction equation solve.
"""
function breeding_values(fit::AnimalModelFit)
    vc = fit.variance_components
    return breeding_values(henderson_mme(fit.spec, vc.sigma_a2, vc.sigma_e2))
end

function breeding_values(result::HendersonMMEResult)
    return BreedingValues(result.animal_effects.ids, copy(result.animal_effects.values))
end

"""
    EBV(fit)

Alias for [`breeding_values`](@ref), matching the R twin's applied
quantitative-genetic extractor vocabulary.
"""
EBV(fit) = breeding_values(fit)

"""
    BLUP(fit)

Alias for [`breeding_values`](@ref). For the Phase 1 animal-effect block, the
returned values are the same animal BLUPs/EBVs as [`breeding_values`](@ref).
"""
BLUP(fit) = breeding_values(fit)

"""
    fitted_values(fit; include_random = true)

Return fitted values for an experimental low-level [`AnimalModelFit`](@ref).

The current implementation solves Henderson's mixed-model equations at the
fit's variance components, then computes `X * beta + Z * u` from that supplied
variance solution. Variance-component estimation is still the experimental
dense path.
"""
function fitted_values(fit::AnimalModelFit; include_random::Bool = true)
    vc = fit.variance_components
    mme = henderson_mme(fit.spec, vc.sigma_a2, vc.sigma_e2)
    return fitted_values(mme; include_random = include_random)
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

function heritability(result::HendersonMMEResult)
    vc = variance_components(result)
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
function prediction_error_variance(fit::AnimalModelFit; method::Symbol = :dense)
    values = _pev_values(
        fit.spec,
        fit.variance_components.sigma_a2,
        fit.variance_components.sigma_e2,
        method,
    )
    return (ids = collect(fit.spec.ids), values = values)
end

"""
    prediction_error_variance(result::HendersonMMEResult)

Return dense prediction error variances for a supplied-variance Henderson MME
result.

This uses the same dense inverse of the mixed-model-equation coefficient matrix
as [`prediction_error_variance(::AnimalModelFit)`](@ref). It is a tiny
validation-path extractor, not production sparse selected inversion.
"""
function prediction_error_variance(result::HendersonMMEResult; method::Symbol = :dense)
    values = _pev_values(result.spec, result.sigma_a2, result.sigma_e2, method)
    return (ids = collect(result.spec.ids), values = values)
end

"""
    reliability(fit)

Return dense animal-level reliability values for the Phase 1 univariate animal
model.

Reliability is computed as `1 - PEV_i / (sigma_a2 * A_ii)` using the dense
relationship matrix `A = inv(Ainv)` implied by the supplied precision. For a
genomic spec (`Ainv = Ginv`) this `A_ii` is `diag(inv(Ginv)) = diag(G) + ridge`
(the regularized genomic self-relationship, often ≠ 1), so the ridge perturbs the
reported reliability/accuracy and the same extractor yields genomic reliabilities.
Values are not clipped; small examples can expose weakly informed animals
directly.
"""
function reliability(fit::AnimalModelFit; method::Symbol = :dense)
    pev = prediction_error_variance(fit; method = method)
    A = inv(Symmetric(Matrix{Float64}(fit.spec.Ainv)))
    animal_variance = fit.variance_components.sigma_a2 .* diag(A)

    all(>(0), animal_variance) ||
        throw(ArgumentError("animal-level additive variances must be positive"))

    return (
        ids = pev.ids,
        values = Vector{Float64}(1 .- pev.values ./ animal_variance),
    )
end

function reliability(result::HendersonMMEResult; method::Symbol = :dense)
    pev = prediction_error_variance(result; method = method)
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
    accuracy(fit)

Return animal-level accuracy values as `sqrt(reliability(fit))`.

This is a validation-scale extractor over the existing reliability method. It
does not add independent accuracy validation and it rejects non-finite or
out-of-range reliability values instead of silently clipping them.
"""
function accuracy(fit)
    return _accuracy_from_reliability(reliability(fit))
end

function _accuracy_from_reliability(reliability_result)
    ids = getproperty(reliability_result, :ids)
    values = Float64.(getproperty(reliability_result, :values))
    length(ids) == length(values) ||
        throw(ArgumentError("reliability ids and values must have the same length"))
    all(isfinite, values) ||
        throw(ArgumentError("reliability values must be finite to compute accuracy"))
    all(value -> 0 <= value <= 1, values) ||
        throw(ArgumentError("reliability values must be within [0, 1] to compute accuracy"))

    return (ids = collect(ids), values = sqrt.(values))
end

# Acklam (2003) rational approximation to the standard-normal quantile
# (|abs error| < 1.15e-9). Lets the heritability interval pick a two-sided z
# without a Distributions/SpecialFunctions dependency.
function _standard_normal_quantile(p::Real)
    0 < p < 1 || throw(ArgumentError("p must be in (0, 1)"))
    a = (-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
         1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00)
    b = (-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
         6.680131188771972e+01, -1.328068155288572e+01)
    c = (-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
         -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00)
    d = (7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
         3.754408661907416e+00)
    plow = 0.02425
    phigh = 1 - plow
    if p < plow
        q = sqrt(-2 * log(p))
        return (((((c[1] * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) * q + c[6]) /
               ((((d[1] * q + d[2]) * q + d[3]) * q + d[4]) * q + 1)
    elseif p <= phigh
        q = p - 0.5
        r = q * q
        return (((((a[1] * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * r + a[6]) * q /
               (((((b[1] * r + b[2]) * r + b[3]) * r + b[4]) * r + b[5]) * r + 1)
    else
        q = sqrt(-2 * log(1 - p))
        return -(((((c[1] * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) * q + c[6]) /
                ((((d[1] * q + d[2]) * q + d[3]) * q + d[4]) * q + 1)
    end
end

# 2x2 average-information (AI) matrix for (sigma_a2, sigma_e2) of the REML
# objective at the given variance components — the same AI metric fit_ai_reml
# uses. Its inverse is the asymptotic variance-component covariance. (Recomputed
# here rather than shared with the fit_ai_reml hot loop, which also needs the
# score and reuses its factor.)
function _reml_information_matrix(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    X = Float64.(spec.X)
    Z = sparse(Float64.(spec.Z))
    y = Float64.(spec.y)
    nfixed = size(X, 2)
    lhs, rhs, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)
    factor = cholesky(Symmetric(lhs); check = true)
    solution = factor \ rhs
    beta = solution[1:nfixed]
    u = solution[(nfixed + 1):end]
    e = y .- X * beta .- Z * u
    wa = (Z * u) ./ sigma_a2
    we = e ./ sigma_e2
    Pwa = _reml_project(factor, X, Z, wa, sigma_e2, nfixed)
    Pwe = _reml_project(factor, X, Z, we, sigma_e2, nfixed)
    return Symmetric(0.5 .* [dot(wa, Pwa) dot(wa, Pwe); dot(we, Pwa) dot(we, Pwe)])
end

"""
    variance_component_covariance(fit)

Asymptotic covariance of the estimated `(sigma_a2, sigma_e2)` for a REML
[`AnimalModelFit`](@ref): the inverse of the average-information matrix. This is a
large-sample approximation and is unreliable on small samples, where the REML
surface is flat and the matrix is ill-conditioned. Experimental; REML only.
"""
function variance_component_covariance(fit::AnimalModelFit)
    fit.spec.method == :REML ||
        throw(ArgumentError("variance_component_covariance requires a REML fit"))
    info = _reml_information_matrix(
        fit.spec,
        fit.variance_components.sigma_a2,
        fit.variance_components.sigma_e2,
    )
    return inv(info)
end

"""
    variance_component_standard_errors(fit)

Asymptotic standard errors of `(sigma_a2, sigma_e2)` for a REML fit, as a
`NamedTuple`. See [`variance_component_covariance`](@ref) for the caveats.
"""
function variance_component_standard_errors(fit::AnimalModelFit)
    cov = variance_component_covariance(fit)
    return (sigma_a2 = sqrt(cov[1, 1]), sigma_e2 = sqrt(cov[2, 2]))
end

"""
    heritability_standard_error(fit)

Delta-method asymptotic standard error of `h² = sigma_a2 / (sigma_a2 + sigma_e2)`
for a REML fit, from [`variance_component_covariance`](@ref). Asymptotic; see the
caveats there.
"""
function heritability_standard_error(fit::AnimalModelFit)
    sigma_a2 = fit.variance_components.sigma_a2
    sigma_e2 = fit.variance_components.sigma_e2
    cov = variance_component_covariance(fit)
    denom = (sigma_a2 + sigma_e2)^2
    g = [sigma_e2 / denom, -sigma_a2 / denom]
    return sqrt(max(0.0, dot(g, cov * g)))
end

"""
    heritability_interval(fit; level = 0.95)

Experimental two-sided confidence interval for `h²` of a REML
[`AnimalModelFit`](@ref). The interval is built on the logit scale (delta method)
and back-transformed, so it always lies in `(0, 1)`. It is a large-sample
approximation: on small samples it is very wide and dominated by the flat REML
surface. Returns `(heritability, lower, upper, level, se)`.
"""
function heritability_interval(fit::AnimalModelFit; level::Real = 0.95)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    h2 = heritability(fit)
    0 < h2 < 1 ||
        throw(ArgumentError("heritability estimate is on the (0, 1) boundary; interval undefined"))
    se = heritability_standard_error(fit)
    z = _standard_normal_quantile((1 + level) / 2)
    eta = log(h2 / (1 - h2))
    se_eta = se / (h2 * (1 - h2))
    lower = 1 / (1 + exp(-(eta - z * se_eta)))
    upper = 1 / (1 + exp(-(eta + z * se_eta)))
    return (heritability = h2, lower = lower, upper = upper, level = level, se = se)
end

"""
    result_payload(fit)

Return a bridge-facing result payload with field names aligned to the R
`hsquared_fit` contract.

This is an experimental low-level payload. It is intended to make the R-Julia
result shape explicit before live bridge execution is widened beyond tiny
validation paths.
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
            dense_validation_path = fit.dense_validation_path,
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

function _coerce_fit_target(target::Symbol)
    target in (:variance_components, :dense_validation) && return :variance_components
    target in (:sparse_reml, :sparse_reml_validation) && return :sparse_reml
    target in (:ai_reml, :ai_reml_validation) && return :ai_reml
    target == :henderson_mme && return :henderson_mme
    throw(ArgumentError("target must be :variance_components, :sparse_reml, :ai_reml, or :henderson_mme"))
end

function _coerce_fit_target(target::AbstractString)
    return _coerce_fit_target(Symbol(target))
end

function _coerce_fit_target(target)
    throw(ArgumentError("target must be a Symbol or string"))
end

function _coerce_supplied_variance_components(::Nothing)
    throw(ArgumentError("variance_components must be supplied when target = :henderson_mme"))
end

function _coerce_supplied_variance_components(variance_components::NamedTuple)
    haskey(variance_components, :sigma_a2) ||
        throw(ArgumentError("variance_components must include sigma_a2"))
    haskey(variance_components, :sigma_e2) ||
        throw(ArgumentError("variance_components must include sigma_e2"))
    return Float64(variance_components.sigma_a2), Float64(variance_components.sigma_e2)
end

function _coerce_supplied_variance_components(variance_components::Tuple)
    length(variance_components) == 2 ||
        throw(ArgumentError("variance_components must contain two values"))
    return Float64(variance_components[1]), Float64(variance_components[2])
end

function _coerce_supplied_variance_components(variance_components::AbstractVector)
    length(variance_components) == 2 ||
        throw(ArgumentError("variance_components must contain two values"))
    return Float64(variance_components[1]), Float64(variance_components[2])
end

function _coerce_supplied_variance_components(variance_components)
    throw(ArgumentError("variance_components must be a NamedTuple, tuple, or vector"))
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

# Prediction error variances = diagonal of the random-effect block of the MME
# coefficient-matrix inverse. `:dense` forms and inverts the dense MME (the tiny
# validation reference); `:selinv` uses the Takahashi selected inverse of the
# sparse MME coefficient matrix in O(nnz(L)). Both paths use the identical
# coefficient matrix, so the diagonal agrees to machine precision.
function _pev_values(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real, method::Symbol)
    if method === :selinv
        return _selinv_mme_random_pev(spec, sigma_a2, sigma_e2)
    elseif method === :dense
        block = _dense_mme_random_inverse_block(spec, sigma_a2, sigma_e2)
        return Vector{Float64}(diag(block))
    else
        throw(ArgumentError("prediction-error-variance method must be :dense or :selinv"))
    end
end

# Sparse selected-inversion PEV: the diagonal of C^-1 at the random-effect rows,
# where C is the sparse Henderson MME coefficient matrix from
# `_sparse_mme_system`. The diagonal is always in the L+Lᵀ pattern, so
# `takahashi_diag` returns it exactly.
function _selinv_mme_random_pev(spec::AnimalModelSpec, sigma_a2::Real, sigma_e2::Real)
    lhs, _, _ = _sparse_mme_system(spec, sigma_a2, sigma_e2)
    factor = cholesky(Symmetric(lhs); check = true)
    diag_inv = takahashi_diag(factor)
    nfixed = size(spec.X, 2)
    return Vector{Float64}(diag_inv[(nfixed + 1):end])
end

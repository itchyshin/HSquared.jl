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
        trace_AC = selinv_trace_against(factor, Ainv, nfixed)
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
    metafounder_animal_model(y, X, Z, pedigree, group_of, Gamma, sigma_a2, sigma_e2;
                             ids = pedigree.ids)

Supplied-variance Gaussian animal-model BLUP under a metafounder-augmented
relationship `A^Γ` (#53, Legarra et al. 2015). Builds the descriptive animal-only
metafounder precision `inv(A^Γ)` via [`metafounder_relationship_inverse`](@ref) and
solves the standard Henderson MME ([`henderson_mme`](@ref)) at supplied variance
components, returning the `HendersonMMEResult`. At `Γ = 0` this reduces EXACTLY to
the classical animal model (`metafounder_relationship_inverse → pedigree_inverse`),
so the fixed effects and EBVs match `henderson_mme` with `pedigree_inverse`.

SUPPLIED-variance and SUPPLIED-`Γ` only — neither `Γ` nor the variance components is
estimated. This is the animal-only BLUP under `A^Γ`; the combined system with
explicit metafounder effects ([`metafounder_inverse`](@ref)) is a separate path, and
there is no R-facing model-spec or bridge payload.
"""
function metafounder_animal_model(y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix,
        pedigree::Pedigree, group_of, Gamma::AbstractMatrix,
        sigma_a2::Real, sigma_e2::Real; ids = pedigree.ids)
    Ainv = metafounder_relationship_inverse(pedigree, group_of, Gamma)
    spec = animal_model_spec(y, X, Z, Ainv; ids = ids)
    return henderson_mme(spec, sigma_a2, sigma_e2)
end

"""
    two_effect_mme(y, X, Z1, Ainv1, Z2, Ainv2, sigma1, sigma2, sigma_e2;
                   ids1 = nothing, ids2 = nothing)

Supplied-variance Henderson solve of a Gaussian model with **two independent
random effects**:

    y = X·β + Z1·u1 + Z2·u2 + e,
    u1 ~ N(0, sigma1·A1),  u2 ~ N(0, sigma2·A2),  e ~ N(0, sigma_e2·I),

with relationship inverses `Ainv1 = A1⁻¹`, `Ainv2 = A2⁻¹`. The mixed-model
equations carry the block-diagonal precision `blockdiag(Ainv1/sigma1,
Ainv2/sigma2)` for the stacked random effect `[u1; u2]`.

This is the general engine kernel for the standard two-random-effect
quantitative-genetic models: repeatability / permanent environment (`Z2 = Z1`,
`A2 = I`; see [`repeatability_mme`](@ref)), common environment (`Z2` = group
incidence, `A2 = I`), and maternal-environment (`Z2` = dam incidence, `A2 = I`).
Experimental, supplied-variance, engine-internal — it does not estimate variances
and does not cover correlated direct–maternal genetic effects (which need a 2×2
genetic covariance). Returns `(beta, effect1, effect2, variance_components)`.
"""
function two_effect_mme(
    y::AbstractVector,
    X::AbstractMatrix,
    Z1::AbstractMatrix,
    Ainv1::AbstractMatrix,
    Z2::AbstractMatrix,
    Ainv2::AbstractMatrix,
    sigma1::Real,
    sigma2::Real,
    sigma_e2::Real;
    ids1 = nothing,
    ids2 = nothing,
)
    sigma1 > 0 || throw(ArgumentError("sigma1 must be positive"))
    sigma2 > 0 || throw(ArgumentError("sigma2 must be positive"))
    sigma_e2 > 0 || throw(ArgumentError("sigma_e2 must be positive"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Z1, 1) == n || throw(ArgumentError("Z1 must have one row per record"))
    size(Z2, 1) == n || throw(ArgumentError("Z2 must have one row per record"))
    n1 = size(Ainv1, 1)
    n2 = size(Ainv2, 1)
    size(Ainv1, 2) == n1 || throw(ArgumentError("Ainv1 must be square"))
    size(Ainv2, 2) == n2 || throw(ArgumentError("Ainv2 must be square"))
    size(Z1, 2) == n1 || throw(ArgumentError("Z1 columns must match Ainv1 dimensions"))
    size(Z2, 2) == n2 || throw(ArgumentError("Z2 columns must match Ainv2 dimensions"))
    e1ids = ids1 === nothing ? collect(1:n1) : collect(ids1)
    e2ids = ids2 === nothing ? collect(1:n2) : collect(ids2)
    length(e1ids) == n1 || throw(ArgumentError("ids1 length must match Ainv1 dimensions"))
    length(e2ids) == n2 || throw(ArgumentError("ids2 length must match Ainv2 dimensions"))

    yv = Float64.(y)
    Xs = sparse(Float64.(X))
    Z1s = sparse(Float64.(Z1))
    Z2s = sparse(Float64.(Z2))
    A1 = sparse(Float64.(Ainv1))
    A2 = sparse(Float64.(Ainv2))
    rp = inv(Float64(sigma_e2))
    Zf = hcat(Z1s, Z2s)
    Ginv = blockdiag(A1 .* inv(Float64(sigma1)), A2 .* inv(Float64(sigma2)))
    Xt = transpose(Xs)
    Zft = transpose(Zf)
    nfixed = size(Xs, 2)
    lhs = [
        rp * (Xt * Xs) rp * (Xt * Zf)
        rp * (Zft * Xs) rp * (Zft * Zf) + Ginv
    ]
    rhs = vcat(rp * (Xt * yv), rp * (Zft * yv))
    solution = lhs \ rhs
    beta = Vector{Float64}(solution[1:nfixed])
    u1 = Vector{Float64}(solution[(nfixed + 1):(nfixed + n1)])
    u2 = Vector{Float64}(solution[(nfixed + n1 + 1):(nfixed + n1 + n2)])
    return (
        beta = beta,
        effect1 = (ids = e1ids, values = u1),
        effect2 = (ids = e2ids, values = u2),
        variance_components = (
            sigma1 = Float64(sigma1),
            sigma2 = Float64(sigma2),
            sigma_e2 = Float64(sigma_e2),
        ),
    )
end

"""
    repeatability_mme(y, X, Z, Ainv, sigma_a2, sigma_pe2, sigma_e2; ids = nothing)

Supplied-variance Henderson solve of the repeatability / permanent-environment
animal model with repeated records:

    y = X·β + Z·a + Z·pe + e,
    a ~ N(0, sigma_a2·A),  pe ~ N(0, sigma_pe2·I),  e ~ N(0, sigma_e2·I),

where `Z` is the record→animal incidence (shared by the additive genetic effect
`a` and the permanent-environment effect `pe`), and `Ainv` is the relationship
inverse. The mixed-model equations carry a block-diagonal relationship precision
`blockdiag(Ainv/sigma_a2, I/sigma_pe2)` for the stacked random effect `[a; pe]`.

This is the first Phase-3 (standard quantitative-genetic) engine slice: a
supplied-variance MME solve (it does **not** estimate the variance components),
the analogue of [`henderson_mme`](@ref) for two random effects. Experimental and
engine-internal; the R `permanent()` / repeatability model-spec mapping and REML
estimation of the three variance components are coordinated separately and not
part of this function. Returns a `NamedTuple`
`(beta, animal_effects, permanent_effects, variance_components)`. Identifiability
of `a` vs `pe` requires repeated records (animals with more than one record).
"""
function repeatability_mme(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix,
    sigma_a2::Real,
    sigma_pe2::Real,
    sigma_e2::Real;
    ids = nothing,
)
    na = size(Ainv, 1)
    # repeatability = the two-effect model with the permanent-environment effect
    # sharing Z and carrying an identity relationship (A2 = I).
    result = two_effect_mme(
        y, X, Z, Ainv, Z, sparse(1.0I, na, na),
        sigma_a2, sigma_pe2, sigma_e2; ids1 = ids, ids2 = ids,
    )
    return (
        beta = result.beta,
        animal_effects = result.effect1,
        permanent_effects = result.effect2,
        variance_components = (
            sigma_a2 = Float64(sigma_a2),
            sigma_pe2 = Float64(sigma_pe2),
            sigma_e2 = Float64(sigma_e2),
        ),
    )
end

# Dense REML log-likelihood and BLUPs for a general two-independent-random-effect
# model: V = sigma1·(Z1 A1 Z1') + sigma2·(Z2 A2 Z2') + sigma_e2·I (validation-scale,
# forms the n×n marginal covariance). `A1`, `A2` are dense relationship matrices.
function _two_effect_dense(y, X, Z1, A1, Z2, A2, sigma1, sigma2, sigma_e2)
    n = length(y)
    V = Symmetric(
        sigma1 .* (Z1 * A1 * transpose(Z1)) .+
        sigma2 .* (Z2 * A2 * transpose(Z2)) .+
        sigma_e2 .* Matrix(1.0I, n, n),
    )
    Vf = cholesky(V)
    ViX = Vf \ Matrix(X)
    XtViX = cholesky(Symmetric(transpose(X) * ViX))
    beta = XtViX \ (transpose(X) * (Vf \ y))
    r = y .- X * beta
    Vir = Vf \ r
    loglik = -0.5 * (logdet(Vf) + logdet(XtViX) + dot(r, Vir))
    u1 = sigma1 .* (A1 * (transpose(Z1) * Vir))
    u2 = sigma2 .* (A2 * (transpose(Z2) * Vir))
    return loglik, Vector{Float64}(beta), u1, u2
end

"""
    fit_two_effect_reml(y, X, Z1, Ainv1, Z2, Ainv2; initial, iterations = 200,
                        ids1 = nothing, ids2 = nothing)

REML estimation of the variance components `(sigma1, sigma2, sigma_e2)` of the
general two-independent-random-effect model (see [`two_effect_mme`](@ref)), by
maximizing the dense two-effect REML log-likelihood (NelderMead). Covers
common-environment (`c² = ratio2`) and maternal-environment variance estimation.

Returns a `NamedTuple` with `variance_components`, `ratio1 = sigma1/total`,
`ratio2 = sigma2/total`, `beta`, the two BLUPs, `loglik`, and `converged`.
Experimental, dense/validation-scale, REML-only; uncertainty intervals and the R
model-spec mapping are not part of this function. On small data the optimum can
sit on a boundary (a variance → 0).
"""
function fit_two_effect_reml(
    y::AbstractVector,
    X::AbstractMatrix,
    Z1::AbstractMatrix,
    Ainv1::AbstractMatrix,
    Z2::AbstractMatrix,
    Ainv2::AbstractMatrix;
    initial = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 200,
    ids1 = nothing,
    ids2 = nothing,
)
    initial.sigma1 > 0 && initial.sigma2 > 0 && initial.sigma_e2 > 0 ||
        throw(ArgumentError("initial variance components must be positive"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Z1, 1) == n || throw(ArgumentError("Z1 must have one row per record"))
    size(Z2, 1) == n || throw(ArgumentError("Z2 must have one row per record"))
    n1 = size(Ainv1, 1)
    n2 = size(Ainv2, 1)
    size(Ainv1, 2) == n1 || throw(ArgumentError("Ainv1 must be square"))
    size(Ainv2, 2) == n2 || throw(ArgumentError("Ainv2 must be square"))
    size(Z1, 2) == n1 || throw(ArgumentError("Z1 columns must match Ainv1 dimensions"))
    size(Z2, 2) == n2 || throw(ArgumentError("Z2 columns must match Ainv2 dimensions"))
    e1ids = ids1 === nothing ? collect(1:n1) : collect(ids1)
    e2ids = ids2 === nothing ? collect(1:n2) : collect(ids2)
    length(e1ids) == n1 || throw(ArgumentError("ids1 length must match Ainv1 dimensions"))
    length(e2ids) == n2 || throw(ArgumentError("ids2 length must match Ainv2 dimensions"))

    A1 = inv(Symmetric(Matrix{Float64}(Ainv1)))
    A2 = inv(Symmetric(Matrix{Float64}(Ainv2)))
    Xd = Matrix{Float64}(X)
    Z1d = Matrix{Float64}(Z1)
    Z2d = Matrix{Float64}(Z2)
    yv = Float64.(y)
    objective(p) = -_two_effect_dense(yv, Xd, Z1d, A1, Z2d, A2, exp(p[1]), exp(p[2]), exp(p[3]))[1]
    p0 = log.([Float64(initial.sigma1), Float64(initial.sigma2), Float64(initial.sigma_e2)])
    result = optimize(objective, p0, NelderMead(), Optim.Options(iterations = iterations))
    sigma1, sigma2, sigma_e2 = exp.(Optim.minimizer(result))
    loglik, beta, u1, u2 = _two_effect_dense(yv, Xd, Z1d, A1, Z2d, A2, sigma1, sigma2, sigma_e2)
    total = sigma1 + sigma2 + sigma_e2
    return (
        variance_components = (sigma1 = sigma1, sigma2 = sigma2, sigma_e2 = sigma_e2),
        ratio1 = sigma1 / total,
        ratio2 = sigma2 / total,
        beta = beta,
        effect1 = (ids = e1ids, values = u1),
        effect2 = (ids = e2ids, values = u2),
        loglik = loglik,
        converged = Optim.converged(result),
    )
end

# Repeatability dense loglik = the two-effect dense loglik with the
# permanent-environment effect sharing Z and carrying an identity relationship.
function _repeatability_dense(y, X, Z, A, sigma_a2, sigma_pe2, sigma_e2)
    na = size(A, 1)
    return _two_effect_dense(y, X, Z, A, Z, Matrix(1.0I, na, na), sigma_a2, sigma_pe2, sigma_e2)
end

"""
    fit_repeatability_reml(y, X, Z, Ainv; initial, iterations = 200, ids = nothing)

Estimate the three variance components `(sigma_a2, sigma_pe2, sigma_e2)` of the
repeatability / permanent-environment animal model by REML, by maximizing the
dense two-random-effect REML log-likelihood over the log-variances (NelderMead).

Returns a `NamedTuple` with `variance_components`, the repeatability
`t = (sigma_a2 + sigma_pe2) / total`, the heritability `h² = sigma_a2 / total`,
`beta`, the `a` / `pe` BLUPs at the estimate, `loglik`, and `converged`.

Experimental and validation-scale: it forms the dense `n×n` marginal covariance,
so it is for small problems, not production. REML-only. Uncertainty intervals for
`t` / `h²` and the R model-spec mapping are not part of this function. Separating
`sigma_a2` from `sigma_pe2` needs relationship contrast and replication; on small
data the optimum can sit on a boundary (one variance → 0).
"""
function fit_repeatability_reml(
    y::AbstractVector,
    X::AbstractMatrix,
    Z::AbstractMatrix,
    Ainv::AbstractMatrix;
    initial = (sigma_a2 = 1.0, sigma_pe2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 200,
    ids = nothing,
)
    initial.sigma_a2 > 0 && initial.sigma_pe2 > 0 && initial.sigma_e2 > 0 ||
        throw(ArgumentError("initial variance components must be positive"))
    n = length(y)
    size(X, 1) == n || throw(ArgumentError("X must have one row per record"))
    size(Z, 1) == n || throw(ArgumentError("Z must have one row per record"))
    na = size(Ainv, 1)
    size(Ainv, 2) == na || throw(ArgumentError("Ainv must be square"))
    size(Z, 2) == na || throw(ArgumentError("Z columns must match Ainv dimensions"))
    encoded_ids = ids === nothing ? collect(1:na) : collect(ids)
    length(encoded_ids) == na ||
        throw(ArgumentError("ids length must match Ainv dimensions"))

    A = inv(Symmetric(Matrix{Float64}(Ainv)))
    Xd = Matrix{Float64}(X)
    Zd = Matrix{Float64}(Z)
    yv = Float64.(y)
    objective(p) = -_repeatability_dense(yv, Xd, Zd, A, exp(p[1]), exp(p[2]), exp(p[3]))[1]
    p0 = log.([Float64(initial.sigma_a2), Float64(initial.sigma_pe2), Float64(initial.sigma_e2)])
    result = optimize(objective, p0, NelderMead(), Optim.Options(iterations = iterations))
    sigma_a2, sigma_pe2, sigma_e2 = exp.(Optim.minimizer(result))
    loglik, beta, ahat, pehat =
        _repeatability_dense(yv, Xd, Zd, A, sigma_a2, sigma_pe2, sigma_e2)
    total = sigma_a2 + sigma_pe2 + sigma_e2
    return (
        variance_components = (sigma_a2 = sigma_a2, sigma_pe2 = sigma_pe2, sigma_e2 = sigma_e2),
        repeatability = (sigma_a2 + sigma_pe2) / total,
        heritability = sigma_a2 / total,
        beta = beta,
        animal_effects = (ids = encoded_ids, values = ahat),
        permanent_effects = (ids = encoded_ids, values = pehat),
        loglik = loglik,
        converged = Optim.converged(result),
    )
end

"""
    repeatability_interval(y, X, Z, Ainv; level = 0.95, initial = ..., iterations = 200,
                           ids = nothing, fd_step = 1e-4)

Asymptotic delta-method confidence interval for the repeatability
`t = (σ²a + σ²pe) / (σ²a + σ²pe + σ²e)` of the repeatability / permanent-environment
animal model. Fits by REML ([`fit_repeatability_reml`](@ref)), forms the observed
information as the central finite-difference Hessian of the REML log-likelihood at
the optimum, and applies the delta method to `t` on the logit scale (so the
interval lies in `(0, 1)`). Returns `(repeatability, lower, upper, level, se)`.

Experimental, asymptotic. `t` is the well-identified summary of this model (the
`σ²a`/`σ²pe` split is weakly identified, so a per-component SE is unreliable, but
`t` is stable). Throws if the REML information is not positive definite (a flat
surface / boundary optimum), or if `t` is on the `(0, 1)` boundary.
"""
function repeatability_interval(
    y::AbstractVector, X::AbstractMatrix, Z::AbstractMatrix, Ainv::AbstractMatrix;
    level::Real = 0.95,
    initial = (sigma_a2 = 1.0, sigma_pe2 = 1.0, sigma_e2 = 1.0),
    iterations::Integer = 200, ids = nothing, fd_step::Real = 1e-4,
)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    fit = fit_repeatability_reml(y, X, Z, Ainv; initial = initial, iterations = iterations, ids = ids)
    vc = fit.variance_components
    theta = [vc.sigma_a2, vc.sigma_pe2, vc.sigma_e2]

    A = inv(Symmetric(Matrix{Float64}(Ainv)))
    Xd = Matrix{Float64}(X); Zd = Matrix{Float64}(Z); yv = Float64.(y)
    loglik(t) = _repeatability_dense(yv, Xd, Zd, A, t[1], t[2], t[3])[1]

    # observed information = −Hessian of the REML loglik (central finite differences)
    h = fd_step .* max.(theta, 1e-3)
    H = zeros(3, 3)
    for i in 1:3, j in 1:3
        ei = zeros(3); ei[i] = h[i]
        ej = zeros(3); ej[j] = h[j]
        H[i, j] = (loglik(theta + ei + ej) - loglik(theta + ei - ej) -
                   loglik(theta - ei + ej) + loglik(theta - ei - ej)) / (4 * h[i] * h[j])
    end
    info = Symmetric(-H)
    isposdef(info) ||
        throw(ArgumentError("repeatability interval undefined: REML information is not positive definite (flat surface / boundary optimum)"))
    covar = inv(info)

    total = sum(theta)
    t = (theta[1] + theta[2]) / total
    0 < t < 1 || throw(ArgumentError("repeatability estimate is on the (0, 1) boundary; interval undefined"))
    # delta-method gradient of t = (σ²a + σ²pe)/total wrt (σ²a, σ²pe, σ²e)
    g = [theta[3] / total^2, theta[3] / total^2, -(theta[1] + theta[2]) / total^2]
    se = sqrt(max(dot(g, covar * g), 0.0))

    z = _standard_normal_quantile((1 + level) / 2)
    eta = log(t / (1 - t)); se_eta = se / (t * (1 - t))
    lower = 1 / (1 + exp(-(eta - z * se_eta)))
    upper = 1 / (1 + exp(-(eta + z * se_eta)))
    return (repeatability = t, lower = lower, upper = upper, level = level, se = se)
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
function reliability(fit::AnimalModelFit; method::Symbol = :dense, pev = nothing)
    pev_res = pev === nothing ? prediction_error_variance(fit; method = method) : pev
    A = inv(Symmetric(Matrix{Float64}(fit.spec.Ainv)))
    animal_variance = fit.variance_components.sigma_a2 .* diag(A)

    all(>(0), animal_variance) ||
        throw(ArgumentError("animal-level additive variances must be positive"))

    return (
        ids = pev_res.ids,
        values = Vector{Float64}(1 .- pev_res.values ./ animal_variance),
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

# Profile REML log-likelihood at a fixed heritability `h2`: maximize the REML
# objective over the total variance `V` along the ray
# `(sigma_a2, sigma_e2) = (h2*V, (1-h2)*V)`. A 1-D maximization reusing
# `sparse_reml_loglik`; the search bracket is anchored on the phenotypic-variance
# scale of `y`. `h2` must be strictly interior to `(0, 1)`. Used by the
# profile-likelihood heritability interval.
function _profile_reml_loglik(spec::AnimalModelSpec, h2::Real)
    0 < h2 < 1 || throw(ArgumentError("h2 must be in (0, 1)"))
    y = Float64.(spec.y)
    n = length(y)
    ybar = sum(y) / n
    v0 = max(sum(abs2, y .- ybar) / max(1, n - 1), eps())
    function objective(logV)
        V = exp(logV)
        try
            return -sparse_reml_loglik(spec, h2 * V, (1 - h2) * V).loglik
        catch err
            err isa PosDefException && return Inf
            rethrow()
        end
    end
    result = optimize(objective, log(v0 * 1e-4), log(v0 * 1e4))
    return -Optim.minimum(result)
end

# Profile REML log-likelihood at a fixed additive variance `sigma_a2`: maximize
# over the NUISANCE residual variance `sigma_e2`. The sigma_a2 companion of
# `_profile_reml_loglik` (which profiles total variance at fixed h²); a 1-D
# maximization reusing `sparse_reml_loglik`, bracketed on the phenotypic variance
# of `y`. Used by `variance_component_interval`.
function _profile_reml_loglik_sigma_a2(spec::AnimalModelSpec, sigma_a2::Real)
    sigma_a2 > 0 || throw(ArgumentError("sigma_a2 must be positive"))
    y = Float64.(spec.y)
    n = length(y)
    ybar = sum(y) / n
    v0 = max(sum(abs2, y .- ybar) / max(1, n - 1), eps())
    function objective(logE)
        sigma_e2 = exp(logE)
        try
            return -sparse_reml_loglik(spec, sigma_a2, sigma_e2).loglik
        catch err
            err isa PosDefException && return Inf
            rethrow()
        end
    end
    result = optimize(objective, log(v0 * 1e-6), log(v0 * 1e4))
    return -Optim.minimum(result)
end

# Root of `target` on the heritability axis for the profile interval. `anchor`
# is the point-estimate side where `target(anchor) < 0`; `bound` is the search
# boundary. If `target(bound) <= 0` the interval reaches the search bound and the
# (clamped) bound is returned; otherwise bisect to the crossing.
function _profile_root(target, bound::Real, anchor::Real)
    target(bound) > 0 || return float(bound)
    a, b = float(anchor), float(bound)
    for _ in 1:200
        m = 0.5 * (a + b)
        fm = target(m)
        (abs(fm) < 1e-9 || abs(b - a) < 1e-13) && return m
        fm < 0 ? (a = m) : (b = m)
    end
    return 0.5 * (a + b)
end

function _heritability_interval_profile(fit::AnimalModelFit; level::Real)
    fit.spec.method == :REML ||
        throw(ArgumentError("profile heritability interval requires a REML fit"))
    h2 = heritability(fit)
    0 < h2 < 1 ||
        throw(ArgumentError("heritability estimate is on the (0, 1) boundary; interval undefined"))
    spec = fit.spec
    llmax = _profile_reml_loglik(spec, h2)
    z = _standard_normal_quantile((1 + level) / 2)
    q = z * z
    target(h) = 2 * (llmax - _profile_reml_loglik(spec, h)) - q
    lower = _profile_root(target, 1e-6, h2)
    upper = _profile_root(target, 1 - 1e-6, h2)
    return (heritability = h2, lower = lower, upper = upper, level = level, method = :profile)
end

"""
    heritability_interval(fit; level = 0.95, method = :delta)

Experimental two-sided confidence interval for `h²` of a REML
[`AnimalModelFit`](@ref).

`method = :delta` (default) builds the interval on the logit scale (delta method)
and back-transforms, so it always lies in `(0, 1)`; it returns
`(heritability, lower, upper, level, se, method)`.

`method = :profile` inverts the REML likelihood-ratio statistic: it profiles the
REML log-likelihood over the total variance at each fixed `h²` and reports the
`h²` range where `2·(ℓmax − ℓprofile(h²)) ≤ χ²₁,level`. Endpoints that reach the
`(0, 1)` search bounds are clamped. It returns
`(heritability, lower, upper, level, method)` (no `se`).

Both are large-sample approximations: on small samples the REML surface is flat,
so the intervals are wide.
"""
function heritability_interval(fit::AnimalModelFit; level::Real = 0.95, method::Symbol = :delta)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    if method === :profile
        return _heritability_interval_profile(fit; level = level)
    end
    method === :delta ||
        throw(ArgumentError("method must be :delta or :profile"))
    h2 = heritability(fit)
    0 < h2 < 1 ||
        throw(ArgumentError("heritability estimate is on the (0, 1) boundary; interval undefined"))
    se = heritability_standard_error(fit)
    z = _standard_normal_quantile((1 + level) / 2)
    eta = log(h2 / (1 - h2))
    se_eta = se / (h2 * (1 - h2))
    lower = 1 / (1 + exp(-(eta - z * se_eta)))
    upper = 1 / (1 + exp(-(eta + z * se_eta)))
    return (heritability = h2, lower = lower, upper = upper, level = level, se = se, method = :delta)
end

function _variance_component_interval_profile(fit::AnimalModelFit; level::Real)
    fit.spec.method == :REML ||
        throw(ArgumentError("profile variance-component interval requires a REML fit"))
    sigma_a2 = fit.variance_components.sigma_a2
    sigma_a2 > 0 ||
        throw(ArgumentError("sigma_a2 estimate is on the boundary; interval undefined"))
    spec = fit.spec
    llmax = _profile_reml_loglik_sigma_a2(spec, sigma_a2)
    z = _standard_normal_quantile((1 + level) / 2)
    q = z * z
    target(v) = 2 * (llmax - _profile_reml_loglik_sigma_a2(spec, v)) - q
    lo_bound = sigma_a2 * 1e-4
    up_bound = sigma_a2 * 1e4
    lower = _profile_root(target, lo_bound, sigma_a2)
    upper = _profile_root(target, up_bound, sigma_a2)
    lower_clamped = target(lo_bound) <= 0
    upper_clamped = target(up_bound) <= 0
    return (sigma_a2 = sigma_a2, lower = lower, upper = upper, level = level,
            lower_clamped = lower_clamped, upper_clamped = upper_clamped,
            method = :profile)
end

"""
    variance_component_interval(fit; level = 0.95, method = :profile)

Profile likelihood-ratio confidence interval for the additive variance component
`sigma_a2` of a REML [`AnimalModelFit`](@ref). It inverts
`2·(ℓmax − ℓprofile(sigma_a2)) ≤ χ²₁,level` while profiling the residual variance
`sigma_e2` as a NUISANCE at each candidate `sigma_a2` — the variance-component
companion of [`heritability_interval`](@ref) `method = :profile` (which profiles
the total variance at fixed `h²`).

Returns `(sigma_a2, lower, upper, level, lower_clamped, upper_clamped, method)`.
The `*_clamped` flags report an endpoint that reached the `(sigma_a2·1e-4,
sigma_a2·1e4)` search bound (the profile did not cross the χ² threshold within
range), so a non-crossing endpoint is self-describing — on small samples the REML
surface is flat and the interval clamps.

Applies unchanged to a genomic GBLUP / supplied-`Ginv` REML fit (`fit_gblup_reml`,
or any `method = :REML` spec with `Ginv` in the `Ainv` slot): the profiler reads
only the spec's precision through `sparse_reml_loglik`. On a genomic spec `sigma_a2`
is the GENOMIC additive variance and the interval is CONDITIONAL on the supplied
`Ginv` (ridge + centering), so the implied `A_ii = diag(inv(Ginv)) ≠ 1` — not a
pedigree-scale `sigma_a2`. A non-PD `Ginv` degrades to a clamped endpoint (the
`PosDefException` is caught as `Inf`), never a silent number.

Experimental, asymptotic, REML only; no coverage calibration.
"""
function variance_component_interval(fit::AnimalModelFit; level::Real = 0.95,
                                     method::Symbol = :profile)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    method === :profile ||
        throw(ArgumentError("variance_component_interval supports method = :profile only"))
    return _variance_component_interval_profile(fit; level = level)
end

"""
    variance_components_plot_data(fit::AnimalModelFit; level = 0.95)

Plot-ready data for the variance-component + heritability forest figure (plotting
set B): tidy parallel vectors `(term, estimate, lo, hi, panel, level,
interval_method, interval_status, supplied = false)` shaped to drop directly into
the R `hs_gg_forest` contract. The variance-component rows (`sigma_a2`, `sigma_e2`)
carry asymptotic `estimate ± z·SE` — NOT clamped, since an asymptotic CI can cross
zero (surfaced, never hidden); the `h2` row carries the logit-delta
[`heritability_interval`](@ref) (always in `(0,1)`). `lo`/`hi` are `NaN` where the
interval is unavailable (no fabricated whiskers); `interval_status` is
`"experimental_asymptotic"` (NOT coverage-calibrated) when any interval is present,
else `"none"`. `interval_method` is a coarse roll-up tag (`"asymptotic_reml"`):
the VC-row whiskers are normal-Wald on the raw variance scale, the `h2`-row whisker
is the logit-delta back-transform — both asymptotic, both from the REML AI matrix.
`supplied = false` is the honest-status hinge — these are ESTIMATED, unlike the
descriptive supplied-`K_g`/`G` plot-data sets. Intervals are REML-only; a non-REML
fit degrades gracefully to points-only (`lo`/`hi` all `NaN`, `interval_status =
"none"`).
"""
function variance_components_plot_data(fit::AnimalModelFit; level::Real = 0.95)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    vc = variance_components(fit)
    h2 = heritability(fit)
    z = _standard_normal_quantile((1 + level) / 2)
    vc_lo = [NaN, NaN]
    vc_hi = [NaN, NaN]
    try
        se = variance_component_standard_errors(fit)
        vc_lo = [vc.sigma_a2 - z * se.sigma_a2, vc.sigma_e2 - z * se.sigma_e2]
        vc_hi = [vc.sigma_a2 + z * se.sigma_a2, vc.sigma_e2 + z * se.sigma_e2]
    catch
    end
    h2_lo = NaN
    h2_hi = NaN
    try
        ci = heritability_interval(fit; level = level)
        h2_lo = ci.lower
        h2_hi = ci.upper
    catch
    end
    has_interval = any(isfinite, vc_lo) || isfinite(h2_lo)
    return (term = ["sigma_a2", "sigma_e2", "h2"],
            estimate = [vc.sigma_a2, vc.sigma_e2, h2],
            lo = [vc_lo[1], vc_lo[2], h2_lo],
            hi = [vc_hi[1], vc_hi[2], h2_hi],
            panel = ["variance components", "variance components", "heritability"],
            level = Float64(level),
            interval_method = has_interval ? "asymptotic_reml" : "none",
            interval_status = has_interval ? "experimental_asymptotic" : "none",
            supplied = false)
end

"""
    breeding_values_plot_data(fit::AnimalModelFit; trait = 1)

Plot-ready data for the EBV "caterpillar" figure (plotting set B): tidy parallel
vectors `(id, trait, value, pev, pev_scale)` shaped to drop directly into the R
`autoplot.R` breeding-value plot (per the #93 R-twin alignment — this closes the last
live-parity gap R flagged). `value` is the EBV ([`breeding_values`](@ref)), `pev` the
prediction error variance ([`prediction_error_variance`](@ref), dense path), and
`pev_scale = "validation"` is the honest-status flag: the PEV denominator forms the
dense `inv(Ainv)`, so it is VALIDATION-scale, NOT a production large-pedigree
reliability claim. The R column convention is followed exactly (EBV as `value`).
Univariate `AnimalModelFit`; `trait` is the (single) trait label. Plot-DATA only —
no drawing backend, no estimation.
"""
function breeding_values_plot_data(fit::AnimalModelFit; trait = 1)
    bv = breeding_values(fit)
    pev = prediction_error_variance(fit)
    n = length(bv.values)
    return (id = collect(bv.ids),
            trait = fill(trait, n),
            value = collect(bv.values),
            pev = collect(pev.values),
            pev_scale = "validation")
end

"""
    result_payload(fit)

Return a bridge-facing result payload with field names aligned to the R
`hsquared_fit` contract.

This is an experimental low-level payload. It is intended to make the R-Julia
result shape explicit before live bridge execution is widened beyond tiny
validation paths.

The payload includes `prediction_error_variance` and `reliability` as standard
fields (each a `(ids, values)` named tuple). The PEV is computed through the
`O(nnz(L))` (sparse-scalable) Takahashi selected inverse (`method = :selinv`),
which matches the dense MME inverse diagonal to machine precision for
well-conditioned validation-scale fits (`V1-SELINV-PEV`). The R twin unpacks
these top-level fields directly via `hs_julia_id_values()` (`hsquared#21`), so
the opportunistic per-extractor enrichment is no longer required. The PEV is
computed once here and reused by `reliability` (no second factorization). This
remains a validation-scale path, not a production large-pedigree reliability
claim: in particular the `reliability` denominator still forms the dense
`A = inv(Ainv)` for the animal self-relationships (a sparse selected-inverse
diagonal of `Ainv` is the production-direction follow-up).
"""
function result_payload(fit::AnimalModelFit)
    vc = variance_components(fit)
    beta = fixed_effects(fit)
    bv = breeding_values(fit)
    predictions = fitted_values(fit)
    pev = prediction_error_variance(fit; method = :selinv)
    rel = reliability(fit; method = :selinv, pev = pev)

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
        prediction_error_variance = (ids = pev.ids, values = pev.values),
        reliability = (ids = rel.ids, values = rel.values),
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

"""
    bootstrap_variance_component_interval(fit::AnimalModelFit; level = 0.95,
        n_boot = 1000, estimator = :sparse_reml,
        rng = Random.MersenneTwister(0x48324352), max_dense_cells = $(DEFAULT_MAX_DENSE_CELLS))

Parametric (Gaussian) bootstrap percentile confidence intervals for `sigma_a2`,
`sigma_e2`, and `h² = σ²a/(σ²a+σ²e)` of a fitted univariate Gaussian REML animal
model — a cross-check on the asymptotic delta / profile-LRT intervals
([`heritability_interval`](@ref), [`variance_component_interval`](@ref)).

Mechanism: at the fitted `(β, σ²a, σ²e)`, simulate Gaussian responses over the
SUPPLIED relationship — `a* = chol(inv(Ainv)).L · randn · √σ²a`,
`e* = randn · √σ²e`, `y* = Xβ + Za* + e*` — refit each replicate with the SAME REML
estimator (`:sparse_reml` → [`fit_sparse_reml`](@ref); `:ai_reml` →
[`fit_ai_reml`](@ref)), and take percentile endpoints from the converged replicate
vectors via the in-package type-7 `_empirical_upper_quantile` (no `Statistics`
dependency). A replicate whose refit throws (`PosDefException`, etc.) or returns a
non-finite/boundary variance is DROPPED and counted: `n_converged` reports how many
of `n_boot` survived (non-convergence is surfaced, not hidden).

Returns a `NamedTuple`: `sigma_a2`, `sigma_e2`, `heritability` (the point estimates
from `fit`); `sigma_a2_ci`, `sigma_e2_ci`, `heritability_ci` (each `(lower, upper)`);
`level`, `n_boot`, `n_converged`, `method = :parametric_bootstrap_percentile`; and
`replicates` (the per-component converged-replicate vectors).

The interval FUNCTION is deterministic: `rng` defaults to a fixed-seed
`MersenneTwister`, so the result is reproducible at the call site (only opt-in sim
harnesses vary the seed).

EXPERIMENTAL, REML-only, univariate-Gaussian, dense/validation-scale (it forms
`inv(Ainv)` + `chol(A)`, guarded by `max_dense_cells`). It is a PERCENTILE bootstrap
(BCa is out of scope); its OWN coverage is NOT calibrated in CI (an opt-in coverage
sim is deferred follow-up) — it is the cross-check the delta/profile interval debt
names, not evidence that those intervals are correct. Rejects non-REML fits;
multivariate / non-Gaussian bootstrap CIs are separate slices.
"""
function bootstrap_variance_component_interval(fit::AnimalModelFit; level::Real = 0.95,
                                               n_boot::Integer = 1000,
                                               estimator::Symbol = :sparse_reml,
                                               rng::AbstractRNG = Random.MersenneTwister(0x48324352),
                                               max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1)"))
    n_boot > 0 || throw(ArgumentError("n_boot must be a positive integer"))
    estimator in (:sparse_reml, :ai_reml) ||
        throw(ArgumentError("estimator must be :sparse_reml or :ai_reml"))
    spec = fit.spec
    spec.method == :REML ||
        throw(ArgumentError("bootstrap_variance_component_interval requires a REML fit (spec.method == :REML)"))
    _check_dense_validation_size(spec, max_dense_cells)

    X = Matrix{Float64}(spec.X)
    Z = Matrix{Float64}(spec.Z)
    A = inv(Symmetric(Matrix{Float64}(Matrix(spec.Ainv))))
    LA = cholesky(Symmetric(A)).L
    beta = Float64.(fit.likelihood.beta)
    s2a = fit.variance_components.sigma_a2
    s2e = fit.variance_components.sigma_e2
    h2 = s2a / (s2a + s2e)
    n = length(spec.y); q = size(Z, 2)
    mu = X * beta
    refit = estimator === :sparse_reml ? fit_sparse_reml : fit_ai_reml

    sa = Float64[]; se = Float64[]; hh = Float64[]
    for _ in 1:n_boot
        ystar = mu .+ Z * (LA * randn(rng, q) .* sqrt(s2a)) .+ randn(rng, n) .* sqrt(s2e)
        try
            spec_b = animal_model_spec(ystar, X, Z, spec.Ainv; ids = spec.ids, method = :REML)
            fb = refit(spec_b)
            sab = fb.variance_components.sigma_a2; seb = fb.variance_components.sigma_e2
            (isfinite(sab) && isfinite(seb) && sab > 0 && seb > 0) || continue
            push!(sa, sab); push!(se, seb); push!(hh, sab / (sab + seb))
        catch
            # PosDefException / non-converged refit → dropped, surfaced via n_converged
        end
    end
    n_conv = length(sa)
    n_conv > 0 ||
        throw(ArgumentError("no bootstrap replicate converged to a finite interior optimum; no interval is reported"))
    plo = (1 - level) / 2; phi = (1 + level) / 2
    _ci(v) = (lower = _empirical_upper_quantile(v, plo), upper = _empirical_upper_quantile(v, phi))
    return (sigma_a2 = s2a, sigma_e2 = s2e, heritability = h2,
            sigma_a2_ci = _ci(sa), sigma_e2_ci = _ci(se), heritability_ci = _ci(hh),
            level = Float64(level), n_boot = Int(n_boot), n_converged = n_conv,
            method = :parametric_bootstrap_percentile,
            replicates = (sigma_a2 = sa, sigma_e2 = se, heritability = hh))
end

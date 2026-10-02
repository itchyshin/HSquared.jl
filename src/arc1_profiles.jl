# Arc 1 Gaussian repeatability profiles. This file stays separate from the
# legacy delta-method `repeatability_interval`; module integration is owned by
# the coordinator after the profile contract is reviewed.

const _ARC1_PROFILE_METHOD_VERSION = :arc1_profile_v1
const _ARC1_PROFILE_CUTOFF_95 = 3.841458820694124

function _arc1_profile_context(y::AbstractVector, X::AbstractMatrix,
                               Z::AbstractMatrix, Ainv::AbstractMatrix)
    yv, Xs = _likelihood_design(y, X; method = :REML)
    n, p = size(Xs, 1), size(Xs, 2)
    n > p || throw(ArgumentError("Arc1 repeatability profiling requires positive REML residual degrees of freedom"))

    Zs, Q, _ = _likelihood_random_inputs(Z, Ainv, n, 1)
    na = size(Zs, 2)
    row_nnz = vec(sum(Zs .!= 0; dims = 2))
    all(==(1), row_nnz) ||
        throw(ArgumentError("Arc1 repeatability profiling requires one animal incidence per record"))
    all(==(1.0), nonzeros(Zs)) ||
        throw(ArgumentError("Arc1 repeatability profiling requires unit animal incidence entries"))
    record_counts = vec(sum(Zs; dims = 1))
    all(x -> x == 0.0 || x == 2.0, record_counts) ||
        throw(ArgumentError("Arc1 repeatability profiling requires each animal to have zero or exactly two records"))
    count(==(2.0), record_counts) > 0 ||
        throw(ArgumentError("Arc1 repeatability profiling requires at least one observed animal"))

    A = _dense_relationship_covariance(Q)
    Zd = Matrix{Float64}(Zs)
    animal_covariance = Zd * A * Zd'
    permanent_covariance = Zd * Zd'
    identity_covariance = Matrix{Float64}(I, n, n)
    convention = loglik_convention_fields(LOGLIK_CONVENTION_OMIT_2PI, n, p)
    return merge((
        y = Vector{Float64}(yv),
        X = Matrix{Float64}(Xs),
        Z = Zd,
        A = A,
        animal_covariance = Symmetric(animal_covariance),
        permanent_covariance = Symmetric(permanent_covariance),
        identity_covariance = identity_covariance,
        nobs = n,
        nfixed = p,
        residual_df = n - p,
        method = :REML,
        estimand = :gaussian_repeatability,
        method_version = _ARC1_PROFILE_METHOD_VERSION,
    ), convention)
end

function _arc1_profile_result(context, loglik, status, beta, sigma_a2, sigma_pe2, sigma_e2)
    return merge((
        loglik = loglik,
        status = status,
        beta = beta,
        variance_components = (sigma_a2 = Float64(sigma_a2),
                               sigma_pe2 = Float64(sigma_pe2),
                               sigma_e2 = Float64(sigma_e2)),
        estimand = context.estimand,
        method = context.method,
        method_version = context.method_version,
    ), loglik_convention_fields(context.loglik_convention, context.nobs, context.nfixed))
end

function _arc1_profile_reml(context, sigma_a2::Real,
                            sigma_pe2::Real, sigma_e2::Real)
    components = (sigma_a2, sigma_pe2, sigma_e2)
    all(x -> x isa Real && isfinite(x) && x >= 0, components) ||
        throw(ArgumentError("Arc1 profile variance components must be finite and nonnegative"))
    sigma_e2 > 0 ||
        return _arc1_profile_result(context, -Inf, :singular_proposal,
                                    fill(NaN, context.nfixed), components...)

    V = sigma_a2 .* context.animal_covariance .+
        sigma_pe2 .* context.permanent_covariance .+
        sigma_e2 .* context.identity_covariance
    try
        Fv = cholesky(Symmetric(Matrix(V)); check = true)
        ViX = Fv \ context.X
        Viy = Fv \ context.y
        fixed_information = Symmetric(context.X' * ViX)
        Fx = cholesky(fixed_information; check = true)
        beta = Fx \ (context.X' * Viy)
        residual = context.y - context.X * beta
        residual_quadratic = dot(residual, Fv \ residual)
        logdet_v = 2sum(log, diag(Fv.L))
        logdet_x = 2sum(log, diag(Fx.L))
        loglik = -0.5 * (logdet_v + logdet_x + residual_quadratic)
        isfinite(loglik) ||
            return _arc1_profile_result(context, -Inf, :singular_proposal,
                                        fill(NaN, context.nfixed), components...)
        return _arc1_profile_result(context, loglik, :ok, beta, components...)
    catch err
        if err isa PosDefException || err isa SingularException ||
           err isa LinearAlgebra.LAPACKException || err isa LinearAlgebra.ZeroPivotException
            return _arc1_profile_result(context, -Inf, :singular_proposal,
                                        fill(NaN, context.nfixed), components...)
        end
        rethrow()
    end
end

function _arc1_profile_scale(context, proportions::Tuple)
    length(proportions) == 3 ||
        throw(ArgumentError("Arc1 component proportions must have length three"))
    all(x -> x isa Real && isfinite(x) && x >= 0, proportions) ||
        throw(ArgumentError("Arc1 component proportions must be finite and nonnegative"))
    isapprox(sum(proportions), 1.0; rtol = 0, atol = 32eps(Float64)) ||
        throw(ArgumentError("Arc1 component proportions must sum to one"))
    proportions[3] > 0 ||
        throw(ArgumentError("Arc1 scale profiling requires a positive residual proportion"))

    V0 = proportions[1] .* context.animal_covariance .+
         proportions[2] .* context.permanent_covariance .+
         proportions[3] .* context.identity_covariance
    Fv = cholesky(Symmetric(Matrix(V0)); check = true)
    ViX = Fv \ context.X
    Viy = Fv \ context.y
    Fx = cholesky(Symmetric(context.X' * ViX); check = true)
    beta = Fx \ (context.X' * Viy)
    residual = context.y - context.X * beta
    residual_quadratic = dot(residual, Fv \ residual)
    scale = residual_quadratic / context.residual_df
    (isfinite(scale) && scale > 0) ||
        throw(ArgumentError("Arc1 analytic total variance is not finite and positive"))
    return scale
end

function _arc1_components_at_ratio(target::Symbol, ratio::Real,
                                   scale::Real, allocation::Real)
    target in (:heritability, :repeatability) ||
        throw(ArgumentError("Arc1 ratio target must be :heritability or :repeatability"))
    (isfinite(ratio) && 0 <= ratio <= 1) ||
        throw(ArgumentError("Arc1 ratio must be finite and in [0, 1]"))
    (isfinite(scale) && scale > 0) ||
        throw(ArgumentError("Arc1 total variance must be finite and positive"))
    (isfinite(allocation) && 0 <= allocation <= 1) ||
        throw(ArgumentError("Arc1 nuisance allocation must be finite and in [0, 1]"))

    if target === :heritability
        sigma_a2 = scale * ratio
        sigma_pe2 = scale * (1 - ratio) * allocation
        sigma_e2 = scale * (1 - ratio) * (1 - allocation)
    else
        sigma_a2 = scale * ratio * allocation
        sigma_pe2 = scale * ratio * (1 - allocation)
        sigma_e2 = scale * (1 - ratio)
    end
    return (sigma_a2 = sigma_a2, sigma_pe2 = sigma_pe2, sigma_e2 = sigma_e2)
end

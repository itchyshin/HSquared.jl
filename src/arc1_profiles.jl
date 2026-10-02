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
    observed_animals = findall(==(2.0), record_counts)
    Aobs = Matrix(Symmetric(A[observed_animals, observed_animals]))
    eig = eigen(Symmetric(Aobs))
    minimum(eig.values) > 0 ||
        throw(ArgumentError("Arc1 observed-animal relationship covariance must be positive definite"))

    # Build an orthonormal sum/difference transform from actual incidence rows,
    # so neither animal column order nor record order is part of the contract.
    m = length(observed_animals)
    pair_transform = zeros(2m, n)
    for (j, animal) in pairs(observed_animals)
        rows = findall(!iszero, view(Zd, :, animal))
        length(rows) == 2 || error("validated repeated-animal row count changed")
        pair_transform[j, rows[1]] = inv(sqrt(2.0))
        pair_transform[j, rows[2]] = inv(sqrt(2.0))
        pair_transform[m + j, rows[1]] = inv(sqrt(2.0))
        pair_transform[m + j, rows[2]] = -inv(sqrt(2.0))
    end
    transform = vcat(eig.vectors' * pair_transform[1:m, :],
                     pair_transform[(m + 1):(2m), :])
    baseline_beta = qr(Matrix{Float64}(Xs)) \ Vector{Float64}(yv)
    H = transform * Matrix{Float64}(Xs)
    z = transform * (Vector{Float64}(yv) - Matrix{Float64}(Xs) * baseline_beta)
    convention = loglik_convention_fields(LOGLIK_CONVENTION_OMIT_2PI, n, p)
    return merge((
        y = Vector{Float64}(yv),
        X = Matrix{Float64}(Xs),
        Z = Zd,
        A = A,
        observed_animals = observed_animals,
        animal_eigenvalues = Vector{Float64}(eig.values),
        transform = transform,
        transformed_response = z,
        transformed_design = H,
        baseline_beta = Vector{Float64}(baseline_beta),
        nobs = n,
        nfixed = p,
        nobserved_animals = m,
        residual_df = 2m - p,
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

    try
        m = context.nobserved_animals
        v = vcat(2sigma_a2 .* context.animal_eigenvalues .+ 2sigma_pe2 .+ sigma_e2,
                 fill(Float64(sigma_e2), m))
        all(x -> isfinite(x) && x > 0, v) ||
            return _arc1_profile_result(context, -Inf, :singular_proposal,
                                        fill(NaN, context.nfixed), components...)
        w = 1.0 ./ v
        H, z = context.transformed_design, context.transformed_response
        M = Symmetric(H' * (w .* H))
        FM = cholesky(M; check = true)
        delta = FM \ (H' * (w .* z))
        beta = context.baseline_beta + delta
        residual = z - H * delta
        q = dot(residual, w .* residual)
        logdet_v = sum(log, v)
        logdet_m = 2sum(log, diag(FM.L))
        loglik = -0.5 * (logdet_v + logdet_m + q)
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

function _arc1_profile_objective_gradient(context, components::AbstractVector;
                                          free_indices = collect(eachindex(components)))
    length(components) == 3 || throw(ArgumentError("Arc1 requires three variance components"))
    length(free_indices) == length(unique(free_indices)) &&
        all(i -> i in 1:3, free_indices) ||
        throw(ArgumentError("free_indices must be unique component indices"))
    fit = _arc1_profile_reml(context, components...)
    fit.status == :ok ||
        return (loglik = fit.loglik, beta = fit.beta, objective = Inf,
                component_gradient = fill(NaN, 3), log_gradient = fill(NaN, length(free_indices)))
    m = context.nobserved_animals
    v = vcat(2components[1] .* context.animal_eigenvalues .+
             2components[2] .+ components[3], fill(Float64(components[3]), m))
    w = 1.0 ./ v
    H, z = context.transformed_design, context.transformed_response
    M = Symmetric(H' * (w .* H))
    FM = cholesky(M; check = true)
    delta = FM \ (H' * (w .* z))
    residual = z - H * delta
    r = Vector{Float64}(undef, 2m)
    for i in 1:(2m)
        # H_i M^-1 H_i' using the small fixed-effect Cholesky factor only.
        solved = FM \ view(H, i, :)
        leverage = dot(view(H, i, :), solved)
        r[i] = (w[i] - w[i]^2 * leverage - (w[i] * residual[i])^2) /
               (2context.residual_df)
    end
    gradient = [sum((2 .* context.animal_eigenvalues) .* view(r, 1:m)),
                2sum(view(r, 1:m)), sum(r)]
    log_gradient = [gradient[i] * components[i] for i in free_indices]
    return (loglik = fit.loglik, beta = fit.beta,
            objective = -fit.loglik / context.residual_df,
            component_gradient = gradient, log_gradient = log_gradient)
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

    m = context.nobserved_animals
    h = vcat(2proportions[1] .* context.animal_eigenvalues .+
             2proportions[2] .+ proportions[3], fill(Float64(proportions[3]), m))
    all(x -> isfinite(x) && x > 0, h) ||
        throw(ArgumentError("Arc1 unit-proportion covariance is singular"))
    w = 1.0 ./ h
    H, z = context.transformed_design, context.transformed_response
    Fm = cholesky(Symmetric(H' * (w .* H)); check = true)
    delta = Fm \ (H' * (w .* z))
    residual = z - H * delta
    residual_quadratic = dot(residual, w .* residual)
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

const _ARC1_PROFILE_TARGETS = (
    :additive_variance,
    :permanent_environment_variance,
    :residual_variance,
    :heritability,
    :repeatability,
)
const _ARC1_START_MULTIPLIERS = (0.01, 0.1, 0.5, 1.0, 5.0)

mutable struct _Arc1ProfileState
    context::Any
    s0::Float64
    point_loglik::Float64
    caches::Dict{Symbol,Dict{Float64,Any}}
    evaluation_counts::Dict{Symbol,Int}
    max_constrained_loglik::Float64
    nuisance_statuses::Vector{Any}
end

_arc1_point_fit_not_optimal(point_loglik::Real, constrained_loglik::Real) =
    constrained_loglik > point_loglik + 1e-7

function _arc1_include_valid_profile_max!(state::_Arc1ProfileState, profile)
    evaluated_max = hasproperty(profile, :max_valid_loglik) ?
                    profile.max_valid_loglik : profile.loglik
    isfinite(evaluated_max) &&
        (state.max_constrained_loglik = max(state.max_constrained_loglik, evaluated_max))
    return state.max_constrained_loglik
end

function _arc1_profile_probe_recorders!(maximum_seen::Base.RefValue{Float64},
        loglik_at, gradient_at)
    record!(value) = begin
        isfinite(value) && (maximum_seen[] = max(maximum_seen[], Float64(value)))
        value
    end
    recorded_loglik_at = components -> begin
        result = loglik_at(components)
        if result isa Tuple && length(result) >= 2 && result[2] == :ok
            record!(result[1])
        end
        result
    end
    recorded_gradient_at = (components; free_indices) -> begin
        result = gradient_at(components; free_indices)
        hasproperty(result, :loglik) && record!(result.loglik)
        result
    end
    return recorded_loglik_at, recorded_gradient_at
end

function _arc1_raw_competitor_is_competitive(candidate, best_loglik::Real)
    candidate.converged && return false
    evaluated = hasproperty(candidate, :max_valid_loglik) ?
                candidate.max_valid_loglik : candidate.loglik
    return evaluated > best_loglik + 1e-8 ||
           (candidate.hit_bound && evaluated >= best_loglik - 1e-8)
end

function _arc1_zero_bound_face_certificate(candidate, target_index::Int, s0::Float64,
        residual_df::Real, faces, intersection, loglik_at, gradient_at;
        historical_likelihoods::AbstractVector{<:Real} = Float64[])
    contacts = hasproperty(candidate, :hit_bound_components) ?
               candidate.hit_bound_components : Any[]
    isempty(contacts) && return (status = :not_applicable,)
    all(c -> c.side === :lower && c.component in (1, 2) &&
             c.component != target_index, contacts) ||
        return (status = :ineligible_contact,)
    hasproperty(candidate, :optimizer_converged) && candidate.optimizer_converged ||
        return (status = :optimizer_unconverged,)
    hasproperty(candidate, :analytic_gradient_valid) && candidate.analytic_gradient_valid ||
        return (status = :invalid_analytic_gradient,)
    hasproperty(candidate, :line_search_failed) && !candidate.line_search_failed ||
        return (status = :line_search_failed,)
    fd_errors = hasproperty(candidate, :finite_difference_errors) ?
                candidate.finite_difference_errors : Dict{Int,Float64}()
    hasproperty(candidate, :free_indices) ||
        return (status = :finite_difference_unavailable,)
    contact_indices = Set(c.component for c in contacts)
    all(index -> begin
            error = get(fd_errors, index, Inf)
            index in contact_indices ?
                (isfinite(error) ? error <= 5e-6 : isinf(error)) :
                (isfinite(error) && error <= 5e-6)
        end, candidate.free_indices) ||
        return (status = :remaining_finite_difference_unresolved,)
    zero_indices = sort!(unique!(Int[c.component for c in contacts]))
    face = if length(zero_indices) == 1
        matches = filter(f -> f.zero_index == only(zero_indices) && f.status == :ok, faces)
        isempty(matches) ? nothing : only(matches)
    else
        intersection !== nothing && intersection.status == :ok ? intersection : nothing
    end
    face === nothing && return (status = :matching_zero_face_unavailable,
                                zero_indices = zero_indices)

    projected = copy(candidate.components)
    projected[zero_indices] .= 0.0
    all(i -> face.components[i] == projected[i], (target_index,)) &&
        all(i -> face.components[i] == 0.0, zero_indices) ||
        return (status = :face_components_mismatch, zero_indices = zero_indices)

    original_ll = candidate.loglik
    projected_ll, projected_status = loglik_at(projected)
    projected_status == :ok && all(isfinite, (original_ll, projected_ll, face.loglik)) ||
        return (status = :nonfinite_face_likelihood, zero_indices = zero_indices)
    comparison_likelihoods = Float64[original_ll, projected_ll, face.loglik]
    append!(comparison_likelihoods, Float64.(historical_likelihoods))
    likelihood_spread = maximum(comparison_likelihoods) - minimum(comparison_likelihoods)
    likelihood_spread <= 1e-8 ||
        return (status = :face_likelihood_mismatch, zero_indices = zero_indices,
                likelihood_spread = likelihood_spread)
    candidate_maximum = hasproperty(candidate, :max_valid_loglik) ?
                        candidate.max_valid_loglik : original_ll
    abs(candidate_maximum - face.loglik) <= 1e-8 ||
        return (status = :candidate_maximum_mismatch, zero_indices = zero_indices,
                original_loglik = original_ll, projected_loglik = projected_ll,
                face_loglik = face.loglik, candidate_max_valid_loglik = candidate_maximum,
                likelihood_spread = likelihood_spread)

    free_indices = filter(i -> i != target_index && !(i in zero_indices), 1:3)
    grad = gradient_at(projected; free_indices)
    projected_gradient_norm = maximum(abs, grad.log_gradient; init = 0.0)
    isfinite(projected_gradient_norm) && projected_gradient_norm <= 1e-6 ||
        return (status = :projected_gradient_unresolved, zero_indices = zero_indices,
                original_loglik = original_ll, projected_loglik = projected_ll,
                face_loglik = face.loglik, likelihood_spread = likelihood_spread,
                projected_gradient_norm = projected_gradient_norm)

    analytic_active = Dict{Int,Float64}()
    forward_active = Dict{Int,NTuple{2,Float64}}()
    q_at(components) = begin
        ll, status = loglik_at(components)
        status == :ok && isfinite(ll) ? -ll / residual_df : NaN
    end
    q0 = q_at(projected)
    isfinite(q0) || return (status = :active_derivative_nonfinite,
                            zero_indices = zero_indices)
    for index in zero_indices
        analytic = s0 * grad.component_gradient[index]
        isfinite(analytic) && analytic > 5e-6 ||
            return (status = :active_derivative_not_positive,
                    zero_indices = zero_indices, analytic_active_derivatives = analytic_active)
        analytic_active[index] = analytic
        estimates = Float64[]
        for h in (1e-4, 1e-5)
            one = copy(projected); one[index] = h * s0
            two = copy(projected); two[index] = 2h * s0
            q1, q2 = q_at(one), q_at(two)
            fd = (-3q0 + 4q1 - q2) / (2h)
            isfinite(fd) && fd >= 0 && abs(fd - analytic) <= 5e-6 ||
                return (status = :forward_derivative_unresolved,
                        zero_indices = zero_indices,
                        analytic_active_derivatives = analytic_active,
                        forward_derivative = fd, step = h)
            push!(estimates, fd)
        end
        abs(estimates[1] - estimates[2]) <= 5e-6 ||
            return (status = :forward_derivative_disagreement,
                    zero_indices = zero_indices,
                    analytic_active_derivatives = analytic_active,
                    forward_derivatives = estimates)
        forward_active[index] = (estimates[1], estimates[2])
    end
    return (status = :resolved_lower_bound_by_zero_face,
            zero_indices = zero_indices, components = copy(face.components),
            loglik = face.loglik, projected_components = projected,
            original_loglik = original_ll, projected_loglik = projected_ll,
            face_loglik = face.loglik, likelihood_spread = likelihood_spread,
            projected_log_gradient_norm = projected_gradient_norm,
            analytic_active_derivatives = analytic_active,
            forward_derivatives = forward_active)
end

function _arc1_projected_face_polish(context, candidate, target_index::Int,
        s0::Float64, residual_df::Real, faces, intersection, initial_certificate;
        maximum_seen::Base.RefValue{Float64} = Ref(Float64(candidate.max_valid_loglik)),
        loglik_at = components -> _arc1_loglik_for_components(context, components),
        gradient_at = (components; free_indices) ->
            _arc1_profile_objective_gradient(context, components; free_indices),
        continuation_runner = (ctx, base, free, starts, scale, budget) ->
            _arc1_bfgs_candidate(ctx, base, free, starts, scale;
                                 max_iterations = budget))
    contacts = hasproperty(candidate, :hit_bound_components) ?
               candidate.hit_bound_components : Any[]
    zero_indices = sort!(unique!(Int[c.component for c in contacts]))
    record(status; kwargs...) = merge((status = status,
        parent_candidate_index = get(candidate, :candidate_index, missing),
        original_iterations = hasproperty(candidate, :iterations) ? candidate.iterations : 0,
        continuation_iterations = 0,
        combined_iterations = hasproperty(candidate, :iterations) ? candidate.iterations : 0,
        objective_evaluations = 0, gradient_evaluations = 0,
        max_valid_loglik = maximum_seen[], initial_certificate = initial_certificate),
        (; kwargs...))
    initial_certificate.status == :projected_gradient_unresolved ||
        return (status = :not_eligible, continuation = record(:not_eligible))
    !isempty(zero_indices) && all(i -> i in (1, 2), zero_indices) ||
        return (status = :ineligible_contacts, continuation = record(:ineligible_contacts))
    all(c -> c.side === :lower, contacts) ||
        return (status = :ineligible_contacts, continuation = record(:ineligible_contacts))
    projected = copy(candidate.components)
    projected[zero_indices] .= 0.0
    remaining = filter(i -> i != target_index && !(i in zero_indices), candidate.free_indices)
    original_iterations = Int(candidate.iterations)
    allowance = max(0, 2000 - original_iterations)
    allowance > 0 || return (status = :iteration_budget_exhausted,
        continuation = record(:iteration_budget_exhausted,
            starting_projection = projected, remaining_indices = remaining,
            iteration_allowance = allowance))
    isempty(remaining) && return (status = :no_remaining_positive_coordinates,
        continuation = record(:no_remaining_positive_coordinates,
            starting_projection = projected, remaining_indices = remaining,
            iteration_allowance = allowance))

    continuation = try
        continuation_runner(context, projected, remaining, projected[remaining], s0, allowance)
    catch err
        err isa InterruptException && rethrow()
        return (status = :continuation_exception,
            continuation = record(:continuation_exception,
                error = sprint(showerror, err), starting_projection = projected,
                remaining_indices = remaining, iteration_allowance = allowance))
    end
    continuation_maximum = hasproperty(continuation, :max_valid_loglik) ?
                            continuation.max_valid_loglik : -Inf
    isfinite(continuation_maximum) &&
        (maximum_seen[] = max(maximum_seen[], continuation_maximum))
    continuation_iterations = hasproperty(continuation, :iterations) ?
                              Int(continuation.iterations) : allowance
    combined_iterations = original_iterations + continuation_iterations
    continuation_record(status; kwargs...) = record(status;
        parent_candidate_index = get(candidate, :candidate_index, missing),
        starting_projection = projected,
        returned_components = hasproperty(continuation, :components) ?
                              continuation.components : nothing,
        continuation_loglik = hasproperty(continuation, :loglik) ? continuation.loglik : -Inf,
        continuation_gradient_norm = hasproperty(continuation, :gradient_norm) ?
                                     continuation.gradient_norm : Inf,
        termination_code = hasproperty(continuation, :termination_code) ?
                           continuation.termination_code : :missing,
        stopped_by = hasproperty(continuation, :stopped_by) ? continuation.stopped_by : nothing,
        original_iterations = original_iterations,
        continuation_iterations = continuation_iterations,
        combined_iterations = combined_iterations,
        iteration_allowance = allowance,
        objective_evaluations = hasproperty(continuation, :objective_evaluations) ?
                                continuation.objective_evaluations : 0,
        gradient_evaluations = hasproperty(continuation, :gradient_evaluations) ?
                               continuation.gradient_evaluations : 0,
        max_valid_loglik = maximum_seen[],
        continuation_status = hasproperty(continuation, :optimizer_status) ?
                              continuation.optimizer_status : :missing,
        new_bound_contacts = hasproperty(continuation, :hit_bound_components) ?
                             continuation.hit_bound_components : Any[], kwargs...)
    if hasproperty(continuation, :hit_bound_components) &&
       !isempty(continuation.hit_bound_components)
        return (status = :additional_bound_contact,
            continuation = continuation_record(:additional_bound_contact))
    end
    hasproperty(continuation, :converged) && continuation.converged ||
        return (status = :continuation_unresolved,
            continuation = continuation_record(:continuation_unresolved))

    merged_fd = merge(candidate.finite_difference_errors,
        hasproperty(continuation, :finite_difference_errors) ?
        continuation.finite_difference_errors : Dict{Int,Float64}())
    polished_candidate = merge(candidate, (; components = continuation.components,
        max_valid_loglik = maximum_seen[], optimizer_converged = continuation.optimizer_converged,
        gradient_norm = continuation.gradient_norm,
        analytic_gradient_valid = continuation.analytic_gradient_valid,
        line_search_failed = continuation.line_search_failed,
        finite_difference_errors = merged_fd))
    probe_ll, probe_gradient = _arc1_profile_probe_recorders!(maximum_seen,
        loglik_at, gradient_at)
    certificate = try
        _arc1_zero_bound_face_certificate(polished_candidate, target_index, s0,
            residual_df, faces, intersection, probe_ll, probe_gradient;
            historical_likelihoods = [initial_certificate.projected_loglik,
                                      continuation.loglik])
    catch err
        err isa InterruptException && rethrow()
        (status = :polished_certificate_exception, error = sprint(showerror, err))
    end
    if certificate.status == :resolved_lower_bound_by_zero_face &&
       maximum_seen[] > certificate.face_loglik + 1e-8
        certificate = merge(certificate, (status = :better_probe_likelihood,
            candidate_max_valid_loglik = maximum_seen[]))
    end
    if certificate.status != :resolved_lower_bound_by_zero_face
        return (status = certificate.status,
            continuation = continuation_record(certificate.status,
                finite_difference_errors = continuation.finite_difference_errors,
                boundary_certificate = certificate))
    end
    return (status = :resolved_projected_face_polish,
        loglik = continuation.loglik, components = copy(continuation.components),
        max_valid_loglik = maximum_seen[],
        boundary_certificate = certificate,
        continuation = continuation_record(:resolved_projected_face_polish,
            finite_difference_errors = continuation.finite_difference_errors,
            boundary_certificate = certificate))
end

function _arc1_segments_from_scores(xs::AbstractVector, scores::AbstractVector,
                                    score_at; tolerance::Real)
    length(xs) == length(scores) ||
        throw(ArgumentError("profile grid and score lengths must match"))
    length(xs) >= 2 || throw(ArgumentError("profile scan requires at least two grid points"))
    all(isfinite, xs) && all(diff(xs) .> 0) ||
        throw(ArgumentError("profile grid must be finite and strictly increasing"))
    all(x -> isfinite(x) || x == Inf, scores) ||
        return (segments = Tuple{Float64,Float64}[], status = :unresolved_search,
                roots = Float64[], root_terminations = Symbol[])

    segments = Tuple{Float64,Float64}[]
    roots = Float64[]
    root_terminations = Symbol[]
    active = scores[1] <= 0
    left = active ? Float64(first(xs)) : NaN
    for i in 1:(length(xs) - 1)
        lo, hi = Float64(xs[i]), Float64(xs[i + 1])
        slo, shi = Float64(scores[i]), Float64(scores[i + 1])
        if (slo <= 0) != (shi <= 0)
            a, b, fa, fb = lo, hi, slo, shi
            root = NaN
            for _ in 1:200
                if abs(b - a) <= tolerance
                    root = a / 2 + b / 2
                    push!(root_terminations, :bracket_tolerance)
                    break
                end
                mid = a / 2 + b / 2
                if mid == a || mid == b
                    push!(root_terminations, :representable_limit)
                    return (segments = Tuple{Float64,Float64}[],
                            status = :unresolved_search, roots = roots,
                            root_terminations = root_terminations)
                end
                fm = Float64(score_at(mid))
                if !isfinite(fm)
                    return (segments = Tuple{Float64,Float64}[],
                            status = :unresolved_search, roots = roots,
                            root_terminations = root_terminations)
                end
                if (fa <= 0) == (fm <= 0)
                    a, fa = mid, fm
                else
                    b, fb = mid, fm
                end
            end
            isfinite(root) ||
                return (segments = Tuple{Float64,Float64}[],
                        status = :unresolved_search, roots = roots,
                        root_terminations = root_terminations)
            push!(roots, root)
            if active
                push!(segments, (left, root))
                active = false
            else
                left = root
                active = true
            end
        end
    end
    active && push!(segments, (left, Float64(last(xs))))
    return (segments = segments, status = :ok, roots = roots,
            root_terminations = root_terminations)
end

function _arc1_profile_score(state::_Arc1ProfileState, target::Symbol, value::Real)
    profile = _arc1_profile_at(state, target, Float64(value))
    profile.status == :ok || return NaN
    return 2 * (state.point_loglik - profile.loglik) - _ARC1_PROFILE_CUTOFF_95
end

function _arc1_profile_cache!(state::_Arc1ProfileState, target::Symbol, value::Float64)
    cache = get!(state.caches, target, Dict{Float64,Any}())
    if haskey(cache, value)
        return cache[value]
    end
    count = get(state.evaluation_counts, target, 0)
    if count >= 4097
        return (loglik = -Inf, status = :unresolved_search_budget,
                      nuisance_statuses = Any[:target_evaluation_budget])
    end
    state.evaluation_counts[target] = count + 1
    result = _arc1_profile_at_uncached(state, target, value)
    cache[value] = result
    _arc1_include_valid_profile_max!(state, result)
    return result
end

function _arc1_loglik_for_components(context, components)
    result = _arc1_profile_reml(context, components...)
    return result.loglik, result.status
end

function _arc1_scaled_gradient(objective, z::AbstractVector)
    gradient = _arc1_scaled_gradient_by_coordinate(objective, z)
    return all(isfinite, gradient) ? gradient : fill(Inf, length(z))
end

function _arc1_scaled_gradient_by_coordinate(objective, z::AbstractVector)
    gradient = similar(Float64.(z))
    for i in eachindex(z)
        step = 1e-5 * max(1.0, abs(z[i]))
        plus, minus = copy(Float64.(z)), copy(Float64.(z))
        plus[i] += step
        minus[i] -= step
        fp, fm = objective(plus), objective(minus)
        gradient[i] = isfinite(fp) && isfinite(fm) ? (fp - fm) / (2step) : Inf
    end
    return gradient
end

function _arc1_bfgs_candidate(context, base_components::Vector{Float64}, free_indices::Vector{Int},
                              start_values::Vector{Float64}, s0::Float64;
                              optimizer_runner = nothing, max_iterations::Int = 2000)
    lo, hi = log(s0 * 2.0^-40), log(s0 * 1.0e6)
    gradient_valid = Ref(false)
    max_valid_loglik = Ref(-Inf)
    objective_evaluations = Ref(0)
    gradient_evaluations = Ref(0)
    objective(z) = begin
        objective_evaluations[] += 1
        all(isfinite, z) || return Inf
        values = copy(base_components)
        for (j, index) in pairs(free_indices)
            z[j] < lo || z[j] > hi ? (return Inf) : nothing
            values[index] = exp(z[j])
        end
        ll, status = _arc1_loglik_for_components(context, values)
        status == :ok && isfinite(ll) &&
            (max_valid_loglik[] = max(max_valid_loglik[], ll))
        status == :ok ? -ll / context.residual_df : Inf
    end
    function gradient!(gradient, z)
        gradient_evaluations[] += 1
        values = copy(base_components)
        for (j, index) in pairs(free_indices)
            if z[j] < lo || z[j] > hi
                gradient_valid[] = false
                fill!(gradient, 0.0)
                return
            end
            values[index] = exp(z[j])
        end
        gradresult = _arc1_profile_objective_gradient(context, values; free_indices)
        isfinite(gradresult.loglik) && isfinite(gradresult.objective) &&
            (max_valid_loglik[] = max(max_valid_loglik[], gradresult.loglik))
        if !all(isfinite, gradresult.log_gradient)
            gradient_valid[] = false
            fill!(gradient, 0.0)
            return
        end
        gradient .= gradresult.log_gradient
        gradient_valid[] = true
        return
    end
    start = log.(start_values)
    result = try
        optimizer_runner === nothing ?
            Optim.optimize(objective, gradient!, start, Optim.BFGS(),
                           _arc1_bfgs_options(max_iterations)) :
            optimizer_runner(objective, gradient!, start)
    catch err
        if err isa InterruptException
            rethrow()
        end
        return (loglik = -Inf, max_valid_loglik = max_valid_loglik[],
                components = copy(base_components), free_indices = copy(free_indices),
                converged = false,
                gradient_norm = Inf, optimizer_status = sprint(showerror, err),
                hit_bound = false, finite_difference_error = Inf,
                analytic_gradient_valid = false, line_search_failed = false,
                optimizer_converged = false,
                termination_code = :exception, stopped_by = nothing, iterations = 0,
                hit_bound_components = Any[],
                objective_evaluations = objective_evaluations[],
                gradient_evaluations = gradient_evaluations[])
    end
    zhat = Optim.minimizer(result)
    values = copy(base_components)
    for (j, index) in pairs(free_indices)
        values[index] = exp(zhat[j])
    end
    ll, status = _arc1_loglik_for_components(context, values)
    status == :ok && isfinite(ll) &&
        (max_valid_loglik[] = max(max_valid_loglik[], ll))
    gradient = similar(zhat)
    gradient_valid[] = false
    gradient!(gradient, zhat)
    gradient_norm = all(isfinite, gradient) ? maximum(abs, gradient; init = 0.0) : Inf
    finite_difference_by_coordinate = _arc1_scaled_gradient_by_coordinate(objective, zhat)
    finite_difference_errors = Dict(free_indices[j] =>
        (isfinite(finite_difference_by_coordinate[j]) && isfinite(gradient[j]) ?
         abs(finite_difference_by_coordinate[j] - gradient[j]) : Inf)
        for j in eachindex(free_indices))
    finite_difference = all(isfinite, finite_difference_by_coordinate) ?
                        finite_difference_by_coordinate : fill(Inf, length(zhat))
    fd_error = maximum(Base.values(finite_difference_errors); init = 0.0)
    hit_bound_components = [(component = free_indices[j],
        side = zhat[j] - lo <= 1e-5 ? :lower : :upper,
        value = values[free_indices[j]], log_value = zhat[j])
        for j in eachindex(zhat) if zhat[j] - lo <= 1e-5 || hi - zhat[j] <= 1e-5]
    hit_bound = !isempty(hit_bound_components)
    ls_failed = hasproperty(result, :stopped_by) &&
                hasproperty(result.stopped_by, :ls_failed) &&
                result.stopped_by.ls_failed === true
    optimizer_converged = Optim.converged(result)
    converged = status == :ok && isfinite(ll) && isfinite(objective(zhat)) &&
                optimizer_converged && gradient_valid[] && all(isfinite, gradient) &&
                all(isfinite, finite_difference_by_coordinate) && fd_error <= 5e-6 &&
                all(z -> isfinite(z) && lo <= z <= hi, zhat) &&
                gradient_norm <= 1e-6 && !hit_bound && !ls_failed
    return (loglik = status == :ok ? ll : -Inf, max_valid_loglik = max_valid_loglik[],
            components = values, free_indices = copy(free_indices),
            converged = converged, gradient_norm = gradient_norm,
            finite_difference_gradient = finite_difference,
            finite_difference_error = fd_error,
            finite_difference_errors = finite_difference_errors,
            analytic_gradient_valid = gradient_valid[],
            line_search_failed = ls_failed,
            optimizer_converged = optimizer_converged,
            termination_code = result.termination_code,
            stopped_by = result.stopped_by,
            iterations = result.iterations,
            hit_bound_components = hit_bound_components,
            optimizer_status = ls_failed ? "line_search_failed" :
                               (Optim.converged(result) ? "converged" : "not_converged"),
            hit_bound = hit_bound,
            objective_evaluations = objective_evaluations[],
            gradient_evaluations = gradient_evaluations[])
end

_arc1_bfgs_options(iterations::Int = 2000) = Optim.Options(iterations = iterations, g_tol = 1e-8,
                                     f_reltol = 0.0, x_abstol = 0.0)

function _arc1_point_fit(context, s0::Float64)
    candidates = Any[]
    failures = Any[]
    for multiplier in _ARC1_START_MULTIPLIERS
        start = fill(s0 * multiplier, 3)
        push!(candidates, _arc1_bfgs_candidate(context, zeros(3), [1, 2, 3], start, s0))
    end
    for fixed_zero in (1, 2)
        base = zeros(3)
        free = fixed_zero == 1 ? [2, 3] : [1, 3]
        for multiplier in _ARC1_START_MULTIPLIERS
            push!(candidates,
                  _arc1_bfgs_candidate(context, base, free,
                                       fill(s0 * multiplier, 2), s0))
        end
    end
    # The both-zero random-effect face has the exact residual-only scale estimate.
    residual_only = _arc1_profile_reml(context, 0.0, 0.0, s0)
    push!(candidates, (loglik = residual_only.loglik,
                       components = [0.0, 0.0, s0],
                       converged = residual_only.status == :ok,
                       gradient_norm = 0.0, optimizer_status = "analytic_residual_only",
                       hit_bound = false))

    finite = filter(c -> isfinite(c.loglik), candidates)
    converged = filter(c -> c.converged, finite)
    isempty(converged) &&
        return (fit = nothing, status = :point_fit_unconverged,
                candidates = candidates, nuisance_statuses = failures)
    best = converged[argmax(getproperty.(converged, :loglik))]
    better_unconverged = filter(c -> !c.converged && c.loglik > best.loglik + 1e-8, finite)
    if !isempty(better_unconverged)
        return (fit = best, status = :point_fit_unconverged,
                candidates = candidates, nuisance_statuses = better_unconverged)
    end
    return (fit = best, status = :ok, candidates = candidates,
            nuisance_statuses = failures)
end

struct _Arc1BracketEvaluationLimit <: Exception end
Base.showerror(io::IO, ::_Arc1BracketEvaluationLimit) =
    print(io, "Arc1 Brent bracket exceeded its evaluation limit")

function _arc1_bounded_brent(objective, lower::Float64, upper::Float64;
                             x_tolerance::Float64, likelihood_tolerance::Float64 = 1e-8,
                             max_evaluations::Int = 2000)
    evaluations = Ref(0)
    best_objective = Ref(Inf)
    max_valid_loglik() = isfinite(best_objective[]) ? -best_objective[] : -Inf
    final_bracket = Ref((lower, upper))
    function guarded_objective(x)
        evaluations[] >= max_evaluations && throw(_Arc1BracketEvaluationLimit())
        evaluations[] += 1
        value = Float64(objective(Float64(x)))
        isfinite(value) && (best_objective[] = min(best_objective[], value))
        return value
    end
    current_lower, current_upper = lower, upper
    solver_tolerance = min(x_tolerance / 4, (upper - lower) / 4)
    result = nothing
    spread = Inf
    while evaluations[] < max_evaluations
        callback = state -> begin
            if hasproperty(state, :metadata)
                metadata = state.metadata
                if haskey(metadata, "x_lower") && haskey(metadata, "x_upper")
                    final_bracket[] = (Float64(metadata["x_lower"]),
                                       Float64(metadata["x_upper"]))
                end
            end
            false
        end
        result = try
            remaining = max_evaluations - evaluations[]
            Optim.optimize(guarded_objective, current_lower, current_upper, Optim.Brent();
                           rel_tol = 0.0, abs_tol = solver_tolerance,
                           iterations = remaining - 1, callback = callback,
                           show_warnings = false)
        catch err
            err isa InterruptException && rethrow()
            return (result = nothing, status = :optimizer_error,
                    error = sprint(showerror, err), evaluations = evaluations[],
                    bracket = final_bracket[], certified = false,
                    likelihood_spread = Inf, max_valid_loglik = max_valid_loglik())
        end
        maximizer = Float64(Optim.minimizer(result))
        bracket = final_bracket[]
        values = try
            (guarded_objective(bracket[1]), guarded_objective(bracket[2]),
             guarded_objective(maximizer))
        catch err
            err isa InterruptException && rethrow()
            return (result = result, status = :certification_budget,
                    error = sprint(showerror, err), evaluations = evaluations[],
                    bracket = bracket, certified = false,
                    likelihood_spread = Inf, max_valid_loglik = max_valid_loglik())
        end
        spread = all(isfinite, values) ? maximum(values) - minimum(values) : Inf
        width_ok = abs(bracket[2] - bracket[1]) <= x_tolerance
        Optim.converged(result) && width_ok && spread <= likelihood_tolerance &&
            return (result = result, status = :ok, error = nothing,
                    evaluations = evaluations[], bracket = bracket, certified = true,
                    likelihood_spread = spread, max_valid_loglik = max_valid_loglik())
        (Optim.converged(result) && width_ok) ||
            return (result = result, status = :uncertified, error = nothing,
                    evaluations = evaluations[], bracket = bracket, certified = false,
                    likelihood_spread = spread, max_valid_loglik = max_valid_loglik())
        current_lower, current_upper = bracket
        solver_tolerance = min(solver_tolerance / 4,
                               abs(current_upper - current_lower) / 4)
        solver_tolerance > 0 || break
    end
    return (result = result, status = :evaluation_budget, error = nothing,
            evaluations = evaluations[], bracket = final_bracket[], certified = false,
            likelihood_spread = spread, max_valid_loglik = max_valid_loglik())
end

function _arc1_cached_bracket_max(cache::AbstractDict, lower::Real, upper::Real;
                                  fallback::Real = -Inf)
    observed = (ll for (x, ll) in cache if lower <= x <= upper && isfinite(ll))
    return max(Float64(fallback), maximum(observed; init = -Inf))
end

function _arc1_unresolved_brent_max(cache::AbstractDict, search, lower::Real, upper::Real;
                                    fallback::Real = -Inf)
    searched = hasproperty(search, :max_valid_loglik) ? search.max_valid_loglik : -Inf
    return _arc1_cached_bracket_max(cache, lower, upper;
                                    fallback = max(Float64(fallback), searched))
end

_arc1_max_valid_profile_likelihood(candidates) = maximum((
    hasproperty(c, :max_valid_loglik) ? c.max_valid_loglik : c.loglik
    for c in candidates); init = -Inf)

function _arc1_physical_zero_endpoint_certificate(make_components,
        remaining_index::Int, target_index::Int, face_zero_index::Int,
        s0::Float64, residual_df::Real, lower_components::AbstractVector,
        lower_loglik::Real, maximum_seen::Base.RefValue{Float64}, loglik_at,
        gradient_at)
    refuse(status; kwargs...) = merge((status = status,
        max_valid_loglik = maximum_seen[]), (; kwargs...))
    remaining_index in (1, 2) && face_zero_index in (1, 2) &&
        target_index in 1:3 && remaining_index != target_index &&
        face_zero_index != target_index && face_zero_index != remaining_index ||
        return refuse(:ineligible_zero_endpoint)
    isapprox(lower_components[remaining_index] / s0, 2.0^-40;
             rtol = 1e-8, atol = 0.0) || return refuse(:not_artificial_lower_endpoint)
    endpoint = Float64.(make_components(0.0))
    length(endpoint) == 3 && length(lower_components) == 3 &&
        all(isfinite, endpoint) && all(>=(0.0), endpoint) ||
        return refuse(:invalid_zero_endpoint_components)
    endpoint[remaining_index] == 0.0 && endpoint[face_zero_index] == 0.0 &&
        all(i -> i == remaining_index || endpoint[i] == lower_components[i], 1:3) ||
        return refuse(:fixed_components_mismatch, components = endpoint)

    observe_ll(components) = begin
        ll, status = loglik_at(components)
        status == :ok && isfinite(ll) &&
            (maximum_seen[] = max(maximum_seen[], Float64(ll)))
        return Float64(ll), status
    end
    endpoint_ll, endpoint_status = observe_ll(endpoint)
    endpoint_status == :ok && isfinite(endpoint_ll) ||
        return refuse(:physical_zero_endpoint_invalid, components = endpoint,
                      endpoint_status = endpoint_status, endpoint_loglik = endpoint_ll)
    isfinite(lower_loglik) && abs(Float64(lower_loglik) - endpoint_ll) <= 1e-8 ||
        return refuse(:lower_endpoint_likelihood_mismatch, components = endpoint,
                      endpoint_loglik = endpoint_ll, lower_loglik = lower_loglik,
                      likelihood_difference = abs(Float64(lower_loglik) - endpoint_ll))

    gradient = gradient_at(endpoint; free_indices = [remaining_index])
    hasproperty(gradient, :loglik) && isfinite(gradient.loglik) &&
        (maximum_seen[] = max(maximum_seen[], Float64(gradient.loglik)))
    hasproperty(gradient, :component_gradient) ||
        return refuse(:endpoint_gradient_unavailable, components = endpoint,
                      endpoint_loglik = endpoint_ll)
    analytic = s0 * Float64(gradient.component_gradient[remaining_index])
    isfinite(analytic) && analytic > 5e-6 ||
        return refuse(:endpoint_derivative_not_positive, components = endpoint,
                      endpoint_loglik = endpoint_ll, analytic_derivative = analytic)

    q0 = -endpoint_ll / residual_df
    forward = Float64[]
    forward_logliks = Float64[]
    for h in (1e-4, 1e-5)
        one = copy(endpoint); one[remaining_index] = h * s0
        two = copy(endpoint); two[remaining_index] = 2h * s0
        ll1, status1 = observe_ll(one)
        ll2, status2 = observe_ll(two)
        status1 == :ok && status2 == :ok && isfinite(ll1) && isfinite(ll2) ||
            return refuse(:endpoint_forward_probe_invalid, components = endpoint,
                          endpoint_loglik = endpoint_ll, step = h,
                          statuses = (status1, status2))
        push!(forward_logliks, ll1, ll2)
        q1, q2 = -ll1 / residual_df, -ll2 / residual_df
        estimate = (-3q0 + 4q1 - q2) / (2h)
        isfinite(estimate) && estimate >= 0 && abs(estimate - analytic) <= 5e-6 ||
            return refuse(:endpoint_forward_derivative_unresolved,
                          components = endpoint, endpoint_loglik = endpoint_ll,
                          analytic_derivative = analytic, forward_derivatives = forward,
                          failed_forward_derivative = estimate, step = h)
        push!(forward, estimate)
    end
    abs(forward[1] - forward[2]) <= 5e-6 ||
        return refuse(:endpoint_forward_derivative_disagreement,
                      components = endpoint, endpoint_loglik = endpoint_ll,
                      analytic_derivative = analytic, forward_derivatives = forward)
    maximum_seen[] <= endpoint_ll + 1e-8 ||
        return refuse(:better_probe_likelihood, components = endpoint,
                      endpoint_loglik = endpoint_ll, analytic_derivative = analytic,
                      forward_derivatives = forward,
                      likelihood_excess = maximum_seen[] - endpoint_ll)
    return (status = :resolved_physical_zero_endpoint, components = endpoint,
            loglik = endpoint_ll, analytic_derivative = analytic,
            forward_derivatives = forward, forward_logliks = forward_logliks,
            max_valid_loglik = maximum_seen[])
end

function _arc1_scalar_profile_max(context, make_components, s0::Float64;
        physical_zero_component::Union{Nothing,Int} = nothing,
        target_component::Union{Nothing,Int} = nothing,
        held_zero_component::Union{Nothing,Int} = nothing,
        profile_loglik_at = components -> _arc1_loglik_for_components(context, components),
        profile_gradient_at = (components; free_indices) ->
            _arc1_profile_objective_gradient(context, components; free_indices))
    lo, hi = log(s0 * 2.0^-40), log(s0 * 1.0e6)
    grid = sort!(unique!(vcat([lo, hi], log.(s0 .* collect(_ARC1_START_MULTIPLIERS)))))
    values = Float64[]
    statuses = Symbol[]
    for z in grid
        ll, status = profile_loglik_at(make_components(exp(z)))
        push!(values, status == :ok ? ll : -Inf)
        push!(statuses, status)
    end
    candidates = Any[(loglik = values[i], logvalue = grid[i], converged = true,
                   status = :exact_endpoint)
                  for i in (firstindex(grid), lastindex(grid)) if isfinite(values[i])]
    unresolved_candidates = Float64[]
    observed_maximum = Ref(maximum(values; init = -Inf))
    for i in 2:(length(grid) - 1)
        values[i] >= values[i - 1] && values[i] >= values[i + 1] || continue
        observed_likelihoods = Float64[values[i - 1], values[i], values[i + 1]]
        objective(z) = begin
            ll, status = profile_loglik_at(make_components(exp(z)))
            status == :ok && push!(observed_likelihoods, ll)
            status == :ok ? -ll : Inf
        end
        search = _arc1_bounded_brent(objective, grid[i - 1], grid[i + 1];
            x_tolerance = 1e-7, likelihood_tolerance = 1e-8, max_evaluations = 2000)
        append!(observed_likelihoods, (search.max_valid_loglik,))
        observed_maximum[] = max(observed_maximum[],
                                 maximum(observed_likelihoods; init = -Inf))
        if search.result === nothing
            push!(unresolved_candidates, maximum(observed_likelihoods; init = values[i]))
            continue
        end
        result = search.result
        zhat = Optim.minimizer(result)
        ll, status = profile_loglik_at(make_components(exp(zhat)))
        ok = search.certified && status == :ok &&
             grid[i - 1] < zhat < grid[i + 1]
        push!(candidates, (loglik = ll, logvalue = zhat,
                           converged = ok, status = ok ? :brent : :unresolved,
                           bracket = search.bracket, evaluations = search.evaluations,
                           likelihood_spread = search.likelihood_spread))
        !ok && push!(unresolved_candidates, maximum(observed_likelihoods;
            init = max(values[i], isfinite(ll) ? ll : -Inf)))
    end
    zero_endpoint_certificate = (status = :not_attempted,)
    if physical_zero_component !== nothing && target_component !== nothing &&
       held_zero_component !== nothing && isfinite(values[1]) &&
       statuses[1] == :ok && !isempty(candidates)
        provisional = candidates[argmax(getproperty.(candidates, :loglik))]
        if abs(provisional.logvalue - lo) <= 1e-5
            zero_maximum = Ref(observed_maximum[])
            zero_endpoint_certificate = try
                _arc1_physical_zero_endpoint_certificate(make_components,
                    physical_zero_component, target_component, held_zero_component,
                    s0, context.residual_df, make_components(exp(lo)), values[1],
                    zero_maximum,
                    profile_loglik_at, profile_gradient_at)
            catch err
                err isa InterruptException && rethrow()
                (status = :endpoint_probe_exception, error = sprint(showerror, err),
                 max_valid_loglik = zero_maximum[])
            end
            observed_maximum[] = max(observed_maximum[], zero_maximum[],
                hasproperty(zero_endpoint_certificate, :max_valid_loglik) ?
                zero_endpoint_certificate.max_valid_loglik : -Inf)
            if zero_endpoint_certificate.status == :resolved_physical_zero_endpoint
                push!(candidates, (loglik = zero_endpoint_certificate.loglik,
                    logvalue = -Inf, converged = true, status = :physical_zero_endpoint,
                    physical_zero_endpoint = true,
                    components = zero_endpoint_certificate.components,
                    boundary_certificate = zero_endpoint_certificate))
            end
        else
            zero_endpoint_certificate = (status = :lower_endpoint_not_competitive,
                max_valid_loglik = observed_maximum[])
        end
    end
    max_valid_loglik = observed_maximum[]
    for candidate in candidates
        isfinite(candidate.loglik) && (max_valid_loglik = max(max_valid_loglik, candidate.loglik))
    end
    isempty(candidates) && return (loglik = -Inf, value = NaN, status = :nuisance_unresolved,
                                   candidates = candidates, max_valid_loglik = max_valid_loglik)
    superseded_lower_endpoint_indices = Int[]
    winner_candidates = candidates
    if zero_endpoint_certificate.status == :resolved_physical_zero_endpoint
        superseded_lower_endpoint_indices = findall(c ->
            hasproperty(c, :status) && c.status == :exact_endpoint &&
            abs(c.logvalue - lo) <= 1e-5, candidates)
        winner_candidates = [c for (i, c) in pairs(candidates)
                             if !(i in superseded_lower_endpoint_indices)]
    end
    best = winner_candidates[argmax(getproperty.(winner_candidates, :loglik))]
    is_physical_zero = hasproperty(best, :physical_zero_endpoint) &&
                       best.physical_zero_endpoint
    best_at_bound = !is_physical_zero &&
        (abs(best.logvalue - lo) <= 1e-5 || abs(best.logvalue - hi) <= 1e-5)
    competitive_unresolved = any(ll -> ll >= best.loglik - 1e-8, unresolved_candidates)
    status = competitive_unresolved || best_at_bound || !best.converged ? :nuisance_unresolved : :ok
    return (loglik = best.loglik, value = is_physical_zero ? 0.0 : exp(best.logvalue),
            status = status,
            candidates = candidates, max_valid_loglik = max_valid_loglik,
            winner_status = best.status,
            superseded_lower_endpoint_indices = superseded_lower_endpoint_indices,
            physical_zero_endpoint_certificate = zero_endpoint_certificate)
end

function _arc1_raw_nuisance(context, target::Symbol, fixed_value::Float64, s0::Float64;
        bfgs_runner = (ctx, base, free, starts, scale) ->
            _arc1_bfgs_candidate(ctx, base, free, starts, scale),
        scalar_profile_runner = (ctx, make_components, scale; kwargs...) ->
            _arc1_scalar_profile_max(ctx, make_components, scale; kwargs...),
        loglik_runner = (ctx, components) -> _arc1_loglik_for_components(ctx, components),
        gradient_runner = (ctx, components; kwargs...) ->
            _arc1_profile_objective_gradient(ctx, components; kwargs...),
        certificate_runner = (candidate, index, scale, df, faces, intersection, ll, grad) ->
            _arc1_zero_bound_face_certificate(candidate, index, scale, df,
                faces, intersection, ll, grad),
        polish_runner = (ctx, candidate, index, scale, df, faces, intersection, initial; kwargs...) ->
            _arc1_projected_face_polish(ctx, candidate, index, scale, df,
                faces, intersection, initial; kwargs...))
    target_index = findfirst(==(target),
        (:additive_variance, :permanent_environment_variance, :residual_variance))
    target_index === nothing && throw(ArgumentError("unknown raw variance target"))
    target_index == 3 && fixed_value == 0 &&
        return (loglik = -Inf, status = :singular_proposal,
                nuisance_statuses = Any[:residual_zero_boundary])

    base = zeros(3)
    base[target_index] = fixed_value
    nuisance = filter(!=(target_index), [1, 2, 3])
    candidates = Any[]
    diagnostics = Any[]

    for m1 in _ARC1_START_MULTIPLIERS, m2 in _ARC1_START_MULTIPLIERS
        candidate = bfgs_runner(context, base, nuisance, [s0 * m1, s0 * m2], s0)
        push!(candidates, candidate)
        push!(diagnostics, (kind = :positive_bfgs, converged = candidate.converged,
                            loglik = candidate.loglik, gradient_norm = candidate.gradient_norm,
                            hit_bound = candidate.hit_bound))
    end

    for zero_index in nuisance
        remaining = only(filter(!=(zero_index), nuisance))
        make_components(value) = begin
            components = copy(base)
            components[zero_index] = 0.0
            components[remaining] = value
            components
        end
        face = scalar_profile_runner(context, make_components, s0;
            physical_zero_component = remaining, target_component = target_index,
            held_zero_component = zero_index)
        values = make_components(face.value)
        face_gradient = gradient_runner(context, values;
            free_indices = filter(!=(zero_index), 1:3)).component_gradient[zero_index]
        push!(candidates, (loglik = face.loglik, max_valid_loglik = face.max_valid_loglik,
                           components = values,
                           converged = face.status == :ok,
                           gradient_norm = NaN, optimizer_status = String(face.status),
                           hit_bound = face.status == :nuisance_unresolved))
        push!(diagnostics, (kind = :exact_zero_face, zero_index = zero_index,
                            converged = face.status == :ok, loglik = face.loglik,
                            status = face.status, components = values,
                            one_sided_objective_gradient = face_gradient,
                            max_valid_loglik = face.max_valid_loglik,
                            brent_candidates = count(c -> c.status == :brent,
                                                     face.candidates),
                            winner_value = face.value,
                            physical_zero_endpoint_certificate =
                                face.physical_zero_endpoint_certificate))
    end
    intersection = copy(base)
    intersection[nuisance] .= 0.0
    ll0, status0 = loglik_runner(context, intersection)
    intersection_gradient = status0 == :ok ?
        gradient_runner(context, intersection).component_gradient : fill(NaN, 3)
    push!(candidates, (loglik = status0 == :ok ? ll0 : -Inf,
                       components = intersection, converged = status0 == :ok,
                       gradient_norm = 0.0, optimizer_status = "exact_zero_intersection",
                       hit_bound = false))
    push!(diagnostics, (kind = :exact_zero_intersection,
                        converged = status0 == :ok, loglik = ll0, status = status0,
                        components = intersection,
                        one_sided_objective_gradient = intersection_gradient))

    finite = filter(c -> isfinite(c.loglik), candidates)
    max_valid_loglik = _arc1_max_valid_profile_likelihood(candidates)
    isempty(finite) && return (loglik = -Inf, max_valid_loglik = max_valid_loglik,
                               status = :nuisance_unresolved,
                               nuisance_statuses = diagnostics)
    resolved_lower_bound = falses(length(candidates))
    resolved_candidates = Any[]
    resolution_diagnostics = Any[]
    comparison_candidates = copy(candidates)
    exact_zero_faces = [d for d in diagnostics if d.kind == :exact_zero_face]
    exact_zero_intersection = only([d for d in diagnostics
        if d.kind == :exact_zero_intersection])
    certificate_maximum = Ref(max_valid_loglik)
    for (i, candidate) in pairs(candidates)
        candidate.converged && continue
        hasproperty(candidate, :hit_bound_components) && !isempty(candidate.hit_bound_components) || continue
        candidate.hit_bound || continue
        candidate_maximum = hasproperty(candidate, :max_valid_loglik) ?
                            candidate.max_valid_loglik : candidate.loglik
        local_probe_maximum = Ref(candidate_maximum)
        loglik_at, gradient_at = _arc1_profile_probe_recorders!(local_probe_maximum,
            components -> loglik_runner(context, components),
            (components; free_indices) -> gradient_runner(
                context, components; free_indices))
        initial_certificate = nothing
        projected_face_polish = nothing
        certificate = try
            current = try
                certificate_runner(candidate, target_index, s0,
                    context.residual_df, exact_zero_faces, exact_zero_intersection,
                    loglik_at, gradient_at)
            catch err
                err isa InterruptException && rethrow()
                (status = :certificate_exception, error = sprint(showerror, err),
                 max_valid_loglik = local_probe_maximum[])
            end
            initial_certificate = current
            if current.status == :projected_gradient_unresolved
                polish = try
                    polish_runner(context,
                        merge(candidate, (; candidate_index = i)), target_index, s0,
                        context.residual_df, exact_zero_faces, exact_zero_intersection,
                        initial_certificate; maximum_seen = local_probe_maximum,
                        loglik_at = components -> _arc1_loglik_for_components(context, components),
                        gradient_at = (components; free_indices) ->
                            _arc1_profile_objective_gradient(context, components; free_indices))
                catch err
                    err isa InterruptException && rethrow()
                    (; status=:projected_face_polish_exception,
                       continuation=(; status=:projected_face_polish_exception,
                           parent_candidate_index=i, max_valid_loglik=local_probe_maximum[],
                           error=sprint(showerror, err)))
                end
                projected_face_polish = polish.continuation
                if polish.status == :resolved_projected_face_polish
                    current = merge(current, (status = :resolved_projected_face_polish,
                        polished_loglik = polish.loglik, polished_components = polish.components,
                        polished_gradient_norm = polish.continuation.continuation_gradient_norm,
                        max_valid_loglik = polish.max_valid_loglik,
                        polished_boundary_certificate = polish.boundary_certificate))
                else
                    current = merge(current, (projected_face_polish_status = polish.status,
                        projected_face_polish = polish.continuation,
                        max_valid_loglik = local_probe_maximum[]))
                end
            end
            if current.status == :resolved_lower_bound_by_zero_face &&
               abs(local_probe_maximum[] - current.face_loglik) > 1e-8
                current = merge(current, (status = :candidate_maximum_mismatch,
                    candidate_max_valid_loglik = local_probe_maximum[],
                    likelihood_spread = max(current.likelihood_spread,
                        abs(local_probe_maximum[] - current.face_loglik))))
            end
            current
        finally
            certificate_maximum[] = max(certificate_maximum[], local_probe_maximum[])
        end
        comparison_candidates[i] = merge(candidate,
            (; max_valid_loglik = local_probe_maximum[]))
        push!(resolution_diagnostics, merge((; candidate_index = i,
            original_loglik = candidate.loglik,
            original_max_valid_loglik = candidate.max_valid_loglik,
            certificate_max_valid_loglik = local_probe_maximum[],
            original_components = candidate.components,
            original_hit_bound_components = candidate.hit_bound_components,
            initial_certificate = initial_certificate,
            projected_face_polish = projected_face_polish), certificate))
        certificate.status in (:resolved_lower_bound_by_zero_face,
                               :resolved_projected_face_polish) || continue
        resolved_lower_bound[i] = true
        if certificate.status == :resolved_lower_bound_by_zero_face
            push!(resolved_candidates, merge(candidate, (; loglik = certificate.loglik,
                components = certificate.components, converged = true, hit_bound = false,
                resolved_lower_bound_by_zero_face = true,
                max_valid_loglik = local_probe_maximum[],
                boundary_certificate = certificate)))
        else
            push!(resolved_candidates, merge(candidate, (; loglik = certificate.polished_loglik,
                components = certificate.polished_components, converged = true, hit_bound = false,
                original_gradient_norm = candidate.gradient_norm,
                gradient_norm = certificate.polished_gradient_norm,
                polished_gradient_norm = certificate.polished_gradient_norm,
                resolved_lower_bound_by_zero_face = true,
                resolved_by_projected_face_polish = true,
                max_valid_loglik = local_probe_maximum[],
                boundary_certificate = certificate.polished_boundary_certificate,
                projected_face_polish = projected_face_polish)))
        end
    end
    max_valid_loglik = max(max_valid_loglik, certificate_maximum[])
    certified = Any[c for c in finite if c.converged]
    append!(certified, resolved_candidates)
    isempty(certified) && return (loglik = -Inf, max_valid_loglik = max_valid_loglik,
                                  status = :nuisance_unresolved,
                                  nuisance_statuses = merge((; raw_candidates = diagnostics),
                                      (; lower_bound_resolutions = resolution_diagnostics)))
    best = certified[argmax(getproperty.(certified, :loglik))]
    unresolved_competitor = any(i -> !resolved_lower_bound[i] &&
        _arc1_raw_competitor_is_competitive(comparison_candidates[i], best.loglik),
        eachindex(comparison_candidates))
    status = unresolved_competitor ? :nuisance_unresolved : :ok
    finite_gradients = [c.gradient_norm for c in candidates
                        if hasproperty(c, :gradient_norm) && isfinite(c.gradient_norm)]
    failure_counts = Dict{Symbol,Int}()
    failure_examples = Dict{Symbol,Vector{Any}}()
    for c in candidates
        c.converged && continue
        kind = c.hit_bound ? :bound_hit :
               (hasproperty(c, :line_search_failed) && c.line_search_failed ? :line_search_failed :
                (isfinite(c.gradient_norm) && c.gradient_norm > 1e-6 ? :gradient_check :
                 :optimizer_unconverged))
        failure_counts[kind] = get(failure_counts, kind, 0) + 1
        xs = get!(failure_examples, kind, Any[])
        length(xs) < 3 && push!(xs, (loglik = c.loglik,
            delta_from_best = c.loglik - best.loglik,
            components = c.components,
            hit_bound_components = hasproperty(c, :hit_bound_components) ?
                c.hit_bound_components : Any[],
            gradient_norm = c.gradient_norm,
            finite_difference_error = hasproperty(c, :finite_difference_error) ?
                c.finite_difference_error : NaN,
            analytic_gradient_valid = hasproperty(c, :analytic_gradient_valid) ?
                c.analytic_gradient_valid : missing,
            line_search_failed = hasproperty(c, :line_search_failed) ?
                c.line_search_failed : missing,
            optimizer_status = c.optimizer_status,
            termination_code = hasproperty(c, :termination_code) ?
                c.termination_code : missing,
            stopped_by = hasproperty(c, :stopped_by) ? c.stopped_by : missing,
            iterations = hasproperty(c, :iterations) ? c.iterations : missing))
    end
    uncertified = filter(c -> !c.converged && isfinite(c.loglik), finite)
    best_uncertified = isempty(uncertified) ? nothing : begin
        c = uncertified[argmax(getproperty.(uncertified, :loglik))]
        (loglik = c.loglik, delta_from_best = c.loglik - best.loglik,
         max_valid_loglik = hasproperty(c, :max_valid_loglik) ? c.max_valid_loglik : c.loglik,
         components = c.components,
         hit_bound_components = hasproperty(c, :hit_bound_components) ?
            c.hit_bound_components : Any[], gradient_norm = c.gradient_norm,
         finite_difference_error = hasproperty(c, :finite_difference_error) ?
            c.finite_difference_error : NaN,
         line_search_failed = hasproperty(c, :line_search_failed) ?
            c.line_search_failed : missing,
         termination_code = hasproperty(c, :termination_code) ? c.termination_code : missing,
         stopped_by = hasproperty(c, :stopped_by) ? c.stopped_by : missing)
    end
    return (loglik = best.loglik, max_valid_loglik = max_valid_loglik, status = status,
            nuisance_statuses = [(kind = :raw_nuisance_search,
                exact_zero_faces = exact_zero_faces,
                exact_zero_intersection = exact_zero_intersection,
                lower_bound_resolutions = resolution_diagnostics,
                resolved_lower_bound_by_zero_face = count(identity, resolved_lower_bound),
                resolved_by_projected_face_polish = count(c ->
                    hasproperty(c, :resolved_by_projected_face_polish) &&
                    c.resolved_by_projected_face_polish, resolved_candidates),
                best_certified = (loglik = best.loglik, components = best.components,
                    gradient_norm = best.gradient_norm,
                    original_gradient_norm = hasproperty(best, :original_gradient_norm) ?
                        best.original_gradient_norm : best.gradient_norm,
                    polished_gradient_norm = hasproperty(best, :polished_gradient_norm) ?
                        best.polished_gradient_norm : best.gradient_norm,
                    hit_bound = best.hit_bound),
                best_uncertified = best_uncertified,
                failure_counts = failure_counts, failure_examples = failure_examples,
                omitted_failures = sum(values(failure_counts); init = 0) -
                    sum(length, values(failure_examples); init = 0),
                positive_starts = length(_ARC1_START_MULTIPLIERS)^2,
                converged_starts = count(c -> c.converged, candidates),
                unconverged_starts = count(c -> !c.converged, candidates),
                bound_hits = count(c -> c.hit_bound, candidates),
                gradient_extrema = isempty(finite_gradients) ? nothing :
                    (minimum = minimum(finite_gradients), maximum = maximum(finite_gradients)),
                zero_face_starts = length(candidates) - length(_ARC1_START_MULTIPLIERS)^2,
                winner_converged = best.converged,
                winner_hit_bound = best.hit_bound,
                winner_gradient_norm = best.gradient_norm,
                unresolved_competitor = unresolved_competitor)])
end

function _arc1_ratio_nuisance(context, target::Symbol, ratio::Float64,
                              s0::Float64, diagnostic_sink = nothing)
    ratio == 1 && return (loglik = -Inf, status = :singular_proposal,
                          nuisance_statuses = Any[:ratio_one_residual_zero])
    if target === :repeatability && ratio == 0
        scale = _arc1_profile_scale(context, (0.0, 0.0, 1.0))
        ll, status = _arc1_loglik_for_components(context, [0.0, 0.0, scale])
        return (loglik = status == :ok ? ll : -Inf,
                max_valid_loglik = status == :ok ? ll : -Inf,
                status = status == :ok ? :ok : :nuisance_unresolved,
                nuisance_statuses = Any[(kind = :analytic_boundary,
                                         target = target, ratio = 0.0,
                                         allocation = :irrelevant,
                                         scale = scale, loglik = ll, status = status)])
    end
    cache = Dict{Float64,Float64}()
    failures = Any[]
    failure_counts = Dict{Symbol,Int}()
    failure_examples = Dict{Symbol,Vector{Any}}()
    function record_failure(kind::Symbol, detail = nothing)
        failure_counts[kind] = get(failure_counts, kind, 0) + 1
        examples = get!(failure_examples, kind, Any[])
        length(examples) < 3 && push!(examples, detail)
    end
    unresolved_candidates = Float64[]
    allocation_budget_exhausted = false
    allocation_gradient_extrema = (minimum = Inf, maximum = -Inf)
    function evaluate(u)
        u = Float64(u)
        haskey(cache, u) && return cache[u]
        if length(cache) >= 4097
            record_failure(:allocation_evaluation_budget, u)
            allocation_budget_exhausted = true
            return NaN
        end
        components = _arc1_components_at_ratio(target, ratio, 1.0, u)
        proportions = (components.sigma_a2, components.sigma_pe2, components.sigma_e2)
        if proportions[3] <= 0
            cache[u] = -Inf
            return -Inf
        end
        scale = try
            _arc1_profile_scale(context, proportions)
        catch err
            err isa InterruptException && rethrow()
            record_failure(:analytic_scale_unresolved, u)
            cache[u] = -Inf
            return -Inf
        end
        isfinite(scale) && scale > 0 || begin
            record_failure(:analytic_scale_unresolved, (u = u, scale = scale))
            cache[u] = -Inf
            return -Inf
        end
        scaled = _arc1_components_at_ratio(target, ratio, scale, u)
        ll, status = _arc1_loglik_for_components(context,
            [scaled.sigma_a2, scaled.sigma_pe2, scaled.sigma_e2])
        if status == :ok
            cache[u] = ll
            return ll
        end
        cache[u] = -Inf
        return -Inf
    end

    edge_knots = (2.0^-20, 2.0^-12, 2.0^-8, 1 - 2.0^-8, 1 - 2.0^-12, 1 - 2.0^-20)
    grid = sort!(unique!(vcat(collect(0.0:0.02:1.0), collect(edge_knots))))
    vals = [evaluate(u) for u in grid]
    candidates = Any[(loglik = vals[i], allocation = grid[i],
                   status = grid[i] == 0.0 || grid[i] == 1.0 ? :boundary : :grid)
                  for i in eachindex(grid) if isfinite(vals[i])]
    for i in 2:(length(grid) - 1)
        vals[i] >= vals[i - 1] && vals[i] >= vals[i + 1] || continue
        search = _arc1_bounded_brent(u -> begin
                ll = evaluate(u)
                isfinite(ll) ? -ll : Inf
            end, grid[i - 1], grid[i + 1]; x_tolerance = 1e-7,
            likelihood_tolerance = 1e-8, max_evaluations = 2000)
        if search.result === nothing
            local_best = _arc1_unresolved_brent_max(cache, search, grid[i - 1],
                grid[i + 1]; fallback = vals[i])
            record_failure(:allocation_brent_failed,
                (allocation = grid[i], bracket = (grid[i - 1], grid[i + 1]),
                 reason = search.error, best_observed_loglik = local_best,
                 evaluations = search.evaluations))
            push!(unresolved_candidates, local_best)
            continue
        end
        result = search.result
        allocation = Optim.minimizer(result)
        ll = evaluate(allocation)
        exact_global_endpoint = allocation == 0.0 || allocation == 1.0
        ok = isfinite(ll) && search.certified &&
             (grid[i - 1] < allocation < grid[i + 1] || exact_global_endpoint)
        push!(candidates, (loglik = ll, allocation = allocation,
                           status = ok ? (exact_global_endpoint ? :boundary : :brent) : :unresolved,
                           bracket = search.bracket, evaluations = search.evaluations,
                           likelihood_spread = search.likelihood_spread))
        if !ok
            local_best = _arc1_unresolved_brent_max(cache, search, grid[i - 1],
                grid[i + 1]; fallback = max(vals[i], isfinite(ll) ? ll : -Inf))
            record_failure(:allocation_brent_unresolved,
                (allocation = allocation, bracket = (grid[i - 1], grid[i + 1]),
                 converged = Optim.converged(result), loglik = ll,
                 likelihood_spread = search.likelihood_spread,
                 best_observed_loglik = local_best))
            push!(unresolved_candidates, local_best)
        end
    end
    isempty(candidates) && return (loglik = -Inf, status = :nuisance_unresolved,
                                   max_valid_loglik = maximum(values(cache); init = -Inf),
                                   nuisance_statuses = [(failures = failure_counts,
                                       examples = failure_examples, allocations = length(cache))])
    refined = filter(c -> c.status == :brent, candidates)
    # Exact boundary allocations are independent valid candidates. Interior grid
    # values establish brackets only; they cannot win the nuisance profile.
    exact_boundaries = filter(c -> c.status == :boundary, candidates)
    winners = vcat(refined, exact_boundaries)
    isempty(winners) && return (loglik = -Inf, status = :nuisance_unresolved,
                                max_valid_loglik = maximum(values(cache); init = -Inf),
                                nuisance_statuses = [(failures = failure_counts,
                                    examples = failure_examples, allocations = length(cache))])
    best = winners[argmax(getproperty.(winners, :loglik))]
    competitive_unresolved = allocation_budget_exhausted ||
        any(ll -> ll >= best.loglik - 1e-8, unresolved_candidates)
    return (loglik = best.loglik,
            max_valid_loglik = maximum(values(cache); init = best.loglik),
            status = competitive_unresolved ? :nuisance_unresolved : :ok,
            nuisance_statuses = [(kind = :allocation_search, failures = failure_counts,
                examples = failure_examples, omitted_failures = sum(values(failure_counts); init = 0) -
                    sum(length, values(failure_examples); init = 0), points = length(cache),
                best_allocation = best.allocation, winner_status = best.status,
                certified_brent_candidates = count(c -> c.status == :brent, candidates),
                gradient_extrema = nothing)])
end

function _arc1_profile_at_uncached(state::_Arc1ProfileState, target::Symbol, value::Float64)
    if target in (:heritability, :repeatability)
        result = _arc1_ratio_nuisance(state.context, target, value, state.s0,
                                      state.nuisance_statuses)
        return result
    end
    return _arc1_raw_nuisance(state.context, target, value, state.s0)
end

function _arc1_profile_at(state::_Arc1ProfileState, target::Symbol, value::Float64)
    return _arc1_profile_cache!(state, target, value)
end

function _arc1_target_grid(target::Symbol, estimate::Float64, s0::Float64)
    if target in (:heritability, :repeatability)
        base = sort!(unique!(vcat(collect(0.0:0.02:1.0), [estimate])))
        grid = Float64[first(base)]
        for i in 1:(length(base) - 1)
            a, b = base[i], base[i + 1]
            n = max(1, ceil(Int, (b - a) / 0.005))
            append!(grid, (a + (b - a) * j / n for j in 1:n))
        end
        return grid
    end

    upper = 1.0e6 * s0
    base = Float64[0.0, estimate]
    append!(base, (s0 * 2.0^(j / 2) for j in -40:8))
    filter!(x -> 0 <= x <= upper, base)
    sort!(unique!(base))
    grid = Float64[first(base)]
    for i in 1:(length(base) - 1)
        a, b = base[i], base[i + 1]
        if a == 0
            if b > 1e-6 * s0
                push!(grid, 1e-6 * s0)
                a = 1e-6 * s0
            else
                push!(grid, b)
                continue
            end
        end
        steps = max(1, ceil(Int, 8 * log2(b / a)))
        for j in 1:steps
            push!(grid, a * 2.0^(log2(b / a) * j / steps))
        end
    end
    return sort!(unique!(grid))
end

function _arc1_midpoint(a::Float64, b::Float64)
    return a == 0 ? b / 2 : sqrt(a) * sqrt(b)
end

function _arc1_midpoint(target::Symbol, a::Float64, b::Float64)
    return target in (:heritability, :repeatability) ? a / 2 + b / 2 :
           _arc1_midpoint(a, b)
end

function _arc1_interval_width(target::Symbol, a::Float64, b::Float64)
    if target in (:heritability, :repeatability) || a == 0
        return b - a
    end
    return log2(b / a)
end

function _arc1_target_search(state::_Arc1ProfileState, target::Symbol,
                             estimate::Float64;
                             profile_evaluator = x -> _arc1_profile_at(state, target, x))
    isfinite(estimate) && estimate >= 0 ||
        return (estimate = estimate, segments = Tuple{Float64,Float64}[],
                status = :nuisance_unresolved, search_status = :nuisance_unresolved,
                domain = (NaN, NaN), max_gap = NaN, refinements = 0,
                brackets = Any[], tail_screen = nothing, nuisance_statuses = Any[:invalid_estimate],
                evaluated = 0, formed = false)

    grid = _arc1_target_grid(target, estimate, state.s0)
    scores = Dict{Float64,Float64}()
    mechanisms = Dict{Symbol,Int}()
    examples = Dict{Symbol,Vector{Any}}()
    function mechanism!(kind::Symbol, value)
        mechanisms[kind] = get(mechanisms, kind, 0) + 1
        xs = get!(examples, kind, Any[])
        length(xs) < 3 && push!(xs, value)
    end
    budget_exhausted = false
    function evaluate(x::Float64)
        if !haskey(scores, x)
            profile = profile_evaluator(x)
            if profile.status == :unresolved_search_budget
                budget_exhausted = true
                mechanism!(:target_evaluation_budget, x)
                scores[x] = NaN
            elseif profile.status == :singular_proposal
                scores[x] = Inf
            elseif profile.status != :ok
                mechanism!(profile.status == :nuisance_unresolved ? :nuisance : :profile_evaluation,
                           (value = x, status = profile.status,
                            nuisance_statuses = profile.nuisance_statuses))
                scores[x] = NaN
            else
                scores[x] = 2 * (state.point_loglik - profile.loglik) -
                            _ARC1_PROFILE_CUTOFF_95
            end
        end
        return scores[x]
    end

    for x in grid
        evaluate(x)
    end
    tail_screen = nothing
    if target ∉ (:heritability, :repeatability)
        cap = 1.0e6 * state.s0
        previous_x = maximum(grid)
        previous_profile = profile_evaluator(previous_x)
        previous_ll = previous_profile.status == :ok ? previous_profile.loglik : -Inf
        consecutive = 0
        tail_points = Any[]
        while previous_x < cap && consecutive < 4 && !budget_exhausted
            x = min(2 * previous_x, cap)
            x <= previous_x && break
            score, profile = evaluate(x), profile_evaluator(x)
            ll = profile.status == :ok ? profile.loglik : -Inf
            outside = isfinite(score) && score > 0
            decreasing = ll < previous_ll
            consecutive = outside && decreasing ? consecutive + 1 : 0
            push!(tail_points, (value = x, loglik = ll, score = score,
                                outside = outside, decreasing = decreasing))
            subdivisions = max(1, ceil(Int, 8 * log2(x / previous_x)))
            for j in 1:(subdivisions - 1)
                intermediate = previous_x * 2.0^(log2(x / previous_x) * j / subdivisions)
                push!(grid, intermediate)
                evaluate(intermediate)
            end
            push!(grid, x)
            previous_x, previous_ll = x, ll
        end
        tail_screen = (points = tail_points, consecutive = consecutive,
                       cap = cap, passed = consecutive >= 4,
                       cap_reached = previous_x >= cap)
    end
    sort!(unique!(grid))

    # Ratio-only adaptive screening uses a breadth-first queue. Every evaluated
    # point remains in the final sorted grid, including when the hard cap stops
    # pending refinements.
    refinements = 0
    unresolved_refinement = false
    if target in (:heritability, :repeatability)
        initial_scores = [evaluate(x) for x in grid]
        sampled_peak_edges = Set{Tuple{Float64,Float64}}()
        for i in 2:(length(grid) - 1)
            a, b, c = initial_scores[i - 1], initial_scores[i], initial_scores[i + 1]
            if isfinite(a) && isfinite(b) && isfinite(c) && b < a && b < c
                push!(sampled_peak_edges, (grid[i - 1], grid[i]))
                push!(sampled_peak_edges, (grid[i], grid[i + 1]))
            end
        end
        pending = [(grid[i], grid[i + 1], 0,
                    (grid[i], grid[i + 1]) in sampled_peak_edges)
                   for i in 1:(length(grid) - 1)]
        refined = Set(grid)
        cursor = 1
        while cursor <= length(pending)
            a, b, depth, force_refine = pending[cursor]
            cursor += 1
            mid = _arc1_midpoint(target, a, b)
            (mid == a || mid == b) && continue
            if get(state.evaluation_counts, target, 0) >= 4097
                unresolved_refinement = true
                break
            end
            fm, fa, fb = evaluate(mid), evaluate(a), evaluate(b)
            push!(refined, mid)
            if !(all(v -> isfinite(v) || v == Inf, (fa, fm, fb)))
                continue
            end
            crossed = (fa <= 0) != (fb <= 0) || (fa <= 0) != (fm <= 0) ||
                      (fm <= 0) != (fb <= 0)
            adjacent = min(abs(fa), abs(fm), abs(fb)) <= 0.5
            curved = abs(fm - (fa + fb) / 2) > 0.05
            peak = fm < min(fa, fb) - 1e-10
            if (force_refine || crossed || adjacent || curved || peak) &&
               b - a > 0.00025 && depth < 32
                refinements += 1
                propagate_peak = force_refine || peak
                push!(pending, (a, mid, depth + 1, propagate_peak),
                                (mid, b, depth + 1, propagate_peak))
            end
        end
        unresolved_refinement |= cursor <= length(pending)
        grid = sort!(collect(refined))
    end

    scan_scores = [evaluate(x) for x in grid]
    root_tol = target in (:heritability, :repeatability) ? 1e-6 : 1e-6 * state.s0
    scan = _arc1_segments_from_scores(grid, scan_scores,
        x -> evaluate(Float64(x)); tolerance = root_tol)
    scan.status == :ok || mechanism!(:root_unresolved, scan.status)
    if any(==(:representable_limit), scan.root_terminations)
        mechanism!(:root_representable_limit, count(==(:representable_limit), scan.root_terminations))
    end
    brackets = [(left = grid[i], right = grid[i + 1],
                 score_left = scan_scores[i], score_right = scan_scores[i + 1])
                for i in 1:(length(grid) - 1)
                if isfinite(scan_scores[i]) && isfinite(scan_scores[i + 1]) &&
                   ((scan_scores[i] <= 0) != (scan_scores[i + 1] <= 0))]

    root_unresolved = any((b.right - b.left) > root_tol for b in brackets) &&
                      scan.status != :ok
    nuisance_bad = get(mechanisms, :nuisance, 0) > 0
    if target ∉ (:heritability, :repeatability)
        if grid[1] == 0.0 && length(grid) > 1 && grid[2] > 1e-6 * state.s0 + eps(state.s0)
            mechanism!(:resolution_unresolved, :zero_to_positive_gap)
        end
        positive_gaps = [log2(grid[i + 1] / grid[i]) for i in 1:length(grid)-1 if grid[i] > 0]
        maximum(positive_gaps; init = 0.0) <= 1 / 8 + 1e-10 ||
            mechanism!(:resolution_unresolved, :positive_gap)
        tail_screen.passed || mechanism!(:unbracketed_limits, tail_screen)
    end
    status = if budget_exhausted || unresolved_refinement
        :unresolved_search_budget
    elseif nuisance_bad
        :nuisance_unresolved
    elseif get(mechanisms, :root_unresolved, 0) > 0
        :root_unresolved
    elseif get(mechanisms, :resolution_unresolved, 0) > 0
        :resolution_unresolved
    elseif get(mechanisms, :unbracketed_limits, 0) > 0
        :unbracketed_limits
    elseif scan.status != :ok
        :unresolved_search
    else
        :finite_grid_resolved
    end
    formed = status == :finite_grid_resolved && !isempty(scan.segments)
    max_gap = maximum(diff(grid); init = 0.0)
    profile_records = get(state.caches, target, Dict{Float64,Any}())
    profile_status_counts = Dict{Symbol,Int}()
    profile_diagnostics = Any[]
    for (value, profile) in profile_records
        profile_status_counts[profile.status] = get(profile_status_counts, profile.status, 0) + 1
        push!(profile_diagnostics, (value = value, loglik = profile.loglik,
            status = profile.status, nuisance = profile.nuisance_statuses))
    end
    sort!(profile_diagnostics; by = x -> x.value)
    return (estimate = estimate, segments = scan.segments,
            confidence_set = formed ? scan.segments : nothing,
            status = formed ? :ok : status, search_status = status,
            domain = (first(grid), last(grid)), max_gap = max_gap,
            refinements = refinements, brackets = brackets, roots = scan.roots,
            root_terminations = scan.root_terminations, tail_screen = tail_screen,
            nuisance_statuses = [(counts = mechanisms, examples = examples,
                omitted = sum(values(mechanisms); init = 0) -
                    sum(length, values(examples); init = 0))],
            profile_status_counts = profile_status_counts,
            profile_diagnostics = profile_diagnostics,
            evaluated = get(state.evaluation_counts, target, 0), formed = formed,
            caveat = "Finite deterministic search resolution; narrower unsampled confidence-set islands are not excluded.")
end

function _arc1_point_failure_result(pointfit, target::Symbol, status::Symbol)
    estimate = pointfit === nothing ? NaN : _arc1_target_estimate(pointfit.components, target)
    return (estimate = estimate, segments = Tuple{Float64,Float64}[], confidence_set = nothing,
            status = status, search_status = status, domain = (NaN, NaN), max_gap = NaN,
            point_fit_not_optimal = false,
            refinements = 0, brackets = Any[], roots = Float64[], tail_screen = nothing,
            nuisance_statuses = Any[], profile_status_counts = Dict{Symbol,Int}(),
            profile_diagnostics = Any[], evaluated = 0, formed = false,
            caveat = "Finite deterministic search resolution; narrower unsampled confidence-set islands are not excluded.")
end

function _arc1_target_estimate(components::AbstractVector, target::Symbol)
    total = sum(components)
    target === :additive_variance && return components[1]
    target === :permanent_environment_variance && return components[2]
    target === :residual_variance && return components[3]
    target === :heritability && return components[1] / total
    target === :repeatability && return (components[1] + components[2]) / total
    throw(ArgumentError("unknown Arc1 profile target $(repr(target))"))
end

function _arc1_apply_point_fit_guard!(targets, point_loglik, max_constrained_loglik)
    _arc1_point_fit_not_optimal(point_loglik, max_constrained_loglik) || return false
    for target in _ARC1_PROFILE_TARGETS
        old = targets[target]
        targets[target] = merge(old, (confidence_set = nothing,
            status = :point_fit_not_optimal,
            search_status = :point_fit_not_optimal, formed = false))
    end
    return true
end

function _arc1_repeatability_profile_intervals(y::AbstractVector, X::AbstractMatrix,
                                              Z::AbstractMatrix, Ainv::AbstractMatrix;
                                              level::Real = 0.95,
                                              cutoff::Real = _ARC1_PROFILE_CUTOFF_95)
    level == 0.95 || throw(ArgumentError("arc1_profile_v1 supports only level=0.95"))
    cutoff == _ARC1_PROFILE_CUTOFF_95 ||
        throw(ArgumentError("arc1_profile_v1 uses the fixed chi-square cutoff 3.841458820694124"))
    context = _arc1_profile_context(y, X, Z, Ainv)
    ols_beta = qr(context.X) \ context.y
    ols_residual = context.y - context.X * ols_beta
    s0 = dot(ols_residual, ols_residual) / context.residual_df
    (isfinite(s0) && s0 > 0) || throw(ArgumentError("Arc1 OLS residual scale must be finite and positive"))

    point = _arc1_point_fit(context, s0)
    if point.fit === nothing || point.status != :ok
        targets = Dict(target => _arc1_point_failure_result(point.fit, target,
                              point.status == :ok ? :point_fit_unconverged : point.status)
                       for target in _ARC1_PROFILE_TARGETS)
        return (point_fit = point.fit, point_fit_status = point.status,
                targets = targets, cutoff = Float64(cutoff), level = Float64(level),
                s0 = s0, max_constrained_loglik = NaN,
                point_fit_not_optimal = false,
                method_version = _ARC1_PROFILE_METHOD_VERSION,
                estimand = context.estimand,
                loglik_convention = context.loglik_convention,
                loglik_full_constant_offset = context.loglik_full_constant_offset,
                loglik_comparable_across_routes = context.loglik_comparable_across_routes,
                nuisance_statuses = Dict(target =>
                    (evaluated = 0, status_counts = Dict{Symbol,Int}(),
                     refusal = targets[target].search_status)
                    for target in _ARC1_PROFILE_TARGETS))
    end

    state = _Arc1ProfileState(context, s0, point.fit.loglik,
        Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), point.fit.loglik, Any[])
    targets = Dict{Symbol,Any}()
    for target in _ARC1_PROFILE_TARGETS
        estimate = _arc1_target_estimate(point.fit.components, target)
        targets[target] = _arc1_target_search(state, target, estimate)
    end
    _arc1_apply_point_fit_guard!(targets, point.fit.loglik, state.max_constrained_loglik)
    return (point_fit = point.fit,
            point_fit_status = point.status,
            targets = targets,
            cutoff = Float64(cutoff),
            level = Float64(level),
            s0 = s0,
            max_constrained_loglik = state.max_constrained_loglik,
            point_fit_not_optimal = _arc1_point_fit_not_optimal(point.fit.loglik,
                                                                 state.max_constrained_loglik),
            method_version = _ARC1_PROFILE_METHOD_VERSION,
            estimand = context.estimand,
            loglik_convention = context.loglik_convention,
            loglik_full_constant_offset = context.loglik_full_constant_offset,
            loglik_comparable_across_routes = context.loglik_comparable_across_routes,
            nuisance_statuses = Dict(target =>
                (evaluated = targets[target].evaluated,
                 status_counts = targets[target].profile_status_counts,
                 refusal = targets[target].search_status)
                for target in _ARC1_PROFILE_TARGETS))
end

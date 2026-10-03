# Arc 1 Gaussian repeatability profiles. This file stays separate from the
# legacy delta-method `repeatability_interval`; module integration is owned by
# the coordinator after the profile contract is reviewed.

const _ARC1_PROFILE_METHOD_VERSION = :arc1_profile_v1
const _ARC1_PROFILE_METHOD_VERSIONS = (:arc1_profile_v1, :arc1_profile_v2,
    :arc1_profile_v3)
const _ARC1_PROFILE_CUTOFF_95 = 3.841458820694124

_arc1_profile_v3_finite_real(x) = x isa Real && !(x isa Bool) && isfinite(x)

function _arc1_validate_profile_method_version(method_version::Symbol)
    method_version in _ARC1_PROFILE_METHOD_VERSIONS ||
        throw(ArgumentError("unsupported Arc1 profile method version: $method_version"))
    return method_version
end

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

function _arc1_profile_fixed_ve_centering_eligible(context, target_index::Int,
                                                    fixed_ve::Real)
    target_index == 3 && fixed_ve isa Real && isfinite(fixed_ve) && fixed_ve > 0 ||
        return false
    hasproperty(context, :nobserved_animals) &&
        hasproperty(context, :transformed_design) &&
        hasproperty(context, :transformed_response) || return false
    m = context.nobserved_animals
    size(context.transformed_design, 1) == 2m || return false
    length(context.transformed_response) == 2m || return false
    return all(iszero, view(context.transformed_design, (m + 1):(2m), :))
end

function _arc1_profile_centering_constant(context, fixed_ve::Real)
    _arc1_profile_fixed_ve_centering_eligible(context, 3, fixed_ve) ||
        throw(ArgumentError("fixed-Ve centering requires an exact zero difference-design block and positive Ve"))
    m = context.nobserved_animals
    z_difference = view(context.transformed_response, (m + 1):(2m))
    return -0.5 * (m * log(Float64(fixed_ve)) + dot(z_difference, z_difference) / fixed_ve)
end

function _arc1_profile_centering_tag_matches(record, fixed_ve)
    fixed_ve isa Real && !(fixed_ve isa Bool) && isfinite(fixed_ve) && fixed_ve > 0 || return false
    hasproperty(record, :centering_ve) || return false
    tag = record.centering_ve
    return tag isa Real && !(tag isa Bool) && isfinite(tag) && tag == fixed_ve
end

function _arc1_profile_centered_value(record, field::Symbol, fixed_ve;
                                      fallback_field::Union{Nothing,Symbol} = nothing)
    _arc1_profile_centering_tag_matches(record, fixed_ve) || return nothing
    for candidate_field in (field, fallback_field)
        candidate_field === nothing && continue
        hasproperty(record, candidate_field) || continue
        value = getproperty(record, candidate_field)
        value isa Real && !(value isa Bool) && isfinite(value) &&
            return Float64(value)
    end
    return nothing
end

function _arc1_profile_finite_likelihood_maximum(values; initial = -Inf)
    best = initial isa Real && !(initial isa Bool) && isfinite(initial) ?
        Float64(initial) : -Inf
    for value in values
        value isa Real && !(value isa Bool) && isfinite(value) || continue
        best = max(best, Float64(value))
    end
    return best
end

function _arc1_profile_bound_contacts_valid(contacts)
    contacts isa AbstractVector || return false
    return all(contact -> hasproperty(contact, :component) &&
        contact.component isa Integer && contact.component in 1:3 &&
        hasproperty(contact, :side) && contact.side isa Symbol &&
        contact.side in (:lower, :upper), contacts)
end

function _arc1_profile_likelihood_history(record; centering_ve = nothing,
        additional_full = (), additional_centered = ())
    full_values = Any[additional_full...]
    for field in (:max_valid_loglik, :loglik)
        hasproperty(record, field) && push!(full_values, getproperty(record, field))
    end
    tag_valid = centering_ve !== nothing &&
        _arc1_profile_centering_tag_matches(record, centering_ve)
    centered_values = Any[additional_centered...]
    if tag_valid
        # A producer's declared maximum is evidence, not a substitute for its
        # terminal value: retain both when they are finite and correctly tagged.
        for field in (:max_valid_centered_loglik, :centered_loglik)
            centered_value = _arc1_profile_centered_value(record, field, centering_ve)
            centered_value === nothing || push!(centered_values, centered_value)
        end
    end
    return (; max_valid_loglik = _arc1_profile_finite_likelihood_maximum(full_values),
        centering_tag_valid = tag_valid,
        max_valid_centered_loglik = tag_valid ?
            _arc1_profile_finite_likelihood_maximum(centered_values) : -Inf)
end

function _arc1_profile_record_likelihood_history!(full_maximum::Base.RefValue{Float64},
        record; centered_maximum::Union{Nothing,Base.RefValue{Float64}} = nothing,
        centering_ve = nothing, additional_full = (), additional_centered = ())
    history = _arc1_profile_likelihood_history(record; centering_ve,
        additional_full, additional_centered)
    full_maximum[] = _arc1_profile_finite_likelihood_maximum(
        (full_maximum[], history.max_valid_loglik))
    if centered_maximum !== nothing && history.centering_tag_valid
        centered_maximum[] = _arc1_profile_finite_likelihood_maximum(
            (centered_maximum[], history.max_valid_centered_loglik))
    end
    return history
end

function _arc1_profile_bfgs_record_valid(record)
    required = (:loglik, :components, :converged, :gradient_norm, :hit_bound,
        :optimizer_status)
    all(field -> hasproperty(record, field), required) || return false
    loglik = record.loglik
    loglik isa Real && !(loglik isa Bool) && (isfinite(loglik) || loglik == -Inf) ||
        return false
    components = record.components
    components isa AbstractVector && length(components) == 3 &&
        all(x -> x isa Real && !(x isa Bool) && isfinite(x) && x >= 0, components) ||
        return false
    record.converged isa Bool && record.hit_bound isa Bool || return false
    record.gradient_norm isa Real && !(record.gradient_norm isa Bool) || return false
    (record.optimizer_status isa AbstractString || record.optimizer_status isa Symbol) ||
        return false
    hasproperty(record, :line_search_failed) &&
        !(record.line_search_failed isa Bool) && return false
    if hasproperty(record, :hit_bound_components)
        _arc1_profile_bound_contacts_valid(record.hit_bound_components) || return false
        record.hit_bound == !isempty(record.hit_bound_components) || return false
    elseif record.hit_bound
        return false
    end
    return true
end

function _arc1_profile_face_candidate_valid(record)
    required = (:loglik, :components, :iterations, :free_indices,
        :hit_bound_components, :converged, :hit_bound, :optimizer_converged,
        :gradient_norm, :analytic_gradient_valid, :line_search_failed,
        :finite_difference_errors)
    all(field -> hasproperty(record, field), required) || return false
    record.loglik isa Real && !(record.loglik isa Bool) && isfinite(record.loglik) ||
        return false
    record.components isa AbstractVector && length(record.components) == 3 &&
        all(x -> x isa Real && !(x isa Bool) && isfinite(x) && x >= 0,
            record.components) || return false
    record.iterations isa Integer && record.iterations >= 0 || return false
    record.free_indices isa AbstractVector && all(i -> i isa Integer && i in 1:3,
        record.free_indices) || return false
    _arc1_profile_bound_contacts_valid(record.hit_bound_components) || return false
    record.converged isa Bool && record.hit_bound isa Bool || return false
    record.optimizer_converged isa Bool && record.analytic_gradient_valid isa Bool &&
        record.line_search_failed isa Bool || return false
    record.gradient_norm isa Real && !(record.gradient_norm isa Bool) || return false
    record.finite_difference_errors isa AbstractDict || return false
    return true
end

function _arc1_profile_continuation_valid(record)
    required = (:loglik, :components, :iterations, :free_indices, :converged,
        :optimizer_converged, :gradient_norm, :analytic_gradient_valid,
        :line_search_failed, :finite_difference_errors, :hit_bound_components)
    all(field -> hasproperty(record, field), required) || return false
    record.loglik isa Real && !(record.loglik isa Bool) && isfinite(record.loglik) ||
        return false
    record.components isa AbstractVector && length(record.components) == 3 &&
        all(x -> x isa Real && !(x isa Bool) && isfinite(x) && x >= 0,
            record.components) || return false
    record.iterations isa Integer && record.iterations >= 0 || return false
    record.free_indices isa AbstractVector && all(i -> i isa Integer && i in 1:3,
        record.free_indices) || return false
    record.converged isa Bool && record.optimizer_converged isa Bool &&
        record.analytic_gradient_valid isa Bool && record.line_search_failed isa Bool ||
        return false
    record.gradient_norm isa Real && !(record.gradient_norm isa Bool) || return false
    record.finite_difference_errors isa AbstractDict &&
        _arc1_profile_bound_contacts_valid(record.hit_bound_components) || return false
    return true
end

function _arc1_profile_resolved_face_certificate_valid(record, centered_active::Bool)
    required = (:status, :zero_indices, :components, :projected_components,
        :loglik, :original_loglik, :projected_loglik, :face_loglik,
        :likelihood_spread, :centered_active, :projected_log_gradient_norm,
        :analytic_active_derivatives, :forward_derivatives)
    all(field -> hasproperty(record, field), required) || return false
    record.status == :resolved_lower_bound_by_zero_face || return false
    record.centered_active isa Bool && record.centered_active == centered_active ||
        return false
    record.zero_indices isa AbstractVector && !isempty(record.zero_indices) &&
        all(i -> i isa Integer && i in 1:3, record.zero_indices) &&
        length(unique(record.zero_indices)) == length(record.zero_indices) || return false
    for field in (:components, :projected_components)
        values = getproperty(record, field)
        values isa AbstractVector && length(values) == 3 &&
            all(x -> x isa Real && !(x isa Bool) && isfinite(x) && x >= 0, values) ||
            return false
        all(i -> values[i] == 0.0, record.zero_indices) || return false
    end
    for field in (:loglik, :original_loglik, :projected_loglik, :face_loglik,
                  :likelihood_spread, :projected_log_gradient_norm)
        value = getproperty(record, field)
        value isa Real && !(value isa Bool) && isfinite(value) || return false
    end
    record.projected_log_gradient_norm <= 1e-6 || return false
    if !centered_active
        record.likelihood_spread <= 1e-8 || return false
        abs(record.loglik - record.face_loglik) <= 1e-8 || return false
    end
    record.analytic_active_derivatives isa AbstractDict &&
        record.forward_derivatives isa AbstractDict || return false
    Set(keys(record.analytic_active_derivatives)) == Set(record.zero_indices) &&
        Set(keys(record.forward_derivatives)) == Set(record.zero_indices) || return false
    for index in record.zero_indices
        analytic = record.analytic_active_derivatives[index]
        analytic isa Real && !(analytic isa Bool) && isfinite(analytic) &&
            analytic > 5e-6 || return false
        estimates = record.forward_derivatives[index]
        estimates isa Tuple && length(estimates) == 2 &&
            all(x -> x isa Real && !(x isa Bool) && isfinite(x) && x >= 0, estimates) ||
            return false
        all(x -> abs(x - analytic) <= 5e-6, estimates) &&
            abs(estimates[1] - estimates[2]) <= 5e-6 || return false
    end
    if centered_active
        centered_required = (:candidate_centered_loglik, :projected_centered_loglik,
            :face_centered_loglik, :candidate_max_valid_centered_loglik,
            :likelihood_spread_centered)
        all(field -> hasproperty(record, field), centered_required) || return false
        all(field -> begin
                value = getproperty(record, field)
                value isa Real && !(value isa Bool) && isfinite(value)
            end, centered_required) || return false
        record.likelihood_spread_centered <= 1e-8 || return false
    end
    return true
end

function _arc1_profile_resolved_polish_certificate_valid(record, centered_active::Bool)
    required = (:status, :projected_loglik, :polished_loglik, :polished_components,
        :polished_gradient_norm, :polished_boundary_certificate)
    all(field -> hasproperty(record, field), required) || return false
    record.status == :resolved_projected_face_polish || return false
    for field in (:projected_loglik, :polished_loglik, :polished_gradient_norm)
        value = getproperty(record, field)
        value isa Real && !(value isa Bool) && isfinite(value) || return false
    end
    components = record.polished_components
    components isa AbstractVector && length(components) == 3 &&
        all(x -> x isa Real && !(x isa Bool) && isfinite(x) && x >= 0, components) ||
        return false
    if centered_active
        hasproperty(record, :projected_centered_loglik) &&
            record.projected_centered_loglik isa Real &&
            isfinite(record.projected_centered_loglik) || return false
    end
    return _arc1_profile_resolved_face_certificate_valid(
        record.polished_boundary_certificate, centered_active)
end

function _arc1_profile_v3_corner_certificate_valid(record, fixed_ve::Real)
    required = (:status, :components, :loglik, :centered_loglik,
        :centering_ve, :max_valid_loglik, :max_valid_centered_loglik,
        :original_native, :returned_native, :initial_certificate,
        :intersection, :point_scores, :centered_score_spread,
        :physical_gradient, :forward_differences, :observations, :iterations)
    all(field -> hasproperty(record, field), required) || return false
    record.status === :resolved_double_zero_corner || return false
    record.centering_ve isa Real && !(record.centering_ve isa Bool) &&
        isfinite(record.centering_ve) && record.centering_ve == fixed_ve || return false
    record.components isa AbstractVector && length(record.components) == 3 &&
        record.components == [0.0, 0.0, Float64(fixed_ve)] || return false
    intersection = record.intersection
    intersection isa NamedTuple && hasproperty(intersection, :status) &&
        intersection.status === :ok && hasproperty(intersection, :components) &&
        intersection.components == record.components &&
        hasproperty(intersection, :loglik) &&
        _arc1_profile_v3_finite_real(intersection.loglik) &&
        hasproperty(intersection, :centered_loglik) &&
        _arc1_profile_v3_finite_real(intersection.centered_loglik) &&
        _arc1_profile_centering_tag_matches(intersection, fixed_ve) || return false
    hasproperty(record, :point_scores) &&
        haskey(record.point_scores, :saved_intersection) || return false
    saved = record.point_scores[:saved_intersection]
    hasproperty(saved, :full) && saved.full == intersection.loglik &&
        hasproperty(saved, :centered) && saved.centered == intersection.centered_loglik ||
        return false
    for field in (:loglik, :centered_loglik, :max_valid_loglik,
                  :max_valid_centered_loglik, :centered_score_spread)
        _arc1_profile_v3_finite_real(getproperty(record, field)) || return false
    end
    record.centered_score_spread <= 1e-8 || return false
    record.forward_differences isa AbstractVector &&
        length(record.forward_differences) == 6 || return false
    record.observations isa AbstractVector || return false
    record.iterations isa NamedTuple &&
        all(key -> hasproperty(record.iterations, key),
            (:original, :continuation, :combined, :allowance)) || return false
    return true
end

const _ARC1_PROFILE_V3_FULL_HISTORY_FIELDS = (
    :loglik, :full, :max_valid_loglik, :original_loglik, :original_max_valid_loglik,
    :candidate_loglik, :certificate_loglik, :continuation_loglik,
    :projected_loglik, :face_loglik, :candidate_max_valid_loglik,
    :certificate_max_valid_loglik, :original_native_loglik,
    :original_native_max_valid_loglik, :returned_native_loglik,
    :returned_continuation_loglik,
    :endpoint_loglik, :lower_endpoint_loglik, :lower_loglik, :probe_loglik,
    :forward_logliks,
)
const _ARC1_PROFILE_V3_CENTERED_HISTORY_FIELDS = (
    :centered, :centered_loglik, :max_valid_centered_loglik,
    :candidate_centered_loglik, :projected_centered_loglik,
    :face_centered_loglik, :candidate_max_valid_centered_loglik,
    :original_native_centered_loglik, :original_native_max_valid_centered_loglik,
    :returned_native_centered_loglik, :returned_native_max_valid_centered_loglik,
    :continuation_centered_loglik, :certificate_centered_loglik,
    :endpoint_centered_loglik, :probe_centered_loglik,
)
const _ARC1_PROFILE_V3_NESTED_HISTORY_FIELDS = (
    :original_native, :returned_native, :returned_continuation, :continuation,
    :initial_certificate, :boundary_certificate, :physical_zero_endpoint_certificate,
    :intersection, :exact_zero_intersection, :exact_zero_faces, :faces,
    :candidates, :point_scores, :forward_differences, :points, :probes, :observations,
)

_arc1_profile_v3_has(record, field::Symbol) = record isa AbstractDict ?
    (haskey(record, field) || haskey(record, String(field))) : hasproperty(record, field)
_arc1_profile_v3_get(record, field::Symbol) = record isa AbstractDict ?
    (haskey(record, field) ? record[field] : record[String(field)]) : getproperty(record, field)

function _arc1_profile_v3_direct_score_status_valid(record)
    _arc1_profile_v3_has(record, :evaluation_valid) &&
        return _arc1_profile_v3_get(record, :evaluation_valid) === true
    _arc1_profile_v3_has(record, :status) || return true
    status = _arc1_profile_v3_get(record, :status)
    return status in (:ok, :resolved_lower_bound_by_zero_face,
        :resolved_projected_face_polish, :resolved_positive_bound_refine,
        :resolved_double_zero_corner, :resolved_physical_zero_endpoint, :boundary, :brent,
        :face_likelihood_mismatch, :projected_gradient_unresolved)
end

function _arc1_profile_v3_sink_record!(sink, target::Symbol, fixed_ve::Real)
    sink === nothing && return nothing
    sink isa Dict{Symbol,Any} || throw(ArgumentError(
        "v3_evidence_sink must be Dict{Symbol,Any}"))
    evaluations = get!(sink, :arc1_profile_v3_evaluations, Any[])
    evaluations isa AbstractVector || throw(ArgumentError(
        "v3_evidence_sink[:arc1_profile_v3_evaluations] must be a vector"))
    record = Dict{Symbol,Any}(:target => target, :fixed_value => Float64(fixed_ve),
        :status => :started, :events => Any[], :producer_history => Any[],
        :max_valid_loglik => -Inf, :max_valid_centered_loglik => -Inf,
        :provenance_failures => Any[])
    push!(evaluations, record)
    return record
end

function _arc1_profile_v3_history!(full_maximum::Base.RefValue{Float64},
        centered_maximum::Base.RefValue{Float64}, record, fixed_ve::Real;
        sink_record = nothing, path::AbstractString = "root")
    provenance_failures = Any[]
    visited = 0
    active = IdDict{Any,Nothing}()
    record_failure(item_path, field, reason; value = nothing, tag = nothing) = begin
        failure = (; path = item_path, field, reason, value, tag,
            expected_ve = Float64(fixed_ve))
        push!(provenance_failures, failure)
        sink_record === nothing || push!(sink_record[:provenance_failures], failure)
        failure
    end
    add_full(value, item_path, field) = begin
        if value isa Real && !(value isa Bool) && isfinite(value)
            full_maximum[] = max(full_maximum[], Float64(value))
            sink_record === nothing || (sink_record[:max_valid_loglik] = max(
                get(sink_record, :max_valid_loglik, -Inf), Float64(value)))
        end
        nothing
    end
    add_centered(value, tag, item_path, field) = begin
        if value isa Real && !(value isa Bool) && isfinite(value) &&
           tag isa Real && !(tag isa Bool) && isfinite(tag) && tag == fixed_ve
            centered_maximum[] = max(centered_maximum[], Float64(value))
            sink_record === nothing || (sink_record[:max_valid_centered_loglik] = max(
                get(sink_record, :max_valid_centered_loglik, -Inf), Float64(value)))
        elseif value isa Real && !(value isa Bool) && isfinite(value)
            record_failure(item_path, field, :centered_provenance_mismatch; value, tag)
        end
        nothing
    end
    function visit(item, item_path, depth)
        item === nothing && return
        if depth > 12
            record_failure(item_path, :history, :supported_depth_exceeded)
            return
        end
        tracked_container = item isa NamedTuple || item isa AbstractDict ||
            item isa AbstractVector
        if tracked_container
            if haskey(active, item)
                record_failure(item_path, :history, :cycle_detected)
                return
            end
            active[item] = nothing
        end
        if item isa NamedTuple || item isa AbstractDict
            visited += 1
            sink_record === nothing || push!(sink_record[:producer_history],
                (; path = item_path, record = item))
            if _arc1_profile_v3_has(item, :kind) && _arc1_profile_v3_has(item, :value) &&
               _arc1_profile_v3_has(item, :status)
                kind = _arc1_profile_v3_get(item, :kind)
                value = _arc1_profile_v3_get(item, :value)
                status = _arc1_profile_v3_get(item, :status)
                explicit_valid = _arc1_profile_v3_has(item, :evaluation_valid) &&
                    _arc1_profile_v3_get(item, :evaluation_valid) === true
                if status === :returned && explicit_valid && value isa Real &&
                   !(value isa Bool) && isfinite(value)
                    if kind === :full
                        add_full(value, item_path, :value)
                    elseif kind === :centered
                        tag = _arc1_profile_v3_has(item, :centering_ve) ?
                            _arc1_profile_v3_get(item, :centering_ve) : nothing
                        add_centered(value, tag, item_path, :value)
                    end
                elseif status === :returned && !explicit_valid
                    # A returned callback record is only history after its producer
                    # validated the callback's likelihood. Returned optimizer state
                    # and finite penalty values are not likelihood evidence.
                    record_failure(item_path, :value, :evaluation_validity_missing)
                end
            end
            for field in _ARC1_PROFILE_V3_FULL_HISTORY_FIELDS
                _arc1_profile_v3_has(item, field) || continue
                value = _arc1_profile_v3_get(item, field)
                declared_maximum = field in (:max_valid_loglik,
                    :original_max_valid_loglik, :candidate_max_valid_loglik,
                    :certificate_max_valid_loglik, :original_native_max_valid_loglik,
                    :returned_native_max_valid_loglik)
                producer_validity = if field === :endpoint_loglik ||
                                       (field === :loglik &&
                                        _arc1_profile_v3_has(item,
                                            :endpoint_loglik_valid))
                    _arc1_profile_v3_has(item, :endpoint_loglik_valid) &&
                        _arc1_profile_v3_get(item, :endpoint_loglik_valid) === true
                elseif field === :lower_loglik
                    _arc1_profile_v3_has(item, :lower_loglik_valid) &&
                        _arc1_profile_v3_get(item, :lower_loglik_valid) === true
                elseif field in (:forward_logliks,)
                    _arc1_profile_v3_has(item, :forward_logliks_valid) &&
                        _arc1_profile_v3_get(item, :forward_logliks_valid) === true
                else
                    _arc1_profile_v3_direct_score_status_valid(item)
                end
                (declared_maximum || producer_validity) || continue
                if field === :forward_logliks && value isa AbstractVector
                    for (index, likelihood) in pairs(value)
                        add_full(likelihood, "$item_path.$field[$index]", field)
                    end
                else
                    add_full(value, item_path, field)
                end
            end
            for field in _ARC1_PROFILE_V3_CENTERED_HISTORY_FIELDS
                _arc1_profile_v3_has(item, field) || continue
                value = _arc1_profile_v3_get(item, field)
                declared_maximum = field in (:max_valid_centered_loglik,
                    :candidate_max_valid_centered_loglik,
                    :original_native_max_valid_centered_loglik,
                    :returned_native_max_valid_centered_loglik)
                centered_validity = if field in (:centered_loglik,
                        :endpoint_centered_loglik) &&
                    _arc1_profile_v3_has(item, :endpoint_centered_loglik_valid)
                    _arc1_profile_v3_get(item, :endpoint_centered_loglik_valid) === true
                elseif _arc1_profile_v3_has(item,
                        :centered_evaluation_valid)
                    _arc1_profile_v3_get(item, :centered_evaluation_valid) === true
                else
                    _arc1_profile_v3_direct_score_status_valid(item)
                end
                centered_validity || declared_maximum || continue
                original_field = startswith(String(field), "original_native_")
                field_tag = if original_field
                    _arc1_profile_v3_has(item, :original_native_centering_ve) ?
                        _arc1_profile_v3_get(item, :original_native_centering_ve) : nothing
                else
                    _arc1_profile_v3_has(item, :centering_ve) ?
                        _arc1_profile_v3_get(item, :centering_ve) : nothing
                end
                add_centered(value, field_tag, item_path, field)
            end
            for field in _ARC1_PROFILE_V3_NESTED_HISTORY_FIELDS
                _arc1_profile_v3_has(item, field) || continue
                child = _arc1_profile_v3_get(item, field)
                if field === :point_scores && child isa AbstractDict
                    for (label, value) in pairs(child)
                        visit(value, "$item_path.$field[$(repr(label))]", depth + 1)
                    end
                    continue
                end
                if child isa AbstractVector
                    for (index, value) in pairs(child)
                        visit(value, "$item_path.$field[$index]", depth + 1)
                    end
                else
                    visit(child, "$item_path.$field", depth + 1)
                end
            end
        elseif item isa AbstractVector
            visited += 1
            for (index, value) in pairs(item)
                visit(value, "$item_path[$index]", depth + 1)
            end
        end
        tracked_container && delete!(active, item)
    end
    visit(record, String(path), 0)
    if sink_record !== nothing
        sink_record[:max_valid_loglik] = max(
            get(sink_record, :max_valid_loglik, -Inf), full_maximum[])
        sink_record[:max_valid_centered_loglik] = max(
            get(sink_record, :max_valid_centered_loglik, -Inf), centered_maximum[])
    end
    return (; max_valid_loglik = full_maximum[],
        max_valid_centered_loglik = centered_maximum[],
        provenance_failures, records_visited = visited)
end

function _arc1_profile_v2_refinement_eligible(candidate, initial_certificate,
        target_index::Int, faces)
    hasproperty(initial_certificate, :status) &&
        initial_certificate.status == :face_likelihood_mismatch || return false
    required = (:components, :converged, :optimizer_converged, :optimizer_status,
        :termination_code, :analytic_gradient_valid, :line_search_failed,
        :iterations, :free_indices, :finite_difference_errors, :hit_bound,
        :hit_bound_components)
    all(field -> hasproperty(candidate, field), required) || return false
    candidate.converged isa Bool && !candidate.converged || return false
    candidate.optimizer_converged === true || return false
    candidate.optimizer_status == "converged" || return false
    candidate.termination_code == Optim.TerminationCode.NoObjectiveChange || return false
    candidate.analytic_gradient_valid === true || return false
    candidate.line_search_failed === false || return false
    candidate.iterations isa Integer && 0 <= candidate.iterations < 2000 || return false
    candidate.hit_bound === true || return false
    contacts = candidate.hit_bound_components
    _arc1_profile_bound_contacts_valid(contacts) && length(contacts) == 1 || return false
    contact = only(contacts)
    contact.component in (1, 2) && contact.component != target_index &&
        contact.side === :lower || return false
    candidate.components isa AbstractVector && length(candidate.components) == 3 &&
        all(x -> x isa Real && !(x isa Bool) && isfinite(x) && x >= 0,
            candidate.components) || return false
    candidate.components[contact.component] > 0 || return false
    free = candidate.free_indices
    free isa AbstractVector && length(free) == 2 &&
        sort(Int.(free)) == sort(filter(!=(target_index), 1:3)) || return false
    remaining = filter(i -> i != contact.component && i != target_index, Int.(free))
    length(remaining) == 1 || return false
    errors = candidate.finite_difference_errors
    errors isa AbstractDict || return false
    contact_error = get(errors, contact.component, NaN)
    contact_error isa Real && !(contact_error isa Bool) &&
        ((isfinite(contact_error) && contact_error <= 5e-6) || contact_error == Inf) ||
        return false
    remaining_error = get(errors, only(remaining), NaN)
    remaining_error isa Real && !(remaining_error isa Bool) &&
        isfinite(remaining_error) && remaining_error <= 5e-6 || return false

    zero_indices = initial_certificate.zero_indices
    zero_indices isa AbstractVector && length(zero_indices) == 1 &&
        only(zero_indices) == contact.component || return false
    spread = get(initial_certificate, :centered_active, false) ?
        get(initial_certificate, :likelihood_spread_centered, NaN) :
        get(initial_certificate, :likelihood_spread, NaN)
    spread isa Real && !(spread isa Bool) && isfinite(spread) && spread > 1e-8 ||
        return false
    matching_faces = filter(face -> hasproperty(face, :zero_index) &&
        face.zero_index == contact.component && hasproperty(face, :status) &&
        face.status == :ok, faces)
    length(matching_faces) == 1 || return false
    face = only(matching_faces)
    hasproperty(face, :components) && face.components isa AbstractVector &&
        length(face.components) == 3 && all(x -> x isa Real && !(x isa Bool) &&
        isfinite(x) && x >= 0, face.components) || return false
    hasproperty(face, :loglik) && face.loglik isa Real &&
        !(face.loglik isa Bool) && isfinite(face.loglik) || return false
    face.components[contact.component] == 0.0 &&
        face.components[target_index] == candidate.components[target_index] || return false
    return true
end

function _arc1_profile_v3_native_lower_contact_valid(contact, components,
        component::Int, s0::Float64)
    hasproperty(contact, :component) && contact.component === component || return false
    hasproperty(contact, :side) && contact.side === :lower || return false
    hasproperty(contact, :value) && contact.value isa Real &&
        !(contact.value isa Bool) && isfinite(contact.value) && contact.value > 0 || return false
    hasproperty(contact, :log_value) && contact.log_value isa Real &&
        !(contact.log_value isa Bool) && isfinite(contact.log_value) || return false
    contact.value === components[component] || return false
    lower = log(s0 * 2.0^-40)
    abs(Float64(contact.log_value) - lower) <= 1e-5 || return false
    abs(log(Float64(contact.value)) - Float64(contact.log_value)) <= 1e-12 || return false
    return true
end

function _arc1_profile_v3_original_status(candidate, initial_certificate,
        target_index::Int, s0::Float64, faces, fixed_ve::Real)
    target_index == 3 && fixed_ve isa Real && !(fixed_ve isa Bool) &&
        isfinite(fixed_ve) && fixed_ve > 0 || return :ineligible_context
    _arc1_profile_v2_refinement_eligible(candidate, initial_certificate,
        target_index, faces) || return :original_native_record_invalid
    candidate.iterations isa Integer && !(candidate.iterations isa Bool) &&
        0 <= candidate.iterations < 2000 || return :original_iteration_count_invalid
    candidate.optimizer_status isa AbstractString &&
        candidate.optimizer_status == "converged" || return :original_native_record_invalid
    candidate.termination_code === Optim.TerminationCode.NoObjectiveChange ||
        return :original_native_record_invalid
    candidate.components isa Vector{Float64} && length(candidate.components) == 3 ||
        return :original_native_record_invalid
    candidate.free_indices isa Vector{Int} && candidate.free_indices == [1, 2] ||
        return :original_free_indices_invalid
    candidate.components[3] == fixed_ve || return :original_target_changed
    candidate.hit_bound_components isa Vector &&
        length(candidate.hit_bound_components) == 1 || return :original_contact_invalid
    contact = only(candidate.hit_bound_components)
    contact.component isa Int && contact.component in (1, 2) &&
        _arc1_profile_v3_native_lower_contact_valid(contact, candidate.components,
            contact.component, s0) || return :original_contact_geometry_invalid
    candidate.finite_difference_errors isa AbstractDict ||
        return :original_native_record_invalid
    hasproperty(candidate, :gradient_norm) &&
        _arc1_profile_v3_finite_real(candidate.gradient_norm) &&
        candidate.gradient_norm >= 0 || return :original_gradient_norm_invalid
    contact_error = get(candidate.finite_difference_errors, contact.component, NaN)
    contact_error isa Real && !(contact_error isa Bool) &&
        (contact_error == Inf || (isfinite(contact_error) &&
            0 <= contact_error <= 5e-6)) ||
        return :original_contact_fd_invalid
    remaining = only(filter(!=(contact.component), candidate.free_indices))
    remaining_error = get(candidate.finite_difference_errors, remaining, NaN)
    remaining_error isa Real && !(remaining_error isa Bool) &&
        isfinite(remaining_error) && 0 <= remaining_error <= 5e-6 ||
        return :original_remaining_fd_invalid
    hasproperty(candidate, :centering_ve) &&
        _arc1_profile_centering_tag_matches(candidate, fixed_ve) ||
        return :original_centering_tag_mismatch
    for field in (:centered_loglik, :max_valid_centered_loglik)
        hasproperty(candidate, field) &&
            _arc1_profile_v3_finite_real(getproperty(candidate, field)) ||
            return :original_centering_evidence_missing
    end
    hasproperty(initial_certificate, :centered_active) &&
        initial_certificate.status === :face_likelihood_mismatch &&
        initial_certificate.centered_active === true ||
        return :initial_certificate_invalid
    initial_certificate.zero_indices == [contact.component] ||
        return :initial_certificate_contact_mismatch
    (!hasproperty(initial_certificate, :centering_ve) ||
        _arc1_profile_centering_tag_matches(initial_certificate, fixed_ve)) ||
        return :initial_certificate_centering_tag_mismatch
    hasproperty(initial_certificate, :likelihood_spread_centered) &&
        _arc1_profile_v3_finite_real(initial_certificate.likelihood_spread_centered) &&
        initial_certificate.likelihood_spread_centered > 1e-8 ||
        return :initial_certificate_not_mismatched
    matching_faces = filter(face -> hasproperty(face, :zero_index) &&
        face.zero_index == contact.component && hasproperty(face, :status) &&
        face.status === :ok, faces)
    length(matching_faces) == 1 || return :matching_face_invalid
    face = only(matching_faces)
    hasproperty(face, :components) && face.components isa AbstractVector &&
        length(face.components) == 3 && face.components[contact.component] === 0.0 &&
        face.components[3] === Float64(fixed_ve) || return :matching_face_geometry_invalid
    _arc1_profile_centering_tag_matches(face, fixed_ve) ||
        return :matching_face_centering_tag_mismatch
    hasproperty(face, :centered_loglik) &&
        _arc1_profile_v3_finite_real(face.centered_loglik) ||
        return :matching_face_score_invalid
    return :eligible
end

function _arc1_profile_v3_native_pair_status(original, continuation,
        target_index::Int, s0::Float64, residual_df::Real,
        initial_certificate, faces, fixed_ve::Real)
    target_index == 3 && isfinite(fixed_ve) && fixed_ve > 0 &&
        isfinite(s0) && s0 > 0 && isfinite(residual_df) && residual_df > 0 ||
        return :ineligible_context
    original_status = _arc1_profile_v3_original_status(original,
        initial_certificate, target_index, s0, faces, fixed_ve)
    original_status === :eligible || return original_status
    required_original = (:centering_ve, :centered_loglik,
        :max_valid_centered_loglik)
    all(k -> hasproperty(original, k), required_original) ||
        return :original_centering_evidence_missing
    _arc1_profile_centering_tag_matches(original, fixed_ve) ||
        return :original_centering_tag_mismatch
    original.iterations isa Integer && !(original.iterations isa Bool) &&
        0 <= original.iterations < 2000 || return :original_iteration_count_invalid
    original.free_indices isa AbstractVector &&
        all(i -> i isa Integer && !(i isa Bool), original.free_indices) &&
        sort(Int.(original.free_indices)) == [1, 2] ||
        return :original_free_indices_invalid
    original.components[3] == fixed_ve || return :original_target_changed
    original.hit_bound_components isa AbstractVector &&
        length(original.hit_bound_components) == 1 ||
        return :original_contact_invalid
    first_contact = only(original.hit_bound_components)
    first_contact.component in (1, 2) || return :original_contact_invalid
    _arc1_profile_v3_native_lower_contact_valid(first_contact,
        original.components, first_contact.component, s0) ||
        return :original_contact_geometry_invalid
    initial_certificate.status === :face_likelihood_mismatch ||
        return :initial_certificate_invalid
    initial_certificate.centered_active === true ||
        return :initial_certificate_centering_inactive
    initial_certificate.zero_indices == [first_contact.component] ||
        return :initial_certificate_contact_mismatch
    (!hasproperty(initial_certificate, :centering_ve) ||
        _arc1_profile_centering_tag_matches(initial_certificate, fixed_ve)) ||
        return :initial_certificate_centering_tag_mismatch
    centered_spread = get(initial_certificate, :likelihood_spread_centered, NaN)
    centered_spread isa Real && !(centered_spread isa Bool) &&
        isfinite(centered_spread) && centered_spread > 1e-8 ||
        return :initial_certificate_not_mismatched
    matching_faces = filter(face -> hasproperty(face, :zero_index) &&
        face.zero_index == first_contact.component && hasproperty(face, :status) &&
        face.status === :ok, faces)
    length(matching_faces) == 1 || return :matching_face_invalid
    face = only(matching_faces)
    hasproperty(face, :components) && face.components isa AbstractVector &&
        length(face.components) == 3 || return :matching_face_invalid
    face.components[first_contact.component] === 0.0 &&
        face.components[3] === fixed_ve || return :matching_face_geometry_invalid
    _arc1_profile_centering_tag_matches(face, fixed_ve) ||
        return :matching_face_centering_tag_mismatch
    hasproperty(face, :centered_loglik) && _arc1_profile_v3_finite_real(face.centered_loglik) ||
        return :matching_face_score_invalid

    required = (:loglik, :max_valid_loglik, :centered_loglik,
        :max_valid_centered_loglik, :centering_ve, :components, :converged,
        :optimizer_converged, :optimizer_status, :termination_code,
        :analytic_gradient_valid, :line_search_failed, :iterations,
        :free_indices, :finite_difference_errors, :gradient_norm, :hit_bound,
        :hit_bound_components)
    all(k -> hasproperty(continuation, k), required) ||
        return :continuation_native_record_invalid
    continuation.loglik isa Real && !(continuation.loglik isa Bool) &&
        isfinite(continuation.loglik) && continuation.max_valid_loglik isa Real &&
        !(continuation.max_valid_loglik isa Bool) && isfinite(continuation.max_valid_loglik) ||
        return :continuation_native_record_invalid
    _arc1_profile_v3_finite_real(continuation.centered_loglik) &&
        _arc1_profile_v3_finite_real(continuation.max_valid_centered_loglik) ||
        return :continuation_native_record_invalid
    _arc1_profile_centering_tag_matches(continuation, fixed_ve) ||
        return :continuation_centering_tag_mismatch
    continuation.components isa AbstractVector && length(continuation.components) == 3 &&
        all(x -> _arc1_profile_v3_finite_real(x) && x >= 0, continuation.components) ||
        return :continuation_native_record_invalid
    continuation.converged === false && continuation.optimizer_converged === true &&
        continuation.optimizer_status isa AbstractString &&
        continuation.optimizer_status == "converged" &&
        continuation.termination_code === Optim.TerminationCode.GradientNorm &&
        continuation.analytic_gradient_valid === true &&
        continuation.line_search_failed === false && continuation.hit_bound === true ||
        return :continuation_native_record_invalid
    continuation.gradient_norm isa Real && !(continuation.gradient_norm isa Bool) &&
        isfinite(continuation.gradient_norm) && 0 <= continuation.gradient_norm <= 1e-6 ||
        return :continuation_native_record_invalid
    continuation.iterations isa Int &&
        0 <= continuation.iterations || return :continuation_iteration_count_invalid
    allowance = 2000 - Int(original.iterations)
    continuation.iterations <= allowance || return :combined_budget_exceeded
    original.iterations + continuation.iterations <= 2000 ||
        return :combined_budget_exceeded
    continuation.free_indices isa Vector{Int} &&
        length(continuation.free_indices) == 1 &&
        only(continuation.free_indices) isa Int ||
        return :continuation_native_record_invalid
    second_contact = only(filter(i -> i != first_contact.component, (1, 2)))
    only(continuation.free_indices) == second_contact ||
        return :continuation_free_index_invalid
    continuation.components[3] === fixed_ve || return :continuation_target_changed
    continuation.components[first_contact.component] ===
        original.components[first_contact.component] || return :held_component_changed
    continuation.components[second_contact] > 0 || return :continuation_contact_invalid
    _arc1_profile_bound_contacts_valid(continuation.hit_bound_components) &&
        length(continuation.hit_bound_components) == 1 ||
        return :continuation_native_record_invalid
    _arc1_profile_v3_native_lower_contact_valid(
        only(continuation.hit_bound_components), continuation.components,
        second_contact, s0) || return :continuation_contact_geometry_invalid
    continuation.finite_difference_errors isa AbstractDict &&
        haskey(continuation.finite_difference_errors, second_contact) &&
        continuation.finite_difference_errors[second_contact] isa Real &&
        !(continuation.finite_difference_errors[second_contact] isa Bool) &&
        continuation.finite_difference_errors[second_contact] == Inf ||
        return :continuation_contact_fd_mismatch
    original_contact_error = get(original.finite_difference_errors,
        first_contact.component, NaN)
    original_contact_error isa Real && !(original_contact_error isa Bool) &&
        ((isfinite(original_contact_error) && original_contact_error <= 5e-6) ||
         isinf(original_contact_error)) || return :original_contact_fd_invalid
    remaining_error = get(original.finite_difference_errors, second_contact, NaN)
    remaining_error isa Real && !(remaining_error isa Bool) &&
        isfinite(remaining_error) && remaining_error <= 5e-6 ||
        return :original_remaining_fd_invalid
    return :eligible
end

function _arc1_profile_v3_double_zero_corner_certificate(original, continuation,
        target_index::Int, s0::Float64, residual_df::Real, faces, intersection,
        initial_certificate, loglik_at, gradient_at, centered_loglik_at,
        fixed_ve::Real; maximum_seen::Base.RefValue{Float64},
        centered_maximum_seen::Base.RefValue{Float64}, sink_record = nothing)
    observations = sink_record === nothing ? Any[] : sink_record[:events]
    history_provenance_failures = Any[]
    record_history!(record, path) = begin
        history = _arc1_profile_v3_history!(maximum_seen,
            centered_maximum_seen, record, fixed_ve; sink_record, path)
        append!(history_provenance_failures, history.provenance_failures)
        history
    end
    record_history!(original, "original_native")
    record_history!(initial_certificate, "initial_certificate")
    record_history!(continuation, "returned_native")
    record_history!(faces, "exact_zero_faces")
    record_history!(intersection, "exact_zero_intersection")
    refuse(status; kwargs...) = begin
        if sink_record !== nothing
            get(sink_record, :status, nothing) === :interrupted ||
                (sink_record[:status] = status)
            sink_record[:max_valid_loglik] = max(
                get(sink_record, :max_valid_loglik, -Inf), maximum_seen[])
            sink_record[:max_valid_centered_loglik] = max(
                get(sink_record, :max_valid_centered_loglik, -Inf), centered_maximum_seen[])
        end
        merge((status=status,
            components=missing, max_valid_loglik=maximum_seen[],
            max_valid_centered_loglik=centered_maximum_seen[], centering_ve=Float64(fixed_ve),
            original_native=original, returned_native=continuation,
            observations=copy(observations)), (;kwargs...))
    end
    publish(status) = begin
        if sink_record !== nothing
            sink_record[:status] = status
            sink_record[:max_valid_loglik] = maximum_seen[]
            sink_record[:max_valid_centered_loglik] = centered_maximum_seen[]
            sink_record[:original_native] = original
            sink_record[:returned_native] = continuation
            sink_record[:initial_certificate] = initial_certificate
            sink_record[:intersection] = intersection
        end
    end
    native_status = _arc1_profile_v3_native_pair_status(original, continuation,
        target_index, s0, residual_df, initial_certificate, faces, fixed_ve)
    native_status === :eligible || begin
        publish(native_status)
        return refuse(native_status)
    end
    corner = [0.0, 0.0, Float64(fixed_ve)]
    intersection_geometry_valid = hasproperty(intersection, :status) && intersection.status === :ok &&
        hasproperty(intersection, :components) && intersection.components == corner
    intersection_geometry_valid || begin
        publish(:intersection_geometry_invalid)
        return refuse(:intersection_geometry_invalid, corner=corner,
            intersection=intersection)
    end
    intersection_scores_valid = hasproperty(intersection, :centered_loglik) &&
        hasproperty(intersection, :loglik) &&
        _arc1_profile_v3_finite_real(intersection.loglik) &&
        _arc1_profile_v3_finite_real(intersection.centered_loglik) &&
        _arc1_profile_centering_tag_matches(intersection, fixed_ve)
    intersection_scores_valid || begin
        publish(:intersection_evidence_invalid)
        return refuse(:intersection_evidence_invalid, corner=corner,
            intersection=intersection)
    end
    isempty(history_provenance_failures) || begin
        publish(:centered_history_provenance_unresolved)
        return refuse(:centered_history_provenance_unresolved,
            provenance_failures=copy(history_provenance_failures))
    end

    capture(label, components, kind, callback) = begin
        event = Dict{Symbol,Any}(:label=>label,:components=>copy(components),
            :centering_ve=>Float64(fixed_ve),:kind=>kind,:status=>:started,
            :value=>missing,:evaluation_valid=>false,:error=>missing)
        push!(observations,event)
        result = try
            callback()
        catch err
            event[:status]=err isa InterruptException ? :interrupted : :error
            event[:error]=sprint(showerror,err)
            sink_record === nothing || begin
                sink_record[:max_valid_loglik] = maximum_seen[]
                sink_record[:max_valid_centered_loglik] = centered_maximum_seen[]
                err isa InterruptException && (sink_record[:status] = :interrupted)
            end
            err isa InterruptException && rethrow()
            return (;event,result=missing)
        end
        event[:result]=result
        event[:status]=:returned
        return (;event,result)
    end
    full_value(label, components) = begin
        call=capture(label,components,:full,()->loglik_at(copy(components)))
        raw=call.result
        valid=raw isa Tuple && length(raw)>=2 && raw[2]===:ok &&
            raw[1] isa Real && !(raw[1] isa Bool) && isfinite(raw[1])
        if valid
            value=Float64(raw[1]); call.event[:value]=value
            call.event[:evaluation_valid]=true
            maximum_seen[]=max(maximum_seen[],value)
            sink_record === nothing || (sink_record[:max_valid_loglik] = maximum_seen[])
            return (;status=:ok,value,event=call.event)
        end
        call.event[:status]===:returned && (call.event[:status]=:invalid_return)
        (;status=:invalid,value=missing,event=call.event)
    end
    centered_value(label, components) = begin
        call=capture(label,components,:centered,()->centered_loglik_at(copy(components)))
        raw=call.result
        valid=raw !== missing && hasproperty(raw,:status) && raw.status===:ok &&
            hasproperty(raw,:loglik) && _arc1_profile_v3_finite_real(raw.loglik)
        if valid
            value=Float64(raw.loglik); call.event[:value]=value
            call.event[:evaluation_valid]=true
            centered_maximum_seen[]=max(centered_maximum_seen[],value)
            sink_record === nothing ||
                (sink_record[:max_valid_centered_loglik] = centered_maximum_seen[])
            return (;status=:ok,value,event=call.event)
        end
        call.event[:status]===:returned && (call.event[:status]=:invalid_return)
        (;status=:invalid,value=missing,event=call.event)
    end
    points=((:returned_terminal,Float64.(continuation.components)),
            (:exact_intersection,Float64.(intersection.components)),
            (:exact_corner,corner))
    scores=Dict{Symbol,Any}()
    for (label,components) in points
        full=full_value(Symbol(label,:_full),components)
        full.status===:ok || return refuse(:physical_likelihood_invalid,
            failed_point=label,point_scores=copy(scores))
        centered=centered_value(Symbol(label,:_centered),components)
        centered.status===:ok || return refuse(:physical_centered_likelihood_invalid,
            failed_point=label,point_scores=copy(scores))
        scores[label]=(;components=copy(components),full=full.value,
            centered=centered.value, centering_ve=Float64(fixed_ve),
            evaluation_valid=true, centered_evaluation_valid=true)
    end
    scores[:saved_intersection] = (;components=copy(corner),
        full=Float64(intersection.loglik), centered=Float64(intersection.centered_loglik),
        centering_ve=Float64(fixed_ve), evaluation_valid=true,
        centered_evaluation_valid=true)
    centered_values=getproperty.(collect(values(scores)),:centered)
    full_values=getproperty.(collect(values(scores)),:full)
    centered_spread=maximum(centered_values)-minimum(centered_values)
    full_spread=maximum(full_values)-minimum(full_values)
    centered_spread<=1e-8 || begin
        publish(:corner_score_spread_unresolved)
        return refuse(:corner_score_spread_unresolved,
        point_scores=scores,centered_score_spread=centered_spread,
        full_score_spread=full_spread)
    end

    corner_gradient_call=capture(:exact_corner_gradient,corner,:gradient,
        ()->gradient_at(copy(corner);free_indices=[1,2]))
    gradient=corner_gradient_call.result
    if hasproperty(gradient, :loglik) &&
       _arc1_profile_v3_finite_real(gradient.loglik)
        value = Float64(gradient.loglik)
        maximum_seen[] = max(maximum_seen[], value)
        # The gradient callback has returned an independently validated full
        # likelihood even if its derivative fields fail the certificate below.
        # Publish that likelihood evidence before any later refusal/interrupt.
        corner_gradient_call.event[:source_kind] = :gradient
        corner_gradient_call.event[:kind] = :full
        corner_gradient_call.event[:value] = value
        corner_gradient_call.event[:evaluation_valid] = true
        sink_record === nothing || (sink_record[:max_valid_loglik] = max(
            get(sink_record, :max_valid_loglik, -Inf), value))
    end
    if gradient === missing || !hasproperty(gradient,:component_gradient) ||
       !(gradient.component_gradient isa AbstractVector) || length(gradient.component_gradient)<2 ||
       !all(_arc1_profile_v3_finite_real,gradient.component_gradient[1:2])
        corner_gradient_call.event[:status]===:returned &&
            (corner_gradient_call.event[:status]=:invalid_return)
        begin
            publish(:corner_gradient_invalid)
            return refuse(:corner_gradient_invalid,point_scores=scores,
            centered_score_spread=centered_spread,full_score_spread=full_spread)
        end
    end
    analytic=Float64(s0).*Float64.(gradient.component_gradient[1:2])
    all(x->isfinite(x)&&x>5e-6,analytic) || begin
        publish(:active_derivative_not_positive)
        return refuse(
        :active_derivative_not_positive,point_scores=scores,
        centered_score_spread=centered_spread,full_score_spread=full_spread,
        physical_gradient=analytic)
    end
    corner_centered=scores[:exact_corner].centered
    directions=((1.0,0.0),(0.0,1.0),(0.5,0.5))
    probes=Any[]
    q0centered=-corner_centered/Float64(residual_df)
    q0full=-scores[:exact_corner].full/Float64(residual_df)
    for (direction_index,direction) in enumerate(directions), h in (1e-4,1e-5)
        pair=Any[]
        for multiplier in (1.0,2.0)
            components=[Float64(s0)*multiplier*h*direction[1],
                Float64(s0)*multiplier*h*direction[2],Float64(fixed_ve)]
            full=full_value(Symbol("fd$(direction_index)_$(h)_$(multiplier)_full"),components)
            full.status===:ok || begin
                publish(:forward_full_likelihood_invalid)
                return refuse(:forward_full_likelihood_invalid,
                point_scores=scores,forward_differences=probes,failed_components=components)
            end
            centered=centered_value(Symbol("fd$(direction_index)_$(h)_$(multiplier)_centered"),components)
            centered.status===:ok || begin
                publish(:forward_centered_likelihood_invalid)
                return refuse(:forward_centered_likelihood_invalid,
                point_scores=scores,forward_differences=probes,failed_components=components)
            end
            push!(pair,(;components,full=full.value,centered=centered.value,
                centering_ve=Float64(fixed_ve)))
        end
        q1c,q2c=-pair[1].centered/Float64(residual_df),-pair[2].centered/Float64(residual_df)
        q1f,q2f=-pair[1].full/Float64(residual_df),-pair[2].full/Float64(residual_df)
        estimate_centered=(-3*q0centered+4*q1c-q2c)/(2*h)
        estimate_full=(-3*q0full+4*q1f-q2f)/(2*h)
        analytic_direction=sum(analytic .* collect(direction))
        record=(;direction,direction_index,h,points=pair,
            full_estimate=estimate_full,centered_estimate=estimate_centered,
            analytic_direction,centered_absolute_error=abs(estimate_centered-analytic_direction),
            full_absolute_error=abs(estimate_full-analytic_direction),
            centered_step_pair_difference=missing)
        push!(probes,record)
        any(p->p.centered>corner_centered+1e-8,pair) && begin
            publish(:better_corner_probe_likelihood)
            return refuse(
            :better_corner_probe_likelihood,point_scores=scores,
            centered_score_spread=centered_spread,full_score_spread=full_spread,
            physical_gradient=analytic,forward_differences=probes)
        end
        estimates=filter(p->p.direction_index==direction_index,probes)
        if length(estimates)==2
            difference=abs(estimates[1].centered_estimate-estimates[2].centered_estimate)
            probes[end]=merge(probes[end],(;centered_step_pair_difference=difference))
            all(p->p.centered_estimate>=0 && isfinite(p.centered_estimate) &&
                abs(p.centered_estimate-p.analytic_direction)<=5e-6,estimates) &&
                difference<=5e-6 || begin
                    publish(:forward_derivative_unresolved)
                    return refuse(:forward_derivative_unresolved,
                    point_scores=scores,centered_score_spread=centered_spread,
                    full_score_spread=full_spread,physical_gradient=analytic,
                    forward_differences=probes)
                end
        end
    end
    publish(:resolved_double_zero_corner)
    return (status=:resolved_double_zero_corner,components=corner,
        loglik=scores[:exact_corner].full,
        centered_loglik=scores[:exact_corner].centered,
        centered_active=true,centering_ve=Float64(fixed_ve),
        max_valid_loglik=maximum_seen[],
        max_valid_centered_loglik=centered_maximum_seen[],
        original_native=original,returned_native=continuation,
        initial_certificate=initial_certificate,intersection=intersection,
        point_scores=scores,full_score_spread=full_spread,
        centered_score_spread=centered_spread,physical_gradient=analytic,
        forward_differences=probes,observations=observations,
        iterations=(original=Int(original.iterations),
            continuation=Int(continuation.iterations),
            combined=Int(original.iterations+continuation.iterations),
            allowance=2000-Int(original.iterations)))
end

function _arc1_positive_bound_refinement(context, candidate, target_index::Int,
        s0::Float64, residual_df::Real, faces, intersection, initial_certificate,
        loglik_at, gradient_at; maximum_seen::Base.RefValue{Float64},
        centered_maximum_seen::Union{Nothing,Base.RefValue{Float64}} = nothing,
        centered_loglik_at = nothing, centering_ve = nothing,
        continuation_runner = nothing)
    candidate_history = _arc1_profile_record_likelihood_history!(maximum_seen,
        candidate; centered_maximum = centered_maximum_seen, centering_ve)
    _arc1_profile_record_likelihood_history!(maximum_seen, initial_certificate;
        centered_maximum = centered_maximum_seen, centering_ve)
    centered_active = centered_loglik_at !== nothing && centered_maximum_seen !== nothing &&
        centering_ve !== nothing && candidate_history.centering_tag_valid
    report(status; kwargs...) = merge((status = status,
        parent_candidate_index = get(candidate, :candidate_index, missing),
        original_iterations = hasproperty(candidate, :iterations) ? candidate.iterations : 0,
        continuation_iterations = 0,
        combined_iterations = hasproperty(candidate, :iterations) ? candidate.iterations : 0,
        original_max_valid_loglik = candidate_history.max_valid_loglik,
        original_native_max_valid_centered_loglik = hasproperty(candidate,
            :max_valid_centered_loglik) ? candidate.max_valid_centered_loglik : missing,
        original_native_centering_ve = hasproperty(candidate, :centering_ve) ?
            candidate.centering_ve : missing,
        max_valid_loglik = maximum_seen[], initial_certificate = initial_certificate),
        centered_active ? (; max_valid_centered_loglik = centered_maximum_seen[],
            centering_ve = Float64(centering_ve)) : NamedTuple(), (; kwargs...))
    _arc1_profile_v2_refinement_eligible(candidate, initial_certificate,
        target_index, faces) || return (status = :not_eligible,
                                  continuation = report(:not_eligible))
    contact_index = only(candidate.hit_bound_components).component
    remaining = only(filter(i -> i != target_index && i != contact_index,
        Int.(candidate.free_indices)))
    allowance = 2000 - Int(candidate.iterations)
    base = copy(candidate.components)
    continuation = try
        continuation_runner === nothing ?
            _arc1_bfgs_candidate(context, base, [remaining], [base[remaining]], s0;
                max_iterations = allowance,
                centered_loglik_at = centered_active ? centered_loglik_at : nothing,
                centering_ve = centered_active ? centering_ve : nothing) :
            continuation_runner(context, base, [remaining], [base[remaining]], s0,
                allowance)
    catch err
        err isa InterruptException && rethrow()
        return (status = :continuation_exception,
            continuation = report(:continuation_exception,
                error = sprint(showerror, err), remaining_indices = [remaining],
                iteration_allowance = allowance,
                continuation_iterations = missing, combined_iterations = missing))
    end
    continuation_history = _arc1_profile_record_likelihood_history!(maximum_seen,
        continuation; centered_maximum = centered_maximum_seen, centering_ve)
    continuation_iterations = hasproperty(continuation, :iterations) &&
        continuation.iterations isa Integer && !(continuation.iterations isa Bool) &&
        continuation.iterations >= 0 ? Int(continuation.iterations) : missing
    combined_iterations = ismissing(continuation_iterations) ? missing :
        Int(candidate.iterations) + continuation_iterations
    continuation_record(status; kwargs...) = report(status;
        returned_continuation = continuation,
        starting_projection = base,
        returned_components = hasproperty(continuation, :components) ?
                              continuation.components : nothing,
        continuation_loglik = hasproperty(continuation, :loglik) ?
                              continuation.loglik : -Inf,
        continuation_gradient_norm = hasproperty(continuation, :gradient_norm) ?
                                     continuation.gradient_norm : Inf,
        termination_code = hasproperty(continuation, :termination_code) ?
                           continuation.termination_code : :missing,
        stopped_by = hasproperty(continuation, :stopped_by) ? continuation.stopped_by : nothing,
        original_iterations = Int(candidate.iterations),
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
    valid = _arc1_profile_face_candidate_valid(continuation) &&
        hasproperty(continuation, :optimizer_status) &&
        continuation.optimizer_status == "converged" &&
        hasproperty(continuation, :termination_code) &&
        continuation.free_indices == [remaining] && continuation.converged &&
        continuation.optimizer_converged && continuation.analytic_gradient_valid &&
        !continuation.line_search_failed && continuation.gradient_norm <= 1e-6 &&
        continuation.iterations <= allowance &&
        isempty(continuation.hit_bound_components) &&
        continuation.components[target_index] == candidate.components[target_index] &&
        continuation.components[contact_index] == candidate.components[contact_index] &&
        continuation.components[remaining] > 0 &&
        haskey(continuation.finite_difference_errors, remaining) &&
        isfinite(continuation.finite_difference_errors[remaining]) &&
        continuation.finite_difference_errors[remaining] <= 5e-6
    valid || return (status = :continuation_unresolved,
        continuation = continuation_record(:continuation_unresolved,
            max_valid_centered_loglik = centered_active ? centered_maximum_seen[] : NaN))

    merged_fd = merge(candidate.finite_difference_errors,
        continuation.finite_difference_errors)
    terminal = merge(candidate, continuation, (; components = copy(continuation.components),
        free_indices = [contact_index, remaining], finite_difference_errors = merged_fd,
        hit_bound = true, hit_bound_components = copy(candidate.hit_bound_components),
        max_valid_loglik = maximum_seen[], max_valid_centered_loglik =
            centered_active ? centered_maximum_seen[] : -Inf,
        centered_loglik = centered_active ? continuation.centered_loglik : -Inf,
        centering_ve = centered_active ? Float64(centering_ve) : missing))
    certificate = try
        _arc1_zero_bound_face_certificate(terminal, target_index, s0, residual_df,
            faces, intersection, loglik_at, gradient_at;
            centered_loglik_at = centered_active ? centered_loglik_at : nothing,
            centering_ve = centered_active ? centering_ve : nothing,
            maximum_seen, centered_maximum_seen = centered_active ?
                centered_maximum_seen : nothing,
            validate_projected_free_fd = true)
    catch err
        err isa InterruptException && rethrow()
        return (status = :recertification_exception,
            continuation = continuation_record(:recertification_exception,
                error = sprint(showerror, err)))
    end
    _arc1_profile_record_likelihood_history!(maximum_seen, certificate;
        centered_maximum = centered_maximum_seen, centering_ve)
    accepted = certificate.status == :resolved_lower_bound_by_zero_face &&
        _arc1_profile_resolved_face_certificate_valid(certificate, centered_active)
    accepted || return (status = certificate.status,
        continuation = continuation_record(certificate.status,
            boundary_certificate = certificate,
            max_valid_centered_loglik = centered_active ? centered_maximum_seen[] : NaN))
    result = (status = :resolved_positive_bound_refine, loglik = continuation.loglik,
        components = copy(continuation.components), max_valid_loglik = maximum_seen[],
        boundary_certificate = certificate,
        continuation = continuation_record(:resolved_positive_bound_refine,
            boundary_certificate = certificate,
            max_valid_centered_loglik = centered_active ? centered_maximum_seen[] : NaN))
    result = merge(result, (; loglik = certificate.loglik,
        components = copy(certificate.components)))
    return centered_active ? merge(result, (; centered_loglik = certificate.face_centered_loglik,
            max_valid_centered_loglik = centered_maximum_seen[],
            centering_ve = Float64(centering_ve))) : result
end

function _arc1_profile_invalid_bfgs_record(record, history; centered_active::Bool,
        fixed_ve::Real)
    normalized = (loglik = -Inf, max_valid_loglik = history.max_valid_loglik,
        components = fill(NaN, 3), converged = false, gradient_norm = NaN,
        optimizer_status = "candidate_record_invalid", hit_bound = false,
        hit_bound_components = Any[])
    centered_active || return normalized
    tag = hasproperty(record, :centering_ve) ? record.centering_ve : missing
    if history.centering_tag_valid
        return merge(normalized, (centered_loglik = -Inf,
            max_valid_centered_loglik = history.max_valid_centered_loglik,
            centering_ve = Float64(fixed_ve)))
    end
    return merge(normalized, (centered_loglik = -Inf,
        max_valid_centered_loglik = -Inf, centering_ve = tag))
end

function _arc1_profile_centered_loglik(context, components::AbstractVector)
    length(components) == 3 || throw(ArgumentError("Arc1 requires three variance components"))
    all(x -> x isa Real && isfinite(x) && x >= 0, components) ||
        return (loglik = -Inf, status = :singular_proposal)
    components[3] > 0 || return (loglik = -Inf, status = :singular_proposal)
    _arc1_profile_fixed_ve_centering_eligible(context, 3, components[3]) ||
        throw(ArgumentError("centered Arc1 likelihood requires an exact zero difference-design block"))

    try
        m = context.nobserved_animals
        v = 2components[1] .* context.animal_eigenvalues .+
            2components[2] .+ components[3]
        all(x -> isfinite(x) && x > 0, v) ||
            return (loglik = -Inf, status = :singular_proposal)
        w = 1.0 ./ v
        H = view(context.transformed_design, 1:m, :)
        z = view(context.transformed_response, 1:m)
        FM = cholesky(Symmetric(H' * (w .* H)); check = true)
        delta = FM \ (H' * (w .* z))
        residual = z - H * delta
        q = dot(residual, w .* residual)
        logdet_v_sum = sum(log, v)
        logdet_m = 2sum(log, diag(FM.L))
        loglik = -0.5 * (logdet_v_sum + logdet_m + q)
        return isfinite(loglik) ? (loglik = loglik, status = :ok) :
               (loglik = -Inf, status = :singular_proposal)
    catch err
        if err isa PosDefException || err isa SingularException ||
           err isa LinearAlgebra.LAPACKException || err isa LinearAlgebra.ZeroPivotException
            return (loglik = -Inf, status = :singular_proposal)
        end
        rethrow()
    end
end

_arc1_profile_centered_loglik_at(context, components, fixed_ve::Real) =
    components[3] == fixed_ve ? _arc1_profile_centered_loglik(context, components) :
    (loglik = -Inf, status = :fixed_ve_mismatch)

_arc1_profile_comparison_loglik(candidate, fixed_ve::Union{Nothing,Real}) =
    fixed_ve === nothing ? candidate.loglik :
    something(_arc1_profile_centered_value(candidate, :centered_loglik, fixed_ve), -Inf)

function _arc1_profile_record_maximum!(full_maximum::Base.RefValue{Float64},
        centered_maximum::Union{Nothing,Base.RefValue{Float64}}, full::Real,
        centered::Union{Nothing,Real})
    isfinite(full) && (full_maximum[] = max(full_maximum[], Float64(full)))
    if centered_maximum !== nothing && centered !== nothing && isfinite(centered)
        centered_maximum[] = max(centered_maximum[], Float64(centered))
    end
    return full_maximum[]
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
    method_version::Symbol
end

_Arc1ProfileState(context, s0, point_loglik, caches, evaluation_counts,
    max_constrained_loglik, nuisance_statuses) = _Arc1ProfileState(context,
    s0, point_loglik, caches, evaluation_counts, max_constrained_loglik,
    nuisance_statuses, _ARC1_PROFILE_METHOD_VERSION)

_arc1_point_fit_not_optimal(point_loglik::Real, constrained_loglik::Real) =
    constrained_loglik > point_loglik + 1e-7

function _arc1_include_valid_profile_max!(state::_Arc1ProfileState, profile)
    evaluated_max = _arc1_profile_likelihood_history(profile).max_valid_loglik
    isfinite(evaluated_max) &&
        (state.max_constrained_loglik = max(state.max_constrained_loglik, evaluated_max))
    return state.max_constrained_loglik
end

function _arc1_profile_probe_recorders!(maximum_seen::Base.RefValue{Float64},
        loglik_at, gradient_at;
        centered_maximum_seen::Union{Nothing,Base.RefValue{Float64}} = nothing,
        centered_loglik_at = nothing, centering_ve::Union{Nothing,Real} = nothing)
    record!(value) = begin
        isfinite(value) && (maximum_seen[] = max(maximum_seen[], Float64(value)))
        value
    end
    recorded_loglik_at = components -> begin
        result = loglik_at(components)
        if result isa Tuple && length(result) >= 2 && result[2] == :ok
            record!(result[1])
            if centered_maximum_seen !== nothing && centered_loglik_at !== nothing &&
               centering_ve !== nothing && length(components) >= 3 &&
               components[3] == centering_ve
                centered, status = centered_loglik_at(components)
                status == :ok && isfinite(centered) &&
                    (centered_maximum_seen[] = max(centered_maximum_seen[], Float64(centered)))
            end
        end
        result
    end
    recorded_gradient_at = (components; free_indices) -> begin
        result = gradient_at(components; free_indices)
        hasproperty(result, :loglik) && record!(result.loglik)
        if centered_maximum_seen !== nothing && centered_loglik_at !== nothing &&
           centering_ve !== nothing && length(components) >= 3 &&
           components[3] == centering_ve && hasproperty(result, :loglik) &&
           isfinite(result.loglik)
            centered, status = centered_loglik_at(components)
            status == :ok && isfinite(centered) &&
                (centered_maximum_seen[] = max(centered_maximum_seen[], Float64(centered)))
        end
        result
    end
    return recorded_loglik_at, recorded_gradient_at
end

function _arc1_raw_competitor_is_competitive(candidate, best_loglik::Real;
                                             centering_ve::Union{Nothing,Real} = nothing)
    candidate.converged && centering_ve === nothing && return false
    evaluated = _arc1_profile_likelihood_history(candidate).max_valid_loglik
    if centering_ve !== nothing
        history = _arc1_profile_likelihood_history(candidate;
            centering_ve = centering_ve)
        history.centering_tag_valid || return false
        evaluated = history.max_valid_centered_loglik
    end
    return evaluated > best_loglik + 1e-8 ||
           (!candidate.converged && candidate.hit_bound && evaluated >= best_loglik - 1e-8)
end

function _arc1_zero_bound_face_certificate(candidate, target_index::Int, s0::Float64,
        residual_df::Real, faces, intersection, loglik_at, gradient_at;
        historical_likelihoods::AbstractVector{<:Real} = Float64[],
        centered_loglik_at = nothing, centering_ve::Union{Nothing,Real} = nothing,
        historical_centered_likelihoods::AbstractVector{<:Real} = Float64[],
        maximum_seen::Union{Nothing,Base.RefValue{Float64}} = nothing,
        centered_maximum_seen::Union{Nothing,Base.RefValue{Float64}} = nothing,
        validate_projected_free_fd::Bool = false)
    candidate_history = _arc1_profile_likelihood_history(candidate;
        centering_ve = centering_ve)
    if maximum_seen !== nothing
        _arc1_profile_record_likelihood_history!(maximum_seen, candidate;
            centered_maximum = centered_maximum_seen, centering_ve)
    end
    candidate_schema_valid = hasproperty(candidate, :loglik) &&
        candidate.loglik isa Real && !(candidate.loglik isa Bool) &&
        isfinite(candidate.loglik) && hasproperty(candidate, :components) &&
        candidate.components isa AbstractVector && length(candidate.components) == 3 &&
        all(x -> x isa Real && !(x isa Bool) && isfinite(x) && x >= 0,
            candidate.components) && hasproperty(candidate, :optimizer_converged) &&
        candidate.optimizer_converged isa Bool &&
        hasproperty(candidate, :analytic_gradient_valid) &&
        candidate.analytic_gradient_valid isa Bool &&
        hasproperty(candidate, :line_search_failed) &&
        candidate.line_search_failed isa Bool && hasproperty(candidate, :free_indices) &&
        candidate.free_indices isa AbstractVector &&
        all(i -> i isa Integer && i in 1:3, candidate.free_indices) &&
        (!hasproperty(candidate, :hit_bound_components) ||
         _arc1_profile_bound_contacts_valid(candidate.hit_bound_components))
    candidate_schema_valid || return (status = :candidate_record_invalid,
        max_valid_loglik = candidate_history.max_valid_loglik,
        max_valid_centered_loglik = candidate_history.max_valid_centered_loglik)
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

    centered_requested = centered_loglik_at !== nothing && centering_ve !== nothing &&
        target_index == 3 && isfinite(centering_ve) && centering_ve > 0
    if centered_requested
        candidate_tag_valid = _arc1_profile_centering_tag_matches(candidate, centering_ve)
        candidate_tag_valid || return (status = :centering_tag_mismatch_candidate,
            zero_indices = zero_indices, expected_centering_ve = Float64(centering_ve),
            observed_centering_ve = hasproperty(candidate, :centering_ve) ?
                candidate.centering_ve : missing)
        face_tag_valid = _arc1_profile_centering_tag_matches(face, centering_ve)
        face_tag_valid || return (status = :centering_tag_mismatch_face,
            zero_indices = zero_indices, expected_centering_ve = Float64(centering_ve),
            observed_centering_ve = hasproperty(face, :centering_ve) ?
                face.centering_ve : missing)
    end

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
    centered_active = centered_requested &&
        _arc1_profile_centering_tag_matches(candidate, centering_ve) &&
        candidate.components[3] == centering_ve && projected[3] == centering_ve &&
        face.components[3] == centering_ve
    original_centered = centered_active ?
        _arc1_profile_centered_value(candidate, :centered_loglik, centering_ve) : nothing
    face_centered = centered_active ?
        _arc1_profile_centered_value(face, :centered_loglik, centering_ve) : nothing
    face_centered === nothing && centered_active && return (
        status = :centered_score_invalid_face, zero_indices = zero_indices,
        expected_centering_ve = Float64(centering_ve))
    original_centered_ll = original_centered === nothing ? NaN : original_centered
    face_centered_ll = face_centered === nothing ? NaN : face_centered
    projected_centered_ll, centered_spread = NaN, NaN
    if centered_active
        projected_centered, projected_centered_status = centered_loglik_at(projected)
        projected_centered_status == :ok && isfinite(projected_centered) ||
            return (status = :nonfinite_centered_face_likelihood,
                    zero_indices = zero_indices, likelihood_spread = likelihood_spread)
        projected_centered_ll = Float64(projected_centered)
        if !isfinite(original_centered_ll)
            original_centered, original_centered_status = centered_loglik_at(candidate.components)
            original_centered_status == :ok && isfinite(original_centered) ||
                return (status = :nonfinite_centered_candidate_likelihood,
                        zero_indices = zero_indices, likelihood_spread = likelihood_spread)
            original_centered_ll = Float64(original_centered)
        end
        if !isfinite(face_centered_ll)
            face_centered, face_centered_status = centered_loglik_at(face.components)
            face_centered_status == :ok && isfinite(face_centered) ||
                return (status = :nonfinite_centered_face_likelihood,
                        zero_indices = zero_indices, likelihood_spread = likelihood_spread)
            face_centered_ll = Float64(face_centered)
        end
        centered_values = Float64[original_centered_ll, projected_centered_ll, face_centered_ll]
        append!(centered_values, Float64.(historical_centered_likelihoods))
        centered_spread = maximum(centered_values) - minimum(centered_values)
    end
    likelihood_gate_spread = centered_active ? centered_spread : likelihood_spread
    likelihood_gate_spread <= 1e-8 ||
        return (status = :face_likelihood_mismatch, zero_indices = zero_indices,
                likelihood_spread = likelihood_spread,
                centered_active = centered_active,
                likelihood_spread_centered = centered_spread)
    candidate_maximum = _arc1_profile_likelihood_history(candidate).max_valid_loglik
    candidate_centered_maximum = centered_active ? something(
        _arc1_profile_centered_value(candidate, :max_valid_centered_loglik,
            centering_ve; fallback_field = :centered_loglik), original_centered_ll) :
        original_centered_ll
    candidate_face_difference = centered_active ?
        candidate_centered_maximum - face_centered_ll : candidate_maximum - face.loglik
    abs(candidate_face_difference) <= 1e-8 ||
        return (status = :candidate_maximum_mismatch, zero_indices = zero_indices,
                original_loglik = original_ll, projected_loglik = projected_ll,
                face_loglik = face.loglik, candidate_max_valid_loglik = candidate_maximum,
                likelihood_spread = likelihood_spread,
                centered_active = centered_active,
                candidate_max_valid_centered_loglik = candidate_centered_maximum,
                face_centered_loglik = face_centered_ll,
                likelihood_spread_centered = centered_spread)

    free_indices = filter(i -> i != target_index && !(i in zero_indices), 1:3)
    grad = gradient_at(projected; free_indices)
    projected_gradient_norm = maximum(abs, grad.log_gradient; init = 0.0)
    isfinite(projected_gradient_norm) && projected_gradient_norm <= 1e-6 ||
        return (status = :projected_gradient_unresolved, zero_indices = zero_indices,
                original_loglik = original_ll, projected_loglik = projected_ll,
                face_loglik = face.loglik, likelihood_spread = likelihood_spread,
                centered_active = centered_active,
                candidate_centered_loglik = original_centered_ll,
                projected_centered_loglik = projected_centered_ll,
                face_centered_loglik = face_centered_ll,
                candidate_max_valid_centered_loglik = candidate_centered_maximum,
                likelihood_spread_centered = centered_spread,
                projected_gradient_norm = projected_gradient_norm)

    analytic_active = Dict{Int,Float64}()
    forward_active = Dict{Int,NTuple{2,Float64}}()
    q_at(components) = begin
        if centered_active
            # The derivative probes also contribute to both historical maxima.
            # Record the full likelihood through the caller's recorder, then
            # evaluate the centered expression directly at the same point.
            full, full_status = loglik_at(components)
            full_status == :ok && isfinite(full) && maximum_seen !== nothing &&
                (maximum_seen[] = max(maximum_seen[], Float64(full)))
            ll, status = centered_loglik_at(components)
            status == :ok && isfinite(ll) && centered_maximum_seen !== nothing &&
                (centered_maximum_seen[] = max(centered_maximum_seen[], Float64(ll)))
        else
            ll, status = loglik_at(components)
        end
        status == :ok && isfinite(ll) ? -ll / residual_df : NaN
    end
    q0 = q_at(projected)
    isfinite(q0) || return (status = :active_derivative_nonfinite,
                            zero_indices = zero_indices)
    projected_remaining_fd_errors = Dict{Int,Float64}()
    if validate_projected_free_fd
        for (j, index) in pairs(free_indices)
            eta = log(projected[index])
            step = 1e-5 * max(1.0, abs(eta))
            plus, minus = copy(projected), copy(projected)
            plus[index] *= exp(step)
            minus[index] *= exp(-step)
            qplus, qminus = q_at(plus), q_at(minus)
            finite_difference = isfinite(qplus) && isfinite(qminus) ?
                (qplus - qminus) / (2step) : Inf
            analytic = grad.log_gradient[j]
            error = isfinite(finite_difference) && isfinite(analytic) ?
                abs(finite_difference - analytic) : Inf
            projected_remaining_fd_errors[index] = error
            isfinite(error) && error <= 5e-6 ||
                return (status = :remaining_finite_difference_unresolved,
                    zero_indices = zero_indices,
                    projected_remaining_finite_difference_errors =
                        copy(projected_remaining_fd_errors),
                    projected_remaining_finite_difference = finite_difference,
                    projected_remaining_analytic = analytic, step)
        end
    end
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
                        forward_derivative = fd, step = h,
                        centered_active = centered_active,
                        likelihood_spread = likelihood_spread,
                        likelihood_spread_centered = centered_spread)
            push!(estimates, fd)
        end
        abs(estimates[1] - estimates[2]) <= 5e-6 ||
            return (status = :forward_derivative_disagreement,
                    zero_indices = zero_indices,
                    analytic_active_derivatives = analytic_active,
                    forward_derivatives = estimates,
                    centered_active = centered_active,
                    likelihood_spread = likelihood_spread,
                    likelihood_spread_centered = centered_spread)
        forward_active[index] = (estimates[1], estimates[2])
    end
    return (status = :resolved_lower_bound_by_zero_face,
            zero_indices = zero_indices, components = copy(face.components),
            loglik = face.loglik, projected_components = projected,
            original_loglik = original_ll, projected_loglik = projected_ll,
            face_loglik = face.loglik, likelihood_spread = likelihood_spread,
            centered_active = centered_active,
            candidate_centered_loglik = original_centered_ll,
            projected_centered_loglik = projected_centered_ll,
            face_centered_loglik = face_centered_ll,
            candidate_max_valid_centered_loglik = candidate_centered_maximum,
            likelihood_spread_centered = centered_spread,
            projected_log_gradient_norm = projected_gradient_norm,
            projected_remaining_finite_difference_errors =
                projected_remaining_fd_errors,
            analytic_active_derivatives = analytic_active,
            forward_derivatives = forward_active)
end

function _arc1_projected_face_polish(context, candidate, target_index::Int,
        s0::Float64, residual_df::Real, faces, intersection, initial_certificate;
        maximum_seen::Base.RefValue{Float64} = Ref(
            _arc1_profile_likelihood_history(candidate).max_valid_loglik),
        centered_maximum_seen::Union{Nothing,Base.RefValue{Float64}} = nothing,
        centered_loglik_at = nothing,
        centering_ve::Union{Nothing,Real} = nothing,
        loglik_at = components -> _arc1_loglik_for_components(context, components),
        gradient_at = (components; free_indices) ->
            _arc1_profile_objective_gradient(context, components; free_indices),
        continuation_runner = nothing)
    candidate_history = _arc1_profile_record_likelihood_history!(maximum_seen,
        candidate; centered_maximum = centered_maximum_seen,
        centering_ve = centering_ve)
    certificate_history = _arc1_profile_record_likelihood_history!(maximum_seen,
        initial_certificate; centered_maximum = centered_maximum_seen,
        centering_ve = centering_ve)
    candidate_schema_valid = _arc1_profile_face_candidate_valid(candidate)
    centered_requested = centered_loglik_at !== nothing && centered_maximum_seen !== nothing &&
        centering_ve !== nothing && target_index == 3 && isfinite(centering_ve) &&
        centering_ve > 0 && _arc1_profile_fixed_ve_centering_eligible(
            context, 3, centering_ve)
    centered_candidate_components_valid = hasproperty(candidate, :components) &&
        candidate.components isa AbstractVector && length(candidate.components) == 3 &&
        candidate.components[3] == centering_ve
    centered_candidate_tag_valid = centered_requested &&
        candidate_history.centering_tag_valid
    centered_candidate_score = centered_candidate_tag_valid ?
        _arc1_profile_centered_value(candidate, :centered_loglik, centering_ve) : nothing
    centered_active = centered_candidate_tag_valid && centered_candidate_score !== nothing &&
        centered_candidate_components_valid
    contacts_valid = hasproperty(candidate, :hit_bound_components) &&
        _arc1_profile_bound_contacts_valid(candidate.hit_bound_components)
    contacts = contacts_valid ? candidate.hit_bound_components : Any[]
    zero_indices = contacts_valid ? sort!(unique!(Int[c.component for c in contacts])) : Int[]
    centered_history_available = centered_requested && centered_maximum_seen !== nothing &&
        (candidate_history.centering_tag_valid || certificate_history.centering_tag_valid ||
         isfinite(centered_maximum_seen[]))
    record(status; kwargs...) = merge((status = status,
        parent_candidate_index = get(candidate, :candidate_index, missing),
        original_iterations = hasproperty(candidate, :iterations) ? candidate.iterations : 0,
        continuation_iterations = 0,
        combined_iterations = hasproperty(candidate, :iterations) ? candidate.iterations : 0,
        objective_evaluations = 0, gradient_evaluations = 0,
        max_valid_loglik = maximum_seen[], initial_certificate = initial_certificate),
        centered_history_available ? (; max_valid_centered_loglik = centered_maximum_seen[],
                             centering_ve = Float64(centering_ve)) : NamedTuple(),
        (; kwargs...))
    if centered_requested && !_arc1_profile_centering_tag_matches(candidate, centering_ve)
        return (status = :candidate_centering_tag_mismatch,
            continuation = record(:candidate_centering_tag_mismatch,
                expected_centering_ve = Float64(centering_ve),
                observed_centering_ve = hasproperty(candidate, :centering_ve) ?
                    candidate.centering_ve : missing))
    elseif !contacts_valid || !candidate_schema_valid
        return (status = :candidate_record_invalid,
            continuation = record(:candidate_record_invalid))
    elseif centered_requested && centered_candidate_score === nothing
        return (status = :candidate_centered_score_invalid,
            continuation = record(:candidate_centered_score_invalid,
                observed_centering_ve = candidate.centering_ve))
    end
    hasproperty(initial_certificate, :status) &&
    initial_certificate.status isa Symbol ||
        return (status = :initial_certificate_record_invalid,
            continuation = record(:initial_certificate_record_invalid))
    initial_certificate.status == :projected_gradient_unresolved ||
        return (status = :not_eligible, continuation = record(:not_eligible))
    certificate_required = centered_candidate_tag_valid ?
        (:projected_loglik, :projected_centered_loglik) : (:projected_loglik,)
    certificate_values_valid = all(field -> hasproperty(initial_certificate, field) &&
        getproperty(initial_certificate, field) isa Real &&
        !(getproperty(initial_certificate, field) isa Bool) &&
        isfinite(getproperty(initial_certificate, field)), certificate_required)
    certificate_values_valid || return (
        status = :initial_certificate_record_invalid,
        continuation = record(:initial_certificate_record_invalid))
    (contacts_valid && candidate_schema_valid) || return (status = :candidate_record_invalid,
        continuation = record(:candidate_record_invalid,
            max_valid_centered_loglik = centered_history_available ?
                centered_maximum_seen[] : candidate_history.max_valid_centered_loglik))
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
        if continuation_runner === nothing
            _arc1_bfgs_candidate(context, projected, remaining, projected[remaining], s0;
                max_iterations = allowance,
                centered_loglik_at = centered_active ? centered_loglik_at : nothing,
                centering_ve = centered_active ? centering_ve : nothing)
        else
            continuation_runner(context, projected, remaining, projected[remaining], s0, allowance)
        end
    catch err
        err isa InterruptException && rethrow()
        return (status = :continuation_exception,
            continuation = record(:continuation_exception,
                error = sprint(showerror, err), starting_projection = projected,
                remaining_indices = remaining, iteration_allowance = allowance))
    end
    continuation_history = _arc1_profile_record_likelihood_history!(maximum_seen,
        continuation; centered_maximum = centered_active ? centered_maximum_seen : nothing,
        centering_ve = centered_active ? centering_ve : nothing)
    continuation_centered_score = nothing
    continuation_centered_maximum = centered_active ?
        continuation_history.max_valid_centered_loglik : -Inf
    if centered_active
        if !continuation_history.centering_tag_valid
            return (status = :continuation_centering_tag_mismatch,
                continuation = record(:continuation_centering_tag_mismatch,
                    observed_centering_ve = hasproperty(continuation, :centering_ve) ?
                        continuation.centering_ve : missing))
        end
        continuation_centered_score = _arc1_profile_centered_value(
            continuation, :centered_loglik, centering_ve)
        continuation_centered_score === nothing && return (
            status = :continuation_centered_score_invalid,
            continuation = record(:continuation_centered_score_invalid,
                observed_centering_ve = continuation.centering_ve))
    end
    _arc1_profile_continuation_valid(continuation) || return (
        status = :continuation_record_invalid,
        continuation = record(:continuation_record_invalid,
            max_valid_centered_loglik = centered_active ?
                centered_maximum_seen[] : continuation_history.max_valid_centered_loglik))
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
        finite_difference_errors = merged_fd),
        centered_active ? (; centered_loglik = continuation_centered_score,
                             max_valid_centered_loglik = centered_maximum_seen[],
                             centering_ve = Float64(centering_ve)) : NamedTuple())
    probe_ll, probe_gradient = _arc1_profile_probe_recorders!(maximum_seen,
        loglik_at, gradient_at;
        centered_maximum_seen = centered_active ? centered_maximum_seen : nothing,
        centered_loglik_at = centered_active ? centered_loglik_at : nothing,
        centering_ve = centered_active ? centering_ve : nothing)
    certificate = try
        _arc1_zero_bound_face_certificate(polished_candidate, target_index, s0,
            residual_df, faces, intersection, probe_ll, probe_gradient;
            historical_likelihoods = [initial_certificate.projected_loglik,
                                      continuation.loglik],
            centered_loglik_at = centered_active ? centered_loglik_at : nothing,
            centering_ve = centered_active ? centering_ve : nothing,
            historical_centered_likelihoods = centered_active ?
                [initial_certificate.projected_centered_loglik,
                 continuation.centered_loglik] : Float64[],
            maximum_seen = maximum_seen,
            centered_maximum_seen = centered_active ? centered_maximum_seen : nothing)
    catch err
        err isa InterruptException && rethrow()
        (status = :polished_certificate_exception, error = sprint(showerror, err))
    end
    if certificate.status == :resolved_lower_bound_by_zero_face &&
       (centered_active ? centered_maximum_seen[] >
          certificate.face_centered_loglik + 1e-8 :
          maximum_seen[] > certificate.face_loglik + 1e-8)
        certificate = merge(certificate, (status = :better_probe_likelihood,
            candidate_max_valid_loglik = maximum_seen[]))
    end
    if certificate.status != :resolved_lower_bound_by_zero_face
        return (status = certificate.status,
            continuation = continuation_record(certificate.status,
                finite_difference_errors = continuation.finite_difference_errors,
                boundary_certificate = certificate))
    end
    result = (status = :resolved_projected_face_polish,
        loglik = continuation.loglik, components = copy(continuation.components),
        max_valid_loglik = maximum_seen[],
        boundary_certificate = certificate,
        continuation = continuation_record(:resolved_projected_face_polish,
            finite_difference_errors = continuation.finite_difference_errors,
            boundary_certificate = certificate))
    return centered_active ? merge(result, (centered_loglik = continuation_centered_score,
        max_valid_centered_loglik = centered_maximum_seen[],
        centering_ve = Float64(centering_ve))) : result
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

function _arc1_profile_cache!(state::_Arc1ProfileState, target::Symbol, value::Float64;
        v3_evidence_sink = nothing)
    cache = get!(state.caches, target, Dict{Float64,Any}())
    if haskey(cache, value)
        return cache[value]
    end
    count = get(state.evaluation_counts, target, 0)
    if count >= 4097
        return (loglik = -Inf, status = :unresolved_search_budget,
                nuisance_statuses = Any[:target_evaluation_budget],
                method_version = state.method_version)
    end
    state.evaluation_counts[target] = count + 1
    result = _arc1_profile_at_uncached(state, target, value; v3_evidence_sink)
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
                              optimizer_runner = nothing, max_iterations::Int = 2000,
                              centered_loglik_at = nothing,
                              centering_ve::Union{Nothing,Real} = nothing)
    lo, hi = log(s0 * 2.0^-40), log(s0 * 1.0e6)
    gradient_valid = Ref(false)
    max_valid_loglik = Ref(-Inf)
    max_valid_centered_loglik = Ref(-Inf)
    objective_evaluations = Ref(0)
    gradient_evaluations = Ref(0)
    centered_active = centered_loglik_at !== nothing && centering_ve !== nothing &&
        _arc1_profile_fixed_ve_centering_eligible(context, 3, centering_ve) &&
        Float64(centering_ve) == Float64(base_components[3]) &&
        !(3 in free_indices)
    function compared_loglik(values, full_loglik)
        centered_active || return full_loglik
        centered, status = centered_loglik_at(values)
        if status == :ok && isfinite(centered) && values[3] == centering_ve
            max_valid_centered_loglik[] = max(max_valid_centered_loglik[], Float64(centered))
            return Float64(centered)
        end
        return -Inf
    end
    objective(z) = begin
        objective_evaluations[] += 1
        all(isfinite, z) || return Inf
        values = copy(base_components)
        for (j, index) in pairs(free_indices)
            z[j] < lo || z[j] > hi ? (return Inf) : nothing
            values[index] = exp(z[j])
        end
        ll, status = _arc1_loglik_for_components(context, values)
        status == :ok && isfinite(ll) || return Inf
        max_valid_loglik[] = max(max_valid_loglik[], ll)
        objective_ll = compared_loglik(values, ll)
        isfinite(objective_ll) ? -objective_ll / context.residual_df : Inf
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
        if centered_active && isfinite(gradresult.loglik)
            compared_loglik(values, gradresult.loglik)
        end
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
    optimizer_result = try
        optimizer_runner === nothing ?
            Optim.optimize(objective, gradient!, start, Optim.BFGS(),
                           _arc1_bfgs_options(max_iterations)) :
            optimizer_runner(objective, gradient!, start)
    catch err
        if err isa InterruptException
            rethrow()
        end
        failed = (loglik = -Inf, max_valid_loglik = max_valid_loglik[],
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
        return centered_active ? merge(failed, (max_valid_centered_loglik =
            max_valid_centered_loglik[], centering_ve = Float64(centering_ve))) : failed
    end
    try
    zhat = Optim.minimizer(optimizer_result)
    values = copy(base_components)
    for (j, index) in pairs(free_indices)
        values[index] = exp(zhat[j])
    end
    ll, status = _arc1_loglik_for_components(context, values)
    status == :ok && isfinite(ll) &&
        (max_valid_loglik[] = max(max_valid_loglik[], ll))
    centered_ll = if centered_active && status == :ok && isfinite(ll)
        candidate_ll = compared_loglik(values, ll)
        isfinite(candidate_ll) ? candidate_ll : -Inf
    else
        NaN
    end
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
    ls_failed = hasproperty(optimizer_result, :stopped_by) &&
                hasproperty(optimizer_result.stopped_by, :ls_failed) &&
                optimizer_result.stopped_by.ls_failed === true
    optimizer_converged = Optim.converged(optimizer_result)
    converged = status == :ok && isfinite(ll) && isfinite(objective(zhat)) &&
                optimizer_converged && gradient_valid[] && all(isfinite, gradient) &&
                all(isfinite, finite_difference_by_coordinate) && fd_error <= 5e-6 &&
                all(z -> isfinite(z) && lo <= z <= hi, zhat) &&
                gradient_norm <= 1e-6 && !hit_bound && !ls_failed
    result = (loglik = status == :ok ? ll : -Inf, max_valid_loglik = max_valid_loglik[],
            components = values, free_indices = copy(free_indices),
            converged = converged, gradient_norm = gradient_norm,
            finite_difference_gradient = finite_difference,
            finite_difference_error = fd_error,
            finite_difference_errors = finite_difference_errors,
            analytic_gradient_valid = gradient_valid[],
            line_search_failed = ls_failed,
            optimizer_converged = optimizer_converged,
            termination_code = optimizer_result.termination_code,
            stopped_by = optimizer_result.stopped_by,
            iterations = optimizer_result.iterations,
            hit_bound_components = hit_bound_components,
            optimizer_status = ls_failed ? "line_search_failed" :
                               (Optim.converged(optimizer_result) ? "converged" : "not_converged"),
            hit_bound = hit_bound,
            objective_evaluations = objective_evaluations[],
            gradient_evaluations = gradient_evaluations[])
    return centered_active ? merge(result, (centered_loglik = centered_ll,
        max_valid_centered_loglik = max_valid_centered_loglik[],
        centering_ve = Float64(centering_ve))) : result
    catch err
        err isa InterruptException && rethrow()
        optimizer_converged = try
            Optim.converged(optimizer_result)
        catch
            false
        end
        failed = (loglik = -Inf, max_valid_loglik = max_valid_loglik[],
            components = copy(base_components), free_indices = copy(free_indices),
            converged = false, gradient_norm = Inf,
            optimizer_status = sprint(showerror, err), hit_bound = false,
            finite_difference_error = Inf, analytic_gradient_valid = false,
            line_search_failed = false, optimizer_converged = optimizer_converged,
            termination_code = hasproperty(optimizer_result, :termination_code) ?
                optimizer_result.termination_code : :postrun_exception,
            stopped_by = hasproperty(optimizer_result, :stopped_by) ?
                optimizer_result.stopped_by : nothing,
            iterations = hasproperty(optimizer_result, :iterations) ?
                optimizer_result.iterations : 0,
            hit_bound_components = Any[],
            objective_evaluations = objective_evaluations[],
            gradient_evaluations = gradient_evaluations[])
        return centered_active ? merge(failed, (
            max_valid_centered_loglik = max_valid_centered_loglik[],
            centering_ve = Float64(centering_ve))) : failed
    end
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
    _arc1_profile_likelihood_history(candidate).max_valid_loglik
    for candidate in candidates); init = -Inf)

function _arc1_physical_zero_endpoint_certificate(make_components,
        remaining_index::Int, target_index::Int, face_zero_index::Int,
        s0::Float64, residual_df::Real, lower_components::AbstractVector,
        lower_loglik::Real, maximum_seen::Base.RefValue{Float64}, loglik_at,
        gradient_at; centered_loglik_at = nothing,
        centering_ve::Union{Nothing,Real} = nothing,
        lower_centered_loglik::Union{Nothing,Real} = nothing,
        centered_maximum_seen::Union{Nothing,Base.RefValue{Float64}} = nothing)
    endpoint_full_score = Ref{Union{Nothing,Float64}}(nothing)
    endpoint_centered_score = Ref{Union{Nothing,Float64}}(nothing)
    centered_active = false
    current_centering_tag = Ref{Union{Nothing,Float64}}(nothing)
    refuse(status; kwargs...) = merge((status = status,
        max_valid_loglik = maximum_seen[],
        endpoint_loglik = endpoint_full_score[] === nothing ?
            get(kwargs, :endpoint_loglik, NaN) : endpoint_full_score[],
        endpoint_loglik_valid = endpoint_full_score[] !== nothing ||
            (haskey(kwargs, :endpoint_loglik) &&
             _arc1_profile_v3_finite_real(get(kwargs, :endpoint_loglik, NaN)) &&
             get(kwargs, :endpoint_status, :ok) === :ok),
        endpoint_centered_loglik = endpoint_centered_score[] === nothing ? NaN :
            endpoint_centered_score[],
        endpoint_centered_loglik_valid = endpoint_centered_score[] !== nothing,
        centering_ve = current_centering_tag[] === nothing ? NaN :
            current_centering_tag[],
        lower_loglik_valid = _arc1_profile_v3_finite_real(lower_loglik),
        forward_logliks_valid = haskey(kwargs, :forward_logliks)), (; kwargs...))
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

    centered_active = centered_loglik_at !== nothing && centering_ve !== nothing &&
        centered_maximum_seen !== nothing && lower_centered_loglik !== nothing &&
        endpoint[3] == centering_ve && lower_components[3] == centering_ve
    current_centering_tag[] = centered_active ? Float64(centering_ve) : nothing

    observe_ll(components) = begin
        ll, status = loglik_at(components)
        status == :ok && isfinite(ll) &&
            (maximum_seen[] = max(maximum_seen[], Float64(ll)))
        centered = NaN
        if centered_active && status == :ok && isfinite(ll) && components[3] == centering_ve
            centered_value, centered_status = centered_loglik_at(components)
            if centered_status == :ok && isfinite(centered_value)
                centered = Float64(centered_value)
                centered_maximum_seen[] = max(centered_maximum_seen[], centered)
            else
                return Float64(ll), :centered_likelihood_unresolved, centered
            end
        end
        return Float64(ll), status, centered
    end
    endpoint_ll, endpoint_status, endpoint_centered_ll = observe_ll(endpoint)
    if _arc1_profile_v3_finite_real(endpoint_ll) &&
       endpoint_status in (:ok, :centered_likelihood_unresolved)
        endpoint_full_score[] = Float64(endpoint_ll)
    end
    if centered_active && _arc1_profile_v3_finite_real(endpoint_centered_ll)
        endpoint_centered_score[] = Float64(endpoint_centered_ll)
    end
    endpoint_status == :ok && isfinite(endpoint_ll) ||
        return refuse(:physical_zero_endpoint_invalid, components = endpoint,
                      endpoint_status = endpoint_status, endpoint_loglik = endpoint_ll)
    lower_difference = centered_active ?
        abs(Float64(lower_centered_loglik) - endpoint_centered_ll) :
        abs(Float64(lower_loglik) - endpoint_ll)
    isfinite(lower_loglik) && lower_difference <= 1e-8 ||
        return refuse(:lower_endpoint_likelihood_mismatch, components = endpoint,
                      endpoint_loglik = endpoint_ll, lower_loglik = lower_loglik,
                      likelihood_difference = abs(Float64(lower_loglik) - endpoint_ll),
                      centered_likelihood_difference = centered_active ? lower_difference : NaN)

    gradient = gradient_at(endpoint; free_indices = [remaining_index])
    hasproperty(gradient, :loglik) && isfinite(gradient.loglik) &&
        (maximum_seen[] = max(maximum_seen[], Float64(gradient.loglik)))
    if centered_active && hasproperty(gradient, :loglik) && isfinite(gradient.loglik)
        centered_gradient_value, centered_gradient_status = centered_loglik_at(endpoint)
        centered_gradient_status == :ok && isfinite(centered_gradient_value) &&
            (centered_maximum_seen[] = max(centered_maximum_seen[],
                                            Float64(centered_gradient_value)))
    end
    hasproperty(gradient, :component_gradient) ||
        return refuse(:endpoint_gradient_unavailable, components = endpoint,
                      endpoint_loglik = endpoint_ll)
    analytic = s0 * Float64(gradient.component_gradient[remaining_index])
    isfinite(analytic) && analytic > 5e-6 ||
        return refuse(:endpoint_derivative_not_positive, components = endpoint,
                      endpoint_loglik = endpoint_ll, analytic_derivative = analytic)

    q0 = -(centered_active ? endpoint_centered_ll : endpoint_ll) / residual_df
    forward = Float64[]
    forward_logliks = Float64[]
    for h in (1e-4, 1e-5)
        one = copy(endpoint); one[remaining_index] = h * s0
        two = copy(endpoint); two[remaining_index] = 2h * s0
        ll1, status1, centered1 = observe_ll(one)
        ll2, status2, centered2 = observe_ll(two)
        status1 == :ok && status2 == :ok && isfinite(ll1) && isfinite(ll2) ||
            return refuse(:endpoint_forward_probe_invalid, components = endpoint,
                          endpoint_loglik = endpoint_ll, step = h,
                          statuses = (status1, status2))
        push!(forward_logliks, ll1, ll2)
        q1, q2 = -(centered_active ? centered1 : ll1) / residual_df,
                 -(centered_active ? centered2 : ll2) / residual_df
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
    maximum_gate = centered_active ? centered_maximum_seen[] : maximum_seen[]
    endpoint_gate = centered_active ? endpoint_centered_ll : endpoint_ll
    maximum_gate <= endpoint_gate + 1e-8 ||
        return refuse(:better_probe_likelihood, components = endpoint,
                      endpoint_loglik = endpoint_ll, analytic_derivative = analytic,
                      forward_derivatives = forward,
                      likelihood_excess = maximum_seen[] - endpoint_ll,
                      centered_likelihood_excess = centered_active ?
                          maximum_gate - endpoint_gate : NaN)
    return (status = :resolved_physical_zero_endpoint, components = endpoint,
            loglik = endpoint_ll, analytic_derivative = analytic,
            forward_derivatives = forward, forward_logliks = forward_logliks,
            endpoint_loglik_valid = true, lower_loglik_valid = true,
            forward_logliks_valid = true,
            max_valid_loglik = maximum_seen[],
            endpoint_centered_loglik = endpoint_centered_score[] === nothing ? NaN :
                endpoint_centered_score[],
            endpoint_centered_loglik_valid = endpoint_centered_score[] !== nothing,
            centered_active = centered_active,
            centered_loglik = centered_active ? endpoint_centered_ll : NaN,
            max_valid_centered_loglik = centered_active ? centered_maximum_seen[] : NaN,
            centering_ve = centered_active ? Float64(centering_ve) : NaN)
end

function _arc1_scalar_profile_max(context, make_components, s0::Float64;
        physical_zero_component::Union{Nothing,Int} = nothing,
        target_component::Union{Nothing,Int} = nothing,
        held_zero_component::Union{Nothing,Int} = nothing,
        profile_loglik_at = components -> _arc1_loglik_for_components(context, components),
        profile_gradient_at = (components; free_indices) ->
            _arc1_profile_objective_gradient(context, components; free_indices),
        centered_loglik_at = nothing,
        centering_ve::Union{Nothing,Real} = nothing)
    lo, hi = log(s0 * 2.0^-40), log(s0 * 1.0e6)
    grid = sort!(unique!(vcat([lo, hi], log.(s0 .* collect(_ARC1_START_MULTIPLIERS)))))
    centered_active = centered_loglik_at !== nothing && centering_ve !== nothing &&
        _arc1_profile_fixed_ve_centering_eligible(context, 3, centering_ve)
    maximum_full = Ref(-Inf)
    maximum_centered = Ref(-Inf)
    callback_error = Ref{Union{Nothing,String}}(nothing)
    callback_failure_result() = merge((loglik = -Inf, value = NaN,
        status = :nuisance_unresolved, candidates = Any[], max_valid_loglik = maximum_full[],
        winner_status = :scalar_callback_exception,
        physical_zero_endpoint_certificate = (status = :not_attempted,),
        error = callback_error[]), centered_active ?
        (centered_active = true, centered_loglik = -Inf,
         max_valid_centered_loglik = maximum_centered[],
         centering_ve = Float64(centering_ve)) : NamedTuple())
    evaluate(components) = begin
        callback_error[] === nothing ||
            return (full = -Inf, comparison = -Inf, centered = NaN,
                    status = :callback_exception, full_valid = false,
                    centered_valid = false)
        full, status = try
            profile_loglik_at(components)
        catch err
            err isa InterruptException && rethrow()
            callback_error[] = sprint(showerror, err)
            return (full = -Inf, comparison = -Inf, centered = NaN,
                    status = :callback_exception, full_valid = false,
                    centered_valid = false)
        end
        if status != :ok || !isfinite(full)
            return (full = Float64(full), comparison = -Inf, centered = NaN,
                    status = status, full_valid = false, centered_valid = false)
        end
        maximum_full[] = max(maximum_full[], Float64(full))
        if centered_active
            if components[3] != centering_ve
                return (full = Float64(full), comparison = -Inf, centered = NaN,
                        status = :fixed_ve_mismatch, full_valid = true,
                        centered_valid = false)
            end
            centered, centered_status = try
                centered_loglik_at(components)
            catch err
                err isa InterruptException && rethrow()
                callback_error[] = sprint(showerror, err)
                return (full = Float64(full), comparison = -Inf, centered = NaN,
                        status = :callback_exception, full_valid = true,
                        centered_valid = false)
            end
            centered_status == :ok && isfinite(centered) ||
                return (full = Float64(full), comparison = -Inf, centered = NaN,
                        status = :centered_likelihood_unresolved,
                        full_valid = true, centered_valid = false)
            maximum_centered[] = max(maximum_centered[], Float64(centered))
            return (full = Float64(full), comparison = Float64(centered),
                    centered = Float64(centered), status = :ok,
                    full_valid = true, centered_valid = true)
        end
        return (full = Float64(full), comparison = Float64(full), centered = NaN,
                status = :ok, full_valid = true, centered_valid = false)
    end
    comparison_values = Float64[]
    full_values = Float64[]
    centered_values = Float64[]
    statuses = Symbol[]
    for z in grid
        value = evaluate(make_components(exp(z)))
        callback_error[] === nothing || return callback_failure_result()
        push!(full_values, value.status == :ok ? value.full : -Inf)
        push!(comparison_values, value.status == :ok ? value.comparison : -Inf)
        push!(centered_values, value.status == :ok ? value.centered : -Inf)
        push!(statuses, value.status)
    end
    make_candidate(full, compared, z; kwargs...) = centered_active ?
        merge((loglik = Float64(full), comparison_loglik = Float64(compared),
               centered_loglik = Float64(compared), centering_ve = Float64(centering_ve),
               logvalue = Float64(z)), (; kwargs...)) :
        merge((loglik = Float64(full), logvalue = Float64(z)), (; kwargs...))
    candidates = Any[make_candidate(full_values[i], comparison_values[i], grid[i];
        converged = true, status = :exact_endpoint,
        evaluation_valid = true, centered_evaluation_valid = centered_active)
        for i in (firstindex(grid), lastindex(grid)) if isfinite(comparison_values[i])]
    unresolved_candidates = Float64[]
    observed_maximum = Ref(maximum(full_values; init = -Inf))
    observed_centered_maximum = Ref(maximum(centered_values; init = -Inf))
    for i in 2:(length(grid) - 1)
        comparison_values[i] >= comparison_values[i - 1] &&
            comparison_values[i] >= comparison_values[i + 1] || continue
        observed_likelihoods = Float64[comparison_values[i - 1], comparison_values[i],
                                       comparison_values[i + 1]]
        objective(z) = begin
            value = evaluate(make_components(exp(z)))
            value.status == :ok && push!(observed_likelihoods, value.comparison)
            value.status == :ok ? -value.comparison : Inf
        end
        search = _arc1_bounded_brent(objective, grid[i - 1], grid[i + 1];
            x_tolerance = 1e-7, likelihood_tolerance = 1e-8, max_evaluations = 2000)
        callback_error[] === nothing || return callback_failure_result()
        append!(observed_likelihoods, (search.max_valid_loglik,))
        observed_maximum[] = maximum_full[]
        observed_centered_maximum[] = maximum_centered[]
        if search.result === nothing
            push!(unresolved_candidates, maximum(observed_likelihoods;
                                                  init = comparison_values[i]))
            continue
        end
        result = search.result
        zhat = Optim.minimizer(result)
        value = evaluate(make_components(exp(zhat)))
        ok = search.certified && value.status == :ok &&
             grid[i - 1] < zhat < grid[i + 1]
        push!(candidates, make_candidate(value.full, value.comparison, zhat;
                           converged = ok, status = ok ? :brent : :unresolved,
                           evaluation_valid = value.full_valid,
                           centered_evaluation_valid = value.centered_valid,
                           bracket = search.bracket, evaluations = search.evaluations,
                           likelihood_spread = search.likelihood_spread))
        !ok && push!(unresolved_candidates, maximum(observed_likelihoods;
            init = max(comparison_values[i], isfinite(value.comparison) ? value.comparison : -Inf)))
    end
    zero_endpoint_certificate = (status = :not_attempted,)
    if physical_zero_component !== nothing && target_component !== nothing &&
       held_zero_component !== nothing && isfinite(full_values[1]) &&
       statuses[1] == :ok && !isempty(candidates)
        provisional = candidates[argmax([_arc1_profile_comparison_loglik(c,
            centered_active ? centering_ve : nothing) for c in candidates])]
        if abs(provisional.logvalue - lo) <= 1e-5
            zero_maximum = Ref(maximum_full[])
            zero_centered_maximum = centered_active ? Ref(maximum_centered[]) : nothing
            zero_endpoint_certificate = try
                _arc1_physical_zero_endpoint_certificate(make_components,
                    physical_zero_component, target_component, held_zero_component,
                    s0, context.residual_df, make_components(exp(lo)), full_values[1],
                    zero_maximum, profile_loglik_at, profile_gradient_at;
                    centered_loglik_at = centered_active ? centered_loglik_at : nothing,
                    centering_ve = centered_active ? centering_ve : nothing,
                    lower_centered_loglik = centered_active ? centered_values[1] : nothing,
                    centered_maximum_seen = zero_centered_maximum)
            catch err
                err isa InterruptException && rethrow()
                (status = :endpoint_probe_exception, error = sprint(showerror, err),
                 max_valid_loglik = zero_maximum[])
            end
            observed_maximum[] = maximum_full[] = max(maximum_full[], zero_maximum[],
                hasproperty(zero_endpoint_certificate, :max_valid_loglik) ?
                zero_endpoint_certificate.max_valid_loglik : -Inf)
            if centered_active
                observed_centered_maximum[] = maximum_centered[] = max(maximum_centered[],
                    zero_centered_maximum[],
                    hasproperty(zero_endpoint_certificate, :max_valid_centered_loglik) ?
                    zero_endpoint_certificate.max_valid_centered_loglik : -Inf)
            end
            if zero_endpoint_certificate.status == :resolved_physical_zero_endpoint
                push!(candidates, make_candidate(zero_endpoint_certificate.loglik,
                    centered_active ? zero_endpoint_certificate.centered_loglik :
                                      zero_endpoint_certificate.loglik,
                    -Inf; converged = true, status = :physical_zero_endpoint,
                    evaluation_valid = true,
                    centered_evaluation_valid = centered_active,
                    physical_zero_endpoint = true,
                    components = zero_endpoint_certificate.components,
                    boundary_certificate = zero_endpoint_certificate))
            end
        else
            zero_endpoint_certificate = merge((status = :lower_endpoint_not_competitive,
                max_valid_loglik = maximum_full[]), centered_active ?
                (centered_active = true, max_valid_centered_loglik = maximum_centered[],
                 centering_ve = Float64(centering_ve)) : NamedTuple())
        end
    end
    max_valid_loglik = maximum_full[]
    for candidate in candidates
        isfinite(candidate.loglik) && (max_valid_loglik = max(max_valid_loglik, candidate.loglik))
    end
    isempty(candidates) && return merge((loglik = -Inf, value = NaN, status = :nuisance_unresolved,
        candidates = candidates, max_valid_loglik = max_valid_loglik),
        centered_active ? (centered_active = true,
            max_valid_centered_loglik = maximum_centered[],
            centering_ve = Float64(centering_ve)) : NamedTuple(),
        centered_active ? (centered_loglik = -Inf,) : NamedTuple())
    superseded_lower_endpoint_indices = Int[]
    winner_candidates = candidates
    if zero_endpoint_certificate.status == :resolved_physical_zero_endpoint
        superseded_lower_endpoint_indices = findall(c ->
            hasproperty(c, :status) && c.status == :exact_endpoint &&
            abs(c.logvalue - lo) <= 1e-5, candidates)
        winner_candidates = [c for (i, c) in pairs(candidates)
                             if !(i in superseded_lower_endpoint_indices)]
    end
    best = winner_candidates[argmax([_arc1_profile_comparison_loglik(c,
        centered_active ? centering_ve : nothing) for c in winner_candidates])]
    is_physical_zero = hasproperty(best, :physical_zero_endpoint) &&
                       best.physical_zero_endpoint
    best_at_bound = !is_physical_zero &&
        (abs(best.logvalue - lo) <= 1e-5 || abs(best.logvalue - hi) <= 1e-5)
    best_comparison = _arc1_profile_comparison_loglik(best,
        centered_active ? centering_ve : nothing)
    competitive_unresolved = any(ll -> ll >= best_comparison - 1e-8, unresolved_candidates)
    status = competitive_unresolved || best_at_bound || !best.converged ? :nuisance_unresolved : :ok
    result = (loglik = best.loglik, value = is_physical_zero ? 0.0 : exp(best.logvalue),
            status = status,
            candidates = candidates, max_valid_loglik = max_valid_loglik,
            winner_status = best.status,
            superseded_lower_endpoint_indices = superseded_lower_endpoint_indices,
            physical_zero_endpoint_certificate = zero_endpoint_certificate)
    return centered_active ? merge(result, (centered_active = true,
        centered_loglik = best_comparison,
        max_valid_centered_loglik = maximum_centered[],
        centering_ve = Float64(centering_ve))) : result
end

function _arc1_raw_nuisance(context, target::Symbol, fixed_value::Float64, s0::Float64;
        method_version::Symbol = _ARC1_PROFILE_METHOD_VERSION,
        v3_evidence_sink = nothing,
        bfgs_runner = nothing,
        refinement_runner = nothing,
        scalar_profile_runner = (ctx, make_components, scale; kwargs...) ->
            _arc1_scalar_profile_max(ctx, make_components, scale; kwargs...),
        loglik_runner = (ctx, components) -> _arc1_loglik_for_components(ctx, components),
        gradient_runner = (ctx, components; kwargs...) ->
            _arc1_profile_objective_gradient(ctx, components; kwargs...),
        certificate_runner = (candidate, index, scale, df, faces, intersection, ll, grad; kwargs...) ->
            _arc1_zero_bound_face_certificate(candidate, index, scale, df,
                faces, intersection, ll, grad; kwargs...),
        polish_runner = (ctx, candidate, index, scale, df, faces, intersection, initial; kwargs...) ->
            _arc1_projected_face_polish(ctx, candidate, index, scale, df,
                faces, intersection, initial; kwargs...))
    _arc1_validate_profile_method_version(method_version)
    method_version === :arc1_profile_v3 && v3_evidence_sink !== nothing &&
        !(v3_evidence_sink isa Dict{Symbol,Any}) && throw(ArgumentError(
            "v3_evidence_sink must be Dict{Symbol,Any}"))
    target_index = findfirst(==(target),
        (:additive_variance, :permanent_environment_variance, :residual_variance))
    target_index === nothing && throw(ArgumentError("unknown raw variance target"))
        target_index == 3 && fixed_value == 0 &&
        return (loglik = -Inf, status = :singular_proposal,
                nuisance_statuses = Any[:residual_zero_boundary],
                method_version = method_version)
    centered_active = _arc1_profile_fixed_ve_centering_eligible(
        context, target_index, fixed_value)
    base_centered_loglik_at = centered_active ?
        (components -> _arc1_profile_centered_loglik_at(context, components, fixed_value)) : nothing
    centered_loglik_at = base_centered_loglik_at
    v3_active = method_version === :arc1_profile_v3 && centered_active && target_index == 3
    v3_evidence = v3_active ? _arc1_profile_v3_sink_record!(v3_evidence_sink,
        target, fixed_value) : nothing
    v3_evidence === nothing && v3_active && (v3_evidence = Dict{Symbol,Any}(
        :target => target, :fixed_value => fixed_value, :status => :started,
        :events => Any[], :producer_history => Any[], :max_valid_loglik => -Inf,
        :max_valid_centered_loglik => -Inf, :provenance_failures => Any[]))
    v3_full_history = Ref(-Inf)
    v3_centered_history = Ref(-Inf)
    v3_provenance_failures = Any[]
    v3_collect!(record, path) = if v3_active
        history = _arc1_profile_v3_history!(v3_full_history, v3_centered_history,
            record, fixed_value; sink_record = v3_evidence, path)
        append!(v3_provenance_failures, history.provenance_failures)
        history
    else
        nothing
    end
    v3_publish!(status) = if v3_evidence !== nothing
        if !(status === :in_progress && get(v3_evidence, :status, nothing) === :interrupted)
            v3_evidence[:status] = status
        end
        v3_evidence[:max_valid_loglik] = max(
            get(v3_evidence, :max_valid_loglik, -Inf), v3_full_history[])
        v3_evidence[:max_valid_centered_loglik] = max(
            get(v3_evidence, :max_valid_centered_loglik, -Inf), v3_centered_history[])
        nothing
    else
        nothing
    end
    v3_observe!(kind, value, status, components, path; tag = nothing) = if v3_active
        valid = status === :ok && value isa Real && !(value isa Bool) && isfinite(value)
        event = Dict{Symbol,Any}(:kind => kind, :value => valid ? Float64(value) : missing,
            :status => valid ? :returned : :invalid_return,
            :evaluation_valid => valid, :components => copy(components), :path => path)
        kind === :centered && tag !== nothing && (event[:centering_ve] = tag)
        push!(v3_evidence[:events], event)
        v3_collect!(event, path)
        v3_publish!(:in_progress)
        valid
    else
        false
    end
    observed_loglik_runner(ctx, components) = begin
        result = loglik_runner(ctx, components)
        if v3_active && result isa Tuple && length(result) >= 2
            v3_observe!(:full, result[1], result[2], components, "raw.loglik")
        end
        result
    end
    observed_centered_loglik_at(components) = begin
        result = base_centered_loglik_at(components)
        if v3_active && result !== nothing && hasproperty(result, :status) &&
           hasproperty(result, :loglik)
            v3_observe!(:centered, result.loglik, result.status, components,
                "raw.centered_loglik"; tag = fixed_value)
        end
        result
    end
    observed_gradient_runner(ctx, components; kwargs...) = begin
        result = gradient_runner(ctx, components; kwargs...)
        v3_active && hasproperty(result, :loglik) &&
            v3_observe!(:full, result.loglik, :ok, components, "raw.gradient")
        result
    end
    v3_active && (centered_loglik_at = observed_centered_loglik_at)
    if v3_evidence !== nothing
        v3_evidence[:fixed_value] = fixed_value
        v3_evidence[:target] = target
    end

    try
    base = zeros(3)
    base[target_index] = fixed_value
    nuisance = filter(!=(target_index), [1, 2, 3])
    candidates = Any[]
    diagnostics = Any[]
    invalid_bfgs_record_seen = false

    for m1 in _ARC1_START_MULTIPLIERS, m2 in _ARC1_START_MULTIPLIERS
        candidate_record = if bfgs_runner === nothing
            _arc1_bfgs_candidate(context, base, nuisance, [s0 * m1, s0 * m2], s0;
                centered_loglik_at = centered_active ? centered_loglik_at : nothing,
                centering_ve = centered_active ? fixed_value : nothing)
        else
            bfgs_runner(context, base, nuisance, [s0 * m1, s0 * m2], s0)
        end
        v3_collect!(candidate_record, "positive_candidate[$(length(candidates)+1)]")
        candidate_history = _arc1_profile_likelihood_history(candidate_record;
            centering_ve = centered_active ? fixed_value : nothing)
        candidate_record_valid = _arc1_profile_bfgs_record_valid(candidate_record)
        candidate = candidate_record_valid ? candidate_record :
            _arc1_profile_invalid_bfgs_record(candidate_record, candidate_history;
                centered_active, fixed_ve = fixed_value)
        invalid_bfgs_record_seen |= !candidate_record_valid
        push!(candidates, candidate)
        centered_candidate_valid = !centered_active ||
            _arc1_profile_centered_value(candidate, :centered_loglik, fixed_value) !== nothing
        push!(diagnostics, merge((kind = :positive_bfgs, converged = candidate.converged,
                            loglik = candidate.loglik, gradient_norm = candidate.gradient_norm,
                            hit_bound = candidate.hit_bound,
                            record_valid = candidate_record_valid),
            centered_active ? (centering_record_valid = centered_candidate_valid,
                source_centering_ve = hasproperty(candidate, :centering_ve) ?
                    candidate.centering_ve : missing) : NamedTuple()))
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
            held_zero_component = zero_index,
            centered_loglik_at = centered_active ? centered_loglik_at : nothing,
            centering_ve = centered_active ? fixed_value : nothing,
            (v3_active ? (;
                profile_loglik_at = components -> observed_loglik_runner(context, components),
                profile_gradient_at = (components; free_indices) ->
                    observed_gradient_runner(context, components; free_indices)) :
                NamedTuple())...)
        v3_collect!(face, "exact_zero_face[$zero_index]")
        face_status = hasproperty(face, :status) ? face.status : :invalid_scalar_record
        face_value = hasproperty(face, :value) ? face.value : missing
        face_loglik = hasproperty(face, :loglik) && face.loglik isa Real &&
            !(face.loglik isa Bool) && isfinite(face.loglik) ? Float64(face.loglik) : -Inf
        face_candidates = hasproperty(face, :candidates) && face.candidates isa AbstractVector ?
            face.candidates : Any[]
        face_endpoint = hasproperty(face, :physical_zero_endpoint_certificate) ?
            face.physical_zero_endpoint_certificate : (status = :not_attempted,)
        face_centering_tag_valid = !centered_active ||
            _arc1_profile_centering_tag_matches(face, fixed_value)
        face_centered_terminal = centered_active && face_centering_tag_valid ?
            _arc1_profile_centered_value(face, :centered_loglik, fixed_value) : nothing
        face_centered_score_valid = !centered_active || face_centered_terminal !== nothing
        face_centering_record_valid = face_centering_tag_valid && face_centered_score_valid &&
            isfinite(face_loglik)
        face_history = _arc1_profile_likelihood_history(face;
            centering_ve = centered_active ? fixed_value : nothing)
        scalar_coordinate_valid = face_value isa Real && !(face_value isa Bool) &&
            isfinite(face_value) && face_value >= 0
        if !scalar_coordinate_valid
            values = fill(NaN, 3)
            values[target_index] = fixed_value
            invalid_candidate = (loglik = -Inf,
                max_valid_loglik = face_history.max_valid_loglik,
                components = values, converged = false, gradient_norm = NaN,
                optimizer_status = "invalid_scalar_coordinate", hit_bound = true)
            if centered_active
                invalid_candidate = merge(invalid_candidate, (
                    centered_loglik = -Inf,
                    max_valid_centered_loglik = face_centering_tag_valid ?
                        face_history.max_valid_centered_loglik : -Inf,
                    centering_ve = face_centering_tag_valid ? fixed_value :
                        (hasproperty(face, :centering_ve) ? face.centering_ve : missing)))
            end
            push!(candidates, invalid_candidate)
            push!(diagnostics, merge((kind = :exact_zero_face,
                zero_index = zero_index, converged = false, loglik = -Inf,
                status = :invalid_coordinate, components = values,
                one_sided_objective_gradient = NaN,
                max_valid_loglik = face_history.max_valid_loglik,
                brent_candidates = count(c -> hasproperty(c, :status) && c.status == :brent,
                                         face_candidates),
                winner_value = face_value,
                physical_zero_endpoint_certificate = face_endpoint,
                centered_loglik = centered_active ? -Inf : NaN,
                max_valid_centered_loglik = centered_active && face_centering_tag_valid ?
                    face_history.max_valid_centered_loglik : NaN,
                centering_ve = centered_active && face_centering_tag_valid ?
                    fixed_value : NaN),
                centered_active ? (centering_tag_valid = face_centering_tag_valid,
                    centered_score_valid = false,
                    source_centering_ve = hasproperty(face, :centering_ve) ?
                        face.centering_ve : missing) : NamedTuple()))
            continue
        end
        values = make_components(face_value)
        face_gradient_fit = centered_active && !face_centering_record_valid ? nothing :
            observed_gradient_runner(context, values; free_indices = filter(!=(zero_index), 1:3))
        face_gradient = face_gradient_fit === nothing ? NaN :
            face_gradient_fit.component_gradient[zero_index]
        face_ll, face_ll_status = centered_active && !face_centering_record_valid ?
            observed_loglik_runner(context, values) :
            (face_loglik, face_loglik == -Inf ? :invalid_terminal : :ok)
        face_full_additional = face_ll_status == :ok ? (face_ll,) : ()
        face_gradient_full = face_gradient_fit !== nothing &&
            hasproperty(face_gradient_fit, :loglik) ? (face_gradient_fit.loglik,) : ()
        face_max_full = _arc1_profile_finite_likelihood_maximum((
            face_history.max_valid_loglik, face_full_additional..., face_gradient_full...))
        face_max_centered = centered_active && face_centering_tag_valid ?
            face_history.max_valid_centered_loglik : -Inf
        if centered_active && face_gradient_fit !== nothing &&
           hasproperty(face_gradient_fit, :loglik) &&
           isfinite(face_gradient_fit.loglik)
            gradient_centered, gradient_centered_status = centered_loglik_at(values)
            gradient_centered_status == :ok && isfinite(gradient_centered) &&
                (face_max_centered = max(face_max_centered, gradient_centered))
        end
        face_candidate = (loglik = centered_active && !face_centering_record_valid ?
                            (face_ll_status == :ok ? face_ll : -Inf) : face_loglik,
                           max_valid_loglik = face_max_full,
                           components = values,
                           converged = face_centering_record_valid && face_status == :ok,
                           gradient_norm = NaN, optimizer_status = !face_centering_tag_valid ?
                               "centering_tag_mismatch" : (!face_centered_score_valid ?
                               "centered_score_invalid" : string(face_status)),
                           hit_bound = face_status == :nuisance_unresolved)
        centered_active && (face_candidate = merge(face_candidate, (
            centered_loglik = face_centered_terminal === nothing ? -Inf : face_centered_terminal,
            max_valid_centered_loglik = face_max_centered,
            centering_ve = face_centering_tag_valid ? fixed_value :
                (hasproperty(face, :centering_ve) ? face.centering_ve : missing))))
        push!(candidates, face_candidate)
        push!(diagnostics, merge((kind = :exact_zero_face, zero_index = zero_index,
                            converged = face_centering_record_valid && face_status == :ok,
                            loglik = face_candidate.loglik,
                            status = !face_centering_tag_valid ? :centering_tag_mismatch :
                                (!face_centered_score_valid ? :centered_score_invalid : face_status),
                            components = values,
                            one_sided_objective_gradient = face_gradient,
                            max_valid_loglik = face_max_full,
                            brent_candidates = count(c -> hasproperty(c, :status) && c.status == :brent,
                                                     face_candidates),
                            winner_value = face_value,
                            physical_zero_endpoint_certificate = face_endpoint,
                            centered_loglik = centered_active ?
                                face_candidate.centered_loglik : NaN,
                            max_valid_centered_loglik = centered_active ? face_max_centered : NaN,
                            centering_ve = centered_active ? fixed_value : NaN),
            centered_active ? (centering_tag_valid = face_centering_tag_valid,
                centered_score_valid = face_centered_score_valid,
                source_centering_ve = hasproperty(face, :centering_ve) ?
                    face.centering_ve : missing) : NamedTuple()))
    end
    intersection = copy(base)
    intersection[nuisance] .= 0.0
    ll0, status0 = observed_loglik_runner(context, intersection)
    centered0 = centered_active && status0 == :ok ?
        centered_loglik_at(intersection) :
        (loglik = -Inf, status = :not_evaluated)
    intersection_gradient_fit = status0 == :ok ?
        observed_gradient_runner(context, intersection) : nothing
    intersection_gradient = status0 == :ok ?
        intersection_gradient_fit.component_gradient : fill(NaN, 3)
    intersection_max_full = status0 == :ok ? Float64(ll0) : -Inf
    centered_active && status0 == :ok && hasproperty(intersection_gradient_fit, :loglik) &&
        isfinite(intersection_gradient_fit.loglik) &&
        (intersection_max_full = max(intersection_max_full, intersection_gradient_fit.loglik))
    intersection_max_centered = centered_active && centered0.status == :ok ?
        Float64(centered0.loglik) : -Inf
    if centered_active && status0 == :ok && hasproperty(intersection_gradient_fit, :loglik) &&
       isfinite(intersection_gradient_fit.loglik)
        gradient_centered, gradient_centered_status = centered_loglik_at(intersection)
        gradient_centered_status == :ok && isfinite(gradient_centered) &&
            (intersection_max_centered = max(intersection_max_centered, gradient_centered))
    end
    intersection_candidate = (loglik = status0 == :ok ? ll0 : -Inf,
                       max_valid_loglik = intersection_max_full,
                       components = intersection, converged = status0 == :ok,
                       gradient_norm = 0.0, optimizer_status = "exact_zero_intersection",
                       hit_bound = false)
    centered_active && (intersection_candidate = merge(intersection_candidate, (
        centered_loglik = centered0.status == :ok ? centered0.loglik : -Inf,
        max_valid_centered_loglik = intersection_max_centered,
        centering_ve = fixed_value)))
    v3_collect!(intersection_candidate, "exact_zero_intersection")
    push!(candidates, intersection_candidate)
    push!(diagnostics, (kind = :exact_zero_intersection,
                        converged = status0 == :ok, loglik = ll0, status = status0,
                        components = intersection,
                        one_sided_objective_gradient = intersection_gradient,
                        centered_loglik = centered_active ? intersection_candidate.centered_loglik : NaN,
                        max_valid_centered_loglik = centered_active ? intersection_candidate.max_valid_centered_loglik : NaN,
                        centering_ve = centered_active ? fixed_value : NaN))

    finite = filter(c -> isfinite(c.loglik), candidates)
    max_valid_loglik = _arc1_max_valid_profile_likelihood(candidates)
    max_valid_centered_loglik = centered_active ? maximum((
        _arc1_profile_likelihood_history(c; centering_ve = fixed_value).
            max_valid_centered_loglik for c in candidates); init = -Inf) : NaN
    isempty(finite) && begin
        v3_publish!(:nuisance_unresolved)
        return merge((loglik = -Inf,
        max_valid_loglik = max(max_valid_loglik, v3_full_history[]),
        status = :nuisance_unresolved, nuisance_statuses = diagnostics),
        centered_active ? (centered_active = true,
            max_valid_centered_loglik = max(max_valid_centered_loglik, v3_centered_history[]),
            centering_ve = fixed_value) : NamedTuple(),
        (; method_version))
    end
    resolved_lower_bound = falses(length(candidates))
    resolved_candidates = Any[]
    resolution_diagnostics = Any[]
    comparison_candidates = copy(candidates)
    exact_zero_faces = [d for d in diagnostics if d.kind == :exact_zero_face]
    exact_zero_intersection = only([d for d in diagnostics
        if d.kind == :exact_zero_intersection])
    certificate_maximum = Ref(max_valid_loglik)
    certificate_centered_maximum = Ref(max_valid_centered_loglik)
    comparison_score(candidate) = centered_active ?
        _arc1_profile_comparison_loglik(candidate, fixed_value) : candidate.loglik
    for (i, candidate) in pairs(candidates)
        candidate.converged && continue
        hasproperty(candidate, :hit_bound_components) && !isempty(candidate.hit_bound_components) || continue
        candidate.hit_bound || continue
        local_probe_maximum = Ref(-Inf)
        local_probe_centered_maximum = centered_active ? Ref(-Inf) : nothing
        if v3_active
            _arc1_profile_v3_history!(local_probe_maximum,
                local_probe_centered_maximum, candidate, fixed_value;
                sink_record = v3_evidence, path = "candidate[$i].native")
        end
        candidate_history = _arc1_profile_record_likelihood_history!(local_probe_maximum,
            candidate; centered_maximum = local_probe_centered_maximum,
            centering_ve = centered_active ? fixed_value : nothing)
        candidate_maximum = local_probe_maximum[]
        candidate_centered_maximum = centered_active ? local_probe_centered_maximum[] : -Inf
        loglik_at, gradient_at = _arc1_profile_probe_recorders!(local_probe_maximum,
            components -> observed_loglik_runner(context, components),
            (components; free_indices) -> observed_gradient_runner(
                context, components; free_indices);
            centered_maximum_seen = local_probe_centered_maximum,
            centered_loglik_at = centered_active ? centered_loglik_at : nothing,
            centering_ve = centered_active ? fixed_value : nothing)
        initial_certificate = nothing
        projected_face_polish = nothing
        certificate = try
            current = try
                    centered_active ? certificate_runner(candidate, target_index, s0,
                    context.residual_df, exact_zero_faces, exact_zero_intersection,
                    loglik_at, gradient_at;
                    centered_loglik_at = centered_loglik_at, centering_ve = fixed_value,
                    historical_likelihoods = [candidate.loglik, candidate_maximum],
                    historical_centered_likelihoods = [candidate_centered_maximum,
                                                       candidate_centered_maximum],
                    maximum_seen = local_probe_maximum,
                    centered_maximum_seen = local_probe_centered_maximum) :
                    certificate_runner(candidate, target_index, s0,
                        context.residual_df, exact_zero_faces, exact_zero_intersection,
                        loglik_at, gradient_at)
            catch err
                err isa InterruptException && rethrow()
                (status = :certificate_exception, error = sprint(showerror, err),
                 max_valid_loglik = local_probe_maximum[])
            end
            v3_collect!(current, "candidate[$i].initial_certificate")
            initial_certificate = current
            _arc1_profile_record_likelihood_history!(local_probe_maximum, current;
                centered_maximum = local_probe_centered_maximum,
                centering_ve = centered_active ? fixed_value : nothing)
            v3_collect!(current, "candidate[$i].resolution")
            current_status = hasproperty(current, :status) ? current.status :
                :certificate_record_invalid
            positive_bound_refinement = nothing
            positive_bound_refinement_attempted = false
            if method_version in (:arc1_profile_v2, :arc1_profile_v3) &&
               current_status == :face_likelihood_mismatch &&
               (!centered_active || _arc1_profile_centering_tag_matches(
                   candidate, fixed_value))
                positive_bound_refinement_attempted = true
                corner_scope = v3_active
                original_eligibility = corner_scope ?
                    _arc1_profile_v3_original_status(candidate, current, target_index,
                        s0, exact_zero_faces, fixed_value) : :eligible
                positive_bound_refinement = if original_eligibility !== :eligible
                    (; status = original_eligibility,
                        original_native = candidate,
                        initial_certificate = current,
                        max_valid_loglik = local_probe_maximum[],
                        max_valid_centered_loglik = centered_active ?
                            local_probe_centered_maximum[] : -Inf,
                        centering_ve = centered_active ? fixed_value : missing,
                        continuation = nothing)
                else
                    _arc1_positive_bound_refinement(
                    context, merge(candidate, (; candidate_index = i)), target_index,
                    s0, context.residual_df, exact_zero_faces, exact_zero_intersection,
                    current, loglik_at, gradient_at; maximum_seen = local_probe_maximum,
                    centered_maximum_seen = centered_active ?
                        local_probe_centered_maximum : nothing,
                    centered_loglik_at = centered_active ? centered_loglik_at : nothing,
                    centering_ve = centered_active ? fixed_value : nothing,
                    continuation_runner = refinement_runner)
                end
                v3_collect!(positive_bound_refinement,
                    "candidate[$i].positive_bound_refinement")
                _arc1_profile_record_likelihood_history!(local_probe_maximum,
                    positive_bound_refinement;
                    centered_maximum = local_probe_centered_maximum,
                    centering_ve = centered_active ? fixed_value : nothing)
                current = merge(positive_bound_refinement,
                    (; initial_certificate = current))
                current_status = positive_bound_refinement.status
                if method_version == :arc1_profile_v3 && target_index == 3 &&
                   centered_active && current_status == :continuation_unresolved &&
                   hasproperty(positive_bound_refinement, :continuation) &&
                   hasproperty(positive_bound_refinement.continuation,
                       :returned_continuation)
                    returned_native = positive_bound_refinement.continuation.returned_continuation
                    corner_certificate = _arc1_profile_v3_double_zero_corner_certificate(
                        candidate, returned_native, target_index, s0,
                        context.residual_df, exact_zero_faces, exact_zero_intersection,
                        initial_certificate, loglik_at, gradient_at, centered_loglik_at,
                        fixed_value; maximum_seen = local_probe_maximum,
                        centered_maximum_seen = local_probe_centered_maximum,
                        sink_record = v3_evidence)
                    _arc1_profile_record_likelihood_history!(local_probe_maximum,
                        corner_certificate; centered_maximum = local_probe_centered_maximum,
                        centering_ve = fixed_value)
                    if corner_certificate.status == :resolved_double_zero_corner &&
                       !_arc1_profile_v3_corner_certificate_valid(corner_certificate,
                           fixed_value)
                        corner_certificate = merge(corner_certificate,
                            (; status = :certificate_record_invalid))
                    end
                    current = merge(current, (; status = corner_certificate.status,
                        double_zero_corner_certificate = corner_certificate,
                        max_valid_loglik = local_probe_maximum[],
                        max_valid_centered_loglik = local_probe_centered_maximum[],
                        centering_ve = fixed_value))
                    v3_collect!(corner_certificate,
                        "candidate[$i].double_zero_corner_certificate")
                    current_status = corner_certificate.status
                end
            end
            if !positive_bound_refinement_attempted &&
               current_status == :projected_gradient_unresolved
                polish = try
                    polish_runner(context,
                        merge(candidate, (; candidate_index = i)), target_index, s0,
                        context.residual_df, exact_zero_faces, exact_zero_intersection,
                        initial_certificate; maximum_seen = local_probe_maximum,
                        centered_maximum_seen = centered_active ?
                            local_probe_centered_maximum : nothing,
                        centered_loglik_at = centered_active ? centered_loglik_at : nothing,
                        centering_ve = centered_active ? fixed_value : nothing,
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
                v3_collect!(polish, "candidate[$i].projected_face_polish")
                _arc1_profile_record_likelihood_history!(local_probe_maximum, polish;
                    centered_maximum = local_probe_centered_maximum,
                    centering_ve = centered_active ? fixed_value : nothing)
                polish_continuation = hasproperty(polish, :continuation) ?
                    polish.continuation : (status = :continuation_record_missing,)
                _arc1_profile_record_likelihood_history!(local_probe_maximum,
                    polish_continuation; centered_maximum = local_probe_centered_maximum,
                    centering_ve = centered_active ? fixed_value : nothing)
                projected_face_polish = polish_continuation
                polish_status = hasproperty(polish, :status) ? polish.status :
                    :projected_face_polish_record_invalid
                continuation_gradient_valid = hasproperty(polish_continuation,
                    :continuation_gradient_norm) &&
                    polish_continuation.continuation_gradient_norm isa Real &&
                    isfinite(polish_continuation.continuation_gradient_norm)
                resolved_polish_record_valid = hasproperty(polish, :loglik) &&
                    polish.loglik isa Real && !(polish.loglik isa Bool) &&
                    isfinite(polish.loglik) && hasproperty(polish, :components) &&
                    polish.components isa AbstractVector && length(polish.components) == 3 &&
                    all(x -> x isa Real && isfinite(x) && x >= 0, polish.components) &&
                    continuation_gradient_valid && hasproperty(polish, :boundary_certificate)
                resolved_polish_record_valid &= continuation_gradient_valid &&
                    hasproperty(polish_continuation, :status) &&
                    polish_continuation.status == :resolved_projected_face_polish &&
                    hasproperty(polish, :boundary_certificate) &&
                    _arc1_profile_resolved_face_certificate_valid(
                        polish.boundary_certificate, centered_active)
                if polish_status == :resolved_projected_face_polish &&
                   resolved_polish_record_valid
                    current = merge(current, (status = :resolved_projected_face_polish,
                        polished_loglik = Float64(polish.loglik),
                        polished_components = copy(polish.components),
                        polished_gradient_norm = Float64(
                            polish_continuation.continuation_gradient_norm),
                        max_valid_loglik = local_probe_maximum[],
                        max_valid_centered_loglik = centered_active ?
                            local_probe_centered_maximum[] : NaN,
                        polished_boundary_certificate = polish.boundary_certificate))
                else
                    rejected_polish_status = polish_status == :resolved_projected_face_polish ?
                        :projected_face_polish_record_invalid : polish_status
                    current = merge(current, (projected_face_polish_status = rejected_polish_status,
                        projected_face_polish = polish_continuation,
                        max_valid_loglik = local_probe_maximum[],
                        max_valid_centered_loglik = centered_active ?
                            local_probe_centered_maximum[] : NaN))
                end
            end
            _arc1_profile_record_likelihood_history!(local_probe_maximum, current;
                centered_maximum = local_probe_centered_maximum,
                centering_ve = centered_active ? fixed_value : nothing)
            current_status = hasproperty(current, :status) ? current.status :
                :certificate_record_invalid
            if current_status == :resolved_lower_bound_by_zero_face &&
               !_arc1_profile_resolved_face_certificate_valid(current, centered_active)
                current = merge(current, (status = :certificate_record_invalid,))
            elseif current_status == :resolved_projected_face_polish &&
                   !_arc1_profile_resolved_polish_certificate_valid(current, centered_active)
                current = merge(current, (status = :certificate_record_invalid,))
            elseif current_status == :resolved_positive_bound_refine &&
                   (!_arc1_profile_resolved_face_certificate_valid(
                       current.boundary_certificate, centered_active) ||
                    !hasproperty(current, :components) ||
                    !hasproperty(current, :loglik))
                current = merge(current, (status = :certificate_record_invalid,))
            elseif current_status == :resolved_double_zero_corner &&
                   (!hasproperty(current, :double_zero_corner_certificate) ||
                    !_arc1_profile_v3_corner_certificate_valid(
                        current.double_zero_corner_certificate, fixed_value))
                current = merge(current, (status = :certificate_record_invalid,))
            end
            current_status = hasproperty(current, :status) ? current.status :
                :certificate_record_invalid
            if current_status == :resolved_lower_bound_by_zero_face &&
               hasproperty(current, :face_loglik) && current.face_loglik isa Real &&
               (centered_active ? hasproperty(current, :face_centered_loglik) &&
                    abs(local_probe_centered_maximum[] - current.face_centered_loglik) > 1e-8 :
                    abs(local_probe_maximum[] - current.face_loglik) > 1e-8)
                current = merge(current, (status = :candidate_maximum_mismatch,
                    candidate_max_valid_loglik = local_probe_maximum[],
                    candidate_max_valid_centered_loglik = centered_active ?
                        local_probe_centered_maximum[] : NaN,
                    likelihood_spread = max(current.likelihood_spread,
                        abs(local_probe_maximum[] - current.face_loglik))))
            end
            current
        finally
            certificate_maximum[] = max(certificate_maximum[], local_probe_maximum[])
            centered_active && (certificate_centered_maximum[] = max(
                certificate_centered_maximum[], local_probe_centered_maximum[]))
            v3_publish!(:in_progress)
            v3_evidence === nothing || begin
                v3_evidence[:max_valid_loglik] = max(
                    v3_evidence[:max_valid_loglik], local_probe_maximum[])
                centered_active && (v3_evidence[:max_valid_centered_loglik] = max(
                    v3_evidence[:max_valid_centered_loglik],
                    local_probe_centered_maximum[]))
            end
        end
        if centered_active && _arc1_profile_centered_value(
                candidate, :centered_loglik, fixed_value) !== nothing
            comparison_candidates[i] = merge(candidate, (; max_valid_loglik = local_probe_maximum[],
                max_valid_centered_loglik = local_probe_centered_maximum[],
                centering_ve = fixed_value))
        else
            comparison_candidates[i] = merge(candidate,
                (; max_valid_loglik = local_probe_maximum[]))
        end
        _arc1_profile_record_likelihood_history!(local_probe_maximum, certificate;
            centered_maximum = local_probe_centered_maximum,
            centering_ve = centered_active ? fixed_value : nothing)
        certificate_status = hasproperty(certificate, :status) ? certificate.status :
            :certificate_record_invalid
        if certificate_status == :resolved_lower_bound_by_zero_face
            required = _arc1_profile_resolved_face_certificate_valid(
                certificate, centered_active)
            required || (certificate_status = :certificate_record_invalid)
        elseif certificate_status == :resolved_projected_face_polish
            required = _arc1_profile_resolved_polish_certificate_valid(
                certificate, centered_active)
            required || (certificate_status = :certificate_record_invalid)
        elseif certificate_status == :resolved_positive_bound_refine
            required = hasproperty(certificate, :boundary_certificate) &&
                _arc1_profile_resolved_face_certificate_valid(
                    certificate.boundary_certificate, centered_active)
            required || (certificate_status = :certificate_record_invalid)
        elseif certificate_status == :resolved_double_zero_corner
            required = method_version == :arc1_profile_v3 && centered_active &&
                hasproperty(certificate, :double_zero_corner_certificate) &&
                _arc1_profile_v3_corner_certificate_valid(
                    certificate.double_zero_corner_certificate, fixed_value)
            required || (certificate_status = :certificate_record_invalid)
        end
        normalized_certificate = hasproperty(certificate, :status) ?
            merge(certificate, (status = certificate_status,)) :
            merge((status = certificate_status,), certificate)
        push!(resolution_diagnostics, merge((; candidate_index = i,
            original_loglik = candidate.loglik,
            original_max_valid_loglik = candidate_history.max_valid_loglik,
            certificate_max_valid_loglik = local_probe_maximum[],
            original_components = candidate.components,
            original_hit_bound_components = candidate.hit_bound_components,
            initial_certificate = initial_certificate,
            projected_face_polish = projected_face_polish), normalized_certificate))
        certificate_status in (:resolved_lower_bound_by_zero_face,
                               :resolved_projected_face_polish,
                               :resolved_positive_bound_refine,
                               :resolved_double_zero_corner) || continue
        resolved_lower_bound[i] = true
        if certificate_status == :resolved_lower_bound_by_zero_face
            push!(resolved_candidates, merge(candidate, (; loglik = certificate.loglik,
                components = certificate.components, converged = true, hit_bound = false,
                resolved_lower_bound_by_zero_face = true,
                max_valid_loglik = local_probe_maximum[],
                centered_loglik = centered_active ?
                    centered_loglik_at(certificate.components).loglik : NaN,
                max_valid_centered_loglik = centered_active ?
                    local_probe_centered_maximum[] : NaN,
                centering_ve = centered_active ? fixed_value : NaN,
                boundary_certificate = certificate)))
        elseif certificate_status == :resolved_projected_face_polish
            push!(resolved_candidates, merge(candidate, (; loglik = certificate.polished_loglik,
                components = certificate.polished_components, converged = true, hit_bound = false,
                original_gradient_norm = candidate.gradient_norm,
                gradient_norm = certificate.polished_gradient_norm,
                polished_gradient_norm = certificate.polished_gradient_norm,
                resolved_lower_bound_by_zero_face = true,
                resolved_by_projected_face_polish = true,
                max_valid_loglik = local_probe_maximum[],
                centered_loglik = centered_active ?
                    centered_loglik_at(certificate.polished_components).loglik : NaN,
                max_valid_centered_loglik = centered_active ?
                    local_probe_centered_maximum[] : NaN,
                centering_ve = centered_active ? fixed_value : NaN,
                boundary_certificate = certificate.polished_boundary_certificate,
                projected_face_polish = projected_face_polish)))
        elseif certificate_status == :resolved_positive_bound_refine
            boundary = certificate.boundary_certificate
            push!(resolved_candidates, merge(candidate, (; loglik = boundary.loglik,
                components = copy(boundary.components), converged = true, hit_bound = false,
                resolved_lower_bound_by_zero_face = true,
                resolved_by_positive_bound_refine = true,
                max_valid_loglik = local_probe_maximum[],
                centered_loglik = centered_active ?
                    centered_loglik_at(boundary.components).loglik : NaN,
                max_valid_centered_loglik = centered_active ?
                    local_probe_centered_maximum[] : NaN,
                centering_ve = centered_active ? fixed_value : NaN,
                boundary_certificate = boundary,
                positive_bound_refinement = certificate.continuation,
                original_certificate = certificate.initial_certificate)))
        else
            corner = certificate.double_zero_corner_certificate
            push!(resolved_candidates, merge(candidate, (; loglik = corner.loglik,
                components = copy(corner.components), converged = true, hit_bound = false,
                resolved_lower_bound_by_zero_face = true,
                resolved_by_double_zero_corner = true,
                max_valid_loglik = local_probe_maximum[],
                centered_loglik = corner.centered_loglik,
                max_valid_centered_loglik = local_probe_centered_maximum[],
                centering_ve = fixed_value,
                double_zero_corner_certificate = corner,
                positive_bound_refinement = certificate.continuation,
                original_certificate = certificate.initial_certificate)))
        end
    end
    max_valid_loglik = max(max_valid_loglik, certificate_maximum[], v3_full_history[])
    max_valid_centered_loglik = centered_active ?
        max(max_valid_centered_loglik, certificate_centered_maximum[],
            v3_centered_history[]) : NaN
    certified = Any[c for c in finite if c.converged &&
        (!centered_active || _arc1_profile_centered_value(
            c, :centered_loglik, fixed_value) !== nothing)]
    append!(certified, resolved_candidates)
    isempty(certified) && begin
        v3_publish!(:nuisance_unresolved)
        return merge((loglik = -Inf,
        max_valid_loglik = max(max_valid_loglik, v3_full_history[]),
        status = :nuisance_unresolved,
        nuisance_statuses = merge((; raw_candidates = diagnostics),
            (; lower_bound_resolutions = resolution_diagnostics))),
        centered_active ? (max_valid_centered_loglik = max(max_valid_centered_loglik,
                v3_centered_history[]),
            centering_ve = fixed_value) : NamedTuple(),
        (; method_version))
    end
    best = certified[argmax(comparison_score.(certified))]
    best_comparison = comparison_score(best)
    unresolved_competitor = any(i -> !resolved_lower_bound[i] &&
        _arc1_raw_competitor_is_competitive(comparison_candidates[i], best_comparison;
            centering_ve = centered_active ? fixed_value : nothing),
        eachindex(comparison_candidates))
    historical_full_competitor = method_version in (:arc1_profile_v2, :arc1_profile_v3) &&
        !centered_active &&
        max_valid_loglik > best.loglik + 1e-8
    unresolved_competitor |= historical_full_competitor
    invalid_centering_tag_indices = centered_active ? findall(c ->
        !_arc1_profile_centering_tag_matches(c, fixed_value), candidates) : Int[]
    historical_centered_competitor = centered_active &&
        max_valid_centered_loglik > best_comparison + 1e-8
    v3_history_unresolved = v3_active && !isempty(v3_provenance_failures)
    face_centering_tag_mismatch = centered_active && any(d ->
        d.kind == :exact_zero_face && !d.centering_tag_valid, diagnostics)
    status = unresolved_competitor || historical_centered_competitor ||
        !isempty(invalid_centering_tag_indices) ||
        face_centering_tag_mismatch || invalid_bfgs_record_seen || v3_history_unresolved ?
        :nuisance_unresolved : :ok
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
            centered_loglik = centered_active ? comparison_score(c) : NaN,
            centered_delta_from_best = centered_active ?
                comparison_score(c) - best_comparison : NaN,
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
        c = uncertified[argmax(comparison_score.(uncertified))]
        (loglik = c.loglik, delta_from_best = c.loglik - best.loglik,
         centered_loglik = centered_active ? comparison_score(c) : NaN,
         centered_delta_from_best = centered_active ?
            comparison_score(c) - best_comparison : NaN,
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
    raw_search_status = (kind = :raw_nuisance_search,
                method_version = method_version,
                exact_zero_faces = exact_zero_faces,
                exact_zero_intersection = exact_zero_intersection,
                lower_bound_resolutions = resolution_diagnostics,
                resolved_lower_bound_by_zero_face = count(identity, resolved_lower_bound),
                resolved_by_projected_face_polish = count(c ->
                    hasproperty(c, :resolved_by_projected_face_polish) &&
                    c.resolved_by_projected_face_polish, resolved_candidates),
                resolved_by_positive_bound_refine = count(c ->
                    hasproperty(c, :resolved_by_positive_bound_refine) &&
                    c.resolved_by_positive_bound_refine, resolved_candidates),
                resolved_by_double_zero_corner = count(c ->
                    hasproperty(c, :resolved_by_double_zero_corner) &&
                    c.resolved_by_double_zero_corner, resolved_candidates),
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
                unresolved_competitor = unresolved_competitor,
                historical_full_competitor = historical_full_competitor,
                v3_history_provenance_failures = copy(v3_provenance_failures),
                invalid_bfgs_record_indices = findall(d ->
                    d.kind == :positive_bfgs && !d.record_valid, diagnostics))
    if centered_active
        invalid_centered_indices = findall(c ->
            _arc1_profile_centered_value(c, :centered_loglik, fixed_value) === nothing,
            candidates)
        raw_search_status = merge(raw_search_status,
            (invalid_centered_record_indices = invalid_centered_indices,
             invalid_centering_tag_indices = invalid_centering_tag_indices))
    end
    result = (loglik = best.loglik, max_valid_loglik = max_valid_loglik,
        status = status, nuisance_statuses = [raw_search_status],
        method_version = method_version)
    v3_publish!(status)
    return centered_active ? merge(result, (
        centered_loglik = best_comparison,
        max_valid_centered_loglik = max_valid_centered_loglik,
        centering_ve = fixed_value)) : result
    catch err
        if v3_evidence !== nothing
            push!(v3_evidence[:events], Dict{Symbol,Any}(
                :kind => :raw_exception,
                :status => err isa InterruptException ? :interrupted : :error,
                :error => sprint(showerror, err)))
            v3_evidence[:error] = sprint(showerror, err)
            v3_publish!(err isa InterruptException ? :interrupted : :error)
        end
        rethrow()
    end
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

function _arc1_profile_at_uncached(state::_Arc1ProfileState, target::Symbol, value::Float64;
        v3_evidence_sink = nothing)
    _arc1_validate_profile_method_version(state.method_version)
    if target in (:heritability, :repeatability)
        result = _arc1_ratio_nuisance(state.context, target, value, state.s0,
                                      state.nuisance_statuses)
        return merge(result, (; method_version = state.method_version))
    end
    return _arc1_raw_nuisance(state.context, target, value, state.s0;
        method_version = state.method_version, v3_evidence_sink)
end

function _arc1_profile_at(state::_Arc1ProfileState, target::Symbol, value::Float64;
        v3_evidence_sink = nothing)
    return _arc1_profile_cache!(state, target, value; v3_evidence_sink)
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
                                              cutoff::Real = _ARC1_PROFILE_CUTOFF_95,
                                              method_version::Symbol = _ARC1_PROFILE_METHOD_VERSION,
                                              v3_evidence_sink = nothing)
    _arc1_validate_profile_method_version(method_version)
    method_version === :arc1_profile_v3 && v3_evidence_sink !== nothing &&
        !(v3_evidence_sink isa Dict{Symbol,Any}) && throw(ArgumentError(
            "v3_evidence_sink must be Dict{Symbol,Any}"))
    level == 0.95 || throw(ArgumentError("Arc1 profile methods support only level=0.95"))
    cutoff == _ARC1_PROFILE_CUTOFF_95 ||
        throw(ArgumentError("Arc1 profile methods use the fixed chi-square cutoff 3.841458820694124"))
    context = merge(_arc1_profile_context(y, X, Z, Ainv),
        (; method_version = method_version))
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
                method_version = method_version,
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
        Dict{Symbol,Dict{Float64,Any}}(), Dict{Symbol,Int}(), point.fit.loglik,
        Any[], method_version)
    targets = Dict{Symbol,Any}()
    for target in _ARC1_PROFILE_TARGETS
        estimate = _arc1_target_estimate(point.fit.components, target)
        targets[target] = _arc1_target_search(state, target, estimate;
            profile_evaluator = x -> _arc1_profile_at(state, target, x;
                v3_evidence_sink = method_version === :arc1_profile_v3 ?
                    v3_evidence_sink : nothing))
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
            method_version = method_version,
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

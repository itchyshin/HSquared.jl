# Public wrappers for the bounded Arc 1 uncertainty leaves. These keep the
# experimental interfaces explicit and separate from legacy intervals.

"""
    arc1_profile_repeatability(y, X, Z, pedigree; ids=pedigree.ids,
                               method="arc1_profile_v1")

Fit the bounded `arc1_profile_v1` or explicitly selected `arc1_profile_v2`,
`arc1_profile_v3`, or `arc1_profile_v4`
uncertainty path for a univariate Gaussian
animal-plus-permanent-environment repeatability design. Each observed animal
must have exactly two records. `X` must be finite and full column rank, with
fewer columns than response rows; the interface does not require an
intercept-only design. The result profiles additive variance, permanent-
environment variance, residual variance, heritability, and repeatability using
the fixed likelihood-ratio cutoff 3.841458820694124, the candidate nominal
95% cutoff. Coverage remains unvalidated. The point fit is the same likelihood
fit used for the profile intervals. Formation is a finite-search result, not
a coverage or calibration claim; refused targets retain their failure status,
and disconnected confidence-set segments are kept separately.
"""
function arc1_profile_repeatability(y::AbstractVector, X::AbstractMatrix,
                                    Z::AbstractMatrix, pedigree::Pedigree;
                                    ids = pedigree.ids,
                                    method = "arc1_profile_v1",
                                    v3_evidence_sink = nothing)
    method_version = _arc1_profile_method_version(method)
    if v3_evidence_sink !== nothing
        method_version in (:arc1_profile_v3, :arc1_profile_v4) || throw(ArgumentError(
            "v3_evidence_sink is only valid with method=\"arc1_profile_v3\" or \"arc1_profile_v4\""))
        v3_evidence_sink isa Dict{Symbol,Any} || throw(ArgumentError(
            "v3_evidence_sink must be a mutable Dict{Symbol,Any}"))
        key, value = :requested_method_version, String(method_version)
        if haskey(v3_evidence_sink, key) && v3_evidence_sink[key] != value
            throw(ArgumentError("v3_evidence_sink contains a conflicting method identity"))
        end
        v3_evidence_sink[key] = value
        # The profile implementation records the shared-history stream under
        # its historical v3 key. Expose the same mutable vector under a v4 key
        # as well so the R transport can name the requested method while still
        # retaining every event if the computation is interrupted.
        if method_version === :arc1_profile_v4
            v3_key = :arc1_profile_v3_evaluations
            v4_key = :arc1_profile_v4_evaluations
            has_v3 = haskey(v3_evidence_sink, v3_key)
            has_v4 = haskey(v3_evidence_sink, v4_key)
            v3_values = has_v3 ? v3_evidence_sink[v3_key] : nothing
            v4_values = has_v4 ? v3_evidence_sink[v4_key] : nothing
            has_v3 && !(v3_values isa AbstractVector) && throw(ArgumentError(
                "v3_evidence_sink[:arc1_profile_v3_evaluations] must be a vector"))
            has_v4 && !(v4_values isa AbstractVector) && throw(ArgumentError(
                "v3_evidence_sink[:arc1_profile_v4_evaluations] must be a vector"))
            if has_v3 && has_v4 && v3_values !== v4_values
                if isempty(v3_values)
                    v3_values = v4_values
                elseif isempty(v4_values)
                    v4_values = v3_values
                elseif !isequal(v3_values, v4_values)
                    throw(ArgumentError(
                        "v3_evidence_sink contains conflicting v3 and v4 evaluation histories"))
                end
            end
            evaluations = has_v3 ? v3_values : has_v4 ? v4_values : Any[]
            v3_evidence_sink[v3_key] = evaluations
            v3_evidence_sink[v4_key] = evaluations
            certificates = get!(v3_evidence_sink, :v4_tail_certificates, Any[])
            certificates isa AbstractVector || throw(ArgumentError(
                "v3_evidence_sink[:v4_tail_certificates] must be a vector"))
        end
    end
    collect(ids) == pedigree.ids ||
        throw(ArgumentError("ids must match pedigree order exactly"))
    size(Z, 2) == length(pedigree.ids) ||
        throw(ArgumentError("Z columns must match pedigree order"))
    Ainv = pedigree_inverse(pedigree)
    if v3_evidence_sink !== nothing
        for (key, value) in ((:actual_method_version, String(method_version)),
                             (:source_identity, _ARC1_SOURCE_IDENTITY))
            haskey(v3_evidence_sink, key) && v3_evidence_sink[key] != value &&
                throw(ArgumentError("v3_evidence_sink contains a conflicting method identity"))
            v3_evidence_sink[key] = value
        end
    end
    result = _arc1_repeatability_profile_intervals(y, X, Z, Ainv;
        method_version, v3_evidence_sink)
    hasproperty(result, :method_version) && result.method_version === method_version ||
        throw(ArgumentError("Arc1 profile result method version does not match the requested method"))
    point_candidate = result.point_fit
    materialized = point_candidate === nothing ?
        (; fit=nothing, candidate=nothing, status=:unavailable, reason=nothing) :
        _arc1_materialize_point_fit(y, X, Z, Ainv, point_candidate)
    point = materialized.fit
    result = merge(result, (; point_fit=point,
        point_fit_candidate=materialized.candidate,
        point_fit_materialization_status=materialized.status,
        point_fit_materialization_reason=materialized.reason))
    if point_candidate !== nothing && point === nothing
        failed_targets = Dict(target => merge(target_result,
            (; confidence_set=nothing, formed=false, status=:point_fit_unconverged))
            for (target, target_result) in result.targets)
        result = merge(result, (; point_fit_status=:point_fit_unconverged,
                                targets=failed_targets))
    end
    estimates = if point === nothing
        nothing
    else
        vc = point.variance_components
        total = vc.sigma_a2 + vc.sigma_pe2 + vc.sigma_e2
        (additive_variance = vc.sigma_a2,
         permanent_environment_variance = vc.sigma_pe2,
         residual_variance = vc.sigma_e2,
         heritability = vc.sigma_a2 / total,
         repeatability = (vc.sigma_a2 + vc.sigma_pe2) / total)
    end
    return merge(result, (method = String(method_version), method_version,
        point_estimates = estimates,
        source_identity = _ARC1_SOURCE_IDENTITY,
        reference_source_identity = _ARC1_SOURCE_IDENTITY,
        point_fit_not_optimal = hasproperty(result, :point_fit_not_optimal) ?
                                result.point_fit_not_optimal : false,
        nuisance_statuses = hasproperty(result, :nuisance_statuses) ?
                            result.nuisance_statuses : Dict{Symbol,Any}(),
        point_identity = point === nothing ? nothing : bytes2hex(sha256(repr((
            point.loglik, point.variance_components,
        )))),
        reference_point_identity = point === nothing ? nothing : bytes2hex(sha256(repr((
            point.loglik, point.variance_components,
        ))))))
end

function _arc1_profile_method_version(method)
    method isa AbstractString || throw(ArgumentError(
        "method must be the string \"arc1_profile_v1\", \"arc1_profile_v2\", \"arc1_profile_v3\", or \"arc1_profile_v4\""))
    method in ("arc1_profile_v1", "arc1_profile_v2", "arc1_profile_v3", "arc1_profile_v4") || throw(ArgumentError(
        "unsupported Arc1 profile method $(repr(method)); choose \"arc1_profile_v1\", \"arc1_profile_v2\", \"arc1_profile_v3\", or \"arc1_profile_v4\""))
    return Symbol(method)
end

function _arc1_materialize_point_fit(y, X, Z, Ainv, point)
    hasproperty(point, :variance_components) &&
        return (; fit=point, candidate=point, status=:already_materialized, reason=nothing)
    hasproperty(point, :components) ||
        return (; fit=nothing, candidate=point, status=:missing_components,
                reason="point candidate lacks a three-component vector")
    length(point.components) == 3 ||
        return (; fit=nothing, candidate=point, status=:invalid_components,
                reason="point candidate does not retain exactly three variance components")
    evaluated = try
        context = _arc1_profile_context(y, X, Z, Ainv)
        _arc1_profile_reml(context, point.components...)
    catch error
        error isa InterruptException && rethrow()
        return (; fit=nothing, candidate=point, status=:reevaluation_failed,
                reason=sprint(showerror, error))
    end
    evaluated.status == :ok ||
        return (; fit=nothing, candidate=point, status=:reevaluation_failed,
                reason="exact point reevaluation returned $(evaluated.status)")
    # Keep the optimizer record intact. This exact likelihood reevaluation only
    # supplies beta and named variance components; it does not certify the
    # optimizer's convergence or replace its diagnostics.
    fit = merge(evaluated, (; components=copy(point.components),
        optimizer_candidate=point,
        optimizer_status=hasproperty(point, :optimizer_status) ? point.optimizer_status : missing,
        optimizer_iterations=hasproperty(point, :iterations) ? point.iterations :
            (hasproperty(point, :optimizer_iterations) ? point.optimizer_iterations : missing)))
    return (; fit, candidate=point, status=:reevaluated, reason=nothing)
end

function _arc1_interface_variance_components(point)
    if hasproperty(point, :variance_components)
        return point.variance_components
    elseif hasproperty(point, :components)
        length(point.components) == 3 ||
            throw(ArgumentError("Arc1 profile point fit must retain three variance components"))
        return (sigma_a2 = point.components[1], sigma_pe2 = point.components[2],
                sigma_e2 = point.components[3])
    end
    throw(ArgumentError("Arc1 profile point fit lacks variance components"))
end

"""
    arc1_confint(profile_result)

Return the long interval table for an `arc1_profile_v1`, `arc1_profile_v2`,
`arc1_profile_v3`, or `arc1_profile_v4`
result. The five
profiled estimands are additive variance, permanent-environment variance,
residual variance, heritability, and repeatability. Disconnected formed
confidence-set segments produce separate rows; refused estimands remain as
rows with missing bounds and a status. The fixed cutoff 3.841458820694124 is
the candidate nominal 95% cutoff; coverage remains unvalidated. This reports
computational formation only.
"""
function arc1_confint(profile_result)
    hasproperty(profile_result, :method) ||
        throw(ArgumentError("arc1_confint requires an Arc1 profile result"))
    method_version = try
        _arc1_profile_method_version(profile_result.method)
    catch error
        error isa ArgumentError || rethrow()
        throw(ArgumentError("arc1_confint requires an arc1_profile_v1, arc1_profile_v2, arc1_profile_v3, or arc1_profile_v4 result"))
    end
    hasproperty(profile_result, :method_version) &&
        profile_result.method_version === method_version ||
        throw(ArgumentError("Arc1 profile method version does not match its method identity"))
    profile_result.source_identity == profile_result.reference_source_identity ||
        throw(ArgumentError("profile and reference point source identities differ"))
    profile_result.point_identity == profile_result.reference_point_identity ||
        throw(ArgumentError("profile intervals and point estimates identify different point fits"))
    rows = NamedTuple[]
    for (target, result) in pairs(profile_result.targets)
        if hasproperty(profile_result, :point_fit) && profile_result.point_fit !== nothing &&
           profile_result.point_estimates !== nothing
            vc = _arc1_interface_variance_components(profile_result.point_fit)
            expected = _arc1_target_estimate(
                [vc.sigma_a2, vc.sigma_pe2, vc.sigma_e2], target)
            isequal(get(profile_result.point_estimates, target, missing), expected) ||
                throw(ArgumentError("Arc1 point estimate for $(target) does not match its reference point fit"))
        end
        segments = result.confidence_set === nothing ? Tuple{Float64,Float64}[] : result.confidence_set
        if !result.formed || isempty(segments)
            push!(rows, (estimand = String(target), trait = missing, segment = 1,
                estimate = profile_result.point_estimates === nothing ? missing :
                           get(profile_result.point_estimates, target, missing),
                lower = missing, upper = missing, formed = false,
                status = String(result.formed && isempty(segments) ? :inconsistent_formed_state : result.status)))
        else
            for (i, bounds) in pairs(segments)
                push!(rows, (estimand = String(target), trait = missing, segment = i,
                    estimate = profile_result.point_estimates === nothing ? missing :
                               get(profile_result.point_estimates, target, missing),
                    lower = bounds[1], upper = bounds[2], formed = true,
                    status = String(result.status)))
            end
        end
    end
    return rows
end

"""
    arc1_bootstrap(selection, Y, X, Z, pedigree; selector=:arc1_v1, B, seeds, ids, traits)

Run `B` full-reselection bootstrap attempts with exactly `B` distinct explicit
`UInt64` seeds and an explicit selector policy matching the outer selection
(`:arc1_v1` or `:arc1_v2`). Each attempt
reruns the selector. No seed schedule or bootstrap count is chosen implicitly;
failed attempts remain visible in the result. The R interface accepts exact
UInt64 decimal seed strings and requires an explicit matching `confint()`
method. Interval formation is not evidence of coverage or calibration.
"""
function arc1_bootstrap(selection, Y, X, Z, pedigree::Pedigree;
                        selector = :arc1_v1, B::Integer, seeds::AbstractVector{UInt64},
                        ids = pedigree.ids, traits)
    selector in (:arc1_v1, :arc1_v2) || throw(ArgumentError(
        "bootstrap requires selector=:arc1_v1 or selector=:arc1_v2"))
    hasproperty(selection, :optimizer_policy) && selection.optimizer_policy == String(selector) ||
        throw(ArgumentError("bootstrap selector must match the outer FA selection policy"))
    B == length(seeds) || throw(ArgumentError("B must equal the exact seed vector length"))
    return _arc1_bootstrap(selection, Y, X, Z, pedigree;
                           seeds = seeds, ids = ids, traits = traits)
end

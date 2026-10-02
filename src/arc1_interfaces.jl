# Public wrappers for the bounded Arc 1 uncertainty leaves. These keep the
# experimental interfaces explicit and separate from legacy intervals.

"""
    arc1_profile_repeatability(y, X, Z, pedigree; ids=pedigree.ids)

Fit the bounded `arc1_profile_v1` uncertainty path for a univariate Gaussian
animal-plus-permanent-environment repeatability design. Each observed animal
must have exactly two records. The point fit is the same likelihood fit used
for the profile intervals. Formation is a finite-search result, not a coverage
or calibration claim.
"""
function arc1_profile_repeatability(y::AbstractVector, X::AbstractMatrix,
                                    Z::AbstractMatrix, pedigree::Pedigree;
                                    ids = pedigree.ids)
    collect(ids) == pedigree.ids ||
        throw(ArgumentError("ids must match pedigree order exactly"))
    size(Z, 2) == length(pedigree.ids) ||
        throw(ArgumentError("Z columns must match pedigree order"))
    Ainv = pedigree_inverse(pedigree)
    result = _arc1_repeatability_profile_intervals(y, X, Z, Ainv)
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
    return merge(result, (method = "arc1_profile_v1", point_estimates = estimates,
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

Return the long interval table for an `arc1_profile_v1` result. Disconnected
formed confidence-set segments produce separate rows; refused estimands remain
as rows with missing bounds. This reports computational formation only.
"""
function arc1_confint(profile_result)
    hasproperty(profile_result, :method) && profile_result.method == "arc1_profile_v1" ||
        throw(ArgumentError("arc1_confint requires an arc1_profile_v1 result"))
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

Run `B` full-reselection bootstrap attempts with exactly `B` explicit `UInt64`
seeds and the supported `:arc1_v1` selector policy. No seed schedule or
bootstrap count is chosen implicitly. Interval formation is not evidence of
coverage or calibration.
"""
function arc1_bootstrap(selection, Y, X, Z, pedigree::Pedigree;
                        selector = :arc1_v1, B::Integer, seeds::AbstractVector{UInt64},
                        ids = pedigree.ids, traits)
    selector === :arc1_v1 || throw(ArgumentError("bootstrap requires selector=:arc1_v1"))
    B == length(seeds) || throw(ArgumentError("B must equal the exact seed vector length"))
    return _arc1_bootstrap(selection, Y, X, Z, pedigree;
                           seeds = seeds, ids = ids, traits = traits)
end

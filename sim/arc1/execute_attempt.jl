# One deterministic Arc1 outer attempt. Study admission and child-process
# ownership live in run_cell.py; this module only consumes pinned inputs.
using TOML
using Serialization
using SHA
using LinearAlgebra

include(joinpath(@__DIR__, "reference.jl"))

const ARC1_DATA_IDENTITY_METHOD = "arc1-semantic-data-v2"

function arc1_engine_pedigree(engine::Module, data_pedigree)
    return getfield(engine, :Pedigree)(copy(data_pedigree.ids), copy(data_pedigree.sire),
                                       copy(data_pedigree.dam), collect(1:length(data_pedigree.ids)))
end

function arc1_fa_design(engine::Module, data)
    n = length(data.observed_ids)
    pedigree = arc1_engine_pedigree(engine, data.pedigree)
    X = ones(Float64, n, 1)
    Z = zeros(Float64, n, length(pedigree.ids))
    for (i, id) in pairs(data.observed_ids)
        Z[i, data.observed_id_to_row[id]] = 1.0
    end
    return (; pedigree, Y=Matrix{Float64}(data.Y), X, Z,
            traits=["trait$i" for i in 1:4], ids=pedigree.ids)
end

function arc1_repeatability_design(engine::Module, data)
    pedigree = arc1_engine_pedigree(engine, data.pedigree)
    nrecord = length(data.y)
    X = ones(Float64, nrecord, 1)
    Z = zeros(Float64, nrecord, length(pedigree.ids))
    for (i, id) in pairs(data.record_animal_ids)
        Z[i, data.observed_id_to_row[id]] = 1.0
    end
    return (; pedigree, y=Vector{Float64}(data.y), X, Z, ids=pedigree.ids)
end

function arc1_rank_receipt(selection; reference_audit=(; status="not_required",
        reason="expanded reference is not required for this attempt"))
    candidates = Dict{String,Any}()
    for candidate in selection.candidate_summary
        label = "K$(candidate.rank)"
        available = Bool(candidate.eligible)
        reason = available ? nothing : something(candidate.reason, String(candidate.status))
        candidates[label] = (; parameter_count=candidate.q,
            aic_penalty=candidate.penalty, available,
            status=available ? "ok" : String(candidate.status), raw_loglik=candidate.loglik,
            score=candidate.criterion, error_reason=reason)
    end
    pair_available = all(candidates[k].available for k in ("K0", "K1"))
    selected = selection.selection_status == :selected && selection.selected_fit !== nothing &&
        selection.selected_rank !== nothing ? "K$(selection.selected_rank)" : nothing
    selector_candidates = Dict("K$(candidate.rank)" => (; near_floor=candidate.near_floor)
        for candidate in selection.candidate_summary)
    selection_diagnostics = (; near_tie=selection.near_tie)
    return (; rank_candidates=candidates, eligible=pair_available,
            both_candidates_available=pair_available,
            selected_rank=selected, selection_status=String(selection.selection_status),
            selection_reason=selection.reason,
            selection=selection_diagnostics, candidate_summary=selector_candidates,
            source_identity=selection.source_identity, starts_planned=selection.starts_planned,
            starts_attempted=selection.starts_attempted, selector_attempts=selection.attempts,
            guard_results=hasproperty(selection, :guard_results) ? selection.guard_results : nothing,
            reference_audit)
end

function arc1_fa_rank_result(selection, reference_audit)
    selection_row = arc1_rank_receipt(selection; reference_audit)
    selected = selection.selection_status == :selected && selection.selected_fit !== nothing
    return merge(selection_row, (; success=selected,
        status=selected ? "ok" : "selection_failed",
        failure_reason=selected ? nothing : something(selection.reason,
            "selector did not return a selected fit; candidate availability is retained separately")))
end

function arc1_reference_required(selection, cell, outer::Int)
    cell["programme"] == "fa_rank" || return false
    phase = cell["phase"]
    phase in ("development", "pilot", "confirmation") || return false
    preselected = phase == "development" ? (31 <= outer <= 50) : (outer <= 20)
    usable = selection.selection_status == :selected && selection.selected_fit !== nothing &&
             selection.selected_rank !== nothing
    preselected || !usable || selection.near_tie === true ||
        any(candidate -> candidate.near_floor === true, selection.candidate_summary)
end

function arc1_reference_audit_from_raw(selection, reference;
        comparison_runner=(ordinary, reference; rank) ->
            arc1_reference_rank_comparison(ordinary, reference; rank))
    comparisons = Dict{String,Any}()
    for rank in (0, 1)
        candidate = findfirst(row -> row.rank == rank, selection.candidate_summary)
        ordinary_loglik = candidate === nothing ? nothing : selection.candidate_summary[candidate].loglik
        comparisons["K$rank"] = comparison_runner(ordinary_loglik, reference; rank)
    end
    starts = Dict("K$(rank)" => count for (rank, count) in reference.starts_planned)
    return (; status=String(reference.status), dataset_identity=String(reference.dataset_identity),
        rows=reference.rows, starts_planned=starts, rank_comparisons=comparisons,
        phenotypic_variances=reference.phenotypic_variances,
        phenotypic_variance_method=reference.phenotypic_variance_method,
        refinement_selection=reference.refinement_selection,
        optimizer_budgets=reference.optimizer_budgets, claim=reference.claim,
        k0_anchor=hasproperty(reference, :k0_anchor) ? reference.k0_anchor :
            (; status=:unavailable, source=:missing_reference_anchor))
end

function arc1_rank_reference_receipt(engine::Module, selection, design, dataset_identity;
        raw_reference_sink=nothing, reference_runner=(eng, Y, X, B; kwargs...) ->
            arc1_fa_expanded_reference(eng, Y, X, B; kwargs...),
        comparison_runner=(ordinary, reference; rank) ->
            arc1_reference_rank_comparison(ordinary, reference; rank))
    relationship_precision = getfield(engine, :pedigree_inverse)(design.pedigree)
    relationship = inv(Symmetric(Matrix{Float64}(relationship_precision)))
    observed_relationship = design.Z * relationship * transpose(design.Z)
    reference = reference_runner(engine, design.Y, design.X, observed_relationship;
                                 dataset_identity)
    raw_reference_sink === nothing || (raw_reference_sink[] = reference)
    return arc1_reference_audit_from_raw(selection, reference; comparison_runner)
end

function arc1_data_identity(data)
    digest_io = IOBuffer()
    serialize(digest_io, data)
    return bytes2hex(sha256(take!(digest_io)))
end

"""Hash the canonical semantic data and design payload, independently of Serialization bytes."""
function arc1_semantic_data_identity(data, design)
    ped = design.pedigree
    canonical_design = (; Y=hasproperty(design, :Y) ? design.Y : design.y,
        X=design.X, Z=design.Z, ids=design.ids,
        pedigree=(; ids=ped.ids, sire=ped.sire, dam=ped.dam))
    payload = (; data, design=canonical_design)
    return bytes2hex(sha256(codeunits(arc1_json(payload))))
end

function arc1_interval_rows(prefix)
    rows = Dict{String,Any}()
    labels = string.([interval.trait for interval in prefix.intervals])
    expected_labels = ["trait$i" for i in 1:4]
    if length(labels) != length(expected_labels) || sort(labels) != expected_labels
        throw(ArgumentError("FA bootstrap intervals must contain exactly one interval for each of traits 1 through 4"))
    end
    for i in 1:4
        result = only(filter(x -> string(x.trait) == "trait$i", prefix.intervals))
        formed = Bool(result.formed)
        segments = formed ? [[Float64(result.lower), Float64(result.upper)]] : Any[]
        rows["h2_$i"] = (; formed, segments, status=formed ? "formed" : "insufficient_usable_bootstrap",
            refusal_status=formed ? nothing : String(result.status),
            formula="G_$(i)$(i)/(G_$(i)$(i)+R_$(i)$(i))", estimate=result.estimate)
    end
    return rows
end

function arc1_inner_rank_receipt(inner)
    candidates = Dict{String,Any}()
    for candidate in something(inner.candidate_summary, Any[])
        label = "K$(candidate.rank)"
        available = Bool(candidate.eligible)
        reason = available ? nothing : something(candidate.reason, String(candidate.status))
        candidates[label] = (; parameter_count=candidate.q, aic_penalty=candidate.penalty,
            available, status=available ? "ok" : String(candidate.status),
            raw_loglik=candidate.loglik, score=candidate.criterion, error_reason=reason)
    end
    for rank in (0, 1)
        label = "K$rank"
        haskey(candidates, label) && continue
        q = rank == 0 ? 14 : 18
        candidates[label] = (; parameter_count=q, aic_penalty=2q, available=false,
            status="candidate_details_unavailable", raw_loglik=nothing, score=nothing,
            error_reason=something(inner.failure_reason, "selector did not retain candidate details"))
    end
    selector_status = hasproperty(inner, :selector_status) && inner.selector_status !== nothing ?
        String(inner.selector_status) : "not_available"
    starts_planned = hasproperty(inner, :starts_planned) ? Int(inner.starts_planned) : 0
    starts_attempted = hasproperty(inner, :starts_attempted) ? Int(inner.starts_attempted) : 0
    schedule_complete = starts_planned == 24 && starts_attempted == 24
    usable = inner.status == :ok && selector_status == "selected" &&
        schedule_complete &&
        hasproperty(inner, :selected_fit_summary) && inner.selected_fit_summary !== nothing &&
        inner.selected_rank !== nothing
    selected_fit = if usable
        (; G_matrix=Matrix{Float64}(inner.selected_fit_summary.genetic_covariance),
           R_matrix=Matrix{Float64}(inner.selected_fit_summary.residual_covariance))
    else
        nothing
    end
    status = usable ? "ok" : String(inner.status == :ok ? selector_status : inner.status)
    reason = usable ? nothing : something(inner.failure_reason,
        "bootstrap selector did not return a usable selected covariance fit")
    return (; inner_index=0, seed=UInt64(0), status,
        success=usable, failure_reason=reason,
        eligible=all(candidates[k].available for k in ("K0", "K1")),
        both_candidates_available=all(candidates[k].available for k in ("K0", "K1")),
        selector_status,
        selection_status=usable ? "selected" : selector_status == "selected" ? "unavailable" : selector_status,
        selector_reason=reason,
        starts_planned, starts_attempted, schedule_complete,
        guard_results=hasproperty(inner, :guard_results) && inner.guard_results !== nothing ?
            inner.guard_results : (; schedule_complete=nothing, better_unaccepted=nothing,
                nonnested=nothing, nesting_witness=(; status=:not_evaluated,
                    discrepancy=nothing, tolerance=1e-8)),
        selected_rank=usable ? "K$(inner.selected_rank)" : nothing,
        rank_candidates=candidates, selected_fit)
end

function _arc1_sha256_repr(value)
    # `repr(Dict)` depends on the process-local hash-table iteration order.
    # Use the Arc1 JSON projection, which sorts dictionary keys, so retained
    # diagnostic identities can be independently recomputed after deserialization.
    bytes = Vector{UInt8}(codeunits(arc1_json(value)))
    return bytes2hex(sha256(bytes))
end

function arc1_repeatability_receipt(profile)
    target_map = Dict(:additive_variance => "Va", :permanent_environment_variance => "Vpe",
                      :residual_variance => "Ve", :heritability => "h2",
                      :repeatability => "t")
    intervals = Dict{String,Any}()
    for (target, label) in target_map
        row = profile.targets[target]
        segments = row.confidence_set === nothing ? Any[] : [collect(pair) for pair in row.confidence_set]
        raw_status = String(row.status)
        allowed = ("unconverged", "nuisance_unresolved", "singular", "unbracketed",
                   "point_fit_not_optimal", "outer_fit_failed", "insufficient_usable_bootstrap",
                   "unresolved_evaluation")
        status = row.formed ? "formed" : raw_status in allowed ? raw_status : "unresolved_evaluation"
        formula = label == "h2" ? "Va/(Va+Vpe+Ve)" : label == "t" ?
            "(Va+Vpe)/(Va+Vpe+Ve)" : label
        point_ok = profile.point_fit !== nothing && profile.point_fit_status == :ok
        formed = point_ok && Bool(row.formed)
        intervals[label] = (; formed, segments=formed ? segments : Any[],
            status=formed ? "formed" : point_ok ? status : "outer_fit_failed",
            refusal_status=formed ? nothing : point_ok ? raw_status :
                "outer point fit status: $(profile.point_fit_status)", formula,
            estimate=profile.point_estimates === nothing ? nothing :
                get(profile.point_estimates, target, missing))
    end
    return (; profile_method="profile_likelihood_ratio", profile_lr_cutoff=profile.cutoff,
            profile_intervals=intervals, point_estimates=profile.point_estimates,
            profile_method_version=profile.method_version,
            point_fit_status=String(profile.point_fit_status),
            point_fit_not_optimal=Bool(profile.point_fit_not_optimal),
            point_loglik=profile.point_fit === nothing ? nothing : profile.point_fit.loglik,
            max_constrained_loglik=profile.max_constrained_loglik,
            point_identity=profile.point_identity,
            reference_point_identity=profile.reference_point_identity,
            source_identity=profile.source_identity,
            reference_source_identity=profile.reference_source_identity,
            point_fit_diagnostic_identity=_arc1_sha256_repr(profile.point_fit_candidate),
            target_diagnostics_identity=_arc1_sha256_repr(profile.targets))
end

function arc1_repeatability_result(profile)
    receipt = arc1_repeatability_receipt(profile)
    point_ok = profile.point_fit !== nothing && profile.point_fit_status == :ok
    return merge(receipt, (; success=point_ok,
        status=point_ok ? "ok" : "fit_failed",
        failure_reason=point_ok ? nothing :
            "repeatability point fit status: $(profile.point_fit_status)"))
end

function arc1_interval_receipt(engine::Module, selection, design, seed_strings, cell, outer)
    seeds = UInt64[parse(UInt64, s) for s in seed_strings]
    bootstrap = getfield(engine, :arc1_bootstrap)(selection, design.Y, design.X, design.Z,
        design.pedigree; selector=:arc1_v1, B=length(seeds), seeds, ids=design.ids,
        traits=design.traits)
    phase = cell["phase"]
    primary = phase == "pilot" ? 199 : length(seeds)
    budgets = primary == length(seeds) ? [primary] : [primary, 499, 999]
    prefixes = [getfield(engine, :_arc1_bootstrap_prefix)(bootstrap, n) for n in budgets]
    return arc1_interval_receipt_from_raw(bootstrap, prefixes, cell)
end

function arc1_interval_receipt_from_raw(bootstrap, prefixes, cell)
    seeds = UInt64.(bootstrap.requested_seeds)
    primary = cell["phase"] == "pilot" ? 199 : length(seeds)
    budgets = primary == length(seeds) ? [primary] : [primary, 499, 999]
    length(prefixes) == length(budgets) || throw(ArgumentError("raw bootstrap prefix count differs"))
    prefix_rows = [begin
        intervals = arc1_interval_rows(prefix)
        (; B=n, usable_inner=prefix.usable_bootstrap_count,
           usable_fraction=prefix.usable_bootstrap_count / n, intervals)
    end for (n, prefix) in zip(budgets, prefixes)]
    primary_prefix = only(filter(row -> row.B == primary, prefix_rows))
    inner_rows = [begin
        row = arc1_inner_rank_receipt(inner)
        merge(row, (; inner_index=i, seed=inner.seed))
    end for (i, inner) in pairs(bootstrap.attempts)]
    inner_seed_digest = bytes2hex(sha256(join((string(s, "\n") for s in seeds))))
    record = (; requested_B=primary, stage="started", refusal_status=nothing,
        inner_attempts=inner_rows, usable_inner=count(x -> x.status == :ok, bootstrap.attempts[1:primary]),
        inner_seed_sha256=inner_seed_digest, intervals=primary_prefix.intervals,
        prefix_results=prefix_rows, method="candidate_percentile_bootstrap", quantiles=[0.025, 0.975],
        failure_causes=bootstrap.failure_causes)
    return (; bootstrap=record, raw_bootstrap=bootstrap, raw_prefixes=prefixes,
            reference_audit=(; status="not_required", reason="expanded reference is not part of the FA interval gate"))
end

function arc1_profile_evidence_summary(evidence)
    evidence isa AbstractDict || return nothing
    v3_history = get(evidence, :arc1_profile_v3_evaluations, Any[])
    v4_history = get(evidence, :arc1_profile_v4_evaluations, Any[])
    history_event_count(rows) = rows isa AbstractVector ? sum(rows; init=0) do row
        events = row isa AbstractDict ? get(row, :events, Any[]) :
            hasproperty(row, :events) ? row.events : Any[]
        events isa AbstractVector ? length(events) : 0
    end : 0
    certificates_present = haskey(evidence, :v4_tail_certificates)
    certificates = get(evidence, :v4_tail_certificates, nothing)
    certificates_shape = !certificates_present ? "missing" :
        certificates isa AbstractVector ? "vector" : "malformed"
    return (; requested_method_version=get(evidence, :requested_method_version, nothing),
        actual_method_version=get(evidence, :actual_method_version, nothing),
        source_identity=get(evidence, :source_identity, nothing),
        returned_method_version=get(evidence, :returned_method_version, nothing),
        history_aliases_match=v3_history isa AbstractVector && v3_history === v4_history,
        history_row_count=v4_history isa AbstractVector ? length(v4_history) : 0,
        history_event_count=history_event_count(v4_history),
        v4_tail_certificates_shape=certificates_shape,
        v4_tail_certificates=certificates isa AbstractVector ? certificates : nothing)
end

function arc1_json_receipt(result)
    if hasproperty(result, :rank_candidates)
        return (; success=result.success, status=result.status, failure_reason=result.failure_reason,
            rank_candidates=result.rank_candidates, eligible=result.eligible,
            both_candidates_available=result.both_candidates_available,
            selection_status=result.selection_status, selection_reason=result.selection_reason,
            selected_rank=result.selected_rank, reference_audit=result.reference_audit,
            selection=result.selection, candidate_summary=result.candidate_summary,
            starts_planned=result.starts_planned, starts_attempted=result.starts_attempted,
        selector_attempts=result.selector_attempts, guard_results=result.guard_results)
    elseif hasproperty(result, :bootstrap)
        return (; success=result.success, status=result.status, failure_reason=result.failure_reason,
            outer_selection=result.outer_selection, bootstrap=result.bootstrap,
            reference_audit=result.reference_audit)
    else
        return (; success=result.success, status=result.status, failure_reason=result.failure_reason,
            profile_method=result.profile_method, profile_lr_cutoff=result.profile_lr_cutoff,
            profile_intervals=result.profile_intervals, point_estimates=result.point_estimates,
            v3_profile_evidence_summary=hasproperty(result, :v3_profile_evidence) ?
                arc1_profile_evidence_summary(result.v3_profile_evidence) : nothing,
            profile_method_version=result.profile_method_version,
            point_fit_status=result.point_fit_status,
            point_fit_not_optimal=result.point_fit_not_optimal,
            point_loglik=result.point_loglik,
            max_constrained_loglik=result.max_constrained_loglik,
            point_identity=result.point_identity,
            reference_point_identity=result.reference_point_identity,
            source_identity=result.source_identity,
            reference_source_identity=result.reference_source_identity,
            point_fit_diagnostic_identity=result.point_fit_diagnostic_identity,
            target_diagnostics_identity=result.target_diagnostics_identity)
    end
end

"""Separate canonical compact summaries from legacy full-history diagnostics."""
function arc1_inspector_receipt_projection(summary)
    summary === nothing && return (; status="missing", qualifiable=false,
        receipt_summary=nothing, diagnostic_summary=nothing)
    if hasproperty(summary, :v3_profile_evidence)
        diagnostic = arc1_json_receipt(summary)
        if hasproperty(summary, :requested_profile_method_version)
            diagnostic = merge(diagnostic, (; requested_profile_method_version=
                summary.requested_profile_method_version))
        end
        return (; status="legacy_full_history_diagnostic_only", qualifiable=false,
            receipt_summary=nothing, diagnostic_summary=diagnostic)
    end
    return (; status="canonical_compact", qualifiable=true,
        receipt_summary=summary, diagnostic_summary=nothing)
end

function arc1_raw_result_projection_difference(payload, result, metadata)
    if hasproperty(result, :rank_candidates)
        hasproperty(payload, :raw_selection) || return "retained FA rank result lacks raw selector"
        selection = payload.raw_selection
        audit = result.reference_audit
        if hasproperty(payload, :reference_raw) && payload.reference_raw !== nothing
            projected_audit = arc1_reference_audit_from_raw(selection, payload.reference_raw)
            arc1_json(projected_audit) == arc1_json(audit) || return "reference audit differs from raw reference"
            audit = projected_audit
        elseif hasproperty(audit, :status) && audit.status == "best_found"
            return "successful reference audit lacks raw reference"
        end
        return arc1_json(arc1_json_receipt(arc1_fa_rank_result(selection, audit))) ==
               arc1_json(arc1_json_receipt(result)) ? nothing : "FA rank receipt differs from raw selector/reference"
    elseif hasproperty(result, :bootstrap)
        hasproperty(payload, :raw_selection) || return "FA interval result lacks raw outer selector"
        selection = payload.raw_selection
        # Expanded reference is never scheduled for interval cells. The nested
        # outer-selector audit has a different meaning from the interval
        # result's top-level reference_audit field, so reconstruct its exact
        # fixed not-required row and bind the digest to retained metadata.
        outer_reference = (; status="not_required",
            reason="attempt is outside the preselected and frozen flag set",
            dataset_identity=metadata.data_identity_sha256)
        selection_row = arc1_rank_receipt(selection; reference_audit=outer_reference)
        arc1_json(selection_row) == arc1_json(result.outer_selection) ||
            return "FA interval outer-selection receipt differs from raw selector"
        if hasproperty(payload, :bootstrap_raw) && hasproperty(payload, :prefix_raw)
            raw_receipt = arc1_interval_receipt_from_raw(payload.bootstrap_raw,
                payload.prefix_raw, metadata.cell)
            projected = merge((; outer_selection=selection_row), raw_receipt,
                (; success=true, status="ok", failure_reason=nothing))
            return arc1_json(arc1_json_receipt(projected)) ==
                   arc1_json(arc1_json_receipt(result)) ? nothing :
                   "FA interval receipt differs from raw bootstrap attempts/prefixes"
        end
        valid_refusal = result.success === false && result.status == "selection_failed" &&
               result.bootstrap.stage == "not_started" &&
               selection.selection_status != :selected
        return valid_refusal ? nothing : "FA interval refusal lacks matching pre-start selector failure"
    elseif hasproperty(payload, :profile)
        projected = arc1_repeatability_result(payload.profile)
        # The serialized result receipt includes the retained v3 evidence
        # sink. Reconstruct that field from the raw artifact as well, rather
        # than comparing an incomplete projection to the transported receipt.
        projected_evidence = hasproperty(payload, :v3_profile_evidence) ?
            payload.v3_profile_evidence : nothing
        retained_evidence = hasproperty(result, :v3_profile_evidence) ?
            result.v3_profile_evidence : nothing
        isequal(projected_evidence, retained_evidence) ||
            return "repeatability receipt differs from raw profile"
        projected = merge(projected, (; v3_profile_evidence=projected_evidence))
        return arc1_json(arc1_json_receipt(projected)) ==
               arc1_json(arc1_json_receipt(result)) ? nothing : "repeatability receipt differs from raw profile"
    end
    return "retained artifact does not contain the raw output for its result programme"
end

arc1_raw_result_matches_derived_receipt(payload, result, metadata) =
    arc1_raw_result_projection_difference(payload, result, metadata) === nothing

function arc1_reference_scale_matches_retained_y(payload, result)
    audit = hasproperty(result, :reference_audit) ? result.reference_audit : nothing
    audit === nothing && return true
    hasproperty(audit, :status) && audit.status == "best_found" || return true
    hasproperty(payload, :data) && hasproperty(payload, :design) &&
        hasproperty(payload, :reference_raw) && payload.reference_raw !== nothing || return false
    expected = diag(arc1_reference_phenotypic_covariance(payload.design.Y, payload.design.X))
    raw = payload.reference_raw
    hasproperty(raw, :phenotypic_variances) || return false
    hasproperty(audit, :phenotypic_variances) || return false
    length(expected) == length(raw.phenotypic_variances) == length(audit.phenotypic_variances) == 4 ||
        return false
    all(isapprox(Float64(expected[i]), Float64(raw.phenotypic_variances[i]);
                 rtol=1e-12, atol=1e-15) for i in 1:4) || return false
    all(isapprox(Float64(expected[i]), Float64(audit.phenotypic_variances[i]);
                 rtol=1e-12, atol=1e-15) for i in 1:4)
end

function arc1_execute_attempt(engine::Module, loaded_engine,
                               engine_hashes::Dict{String,String},
                               environment_hashes::Dict{String,String},
                               cell::Dict{String,Any}, outer::Int, seed::UInt64,
                               bootstrap_seed_strings::Vector{String},
                               requested_profile_method_version::Union{Nothing,String};
                               v3_evidence_sink=nothing)
    programme = cell["programme"]
    n = Int(cell["N"])
    started = time_ns()
    if programme in ("fa_rank", "fa_interval")
        rho = Dict("null" => 0.0, "weak" => 0.15, "strong" => 0.70)[cell["signal"]]
        data = arc1_simulate_fa(seed, n, rho)
        design = arc1_fa_design(engine, data)
        selection = getfield(engine, :select_fa_rank)(design.Y, design.X, design.Z,
            design.pedigree; ids=design.ids, traits=design.traits, optimizer_policy="arc1_v1")
        data_hash = arc1_data_identity(data)
        raw_reference = Ref{Any}(nothing)
        reference_audit = if arc1_reference_required(selection, cell, outer)
            try
                arc1_rank_reference_receipt(engine, selection, design, data_hash;
                    raw_reference_sink=raw_reference)
            catch err
                err isa InterruptException && rethrow()
                (; status="error", reason=sprint(showerror, err), dataset_identity=data_hash,
                   rows=Any[], starts_planned=Dict("K0" => 0, "K1" => 0),
                   rank_comparisons=Dict{String,Any}())
            end
        else
            (; status="not_required", reason="attempt is outside the preselected and frozen flag set",
               dataset_identity=data_hash)
        end
        result = if programme == "fa_rank"
            arc1_fa_rank_result(selection, reference_audit)
        else
            selection_row = arc1_rank_receipt(selection; reference_audit)
            if selection.selection_status != :selected || selection.selected_fit === nothing
                primary = cell["phase"] == "pilot" ? 199 : length(bootstrap_seed_strings)
                failed_intervals = Dict("h2_$i" => (; formed=false, segments=Any[],
                    status="outer_fit_failed", refusal_status="outer selector did not return an eligible selected fit",
                    formula="G_$(i)$(i)/(G_$(i)$(i)+R_$(i)$(i))") for i in 1:4)
                (; outer_selection=selection_row, success=false, status="selection_failed",
                   failure_reason="outer selector did not return an eligible selected fit",
                   bootstrap=(; stage="not_started", refusal_status=String(selection.selection_status),
                              requested_B=primary, inner_attempts=Any[], usable_inner=0,
                              intervals=failed_intervals), intervals=failed_intervals,
                   reference_audit=(; status="not_required",
                       reason="expanded reference is only scheduled for FA rank study cells"))
            else
                merge((; outer_selection=selection_row),
                    arc1_interval_receipt(engine, selection, design, bootstrap_seed_strings, cell, outer),
                    (; success=true, status="ok", failure_reason=nothing))
            end
        end
        model = programme == "fa_interval" && hasproperty(result, :raw_bootstrap) ?
            (; data, design, raw_selection=selection, result, bootstrap_raw=result.raw_bootstrap,
               prefix_raw=result.raw_prefixes) :
            (; data, design, raw_selection=selection, result, reference_raw=raw_reference[])
        kind = programme == "fa_rank" ? "fa_rank" : "fa_interval"
    elseif programme in ("repeatability", "boundary")
        requested_profile_method_version == "arc1_profile_v4" ||
            throw(ArgumentError("profile attempt must explicitly request arc1_profile_v4"))
        data = arc1_simulate_repeatability(seed, n, Symbol(cell["signal"]))
        design = arc1_repeatability_design(engine, data)
        profile = getfield(engine, :arc1_profile_repeatability)(design.y, design.X,
            design.Z, design.pedigree; ids=design.ids,
            method=requested_profile_method_version,
            v3_evidence_sink)
        actual_version = hasproperty(profile, :method_version) ?
            string(profile.method_version) : nothing
        v3_evidence_sink[:returned_method_version] = actual_version
        actual_version == requested_profile_method_version ||
            throw(ArgumentError("profile engine returned a method version different from the admitted request"))
        result = merge(arc1_repeatability_result(profile),
            (; v3_profile_evidence=v3_evidence_sink))
        model = (; data, design, profile, result,
                 v3_profile_evidence=v3_evidence_sink)
        kind = "repeatability"
    else
        throw(ArgumentError("unsupported Arc1 programme: $(repr(programme))"))
    end
    elapsed = (time_ns() - started) / 1e9
    identity = arc1_execution_identity(loaded_engine, engine_hashes, environment_hashes)
    data_hash = arc1_data_identity(model.data)
    semantic_data_hash = arc1_semantic_data_identity(model.data, model.design)
    success = hasproperty(result, :success) ? result.success : true
    status = hasproperty(result, :status) ? result.status : "ok"
    failure_reason = hasproperty(result, :failure_reason) ? result.failure_reason : nothing
    return (; success, status, failure_reason, result_kind=kind,
            outer, seed, seed_string=string(seed), observed_ids=model.data.observed_ids,
            record_ids=hasproperty(model.data, :record_ids) ? model.data.record_ids : String[],
            record_animal_ids=hasproperty(model.data, :record_animal_ids) ? model.data.record_animal_ids : String[],
            truth=model.data.truth, data_identity_sha256=data_hash,
            semantic_data_identity_sha256=semantic_data_hash,
            data_identity_method=ARC1_DATA_IDENTITY_METHOD, elapsed_seconds=elapsed,
            execution_identity=identity, result=model.result, artifact_payload=model)
end

# Different Windows volumes yield an absolute result from `relpath`.
function arc1_output_relative_disjoint(relative::AbstractString)
    parts = splitpath(relative)
    return isabspath(relative) || (!isempty(parts) && first(parts) == "..")
end

if abspath(PROGRAM_FILE) == @__FILE__
    config_path = abspath(ARGS[1])
    config = TOML.parsefile(config_path)
    root = realpath(config["source_root"])
    output_root = realpath(config["attempt_output"])
    rel_output = relpath(output_root, root)
    arc1_output_relative_disjoint(rel_output) ||
        error("Arc1 output directory must be disjoint from the source root")
    global engine_hashes = Dict{String,String}(String(k) => String(v) for (k,v) in config["engine_hashes"])
    global environment_hashes = Dict{String,String}(String(k) => String(v) for (k,v) in config["environment_hashes"])
    global driver_protocol_identity = (; source_sha256=Dict{String,String}(
        String(k) => String(v) for (k,v) in config["source_hashes"]),
        protocol_sha256=String(config["protocol_sha256"]),
        environment_sha256=copy(environment_hashes))
    include(joinpath(root, "sim", "arc1", "execution_identity.jl"))
    loaded_engine = arc1_load_admitted_engine(root, engine_hashes, environment_hashes)
    BLAS.set_num_threads(Int(config["blas_threads"]))
    loaded_engine.active_project == realpath(joinpath(root, "Project.toml")) || error("active project mismatch")
    global engine = loaded_engine.module_object
    include(joinpath(root, "sim", "arc1", "independent_dgp.jl"))
    include(joinpath(root, "sim", "arc1", "engine_io.jl"))
    include(joinpath(root, "sim", "arc1", "artifact_container.jl"))
    pre_identity = arc1_execution_identity(loaded_engine, engine_hashes, environment_hashes)
    requested_profile_method_version = isempty(String(get(config, "profile_method_version", ""))) ?
        nothing : String(config["profile_method_version"])
    v3_evidence_sink = requested_profile_method_version in ("arc1_profile_v3", "arc1_profile_v4") ?
        Dict{Symbol,Any}(:requested_method_version => requested_profile_method_version) : nothing
    try
        cell = Dict{String,Any}(String(k) => v for (k,v) in config["cell"])
        seed = parse(UInt64, String(config["seed"]))
        bootstrap_seed_strings = String[String(s) for s in get(config, "bootstrap_seeds", String[])]
        profile_programme = config["cell"]["programme"] in ("repeatability", "boundary")
        profile_programme == (requested_profile_method_version !== nothing) ||
            error("profile method admission pin does not match the requested programme")
        profile_programme && requested_profile_method_version != "arc1_profile_v4" &&
            error("profile attempt requires explicit arc1_profile_v4")
        summary = arc1_execute_attempt(engine, loaded_engine, engine_hashes, environment_hashes,
            cell, Int(config["outer"]), seed, bootstrap_seed_strings,
            requested_profile_method_version; v3_evidence_sink)
        post_identity = arc1_execution_identity(loaded_engine, engine_hashes, environment_hashes)
        pre_identity == post_identity || error("runtime identity changed during Arc1 outer attempt")
        receipt_summary = merge(arc1_json_receipt(summary.result),
            (; requested_profile_method_version))
        receipt_summary_path = String(config["artifact_path"]) * ".summary.json"
        receipt_summary_text = arc1_json(receipt_summary) * "\n"
        receipt_summary_sha = arc1_write_text_new(receipt_summary_path, receipt_summary_text)
        actual_profile_method_version_value = hasproperty(summary.result, :profile_method_version) ?
            string(summary.result.profile_method_version) : nothing
        profile_method_version_mismatch = requested_profile_method_version !== nothing &&
            actual_profile_method_version_value != requested_profile_method_version
        artifact_metadata = (; schema="arc1-full-result-v2",
            mode=String(config["mode"]), cell, outer=summary.outer,
            seed_string=summary.seed_string, julia_version=string(VERSION),
            execution_identity=post_identity, timing_seconds=summary.elapsed_seconds,
            driver_protocol_identity,
            data_identity_sha256=summary.data_identity_sha256,
            semantic_data_identity_sha256=summary.semantic_data_identity_sha256,
            data_identity_method=summary.data_identity_method,
            requested_profile_method_version,
            profile_method_version_mismatch,
            profile_method_version=actual_profile_method_version_value,
            loaded_arc1_source_identity=string(getfield(loaded_engine.module_object, :_ARC1_SOURCE_IDENTITY)),
            receipt_summary_sha256=receipt_summary_sha,
            receipt_summary_path=receipt_summary_path)
        artifact = merge(summary.artifact_payload,
            (; metadata=artifact_metadata, receipt_summary), receipt_summary)
        artifact_sha = arc1_write_artifact_container_new(config["artifact_path"], artifact)
        receipt = (; schema="arc1-attempt-result-v1", mode=String(config["mode"]),
            success=summary.success, status=summary.status, failure_reason=summary.failure_reason,
            outer=summary.outer, seed=summary.seed,
            seed_string=summary.seed_string, result_kind=summary.result_kind,
            data_identity_sha256=summary.data_identity_sha256,
            semantic_data_identity_sha256=summary.semantic_data_identity_sha256,
            data_identity_method=summary.data_identity_method,
            requested_profile_method_version,
            profile_method_version_mismatch,
            profile_method_version=actual_profile_method_version_value,
            profile_source_identity=hasproperty(summary.result, :source_identity) ?
                summary.result.source_identity : nothing,
            artifact_path=String(config["artifact_path"]),
            artifact_sha256=artifact_sha, elapsed_seconds=summary.elapsed_seconds,
            observed_ids=summary.observed_ids, record_ids=summary.record_ids,
            record_animal_ids=summary.record_animal_ids, truth=summary.truth,
            execution_identity=post_identity, result=receipt_summary,
            receipt_summary_path, receipt_summary_sha256=receipt_summary_sha)
        projection_error = arc1_emit_receipt(receipt; fallback_fields=(;
            preserve_original_error=false, mode=String(config["mode"]),
            outer=summary.outer, seed_string=summary.seed_string, status=summary.status,
            failure_reason=summary.failure_reason, error_type="",
            requested_profile_method_version,
            profile_method_version=actual_profile_method_version_value,
            profile_method_version_mismatch,
            profile_source_identity=hasproperty(summary.result, :source_identity) ?
                summary.result.source_identity : nothing,
            loaded_arc1_source_identity=string(getfield(loaded_engine.module_object, :_ARC1_SOURCE_IDENTITY)),
            artifact_path=String(config["artifact_path"]), artifact_sha256=artifact_sha,
            retention_error=nothing))
        projection_error === nothing || exit(2)
        summary.success || exit(2)
    catch error
        after_error_identity = try arc1_execution_identity(loaded_engine, engine_hashes, environment_hashes) catch; nothing end
        failure_status = error isa InterruptException ? "interrupted" : "error"
        failure_reason = sprint(showerror, error)
        actual_profile_method_version = v3_evidence_sink === nothing ? nothing :
            get(v3_evidence_sink, :returned_method_version,
                get(v3_evidence_sink, :actual_method_version, nothing))
        profile_method_version_mismatch = v3_evidence_sink !== nothing &&
            haskey(v3_evidence_sink, :returned_method_version) &&
            actual_profile_method_version != requested_profile_method_version
        evidence_retention_error = nothing
        failure_artifact = (; metadata=(; schema="arc1-full-result-v2",
            mode=String(config["mode"]), cell=config["cell"], outer=Int(config["outer"]),
            seed_string=String(config["seed"]), julia_version=string(VERSION),
            requested_profile_method_version=String(get(config, "profile_method_version", "")) == "" ?
                nothing : String(config["profile_method_version"]),
            profile_method_version_mismatch,
            profile_method_version=actual_profile_method_version,
            loaded_arc1_source_identity=string(getfield(loaded_engine.module_object, :_ARC1_SOURCE_IDENTITY)),
            execution_identity=after_error_identity, status=failure_status,
            driver_protocol_identity,
            failure_reason, timing_seconds=nothing),
            v3_profile_evidence=v3_evidence_sink,
            error=(; type=string(typeof(error)), message=failure_reason,
                   backtrace=string.(Base.stacktrace(catch_backtrace()))))
        failure_artifact_sha = try
            arc1_write_artifact_container_new(config["artifact_path"], failure_artifact)
        catch retention_error
            evidence_retention_error = sprint(showerror, retention_error)
            nothing
        end
        if failure_artifact_sha === nothing && v3_evidence_sink !== nothing
            # Keep the original error and status if a malformed sink cannot be
            # serialized. The receipt reports that evidence retention failed.
            fallback = (; metadata=merge(failure_artifact.metadata,
                    (; v3_evidence_retention_error=evidence_retention_error)),
                v3_profile_evidence_raw=v3_evidence_sink,
                error=failure_artifact.error)
            failure_artifact_sha = try
                arc1_write_artifact_container_new(config["artifact_path"], fallback)
            catch fallback_error
                evidence_retention_error = string(evidence_retention_error,
                    "; fallback artifact: ", sprint(showerror, fallback_error))
                nothing
            end
        end
        failure = (; schema="arc1-attempt-result-v1", mode=String(config["mode"]), success=false,
            status=failure_status,
            outer=Int(config["outer"]), seed_string=String(config["seed"]),
            requested_profile_method_version=String(get(config, "profile_method_version", "")) == "" ?
                nothing : String(config["profile_method_version"]),
            profile_method_version_mismatch,
            profile_method_version=actual_profile_method_version,
            profile_source_identity=v3_evidence_sink === nothing ? nothing :
                get(v3_evidence_sink, :source_identity, nothing),
            v3_profile_evidence_summary=arc1_profile_evidence_summary(v3_evidence_sink),
            v3_evidence_retention_error=evidence_retention_error,
            failure_reason, execution_identity=after_error_identity,
            artifact_path=String(config["artifact_path"]), artifact_sha256=failure_artifact_sha,
            error_type=string(typeof(error)))
        arc1_emit_receipt(failure; fallback_fields=(;
            preserve_original_error=true, mode=String(config["mode"]),
            outer=Int(config["outer"]), seed_string=String(config["seed"]),
            status=failure_status,
            failure_reason, error_type=string(typeof(error)),
            requested_profile_method_version=String(get(config, "profile_method_version", "")) == "" ?
                nothing : String(config["profile_method_version"]),
            profile_method_version=actual_profile_method_version,
            profile_method_version_mismatch,
            profile_source_identity=v3_evidence_sink === nothing ? nothing :
                get(v3_evidence_sink, :source_identity, nothing),
            v3_profile_evidence_summary=arc1_profile_evidence_summary(v3_evidence_sink),
            loaded_arc1_source_identity=after_error_identity === nothing ? nothing :
                string(getfield(loaded_engine.module_object, :_ARC1_SOURCE_IDENTITY)),
            artifact_path=String(config["artifact_path"]), artifact_sha256=failure_artifact_sha,
            retention_error=evidence_retention_error))
        exit(2)
    end
end

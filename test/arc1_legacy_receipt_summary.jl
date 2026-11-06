module Arc1LegacyReceiptSummaryRegression
using Test

include(joinpath(@__DIR__, "..", "sim", "arc1", "execute_attempt.jl"))
include(joinpath(@__DIR__, "..", "sim", "arc1", "engine_io.jl"))

@testset "Arc1 legacy profile receipt summary stays compact at inspection" begin
    event_count = 10_000
    events = [Dict{Symbol,Any}(:event_index => i,
        :diagnostic => repeat("legacy-profile-event-", 3)) for i in 1:event_count]
    history = [Dict{Symbol,Any}(:target => :additive_variance, :events => events)]
    evidence = Dict{Symbol,Any}(
        :requested_method_version => "arc1_profile_v4",
        :actual_method_version => "arc1_profile_v4",
        :source_identity => repeat("a", 64),
        :arc1_profile_v3_evaluations => history,
        :arc1_profile_v4_evaluations => history,
        :v4_tail_certificates => Any[])
    legacy_summary = (
        success=true, status="ok", failure_reason=nothing,
        profile_method="arc1_profile_v4", profile_lr_cutoff=3.841458820694124,
        profile_intervals=(additive_variance=(0.0, 0.8),),
        point_estimates=(additive_variance=0.3,),
        requested_profile_method_version="arc1_profile_v4",
        v3_profile_evidence=evidence,
        profile_method_version="arc1_profile_v4", point_fit_status="ok",
        point_fit_not_optimal=false, point_loglik=-10.0,
        max_constrained_loglik=-11.0,
        point_identity=repeat("b", 64), reference_point_identity=repeat("c", 64),
        source_identity=repeat("a", 64), reference_source_identity=repeat("a", 64),
        point_fit_diagnostic_identity=repeat("d", 64),
        target_diagnostics_identity="legacy-process-order-dependent-hash")

    projection = arc1_inspector_receipt_projection(legacy_summary)
    inspected_json = arc1_json(projection.diagnostic_summary)
    @test arc1_profile_evidence_summary(evidence).history_event_count == event_count
    @test ncodeunits(inspected_json) < 50_000
    @test projection.status == "legacy_full_history_diagnostic_only"
    @test !projection.qualifiable
    @test projection.receipt_summary === nothing
    @test projection.diagnostic_summary.v3_profile_evidence_summary.history_event_count == event_count
    @test projection.diagnostic_summary.requested_profile_method_version ==
        "arc1_profile_v4"
    @test projection.diagnostic_summary.target_diagnostics_identity ==
        "legacy-process-order-dependent-hash"

    changed_events = deepcopy(events)
    changed_events[1][:diagnostic] = "changed while preserving event count"
    changed_row = copy(history[1])
    changed_row[:events] = changed_events
    changed_history = [changed_row]
    changed_evidence = copy(evidence)
    changed_evidence[:arc1_profile_v3_evaluations] = changed_history
    changed_evidence[:arc1_profile_v4_evaluations] = changed_history
    changed_legacy_summary = merge(legacy_summary,
        (; v3_profile_evidence=changed_evidence))
    changed_projection = arc1_inspector_receipt_projection(changed_legacy_summary)
    @test changed_projection.status == "legacy_full_history_diagnostic_only"
    @test !changed_projection.qualifiable
end
end

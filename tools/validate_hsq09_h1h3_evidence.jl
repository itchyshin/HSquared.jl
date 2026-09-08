#!/usr/bin/env julia
#
# Deterministic self-test for the private A2 H1/H3 retained-evidence
# adjudicator.  It does not read evidence, start a campaign, or fit a model.

include(joinpath(@__DIR__, "..", "sim", "phase1_interval_coverage_ext.jl"))

function _a2_assert(condition::Bool, label::AbstractString)
    condition || error("A2 self-test failed: $(label)")
    return nothing
end

function _a2_summary(; scheduled_reps = 100, interval_success = 100,
                     covered = 95, role = "covered_pillar_bank",
                     evidence_missing = false, immutable_failure = false,
                     per_task_rate = nothing)
    return (
        scheduled_reps = scheduled_reps,
        interval_success = interval_success,
        covered = covered,
        role = role,
        evidence_missing = evidence_missing,
        immutable_failure = immutable_failure,
        per_task_rate = per_task_rate,
    )
end

function _a2_verdict(summary; lower_band = 0.93, upper_band = 0.97)
    return _adjudicate_h1h3(summary; lower_band = lower_band, upper_band = upper_band)
end

function _a2_expect(summary, expected::Symbol; lower_band = 0.93, upper_band = 0.97)
    result = _a2_verdict(summary; lower_band = lower_band, upper_band = upper_band)
    _a2_assert(result.verdict === expected, "expected $(expected), got $(result.verdict)")
    _a2_assert(result.promotable === false, "A2 adjudication must never promote")
    return result
end

function _a2_expect_error(thunk, label::AbstractString)
    try
        thunk()
    catch err
        err isa ErrorException || rethrow()
        return nothing
    end
    error("A2 mutation was accepted: $(label)")
end

function _self_test()
    # Positive classification rows plus paired mutations at each material
    # decision boundary.  The paired result must differ, so a collapsed or
    # reordered predicate cannot pass silently.
    _a2_expect(_a2_summary(), :calibrated_candidate)
    _a2_expect(_a2_summary(immutable_failure = true), :hold)
    _a2_expect(_a2_summary(evidence_missing = true), :hold)
    _a2_expect(_a2_summary(interval_success = 89, covered = 85), :hold)
    _a2_expect(_a2_summary(interval_success = 90, covered = 85), :calibrated_candidate)
    _a2_expect(_a2_summary(role = "characterization_only"), :characterization_only)
    _a2_expect(_a2_summary(covered = 100), :hold)
    _a2_expect(_a2_summary(covered = 99), :directional_conservative)
    _a2_expect(_a2_summary(covered = 89), :experimental)

    # The 0.90 threshold is separate from the declared calibration band.
    _a2_expect(_a2_summary(covered = 90), :experimental;
               lower_band = 0.90, upper_band = 0.97)
    _a2_expect(_a2_summary(covered = 91), :calibrated_candidate;
               lower_band = 0.90, upper_band = 0.97)
    _a2_expect(_a2_summary(covered = 93), :experimental)
    _a2_expect(_a2_summary(covered = 94), :calibrated_candidate)
    _a2_expect(_a2_summary(covered = 97), :directional_conservative)
    _a2_expect(_a2_summary(covered = 96), :calibrated_candidate)

    # `per_task_rate` is deliberately a decoy.  Pooled counts, rather than
    # mean(0/1, 100/100) == 0.5, determine this 100/101 outcome.
    pooled = _a2_expect(_a2_summary(
        scheduled_reps = 101,
        interval_success = 101,
        covered = 100,
        per_task_rate = 0.5,
    ), :directional_conservative)
    _a2_assert(pooled.coverage == 100 / 101, "pooled counts were not used")

    # Mutation controls for undefined or inconsistent retained counts.
    _a2_expect_error(() -> _a2_verdict((;
        scheduled_reps = 100, interval_success = 100, covered = missing,
        role = "covered_pillar_bank", evidence_missing = false,
        immutable_failure = false,
    )), "missing covered count")
    _a2_expect_error(() -> _a2_verdict((;
        scheduled_reps = 100, interval_success = 101, covered = 100,
        role = "covered_pillar_bank", evidence_missing = false,
        immutable_failure = false,
    )), "interval denominator above scheduled count")
    _a2_expect_error(() -> _a2_verdict((;
        scheduled_reps = 100, interval_success = 100, covered = 95,
        role = "unreviewed_role", evidence_missing = false,
        immutable_failure = false,
    )), "unadmitted role")
    return nothing
end

function main(args = ARGS)
    isempty(args) || args == ["--self-test"] ||
        error("only --self-test is supported by this deterministic A2 tool")
    _self_test()
    println("A2_EVIDENCE_INFRA_TESTS_OK")
    println("A2_MUTATION_CONTROLS_OK")
    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

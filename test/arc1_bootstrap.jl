using Test
using LinearAlgebra
using Random
using SHA
using HSquared

# The implementation remains a separately reviewed candidate until the
# package module include and public method dispatch are integrated.
isdefined(HSquared, :_arc1_bootstrap) ||
    Base.include(HSquared, joinpath(@__DIR__, "..", "src", "arc1_bootstrap.jl"))

const _BOOT_IDS = ["a1", "a2", "a3", "a4", "a5", "a6"]
const _BOOT_PED = normalize_pedigree(_BOOT_IDS, fill("0", 6), fill("0", 6))
const _BOOT_Y = reshape(collect(1.0:24.0), 6, 4)
const _BOOT_X = ones(6, 1)
const _BOOT_Z = Matrix{Float64}(I, 6, 6)
const _BOOT_TRAITS = ["t1", "t2", "t3", "t4"]
const _BOOT_G = Matrix{Float64}(I, 4, 4)
const _BOOT_R = Matrix{Float64}(I, 4, 4)
const _BOOT_BETA = zeros(1, 4)

function _bootstrap_test_selection(Y = _BOOT_Y)
    Ym, Xm, Zm = Matrix{Float64}(Y), Matrix{Float64}(_BOOT_X), Matrix{Float64}(_BOOT_Z)
    A = HSquared._arc1_bootstrap_relationship(_BOOT_PED)
    fit = (; genetic_covariance = _BOOT_G, residual_covariance = _BOOT_R,
        beta = _BOOT_BETA, fa_start_diagnostics = (; fixed_rank_request = nothing,
            source_identity = HSquared._ARC1_SOURCE_IDENTITY,
            optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
            starts_planned = 19, starts_attempted = 19))
    return (; selection_status = :selected, selected_rank = 0,
        selected_fit = fit, source_identity = HSquared._ARC1_SOURCE_IDENTITY,
        guard_results = (; schedule_complete = true, better_unaccepted = false,
            nonnested = false, nesting_witness = (; status = :passed,
                discrepancy = 0.0, tolerance = 1e-4)),
        optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
        starts_planned = 19, starts_attempted = 19,
        design_fingerprint = HSquared._arc1_bootstrap_design_fingerprint(
            Ym, Xm, Zm, _BOOT_TRAITS, _BOOT_PED.ids),
        relationship_fingerprint = bytes2hex(SHA.sha256(repr(A))))
end

function _bootstrap_fake_selector(counter; fail_at = nothing, interrupt_at = nothing,
                                   return_interrupt_at = nothing,
                                   wrong_identity_at = nothing, k0_fail_at = nothing,
                                   response_seen = nothing, corrupt_at = nothing)
    return function (Y, X, Z, pedigree; ids, traits, kwargs...)
        counter[] += 1
        @test keys(kwargs) == (:ledger_sink,)
        kwargs[:ledger_sink][] = (; candidate_summary = [(rank = 0,)],
                                   attempts = [(status = :running,)])
        @test X == _BOOT_X
        @test Z == _BOOT_Z
        @test ids == _BOOT_PED.ids
        @test traits == _BOOT_TRAITS
        response_seen === nothing || (response_seen[] = copy(Y))
        counter[] == interrupt_at && throw(InterruptException())
        if counter[] == return_interrupt_at
            partial_attempts = [(start_id = "start-$i", attempted = true,
                status = i == 5 ? :running : :ok, score = Float64(i)) for i in 1:5]
            partial_ledger = (; candidate_summary = [(rank = 0,)],
                starts_attempted = length(partial_attempts), attempts = partial_attempts,
                guard_results = (; schedule_complete = false, better_unaccepted = false,
                    nonnested = false, nesting_witness = (; status = :unavailable,
                        discrepancy = nothing, tolerance = 1e-4)))
            kwargs[:ledger_sink][] = partial_ledger
            A = HSquared._arc1_bootstrap_relationship(pedigree)
            return (; selection_status = :interrupted, reason = "controlled returned interruption",
                selected_rank = nothing, selected_fit = nothing,
                candidate_summary = partial_ledger.candidate_summary, attempts = partial_attempts,
                guard_results = partial_ledger.guard_results,
                source_identity = HSquared._ARC1_SOURCE_IDENTITY,
                optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
                starts_planned = 19, starts_attempted = 0,
                design_fingerprint = HSquared._arc1_bootstrap_design_fingerprint(
                    Matrix{Float64}(Y), Matrix{Float64}(X), Matrix{Float64}(Z), traits, ids),
                relationship_fingerprint = bytes2hex(SHA.sha256(repr(A))))
        end
        counter[] == fail_at && error("controlled fit failure")
        A = HSquared._arc1_bootstrap_relationship(pedigree)
        if counter[] == k0_fail_at
            return (; selection_status = :not_selected, selected_rank = nothing,
                selected_fit = nothing, reason = "K0 optimizer failure",
                guard_results = (; schedule_complete = false, better_unaccepted = false,
                    nonnested = false, nesting_witness = (; status = :unavailable,
                        discrepancy = nothing, tolerance = 1e-4)),
                source_identity = HSquared._ARC1_SOURCE_IDENTITY,
                optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
                starts_planned = 19, starts_attempted = 3,
                design_fingerprint = HSquared._arc1_bootstrap_design_fingerprint(
                    Matrix{Float64}(Y), Matrix{Float64}(X), Matrix{Float64}(Z), traits, ids),
                relationship_fingerprint = bytes2hex(SHA.sha256(repr(A))))
        end
        value = 0.1 * counter[]
        G = Matrix(Diagonal(fill(value, 4)))
        R = Matrix(Diagonal(fill(1 - value, 4)))
        if counter[] == corrupt_at
            G[1, 2] = G[2, 1] = 2.0
        end
        fit = (; genetic_covariance = G, residual_covariance = R,
            beta = _BOOT_BETA,
            fa_start_diagnostics = (; fixed_rank_request = nothing,
                source_identity = HSquared._ARC1_SOURCE_IDENTITY,
                optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
                starts_planned = 19, starts_attempted = 19))
        return (; selection_status = :selected, selected_rank = isodd(counter[]) ? 0 : 1,
            selected_fit = fit, source_identity = counter[] == wrong_identity_at ? "wrong" :
                HSquared._ARC1_SOURCE_IDENTITY,
            guard_results = (; schedule_complete = true, better_unaccepted = false,
                nonnested = false, nesting_witness = (; status = :passed,
                    discrepancy = 0.0, tolerance = 1e-4)),
            optimizer_policy = "arc1_v1", optimizer_policy_version = 1,
            starts_planned = 19, starts_attempted = 19,
            design_fingerprint = HSquared._arc1_bootstrap_design_fingerprint(
                Matrix{Float64}(Y), Matrix{Float64}(X), Matrix{Float64}(Z), traits, ids),
            relationship_fingerprint = bytes2hex(SHA.sha256(repr(A))))
    end
end

@testset "ARC1 fixed-B selector-repeating h² bootstrap" begin
    seeds = UInt64[0x10, 0x20, 0x30]
    selection = _bootstrap_test_selection()
    counter = Ref(0)
    result = HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds, ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(counter))

    @test counter[] == length(seeds) # every fixed attempt reruns the whole callback
    @test result.requested_seeds == seeds
    @test result.point_fit === selection.selected_fit
    @test result.point_estimates == fill(0.5, 4)
    @test result.requested_bootstrap_count == 3
    @test result.usable_bootstrap_count == 3
    @test all(attempt.guard_results.schedule_complete for attempt in result.attempts)
    @test all(attempt.guard_results.nesting_witness.status == :passed for attempt in result.attempts)
    @test result.required_usable_count == 3
    @test result.formed
    @test result.calibration_status == :unverified
    @test result.rank_frequencies == Dict(0 => 2, 1 => 1)
    @test all(a -> a.starts_planned == 19 && a.starts_attempted == 19, result.attempts)
    @test [a.seed for a in result.attempts] == seeds
    @test result.intervals[1].lower ≈ 0.105 # type-7 over 0.1, 0.2, 0.3
    @test result.intervals[1].upper ≈ 0.295

    prefix = HSquared._arc1_bootstrap_prefix(result, 2)
    @test prefix.requested_bootstrap_count == 2
    @test prefix.usable_bootstrap_count == 2
    @test prefix.formed
    @test prefix.intervals[1].lower ≈ 0.1025
    @test prefix.intervals[1].upper ≈ 0.1975
    @test result.requested_bootstrap_count == 3 # prefix summarization is pure
    @test result.attempts === prefix.attempts

    failed_counter = Ref(0)
    failed = HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds, ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(failed_counter; fail_at = 2))
    @test failed.attempts[2].status == :failed
    @test failed.attempts[2].guard_results === nothing
    @test occursin("controlled fit failure", failed.attempts[2].failure_reason)
    @test failed.requested_bootstrap_count == 3
    @test failed.usable_bootstrap_count == 2
    @test !failed.formed # fixed denominator: ceil(0.99 * 3) == 3
    @test all(ismissing, [x.lower for x in failed.intervals])

    interrupted_counter = Ref(0)
    interrupted = HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds, ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(interrupted_counter; interrupt_at = 2))
    @test interrupted.interruption_ledger.attempt == 2
    @test [a.status for a in interrupted.attempts] ==
        [:ok, :interrupted, :not_run_after_interruption]
    @test interrupted.attempts[2].selector_ledger !== nothing
    @test interrupted.attempts[2].starts_attempted == 1
    @test interrupted.attempts[2].guard_results === nothing
    @test interrupted.requested_bootstrap_count == 3
    @test interrupted.usable_bootstrap_count == 1
    @test !interrupted.formed

    returned_interrupt_counter = Ref(0)
    returned_interrupt = HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds, ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(returned_interrupt_counter; return_interrupt_at = 2))
    @test returned_interrupt_counter[] == 2
    @test returned_interrupt.interruption_ledger.attempt == 2
    @test [a.status for a in returned_interrupt.attempts] ==
        [:ok, :interrupted, :not_run_after_interruption]
    @test returned_interrupt.attempts[2].starts_attempted == 5
    @test returned_interrupt.attempts[2].guard_results.nesting_witness.status == :unavailable
    @test length(returned_interrupt.attempts[2].selector_ledger.attempts) == 5
    @test returned_interrupt.attempts[3].starts_attempted == 0
    @test returned_interrupt.counts.not_run == 1
    @test !returned_interrupt.formed

    outer_failure_counter = Ref(0)
    unavailable_outer = (; selection_status = :not_selected,
        reason = "both outer rank candidates unavailable",
        source_identity = HSquared._ARC1_SOURCE_IDENTITY,
        candidate_summary = [(rank = 0, status = :fit_failed), (rank = 1, status = :fit_failed)],
        attempts = [(rank = 0, status = :failed), (rank = 1, status = :failed)])
    outer_failure = HSquared._arc1_bootstrap(unavailable_outer,
        _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED; seeds, ids = _BOOT_PED.ids,
        traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(outer_failure_counter))
    @test outer_failure_counter[] == 0
    @test outer_failure.outer_selection === unavailable_outer
    @test outer_failure.point_fit === nothing
    @test outer_failure.requested_bootstrap_count == length(seeds)
    @test outer_failure.requested_seeds == seeds
    @test all(a -> a.status == :not_run_after_outer_selection_failure, outer_failure.attempts)
    @test all(a -> a.starts_attempted == 0, outer_failure.attempts)
    @test outer_failure.counts.not_run == length(seeds)
    @test outer_failure.counts.started == 0
    @test outer_failure.failure_causes["outer_selection_failure"] == length(seeds)
    @test !outer_failure.formed
    @test all(ismissing, [interval.lower for interval in outer_failure.intervals])

    mismatch_counter = Ref(0)
    mismatch = HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds, ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(mismatch_counter; wrong_identity_at = 1))
    @test mismatch.attempts[1].status == :failed
    @test startswith(mismatch.attempts[1].failure_reason, "identity_mismatch")
    @test mismatch.requested_bootstrap_count == 3
    @test mismatch.usable_bootstrap_count == 2
    @test !mismatch.formed

    k0 = HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds = UInt64[0x41], ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(Ref(0); k0_fail_at = 1))
    @test k0.attempts[1].status == :selection_failed
    @test !occursin("identity_mismatch", k0.attempts[1].failure_reason)

    bad_covariance = HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds = UInt64[0x42], ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(Ref(0); corrupt_at = 1))
    @test bad_covariance.attempts[1].status == :failed
    @test startswith(bad_covariance.attempts[1].failure_reason, "invalid_fit:")

    seen = Ref{Any}(nothing)
    seed = UInt64(0x1234)
    replay = HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds = UInt64[seed], ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(Ref(0); response_seen = seen))
    A = HSquared._arc1_bootstrap_relationship(_BOOT_PED)
    rng = MersenneTwister(seed)
    expected_animal = cholesky(Symmetric(A)).L * randn(rng, 6, 4) *
        transpose(cholesky(Symmetric(_BOOT_G)).L)
    expected = _BOOT_X * _BOOT_BETA + _BOOT_Z * expected_animal +
        randn(rng, 6, 4) * transpose(cholesky(Symmetric(_BOOT_R)).L)
    @test seen[] == expected
    @test replay.seed_derivation_version == "explicit_uint64_v1"

    wrong_outer = merge(selection, (; source_identity = "different-source"))
    @test_throws ArgumentError HSquared._arc1_bootstrap(wrong_outer, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds, ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(Ref(0)))
    nonsymmetric_G = copy(_BOOT_G)
    nonsymmetric_G[1, 2] = 0.25
    nonsymmetric_outer_fit = merge(selection.selected_fit,
        (; genetic_covariance = nonsymmetric_G))
    nonsymmetric_outer = merge(selection, (; selected_fit = nonsymmetric_outer_fit))
    @test_throws ArgumentError HSquared._arc1_bootstrap(nonsymmetric_outer,
        _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED; seeds, ids = _BOOT_PED.ids,
        traits = _BOOT_TRAITS, selector = _bootstrap_fake_selector(Ref(0)))
    @test_throws ArgumentError HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds = UInt64[1, 1], ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(Ref(0)))
    @test_throws TypeError HSquared._arc1_bootstrap(selection, _BOOT_Y, _BOOT_X, _BOOT_Z, _BOOT_PED;
        seeds = [1, 2], ids = _BOOT_PED.ids, traits = _BOOT_TRAITS,
        selector = _bootstrap_fake_selector(Ref(0)))
end

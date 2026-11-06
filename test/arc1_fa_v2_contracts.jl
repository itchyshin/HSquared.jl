using LinearAlgebra
using Test
using HSquared

@testset "Arc1 profile v4 evidence sink interface contract" begin
    n = 4
    ids = collect(1:n)
    pedigree = HSquared.normalize_pedigree(ids, zeros(Int, n), zeros(Int, n))
    retained = Any[Dict(:kind => :tail_certificate, :status => :excluded_tail),
                   Dict(:kind => :refusal, :status => :unresolved_shared_competitor),
                   Dict(:kind => :provenance, :status => :retained)]
    sink = Dict{Symbol,Any}(
        :arc1_profile_v3_evaluations => retained,
        :arc1_profile_v4_evaluations => retained,
        :tail_proof => retained[1],
        :refusal_record => retained[2],
        :provenance_record => retained[3],
    )

    # A deliberately mismatched response length stops after the wrapper stamps
    # method identity and prepares the sink, without running an optimizer.
    @test_throws Exception HSquared.arc1_profile_repeatability(
        zeros(2n - 1), ones(2n, 1), Matrix{Float64}(I, n, n), pedigree;
        method="arc1_profile_v4", v3_evidence_sink=sink)

    @test sink[:requested_method_version] == "arc1_profile_v4"
    @test sink[:actual_method_version] == "arc1_profile_v4"
    @test sink[:source_identity] == HSquared._ARC1_SOURCE_IDENTITY
    @test sink[:arc1_profile_v4_evaluations] === sink[:arc1_profile_v3_evaluations]
    @test sink[:arc1_profile_v4_evaluations][1:3] == retained
    @test sink[:tail_proof] === retained[1]
    @test sink[:refusal_record] === retained[2]
    @test sink[:provenance_record] === retained[3]

    stale_identity = Dict{Symbol,Any}(:requested_method_version => "arc1_profile_v3")
    @test_throws ArgumentError HSquared.arc1_profile_repeatability(
        zeros(2n - 1), ones(2n, 1), Matrix{Float64}(I, n, n), pedigree;
        method="arc1_profile_v4", v3_evidence_sink=stale_identity)
    @test stale_identity == Dict{Symbol,Any}(:requested_method_version => "arc1_profile_v3")

    stale_actual_identity = Dict{Symbol,Any}(
        :actual_method_version => "arc1_profile_v3",
    )
    @test_throws ArgumentError HSquared.arc1_profile_repeatability(
        zeros(2n - 1), ones(2n, 1), Matrix{Float64}(I, n, n), pedigree;
        method="arc1_profile_v4", v3_evidence_sink=stale_actual_identity)
    @test stale_actual_identity[:actual_method_version] == "arc1_profile_v3"

    conflicting_histories = Dict{Symbol,Any}(
        :arc1_profile_v3_evaluations => Any[:old_history],
        :arc1_profile_v4_evaluations => Any[:different_history],
    )
    @test_throws ArgumentError HSquared.arc1_profile_repeatability(
        zeros(2n - 1), ones(2n, 1), Matrix{Float64}(I, n, n), pedigree;
        method="arc1_profile_v4", v3_evidence_sink=conflicting_histories)
    @test conflicting_histories[:arc1_profile_v3_evaluations] == Any[:old_history]
    @test conflicting_histories[:arc1_profile_v4_evaluations] == Any[:different_history]

    for method in ("arc1_profile_v1", "arc1_profile_v2")
        bad_sink = Dict{Symbol,Any}()
        @test_throws ArgumentError HSquared.arc1_profile_repeatability(
            zeros(2n), ones(2n, 1), Matrix{Float64}(I, n, n), pedigree;
            method, v3_evidence_sink=bad_sink)
        @test isempty(bad_sink)
    end

    v3_sink = Dict{Symbol,Any}()
    @test_throws Exception HSquared.arc1_profile_repeatability(
        zeros(2n - 1), ones(2n, 1), Matrix{Float64}(I, n, n), pedigree;
        method="arc1_profile_v3", v3_evidence_sink=v3_sink)
    @test v3_sink[:requested_method_version] == "arc1_profile_v3"
    @test !haskey(v3_sink, :arc1_profile_v4_evaluations)
end

function _arc1_v2_contract_fixture()
    Y = [0.1 0.4 -0.2 0.8; 0.7 -0.1 0.5 0.2; -0.3 0.6 0.9 -0.4;
         0.8 0.2 -0.5 0.1; -0.4 -0.3 0.2 0.7]
    X = ones(5, 1)
    B = Matrix{Float64}(I, 5, 5)
    lambda = [0.62, -0.44, 0.31, -0.53]
    psi = [0.2401, 0.3301, 0.2901, 0.2101]
    R = [0.7 0.08 0.03 0.0; 0.08 0.8 0.06 0.02;
         0.03 0.06 0.75 0.04; 0.0 0.02 0.04 0.72]
    L = Matrix(cholesky(Symmetric(R)).L)
    residual = Float64[]
    for j in 1:4, i in j:4
        push!(residual, i == j ? log(L[i,j]) : L[i,j])
    end
    params = vcat(lambda, log.(psi .- HSquared.FA_UNIQUENESS_FLOOR), residual)
    (; Y, X, B, lambda, psi, R, params, residual)
end

@testset "ARC1 retained-factor v2 contracts" begin
    d = _arc1_v2_contract_fixture()
    ctx = HSquared._arc1_fa_spectral_context(d.Y, d.X, d.B).context

    @testset "v1 automatic selector keeps its legacy attempt-row schema" begin
        n = 8
        ids = collect(1:n)
        sire = zeros(Int, n); dam = zeros(Int, n)
        for i in 5:n
            sire[i] = 1 + (i - 5) % 2
            dam[i] = 3 + (i - 5) % 2
        end
        ped = HSquared.normalize_pedigree(ids, sire, dam)
        Y = [sin(0.23i + 0.41j) + cos(0.17i * j) for i in 1:n, j in 1:4]
        X = ones(n, 1)
        Z = Matrix{Float64}(I, n, n)
        legacy_runner = function (spectral, params0, rank, start_id, observe)
            evaluation = HSquared._arc1_fa_exact_objective_gradient(spectral, params0, rank)
            @test evaluation.status == :ok
            return (; phat = copy(params0), objective = -evaluation.loglik,
                converged = true, optimizer_converged = true, iterations = 1,
                optimizer_status = "v1 schema regression")
        end
        result = HSquared._arc1_select_fa_rank(Y, X, Z, ped; ids,
            attempt_runner = legacy_runner)
        @test result.optimizer_policy == "arc1_v1"
        @test !isempty(result.attempts)
        @test all(a -> !hasproperty(a, :best_observation_certificate_status),
            result.attempts)
        @test any(a -> a.status == :completed && a.finite_objective === true,
            result.attempts)
        @test result.selection_status in (:selected, :unavailable)
    end

    @testset "well-conditioned v2 objective agrees with legacy and independent likelihood" begin
        old = HSquared._arc1_fa_exact_objective_gradient(ctx, d.params, 1)
        new = HSquared._arc1_fa_v2_exact_objective_gradient(ctx, d.params, 1)
        independent = HSquared._arc1_fa_v2_certify(d.Y, d.X, d.B, d.params, 1, new.loglik)
        @test old.status == new.status == :ok
        @test new.objective ≈ old.objective atol = 1e-9 rtol = 1e-10
        @test new.gradient ≈ old.gradient atol = 1e-8 rtol = 1e-7
        @test independent.status == :ok
        @test independent.discrepancy <= 1e-8
        @test new.factor_state.rank == 1
        @test new.factor_state.factor_order == HSquared._ARC1_FA_V2_FACTOR_ORDER
    end

    @testset "positive excess survives rounded uniqueness at the open floor" begin
        params0 = vcat(fill(log(1e-25), 4), d.residual)
        state = HSquared._arc1_fa_v2_factor_state(params0, 0).state
        v2 = HSquared._arc1_fa_v2_exact_objective_gradient(ctx, params0, 0)
        v1 = HSquared._arc1_fa_exact_objective_gradient(ctx, params0, 0)
        @test all(>(0), state.delta)
        @test all(==(0.0), state.rounded_floor_distance)
        @test state.floor_rounding
        @test v2.status == :ok
        @test v1.status == :invalid_proposal
    end

    @testset "likelihood observation survives gradient failure status" begin
        state = HSquared._arc1_fa_v2_factor_state(d.params, 1).state
        failed_gradient = HSquared._arc1_fa_v2_gradient_failure(1.0, 5.0,
            state, zeros(4), fill(NaN, length(d.params)))
        invalid = HSquared._arc1_fa_v2_invalid("invalid proposal", length(d.params))
        @test failed_gradient.status == :failed
        @test failed_gradient.observation.status == :ok
        @test HSquared._arc1_fa_v2_valid_likelihood_observation(failed_gradient)
        @test !HSquared._arc1_fa_v2_valid_likelihood_observation(invalid)
    end

    @testset "factor validity is separate from rounded residual PD" begin
        params0 = vcat(log.(d.psi .- HSquared.FA_UNIQUENESS_FLOOR), d.residual)
        params0[5] = 0.0       # L[1,1] = 1
        params0[6] = 1.0       # L[2,1] = 1
        params0[9] = log(1e-10) # L[2,2] > 0, but L*L' rounds singular
        state_result = HSquared._arc1_fa_v2_factor_state(params0, 0)
        @test state_result.status == :ok
        @test state_result.state.factor_valid
        @test !state_result.state.pd_residual
        @test state_result.state.residual_factor[2, 2] > 0
    end

    @testset "malformed optimizer outputs retain v2 attempt identity" begin
        ctx_rank = (; Y = d.Y, X = d.X,
            Z = Matrix{Float64}(I, size(d.Y, 1), size(d.Y, 1)), A = d.B)
        valid = HSquared._arc1_fa_v2_exact_objective_gradient(ctx, d.params, 1)
        nonfinite = copy(d.params)
        nonfinite[1] = NaN
        cases = (
            (:absent, (; objective = valid.raw_objective), "no parameter vector"),
            (:wrong_length, (; phat = d.params[1:end-1], objective = valid.raw_objective),
                "wrong-length"),
            (:nonfinite, (; phat = nonfinite, objective = valid.raw_objective), "wrong-length"))
        for (label, output, reason_text) in cases
            row = HSquared._fa_rank_evaluate_attempt(ctx_rank, 1, label, 0,
                d.params, output; optimizer_policy = "arc1_v2")
            @test row.status == :failed
            @test row.requested_optimizer_policy == "arc1_v2"
            @test row.actual_optimizer_policy == "arc1_v2"
            @test row.optimizer_policy == "arc1_v2"
            @test row.optimizer_policy_version == 2
            @test row.source_identity == HSquared._ARC1_SOURCE_IDENTITY
            @test occursin(reason_text, row.reason)
        end
    end

    @testset "selector retains and refuses a better unaccepted valid proposal" begin
        n = 8
        ids = collect(1:n)
        sire = zeros(Int, n); dam = zeros(Int, n)
        for i in 5:n
            sire[i] = 1 + (i - 5) % 2
            dam[i] = 3 + (i - 5) % 2
        end
        ped = HSquared.normalize_pedigree(ids, sire, dam)
        Y = [sin(0.31i + 0.7j) + cos(0.13i * j) for i in 1:n, j in 1:4]
        X = ones(n, 1)
        Z = Matrix{Float64}(I, n, n)
        shared_k1 = Ref{Any}(nothing)
        runner = function (spectral, params, rank, name)
            if rank == 0
                phat = copy(params)
            else
                shared_k1[] === nothing && (shared_k1[] = copy(params))
                phat = copy(shared_k1[])
            end
            evaluated = HSquared._arc1_fa_v2_exact_objective_gradient(spectral, phat, rank)
            @test evaluated.status == :ok
            proposal = copy(phat)
            if rank == 1 && name == :default
                direction = -evaluated.gradient ./ max(norm(evaluated.gradient, Inf), 1.0)
                for exponent in 2:-1:-14
                    candidate = phat .+ 10.0^exponent .* direction
                    trial = HSquared._arc1_fa_v2_exact_objective_gradient(spectral, candidate, rank)
                    if trial.status == :ok && trial.loglik > evaluated.loglik + HSquared._FA_RANK_TAU
                        proposal = candidate
                        break
                    end
                end
            end
            return (; phat, objective = evaluated.raw_objective,
                converged = true, optimizer_converged = true,
                optimizer_assessment_status = :accepted, iterations = 1,
                optimizer_status = "injected", best_observation_parameters = proposal)
        end
        result = HSquared._arc1_select_fa_rank(Y, X, Z, ped; ids,
            optimizer_policy = "arc1_v2", attempt_runner = runner)
        @test result.selection_status == :unavailable
        @test result.guard_results.better_unaccepted === true
        @test occursin("better finite unaccepted", result.reason)
        valid_proposals = filter(a -> a.rank == 1 && a.attempted &&
            a.best_observation_certificate_status === :ok, result.attempts)
        @test !isempty(valid_proposals)
        best_row = valid_proposals[argmax(getproperty.(valid_proposals, :best_observed_loglik))]
        @test best_row.best_observed_loglik > result.candidate_summary[2].loglik +
            HSquared._FA_RANK_TAU / 2
        @test best_row.best_observation_accepted === false
    end

    @testset "v2 callback observations survive runner-up certification and failed exits" begin
        function selector_fixture()
            n = 8
            ids = collect(1:n)
            sire = zeros(Int, n); dam = zeros(Int, n)
            for i in 5:n
                sire[i] = 1 + (i - 5) % 2
                dam[i] = 3 + (i - 5) % 2
            end
            ped = HSquared.normalize_pedigree(ids, sire, dam)
            Y = [sin(0.31i + 0.7j) + cos(0.13i * j) for i in 1:n, j in 1:4]
            (; n, ids, ped, Y, X = ones(n, 1), Z = Matrix{Float64}(I, n, n))
        end
        fixture = selector_fixture()
        accepted_output = function (spectral, params, rank)
            ev = HSquared._arc1_fa_v2_exact_objective_gradient(spectral, params, rank)
            (; phat = copy(params), objective = ev.raw_objective,
                converged = true, optimizer_converged = true,
                optimizer_assessment_status = :accepted, iterations = 1,
                optimizer_status = "callback test")
        end

        @testset "every relevant observation is retained and runner-up is certified" begin
            shared_k1 = Ref{Any}(nothing)
            best_coordinates = Ref{Any}(nothing)
            runner_up_coordinates = Ref{Any}(nothing)
            runner_up_loglik = Ref(-Inf)
            relationship = inv(Symmetric(Matrix(HSquared.pedigree_inverse(fixture.ped))))
            B = fixture.Z * relationship * transpose(fixture.Z)
            runner = function (spectral, params, rank, name, observe)
                if rank == 0
                    phat = copy(params)
                else
                    shared_k1[] === nothing && (shared_k1[] = copy(params))
                    phat = copy(shared_k1[])
                end
                base = HSquared._arc1_fa_v2_exact_objective_gradient(spectral, phat, rank)
                @test HSquared._arc1_fa_v2_valid_likelihood_observation(base)
                observe(phat, base)
                if rank == 1 && name == :default
                    direction = -base.gradient ./ max(norm(base.gradient, Inf), 1.0)
                    proposals = NamedTuple[]
                    for exponent in 2:-1:-12
                        candidate = phat .+ 10.0^exponent .* direction
                        evaluation = HSquared._arc1_fa_v2_exact_objective_gradient(spectral,
                            candidate, rank)
                        HSquared._arc1_fa_v2_valid_likelihood_observation(evaluation) || continue
                        evaluation.loglik > base.loglik + HSquared._FA_RANK_TAU || continue
                        push!(proposals, (; candidate, evaluation))
                    end
                    sort!(proposals; by = x -> x.evaluation.loglik, rev = true)
                    @test length(proposals) >= 2
                    best = proposals[1]
                    runnerup = proposals[2]
                    best_coordinates[] = copy(best.candidate)
                    runner_up_coordinates[] = copy(runnerup.candidate)
                    runner_up_loglik[] = runnerup.evaluation.loglik
                    observe(best.candidate, best.evaluation)
                    observe(runnerup.candidate, runnerup.evaluation)
                end
                return accepted_output(spectral, phat, rank)
            end
            certifier = function (observation)
                if isequal(observation.coordinates, best_coordinates[])
                    return (; status = :failed, independent_loglik = -Inf, discrepancy = Inf)
                end
                ev = HSquared._arc1_fa_v2_exact_objective_gradient(
                    HSquared._arc1_fa_spectral_context(fixture.Y, fixture.X, B).context,
                    observation.coordinates, observation.rank)
                HSquared._arc1_fa_v2_certify(fixture.Y, fixture.X, B,
                    observation.coordinates, observation.rank, ev.loglik)
            end
            result = HSquared._arc1_select_fa_rank(fixture.Y, fixture.X, fixture.Z, fixture.ped;
                ids = fixture.ids, optimizer_policy = "arc1_v2", attempt_runner = runner,
                observation_certifier = certifier)
            @test result.guard_results.better_unaccepted === true
            @test result.selection_status == :unavailable
            default = only(filter(a -> a.rank == 1 && a.start_id == :default, result.attempts))
            by_coordinates = Dict(Tuple(o.coordinates) => o for o in default.optimizer_observations)
            failed_max = by_coordinates[Tuple(best_coordinates[])]
            passed_runnerup = by_coordinates[Tuple(runner_up_coordinates[])]
            @test failed_max.certificate_status == :failed
            @test passed_runnerup.certificate_status == :ok
            @test passed_runnerup.independent_loglik ≈ runner_up_loglik[] atol = 1e-8
            @test passed_runnerup.independent_loglik > result.candidate_summary[2].loglik +
                HSquared._FA_RANK_TAU / 2
            @test all(o -> o.source_identity == HSquared._ARC1_SOURCE_IDENTITY &&
                o.requested_optimizer_policy == "arc1_v2" && o.actual_optimizer_policy == "arc1_v2" &&
                o.rank == 1 && o.start_id == :default, default.optimizer_observations)
        end

        @testset "certificate tolerance margin cannot hide a competitive observation" begin
            relationship = inv(Symmetric(Matrix(HSquared.pedigree_inverse(fixture.ped))))
            B = fixture.Z * relationship * transpose(fixture.Z)
            evaluation = HSquared._arc1_fa_v2_exact_objective_gradient(ctx, d.params, 1)
            observations = NamedTuple[]
            record = HSquared._arc1_fa_v2_retain_observation!(observations,
                d.params, evaluation; rank = 1, start_id = :boundary,
                retry_index = 0, source_identity = HSquared._ARC1_SOURCE_IDENTITY)
            candidate_loglik = -100.0
            threshold = candidate_loglik + HSquared._FA_RANK_TAU / 2
            observations[1] = merge(record, (; loglik = threshold - 5e-9))
            calls = Ref(0)
            certify = observation -> begin
                calls[] += 1
                (; status = :ok, independent_loglik = threshold + 3e-9,
                   discrepancy = 8e-9)
            end
            certified = HSquared._arc1_fa_v2_certify_observations(observations,
                ctx, fixture.Y, fixture.X, B, 1, candidate_loglik;
                certifier = certify)
            @test calls[] == 1
            @test only(certified).certificate_status == :ok
            @test only(certified).independent_loglik > threshold
        end

        @testset "normal exceptions preserve callback observations" begin
            runner = function (spectral, params, rank, name, observe)
                ev = HSquared._arc1_fa_v2_exact_objective_gradient(spectral, params, rank)
                observe(params, ev)
                rank == 1 && name == :default && error("injected optimizer error")
                accepted_output(spectral, params, rank)
            end
            result = HSquared._arc1_select_fa_rank(fixture.Y, fixture.X, fixture.Z, fixture.ped;
                ids = fixture.ids, optimizer_policy = "arc1_v2", attempt_runner = runner)
            row = only(filter(a -> a.rank == 1 && a.start_id == :default, result.attempts))
            @test row.status == :failed
            @test length(row.optimizer_observations) == 1
            @test row.optimizer_observations[1].start_id == :default
            @test row.optimizer_observations[1].source_identity == HSquared._ARC1_SOURCE_IDENTITY
        end

        @testset "interruption publishes callback observations" begin
            ledger = Ref{Any}(nothing)
            runner = function (spectral, params, rank, name, observe)
                ev = HSquared._arc1_fa_v2_exact_objective_gradient(spectral, params, rank)
                observe(params, ev)
                throw(InterruptException())
            end
            @test_throws InterruptException HSquared._arc1_select_fa_rank(fixture.Y,
                fixture.X, fixture.Z, fixture.ped; ids = fixture.ids, ledger_sink = ledger,
                optimizer_policy = "arc1_v2", attempt_runner = runner)
            row = only(filter(a -> a.rank == 0 && a.start_id == :default, ledger[].attempts))
            @test row.status == :interrupted
            @test length(row.optimizer_observations) == 1
            @test row.optimizer_observations[1].actual_optimizer_policy == "arc1_v2"
        end

        @testset "malformed terminal parameters preserve callback observations" begin
            runner = function (spectral, params, rank, name, observe)
                ev = HSquared._arc1_fa_v2_exact_objective_gradient(spectral, params, rank)
                observe(params, ev)
                output = accepted_output(spectral, params, rank)
                rank == 1 && name == :default ? merge(output, (; phat = params[1:end-1])) : output
            end
            result = HSquared._arc1_select_fa_rank(fixture.Y, fixture.X, fixture.Z, fixture.ped;
                ids = fixture.ids, optimizer_policy = "arc1_v2", attempt_runner = runner)
            row = only(filter(a -> a.rank == 1 && a.start_id == :default, result.attempts))
            @test row.status == :failed
            @test length(row.optimizer_observations) == 1
            @test row.optimizer_observations[1].coordinates == row.initial_parameters
            @test row.optimizer_observations[1].optimizer_policy_version == 2
        end
    end

    @testset "v2 requires an accepted optimizer assessment" begin
        ctx_rank = (; Y = d.Y, X = d.X, Z = Matrix{Float64}(I, size(d.Y, 1), size(d.Y, 1)),
            A = d.B)
        evaluated = HSquared._arc1_fa_v2_exact_objective_gradient(ctx, d.params, 1)
        output = (; phat = d.params, objective = evaluated.raw_objective,
            converged = true, optimizer_converged = true, iterations = 1,
            optimizer_status = "injected")
        missing = HSquared._fa_rank_evaluate_attempt(ctx_rank, 1, :test, 0,
            d.params, output; optimizer_policy = "arc1_v2")
        rejected = HSquared._fa_rank_evaluate_attempt(ctx_rank, 1, :test, 0,
            d.params, merge(output, (; optimizer_assessment_status = :numerical_gradient_failure));
            optimizer_policy = "arc1_v2")
        @test missing.status == :failed
        @test missing.optimizer_assessment_status === nothing
        @test occursin("assessment status is missing", missing.reason)
        @test !missing.eligible
        @test rejected.status == :failed
        @test !rejected.eligible
    end

    @testset "interruption preserves per-start actual policy" begin
        n = 8
        ids = collect(1:n)
        sire = zeros(Int, n); dam = zeros(Int, n)
        for i in 5:n
            sire[i] = 1 + (i - 5) % 2
            dam[i] = 3 + (i - 5) % 2
        end
        ped = HSquared.normalize_pedigree(ids, sire, dam)
        Y = [sin(0.31i + 0.7j) + cos(0.13i * j) for i in 1:n, j in 1:4]
        X = ones(n, 1)
        Z = Matrix{Float64}(I, n, n)
        runner = function (spectral, params, rank, name)
            fit = HSquared._arc1_fa_v2_exact_objective_gradient(spectral, params, rank)
            (; phat = copy(params), objective = fit.raw_objective,
                converged = true, optimizer_converged = true,
                optimizer_assessment_status = :accepted, iterations = 1,
                optimizer_status = "injected")
        end

        before = Ref{Any}(nothing)
        before_result = HSquared._arc1_select_fa_rank(Y, X, Z, ped;
            ids, ledger_sink = before, optimizer_policy = "arc1_v2",
            attempt_runner = runner,
            checkpoint = () -> throw(InterruptException()))
        @test before_result.selection_status == :interrupted
        @test all(a -> !a.attempted && a.actual_optimizer_policy === nothing,
            before_result.attempts)
        @test before_result.actual_optimizer_policy === nothing

        checkpoint_calls = Ref(0)
        between = Ref{Any}(nothing)
        between_result = HSquared._arc1_select_fa_rank(Y, X, Z, ped;
            ids, ledger_sink = between, optimizer_policy = "arc1_v2",
            attempt_runner = runner,
            checkpoint = () -> begin
                checkpoint_calls[] += 1
                checkpoint_calls[] == 2 && throw(InterruptException())
            end)
        @test between_result.selection_status == :interrupted
        @test between_result.attempts[1].attempted
        @test between_result.attempts[1].actual_optimizer_policy == "arc1_v2"
        @test all(a -> a.attempted || a.actual_optimizer_policy === nothing,
            between_result.attempts)
        @test between_result.actual_optimizer_policy == "arc1_v2"
    end

    @testset "actual policy belongs to executed attempt rows" begin
        unattempted = merge(HSquared._fa_rank_attempt(0, :queued, 0;
            status = :unattempted, reason = "queued"), (; attempted = false))
        attempted = merge(HSquared._fa_rank_attempt(0, :started, 0),
            (; actual_optimizer_policy = "arc1_v2"))
        ledger = Ref{Any}(nothing)
        snapshot = HSquared._fa_rank_publish!(ledger,
            [HSquared._fa_rank_candidate(0), HSquared._fa_rank_candidate(1)],
            [unattempted, attempted]; optimizer_policy = "arc1_v2",
            optimizer_policy_version = 2,
            requested_optimizer_policy = "arc1_v2",
            actual_optimizer_policy = "arc1_v2",
            source_identity = HSquared._ARC1_SOURCE_IDENTITY)
        @test snapshot.attempts[1].actual_optimizer_policy === nothing
        @test snapshot.attempts[2].actual_optimizer_policy == "arc1_v2"
    end

    @testset "rounded-matrix PD does not enable v2 GLS/BLUP" begin
        k0params = vcat(log.(d.psi .- HSquared.FA_UNIQUENESS_FLOOR), d.residual)
        state = HSquared._arc1_fa_v2_factor_state(k0params, 0).state
        attempt = (; rank = 0, genetic_covariance = state.G,
            residual_covariance = state.R, factor_state = state, factor_valid = true,
            genetic_loadings = nothing, uniqueness = state.psi, loglik = -1.0,
            optimizer_iterations = 1, start_id = :test,
            floor_distances = state.delta, near_floor = false)
        candidates = [HSquared._fa_rank_candidate(0;
                objective_range = nothing, g_relative_disagreement = nothing,
                r_relative_disagreement = nothing),
            HSquared._fa_rank_candidate(1)]
        fit = HSquared._fa_rank_fit((; ids = [1], traits = ["a", "b", "c", "d"]),
            attempt, candidates, [attempt]; optimizer_policy = "arc1_v2")
        @test all(values(fit.rounded_matrix_pd))
        @test fit.beta === nothing
        @test fit.breeding_values === nothing
        @test fit.matrix_operations_status == :unavailable
        @test fit.downstream_diagnostics.gls == :not_certified
        @test fit.downstream_diagnostics.blup == :not_certified

        reported_indefinite = [
            0.32703552661281554  0.3339778994936688  -0.12197868147333915 -0.15526750130081754;
            0.3339778994936688  0.6110494128948445   0.25214283287929734 -0.07012389993364093;
           -0.12197868147333915 0.25214283287929734  0.5862464535913825   0.09660223544193038;
           -0.15526750130081754 -0.07012389993364093 0.09660223544193038  0.5773462119534791]
        inconsistent_rounding = merge(attempt,
            (; residual_covariance = reported_indefinite))
        diagnostic_fit = HSquared._fa_rank_fit(
            (; ids = [1], traits = ["a", "b", "c", "d"]),
            inconsistent_rounding, candidates, [inconsistent_rounding];
            optimizer_policy = "arc1_v2")
        @test diagnostic_fit.factor_valid
        @test diagnostic_fit.rounded_matrix_pd.residual === false
        @test diagnostic_fit.matrix_operations_status == :unavailable
    end

    @testset "accuracy limits preserve equality and reject malformed evidence" begin
        grad = zeros(2)
        exact = HSquared._arc1_fa_v2_accuracy_check(0.0, 1e-8, grad,
            [5e-6, 0.0], [0.0, 5e-6], true)
        beyond = HSquared._arc1_fa_v2_accuracy_check(0.0, 1.0001e-8, grad,
            zeros(2), zeros(2), true)
        malformed = HSquared._arc1_fa_v2_accuracy_check(0.0, 0.0, [0.0],
            zeros(2), zeros(2), true)
        @test exact.passed
        @test !beyond.passed
        @test !malformed.passed
    end
end

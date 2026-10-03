using Test
using SHA
using TOML
using Serialization
using LinearAlgebra
using Optim

const ARC1_EXECUTOR_REPO = normpath(joinpath(@__DIR__, ".."))

module Arc1ExecutorReferenceAPIEngine
using LinearAlgebra
struct Pedigree
    ids::Vector{String}
    sire::Vector{Int}
    dam::Vector{Int}
    order::Vector{Int}
end
pedigree_inverse(pedigree) = Matrix{Float64}(I, length(pedigree.ids), length(pedigree.ids))
end

include(joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", "execute_attempt.jl"))

function _arc1_write_fake_engine(root)
    mkpath(joinpath(root, "src"))
    write(joinpath(root, "Project.toml"), """
    name = "HSquared"
    uuid = "a0667dea-0f38-44e8-9150-4fda00624eac"
    version = "0.1.0"

    [deps]
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
    """)
    write(joinpath(root, "Manifest.toml"), """
    julia_version = "$(VERSION)"
    manifest_format = "2.0"
    project_hash = "0000000000000000000000000000000000000000"

    [[deps.LinearAlgebra]]
    uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

    [[deps.Random]]
    uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
    """)
    write(joinpath(root, "src", "HSquared.jl"), raw"""
    module HSquared
    using LinearAlgebra
    using Random
    @enum FakeTerminationCode::UInt8 FakeNoObjectiveChange=7
    const _ARC1_SOURCE_IDENTITY = "fake-loaded-source-v1"
    struct Pedigree
        ids::Vector{String}
        sire::Vector{Int}
        dam::Vector{Int}
        order::Vector{Int}
    end
    function _candidates()
        [(; rank=0, q=14, penalty=28, eligible=true, status=:ok, reason=nothing,
           loglik=-10.0, criterion=48.0, near_floor=false),
         (; rank=1, q=18, penalty=36, eligible=true, status=:ok, reason=nothing,
           loglik=-7.0, criterion=50.0, near_floor=false)]
    end
    _guard_results(selected) = (; schedule_complete=true, better_unaccepted=false,
        nonnested=!selected, nesting_witness=(; status=:passed, discrepancy=0.0, tolerance=1e-8))
    function select_fa_rank(Y, X, Z, ped; ids, traits, optimizer_policy)
        if get(ENV, "ARC1_FAKE_UNAVAILABLE", "false") == "true"
        return (; selection_status=:unavailable, selected_rank=nothing,
            selected_fit=nothing, candidate_summary=_candidates(), starts_planned=19,
            starts_attempted=19, attempts=[(; rank=0, status=:ok)],
            guard_results=_guard_results(false),
            near_tie=false,
            source_identity="fake-source-v1", reason="synthetic nesting guard")
        end
        G = Matrix{Float64}(I, 4, 4) .* 0.25
        R = Matrix{Float64}(I, 4, 4) .* 0.25
        fit = (; genetic_covariance=G, residual_covariance=R, beta=zeros(1,4), loglik=-10.0)
        (; selection_status=:selected, selected_rank=0, selected_fit=fit,
           candidate_summary=_candidates(), starts_planned=19, starts_attempted=19,
           attempts=[(; rank=0, status=:ok)], guard_results=_guard_results(true),
           near_tie=false,
           source_identity="fake-source-v1", reason=nothing)
    end
    function arc1_profile_repeatability(y, X, Z, ped; ids, method="arc1_profile_v1",
                                       v3_evidence_sink=nothing)
        returned_method = get(ENV, "ARC1_FAKE_PROFILE_WRONG_VERSION", "false") == "true" ?
            :arc1_profile_v2 : Symbol(method)
        if v3_evidence_sink !== nothing
            get(ENV, "ARC1_FAKE_V3_MISSING_ACTUAL", "false") == "true" ||
                (v3_evidence_sink[:actual_method_version] = String(returned_method))
            v3_evidence_sink[:source_identity] =
                get(ENV, "ARC1_FAKE_V3_WRONG_SOURCE", "false") == "true" ?
                    "wrong-loaded-source" : _ARC1_SOURCE_IDENTITY
            push!(get!(v3_evidence_sink, :arc1_profile_v3_evaluations, Any[]),
                Dict{Symbol,Any}(:target => :heritability, :fixed_value => 0.0,
                    :status => :interrupted,
                    :events => [Dict{Symbol,Any}(:event => :interrupted,
                        :components => [0.2, 0.1, 0.7], :value => -3.0,
                        :termination_code => FakeNoObjectiveChange,
                        :native_tuple => (missing, Inf, NaN),
                        :native_dict => Dict(:reason => :line_search_stopped),
                        :error => "InterruptException")],
                    :producer_history => [Dict{Symbol,Any}(:stage => :bounded_probe)],
                    :max_valid_loglik => -3.0,
                    :max_valid_centered_loglik => -3.0))
        end
        get(ENV, "ARC1_FAKE_PROFILE_INTERRUPT", "false") == "true" && throw(InterruptException())
        targets = Dict{Symbol,Any}()
        for target in (:additive_variance, :permanent_environment_variance,
                       :residual_variance, :heritability, :repeatability)
            segments = target == :heritability ? [(0.1, 0.2), (0.4, 0.6)] : [(0.1, 0.6)]
            targets[target] = (; formed=true, confidence_set=segments, status=:formed)
        end
        profile = (; targets, cutoff=3.841458820694124, method_version=returned_method,
           point_estimates=(; additive_variance=0.3, permanent_environment_variance=0.2,
             residual_variance=0.5, heritability=0.3, repeatability=0.5),
           point_fit=(; loglik=-3.0), point_fit_status=:ok,
           point_fit_candidate=(; iterations=23, optimizer_converged=false),
           max_constrained_loglik=-3.00001, point_fit_not_optimal=false,
           point_identity="point-id", reference_point_identity="point-id",
           source_identity="fake-loaded-source-v1",
           reference_source_identity="fake-loaded-source-v1")
        get(ENV, "ARC1_FAKE_PROFILE_MISSING_VERSION", "false") == "true" ?
            Base.structdiff(profile, (; method_version=returned_method)) : profile
    end
    function arc1_bootstrap(selection, Y, X, Z, ped; selector, B, seeds, ids, traits)
        attempts = [begin
            (; seed, status=:ok, selected_rank=0, candidate_summary=_candidates(),
               selected_fit_summary=(; genetic_covariance=Matrix{Float64}(I,4,4).*0.25,
                   residual_covariance=Matrix{Float64}(I,4,4).*0.25), failure_reason=nothing)
        end for seed in seeds]
        (; attempts, failure_causes=Dict{String,Int}(), requested_seeds=seeds)
    end
    function _arc1_bootstrap_prefix(result, n)
        intervals = [(; trait=Symbol("trait$i"), formed=true, lower=0.2, upper=0.8,
                       estimate=0.5, status=:formed) for i in 1:4]
        (; intervals, usable_bootstrap_count=n, attempts=result.attempts[1:n])
    end
    end
    """)
    for filename in ("execution_identity.jl", "independent_dgp.jl", "engine_io.jl",
                     "inspect_artifacts.jl", "reference.jl", "execute_attempt.jl")
        target = joinpath(root, "sim", "arc1", filename)
        mkpath(dirname(target))
        cp(joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", filename), target; force=true)
    end
end

function _arc1_run_fake_attempt(root, output, cell, seed, bootstrap_seeds;
                                unavailable=false, wrong_profile_version=false,
                                missing_profile_version=false,
                                wrong_v3_source=false, missing_v3_actual=false,
                                interrupt_profile=false,
                                outer=1, admission=nothing)
    admitted_sources = admission === nothing ? nothing :
        get(admission, "source_sha256", get(admission, "source_hashes", nothing))
    admitted_protocol = admission === nothing ? nothing :
        get(admission, "protocol_sha256", get(admission, "protocol_sha256", nothing))
    source = joinpath(root, "src", "HSquared.jl")
    source_hash = bytes2hex(sha256(read(source)))
    project = joinpath(root, "Project.toml")
    manifest = joinpath(root, "Manifest.toml")
    env_hashes = Dict("Project.toml" => bytes2hex(sha256(read(project))),
                      "Manifest.toml" => bytes2hex(sha256(read(manifest))))
    attempt_dir = joinpath(output, "attempts")
    mkpath(attempt_dir)
    artifact_path = joinpath(attempt_dir, "$(cell.programme)-$(seed).full.jls")
    config = Dict{String,Any}(
        "mode" => "engineering_probe", "source_root" => root,
        "attempt_output" => attempt_dir, "artifact_path" => artifact_path,
        "outer" => outer, "seed" => string(seed), "blas_threads" => 1,
        "profile_method_version" => cell.programme in ("repeatability", "boundary") ?
            "arc1_profile_v3" : "",
        "bootstrap_seeds" => string.(bootstrap_seeds),
        "cell" => Dict("programme" => cell.programme, "phase" => cell.phase,
                       "N" => cell.N, "signal" => cell.signal),
        "engine_hashes" => admission === nothing ? Dict("src/HSquared.jl" => source_hash) :
            Dict{String,String}(String(k) => String(v) for (k,v) in admitted_sources
                if startswith(String(k), "src/")),
        "environment_hashes" => env_hashes,
        "source_hashes" => admission === nothing ? Dict("src/HSquared.jl" => source_hash,
            "sim/arc1/execute_attempt.jl" => bytes2hex(sha256(read(joinpath(ARC1_EXECUTOR_REPO,
                "sim", "arc1", "execute_attempt.jl")))),
            "sim/arc1/engine_io.jl" => bytes2hex(sha256(read(joinpath(ARC1_EXECUTOR_REPO,
                "sim", "arc1", "engine_io.jl"))))) : admitted_sources,
        "protocol_sha256" => admission === nothing ? repeat("0", 64) : admitted_protocol)
    input = joinpath(attempt_dir, "input.toml")
    open(input, "w") do io
        TOML.print(io, config)
    end
    depot = joinpath(output, "depot")
    mkpath(depot)
    depot_path = string(depot, Sys.iswindows() ? ';' : ':', first(DEPOT_PATH))
    command = addenv(`$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$root $(joinpath(root,"sim","arc1","execute_attempt.jl")) $input`,
                     "JULIA_DEPOT_PATH" => depot_path,
                     "OPENBLAS_NUM_THREADS" => "1", "JULIA_NUM_THREADS" => "1",
                     "ARC1_FAKE_UNAVAILABLE" => unavailable ? "true" : "false",
                     "ARC1_FAKE_PROFILE_WRONG_VERSION" => wrong_profile_version ? "true" : "false",
                     "ARC1_FAKE_PROFILE_MISSING_VERSION" => missing_profile_version ? "true" : "false",
                     "ARC1_FAKE_V3_WRONG_SOURCE" => wrong_v3_source ? "true" : "false",
                     "ARC1_FAKE_V3_MISSING_ACTUAL" => missing_v3_actual ? "true" : "false",
                     "ARC1_FAKE_PROFILE_INTERRUPT" => interrupt_profile ? "true" : "false")
    stdout = read(pipeline(ignorestatus(command), stderr=Base.stdout), String)
    return stdout, artifact_path
end

function _arc1_inspect_fake_artifact(root, artifact_path)
    request = artifact_path * ".inspect.txt"
    write(request, artifact_path * "\n")
    command = `$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$root $(joinpath(root,"sim","arc1","inspect_artifacts.jl")) $request`
    depot = joinpath(dirname(dirname(artifact_path)), "depot")
    mkpath(depot)
    env = Dict("JULIA_DEPOT_PATH" => string(depot, Sys.iswindows() ? ';' : ':', first(DEPOT_PATH)),
        "OPENBLAS_NUM_THREADS" => "1", "JULIA_NUM_THREADS" => "1")
    return read(pipeline(addenv(command, env...), stderr=Base.stdout), String)
end

@testset "Arc1 source-bound one-attempt executor" begin
    include(joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", "engine_io.jl"))
    include(joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", "independent_dgp.jl"))
    @testset "typed transport preserves exact and exceptional values" begin
        seed = typemax(UInt64)
        transport = (; seed, nothing_value=nothing, missing_value=missing,
                     nan=NaN, positive_infinity=Inf,
                     segments=[[(0.1,0.2),(0.4,0.7)]],
                     ledger=[(; status=:interrupted, starts_attempted=UInt64(3),
                              termination_code=Optim.TerminationCode.NoObjectiveChange,
                              tuple_leaf=(missing, Inf, NaN),
                              diagnostic_dict=Dict(:reason => :line_search_stopped))])
        encoded = arc1_json(transport)
        @test occursin(string(seed), encoded)
        @test occursin("\"nothing_value\":null", encoded)
        @test occursin("\"__arc1_type__\":\"missing\"", encoded)
        @test occursin("\"__arc1_float__\":\"NaN\"", encoded)
        @test occursin("\"__arc1_float__\":\"Inf\"", encoded)
        @test occursin("0.1,0.2", encoded) && occursin("0.4,0.7", encoded)
        @test occursin("\"__arc1_enum__\"", encoded)
        @test occursin("\"name\":\"NoObjectiveChange\"", encoded)
        @test occursin("\"value\":", encoded)
        matrix_json = arc1_json([1 2 3; 4 5 6])
        @test occursin("\"dims\":[2,3]", matrix_json)
        @test occursin("\"layout\":\"julia_column_major\"", matrix_json)
        @test occursin("\"data\":[1,4,2,5,3,6]", matrix_json)
        mktempdir() do directory
            path = joinpath(directory, "full.jls")
            hash = arc1_serialize_new(path, transport)
            @test hash == bytes2hex(sha256(read(path)))
            restored = open(deserialize, path)
            @test restored.seed === seed
            @test restored.nothing_value === nothing
            @test restored.missing_value === missing
            @test isnan(restored.nan) && restored.positive_infinity == Inf
            @test restored.segments == transport.segments
            @test restored.ledger[1].termination_code ===
                Optim.TerminationCode.NoObjectiveChange
        @test isequal(restored.ledger[1].tuple_leaf, (missing, Inf, NaN))
            @test_throws ArgumentError arc1_serialize_new(path, transport)
        end
        # A JLS artifact can preserve a native leaf that the JSON projection
        # deliberately refuses. The terminal fallback must preserve the
        # original interruption and identify the projection failure without
        # retrying conversion of the unsafe sink.
        native_with_unsupported_leaf = (; v3_profile_evidence=merge(
            (; requested_method_version="arc1_profile_v3",
               actual_method_version="arc1_profile_v3",
               source_identity=repeat("a", 64),
               arc1_profile_v3_evaluations=transport.ledger),
            (; unsupported=Ref(17))))
        @test_throws ArgumentError arc1_json(native_with_unsupported_leaf)
        projected, projection_error = arc1_receipt_json(
            (; status="interrupted", v3_profile_evidence=native_with_unsupported_leaf);
            fallback_fields=(; preserve_original_error=true, mode="engineering_probe",
                outer=1, seed_string="99", status="interrupted",
                failure_reason="InterruptException", error_type="InterruptException",
                requested_profile_method_version="arc1_profile_v3",
                profile_method_version="arc1_profile_v3",
                profile_method_version_mismatch=false,
                profile_source_identity=repeat("a", 64),
                loaded_arc1_source_identity=repeat("b", 64),
                artifact_path="retained.jls", artifact_sha256="abc",
                retention_error=nothing))
        @test projection_error isa ArgumentError
        @test occursin("\"status\":\"interrupted\"", projected)
        @test occursin("\"error_type\":\"InterruptException\"", projected)
        @test occursin("\"profile_method_version\":\"arc1_profile_v3\"", projected)
        @test occursin("\"artifact_path\":\"retained.jls\"", projected)
        @test occursin("receipt_projection_error", projected)
    end

    @testset "fresh-process fake-engine wiring and evidence" begin
        mktempdir(prefix="arc1-executor-fixture-") do temp
            root = joinpath(temp, "fake-engine")
            output = joinpath(temp, "outside-results")
            mkpath(output)
            _arc1_write_fake_engine(root)
            fa_cell = (; programme="fa_rank", phase="engineering_probe", N=16, signal="weak")
            stdout, artifact = _arc1_run_fake_attempt(root, output, fa_cell, typemax(UInt64), UInt64[])
            @test occursin("\"success\":true", stdout)
            @test occursin("18446744073709551615", stdout)
            @test occursin("\"status\":\"not_required\"", stdout)
            @test occursin("offspring-1", stdout)
            @test isfile(artifact)
            @test filesize(artifact) > 0
            semantic_data = arc1_simulate_fa(UInt64(20261002), 16, 0.15)
            semantic_design = arc1_fa_design(Arc1ExecutorReferenceAPIEngine, semantic_data)
            semantic_id = arc1_semantic_data_identity(semantic_data, semantic_design)
            @test semantic_id == arc1_semantic_data_identity(semantic_data, semantic_design)
            changed_y = deepcopy(semantic_data); changed_y.Y[1, 1] += 1
            @test semantic_id != arc1_semantic_data_identity(changed_y, semantic_design)
            changed_x = deepcopy(semantic_design); changed_x.X[1, 1] += 1
            @test semantic_id != arc1_semantic_data_identity(semantic_data, changed_x)
            changed_z = deepcopy(semantic_design); changed_z.Z[1, 1] = 1 - changed_z.Z[1, 1]
            @test semantic_id != arc1_semantic_data_identity(semantic_data, changed_z)
            changed_ped = deepcopy(semantic_design); changed_ped.pedigree.sire[1] = 1
            @test semantic_id != arc1_semantic_data_identity(semantic_data, changed_ped)

            repeat_cell = (; programme="repeatability", phase="engineering_probe", N=16,
                           signal="near_zero_pe")
            repeat_stdout, repeat_artifact = _arc1_run_fake_attempt(root, output, repeat_cell,
                                                                      UInt64(20261002), UInt64[])
            @test occursin("record_animal_ids", repeat_stdout)
            @test occursin("offspring-1-record-1", repeat_stdout) # record IDs remain unique
            @test occursin("\"record_animal_ids\":[\"offspring-1\",\"offspring-1\"", repeat_stdout)
            @test occursin("0.1,0.2", repeat_stdout) && occursin("0.4,0.6", repeat_stdout)
            @test occursin("\"point_fit_status\":\"ok\"", repeat_stdout)
            @test occursin("\"point_fit_not_optimal\":false", repeat_stdout)
            @test occursin("\"profile_method_version\":\"arc1_profile_v3\"", repeat_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v3\"", repeat_stdout)
            @test occursin("\"max_constrained_loglik\":-3.00001", repeat_stdout)
            @test occursin("target_diagnostics_identity", repeat_stdout)
            @test isfile(repeat_artifact)
            inspected_profile = _arc1_inspect_fake_artifact(root, repeat_artifact)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v3\"", inspected_profile)
            @test occursin("\"profile_method_version\":\"arc1_profile_v3\"", inspected_profile)
            @test occursin("\"loaded_engine_source_identity_matches\":true", inspected_profile)
            @test occursin("\"retained_result_identity_matches\":true", inspected_profile)
            @test occursin("\"receipt_summary_matches_retained_result\":true", inspected_profile)

            bad_profile_cell = (; programme="repeatability", phase="engineering_probe", N=16,
                                signal="invalid")
            failed_profile_stdout, failed_profile_artifact = _arc1_run_fake_attempt(
                root, output, bad_profile_cell, UInt64(20261003), UInt64[])
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v3\"",
                           failed_profile_stdout)
            @test occursin("\"profile_method_version\":null", failed_profile_stdout)
            @test occursin("\"profile_method_version_mismatch\":false", failed_profile_stdout)
            @test !occursin("\"profile_method_version\":\"arc1_profile_v1\"", failed_profile_stdout)
            inspected_failure = _arc1_inspect_fake_artifact(root, failed_profile_artifact)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v3\"", inspected_failure)
            @test occursin("\"v3_evidence_identity_matches\":true", inspected_failure)
            @test occursin("\"loaded_engine_source_identity_matches\":true", inspected_failure)

            mismatch_stdout, mismatch_artifact = _arc1_run_fake_attempt(root, output,
                repeat_cell, UInt64(20261004), UInt64[]; wrong_profile_version=true)
            @test occursin("\"profile_method_version_mismatch\":true", mismatch_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v3\"", mismatch_stdout)
            @test occursin("\"profile_method_version\":\"arc1_profile_v2\"", mismatch_stdout)
            @test isfile(mismatch_artifact)

            missing_stdout, missing_artifact = _arc1_run_fake_attempt(root, output,
                repeat_cell, UInt64(20261005), UInt64[]; missing_profile_version=true)
            @test occursin("\"profile_method_version_mismatch\":true", missing_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v3\"", missing_stdout)
            @test occursin("\"profile_method_version\":null", missing_stdout)
            @test isfile(missing_artifact)

            interrupted_stdout, interrupted_artifact = _arc1_run_fake_attempt(root, output,
                repeat_cell, UInt64(20261006), UInt64[]; interrupt_profile=true)
            @test occursin("\"status\":\"interrupted\"", interrupted_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v3\"",
                           interrupted_stdout)
            @test occursin("\"profile_method_version\":\"arc1_profile_v3\"", interrupted_stdout)
            @test occursin("\"actual_method_version\":\"arc1_profile_v3\"", interrupted_stdout)
            @test occursin("\"max_valid_centered_loglik\":-3.0", interrupted_stdout)
            @test occursin("\"event\":\"interrupted\"", interrupted_stdout)
            @test occursin("\"__arc1_enum__\"", interrupted_stdout)
            @test occursin("\"name\":\"FakeNoObjectiveChange\"", interrupted_stdout)
            @test !occursin("\"profile_intervals\":", interrupted_stdout)
            @test isfile(interrupted_artifact)
            inspected_interruption = _arc1_inspect_fake_artifact(root, interrupted_artifact)
            @test occursin("\"retained_v3_evidence_present\":true", inspected_interruption)
            @test occursin("\"v3_evidence_identity_matches\":true", inspected_interruption)
            @test occursin("\"v3_evidence_partial_present\":true", inspected_interruption)
            @test occursin("\"loaded_engine_source_identity_matches\":true", inspected_interruption)
            @test occursin("\"actual_method_version\":\"arc1_profile_v3\"", inspected_interruption)
            @test occursin("\"max_valid_centered_loglik\":-3.0", inspected_interruption)
            @test occursin("\"termination_code\":{\"__arc1_enum__\":", inspected_interruption)
            @test occursin("\"native_dict\":{\"reason\":\"line_search_stopped\"}", inspected_interruption)
            @test occursin("\"native_tuple\":[{\"__arc1_type__\":\"missing\"},{\"__arc1_float__\":\"Inf\"},{\"__arc1_float__\":\"NaN\"}]", inspected_interruption)

            wrong_source_cell = (; programme="repeatability", phase="engineering_probe", N=16,
                                 signal="near_zero_pe")
            _, wrong_source_path = _arc1_run_fake_attempt(root, output, wrong_source_cell,
                UInt64(20261007), UInt64[]; interrupt_profile=true, wrong_v3_source=true)
            wrong_source_output = _arc1_inspect_fake_artifact(root, wrong_source_path)
            @test occursin("\"v3_evidence_identity_matches\":false", wrong_source_output)

            _, missing_actual_path = _arc1_run_fake_attempt(root, output, wrong_source_cell,
                UInt64(20261008), UInt64[]; interrupt_profile=true, missing_v3_actual=true)
            missing_actual_output = _arc1_inspect_fake_artifact(root, missing_actual_path)
            @test occursin("\"v3_evidence_identity_matches\":false", missing_actual_output)

            interval_cell = (; programme="fa_interval", phase="pilot", N=16, signal="null")
            inner = UInt64[typemax(UInt64) - i for i in 0:998]
            interval_stdout, interval_artifact = _arc1_run_fake_attempt(root, output,
                interval_cell, UInt64(991), inner)
            @test occursin("\"requested_B\":199", interval_stdout)
            @test occursin("\"B\":499", interval_stdout)
            @test occursin("\"B\":999", interval_stdout)
            @test occursin("18446744073709551615", interval_stdout)
            @test isfile(interval_artifact)

            bad_cell = (; programme="fa_rank", phase="engineering_probe", N=16, signal="bad_signal")
            error_stdout, error_artifact = _arc1_run_fake_attempt(root, output,
                bad_cell, UInt64(992), UInt64[])
            @test occursin("\"success\":false", error_stdout)
            @test occursin("\"status\":\"error\"", error_stdout)
            @test occursin("KeyError", error_stdout)
            @test isfile(error_artifact)
            retained = open(deserialize, error_artifact)
            @test retained.metadata.status == "error"
            @test occursin("KeyError", retained.error.type)

            unavailable_cell = (; programme="fa_interval", phase="pilot", N=16, signal="null")
            unavailable_stdout, unavailable_artifact = _arc1_run_fake_attempt(root, output,
                unavailable_cell, UInt64(993), UInt64[UInt64(994)]; unavailable=true)
            @test occursin("\"status\":\"selection_failed\"", unavailable_stdout)
            @test occursin("\"eligible\":true", unavailable_stdout)
            @test occursin("\"selection_status\":\"unavailable\"", unavailable_stdout)
            @test occursin("\"stage\":\"not_started\"", unavailable_stdout)
            @test occursin("expanded reference is only scheduled for FA rank study cells", unavailable_stdout)
            @test !occursin("\"inner_index\"", unavailable_stdout)
            @test isfile(unavailable_artifact)
        end
    end
end

@testset "Arc1 reference-admission flags and rank comparison receipts" begin
    selected = (; selection_status=:selected, selected_fit=(;), selected_rank=0,
        near_tie=false, candidate_summary=[(; rank=0, eligible=true, loglik=-10.0,
            near_floor=false), (; rank=1, eligible=true, loglik=-7.0, near_floor=false)])
    @test !arc1_reference_required(selected,
        Dict("programme" => "fa_rank", "phase" => "engineering_probe"), 1)
    @test arc1_reference_required(selected,
        Dict("programme" => "fa_rank", "phase" => "pilot"), 20)
    near_floor = merge(selected, (; candidate_summary=[selected.candidate_summary[1],
        merge(selected.candidate_summary[2], (; near_floor=true))]))
    @test arc1_reference_required(near_floor,
        Dict("programme" => "fa_rank", "phase" => "pilot"), 21)

    reference_runner = (_engine, _Y, _X, _B; dataset_identity) -> (; status=:best_found,
        dataset_identity, rows=[(; dataset_identity, rank=rank,
            stage=:bfgs_initial, schedule_index=i, intermediate_maxima=Any[])
            for (rank, count) in ((0, 6), (1, 64)) for i in 1:count],
        starts_planned=Dict(0 => 6, 1 => 64),
        phenotypic_variances=fill(0.5, 4),
        phenotypic_variance_method="retained_Y_sample_variance_nonpositive_fallback_1",
        k0_anchor=(; source=:analytic_split_fallback, split=0.5,
            genetic_diagonal=fill(0.25, 4), residual_covariance=Matrix{Float64}(I,4,4).*0.25,
            observation_order=nothing, status=:available),
        refinement_selection=(; per_rank=4, k0_initial=Any[], k0_nelder_mead=Any[],
            k1_initial=Any[], k1_nelder_mead=Any[]),
        optimizer_budgets=(; bfgs=10_000, nelder_mead=20_000, retained_per_rank=4),
        best_by_rank=Dict(0 => (; loglik=-10.00005), 1 => nothing),
        claim="best found, not global")
    design = (; pedigree=(; ids=["a", "b"]), Y=zeros(2,4), X=ones(2,1),
              Z=Matrix{Float64}(I,2,2))
    unavailable = merge(selected, (; candidate_summary=[selected.candidate_summary[1],
        (; rank=1, eligible=false, loglik=nothing, near_floor=nothing)]))
    audit = arc1_rank_reference_receipt(Arc1ExecutorReferenceAPIEngine, unavailable,
        design, "outer-data-sha"; reference_runner)
    @test audit.status == "best_found"
    @test audit.dataset_identity == "outer-data-sha"
    @test audit.starts_planned == Dict("K0" => 6, "K1" => 64)
    @test audit.rank_comparisons["K0"].status == :compared
    @test audit.rank_comparisons["K0"].passed
    @test audit.rank_comparisons["K1"].status == :not_applicable
    @test !audit.rank_comparisons["K1"].passed
end

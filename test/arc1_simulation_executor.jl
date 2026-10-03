using Test
using SHA
using TOML
using Serialization
using LinearAlgebra

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
    function arc1_profile_repeatability(y, X, Z, ped; ids, method="arc1_profile_v1")
        targets = Dict{Symbol,Any}()
        for target in (:additive_variance, :permanent_environment_variance,
                       :residual_variance, :heritability, :repeatability)
            segments = target == :heritability ? [(0.1, 0.2), (0.4, 0.6)] : [(0.1, 0.6)]
            targets[target] = (; formed=true, confidence_set=segments, status=:formed)
        end
        returned_method = get(ENV, "ARC1_FAKE_PROFILE_WRONG_VERSION", "false") == "true" ?
            :arc1_profile_v1 : Symbol(method)
        (; targets, cutoff=3.841458820694124, method_version=returned_method,
           point_estimates=(; additive_variance=0.3, permanent_environment_variance=0.2,
             residual_variance=0.5, heritability=0.3, repeatability=0.5),
           point_fit=(; loglik=-3.0), point_fit_status=:ok,
           point_fit_candidate=(; iterations=23, optimizer_converged=false),
           max_constrained_loglik=-3.00001, point_fit_not_optimal=false,
           point_identity="point-id", reference_point_identity="point-id",
           source_identity="fake-source-v1", reference_source_identity="fake-source-v1")
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
            "arc1_profile_v2" : "",
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
                     "ARC1_FAKE_PROFILE_WRONG_VERSION" => wrong_profile_version ? "true" : "false")
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
                     ledger=[(; status=:interrupted, starts_attempted=UInt64(3))])
        encoded = arc1_json(transport)
        @test occursin(string(seed), encoded)
        @test occursin("\"nothing_value\":null", encoded)
        @test occursin("\"__arc1_type__\":\"missing\"", encoded)
        @test occursin("\"__arc1_float__\":\"NaN\"", encoded)
        @test occursin("\"__arc1_float__\":\"Inf\"", encoded)
        @test occursin("0.1,0.2", encoded) && occursin("0.4,0.7", encoded)
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
            @test_throws ArgumentError arc1_serialize_new(path, transport)
        end
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
            @test occursin("\"profile_method_version\":\"arc1_profile_v2\"", repeat_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v2\"", repeat_stdout)
            @test occursin("\"max_constrained_loglik\":-3.00001", repeat_stdout)
            @test occursin("target_diagnostics_identity", repeat_stdout)
            @test isfile(repeat_artifact)
            inspected_profile = _arc1_inspect_fake_artifact(root, repeat_artifact)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v2\"", inspected_profile)
            @test occursin("\"profile_method_version\":\"arc1_profile_v2\"", inspected_profile)

            bad_profile_cell = (; programme="repeatability", phase="engineering_probe", N=16,
                                signal="invalid")
            failed_profile_stdout, failed_profile_artifact = _arc1_run_fake_attempt(
                root, output, bad_profile_cell, UInt64(20261003), UInt64[])
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v2\"",
                           failed_profile_stdout)
            @test !occursin("\"profile_method_version\":\"arc1_profile_v1\"", failed_profile_stdout)
            inspected_failure = _arc1_inspect_fake_artifact(root, failed_profile_artifact)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v2\"", inspected_failure)

            mismatch_stdout, mismatch_artifact = _arc1_run_fake_attempt(root, output,
                repeat_cell, UInt64(20261004), UInt64[]; wrong_profile_version=true)
            @test occursin("\"profile_method_version_mismatch\":true", mismatch_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v2\"", mismatch_stdout)
            @test isfile(mismatch_artifact)

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

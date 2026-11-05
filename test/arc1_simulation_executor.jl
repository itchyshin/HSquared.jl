using Test
using SHA
using TOML
using Serialization
using LinearAlgebra
using SparseArrays
using Optim
using HSquared

const ARC1_EXECUTOR_REPO = normpath(joinpath(@__DIR__, ".."))

@testset "Arc1 Julia CLI refuses unverified attempt history before reading inputs" begin
    mktempdir() do dir
        missing_input = joinpath(dir, "must-not-be-read.toml")
        driver = joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", "execute_attempt.jl")
        command = `$(Base.julia_cmd()) --startup-file=no $driver $missing_input`
        combined = Pipe()
        process = run(pipeline(ignorestatus(command), stdout=combined, stderr=combined); wait=false)
        close(combined.in)
        result = read(combined, String)
        wait(process)
        @test !success(process)
        @test occursin("Arc1 study execution is disabled: authoritative attempt history is unverified", result)
        @test isempty(readdir(dir))
        # A caller-selected probe mode is not an escape hatch.
        input = joinpath(dir, "input.toml")
        write(input, "mode = \"engineering_probe\"\n")
        combined2 = Pipe()
        command2 = `$(Base.julia_cmd()) --startup-file=no $driver $input`
        process2 = run(pipeline(ignorestatus(command2), stdout=combined2, stderr=combined2); wait=false)
        close(combined2.in)
        result2 = read(combined2, String)
        wait(process2)
        @test !success(process2)
        @test occursin("Arc1 study execution is disabled: authoritative attempt history is unverified", result2)
        @test readdir(dir) == ["input.toml"]
    end
end

function _arc1_strip_refusal_for_fake_engine(source)
    refusal = "    error(\"Arc1 study execution is disabled: authoritative attempt history is unverified\")"
    length(findall(refusal, source)) == 1 || error("CLI refusal missing or duplicated")
    return replace(source, refusal => ""; count=1)
end

@testset "fake-engine copy accepts both line endings" begin
    line = "    error(\"Arc1 study execution is disabled: authoritative attempt history is unverified\")"
    @test _arc1_strip_refusal_for_fake_engine(line * "\n") == "\n"
    @test _arc1_strip_refusal_for_fake_engine(line * "\r\n") == "\r\n"
    @test_throws ErrorException _arc1_strip_refusal_for_fake_engine(line * "\n" * line)
end

function _arc1_inject_projection_counter(source)
    signature = "function arc1_raw_result_projection_difference(payload, result, metadata)"
    length(findall(signature, source)) == 1 || error("raw-result projection hook missing or duplicated")
    injection = """
        function arc1_raw_result_projection_difference(payload, result, metadata)
            counter_path = get(ENV, "ARC1_TEST_PROJECTION_COUNTER", "")
            if !isempty(counter_path)
                open(counter_path, "a") do io
                    println(io, "called")
                end
            end
    """
    return replace(source, signature => injection; count=1)
end

struct Arc1ContainerUnsupportedInteger <: Integer
    value::Int
end

@enum Arc1ContainerUnapprovedEnum::UInt8 Arc1ContainerUnapprovedValue=1

function _arc1_assert_argument_error_message(f, message_part)
    error = try
        f()
        nothing
    catch caught
        caught
    end
    @test error isa ArgumentError
    error isa ArgumentError && @test occursin(message_part, sprint(showerror, error))
    return nothing
end

function _arc1_test_profile_row(fields::Pair...)
    row = Dict{Symbol,Any}(:target => :heritability, :fixed_value => 0.5,
        :status => :ok, :events => Any[], :producer_history => Any[],
        :provenance_failures => Any[], :max_valid_loglik => -Inf,
        :max_valid_centered_loglik => -Inf)
    merge!(row, Dict{Symbol,Any}(fields))
    return row
end

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
    SHA = "ea8e919c-243c-51af-8825-aaa63cd721ce"
    Serialization = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
    """)
    write(joinpath(root, "Manifest.toml"), """
    julia_version = "$(VERSION)"
    manifest_format = "2.0"
    project_hash = "0000000000000000000000000000000000000000"

    [[deps.LinearAlgebra]]
    uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

    [[deps.Random]]
    uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

    [[deps.SHA]]
    uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

    [[deps.Serialization]]
    uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
    """)
    write(joinpath(root, "src", "HSquared.jl"), raw"""
    module HSquared
    using LinearAlgebra
    using Random
    using SHA
    using Serialization
    const _ARC1_SOURCE_IDENTITY = "fake-loaded-source-v1"
    struct Pedigree
        ids::Vector{String}
        sire::Vector{Int}
        dam::Vector{Int}
        order::Vector{Int}
    end
    pedigree_inverse(pedigree) = Matrix{Float64}(I, length(pedigree.ids), length(pedigree.ids))
    function _arc1_profile_context(y, X, Z, Ainv)
        get(ENV, "ARC1_FAKE_CONTEXT_UNAVAILABLE", "false") == "true" &&
            error("synthetic retained-design reconstruction failure")
        counts = vec(sum(Z; dims=1))
        observed = findall(==(2.0), counts)
        m, p = length(observed), size(X, 2)
        H = zeros(Float64, 2m, p)
        for (j, animal) in pairs(observed)
            rows = findall(!iszero, view(Z, :, animal))
            H[j, :] .= (X[rows[1], :] .+ X[rows[2], :]) ./ sqrt(2.0)
            H[m + j, :] .= (X[rows[1], :] .- X[rows[2], :]) ./ sqrt(2.0)
        end
        exact = [Rational{BigInt}(H[i, j]) for i in axes(H, 1), j in axes(H, 2)]
        determinant = sum(abs2, exact[:, 1])
        design_identity = bytes2hex(sha256(reinterpret(UInt8, vec(H))))
        return (; transformed_design=H, residual_df=2m-p,
            profile_v4_design_data=(; status=:ok, determinant, design_identity))
    end
    function _arc1_profile_v4_rational_lower(x::Rational{BigInt})
        numerator_lower = setrounding(BigFloat, RoundDown) do
            BigFloat(numerator(x))
        end
        denominator_upper = setrounding(BigFloat, RoundUp) do
            BigFloat(denominator(x))
        end
        setrounding(BigFloat, RoundDown) do
            numerator_lower / denominator_upper
        end
    end
    function _arc1_profile_v4_tail_certificate(H::AbstractMatrix, E::Real,
            point_loglik::Real; cutoff::Real=3.841458820694124,
            precision::Int=256, normalization_convention, design_data)
        n, p = size(H)
        determinant, design_identity = design_data.determinant, design_data.design_identity
        residual_df = n - p
        upper, threshold, gap = setprecision(BigFloat, precision) do
            determinant_lower = setrounding(BigFloat, RoundDown) do
                log(_arc1_profile_v4_rational_lower(determinant))
            end
            loge_lower = setrounding(BigFloat, RoundDown) do
                log(BigFloat(E))
            end
            inside_lower = setrounding(BigFloat, RoundDown) do
                BigFloat(residual_df) * loge_lower + determinant_lower
            end
            upper_bound = setrounding(BigFloat, RoundUp) do
                -BigFloat(0.5) * inside_lower
            end
            threshold_lower = setrounding(BigFloat, RoundDown) do
                BigFloat(point_loglik) - BigFloat(cutoff) / BigFloat(2)
            end
            gap_lower = setrounding(BigFloat, RoundDown) do
                threshold_lower - upper_bound
            end
            upper_bound, threshold_lower, gap_lower
        end
        tolerance = 1e-8
        certified = gap > BigFloat(tolerance)
        return (; status=certified ? :excluded_tail : :bound_not_separating,
            reason=certified ? nothing : :conservative_gap_too_small, certified,
            E=Float64(E), upper_bound=upper, threshold_lower=threshold,
            gap_lower=gap, precision, rounding=:directed_mpfr,
            determinant, residual_df, design_identity,
            convention=normalization_convention, point_loglik=Float64(point_loglik),
            cutoff=Float64(cutoff), separation_tolerance=tolerance,
            rounding_contract=(; rational_numerator=:down,
                rational_denominator=:up, rational_division=:down,
                determinant_log=:down, boundary_variance_log=:down,
                residual_df_product_and_sum=:down,
                upper_bound_negation_and_product=:up,
                threshold_subtraction=:down, gap_subtraction=:down),
            boundary_rounding_contract=(; reference_threshold=:down,
                log_determinant_lower=:down, log_boundary_numerator=:up,
                residual_df_division=:up, exponential=:up,
                float_conversion=:nearest_then_nextfloat),
            determinant_identity=:detD_detHinvDH_equals_detHtH_detCtDC)
    end
    function _candidates()
        [(; rank=0, q=14, penalty=28, eligible=true, status=:ok, reason=nothing,
           loglik=-10.0, criterion=48.0, near_floor=false),
         (; rank=1, q=18, penalty=36, eligible=true, status=:ok, reason=nothing,
           loglik=-7.0, criterion=50.0, near_floor=false)]
    end
    _guard_results(selected) = (; schedule_complete=true, better_unaccepted=false,
        nonnested=!selected, nesting_witness=(; status=:passed, discrepancy=0.0, tolerance=1e-8))
    _selector_attempts() = [begin
        rank = index <= 6 ? 0 : 1
        (; rank, attempted=true, status=:ok)
    end for index in 1:24]
    function select_fa_rank(Y, X, Z, ped; ids, traits, optimizer_policy)
        if get(ENV, "ARC1_FAKE_UNAVAILABLE", "false") == "true"
        return (; selection_status=:unavailable, selected_rank=nothing,
            selected_fit=nothing, candidate_summary=_candidates(), starts_planned=24,
            starts_attempted=24, attempts=_selector_attempts(),
            guard_results=_guard_results(false),
            near_tie=false,
            source_identity="fake-source-v1", reason="synthetic nesting guard")
        end
        G = Matrix{Float64}(I, 4, 4) .* 0.25
        R = Matrix{Float64}(I, 4, 4) .* 0.25
        fit = (; genetic_covariance=G, residual_covariance=R, beta=zeros(1,4), loglik=-10.0)
        (; selection_status=:selected, selected_rank=0, selected_fit=fit,
           candidate_summary=_candidates(), starts_planned=24, starts_attempted=24,
           attempts=_selector_attempts(), guard_results=_guard_results(true),
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
            evaluations = get!(v3_evidence_sink, :arc1_profile_v3_evaluations, Any[])
            v3_evidence_sink[:arc1_profile_v4_evaluations] =
                get(ENV, "ARC1_FAKE_V4_SPLIT_ALIAS", "false") == "true" ?
                    copy(evaluations) : evaluations
            v3_evidence_sink[:v4_tail_certificates] = Any[]
            push!(evaluations,
                Dict{Symbol,Any}(:target => :heritability, :fixed_value => 0.0,
                    :status => :interrupted,
                    :events => [Dict{Symbol,Any}(:event => :interrupted,
                        :components => [0.2, 0.1, 0.7], :value => -3.0,
                        :termination_code => :FakeNoObjectiveChange,
                        :native_tuple => (missing, Inf, NaN),
                        :native_dict => Dict(:reason => :line_search_stopped),
                        :error => "InterruptException")],
                    :producer_history => [(; path="candidate[1]", owner=:candidate,
                        candidate_id=1, source_id=(:producer_record, :candidate, 1,
                            "candidate[1]", 1), record=(; stage=:bounded_probe))],
                    :provenance_failures => Any[],
                    :max_valid_loglik => -3.0,
                    :max_valid_centered_loglik => -3.0))
            if haskey(ENV, "ARC1_FAKE_V4_CERTIFICATE_PATH")
                certificate = open(deserialize, ENV["ARC1_FAKE_V4_CERTIFICATE_PATH"])
                push!(v3_evidence_sink[:v4_tail_certificates],
                    (; target=:residual_variance, certificate))
            end
        end
        get(ENV, "ARC1_FAKE_PROFILE_INTERRUPT", "false") == "true" && throw(InterruptException())
        get(ENV, "ARC1_FAKE_PROFILE_FAIL", "false") == "true" &&
            error("synthetic profile failure after v4 evidence retention")
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
                     "artifact_container.jl",
                     "inspect_artifacts.jl", "reference.jl", "execute_attempt.jl")
        target = joinpath(root, "sim", "arc1", filename)
        mkpath(dirname(target))
        cp(joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", filename), target; force=true)
        if filename == "execute_attempt.jl"
            source = read(target, String)
            # This isolated fake-engine harness exercises the executor internals
            # on a modified copy. The unmodified CLI refusal is tested above.
            write(target, _arc1_inject_projection_counter(_arc1_strip_refusal_for_fake_engine(source)))
        end
    end
end

function _arc1_run_fake_attempt(root, output, cell, seed, bootstrap_seeds;
                                unavailable=false, wrong_profile_version=false,
                                missing_profile_version=false,
                                wrong_v3_source=false, missing_v3_actual=false,
                                split_v4_alias=false,
                                interrupt_profile=false,
                                fail_profile=false, v4_certificate_path=nothing,
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
            "arc1_profile_v4" : "",
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
                     "ARC1_FAKE_V4_SPLIT_ALIAS" => split_v4_alias ? "true" : "false",
                     "ARC1_FAKE_PROFILE_INTERRUPT" => interrupt_profile ? "true" : "false",
                     "ARC1_FAKE_PROFILE_FAIL" => fail_profile ? "true" : "false",
                     "ARC1_FAKE_V4_CERTIFICATE_PATH" => v4_certificate_path === nothing ?
                        nothing : String(v4_certificate_path))
    stdout = read(pipeline(ignorestatus(command), stderr=Base.stdout), String)
    return stdout, artifact_path
end

function _arc1_inspect_fake_artifact(root, artifact_path; context_unavailable=false,
                                     projection_counter=nothing,
                                     include_full_v3_evidence=false)
    request = artifact_path * ".inspect.txt"
    write(request, artifact_path * "\n")
    command = `$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$root $(joinpath(root,"sim","arc1","inspect_artifacts.jl")) $request`
    depot = joinpath(dirname(dirname(artifact_path)), "depot")
    mkpath(depot)
    env = Dict("JULIA_DEPOT_PATH" => string(depot, Sys.iswindows() ? ';' : ':', first(DEPOT_PATH)),
        "OPENBLAS_NUM_THREADS" => "1", "JULIA_NUM_THREADS" => "1",
        "ARC1_FAKE_CONTEXT_UNAVAILABLE" => context_unavailable ? "true" : "false",
        "ARC1_INSPECT_INCLUDE_V3_EVIDENCE" => include_full_v3_evidence ? "true" : "false",
        "ARC1_TEST_PROJECTION_COUNTER" => projection_counter === nothing ? "" : String(projection_counter))
    return read(pipeline(addenv(command, env...), stderr=Base.stdout), String)
end

function _arc1_replace_fake_certificate_collection(root, artifact_path, label, replacement;
                                                   missing=false)
    corrupted_path = artifact_path * "." * label * ".jls"
    script_path = corrupted_path * ".jl"
    replacement_expr = repr(replacement)
    mutation = missing ? "delete!(evidence, :v4_tail_certificates)" :
        "evidence[:v4_tail_certificates] = $replacement_expr"
    write(script_path, """
    using HSquared
    root = ARGS[3]
    include(joinpath(root, "sim", "arc1", "engine_io.jl"))
    include(joinpath(root, "sim", "arc1", "artifact_container.jl"))
    artifact = arc1_read_artifact_container(ARGS[1])
    evidence = copy(artifact.v3_profile_evidence)
    $mutation
    result = merge(artifact.result, (; v3_profile_evidence=evidence))
    summary = merge(artifact.receipt_summary, (; v3_profile_evidence=evidence))
    corrupted = merge(artifact, (; v3_profile_evidence=evidence, result,
                                 receipt_summary=summary))
    arc1_write_artifact_container_new(ARGS[2], corrupted)
    """)
    command = `$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$root $script_path $artifact_path $corrupted_path $root`
    depot = joinpath(dirname(dirname(artifact_path)), "depot")
    env = Dict("JULIA_DEPOT_PATH" => string(depot, Sys.iswindows() ? ';' : ':', first(DEPOT_PATH)),
        "OPENBLAS_NUM_THREADS" => "1", "JULIA_NUM_THREADS" => "1")
    run(addenv(command, env...))
    return corrupted_path
end

function _arc1_write_v4_certificate(path, certificate)
    open(path, "w") do io
        serialize(io, certificate)
    end
    return path
end

function _arc1_relabel_fake_artifact(root, artifact_path, status)
    output_path = artifact_path * ".relabeled.jls"
    script_path = artifact_path * ".relabeled.jl"
    write(script_path, """
    using Serialization
    using HSquared
    root = ARGS[3]
    include(joinpath(root, "sim", "arc1", "engine_io.jl"))
    include(joinpath(root, "sim", "arc1", "artifact_container.jl"))
    artifact = arc1_read_artifact_container(ARGS[1])
    metadata = merge(artifact.metadata, (; status=$(repr(String(status)))) )
    relabeled = merge(artifact, (; metadata))
    arc1_write_artifact_container_new(ARGS[2], relabeled)
    """)
    command = `$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$root $script_path $artifact_path $output_path $root`
    depot = joinpath(dirname(dirname(artifact_path)), "depot")
    env = Dict("JULIA_DEPOT_PATH" => string(depot, Sys.iswindows() ? ';' : ':', first(DEPOT_PATH)),
        "OPENBLAS_NUM_THREADS" => "1", "JULIA_NUM_THREADS" => "1")
    run(addenv(command, env...))
    return output_path
end

@testset "Arc1 source-bound one-attempt executor" begin
    include(joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", "engine_io.jl"))
    include(joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", "independent_dgp.jl"))
    artifact_container_source = joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", "artifact_container.jl")
    @test isfile(artifact_container_source)
    if isfile(artifact_container_source)
        include(artifact_container_source)
        function _arc1_rewrite_container_section(path, section_name;
                payload_transform=identity, records_transform=identity)
            bytes = read(path)
            io = IOBuffer(bytes)
            read(io, length(ARC1_CONTAINER_MAGIC)) == ARC1_CONTAINER_MAGIC || error("bad fixture magic")
            arc1_container_read_u16(io) == ARC1_CONTAINER_VERSION || error("bad fixture version")
            count = Int(arc1_container_read_u16(io))
            entries = NamedTuple[]
            for _ in 1:count
                name = arc1_container_read_string(io)
                schema = arc1_container_read_string(io)
                offset = arc1_container_read_u64(io)
                len = arc1_container_read_u64(io)
                records = arc1_container_read_u64(io)
                digest = read(io, 32)
                push!(entries, (; name, schema, offset, len, records, digest))
            end
            payloads = Vector{UInt8}[]
            for entry in entries
                start = Int(entry.offset) + 1
                stop = start + Int(entry.len) - 1
                payload = bytes[start:stop]
                records = entry.records
                if entry.name == section_name
                    payload = payload_transform(payload)
                    records = records_transform(records)
                end
                push!(payloads, payload)
                i = length(payloads)
                entries[i] = (; entry.name, entry.schema, entry.offset,
                    length=UInt64(length(payload)), records,
                    digest=SHA.sha256(payload))
            end
            offsets = zeros(UInt64, length(entries))
            directory = UInt8[]
            for _ in 1:4
                directory = arc1_container_encode_directory(entries, offsets)
                offset = UInt64(length(directory))
                for i in eachindex(entries)
                    offsets[i] = offset
                    offset += entries[i].length
                end
            end
            directory = arc1_container_encode_directory(entries, offsets)
            open(path, "w") do output
                write(output, directory)
                foreach(payload -> write(output, payload), payloads)
            end
            return path
        end
        function _arc1_write_unchecked_container(path, section_name, value)
            payload_io = IOBuffer()
            serialize(payload_io, value)
            payload = take!(payload_io)
            entries = [(name=section_name,
                schema=string(ARC1_CONTAINER_SCHEMA, ":", section_name),
                length=UInt64(length(payload)), records=UInt64(1),
                digest=SHA.sha256(payload))]
            offsets = zeros(UInt64, 1)
            directory = UInt8[]
            for _ in 1:4
                directory = arc1_container_encode_directory(entries, offsets)
                offsets[1] = UInt64(length(directory))
            end
            directory = arc1_container_encode_directory(entries, offsets)
            open(path, "w") do output
                write(output, directory)
                write(output, payload)
            end
            return path
        end
        function _arc1_mutate_container_directory(path, transform)
            bytes = read(path)
            io = IOBuffer(bytes)
            read(io, length(ARC1_CONTAINER_MAGIC))
            arc1_container_read_u16(io)
            count = Int(arc1_container_read_u16(io))
            entries = NamedTuple[]
            for _ in 1:count
                name = arc1_container_read_string(io)
                schema = arc1_container_read_string(io)
                offset, len, records = arc1_container_read_u64(io),
                    arc1_container_read_u64(io), arc1_container_read_u64(io)
                digest = read(io, 32)
                push!(entries, (; name, schema, offset, length=len, records, digest))
            end
            payloads = [bytes[Int(entry.offset)+1:Int(entry.offset+entry.length)]
                for entry in entries]
            entries = transform(entries)
            offsets = UInt64[entry.offset for entry in entries]
            directory = arc1_container_encode_directory(entries, offsets)
            open(path, "w") do output
                write(output, directory)
                foreach(payload -> write(output, payload), payloads)
            end
            return path
        end
        function _arc1_write_profile_row_container(path, row; history=Any[])
            refs = Dict("evidence.arc1_profile_v3_evaluations" => UInt64(1),
                "evidence.arc1_profile_v4_evaluations" => UInt64(1),
                "evaluation.1.events" => UInt64(2),
                "evaluation.1.producer_history" => UInt64(3),
                "evaluation.1.provenance_failures" => UInt64(4))
            evidence = Dict{Symbol,Any}(
                :arc1_profile_v3_evaluations => Arc1ContainerRef(UInt64(1)),
                :arc1_profile_v4_evaluations => Arc1ContainerRef(UInt64(1)))
            sections = Dict{String,Any}(
                "references" => refs, "evidence" => evidence,
                "history_rows" => Any[row], "history" => history)
            return arc1_write_container_new(path, sections)
        end

        @testset "authoritative container rejects malformed identity and serialization" begin
            no_reference = Dict{Symbol,Any}(:arc1_profile_v3_evaluations => Any[])
            @test_throws ArgumentError arc1_container_restore_history(
                no_reference, nothing, Dict{String,UInt64}())

            rows = Any[_arc1_test_profile_row(:events => Arc1ContainerRef(7),
                :producer_history => Arc1ContainerRef(7),
                :event_lengths => Dict(:events => 1, :producer_history => 1))]
            conflicting_records = Any[(; row_index=1, field=:events,
                    event_index=1, event=:event),
                (; row_index=1, field=:producer_history, event_index=1, event=:producer)]
            conflicting_refs = Dict("evaluation.1.events" => UInt64(7),
                "evaluation.1.producer_history" => UInt64(7))
            @test_throws ArgumentError arc1_container_restore_evaluations(
                rows, conflicting_records, conflicting_refs)

            deleted_terminal_rows = Any[_arc1_test_profile_row(
                :events => Arc1ContainerRef(9), :event_lengths => Dict(:events => 2))]
            one_remaining_event = Any[(; row_index=1, field=:events,
                event_index=1, event=:first)]
            @test_throws ArgumentError arc1_container_restore_evaluations(
                deleted_terminal_rows, one_remaining_event,
                Dict("evaluation.1.events" => UInt64(9)))
            malformed_length_key_rows = Any[_arc1_test_profile_row(
                :events => Arc1ContainerRef(10), :event_lengths => Dict(1 => 1))]
            @test_throws ArgumentError arc1_container_restore_evaluations(
                malformed_length_key_rows, one_remaining_event,
                Dict("evaluation.1.events" => UInt64(10)))

            mktempdir() do terminal_dir
                terminal_event_path = joinpath(terminal_dir, "deleted-terminal-event.arc1c")
                terminal_history = Any[_arc1_test_profile_row(:events => Any[
                    (; value=:first), (; value=:terminal)])]
                terminal_evidence = Dict{Symbol,Any}(
                    :arc1_profile_v3_evaluations => terminal_history,
                    :arc1_profile_v4_evaluations => terminal_history)
                arc1_write_artifact_container_new(terminal_event_path,
                    (; v3_profile_evidence=terminal_evidence))
                delete_terminal_history_record(payload) = begin
                    input = IOBuffer(payload)
                    records = Vector{UInt8}[]
                    while !eof(input)
                        n = Int(arc1_container_read_u64(input))
                        bytes = read(input, n)
                        length(bytes) == n || error("bad history fixture")
                        push!(records, bytes)
                    end
                    length(records) == 2 || error("expected two terminal-history records")
                    pop!(records)
                    output = IOBuffer()
                    for bytes in records
                        arc1_container_write_u64(output, length(bytes))
                        write(output, bytes)
                    end
                    take!(output)
                end
                _arc1_rewrite_container_section(terminal_event_path, "history";
                    payload_transform=delete_terminal_history_record,
                    records_transform=n -> n - UInt64(1))
                _arc1_assert_argument_error_message(
                    () -> arc1_read_artifact_container(terminal_event_path),
                    "profile event count differs from the retained expected length")

                valid_baseline_path = joinpath(terminal_dir, "valid-baseline.arc1c")
                arc1_write_artifact_container_new(valid_baseline_path,
                    (; v3_profile_evidence=terminal_evidence))
                valid_baseline = arc1_read_artifact_container(valid_baseline_path)
                @test haskey(valid_baseline.v3_profile_evidence,
                    :arc1_profile_v3_evaluations)

                unsupported_scalar_path = joinpath(terminal_dir, "unsupported-scalar.arc1c")
                _arc1_assert_argument_error_message(
                    () -> arc1_write_container_new(unsupported_scalar_path,
                        Dict("payload" => Arc1ContainerUnsupportedInteger(3))),
                    "unsupported Arc1 container type")
                unapproved_enum_path = joinpath(terminal_dir, "unapproved-enum.arc1c")
                _arc1_assert_argument_error_message(
                    () -> arc1_write_container_new(unapproved_enum_path,
                        Dict("payload" => Arc1ContainerUnapprovedValue)),
                    "unsupported Arc1 container type")
                @test arc1_container_validate_supported(
                    Optim.TerminationCode.NoObjectiveChange) === nothing
                heterogeneous_named_tuples = NamedTuple[(; value=1), (; value=2.0)]
                @test arc1_container_validate_supported(heterogeneous_named_tuples;
                    path="raw_selection[18]") === nothing
                named_tuple_path = joinpath(terminal_dir,
                    "heterogeneous-named-tuple-vector.arc1c")
                arc1_write_container_new(named_tuple_path,
                    Dict("payload" => heterogeneous_named_tuples))
                named_tuple_roundtrip = arc1_read_container(named_tuple_path)["payload"]
                @test named_tuple_roundtrip == heterogeneous_named_tuples
                fixed_key_named_tuples = NamedTuple{(:kind, :zero_index)}[
                    (; kind=:candidate, zero_index=1),
                    (; kind=:boundary, zero_index=2)]
                @test eltype(fixed_key_named_tuples) === NamedTuple{(:kind, :zero_index)}
                @test !isconcretetype(eltype(fixed_key_named_tuples))
                @test arc1_container_validate_supported(fixed_key_named_tuples;
                    path="profile.targets[:additive_variance].profile_diagnostics") === nothing
                fixed_key_named_tuple_path = joinpath(terminal_dir,
                    "fixed-key-abstract-named-tuple-vector.arc1c")
                arc1_write_container_new(fixed_key_named_tuple_path,
                    Dict("payload" => fixed_key_named_tuples))
                fixed_key_named_tuple_roundtrip =
                    arc1_read_container(fixed_key_named_tuple_path)["payload"]
                @test fixed_key_named_tuple_roundtrip == fixed_key_named_tuples
                raw_selection = Any[nothing for _ in 1:18]
                raw_selection[18] = heterogeneous_named_tuples
                artifact_path = joinpath(terminal_dir,
                    "heterogeneous-raw-selection.arc1c")
                arc1_write_artifact_container_new(artifact_path, (; raw_selection))
                artifact_roundtrip = arc1_read_artifact_container(artifact_path)
                @test artifact_roundtrip.raw_selection[18] == heterogeneous_named_tuples
                unsupported_named_tuple_value = NamedTuple[(; value=1),
                    (; value=Set([2]))]
                @test_throws ArgumentError arc1_container_validate_supported(
                    unsupported_named_tuple_value; path="raw_selection[18]")
                pedigree = Pedigree(["founder", "offspring"], [0, 0], [0, 1], [1, 2])
                @test arc1_container_validate_supported((pedigree,); path="design") === nothing
                pedigree_path = joinpath(terminal_dir, "pedigree-design.arc1c")
                arc1_write_container_new(pedigree_path, Dict("design" => (pedigree,)))
                pedigree_roundtrip = arc1_read_container(pedigree_path)["design"][1]
                @test pedigree_roundtrip.ids == pedigree.ids
                @test pedigree_roundtrip.original_order == pedigree.original_order
                invalid_optim_enum = reinterpret(
                    typeof(Optim.TerminationCode.NoObjectiveChange), Int32(0x7fffffff))
                _arc1_assert_argument_error_message(
                    () -> arc1_container_validate_supported(invalid_optim_enum),
                    "unsupported Arc1 enum value")

                empty_ref_vector_path = joinpath(terminal_dir, "empty-ref-vector.arc1c")
                _arc1_assert_argument_error_message(
                    () -> arc1_write_container_new(empty_ref_vector_path,
                        Dict("payload" => Ref{Int}[])), "unsupported Arc1 container type")
                empty_ref_dict_path = joinpath(terminal_dir, "empty-ref-dict.arc1c")
                _arc1_assert_argument_error_message(
                    () -> arc1_write_container_new(empty_ref_dict_path,
                        Dict("payload" => Dict{String,Ref{Int}}())),
                    "unsupported Arc1 container type")
                empty_three_dimensional_path = joinpath(terminal_dir, "empty-3d-array.arc1c")
                _arc1_assert_argument_error_message(
                    () -> arc1_write_container_new(empty_three_dimensional_path,
                        Dict("payload" => Array{Float64,3}(undef, 0, 0, 0))),
                    "unsupported Arc1 container type or dimensions")
                unchecked_empty_path = joinpath(terminal_dir, "unchecked-empty-ref.arc1c")
                _arc1_write_unchecked_container(unchecked_empty_path, "payload", Ref{Int}[])
                _arc1_assert_argument_error_message(
                    () -> arc1_read_container(unchecked_empty_path),
                    "unsupported Arc1 container type")
                unchecked_empty_dict_path = joinpath(terminal_dir, "unchecked-empty-ref-dict.arc1c")
                _arc1_write_unchecked_container(unchecked_empty_dict_path, "payload",
                    Dict{Symbol,Ref{Int}}())
                _arc1_assert_argument_error_message(
                    () -> arc1_read_container(unchecked_empty_dict_path),
                    "unsupported Arc1 container type")
                sparse_index_path = joinpath(terminal_dir, "unsupported-sparse-index.arc1c")
                bad_sparse = SparseMatrixCSC{Float64,UInt64}(0, 0, UInt64[1], UInt64[], Float64[])
                _arc1_assert_argument_error_message(
                    () -> arc1_write_container_new(sparse_index_path,
                        Dict("payload" => bad_sparse)), "unsupported Arc1 container sparse index type")
                unchecked_sparse_path = joinpath(terminal_dir, "unchecked-sparse-index.arc1c")
                _arc1_write_unchecked_container(unchecked_sparse_path, "payload", bad_sparse)
                _arc1_assert_argument_error_message(
                    () -> arc1_read_container(unchecked_sparse_path),
                    "unsupported Arc1 container sparse index type")

                unsupported_row_path = joinpath(terminal_dir, "unsupported-row-field.arc1c")
                bad_row = _arc1_test_profile_row(:events => Any[], :surprise => true)
                bad_history = Any[bad_row]
                bad_evidence = Dict{Symbol,Any}(
                    :arc1_profile_v3_evaluations => bad_history,
                    :arc1_profile_v4_evaluations => bad_history)
                _arc1_assert_argument_error_message(
                    () -> arc1_write_artifact_container_new(unsupported_row_path,
                        (; v3_profile_evidence=bad_evidence)),
                    "profile history row has unsupported fields")
                bad_target_path = joinpath(terminal_dir, "invalid-row-target.arc1c")
                bad_target_history = Any[_arc1_test_profile_row(:events => Any[], :target => "h2")]
                bad_target_evidence = Dict{Symbol,Any}(
                    :arc1_profile_v3_evaluations => bad_target_history,
                    :arc1_profile_v4_evaluations => bad_target_history)
                _arc1_assert_argument_error_message(
                    () -> arc1_write_artifact_container_new(bad_target_path,
                        (; v3_profile_evidence=bad_target_evidence)),
                    "profile history row target is invalid")
                malformed_row_values = (
                    (:fixed_value, true, "profile history row fixed_value must be real"),
                    (:status, "ok", "profile history row status must be a symbol"),
                    (:events, (), "profile history row events must be a vector or reference"),
                    (:max_valid_loglik, "-Inf", "profile history row max_valid_loglik must be real"),
                    (:event_lengths, Dict(:events => true),
                        "profile history row event_lengths must map symbols to nonnegative Int values"))
                for (index, (field, bad_value, expected_error)) in
                    pairs(malformed_row_values)
                    malformed_row_path = joinpath(terminal_dir,
                        "invalid-row-$(field).arc1c")
                    malformed_history = Any[_arc1_test_profile_row(
                        :events => Any[], field => bad_value)]
                    malformed_evidence = Dict{Symbol,Any}(
                        :arc1_profile_v3_evaluations => malformed_history,
                        :arc1_profile_v4_evaluations => malformed_history)
                    _arc1_assert_argument_error_message(
                        () -> arc1_write_artifact_container_new(malformed_row_path,
                            (; v3_profile_evidence=malformed_evidence)), expected_error)

                    reader_row = _arc1_test_profile_row(
                        :events => Arc1ContainerRef(UInt64(2)),
                        :producer_history => Arc1ContainerRef(UInt64(3)),
                        :provenance_failures => Arc1ContainerRef(UInt64(4)),
                        :event_lengths => Dict(:events => 0,
                            :producer_history => 0, :provenance_failures => 0),
                        field => bad_value)
                    malformed_reader_path = joinpath(terminal_dir,
                        "invalid-reader-row-$(field).arc1c")
                    _arc1_write_profile_row_container(malformed_reader_path, reader_row)
                    _arc1_assert_argument_error_message(
                        () -> arc1_read_artifact_container(malformed_reader_path),
                        expected_error)
                end

                bad_producer = (; path="candidate[1]", owner=:candidate,
                    candidate_id=1, source_id=(:producer_record, :candidate, 1,
                        "candidate[1]", 1), record="not a producer record")
                mismatched_producer_source = (; path="candidate[2]", owner=:candidate,
                    candidate_id=1, source_id=(:producer_record, :candidate, 1,
                        "candidate[1]", 1), record=(; kind=:bounded_probe))
                producer_identity_cases = (
                    (; path="candidate[1]", owner=:candidate, candidate_id=1,
                        source_id=(:wrong_producer_record, :candidate, 1,
                            "candidate[1]", 1), record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=1,
                        source_id=(:producer_record, :candidate, 1, "candidate[1]"),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=1,
                        source_id=(:producer_record, :shared, 1, "candidate[1]", 1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=1,
                        source_id=(:producer_record, :candidate, 2, "candidate[1]", 1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=0,
                        source_id=(:producer_record, :candidate, 0, "candidate[1]", 1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=-1,
                        source_id=(:producer_record, :candidate, -1, "candidate[1]", 1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id="1",
                        source_id=(:producer_record, :candidate, "1", "candidate[1]", 1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=1,
                        source_id=(:producer_record, :candidate, 1, "candidate[1]", true),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=1,
                        source_id=(:producer_record, :candidate, 1, "candidate[1]", 0),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=true,
                        source_id=(:producer_record, :candidate, true, "candidate[1]", 1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:shared, candidate_id=1,
                        source_id=(:producer_record, :shared, 1, "candidate[1]", 1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=nothing, candidate_id=1,
                        source_id=(:producer_record, nothing, 1, "candidate[1]", 1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:unapproved, candidate_id=nothing,
                        source_id=(:producer_record, :unapproved, nothing, "candidate[1]", 1),
                        record=(; kind=:bounded_probe)),
                    (; path=1, owner=:candidate, candidate_id=1,
                        source_id=(:producer_record, :candidate, 1, 1, 1),
                        record=(; kind=:bounded_probe)),
                    (; path="", owner=:candidate, candidate_id=1,
                        source_id=(:producer_record, :candidate, 1, "", 1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=1,
                        source_id="not-a-tuple", record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=1,
                        source_id=(:producer_record, :candidate, 1, "candidate[1]", -1),
                        record=(; kind=:bounded_probe)),
                    (; path="candidate[1]", owner=:candidate, candidate_id=1,
                        source_id=(:producer_record, :candidate, 1, "candidate[1]", BigInt(1)),
                        record=(; kind=:bounded_probe)))
                bad_provenance = (; path=1, field=:value, reason=:invalid,
                    value=nothing, tag=nothing, expected_ve=0.0)
                nested_row_cases = vcat([
                    (:producer_history, bad_producer,
                        "profile history producer_history entry values are invalid"),
                    (:producer_history, mismatched_producer_source,
                        "profile history producer_history entry values are invalid")],
                    [(:producer_history, item,
                        "profile history producer_history entry values are invalid")
                     for item in producer_identity_cases],
                    [
                    (:provenance_failures, bad_provenance,
                        "profile history provenance_failures entry values are invalid")])
                for (index, (field, bad_item, expected_error)) in
                        enumerate(nested_row_cases)
                    writer_path = joinpath(terminal_dir,
                        "invalid-nested-$(field)-$(index)-writer.arc1c")
                    bad_history = Any[_arc1_test_profile_row(field => Any[bad_item])]
                    bad_evidence = Dict{Symbol,Any}(
                        :arc1_profile_v3_evaluations => bad_history,
                        :arc1_profile_v4_evaluations => bad_history)
                    _arc1_assert_argument_error_message(
                        () -> arc1_write_artifact_container_new(writer_path,
                            (; v3_profile_evidence=bad_evidence)), expected_error)

                    reader_row = _arc1_test_profile_row(
                        :events => Arc1ContainerRef(UInt64(2)),
                        :producer_history => Arc1ContainerRef(UInt64(3)),
                        :provenance_failures => Arc1ContainerRef(UInt64(4)),
                        :event_lengths => Dict(:events => 0,
                            :producer_history => field === :producer_history ? 1 : 0,
                            :provenance_failures => field === :provenance_failures ? 1 : 0))
                    reader_history = Any[(; row_index=1, field,
                        event_index=1, event=bad_item)]
                    reader_path = joinpath(terminal_dir,
                        "invalid-nested-$(field)-$(index)-reader.arc1c")
                    _arc1_write_profile_row_container(reader_path, reader_row;
                        history=reader_history)
                    _arc1_assert_argument_error_message(
                        () -> arc1_read_artifact_container(reader_path), expected_error)
                end

                directory_base = joinpath(terminal_dir, "directory-adversary.arc1c")
                arc1_write_container_new(directory_base,
                    Dict("alpha" => (; value=1), "beta" => (; value=2),
                         "gamma" => (; value=3)))
                duplicate_directory = cp(directory_base,
                    joinpath(terminal_dir, "duplicate-directory.arc1c"); force=true)
                _arc1_mutate_container_directory(duplicate_directory,
                    entries -> [entries[1]; [(; entries[2]..., name=entries[1].name,
                        schema=entries[1].schema)]; entries[3:3]])
                _arc1_assert_argument_error_message(
                    () -> arc1_read_container(duplicate_directory),
                    "duplicate Arc1 container section")
                reordered_directory = cp(directory_base,
                    joinpath(terminal_dir, "reordered-directory.arc1c"); force=true)
                _arc1_mutate_container_directory(reordered_directory,
                    entries -> [merge(entries[1], (; name="zeta", schema="$(ARC1_CONTAINER_SCHEMA):zeta")),
                        entries[2], entries[3]])
                _arc1_assert_argument_error_message(
                    () -> arc1_read_container(reordered_directory), "container sections are reordered")
                overlapping_directory = cp(directory_base,
                    joinpath(terminal_dir, "overlapping-directory.arc1c"); force=true)
                _arc1_mutate_container_directory(overlapping_directory,
                    entries -> [entries[1], merge(entries[2], (; offset=entries[1].offset)), entries[3]])
                _arc1_assert_argument_error_message(
                    () -> arc1_read_container(overlapping_directory),
                    "container sections are reordered or overlap")

                valid_event_row = Any[_arc1_test_profile_row(
                    :events => Arc1ContainerRef(12), :event_lengths => Dict(:events => 1))]
                event_refs = Dict("evaluation.1.events" => UInt64(12))
                event_base = (; row_index=1, field=:events, event_index=1, event=:ok)
                _arc1_assert_argument_error_message(
                    () -> arc1_container_restore_evaluations(valid_event_row,
                        Any[merge(event_base, (; extra=:unexpected))], event_refs),
                    "profile event stream record fields differ")
                _arc1_assert_argument_error_message(
                    () -> arc1_container_restore_evaluations(valid_event_row,
                        Any[merge(event_base, (; event_index=true))], event_refs),
                    "profile event row and index must be positive Int values")
                _arc1_assert_argument_error_message(
                    () -> arc1_container_restore_evaluations(valid_event_row,
                        Any[merge(event_base, (; row_index=1.0))], event_refs),
                    "profile event row and index must be positive Int values")
                _arc1_assert_argument_error_message(
                    () -> arc1_container_restore_evaluations(valid_event_row,
                        Any[merge(event_base, (; row_index=2))], event_refs),
                    "profile event row index is out of range")
                _arc1_assert_argument_error_message(
                    () -> arc1_container_restore_evaluations(valid_event_row,
                        Any[merge(event_base, (; field="events"))], event_refs),
                    "profile event field is unsupported")
                unexpected_row_field = copy(only(valid_event_row))
                unexpected_row_field[:surprise] = true
                _arc1_assert_argument_error_message(
                    () -> arc1_container_restore_evaluations(Any[unexpected_row_field],
                        Any[event_base], event_refs), "profile history row has unsupported fields")

                for shadow_name in ("v3_profile_evidence", "receipt_summary")
                    shadow_path = joinpath(terminal_dir, "shadow-" * shadow_name * ".arc1c")
                    arc1_write_container_new(shadow_path,
                        Dict("evidence" => terminal_evidence, "summary" => (; status="ok"),
                             shadow_name => (; status="contradictory")))
                    _arc1_assert_argument_error_message(
                        () -> arc1_read_artifact_container(shadow_path),
                        "unsupported Arc1 artifact sections: $shadow_name")
                end

                publication_sections = Dict("alpha" => [1, 2],
                    "beta" => (; status=:ok), "gamma" => Dict(:value => 3.0))
                interruption_points = Any[(:section_staged, name)
                    for name in keys(publication_sections)]
                append!(interruption_points, [(:directory_written, nothing)])
                append!(interruption_points, [(:section_published, name)
                    for name in keys(publication_sections)])
                push!(interruption_points, (:before_publish, nothing))
                mktempdir() do publication_dir
                    for (stage, name) in interruption_points
                        partial_path = joinpath(publication_dir, "interrupted.arc1c")
                        hook = (seen_stage, seen_name) -> begin
                            stage === seen_stage && name === seen_name &&
                                throw(InterruptException())
                        end
                        @test_throws InterruptException arc1_write_container_new(
                            partial_path, publication_sections; publication_hook=hook)
                        @test !ispath(partial_path)
                        @test isempty(readdir(publication_dir))
                    end
                    complete_path = joinpath(publication_dir, "complete.arc1c")
                    arc1_write_container_new(complete_path, publication_sections)
                    @test arc1_read_container(complete_path)["alpha"] == [1, 2]
                end

                function decode_history_records(payload)
                    input = IOBuffer(payload)
                    records = Any[]
                    while !eof(input)
                        n = Int(arc1_container_read_u64(input))
                        bytes = read(input, n)
                        length(bytes) == n || error("truncated history record")
                        push!(records, deserialize(IOBuffer(bytes)))
                    end
                    return records
                end
                function encode_history_records(records)
                    output = IOBuffer()
                    for record in records
                        record_bytes = let buffer = IOBuffer()
                            serialize(buffer, record)
                            take!(buffer)
                        end
                        arc1_container_write_u64(output, length(record_bytes))
                        write(output, record_bytes)
                    end
                    return take!(output)
                end
                history_baseline = joinpath(terminal_dir, "history-mutation-baseline.arc1c")
                history_fixture = Any[_arc1_test_profile_row(:events => Any[
                    (; value=:first), (; value=:middle), (; value=:terminal)])]
                history_evidence = Dict{Symbol,Any}(
                    :arc1_profile_v3_evaluations => history_fixture,
                    :arc1_profile_v4_evaluations => history_fixture)
                arc1_write_artifact_container_new(history_baseline,
                    (; v3_profile_evidence=history_evidence))
                baseline_history = arc1_read_artifact_container(history_baseline)
                @test baseline_history.v3_profile_evidence[
                    :arc1_profile_v3_evaluations][1][:events] == Any[
                        (; value=:first), (; value=:middle), (; value=:terminal)]
                function assert_history_mutation_fails(label, mutate, message_part)
                    path = joinpath(terminal_dir, "history-$(label).arc1c")
                    cp(history_baseline, path)
                    mutated = Ref{Any}(nothing)
                    transform = payload -> begin
                        mutated[] = mutate(decode_history_records(payload))
                        encode_history_records(mutated[])
                    end
                    _arc1_rewrite_container_section(path, "history";
                        payload_transform=transform,
                        records_transform=_ -> UInt64(length(mutated[])))
                    _arc1_assert_argument_error_message(
                        () -> arc1_read_artifact_container(path), message_part)
                end
                event_records = let payload = read(history_baseline)
                    io = IOBuffer(payload)
                    seek(io, length(ARC1_CONTAINER_MAGIC))
                    arc1_container_read_u16(io)
                    count = Int(arc1_container_read_u16(io))
                    entries = NamedTuple[]
                    for _ in 1:count
                        name = arc1_container_read_string(io)
                        schema = arc1_container_read_string(io)
                        offset = arc1_container_read_u64(io)
                        length = arc1_container_read_u64(io)
                        records = arc1_container_read_u64(io)
                        digest = read(io, 32)
                        push!(entries, (; name, schema, offset, length, records, digest))
                    end
                    history_entry = only(filter(entry -> entry.name == "history", entries))
                    start = Int(history_entry.offset) + 1
                    stop = start + Int(history_entry.length) - 1
                    decode_history_records(payload[start:stop])
                end
                assert_history_mutation_fails("middle-delete",
                    records -> Any[records[1], records[3]],
                    "profile event stream is reordered or has a gap")
                assert_history_mutation_fails("insert",
                    records -> vcat(records, [merge(last(records), (; event_index=4))]),
                    "profile event count differs from the retained expected length")
                assert_history_mutation_fails("duplicate",
                    records -> Any[records[1], records[1], records[2:end]...],
                    "profile event stream is reordered or has a gap")
                assert_history_mutation_fails("reorder",
                    records -> Any[records[2], records[1], records[3]],
                    "profile event stream is reordered or has a gap")
                assert_history_mutation_fails("wrong-row",
                    records -> Any[merge(records[1], (; row_index=2)), records[2:end]...],
                    "profile event row index is out of range")
                assert_history_mutation_fails("wrong-field",
                    records -> Any[merge(records[1], (; field=:unknown)), records[2:end]...],
                    "profile event field is unsupported")
                assert_history_mutation_fails("extra-event-field",
                    records -> Any[merge(records[1], (; unexpected=:value)), records[2:end]...],
                    "profile event stream record fields differ")
                assert_history_mutation_fails("bool-index",
                    records -> Any[merge(records[1], (; event_index=true)), records[2:end]...],
                    "profile event row and index must be positive Int values")
                @test length(event_records) == 3

                unknown_writer_path = joinpath(terminal_dir, "unknown-writer-section.arc1c")
                @test_throws ArgumentError arc1_write_artifact_container_new(
                    unknown_writer_path,
                    (; v3_profile_evidence=terminal_evidence, surprise_field=:unexpected))
                unknown_reader_path = joinpath(terminal_dir, "unknown-reader-section.arc1c")
                arc1_write_container_new(unknown_reader_path,
                    Dict("surprise_field" => :unexpected))
                @test_throws ArgumentError arc1_read_artifact_container(unknown_reader_path)
            end

            mktempdir() do directory
                record_path = joinpath(directory, "bad-record-count.arc1c")
                arc1_write_container_new(record_path, Dict("payload" => [1, 2]))
                _arc1_rewrite_container_section(record_path, "payload";
                    records_transform=n -> n + UInt64(1))
                @test_throws ArgumentError arc1_read_container(record_path)

                native_path = joinpath(directory, "native-trailer.arc1c")
                arc1_write_container_new(native_path, Dict("payload" => [1, 2]))
                _arc1_rewrite_container_section(native_path, "payload";
                    payload_transform=payload -> vcat(payload, UInt8[0xff]))
                @test_throws ArgumentError arc1_read_container(native_path)

                history_path = joinpath(directory, "history-trailer.arc1c")
                arc1_write_container_new(history_path,
                    Dict("history" => Any[(; value=:retained)]))
                append_event_trailer(payload) = begin
                    input = IOBuffer(payload)
                    record_size = Int(arc1_container_read_u64(input))
                    record = read(input, record_size)
                    remainder = read(input)
                    output = IOBuffer()
                    arc1_container_write_u64(output, length(record) + 1)
                    write(output, record, UInt8[0xff], remainder)
                    take!(output)
                end
                _arc1_rewrite_container_section(history_path, "history";
                    payload_transform=append_event_trailer)
                @test_throws ArgumentError arc1_read_container(history_path)

                short_record_path = joinpath(directory, "short-event-record.arc1c")
                arc1_write_container_new(short_record_path,
                    Dict("history" => Any[(; value=:retained)]))
                declare_overlong_record(payload) = begin
                    input = IOBuffer(payload)
                    record_size = arc1_container_read_u64(input)
                    output = IOBuffer()
                    arc1_container_write_u64(output, record_size + UInt64(1))
                    write(output, read(input))
                    take!(output)
                end
                _arc1_rewrite_container_section(short_record_path, "history";
                    payload_transform=declare_overlong_record)
                @test_throws ArgumentError arc1_read_container(short_record_path)

                category_alias_path = joinpath(directory, "cross-category-object-id.arc1c")
                history = Any[_arc1_test_profile_row(:events => Any[(; value=:event)])]
                evidence = Dict{Symbol,Any}(:arc1_profile_v3_evaluations => history,
                    :arc1_profile_v4_evaluations => history)
                arc1_write_artifact_container_new(category_alias_path,
                    (; v3_profile_evidence=evidence))
                colliding_id = arc1_read_container(category_alias_path)["references"][
                    "evidence.arc1_profile_v3_evaluations"]
                collide_event_with_history(payload) = begin
                    references = deserialize(IOBuffer(payload))
                    references["evaluation.1.events"] = references[
                        "evidence.arc1_profile_v3_evaluations"]
                    output = IOBuffer()
                    serialize(output, references)
                    take!(output)
                end
                _arc1_rewrite_container_section(category_alias_path, "references";
                    payload_transform=collide_event_with_history)
                collide_history_row_marker(payload) = begin
                    rows = deserialize(IOBuffer(payload))
                    rows[1][:events] = Arc1ContainerRef(colliding_id)
                    output = IOBuffer()
                    serialize(output, rows)
                    take!(output)
                end
                _arc1_rewrite_container_section(category_alias_path, "history_rows";
                    payload_transform=collide_history_row_marker)
                category_error = try
                    arc1_read_artifact_container(category_alias_path)
                    nothing
                catch error
                    error
                end
                @test category_error isa ArgumentError
                @test sprint(showerror, category_error) ==
                    "ArgumentError: container object ID crosses semantic categories"

                certificate_conflict_path = joinpath(directory, "certificate-authority-conflict.arc1c")
                arc1_write_artifact_container_new(certificate_conflict_path,
                    (; v3_profile_evidence=Dict{Symbol,Any}(
                        :v4_tail_certificates => (; authority=:separate_section))))
                add_inline_certificate_conflict(payload) = begin
                    stored = deserialize(IOBuffer(payload))
                    stored[:v4_tail_certificates] = (; authority=:inline_conflict)
                    output = IOBuffer()
                    serialize(output, stored)
                    take!(output)
                end
                _arc1_rewrite_container_section(certificate_conflict_path, "evidence";
                    payload_transform=add_inline_certificate_conflict)
                @test_throws ArgumentError arc1_read_artifact_container(certificate_conflict_path)
            end
        end

        @testset "authoritative container round-trips typed sections and alias topology" begin
            history = Any[Dict{Symbol,Any}(:kind => :raw, :value => missing,
                :components => reshape(Float64[1, NaN, Inf, -Inf], 2, 2),
                :seed => typemax(UInt64), :candidate => (nothing, :ok))]
            raw_profile = (; status=:ok, exact=Rational{BigInt}(big(5), big(7)))
            raw_result = (; status="ok", raw_profile, history)
            summary = (; status="ok", history=copy(history))
            refs = arc1_container_reference_table(Dict{String,Any}("profile" => raw_profile,
                "result" => raw_result, "summary" => summary, "history" => history,
                "history_alias" => history))
            @test refs["history"] == refs["history_alias"]
            mktempdir() do directory
                path = joinpath(directory, "fixture.arc1c")
                section_values = Dict{String,Any}(
                    "profile" => raw_profile,
                    "result" => raw_result,
                    "summary" => summary,
                    "history" => history,
                    "references" => refs,
                )
                digest = arc1_write_container_new(path, section_values)
                @test digest == bytes2hex(sha256(read(path)))
                restored = arc1_read_container(path)
                @test isequal(restored["profile"], raw_profile)
                @test isequal(restored["result"], raw_result)
                @test isequal(restored["summary"], summary)
                @test restored["references"]["history"] ==
                      restored["references"]["history_alias"]
                @test arc1_container_object(restored, "history", "history_alias") ===
                      restored["history"]
                @test_throws ArgumentError arc1_write_container_new(path, section_values)
                unsupported_path = joinpath(directory, "unsupported-ref.arc1c")
                @test_throws ArgumentError arc1_write_container_new(unsupported_path,
                    Dict("payload" => (; nested=Ref(17))))
                unchecked_path = joinpath(directory, "unchecked-ref.arc1c")
                _arc1_write_unchecked_container(unchecked_path, "payload",
                    (; nested=Ref(17)))
                @test_throws ArgumentError arc1_read_container(unchecked_path)
                bytes = read(path)
                old_version_bytes = copy(bytes)
                old_version_bytes[length(ARC1_CONTAINER_MAGIC) + 1] = 0x01
                old_version_bytes[length(ARC1_CONTAINER_MAGIC) + 2] = 0x00
                old_version_path = path * ".old-version"
                write(old_version_path, old_version_bytes)
                @test_throws ArgumentError arc1_read_container(old_version_path)
                truncated_path = path * ".truncated"
                write(truncated_path, bytes[1:end-1])
                @test_throws ArgumentError arc1_read_container(truncated_path)
                corrupted_path = path * ".corrupted"
                bytes[end] ⊻= 0x01
                write(corrupted_path, bytes)
                @test_throws ArgumentError arc1_read_container(corrupted_path)
            end
        end
        @testset "authoritative container streams profile events and preserves entry state" begin
            events = Any[Dict{Symbol,Any}(:kind => :raw, :value => 1.0,
                    :tuple => (missing, nothing, NaN)),
                Dict{Symbol,Any}(:kind => :centered, :value => Inf,
                    :seed => typemax(UInt64))]
            gap = setprecision(BigFloat, 256) do
                BigFloat(1) / BigFloat(3)
            end
            history = Any[_arc1_test_profile_row(:target => :residual_variance,
                :events => events, :producer_history => Any[(; path="producer[1]",
                    owner=:shared, candidate_id=nothing,
                    source_id=(:producer_record, :shared, nothing, "producer[1]", 1),
                    record=(; kind=:bounded_probe))],
                :provenance_failures => Any[],
                :max_valid_loglik => -1.0, :max_valid_centered_loglik => -1.0,
                :initial_certificate =>
                    (determinant=Rational{BigInt}(big(17), big(3)), gap))]
            sink = Dict{Symbol,Any}(:requested_method_version => "arc1_profile_v4",
                :actual_method_version => "arc1_profile_v4",
                :arc1_profile_v3_evaluations => history,
                :arc1_profile_v4_evaluations => history)
            compact_evidence = (; requested_method_version="arc1_profile_v4",
                actual_method_version="arc1_profile_v4", returned_method_version="arc1_profile_v4",
                source_identity=repeat("a", 64), history_aliases_match=true,
                history_row_count=1, history_event_count=2,
                v4_tail_certificates=Any[])
            result = (; status="ok", v3_profile_evidence=sink,
                point_fit_candidate=(status=:accepted, reasons=(:a, :b)))
            summary = (; status="ok", v3_profile_evidence=sink)
            artifact = (; metadata=(; status="ok"), data=(; seed=typemax(UInt64)),
                design=(; y=Float64[1, 2]), profile=(; point_fit=result.point_fit_candidate),
                result, v3_profile_evidence=sink, receipt_summary=summary,
                v3_profile_evidence_summary=compact_evidence)
            source_refs = arc1_container_reference_table(artifact)
            @test source_refs["evidence.arc1_profile_v3_evaluations"] ==
                  source_refs["evidence.arc1_profile_v4_evaluations"]
            @test source_refs["evaluation.1.events"] !=
                  source_refs["evaluation.1.producer_history"]
            mktempdir() do directory
                path = joinpath(directory, "attempt.jls")
                digest = arc1_write_artifact_container_new(path, artifact)
                @test digest == arc1_artifact_sha256(path)
                restored = arc1_read_artifact_container(path)
                v3 = restored.v3_profile_evidence[:arc1_profile_v3_evaluations]
                v4 = restored.v3_profile_evidence[:arc1_profile_v4_evaluations]
                @test v3 === v4
                @test restored.result.v3_profile_evidence === restored.v3_profile_evidence
                @test restored.receipt_summary.v3_profile_evidence === restored.v3_profile_evidence
                @test restored.v3_profile_evidence_summary == compact_evidence
                @test isequal(v3, history)
                @test restored.result.point_fit_candidate == result.point_fit_candidate
            end
            copied_sink = Dict{Symbol,Any}(:arc1_profile_v3_evaluations => deepcopy(history),
                :arc1_profile_v4_evaluations => deepcopy(history))
            @test_throws ArgumentError arc1_container_reference_table(
                (; v3_profile_evidence=copied_sink))
            pre_entry = Dict{Symbol,Any}(:requested_method_version => "arc1_profile_v4")
            pre_entry_artifact = (; metadata=(; status="interrupted"),
                v3_profile_evidence=pre_entry)
            mktempdir() do directory
                path = joinpath(directory, "pre-entry.jls")
                arc1_write_artifact_container_new(path, pre_entry_artifact)
                restored = arc1_read_artifact_container(path)
                @test !haskey(restored.v3_profile_evidence, :arc1_profile_v3_evaluations)
                @test !haskey(restored.v3_profile_evidence, :arc1_profile_v4_evaluations)
            end
        end
    end
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
        exact_rational = Rational{BigInt}(big(12345678901234567890), big(7))
        exact_bigfloat = setprecision(BigFloat, 256) do
            BigFloat(1) / BigFloat(3)
        end
        exact_json = arc1_json((; exact_rational, exact_bigfloat))
        @test occursin("\"__arc1_rational__\"", exact_json)
        @test occursin("\"numerator\":\"12345678901234567890\"", exact_json)
        @test occursin("\"denominator\":\"7\"", exact_json)
        @test occursin("\"type\":\"Rational{BigInt}\"", exact_json)
        @test occursin("\"__arc1_bigfloat__\"", exact_json)
        @test occursin("\"precision\":256", exact_json)
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
            (; requested_method_version="arc1_profile_v4",
               actual_method_version="arc1_profile_v4",
               source_identity=repeat("a", 64),
               arc1_profile_v3_evaluations=transport.ledger,
               arc1_profile_v4_evaluations=transport.ledger),
            (; unsupported=Ref(17))))
        @test_throws ArgumentError arc1_json(native_with_unsupported_leaf)
        projected, projection_error = arc1_receipt_json(
            (; status="interrupted", v3_profile_evidence=native_with_unsupported_leaf);
            fallback_fields=(; preserve_original_error=true, mode="engineering_probe",
                outer=1, seed_string="99", status="interrupted",
                failure_reason="InterruptException", error_type="InterruptException",
                requested_profile_method_version="arc1_profile_v4",
                profile_method_version="arc1_profile_v4",
                profile_method_version_mismatch=false,
                profile_source_identity=repeat("a", 64),
                loaded_arc1_source_identity=repeat("b", 64),
                artifact_path="retained.jls", artifact_sha256="abc",
                retention_error=nothing))
        @test projection_error isa ArgumentError
        @test occursin("\"status\":\"interrupted\"", projected)
        @test occursin("\"error_type\":\"InterruptException\"", projected)
        @test occursin("\"profile_method_version\":\"arc1_profile_v4\"", projected)
        @test occursin("\"artifact_path\":\"retained.jls\"", projected)
        @test occursin("receipt_projection_error", projected)
    end

    @testset "fresh-process fake-engine wiring and evidence" begin
        signature = "function arc1_raw_result_projection_difference(payload, result, metadata)"
        for newline in ("\n", "\r\n")
            injected = _arc1_inject_projection_counter(signature * newline * "end" * newline)
            @test occursin("ARC1_TEST_PROJECTION_COUNTER", injected)
            @test length(findall(signature, injected)) == 1
        end
        @test_throws ErrorException _arc1_inject_projection_counter("missing")
        @test_throws ErrorException _arc1_inject_projection_counter(signature * "\n" * signature)
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
            repeat_seed = UInt64(20261002)
            repeat_data = arc1_simulate_repeatability(repeat_seed, repeat_cell.N,
                Symbol(repeat_cell.signal))
            repeat_design = arc1_repeatability_design(Arc1ExecutorReferenceAPIEngine,
                repeat_data)
            repeat_context = HSquared._arc1_profile_context(repeat_design.y,
                repeat_design.X, repeat_design.Z,
                Arc1ExecutorReferenceAPIEngine.pedigree_inverse(repeat_design.pedigree))
            repeat_point = HSquared._arc1_profile_reml(repeat_context, 0.3, 0.2, 0.5)
            @test repeat_point.status == :ok
            v4_certificate = HSquared._arc1_profile_v4_tail_certificate(
                repeat_context.transformed_design, 100.0, -3.0;
                normalization_convention=:omit_2pi,
                design_data=repeat_context.profile_v4_design_data)
            @test v4_certificate.certified
            certificate_path = joinpath(output, "real-v4-tail-certificate.jls")
            open(certificate_path, "w") do io
                serialize(io, v4_certificate)
            end
            repeat_stdout, repeat_artifact = _arc1_run_fake_attempt(root, output, repeat_cell,
                repeat_seed, UInt64[]; v4_certificate_path=certificate_path)
            @test occursin("record_animal_ids", repeat_stdout)
            @test occursin("offspring-1-record-1", repeat_stdout) # record IDs remain unique
            @test occursin("\"record_animal_ids\":[\"offspring-1\",\"offspring-1\"", repeat_stdout)
            @test occursin("0.1,0.2", repeat_stdout) && occursin("0.4,0.6", repeat_stdout)
            @test occursin("\"point_fit_status\":\"ok\"", repeat_stdout)
            @test occursin("\"point_fit_not_optimal\":false", repeat_stdout)
            @test occursin("\"profile_method_version\":\"arc1_profile_v4\"", repeat_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v4\"", repeat_stdout)
            @test occursin("\"max_constrained_loglik\":-3.00001", repeat_stdout)
            @test occursin("target_diagnostics_identity", repeat_stdout)
            @test occursin("\"__arc1_rational__\"", repeat_stdout)
            @test occursin("\"__arc1_bigfloat__\"", repeat_stdout)
            @test isfile(repeat_artifact)
            projection_counter = joinpath(output, "profile-projection-calls.txt")
            inspected_profile = _arc1_inspect_fake_artifact(root, repeat_artifact;
                projection_counter)
            @test length(readlines(projection_counter)) == 1
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v4\"", inspected_profile)
            @test occursin("\"profile_method_version\":\"arc1_profile_v4\"", inspected_profile)
            @test occursin("\"loaded_engine_source_identity_matches\":true", inspected_profile)
            @test occursin("\"retained_result_identity_matches\":true", inspected_profile)
            @test occursin("\"receipt_summary_matches_retained_result\":true", inspected_profile)
            @test occursin("\"v3_evidence_records\":{", inspected_profile)
            @test !occursin("\"arc1_profile_v4_evaluations\":", inspected_profile)
            @test occursin("\"__arc1_rational__\"", inspected_profile)
            @test occursin("\"__arc1_bigfloat__\"", inspected_profile)
            @test occursin(arc1_json(v4_certificate.determinant), inspected_profile)
            @test occursin("\"target\":\"residual_variance\"", inspected_profile)
            @test occursin("\"v4_tail_certificate_validation_status\":\"validated\"",
                inspected_profile)
            for (label, replacement, expected_shape) in
                    (("missing-certificate-collection", nothing, "missing"),
                     ("malformed-certificate-collection", (; malformed=true), "malformed"))
                malformed_path = _arc1_replace_fake_certificate_collection(
                    root, repeat_artifact, label, replacement;
                    missing=expected_shape == "missing")
                malformed_inspection = _arc1_inspect_fake_artifact(root, malformed_path)
                @test occursin("\"v4_tail_certificates_shape\":\"$expected_shape\"",
                    malformed_inspection)
                @test occursin("\"v4_tail_certificate_validation_status\":\"invalid\"",
                    malformed_inspection)
                @test occursin("\"v4_tail_certificate_design_correspondence\":\"failed\"",
                    malformed_inspection)
                @test occursin("\"v4_tail_certificate_evidence_valid\":false",
                    malformed_inspection)
                @test occursin("\"v3_evidence_identity_matches\":false",
                    malformed_inspection)
            end
            @test occursin("\"v4_tail_certificate_design_correspondence\":\"matched\"",
                inspected_profile)
            @test occursin("\"v4_tail_certificate_evidence_valid\":true", inspected_profile)

            corrupted_certificates = (
                wrong_status=merge(v4_certificate, (; status=:bound_not_separating)),
                wrong_reason=merge(v4_certificate, (; reason=:unexpected)),
                uncertified=merge(v4_certificate, (; certified=false)),
                low_precision=merge(v4_certificate, (; precision=128)),
                wrong_rounding=merge(v4_certificate, (; rounding=:nearest)),
                nonrational_determinant=merge(v4_certificate, (; determinant=1.0)),
                nonpositive_determinant=merge(v4_certificate,
                    (; determinant=BigInt(0)//BigInt(1))),
                boolean_residual_df=merge(v4_certificate, (; residual_df=true)),
                nonpositive_residual_df=merge(v4_certificate, (; residual_df=0)),
                noninteger_residual_df=merge(v4_certificate, (; residual_df=1.5)),
                invalid_design_identity=merge(v4_certificate, (; design_identity="0")),
                wrong_convention=merge(v4_certificate, (; convention=:include_2pi)),
                modified_E=merge(v4_certificate, (; E=v4_certificate.E / 2)),
                nonpositive_E=merge(v4_certificate, (; E=0.0)),
                wrong_type_E=merge(v4_certificate, (; E=BigFloat(v4_certificate.E))),
                nan_E=merge(v4_certificate, (; E=NaN)),
                infinite_E=merge(v4_certificate, (; E=Inf)),
                nonfinite_upper_bound=merge(v4_certificate, (; upper_bound=BigFloat(Inf))),
                wrong_type_upper_bound=merge(v4_certificate, (; upper_bound=0.0)),
                nonfinite_threshold=merge(v4_certificate, (; threshold_lower=BigFloat(NaN))),
                wrong_type_threshold=merge(v4_certificate, (; threshold_lower=0.0)),
                infinite_threshold=merge(v4_certificate, (; threshold_lower=BigFloat(Inf))),
                modified_gap=merge(v4_certificate, (; gap_lower=
                    setprecision(BigFloat, 256) do
                        v4_certificate.gap_lower + BigFloat(1)
                    end)),
                gap_at_separation_threshold=merge(v4_certificate,
                    (; gap_lower=BigFloat(1e-8))),
                wrong_type_gap=merge(v4_certificate, (; gap_lower=0.0)),
                nan_gap=merge(v4_certificate, (; gap_lower=BigFloat(NaN))),
                zero_cutoff=merge(v4_certificate, (; cutoff=0.0)),
                wrong_type_cutoff=merge(v4_certificate, (; cutoff=BigFloat(3))),
                infinite_cutoff=merge(v4_certificate, (; cutoff=Inf)),
                wrong_separation_tolerance=merge(v4_certificate,
                    (; separation_tolerance=0.0)),
                wrong_type_separation_tolerance=merge(v4_certificate,
                    (; separation_tolerance=BigFloat(1e-8))),
                infinite_separation_tolerance=merge(v4_certificate,
                    (; separation_tolerance=Inf)),
                wrong_rounding_contract=merge(v4_certificate,
                    (; rounding_contract=merge(v4_certificate.rounding_contract,
                        (; threshold_subtraction=:up)))),
                wrong_boundary_contract=merge(v4_certificate,
                    (; boundary_rounding_contract=merge(
                        v4_certificate.boundary_rounding_contract,
                        (; exponential=:down)))),
                wrong_determinant_identity=merge(v4_certificate,
                    (; determinant_identity=:incorrect)),
                missing_E=Base.structdiff(v4_certificate, (; E=v4_certificate.E)),
                wrong_reference=merge(v4_certificate, (; point_loglik=
                    v4_certificate.point_loglik + 1.0)),
                combined_recomputation_mismatch=merge(v4_certificate,
                    (; E=v4_certificate.E * 2.0,
                       point_loglik=v4_certificate.point_loglik + 1.0)),
                nonfinite_point_loglik=merge(v4_certificate,
                    (; point_loglik=Inf)),
                nan_point_loglik=merge(v4_certificate, (; point_loglik=NaN)),
                wrong_type_point_loglik=merge(v4_certificate,
                    (; point_loglik=BigFloat(0))) )
            for (index, (label, bad_certificate)) in enumerate(pairs(corrupted_certificates))
                bad_certificate_path = _arc1_write_v4_certificate(
                    joinpath(output, "$(label)-v4-certificate.jls"), bad_certificate)
                _, bad_certificate_artifact = _arc1_run_fake_attempt(root, output,
                    repeat_cell, UInt64(20261020 + index), UInt64[];
                    v4_certificate_path=bad_certificate_path)
                bad_certificate_inspection = _arc1_inspect_fake_artifact(root,
                    bad_certificate_artifact)
                @test occursin("\"v4_tail_certificate_validation_status\":\"invalid\"",
                    bad_certificate_inspection)
                @test occursin("\"v4_tail_certificate_evidence_valid\":false",
                    bad_certificate_inspection)
                if label === :combined_recomputation_mismatch
                    @test occursin(
                        "\"v4_tail_certificate_design_correspondence\":\"matched\"",
                        bad_certificate_inspection)
                end
            end

            certificate_fields = (:status, :reason, :certified, :precision, :rounding,
                :determinant, :residual_df, :design_identity, :convention, :E,
                :upper_bound, :threshold_lower, :gap_lower, :point_loglik, :cutoff,
                :separation_tolerance, :rounding_contract,
                :boundary_rounding_contract, :determinant_identity)
            for (index, field) in enumerate(certificate_fields)
                field === :E && continue # Already covered by missing_E above.
                omitted_field = NamedTuple{(field,)}((getproperty(v4_certificate, field),))
                incomplete_certificate = Base.structdiff(v4_certificate, omitted_field)
                incomplete_path = _arc1_write_v4_certificate(
                    joinpath(output, "missing-$(field)-v4-certificate.jls"),
                    incomplete_certificate)
                _, incomplete_artifact = _arc1_run_fake_attempt(root, output,
                    repeat_cell, UInt64(20261100 + index), UInt64[];
                    v4_certificate_path=incomplete_path)
                incomplete_inspection = _arc1_inspect_fake_artifact(root,
                    incomplete_artifact)
                @test occursin("\"v4_tail_certificate_validation_status\":\"invalid\"",
                    incomplete_inspection)
                @test occursin("\"v4_tail_certificate_evidence_valid\":false",
                    incomplete_inspection)
            end

            unavailable_completed = _arc1_inspect_fake_artifact(root, repeat_artifact;
                context_unavailable=true)
            @test occursin("\"v4_tail_certificate_validation_status\":\"invalid\"",
                unavailable_completed)
            @test occursin("\"v4_tail_certificate_design_correspondence\":\"failed\"",
                unavailable_completed)
            @test occursin("\"v4_tail_certificate_evidence_valid\":false",
                unavailable_completed)

            structurally_incomplete_interrupted = (
                missing_point_loglik=Base.structdiff(v4_certificate,
                    (; point_loglik=v4_certificate.point_loglik)),
                missing_cutoff=Base.structdiff(v4_certificate,
                    (; cutoff=v4_certificate.cutoff)),
                missing_upper_bound=Base.structdiff(v4_certificate,
                    (; upper_bound=v4_certificate.upper_bound)),
                missing_threshold=Base.structdiff(v4_certificate,
                    (; threshold_lower=v4_certificate.threshold_lower)),
                missing_contract=Base.structdiff(v4_certificate,
                    (; rounding_contract=v4_certificate.rounding_contract)))
            for (index, (label, incomplete_certificate)) in
                    enumerate(pairs(structurally_incomplete_interrupted))
                incomplete_path = _arc1_write_v4_certificate(
                    joinpath(output, "$(label)-interrupted-certificate.jls"),
                    incomplete_certificate)
                _, incomplete_artifact = _arc1_run_fake_attempt(root, output,
                    repeat_cell, UInt64(20261030 + index), UInt64[];
                    interrupt_profile=true, v4_certificate_path=incomplete_path)
                @test isfile(incomplete_artifact)
                incomplete_inspection = _arc1_inspect_fake_artifact(root,
                    incomplete_artifact)
                @test occursin("\"v4_tail_certificate_validation_status\":\"invalid\"",
                    incomplete_inspection)
                @test occursin("\"v4_tail_certificate_evidence_valid\":false",
                    incomplete_inspection)
            end

            interrupted_with_design = _arc1_relabel_fake_artifact(root,
                repeat_artifact, "interrupted")
            interrupted_reconstruction_failure = _arc1_inspect_fake_artifact(root,
                interrupted_with_design; context_unavailable=true)
            @test occursin("\"v4_tail_certificate_validation_status\":\"invalid\"",
                interrupted_reconstruction_failure)
            @test occursin("\"v4_tail_certificate_design_correspondence\":\"failed\"",
                interrupted_reconstruction_failure)

            bad_profile_cell = (; programme="repeatability", phase="engineering_probe", N=16,
                                signal="invalid")
            failed_profile_stdout, failed_profile_artifact = _arc1_run_fake_attempt(
                root, output, bad_profile_cell, UInt64(20261003), UInt64[])
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v4\"",
                           failed_profile_stdout)
            @test occursin("\"profile_method_version\":null", failed_profile_stdout)
            @test occursin("\"profile_method_version_mismatch\":false", failed_profile_stdout)
            @test !occursin("\"profile_method_version\":\"arc1_profile_v1\"", failed_profile_stdout)
            failed_projection_counter = joinpath(output, "failed-projection-calls.txt")
            inspected_failure = _arc1_inspect_fake_artifact(root, failed_profile_artifact;
                projection_counter=failed_projection_counter)
            @test !isfile(failed_projection_counter)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v4\"", inspected_failure)
            @test occursin("\"v3_evidence_identity_matches\":true", inspected_failure)
            @test occursin("\"loaded_engine_source_identity_matches\":true", inspected_failure)

            mismatch_stdout, mismatch_artifact = _arc1_run_fake_attempt(root, output,
                repeat_cell, UInt64(20261004), UInt64[]; wrong_profile_version=true)
            @test occursin("\"profile_method_version_mismatch\":true", mismatch_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v4\"", mismatch_stdout)
            @test occursin("\"profile_method_version\":\"arc1_profile_v2\"", mismatch_stdout)
            @test isfile(mismatch_artifact)

            missing_stdout, missing_artifact = _arc1_run_fake_attempt(root, output,
                repeat_cell, UInt64(20261005), UInt64[]; missing_profile_version=true)
            @test occursin("\"profile_method_version_mismatch\":true", missing_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v4\"", missing_stdout)
            @test occursin("\"profile_method_version\":null", missing_stdout)
            @test isfile(missing_artifact)

            interrupted_stdout, interrupted_artifact = _arc1_run_fake_attempt(root, output,
                repeat_cell, UInt64(20261006), UInt64[]; interrupt_profile=true,
                v4_certificate_path=certificate_path)
            @test occursin("\"status\":\"interrupted\"", interrupted_stdout)
            @test occursin("\"requested_profile_method_version\":\"arc1_profile_v4\"",
                           interrupted_stdout)
            @test occursin("\"profile_method_version\":\"arc1_profile_v4\"", interrupted_stdout)
            @test occursin("\"actual_method_version\":\"arc1_profile_v4\"", interrupted_stdout)
            @test occursin("\"v3_profile_evidence_summary\":{", interrupted_stdout)
            @test occursin("\"history_event_count\":1", interrupted_stdout)
            @test !occursin("\"event\":\"interrupted\"", interrupted_stdout)
            @test !occursin("\"termination_code\":\"FakeNoObjectiveChange\"", interrupted_stdout)
            @test !occursin("\"profile_intervals\":", interrupted_stdout)
            @test isfile(interrupted_artifact)
            inspected_interruption = _arc1_inspect_fake_artifact(root, interrupted_artifact;
                include_full_v3_evidence=true)
            @test occursin("\"retained_v3_evidence_present\":true", inspected_interruption)
            @test occursin("\"v3_evidence_identity_matches\":false", inspected_interruption)
            @test occursin("\"v3_evidence_partial_present\":true", inspected_interruption)
            @test occursin("\"loaded_engine_source_identity_matches\":true", inspected_interruption)
            @test occursin("\"actual_method_version\":\"arc1_profile_v4\"", inspected_interruption)
            @test occursin("\"max_valid_centered_loglik\":-3.0", inspected_interruption)
            @test occursin("\"termination_code\":\"FakeNoObjectiveChange\"", inspected_interruption)
            @test occursin("\"native_dict\":{\"reason\":\"line_search_stopped\"}", inspected_interruption)
            @test occursin("\"native_tuple\":[{\"__arc1_type__\":\"missing\"},{\"__arc1_float__\":\"Inf\"},{\"__arc1_float__\":\"NaN\"}]", inspected_interruption)
            @test occursin("\"v4_tail_certificates\":[{\"certificate\":", inspected_interruption)
            @test occursin("\"v4_tail_certificate_validation_status\":\"design_correspondence_unavailable_interrupted\"",
                inspected_interruption)
            @test occursin("\"v4_tail_certificate_design_correspondence\":\"unavailable_interrupted\"",
                inspected_interruption)
            @test occursin("\"v4_tail_certificate_evidence_valid\":false",
                inspected_interruption)

            failed_sink_stdout, failed_sink_artifact = _arc1_run_fake_attempt(root, output,
                repeat_cell, UInt64(20261010), UInt64[]; fail_profile=true,
                v4_certificate_path=certificate_path)
            @test occursin("\"status\":\"error\"", failed_sink_stdout)
            @test occursin("synthetic profile failure after v4 evidence retention",
                failed_sink_stdout)
            inspected_failed_sink = _arc1_inspect_fake_artifact(root, failed_sink_artifact)
            @test occursin("\"__arc1_rational__\"", inspected_failed_sink)
            @test occursin("\"__arc1_bigfloat__\"", inspected_failed_sink)
            @test occursin("\"v4_tail_certificates\":[{\"certificate\":", inspected_failed_sink)

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

            _, split_alias_path = _arc1_run_fake_attempt(root, output, wrong_source_cell,
                UInt64(20261009), UInt64[]; interrupt_profile=true, split_v4_alias=true)
            split_alias_output = _arc1_inspect_fake_artifact(root, split_alias_path)
            @test occursin("\"v4_evidence_aliases_match\":false", split_alias_output)
            @test occursin("\"v3_evidence_identity_matches\":false", split_alias_output)
            raw_sink_check = split_alias_path * ".raw-sink-check.jl"
            write(raw_sink_check, """
            using HSquared
            include($(repr(joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", "engine_io.jl"))))
            include($(repr(joinpath(ARC1_EXECUTOR_REPO, "sim", "arc1", "artifact_container.jl"))))
            artifact = arc1_read_artifact_container($(repr(split_alias_path)))
            @assert hasproperty(artifact, :v3_profile_evidence_raw)
            raw = artifact.v3_profile_evidence_raw
            @assert raw[:arc1_profile_v3_evaluations] !== raw[:arc1_profile_v4_evaluations]
            """)
            raw_sink_depot = joinpath(output, "depot")
            raw_sink_command = `$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$root $raw_sink_check`
            run(addenv(raw_sink_command,
                "JULIA_DEPOT_PATH" => string(raw_sink_depot, Sys.iswindows() ? ';' : ':', first(DEPOT_PATH)),
                "OPENBLAS_NUM_THREADS" => "1", "JULIA_NUM_THREADS" => "1"))

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
            retained = arc1_read_artifact_container(error_artifact)
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

    @testset "raw repeatability projection retains v3 evidence sink" begin
        targets = Dict{Symbol,Any}(name =>
            (; confidence_set=nothing, status=:unbracketed, formed=false)
            for name in (:additive_variance, :permanent_environment_variance,
                         :residual_variance, :heritability, :repeatability))
        evidence = Dict{Symbol,Any}(:requested_method_version => "arc1_profile_v4",
            :actual_method_version => "arc1_profile_v4",
            :source_identity => repeat("a", 64),
            :arc1_profile_v3_evaluations => Any[],
            :arc1_profile_v4_evaluations => Any[])
        profile = (; targets, cutoff=3.841458820694124, point_estimates=nothing,
            method_version=:arc1_profile_v4, point_fit_status=:failed,
            point_fit_not_optimal=false, point_fit=nothing,
            max_constrained_loglik=-Inf, point_identity=nothing,
            reference_point_identity=nothing, source_identity=repeat("a", 64),
            reference_source_identity=repeat("a", 64),
            point_fit_candidate=nothing)
        result = merge(arc1_repeatability_result(profile),
            (; v3_profile_evidence=evidence))
        payload = (; profile, v3_profile_evidence=evidence)
        @test arc1_raw_result_projection_difference(payload, result, (;)) === nothing
        missing_evidence = arc1_raw_result_projection_difference((; profile), result, (;))
        @test missing_evidence == "repeatability receipt differs from raw profile"
        altered_profile = merge(profile, (; source_identity=repeat("b", 64)))
        profile_difference = arc1_raw_result_projection_difference(
            (; profile=altered_profile, v3_profile_evidence=evidence), result, (;))
        @test profile_difference == "repeatability receipt differs from raw profile"
        altered_evidence = merge(evidence, Dict(:source_identity => repeat("b", 64)))
        evidence_difference = arc1_raw_result_projection_difference(
            (; profile, v3_profile_evidence=altered_evidence), result, (;))
        @test evidence_difference == "repeatability receipt differs from raw profile"
    end
end

@testset "Arc1 reference-admission flags and rank comparison receipts" begin
    missing_rank_selector_result = (; rank_candidates=Any[],
        reference_audit=(; status="not_required"))
    @test arc1_raw_result_projection_difference((;), missing_rank_selector_result, (;)) ==
        "retained FA rank result lacks raw selector"
    missing_interval_selector_result = (; bootstrap=(;))
    @test arc1_raw_result_projection_difference((;), missing_interval_selector_result, (;)) ==
        "FA interval result lacks raw outer selector"

    selected = (; selection_status=:selected, selected_fit=(;), selected_rank=0,
        reason=nothing, source_identity=repeat("c", 64), starts_planned=1,
        starts_attempted=1, attempts=Any[], guard_results=nothing,
        near_tie=false, candidate_summary=[(; rank=0, eligible=true, loglik=-10.0,
            near_floor=false, q=0, penalty=0.0, criterion=-10.0, status=:ok,
            reason=nothing), (; rank=1, eligible=true, loglik=-7.0, near_floor=false,
            q=1, penalty=2.0, criterion=-9.0, status=:ok, reason=nothing)])
    rank_result = arc1_fa_rank_result(selected,
        (; status="not_required", reason="expanded reference is not required for this attempt"))
    altered_rank_result = merge(rank_result, (; selected_rank="K1"))
    @test arc1_raw_result_projection_difference((; raw_selection=selected),
        altered_rank_result, (;)) == "FA rank receipt differs from raw selector/reference"

    interval_metadata = (; data_identity_sha256=repeat("d", 64))
    altered_interval_result = (; bootstrap=(;), outer_selection=(;))
    @test arc1_raw_result_projection_difference((; raw_selection=selected),
        altered_interval_result, interval_metadata) ==
        "FA interval outer-selection receipt differs from raw selector"

    @test !arc1_reference_required(selected,
        Dict("programme" => "fa_rank", "phase" => "engineering_probe"), 1)
    @test arc1_reference_required(selected,
        Dict("programme" => "fa_rank", "phase" => "pilot"), 20)
    @test !arc1_reference_required(selected,
        Dict("programme" => "fa_rank", "phase" => "development"), 30)
    @test arc1_reference_required(selected,
        Dict("programme" => "fa_rank", "phase" => "development"), 31)
    @test arc1_reference_required(selected,
        Dict("programme" => "fa_rank", "phase" => "development"), 50)
    @test !arc1_reference_required(selected,
        Dict("programme" => "fa_rank", "phase" => "development"), 51)
    @test !arc1_reference_required(selected,
        Dict("programme" => "repeatability", "phase" => "development"), 31)
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

@testset "Arc1 receipt diagnostic identities are stable after deserialization" begin
    values = Any[
        Dict("target" => (status=:formed, segment=[0.0, 1.0])),
        Dict("label" => "receipt-β-λ", "boundary" => repeat("x", 65)),
        Dict("target" => (diagnostics=fill(UInt32(42), 100_000),)),
    ]
    for value in values
        expected = bytes2hex(SHA.sha256(Vector{UInt8}(codeunits(arc1_json(value)))))
        @test _arc1_sha256_repr(value) == expected
    end
    for value in (repeat("a", 63), repeat("b", 64), repeat("c", 65), "β")
        expected = bytes2hex(SHA.sha256(Vector{UInt8}(codeunits(arc1_json(value)))))
        @test _arc1_sha256_repr(value) == expected
    end
    for text in (repeat("a", 63), repeat("b", 64), repeat("c", 65), "β")
        @test bytes2hex(SHA.sha256(text)) ==
              bytes2hex(SHA.sha256(Vector{UInt8}(codeunits(text))))
    end

    target_names = (:additive_variance, :permanent_environment_variance,
                    :residual_variance, :heritability, :repeatability)
    targets = Dict(name => (; formed=true, status=:ok,
        confidence_set=[(0.1, 0.2)]) for name in target_names)
    reverse_targets = Dict{Symbol,Any}()
    for name in reverse(target_names)
        reverse_targets[name] = targets[name]
    end
    @test _arc1_sha256_repr(targets) == _arc1_sha256_repr(reverse_targets)
    point_candidate = (; diagnostics=fill(UInt32(42), 100_000))
    profile = (; targets, point_fit_candidate=point_candidate,
        point_fit=(; loglik=-1.0), point_fit_status=:ok,
        point_estimates=Dict(name => 0.1 for name in target_names),
        cutoff=3.841458820694124, method_version="arc1_profile_v4",
        point_fit_not_optimal=false, max_constrained_loglik=Dict(),
        point_identity="point", reference_point_identity="reference",
        source_identity="source", reference_source_identity="reference-source")
    receipt = arc1_repeatability_receipt(profile)
    @test receipt.point_fit_diagnostic_identity ==
          bytes2hex(SHA.sha256(Vector{UInt8}(codeunits(arc1_json(point_candidate)))))
    @test receipt.target_diagnostics_identity ==
          bytes2hex(SHA.sha256(Vector{UInt8}(codeunits(arc1_json(targets)))))

    history = Any[(; events=Any[(; event_index=1), (; event_index=2)])]
    evidence = Dict{Symbol,Any}(:requested_method_version => "arc1_profile_v4",
        :actual_method_version => "arc1_profile_v4", :source_identity => repeat("a", 64),
        :returned_method_version => "arc1_profile_v4",
        :arc1_profile_v3_evaluations => history,
        :arc1_profile_v4_evaluations => history, :v4_tail_certificates => Any[])
    compact = arc1_profile_evidence_summary(evidence)
    @test compact.history_aliases_match
    @test compact.history_row_count == 1
    @test compact.history_event_count == 2
    @test compact.v4_tail_certificates_shape == "vector"
    compact_receipt = arc1_json_receipt(merge(arc1_repeatability_result(profile),
        (; v3_profile_evidence=evidence)))
    @test !hasproperty(compact_receipt, :v3_profile_evidence)
    @test compact_receipt.v3_profile_evidence_summary == compact
    evidence[:arc1_profile_v4_evaluations] = deepcopy(history)
    @test !arc1_profile_evidence_summary(evidence).history_aliases_match
    evidence[:arc1_profile_v4_evaluations] = history
    delete!(evidence, :v4_tail_certificates)
    missing_certificates = arc1_profile_evidence_summary(evidence)
    @test missing_certificates.v4_tail_certificates_shape == "missing"
    @test missing_certificates.v4_tail_certificates === nothing
    evidence[:v4_tail_certificates] = (; malformed=true)
    malformed_certificates = arc1_profile_evidence_summary(evidence)
    @test malformed_certificates.v4_tail_certificates_shape == "malformed"
    @test malformed_certificates.v4_tail_certificates === nothing
end


include("arc1_container_framing.jl")

@testset "Arc1 interval receipt matches bootstrap trait labels" begin
    for label_type in (String, Symbol)
        intervals = [
            (; trait=label_type("trait$i"), estimate=0.5, lower=0.2, upper=0.8,
               formed=true, status=:formed)
            for i in 1:4
        ]
        projected = arc1_interval_rows((; intervals))
        @test length(projected) == 4
        for i in 1:4
            row = projected["h2_$i"]
            @test row.formed
            @test row.estimate == 0.5
            @test row.segments == [[0.2, 0.8]]
        end
    end

    valid_intervals = [
        (; trait="trait$i", estimate=0.5, lower=0.2, upper=0.8,
           formed=true, status=:formed)
        for i in 1:4
    ]
    @test_throws ArgumentError arc1_interval_rows((; intervals=valid_intervals[1:3]))
    duplicated = [valid_intervals[1], valid_intervals[1], valid_intervals[3], valid_intervals[4]]
    @test_throws ArgumentError arc1_interval_rows((; intervals=duplicated))
    extra = [valid_intervals; (; trait="trait5", estimate=0.5, lower=0.2,
        upper=0.8, formed=true, status=:formed)]
    @test_throws ArgumentError arc1_interval_rows((; intervals=extra))
end

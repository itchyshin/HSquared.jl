using Test
using SHA
using Serialization
using Optim

const ARC1_TRANSPORT_ROOT = normpath(joinpath(@__DIR__, ".."))
include(joinpath(ARC1_TRANSPORT_ROOT, "sim", "arc1", "engine_io.jl"))

@testset "Arc1 native JSON/JLS interruption transport leaves" begin
    code = Optim.TerminationCode.NoObjectiveChange
    @test code isa Enum
    evidence = Dict{Symbol,Any}(
        :requested_method_version => "arc1_profile_v3",
        :actual_method_version => "arc1_profile_v3",
        :source_identity => repeat("a", 64),
        :arc1_profile_v3_evaluations => Any[Dict{Symbol,Any}(
            :status => :interrupted,
            :termination_code => code,
            :producer_history => Any[(; stage=:bfgs, reason=code,
                nested=Dict(:missing_value => missing, :tuple => (Inf, NaN)))],
            :max_valid_loglik => -3.0,
            :candidate_matrix => [1 2; 3 4]
        )]
    )
    encoded = arc1_json((; seed=typemax(UInt64), evidence))
    @test occursin(string(typemax(UInt64)), encoded)
    @test occursin("\"__arc1_enum__\"", encoded)
    @test occursin("\"type\":\"Optim.TerminationCode.T\"", encoded)
    @test occursin("\"name\":\"NoObjectiveChange\"", encoded)
    @test occursin("\"__arc1_type__\":\"missing\"", encoded)
    @test occursin("\"__arc1_float__\":\"Inf\"", encoded)
    @test occursin("\"__arc1_float__\":\"NaN\"", encoded)
    @test occursin("\"dims\":[2,2]", encoded)
    @test occursin("\"data\":[1,3,2,4]", encoded)

    mktempdir(prefix="arc1-t1-jls-") do directory
        path = joinpath(directory, "interrupted.full.jls")
        hash = arc1_serialize_new(path, evidence)
        restored = open(deserialize, path)
        @test hash == bytes2hex(sha256(read(path)))
        @test restored[:actual_method_version] == "arc1_profile_v3"
        @test restored[:arc1_profile_v3_evaluations][1][:termination_code] === code
        @test restored[:arc1_profile_v3_evaluations][1][:producer_history][1].reason === code
        @test restored[:arc1_profile_v3_evaluations][1][:producer_history][1].nested[:missing_value] === missing
        @test_throws ArgumentError arc1_serialize_new(path, evidence)
    end

    unsafe = merge(evidence, Dict{Symbol,Any}(:unsupported => Ref(17)))
    @test_throws ArgumentError arc1_json(unsafe)
    fallback, projection_error = arc1_receipt_json(
        (; schema="arc1-attempt-result-v1", status="interrupted", success=false,
           v3_profile_evidence=unsafe);
        fallback_fields=(; preserve_original_error=true, mode="engineering_probe",
            outer=2, seed_string="9223372036854775809", status="interrupted",
            failure_reason="InterruptException", error_type="InterruptException",
            requested_profile_method_version="arc1_profile_v3",
            profile_method_version="arc1_profile_v3",
            profile_method_version_mismatch=false,
            profile_source_identity=repeat("a", 64),
            loaded_arc1_source_identity=repeat("b", 64),
            artifact_path="retained.full.jls", artifact_sha256=repeat("c", 64),
            retention_error="JLS retention remained available"))
    @test projection_error isa ArgumentError
    @test occursin("\"status\":\"interrupted\"", fallback)
    @test occursin("\"error_type\":\"InterruptException\"", fallback)
    @test occursin("\"profile_method_version\":\"arc1_profile_v3\"", fallback)
    @test occursin("\"artifact_path\":\"retained.full.jls\"", fallback)
    @test occursin("\"artifact_sha256\":\"$(repeat("c", 64))\"", fallback)
    @test occursin("JSON receipt projection failed", fallback)
    @test !occursin("\"unsupported\":", fallback)
end

using Test
include(joinpath(@__DIR__, "..", "tools", "validate_hsq09_h3_replacement_s11_manifest.jl"))
@testset "H3 S11 manifest" begin
    manifest = TOML.parsefile(H3_S11_MANIFEST)
    @test manifest["governed_inputs"]["reconciler_sha256"] == bytes2hex(sha256(read(joinpath(@__DIR__, "..", "tools", "reconcile_hsq09_h3_replacement_s11.jl"))))
    @test haskey(manifest["governed_inputs"], "external_failure_materializer_sha256")
    haskey(manifest["governed_inputs"], "external_failure_materializer_sha256") && @test manifest["governed_inputs"]["external_failure_materializer_sha256"] == bytes2hex(sha256(read(joinpath(@__DIR__, "..", "tools", "materialize_hsq09_h3_replacement_s11_failure.jl"))))
    @test haskey(manifest, "recovery")
    haskey(manifest, "recovery") && @test manifest["recovery"] == Dict(
        "cell" => "ram", "task_start" => 490, "task_stop" => 494,
        "failure_reason" => "scheduler_sigbus_nc10901", "excluded_node" => "nc10901",
        "resume_task_start" => 495, "resume_task_stop" => 2000,
        "rerun_failed_seeds" => false, "scientific_fixture_change" => false,
    )
    @test h3_replacement_s11_manifest_validate() === nothing
    @test h3_replacement_s11_manifest_mutation_controls() === nothing
end
println("H3_REPLACEMENT_S11_MANIFEST_TESTS_OK")

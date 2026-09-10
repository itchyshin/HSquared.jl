using Test
include(joinpath(@__DIR__, "..", "tools", "validate_hsq09_h3_replacement_s11_manifest.jl"))
@testset "H3 S11 manifest" begin
    manifest = TOML.parsefile(H3_S11_MANIFEST)
    @test manifest["governed_inputs"]["reconciler_sha256"] == bytes2hex(sha256(read(joinpath(@__DIR__, "..", "tools", "reconcile_hsq09_h3_replacement_s11.jl"))))
    @test h3_replacement_s11_manifest_validate() === nothing
    @test h3_replacement_s11_manifest_mutation_controls() === nothing
end
println("H3_REPLACEMENT_S11_MANIFEST_TESTS_OK")

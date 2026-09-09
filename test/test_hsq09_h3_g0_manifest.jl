using Test

include(joinpath(@__DIR__, "..", "tools", "validate_hsq09_h3_g0_manifest.jl"))

@testset "HSQ09 H3 G0 manifest" begin
    manifest = hsq09_h3_g0_manifest()
    @test manifest["manifest"]["id"] == "HSQ09-H3-G0-PRERUN-01"
    @test hsq09_h3_g0_manifest_self_test()
end

println("HSQ09_H3_G0_MANIFEST_TESTS_OK")

using Test

include(joinpath(@__DIR__, "..", "tools", "validate_hsq09_s9_a4_manifest.jl"))

const S9_A4_MANIFEST = joinpath(@__DIR__, "..", "docs", "dev-log", "evidence", "2026-09-09-hsq09-s9-a4-evidence-manifest.toml")

@testset "HSQ09 S9-A4 source-inert evidence manifest" begin
    r_root = get(ENV, "HSQ09_S9_A4_R_ROOT", nothing)
    @test r_root !== nothing
    @test s9_a4_validate(S9_A4_MANIFEST; r_root = r_root, assert_inert = true) === nothing
    @test s9_a4_mutation_controls(S9_A4_MANIFEST; r_root = r_root) === nothing
end

println("HSQ09_S9_A4_TESTS_OK")

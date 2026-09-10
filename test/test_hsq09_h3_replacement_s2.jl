using Test

const H3_REPLACEMENT_S2_VALIDATOR = joinpath(@__DIR__, "..", "tools",
    "validate_hsq09_h3_replacement_s2.jl")

@testset "H3 replacement S2 materialization" begin
    @test isfile(H3_REPLACEMENT_S2_VALIDATOR)
    if isfile(H3_REPLACEMENT_S2_VALIDATOR)
        include(H3_REPLACEMENT_S2_VALIDATOR)
        material = h3_replacement_s2_manifest()

        @test material["manifest"]["id"] == "HSQ09-H3-REPLACEMENT-S2-01"
        @test material["manifest"]["source_inert"] === true
        @test material["rg"]["estimand"] == "r_g"
        @test material["rg"]["animals"] == 80
        @test material["rg"]["records"] == 240
        @test material["rg"]["initializer"] == "phenotypic_scale_default; initial=nothing"
        @test material["ram"]["estimand"] == "r_am"
        @test material["ram"]["animals"] == 996
        @test material["ram"]["records"] == 960
        @test material["ram"]["initializer"] == "G_dm=I2; sigma_e2=1.0; initial is not truth"
        @test material["negative_controls"]["rg"] == "G12=0.9; non_interpretable; excluded"
        @test material["negative_controls"]["ram"] == "dam_own_records=false; retained separately; excluded"
        @test all(value === false for value in values(material["authorizations"]))
        @test h3_replacement_s2_fixture_mutation_test()
        @test h3_replacement_s2_self_test()
    end
end

println("H3_REPLACEMENT_S2_TESTS_OK")

using Test
using TOML

const H3_S11_TEMPLATE = joinpath(
    @__DIR__, "..", "docs", "dev-log", "evidence",
    "2026-09-09-h3-replacement-s11-template.toml",
)
const H3_S11_VALIDATOR = joinpath(
    @__DIR__, "..", "tools", "validate_hsq09_h3_replacement_s11_template.jl",
)

@testset "H3 replacement S11 decision template" begin
    @test isfile(H3_S11_TEMPLATE)
    @test isfile(H3_S11_VALIDATOR)
    template_data = TOML.parsefile(H3_S11_TEMPLATE)
    @test template_data["template"]["engine_capability_inert"] === true
    @test !haskey(template_data["template"], "source_inert")
    if isfile(H3_S11_VALIDATOR)
        include(H3_S11_VALIDATOR)
        @test h3_replacement_s11_template_validate(H3_S11_TEMPLATE) === nothing
        @test h3_replacement_s11_template_mutation_controls(H3_S11_TEMPLATE) === nothing
    end
end

println("H3_REPLACEMENT_S11_TEMPLATE_TESTS_OK")

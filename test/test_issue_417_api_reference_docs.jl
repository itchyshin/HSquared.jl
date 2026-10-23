using HSquared
using Test

@testset "issue 417 API reference coverage" begin
    root = normpath(joinpath(@__DIR__, ".."))
    api = read(joinpath(root, "docs", "src", "api.md"), String)
    boundary = read(joinpath(root, "docs", "src", "twin-boundary.md"), String)
    changelog = read(joinpath(root, "docs", "src", "changelog.md"), String)
    missing_before = [
        :FA_UNIQUENESS_FLOOR,
        :bootstrap_variance_component_interval,
        :fa_covered_flip_cell,
        :fit_matrix_free_reml,
        :fit_multivariate_repeatability_reml,
        :fit_payload_v2,
        :genetic_correlation_interval,
        :ledermann_slack,
        :multivariate_repeatability_result_payload,
        :nested_lrt,
        :nongaussian_heritability,
        :parse_payload_v2,
        :require_fa_covered_flip_cell,
        :result_payload_v2,
        :structured_genetic_payload,
        :variance_component_interval,
        :gpu_fit_gblup,
    ]

    exported = Set(names(HSquared))
    @test all(name -> name in exported, missing_before)
    @test all(
        name -> occursin("HSquared.$name", api),
        missing_before,
    )
    @test occursin("/HSquared.jl/dev/api.html", boundary)
    @test occursin("stable reference is the API snapshot", boundary)
    @test occursin("## 0.9.0 (experimental)", changelog)
    @test !occursin("not reconciled with this file", changelog)
end

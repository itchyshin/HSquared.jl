using Test

@testset "issue 418 changelog claims" begin
    root = normpath(joinpath(@__DIR__, ".."))
    changelog = read(joinpath(root, "docs", "src", "changelog.md"), String)

    @test occursin("including the current R\n  formula bridge", changelog)
    @test occursin("still obtain it through the selected inverse", changelog)
    @test occursin("Fixed #370/#371", changelog)
    @test occursin("multi-effect K-effect route", changelog)
    @test occursin("univariate animal-model route is unchanged", changelog)
    @test occursin("not a reproducible package benchmark", changelog)
    @test !occursin("5.9 s / 832 MB", changelog)
    @test !occursin("attached by the payload-v2 bridge", changelog)
end

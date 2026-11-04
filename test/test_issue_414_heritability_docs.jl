using Test

@testset "issue 414 heritability denominators" begin
    root = normpath(joinpath(@__DIR__, ".."))
    source = read(joinpath(root, "src", "likelihood.jl"), String)
    qg_docs = read(joinpath(root, "docs", "src", "standard-qg-models.md"), String)

    @test occursin("Fixed-effect variance is not included in", source)
    @test occursin("permanent-environment", source)
    @test occursin("common-environment", source)
    @test occursin("maternal variance", source)
    @test occursin("σ²a + σ²pe + σ²e", qg_docs)
    @test occursin("Fixed-effect variance is outside both", qg_docs)
    @test !occursin("h² = σ²a/total", qg_docs)
end

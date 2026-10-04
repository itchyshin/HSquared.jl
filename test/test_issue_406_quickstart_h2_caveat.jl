using Test

@testset "issue 406 toy heritability caveat" begin
    root = normpath(joinpath(@__DIR__, ".."))
    quickstart = read(joinpath(root, "docs", "src", "quickstart.md"), String)

    @test occursin("Syntax demonstration, not a heritability estimate", quickstart)
    @test occursin("Both fitted variance components are therefore near zero", quickstart)
    @test occursin("unstable ratio of two near-zero numbers", quickstart)
    @test occursin(r"must not be\r?\n    interpreted or reported", quickstart)
end

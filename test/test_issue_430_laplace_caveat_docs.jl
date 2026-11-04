using Test

@testset "issue 430 Laplace bias caveat" begin
    root = normpath(joinpath(@__DIR__, ".."))
    quickstart = read(joinpath(root, "docs", "src", "quickstart.md"), String)

    @test occursin("Non-Gaussian marginal caveat", quickstart)
    @test occursin("874-record *Plodia* pupation", quickstart)
    @test occursin("42% below an", quickstart)
    @test occursin("exact-likelihood reference", quickstart)
    @test occursin("marginal = :variational", quickstart)
    @test occursin("not a universal correction factor", quickstart)
    @test occursin("not directly comparable", quickstart)
end

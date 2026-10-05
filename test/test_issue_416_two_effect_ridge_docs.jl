# HSquared.jl #416 — document the animal + dam REML ridge.
# Standalone:
# julia --project=. -e 'include("test/test_issue_416_two_effect_ridge_docs.jl")'

using Test

@testset "issue 416 two-effect ridge is documented" begin
    root = normpath(joinpath(@__DIR__, ".."))
    help = read(joinpath(root, "src", "likelihood.jl"), String)
    page = read(joinpath(root, "docs", "src", "standard-qg-models.md"), String)

    @test occursin("NelderMead", help)
    @test occursin("A = 0.5 I + 0.5 D", help)
    @test occursin("one point on that ridge", help)

    @test occursin("Nelder-Mead simplex contracted", page)
    @test occursin("A = 0.5 I + 0.5 D", page)
    @test occursin("0.5 Va + Ve", page)
    @test occursin("Nothing in the returned `converged` flag names that ridge", page)
end

# HSquared.jl #340 — document that fit_multivariate_reml still optimizes
# the unreduced loading vector. Standalone:
# julia --project=. -e 'include("test/test_issue_340_fa_ngen_docs.jl")'

using Test

@testset "issue 340 FA optimizer parameter count is documented" begin
    root = normpath(joinpath(@__DIR__, ".."))
    help = read(joinpath(root, "src", "multivariate.jl"), String)
    page = read(joinpath(root, "docs", "src", "multivariate-models.md"), String)

    @test occursin("full raw loading vector", help)
    @test occursin("K(K-1)/2", help)
    @test occursin("_mv_nparams", help)
    @test occursin("LRT reporting only", help)
    @test occursin("unreduced parameter count", help)

    @test occursin("full raw loading vector", page)
    @test occursin("K(K-1)/2", page)
    @test occursin("_mv_nparams", page)
    @test occursin("unreduced", page)
end

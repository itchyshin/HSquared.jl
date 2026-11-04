# HSquared.jl #352 — document the existing 1 / 2 / 3-or-more PE dispatch.
# Standalone:
# julia --project=. -e 'include("test/test_issue_352_pe_dispatch_docs.jl")'

using Test

@testset "issue 352 PE dispatch rule is documented" begin
    root = normpath(joinpath(@__DIR__, ".."))
    help = read(joinpath(root, "src", "bridge_payload_v2.jl"), String)
    page = read(joinpath(root, "docs", "src", "standard-qg-models.md"), String)

    @test occursin("1 pedigree block → `:animal`", help)
    @test occursin("2 independent blocks → `:two_effect`", help)
    @test occursin("3 or more independent blocks → `:multi_effect`", help)
    @test occursin("Two effects are not rejected", help)
    @test occursin("animal + permanent environment", help)

    @test occursin("One pedigree block goes to `:animal`", page)
    @test occursin("Two independent blocks go to `:two_effect`", page)
    @test occursin("Three or more independent blocks go to `:multi_effect`", page)
    @test occursin("Two effects are not rejected", page)
    @test occursin("animal + permanent environment", page)
end

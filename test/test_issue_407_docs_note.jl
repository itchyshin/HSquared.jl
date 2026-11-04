# HSquared.jl #407 — docs/src/fitting-at-scale.md must name the AI-REML q > 512 limit
# and the fit_sparse_reml fallback. Docs-content check only; no model fit.
# Standalone:
# julia --project=. -e 'include("test/test_issue_407_docs_note.jl")'

using Test

@testset "issue 407 fitting-at-scale page names the q > 512 limit and fallback" begin
    page = read(joinpath(@__DIR__, "..", "docs", "src", "fitting-at-scale.md"), String)
    @test occursin("boundary_score_unresolved", page)
    @test occursin("fit_sparse_reml", page)
    @test occursin("q > 512", page)
    @test occursin("more than 512 animals", page)
end

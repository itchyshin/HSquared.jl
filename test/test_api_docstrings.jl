# Every `HSquared.*` entry in `docs/src/api.md` must resolve to a real docstring.
#
# WHY THIS EXISTS. Documenter's `@docs` block fails the whole build on a binding with no
# docstring (`:docs_block`, plus `:cross_references` for every `@ref` to it), and that
# failure is only visible where the docs are built. In this repo that is CI alone:
# `docs/make.jl` cannot complete in at least one developer checkout (it dies at
# `npm … vitepress build`), so nothing catches it before push.
#
# The class has already bitten twice in one arc. #370 caught an unresolvable
# `[_ratio_delta_ci](@ref)` by hand; the sibling case --- the docstring for
# `multi_effect_variance_component_covariance` left on the private
# `_multi_effect_variance_component_covariance` when #362 split the function --- was missed,
# and `main` shipped a red Documenter across two PRs (#373).
#
# Neither instance was a docs edit. Both were ordinary refactors that moved a definition out
# from under its docstring, which is why this is asserted as a PROPERTY of `api.md` rather
# than pinned symbol by symbol: the next one will be a different name.
@testset "every api.md @docs entry has a docstring" begin
    api = joinpath(@__DIR__, "..", "docs", "src", "api.md")
    @test isfile(api)

    entries = [
        strip(line) for line in eachline(api)
        if startswith(strip(line), "HSquared.")
    ]
    # Guard the guard: if `api.md` is moved or restructured, an empty list would make
    # this testset pass while asserting nothing.
    @test length(entries) > 50

    meta = Docs.meta(HSquared)
    undocumented = [
        e for e in entries
        if !haskey(meta, Docs.Binding(HSquared, Symbol(replace(e, "HSquared." => "", count = 1))))
    ]
    @test isempty(undocumented)
    isempty(undocumented) || @info "api.md entries without a docstring" undocumented
end

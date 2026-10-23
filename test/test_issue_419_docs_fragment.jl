using Test

# Documenter heading id: whitespace to hyphens, case kept, parentheses and
# backticks dropped (e.g. "## Documentation map (applied journey)" ->
# "Documentation-map-applied-journey").
heading_id(text) = replace(replace(strip(text), r"[()`]" => ""), r"\s+" => "-")

function heading_ids(path)
    ids = String[]
    in_fence = false
    for line in eachline(path)
        startswith(line, "```") && (in_fence = !in_fence; continue)
        in_fence && continue
        m = match(r"^#{1,6}\s+(.+?)\s*#*\s*$", line)
        m === nothing || push!(ids, heading_id(m.captures[1]))
    end
    return ids
end

# Every `page.md#Fragment` link under docs/src, as (source, page, fragment).
function fragment_links(src)
    links = Tuple{String,String,String}[]
    for file in filter(f -> endswith(f, ".md"), readdir(src))
        text = read(joinpath(src, file), String)
        for m in eachmatch(r"\]\(([A-Za-z0-9_-]+\.md)#([^)\s]+)\)", text)
            push!(links, (file, m.captures[1], m.captures[2]))
        end
    end
    return links
end

@testset "issue 419 docs fragment links" begin
    src = normpath(joinpath(@__DIR__, "..", "docs", "src"))

    @test heading_id("Documentation map (applied journey)") == "Documentation-map-applied-journey"
    @test heading_id("Fit Variance Components Experimentally") == "Fit-Variance-Components-Experimentally"

    links = fragment_links(src)
    @test ("index.md", "twin-boundary.md", "Documentation-map-applied-journey") in links
    @test ("fitting-at-scale.md", "quickstart.md", "Fit-Variance-Components-Experimentally") in links

    for (source, page, fragment) in links
        @test fragment in heading_ids(joinpath(src, page))
    end
end

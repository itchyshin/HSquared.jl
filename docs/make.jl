using Pkg

Pkg.develop(PackageSpec(path = joinpath(@__DIR__, "..")))
Pkg.instantiate()

using Documenter
using DocumenterVitepress
using HSquared

makedocs(;
    sitename = "HSquared.jl",
    authors = "Shinichi Nakagawa",
    modules = [HSquared],
    warnonly = true,
    format = MarkdownVitepress(
        repo = "github.com/itchyshin/HSquared.jl",
        devbranch = "main",
        devurl = "dev",
    ),
    pages = [
        "Home" => "index.md",
        "Get started" => "quickstart.md",
        "Pedigrees and Ainv" => "pedigree-ainv.md",
        "Audience and comparators" => "audience-comparators.md",
        "Roadmap" => "roadmap.md",
        "Reference" => "api.md",
        "Changelog" => "changelog.md",
    ],
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/itchyshin/HSquared.jl.git",
    target = joinpath(@__DIR__, "build"),
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true,
)

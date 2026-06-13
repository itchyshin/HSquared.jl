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
        "Model spec grammar" => "model-spec-grammar.md",
        "Validation status" => "validation-status.md",
        "Data containers" => "data.md",
        "Pedigrees and Ainv" => "pedigree-ainv.md",
        "Audience and comparators" => "audience-comparators.md",
        "Genomics, QTL, GPU, and HPC" => "genomics-qtl-gpu-hpc.md",
        "Backend and algorithm roadmap" => "backend-algorithm-roadmap.md",
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

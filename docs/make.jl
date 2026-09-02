using Pkg

Pkg.develop(PackageSpec(path = joinpath(@__DIR__, "..")))
Pkg.instantiate()

using Documenter
using DocumenterVitepress
using HSquared

# A18: regenerate the Documenter status table from validation_status() before
# makedocs so the public page cannot drift from the live ladder.
include(joinpath(@__DIR__, "..", "tools", "write_validation_status_page.jl"))
write_validation_status_table!()

# Sidebar mirrors hsquared's pkgdown navbar-by-job (Get started / Model guides /
# Status / Comparators / Developer / Reference). Existing pages are regrouped;
# no new reader prose invented here.
# warnonly narrowed from blanket `true`: missing_docs stay warnings; broken
# doctests and cross-refs fail the build (ultra-plan A18 / G8).
makedocs(;
    sitename = "HSquared.jl",
    authors = "Shinichi Nakagawa",
    modules = [HSquared],
    warnonly = [:missing_docs],
    format = MarkdownVitepress(
        repo = "github.com/itchyshin/HSquared.jl",
        devbranch = "main",
        devurl = "dev",
    ),
    pages = [
        "Home" => "index.md",
        "Get started" => [
            "Quick start" => "quickstart.md",
            "Model spec grammar" => "model-spec-grammar.md",
            "Data containers" => "data.md",
            "Pedigrees and Ainv" => "pedigree-ainv.md",
        ],
        "Model guides" => [
            "Standard QG models" => "standard-qg-models.md",
            "Genomic models" => "genomic-models.md",
            "Multivariate models" => "multivariate-models.md",
            "Fitting at scale" => "fitting-at-scale.md",
        ],
        "Status" => [
            "Validation status" => "validation-status.md",
            "Mission control" => "mission-control.md",
        ],
        "Comparators" => [
            "Audience and comparators" => "audience-comparators.md",
        ],
        "Developer" => [
            "Roadmap" => "roadmap.md",
            "Backend and algorithm roadmap" => "backend-algorithm-roadmap.md",
            "Genomics, QTL, GPU, and HPC" => "genomics-qtl-gpu-hpc.md",
        ],
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

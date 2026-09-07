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

# Sidebar follows the applied-reader journey frozen with hsquared on 2026-09-07:
# Get started → Choose a model → Fit → Diagnose → Report. Engine and developer
# routes remain visible but do not replace the R-first applied path.
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
            "Data containers" => "data.md",
            "Pedigrees and Ainv" => "pedigree-ainv.md",
        ],
        "Choose a model" => [
            "Model spec grammar" => "model-spec-grammar.md",
            "Standard QG models" => "standard-qg-models.md",
            "Genomic models" => "genomic-models.md",
            "Multivariate models" => "multivariate-models.md",
        ],
        "Fit" => [
            "Fitting at scale" => "fitting-at-scale.md",
        ],
        "Diagnose" => [
            "Validation status" => "validation-status.md",
        ],
        "Report" => [
            "Twin boundary" => "twin-boundary.md",
            "Audience and comparators" => "audience-comparators.md",
            "Progression and evidence" => "progression-evidence.md",
        ],
        "Developer" => [
            "Roadmap" => "roadmap.md",
            "Backend and algorithm roadmap" => "backend-algorithm-roadmap.md",
            "Genomics, QTL, GPU, and HPC" => "genomics-qtl-gpu-hpc.md",
            "Mission control" => "mission-control.md",
            "Changelog" => "changelog.md",
        ],
        "Reference" => "api.md",
    ],
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/itchyshin/HSquared.jl.git",
    target = joinpath(@__DIR__, "build"),
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true,
)

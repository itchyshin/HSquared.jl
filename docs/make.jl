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
    # Only require *exported* names to appear in the manual. Internal kernels and
    # private helpers (e.g. the Takahashi selected-inverse routines,
    # `_numerator_relationship`, `_single_step_Hinv`) keep their docstrings for
    # source readers without being surfaced on the public API page.
    checkdocs = :exported,
    format = MarkdownVitepress(
        repo = "github.com/itchyshin/HSquared.jl",
        devbranch = "main",
        devurl = "dev",
    ),
    pages = [
        "Home" => "index.md",
        "Mission control" => "mission-control.md",
        "Get started" => "quickstart.md",
        "Model spec grammar" => "model-spec-grammar.md",
        "Validation status" => "validation-status.md",
        "Data containers" => "data.md",
        "Pedigrees and Ainv" => "pedigree-ainv.md",
        "Genomic models" => "genomic-models.md",
        "Standard QG models" => "standard-qg-models.md",
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

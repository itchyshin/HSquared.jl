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
            "Standard QG models" => "standard-qg-models.md",
            "Multivariate models" => "multivariate-models.md",
            "Genomic models" => "genomic-models.md",
            "Model spec grammar" => "model-spec-grammar.md",
        ],
        "Fit" => [
            "Tutorial fit (quick start)" => "quickstart.md",
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

# Legacy Documenter `/dev/reference/` bookmarks → current API page on stable.
ref_redirect = joinpath(@__DIR__, "build", "dev", "reference", "index.html")
mkpath(dirname(ref_redirect))
open(ref_redirect, "w") do io
    write(
        io,
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta http-equiv="refresh" content="0; url=../../stable/api.html">
          <link rel="canonical" href="https://itchyshin.github.io/HSquared.jl/stable/api.html">
          <title>Redirect to API reference</title>
        </head>
        <body>
          <p>Moved to <a href="../../stable/api.html">API reference</a>.</p>
        </body>
        </html>
        """,
    )
end

DocumenterVitepress.deploydocs(;
    repo = "github.com/itchyshin/HSquared.jl.git",
    target = joinpath(@__DIR__, "build"),
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true,
)

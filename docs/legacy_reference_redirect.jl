"""
    write_legacy_dev_reference_redirect!(docs_dir)

Write static redirects for legacy Documenter `/dev/reference` bookmarks into each
VitePress build folder that deploys as `dev` on gh-pages.

DocumenterVitepress builds land in `build/1`, `build/2`, … with bases listed in
`build/bases.txt`. Writing under `build/dev/` before deploy is not deployed.
"""
function write_legacy_dev_reference_redirect!(docs_dir::AbstractString)
    build_dir = joinpath(docs_dir, "build")
    bases_file = joinpath(build_dir, "bases.txt")
    isfile(bases_file) || begin
        @warn "Skipping legacy /dev/reference redirect (no bases.txt)" bases_file
        return
    end

    canonical = "https://itchyshin.github.io/HSquared.jl/stable/api.html"
    redirect_html(target) = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta http-equiv="refresh" content="0; url=$target">
      <link rel="canonical" href="$canonical">
      <title>Redirect to API reference</title>
    </head>
    <body>
      <p>Moved to <a href="$target">API reference</a>.</p>
    </body>
    </html>
    """

    bases = filter(!isempty, readlines(bases_file))
    for (i, base) in enumerate(bases)
        base == "dev" || continue
        version_dir = joinpath(build_dir, string(i))
        ref_dir_index = joinpath(version_dir, "reference", "index.html")
        ref_file = joinpath(version_dir, "reference.html")
        mkpath(dirname(ref_dir_index))
        write(ref_dir_index, redirect_html("../../stable/api.html"))
        write(ref_file, redirect_html("../stable/api.html"))
        @info "Wrote legacy /dev/reference redirects" ref_dir_index ref_file
    end
end

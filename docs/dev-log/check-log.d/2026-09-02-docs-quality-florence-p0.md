# 2026-09-02 — Florence P0 docs figures (Documenter)

- Branch: `cursor/docs-quality-060-20260902` from `origin/main` (`9b321213`).
- `pkgdown::check_pkgdown()`: No problems found.
- `pkgdown::build_site(preview = FALSE, devel = TRUE)`: Finished building pkgdown site (exit 0, ~129 s). F1/F3/F5 present in built HTML. Article ladder path then corrected to `vignettes/articles/figures/` (avoid `../../reference` breakage).
- `julia --project=docs docs/make.jl`: exit 0, ~58 s. Vitepress build complete. `warnonly = [:missing_docs]` emitted the usual missing-docs list (pre-existing). F1/F3 hashed into `docs/build/1/assets/`. Deployment skipped (local).
- Claim boundary: docs/figures only. No `src/` change, no covered flip, no General/CRAN, no `Pkg.add("HSquared")` by name.
- Twin: R pkgdown figures in `itchyshin/hsquared` branch of the same name.

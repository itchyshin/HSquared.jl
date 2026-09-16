# 2026-09-02 — Florence P0 docs figures (Documenter)

- Branch: `cursor/docs-quality-060-20260902` from `origin/main` (rebased through G10 0.6.0).
- R twin (same branch): `pkgdown::check_pkgdown()`: No problems found. `pkgdown::build_site(preview = FALSE, devel = TRUE)`: Finished building pkgdown site (exit 0, ~103 s). F1 at `articles/hsquared.html` → `../reference/figures/animal-model-path.svg`. F3 at `articles/current-limits.html` and `articles/validation-evidence.html` → `../reference/figures/recovery-ladder.svg`. F5 `pkgdown/extra.css` copied to site `extra.css`.
- `julia --project=docs docs/make.jl`: exit 0, ~38 s. Vitepress build complete. `warnonly = [:missing_docs]` emitted the usual 39 missing-docs list (pre-existing). F1 hashed as `animal-model-path.B7x0nHsE.svg`; F3 as `recovery-ladder.BFIWk2-1.svg`. Deployment skipped (local; `ENV["CI"]` unset).
- Claim boundary: docs/figures only. No `src/` change, no covered flip, no General/CRAN, no `Pkg.add("HSquared")` by name.
- Twin: R pkgdown figures in `itchyshin/hsquared` branch of the same name.

# 2026-09-02 — Florence P1 docs figures (Documenter)

- Branch: `cursor/docs-quality-060-20260902` (continues draft PR #283 after P0).
- Lane: `cursor:HSquared.jl-docs-quality-p1` (narrowed away from post-g10 `docs/src/index.md` / changelog leases).
- Added: F4 `docs/src/assets/twin-bridge.svg` in `quickstart.md` CSC section; F2 `docs/src/assets/g0-rg-teaching.svg` in `multivariate-models.md`.
- `julia --project=docs -e 'include("docs/make.jl")'`: exit 0 (~45 s). Vitepress build complete. Deployment skipped (local). Usual `warnonly = [:missing_docs]` list (pre-existing).
- Claim boundary: docs/figures only. No `src/` change, no covered flip, no General/CRAN.
- Twin: hsquared PR #150 same branch name.

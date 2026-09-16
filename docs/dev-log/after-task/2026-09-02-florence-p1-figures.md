# After-task — Florence P1 twin-bridge + G0/r_g + banners

**Date:** 2026-09-02  
**Lanes:** `cursor/docs-quality-060-20260902` (R + Julia)  
**PRs:** hsquared #150 · HSquared.jl #283 (draft, same branch)

## What landed

| ID | R | Julia |
| --- | --- | --- |
| F4 twin bridge | `man/figures/twin-bridge.svg` in `fitting-models.Rmd` | `docs/src/assets/twin-bridge.svg` in `quickstart.md` |
| F2 G0 / r_g | SVG + `autoplot(..., "g_matrix")` in `g-matrix-interpretation.Rmd`; SVG callout in `multivariate.Rmd` | SVG in `multivariate-models.md` |
| F5 banners | Remaining articles that lacked `hs-banner` | Already covered in P0 |

## Rose

No claim flips. Default vs opt-in labelled on F4. Multivariate figures wear experimental / point-display / no-loadings language. Intervals banners remain asymptotic / not coverage-calibrated.

## Checks

- R: `pkgdown::check_pkgdown()` clean; targeted `build_article` ×3 OK.
- Julia: `docs/make.jl` exit 0.

## Next

P2 (F7 EBV caterpillar polish / F8 recovery strip) only if timeboxed. Watch CI on #150 / #283.

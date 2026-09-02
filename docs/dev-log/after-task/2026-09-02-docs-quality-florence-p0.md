# After-task — Florence P0 docs figures (Documenter)

**Date:** 2026-09-02  
**Goal:** Ship F5 experimental banner chrome, F1 animal-model path, F3 recovery ladder on HSquared.jl Documenter; fix stale honesty on standard-QG, multivariate, and genomics-roadmap pages. No covered flip.

**Active lenses:** Florence, Pat, Rose, Darwin, Grace (perspectives)  
**Spawned subagents:** none  
**Current lane:** Julia docs (`cursor/docs-quality-060-20260902`)  
**R twin:** parallel WT, same branch name. G10 `vignettes/` lease still live — R after-task skipped; R pkgdown rebuild recorded below.

## Files changed

- `docs/src/assets/animal-model-path.svg` (F1 engine twin; ASCII labels)
- `docs/src/assets/recovery-ladder.svg` (F3; caption dated post-G10 count 6)
- `docs/src/assets/hs-docs.css`
- `docs/src/quickstart.md` — F5 warning + F1
- `docs/src/validation-status.md` — F3
- `docs/src/genomic-models.md` — F5 warning + CSS
- `docs/src/multivariate-models.md` — F5 + drop “not wired to R” / “no comparator yet”
- `docs/src/standard-qg-models.md` — F5 + drop “R formula still errors as planned”
- `docs/src/fitting-at-scale.md` — F5 wording + CSS
- `docs/src/genomics-qtl-gpu-hpc.md` — F5 + reserved-name honesty (`permanent()`/`common_env()` do fit opt-in)

## Public claim audit (Rose)

CLEAN-WITH-LIMITATIONS. No capability-status edit. No `public_covered_count` move. Experimental label retained. Registration remains url-only. Multivariate/QG/genomics-roadmap pages now *under-claim less* and no longer contradict the ledger. Figure captions defer live count to `validation_status()`. F3 caption dated 2026-09-02 post-G10 (`= 6`).

## Checks

See `docs/dev-log/check-log.d/2026-09-02-docs-quality-florence-p0.md`.

## What did not go smoothly

- Rebased onto G10 0.6.0 (`public_covered_count` 6) after first commit; SVG caption had to follow live status.
- First SVG pass used non-ASCII punctuation that mojibake’d in git; rewritten ASCII-only.
- R `docs/dev-log/` and remaining experimental articles without `hs-banner` left alone because `cursor:hsquared-post-g10-060` still leases `vignettes/` and `docs/dev-log/`.

## Next

Draft PRs (this slice). P1 leftover: F4 twin-bridge, F2 G₀ panel, remaining R article banners after G10 lease release. No covered flip.

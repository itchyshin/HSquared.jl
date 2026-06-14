# 2026-06-14 GitHub Landing-Page Docs Link

## Task Goal

Make the live Julia Documenter site discoverable from the GitHub repository
landing page, and keep the twin documentation links visible without implying a
new bridge or engine capability.

## Active Lenses And Spawned Agents

- Grace: GitHub repository metadata and Pages availability.
- Shannon: R/Julia twin discoverability.
- Rose: public claim boundary.
- Spawned agents: none.

## Files Changed

- `README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- this report

## What Landed

The live Julia Documenter site is:

<https://itchyshin.github.io/HSquared.jl/>

The GitHub repository metadata already reports that URL as the repository
homepage / Website field, and the README now exposes it immediately under the
title. The README also links the R twin pkgdown site and R twin repository.

## Checks

- `curl -L https://itchyshin.github.io/HSquared.jl/`: HTTP 200, redirects to
  `./dev/`.
- `curl -L https://itchyshin.github.io/HSquared.jl/dev/`: HTTP 200.
- GitHub API repo metadata reports homepage
  `https://itchyshin.github.io/HSquared.jl/` and `has_pages = true`.
- `git diff --check`: passed.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats: 8 docstrings not included in the manual, local
  deployment skipped, default VitePress substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated dependencies.

## Public Claim Audit

Allowed:

- the Julia engine docs are live;
- the GitHub repository Website field points at those docs;
- the README links both the Julia engine docs and the R twin pkgdown site.

Blocked:

- no engine behavior changed;
- no R bridge contract changed;
- no validation status was promoted;
- no new production, comparator, genomic, QTL, GPU, or performance claim was
  made.

## Coordination Notes

The R package repository was not edited. No R issue action is required because
this is Julia repository discoverability only, and the R twin's pkgdown site
was linked rather than changed.

## What Did Not Go Smoothly

The top-of-README link already existed in a stacked Phase 5 draft branch. This
slice repeats only the small landing-page link on a separate branch from
`main`, so it can be reviewed independently of the marker-scan work.

## Known Limitations

The live Documenter root currently redirects to the `dev` documentation build.
That is normal for the current unreleased package state. It is not a stable
versioned release URL.

## Next Actions

- Keep this PR independent and merge only by human decision.
- If this lands before the Phase 5 stack, rebase the stacked branches so the
  duplicate README link disappears cleanly.

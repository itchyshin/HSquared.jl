# 2026-09-07 — tablet navigation overflow regression receipt

- Scope: local-only CSS follow-up to the applied-reader website candidate;
  no rebase, push, merge, API, claim, or capability-status change.
- Measured diagnosis (`/private/tmp/hsq-web-20260907-nav-diagnose.json`): at
  768px, `.VPNavBarMenu` was 842.9px wide, stretching content to 1117.4px and
  document/root width to 1273px.
- Regression rule: at 768–959px only, hide `.VPNavBarMenu`, expose
  `.VPNavBarHamburger` with `display:flex`, and expose `.VPNavScreen` with
  `display:block`; ≥960px keeps the existing desktop menu.
- Measured follow-up: the 768px root width is 768px after the menu switch.
  Keyboard activation expands the hamburger (`aria-expanded=true`) and shows
  the complete mobile screen menu (936px height) while root width remains
  768px.
- Build: `OPENBLAS_NUM_THREADS=1 julia --project=docs docs/make.jl` PASS;
  retained log `/private/tmp/hsq-web-20260907-julia-documenter-tablet-nav.log`.
  No `Pkg.test` rerun: this is CSS-only and the fresh source-test PASS remains
  recorded in `2026-09-07-julia-applied-reader-website.md`.

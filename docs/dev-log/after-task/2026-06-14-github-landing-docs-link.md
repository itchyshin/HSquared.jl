# 2026-06-14 GitHub Landing-Page Docs Link

## Task Goal

Make the live Julia Documenter site discoverable from the GitHub repository
landing page and keep the landing-page status wording honest.

## Active Lenses And Spawned Agents

- Grace: GitHub repository metadata and Pages availability.
- Shannon: R/Julia twin discoverability.
- Rose: public claim boundary.
- Spawned agents: none.

## Files Changed

- `README.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

The GitHub repository homepage field for `itchyshin/HSquared.jl` now points to
the Julia Documenter site:

<https://itchyshin.github.io/HSquared.jl/>

The README now exposes, right under the title:

- the Julia engine docs: <https://itchyshin.github.io/HSquared.jl/>
- the R twin pkgdown site: <https://itchyshin.github.io/hsquared/>
- the R twin repository: <https://github.com/itchyshin/hsquared>

The README status text was also brought in line with the current evidence
ladder: experimental engine utilities exist beyond the initial scaffold, but
production sparse fitting and most public R formula defaults remain blocked.

## Checks

- `curl -L https://itchyshin.github.io/HSquared.jl/`: HTTP 200.
- `curl -L https://itchyshin.github.io/HSquared.jl/dev/mission-control.html`:
  HTTP 200.
- `curl -L https://itchyshin.github.io/hsquared/`: HTTP 200.
- GitHub API repo metadata reports homepage
  `https://itchyshin.github.io/HSquared.jl/`.
- `git diff --check`: passed.

## Public Claim Audit

Allowed:

- the Julia engine docs are live and linked from the repository homepage;
- the R twin pkgdown site is linked for user-facing package docs.

Blocked:

- no engine behavior changed;
- no R bridge contract changed;
- no validation status was promoted;
- no new production or comparator claim was made.

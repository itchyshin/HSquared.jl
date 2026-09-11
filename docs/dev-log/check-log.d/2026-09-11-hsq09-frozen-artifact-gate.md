# 0.9.0 isolated candidates — frozen-artifact gate

**Purpose:** release-candidate artifact preparation only; no promotion or
release action.

- Julia candidate before this check record:
  `89ab34247d0cdebd13c6c62a54ac7a571d8c1933`, clean.
- R candidate: `a1bd525e8594ccc346f43d7741eb37b1e7e112d2`, clean.
- R source tarball SHA-256:
  `942898152a45ea27533ee0a13e4647cdf045e45735e6e1a8ffb1ce43f99f678b`.
- Julia `Pkg.test()` passed after source-bearing 0.9 changes; final Documenter
  build passed at the Julia candidate (42 pre-existing unlisted-docstrings
  warning; local deployment intentionally skipped).
- R: 2867 pass, 0 failure, 0 warning, 75 expected skips; `pkgdown::check_pkgdown()`
  passed; built tarball `R CMD check` had only the expected `New submission` NOTE.
- R Unlazy re-verification: all ten gates met.
- Independent Rose frozen-artifact audit: **PASS**. It checked clean exact heads,
  artifact hash, canonical `V6-GGLLVM-LAPLACE` status, Laplace/ELBO wording for
  non-Gaussian paths, and the experimental opt-in genomic fence.

**Held:** no push, merge, tag, CRAN submission, Julia registry action, or
publication. External CI at the final heads and a separate Gate B maintainer
decision remain required.

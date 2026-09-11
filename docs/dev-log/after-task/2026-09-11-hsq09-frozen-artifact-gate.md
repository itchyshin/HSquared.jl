# 0.9.0 isolated candidates — frozen-artifact gate (2026-09-11)

## Task goal

Prepare paired `hsquared` and `HSquared.jl` 0.9.0 isolated candidates and the
R CRAN artifact gate, while keeping every release action held until an
independent frozen-artifact review passes.

## Exact candidate state

- Julia: branch `codex/hsq09-release-julia-20260911-docs`, commit
  `89ab34247d0cdebd13c6c62a54ac7a571d8c1933` before this closure record.
- R: branch `codex/hsq09-release-r-20260911-integrated`, commit
  `a1bd525e8594ccc346f43d7741eb37b1e7e112d2`.
- R source artifact:
  `hsquared_0.9.0.tar.gz`, SHA-256
  `942898152a45ea27533ee0a13e4647cdf045e45735e6e1a8ffb1ce43f99f678b`.
- Neither Dropbox source checkout was modified.

## Active review lenses

The implementation lane used the R/Julia bridge and scientific-contract
boundaries already ratified for 0.9.0. Three independent, read-only Rose
frozen-artifact passes were requested serially; the first two disclosed stale
terminology rather than passing it. The final Rose review passed after the
repairs below. No compute lane was used in this closeout.

## Files changed

Julia 0.9.0 preparation updated the package version and generated documentation,
the non-Gaussian genetic-GLLVM status language, validation-status identifiers,
tests, and recovery wording. In particular, the canonical public status ID is
`V6-GGLLVM-LAPLACE`; `fit_gllvm_laplace_reml` remains an explicitly historical
function name. The capability and debt ledgers now say that non-Gaussian fitting
uses a Laplace marginal, with exact REML only for its Gaussian reduction.

The paired R candidate carries the corresponding 0.9.0 version and documentation
updates, including the explicit experimental, opt-in Julia genomic route and
non-Gaussian objective terminology.

## Checks run

- Julia `Pkg.test()` passed after the source-bearing terminology/status changes.
- Julia `julia --project=docs docs/make.jl` passed at final candidate
  `89ab3424`; the normal 42 unlisted-docstrings warning and local no-deployment
  notice remained non-failing.
- R full test suite passed: 2867 pass, 0 failures, 0 warnings, 75 expected
  skips.
- R package check of the sealed 0.9.0 tarball completed with one expected
  `New submission` NOTE and no errors or warnings.
- `pkgdown::check_pkgdown()` passed for the R candidate.
- The R Unlazy ledger was reverified with all ten gates met.
- Final independent frozen-artifact Rose audit: PASS. It verified the two clean
  heads, artifact hash, canonical GLLVM status, non-Gaussian objective wording,
  and opt-in experimental genomic fence.

## Public-claim audit

The release candidate does not promote a new covered capability. It preserves
the distinct states of engine implementation, experimental R-public surface,
validation evidence, and release eligibility. Non-Gaussian statements use
Laplace marginal likelihood or variational ELBO terminology; REML is retained
only where it is a clearly labelled historical identifier or the exact Gaussian
reduction. Genomic GREML remains explicit `engine = "julia"`, experimental,
validation-scale, and non-default.

## Tests of the checks

The independent audit caught three stale live surfaces in sequence: a legacy
status cross-reference, a current capability phrase, and the phrase
`slice 3 REML`. Each was corrected, the generated documentation was rebuilt,
and a new auditor received a newly frozen exact head. The final PASS therefore
is not a self-review or a result recycled from an earlier head.

## Coordination and deviations

Work occurred only in fresh isolated R and Julia worktrees. The R candidate is
ahead of its remote branch but was not pushed. The Julia candidate is local.
No source work, fixture change, smoke/campaign rerun, promotion, merge, tag,
registry action, CRAN submission, or publication occurred in this closeout.

## What did not go smoothly

The generated Julia validation-status page carries a regeneration timestamp,
so each final documentation rebuild created a small tracked delta that needed a
separate clean commit. More importantly, initial artifact-audit attempts exposed
current uses of `REML` that were too broad for non-Gaussian fits. Treating those
findings as blockers, rather than exceptions, produced the final contract-consistent
candidate.

## Known limitations

This is an artifact-gate result, not a public release. The final package heads
have not been pushed through external CI at these exact commits, and no external
release system has been contacted. The existing scientific scope remains bounded:
the non-Gaussian genetic-GLLVM path is internal, dense/validation-scale and
experimental; the genomic route is opt-in and experimental.

## Next actions

Prepare a Gate B release packet from these exact candidate commits, including
external CI receipts at the final heads and a maintainer decision. Only that
separate gate may authorize push/merge, tags, CRAN submission, Julia registry,
or public publication.

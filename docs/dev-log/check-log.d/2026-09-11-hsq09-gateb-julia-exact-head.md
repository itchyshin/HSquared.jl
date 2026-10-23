# 0.9 Gate-B Julia exact-head candidate check

- Candidate branch: `codex/hsq09-gateb-julia-integration-20260911`.
- Base: PR #322 exact head `99a1af2eb765d7dd7d8aea1eb642909c9af718e7`.
- Scope: version/candidate metadata and claim-language reconciliation only.
  No estimator, bridge field, fixture, evidence denominator, capability state,
  or public-covered count changed.
- Metadata fence: `Project.toml` and `CITATION.cff` say `0.9.0`; the citation
  file explicitly says it is an unreleased candidate and has no release date.
- Terminology: `V6-GGLLVM-LAPLACE` now calls the non-Gaussian objective a
  Laplace marginal likelihood. The historical function name remains only for
  compatibility; exact REML is restricted to the Gaussian reduction.
- Focused contract command passed:
  `julia --project=. -e 'using HSquared; ... V6-GGLLVM-LAPLACE ...'`.
- Documentation command passed: `julia --project=docs docs/make.jl`.
  Documenter emitted pre-existing undocumented-docstring warnings and skipped
  deployment locally; the generated status page contains `V6-GGLLVM-LAPLACE`.
- Full package command passed: `julia --project=. -e 'using Pkg; Pkg.test()'`.
  The retained log ends `Testing HSquared tests passed`, including A3 and A4.
- Unlazy re-verification passed: six of six gates (`J0`–`J5`).
- No PR was updated, no push/merge/tag/registry/release action occurred.

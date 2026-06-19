# After-Task Report: Multivariate Result Extractors

## Task Goal

Add Julia-side extractor ergonomics for existing Phase 4 multivariate result
objects while keeping the R bridge payload unchanged.

## Active Lenses And Spawned Agents

- Active lenses: Ada, Shannon, Hopper, Gauss, Karpinski, Grace, Rose.
- Spawned subagents: none.

## Files Changed

- `src/multivariate.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `ROADMAP.md`
- `docs/design/03-engine-contract.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/src/multivariate-models.md`
- `docs/src/validation-status.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-14-multivariate-result-extractors.md`

## Checks Run

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  - Phase 4 supplied-covariance testset: 37 checks.
  - Phase 4 multivariate REML testset: 34 checks.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
  - Known caveats remain: 8 unrelated exported/internal docstrings are not in
    the manual, local deployment is skipped outside CI, generated VitePress
    assets use substitutions, and npm audit reports 4 generated-docs
    dependency advisories.
- `git diff --check`: passed.
- Claim scan over touched multivariate/source/status docs: no accidental
  production, comparator, or bridge-payload promotion found.

## Public Claim Audit

This slice adds accessors only:

- `variance_components(result::NamedTuple)`
- `fixed_effects(result::NamedTuple)`
- `breeding_values(result::NamedTuple)`
- `heritability(result::NamedTuple)` for REML results
- `EBV()` / `BLUP()` through the existing `breeding_values()` alias path

The accessors wrap existing multivariate result fields and return copies of
matrix/vector data. They do not widen `result_payload()`, change R syntax,
alter the bridge contract, add comparator evidence, or promote any Phase 4 row
out of `partial`.

## Tests Of The Tests

The new tests mutate returned covariance, fixed-effect, EBV, and heritability
objects and confirm the original fit objects are unchanged. They also confirm
that unrelated `NamedTuple`s fail with `ArgumentError`, and that
`heritability()` is unavailable on supplied-covariance multivariate MME results.

## Coordination Notes

R head `21161a5` documented R-side multivariate extractor examples, with CI
recorded by `6b5758b`. Julia now mirrors the local extractor vocabulary for
multivariate engine results without editing the R repository and without a
bridge payload change.

## What Did Not Go Smoothly

The first attempted test patch used stale context from before the resumed run.
I re-read the current Phase 4 testset and patched against the live file.

## Known Limitations

- Multivariate REML remains dense/validation-scale and partial.
- There is no external sommer/ASReml/JWAS/BLUPF90 parity yet.
- There are no covariance standard errors or likelihood-ratio tests yet.
- There is no R-facing multivariate covariance-structure syntax from this
  slice.

## Next Actions

- Push this extractor slice to PR #17 and record remote CI.
- Continue Phase 4B / Phase 4 evidence work without merging the draft PR.
- Keep R coordination through GitHub issues only unless the lane is explicitly
  reassigned.

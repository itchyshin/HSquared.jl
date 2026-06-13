# EBV BLUP Accuracy Extractor Parity

Date: 2026-06-13

Active lenses: Ada, Hopper, Henderson, Fisher, Karpinski, Rose, Grace.

Spawned subagents: none.

## Goal

Mirror the R twin's EBV/BLUP/accuracy extractor ergonomics in `HSquared.jl`
while preserving the current Julia engine contract: compact `result_payload()`,
validation-scale reliability/PEV only, and no new fitting claim.

## Julia Action

Changed:

- `src/HSquared.jl`;
- `src/likelihood.jl`;
- `src/validation_status.jl`;
- `test/runtests.jl`;
- `docs/design/03-engine-contract.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/src/api.md`;
- `docs/src/changelog.md`;
- `docs/src/index.md`;
- `docs/src/quickstart.md`;
- `docs/src/roadmap.md`;
- `docs/src/validation-status.md`;
- `README.md`;
- `ROADMAP.md`.

Implemented:

- `EBV(fit)` as an alias for `breeding_values(fit)`;
- `BLUP(fit)` as an alias for `breeding_values(fit)`;
- `accuracy(fit)` as `sqrt(reliability(fit))` with finite and `[0, 1]`
  reliability checks.

## Public Claim Audit

Allowed wording:

- Julia has EBV/BLUP extractor aliases matching the R twin's vocabulary.
- Julia has a derived validation-scale `accuracy()` extractor when reliability
  values are valid.

Blocked wording:

- independent accuracy validation;
- production sparse reliability or PEV;
- fitted Mrode output validation;
- external fitted-model comparator parity;
- bridge payload widening;
- new fitting capability.

Rose verdict before checks: clean with limitations.

## Tests Of The Tests

The first `Pkg.test()` run failed when the shared supplied-variance Henderson
MME fixture produced reliability values outside `[0, 1]`. The implementation
was doing the right thing by refusing to compute accuracy. The test was changed
to assert that `accuracy(mme)` errors for that fixture rather than clipping or
hiding the invalid reliability values.

Additional tests cover:

- `EBV(fit)` and `BLUP(fit)` matching `breeding_values(fit)`;
- `EBV(mme)` and `BLUP(mme)` matching `breeding_values(mme)`;
- `accuracy(fit)` and `accuracy(mme)` when reliability is valid;
- malformed reliability rows: out-of-range, non-finite, and length mismatch.

## Checks

- Initial `julia --project=. -e 'using Pkg; Pkg.test()'`: failed as expected
  after exposing invalid fixture reliability for `accuracy(mme)`.
- Final `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals
  sum to 403 checks; dense extractor testset has 48 checks and the Henderson
  MME supplied-variance validation fixture has 42 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependency installation still
  reported npm advisories in transient build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: no matches after replacing new `isapprox`
  shorthand symbols with ASCII calls.
- Claim-boundary scan: expected status/limitation hits only.

## Coordination Notes

R head `afa25f1` added R-side `EBV()`, `BLUP()`, and `accuracy()` extractor
ergonomics. This Julia slice mirrors the vocabulary locally. No R repo edits
were made, and no bridge payload change is required.

## Known Limitations

- `accuracy()` is derived from reliability and is not independently validated.
- Validation-scale reliability can fall outside `[0, 1]`; `accuracy()` errors
  in that case.
- Production sparse reliability/PEV remains planned.
- Fitted Mrode output validation and external fitted-model comparator checks
  remain planned.

## Next Actions

1. Run whitespace, ASCII, and claim-boundary checks.
2. Commit and push.
3. Watch CI, Documenter, and Pages.
4. Continue toward fitted Mrode validation or production sparse output work as
   separate evidence-gated slices.

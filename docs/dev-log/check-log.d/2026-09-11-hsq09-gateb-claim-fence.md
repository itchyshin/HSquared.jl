# Gate B candidate claim-fence correction — 2026-09-11

Scope: terminology and route wording only; no estimator, bridge payload, fixture,
or scientific-contract change.

## Guard

`test/runtests.jl` now rejects the stale genomic-default wording and the two
non-Gaussian-Laplace phrases that called a marginal-likelihood objective REML.
The new guard was observed failing before the correction, then passing.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'` — PASS (including 429/429
  Phase-0 assertions).
- `julia --project=docs docs/make.jl` — PASS. The pre-existing 43
  undocumented-docstring warnings remain; local deployment is intentionally
  skipped outside CI.
- Targeted stale-phrase scan — PASS. Remaining `default-route` strings occur
  only in historical/design documents that explicitly say no default promotion
  occurred.

This receipt does not provide H0/H1/H3 calibration evidence or a release
decision.

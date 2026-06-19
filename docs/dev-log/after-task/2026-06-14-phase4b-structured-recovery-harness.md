# Phase 4B: opt-in structured covariance recovery harness

Active lenses: Curie/Fisher, Gauss, Kirkpatrick/Noether, Rose. Spawned
subagents: none.

## Goal

Add a reproducible recovery harness for the Phase-4B structured multivariate
genetic covariance estimator without making the package test suite RNG-based.

## Files Changed

- `sim/phase4b_structured_covariance_recovery.jl`
- `src/validation_status.jl`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `ROADMAP.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- this report

## What Landed

`sim/phase4b_structured_covariance_recovery.jl` is an opt-in script, not part of
CI. It simulates a repeated-record half-sib design with:

- 60 animals;
- 180 records;
- 3 traits;
- 3 records per animal;
- seeded factor-analytic and low-rank genetic covariance structures.

The script exits nonzero unless:

- the optimizer converges;
- relative Frobenius error for the genetic covariance is at most `0.45`;
- relative Frobenius error for the residual covariance is at most `0.25`.

These are loose, version-robust recovery thresholds. They are not comparator
tolerances.

## Checks Run

Command:

```sh
~/.juliaup/bin/julia --project=. sim/phase4b_structured_covariance_recovery.jl
```

Outcome: passed.

Results:

- factor-analytic, seed `20260614`: converged, 2362 iterations,
  `relative_error_G = 0.200897`, `relative_error_R = 0.167222`;
- low-rank, seed `20260615`: converged, 423 iterations,
  `relative_error_G = 0.376322`, `relative_error_R = 0.133646`.

## Public Claim Audit

Allowed:

- an opt-in, seeded, internal recovery harness exists for Phase-4B low-rank and
  factor-analytic covariance structures;
- the harness passed once under the command and seeds above;
- CI remains RNG-free.

Blocked / not claimed:

- no R-facing covariance-structure syntax;
- no bridge payload or `result_payload()` change;
- no loading sign or rotation convention;
- no covariance standard errors or likelihood-ratio tests;
- no multi-seed calibration;
- no published multi-trait fixture;
- no sommer/ASReml/BLUPF90 comparator parity;
- no production sparse factor-analytic fitting.

`V4-FA` remains `partial`.

## Tests Of The Tests

The harness would fail if `fit_multivariate_reml` did not converge on either
seeded case or if the recovered covariance matrices missed the loose relative
error bounds. It is deliberately separate from `test/runtests.jl` so Julia
minor-version RNG or optimization drift cannot make regular CI flaky.

## Coordination Notes

The R bridge issue already records that Phase 4B is Julia-internal and does not
request R syntax or payload changes. This slice strengthens Julia evidence only.

## What Did Not Go Smoothly

The first single-record prototype recovered the broad signal but did not
converge within a friendly iteration budget. The final harness uses repeated
records per animal to separate genetic and residual covariance more clearly.

## Known Limitations

- One seed per structure, not a calibrated simulation study.
- Loose recovery thresholds.
- No external comparator.
- No loading interpretation convention.

## Next Actions

1. Decide and document loading sign / rotation conventions before interpreting
   `genetic_loadings`.
2. Add a shared deterministic multi-trait fixture for R-lane comparator work.
3. Keep covariance-structure syntax out of the R bridge until the contract is
   explicitly agreed.

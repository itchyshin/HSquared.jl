# Phase 4: opt-in multivariate REML recovery harness

Active lenses: Curie/Fisher, Gauss, Rose. Spawned subagents: none.

## Goal

Add a committed, reproducible recovery harness for unstructured multivariate
REML without putting RNG into the regular CI test suite.

## Files Changed

- `sim/phase4_multivariate_reml_recovery.jl`
- `src/validation_status.jl`
- `ROADMAP.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- this report

## What Landed

`sim/phase4_multivariate_reml_recovery.jl` is an opt-in script, not part of CI.
It simulates a repeated-record half-sib design with:

- 80 animals;
- 240 records;
- 2 traits;
- 3 records per animal;
- true unstructured genetic and residual covariance matrices.

The script exits nonzero unless:

- the optimizer converges;
- relative Frobenius error for the genetic covariance is at most `0.25`;
- relative Frobenius error for the residual covariance is at most `0.20`.

## Checks Run

Command:

```sh
~/.juliaup/bin/julia --project=. sim/phase4_multivariate_reml_recovery.jl
```

Outcome: passed.

Results:

- seed `20260616`;
- 244 iterations;
- `relative_error_G = 0.174500`;
- `relative_error_R = 0.131056`.

Additional checks:

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
- `git diff --check`: passed.
- Current docs/source scan found no stale "no committed recovery harness" or
  "known-truth recovery is one-off" wording for `V4-MV-REML`.

Docs build caveats are unchanged from earlier slices: 8 unrelated docstrings are
not included in the manual, local deployment is skipped outside CI,
logo/favicon/package.json substitutions are absent, and VitePress reports 4 npm
audit advisories in generated docs dependencies.

## Public Claim Audit

Allowed:

- an opt-in, seeded, internal recovery harness exists for unstructured
  two-trait REML;
- the harness passed once under the command and seed above;
- CI remains RNG-free.

Blocked / not claimed:

- no multi-seed recovery calibration;
- no covariance standard errors or likelihood-ratio tests;
- no published Mrode multi-trait fixture;
- no sommer/ASReml/JWAS comparator parity;
- no R-facing multivariate syntax;
- no bridge payload or `result_payload()` change;
- no production sparse multivariate fitting.

`V4-MV-REML` remains `partial`.

## Coordination Notes

No R repository code was edited. This slice strengthens Julia-internal recovery
evidence and gives the R lane a clearer target for future comparator work.

## Next Actions

1. Use the shared CSV fixture in `test/fixtures/phase4_multitrait_parity/` for
   R-lane sommer/ASReml/BLUPF90 comparator checks.
2. Add covariance SE/LRT support only after an explicit inference design slice.
3. Keep multivariate syntax out of the R bridge until the R lane opens that
   contract deliberately.

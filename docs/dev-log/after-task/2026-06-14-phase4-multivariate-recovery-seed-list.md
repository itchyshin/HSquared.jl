# 2026-06-14 Phase 4 Multivariate Recovery Seed-List Reporting

## Task Goal

Add explicit seed-list reporting to the unstructured Phase 4 multivariate REML
recovery harness, matching the Phase 4B structured harness surface while keeping
recovery evidence opt-in and outside CI.

## Active Lenses And Spawned Agents

- Curie/Fisher: simulation target and interpretation.
- Gauss: multivariate REML recovery behavior.
- Grace: local checks and reproducibility.
- Rose: claim-vs-evidence boundary.
- Spawned agents: none.

## Files Changed

- `sim/phase4_multivariate_reml_recovery.jl`
- `src/validation_status.jl`
- `test/runtests.jl`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/src/validation-status.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `ROADMAP.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

`sim/phase4_multivariate_reml_recovery.jl` now supports:

```sh
--seed=N
--seeds=N[,N...]
```

The historical `--seed` interface remains for one run. The new `--seeds` option
runs every listed seed and prints a summary with seed count, pass count, and
maximum relative errors. The two options are mutually exclusive.

## Checks Run

- `~/.juliaup/bin/julia --project=. sim/phase4_multivariate_reml_recovery.jl --seeds=20260616`: passed.
  - converged: true
  - iterations: 244
  - relative error `G = 0.174500`, threshold `0.25`
  - relative error `R = 0.131056`, threshold `0.20`
- `~/.juliaup/bin/julia --project=. sim/phase4_multivariate_reml_recovery.jl --seed=20260616 --seeds=20260616`: failed as intended.
  - error: `ArgumentError: use either --seed or --seeds, not both`
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed after
  updating one stale assertion.
  - Phase 0 scaffold/validation-status block is now 174 checks.
  - Phase 4B structured covariance testset remains 61 checks.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.

## Public Claim Audit

Allowed:

- the unstructured multivariate REML recovery harness supports explicit seed
  lists;
- the historical seed `20260616` passes through the explicit seed-list path at
  default iterations;
- the script rejects ambiguous simultaneous `--seed` and `--seeds` arguments.

Blocked:

- no CI RNG;
- no broad multi-seed calibration claim;
- no R-facing multivariate syntax;
- no bridge payload or `result_payload()` change;
- no external comparator parity;
- no status promotion for `V4-MV-REML`.

## Tests Of The Tests

`test/runtests.jl` now requires the `V4-MV-REML` validation-status evidence to
mention explicit `--seeds` support and its claim boundary to retain the "not
broadly multi-seed calibrated" wording.

## Coordination Notes

No R repository code was edited. This gives future R-lane comparator work a
clearer way to request or reproduce Julia-side unstructured multivariate REML
recovery runs, but it does not change the R bridge or user syntax.

## What Did Not Go Smoothly

The first `Pkg.test()` pass failed because the status text changed from "not
multi-seed calibrated" to "not broadly multi-seed calibrated", while one old
test assertion still expected the former. The failure did its job: it forced the
claim-boundary assertion to be updated deliberately.

## Known Limitations

- Only the historical default seed was rerun through the new explicit seed-list
  path.
- There is no simulation-error interval, seed-count justification, or parameter
  grid.
- This is still internal recovery evidence, not external comparator parity.

## Next Actions

1. Add a real calibration protocol before any future multi-seed claim.
2. Keep external multi-trait comparator parity on the R issue track.
3. Leave `V4-MV-REML` partial.

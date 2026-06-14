# 2026-06-14 Phase 4B Structured Recovery Seed-List Reporting

## Task Goal

Improve the opt-in Phase 4B structured-covariance recovery harness so it can run
explicit seed lists and summarize pass/fail evidence by covariance structure,
without moving stochastic recovery into CI or overclaiming calibration.

## Active Lenses And Spawned Agents

- Curie/Fisher: simulation target and interpretation.
- Kirkpatrick/Gauss: structured covariance recovery semantics.
- Grace: local checks and reproducibility.
- Rose: claim-vs-evidence boundary.
- Spawned agents: none.

## Files Changed

- `sim/phase4b_structured_covariance_recovery.jl`
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

`sim/phase4b_structured_covariance_recovery.jl` now accepts:

```sh
--seeds=N[,N...]
```

When `--seeds` is omitted, the script preserves the historical single default
seed for each requested case. When `--seeds` is supplied, every requested case is
run for every listed seed. The script prints each result as it finishes, then a
summary line for each case with the number of seeds, number passed, and maximum
relative errors.

## Checks Run

- `~/.juliaup/bin/julia --project=. sim/phase4b_structured_covariance_recovery.jl --case=factor_analytic --seeds=20260614`: passed.
  - converged: true
  - iterations: 2362
  - relative error `G = 0.200897`, threshold `0.45`
  - relative error `R = 0.167222`, threshold `0.25`
- `~/.juliaup/bin/julia --project=. sim/phase4b_structured_covariance_recovery.jl --case=lowrank --seeds=20260615`: passed.
  - converged: true
  - iterations: 423
  - relative error `G = 0.376322`, threshold `0.45`
  - relative error `R = 0.133646`, threshold `0.25`
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  - Phase 0 scaffold/validation-status block is now 173 checks.
  - Phase 4B structured covariance testset remains 61 checks.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.

## Public Claim Audit

Allowed:

- the Phase 4B structured recovery harness supports explicit seed lists;
- historical factor-analytic and low-rank recovery seeds pass through the
  explicit seed-list path at default iterations;
- the script prints per-case summaries for opt-in recovery runs.

Blocked:

- no CI RNG;
- no broad multi-seed calibration claim;
- no R-facing covariance syntax;
- no bridge payload or `result_payload()` change;
- no external comparator parity;
- no status promotion for `V4-FA`.

## Tests Of The Tests

`test/runtests.jl` now requires the `V4-FA` validation-status evidence to mention
explicit `--seeds` support, so future rewrites should not silently drop the
reproducibility surface.

## Coordination Notes

No R repository code was edited. This slice gives the R lane a clearer future
way to request or reproduce Julia-side structured-covariance recovery runs, but
it does not create R syntax or a bridge contract.

## What Did Not Go Smoothly

An attempted factor-analytic smoke run with
`--seeds=20260614,20260615 --iterations=1500` failed because neither fit
converged by the reduced iteration cap. The relative covariance errors were
inside the loose bounds, but convergence is part of the pass condition, so this
run is deliberately not used as recovery evidence.

The full all-cases two-seed run was also too slow for a quick gate. That is why
the status wording says explicit seed-list reporting exists, while broad
multi-seed calibration remains future work.

## Known Limitations

- Only the historical factor-analytic and low-rank seeds were rerun at default
  iterations through the new seed-list path.
- There is no simulation-error interval, coverage estimate, or seed-count
  justification.
- This is still model-internal recovery, not external comparator parity.

## Next Actions

1. Add a planned calibration protocol before any future multi-seed claim:
   seed count, parameter grid, runtime budget, and summary statistics.
2. Keep the R lane on issue coordination only until it chooses an external
   comparator run.
3. Leave `V4-FA` partial.

# 2026-06-14 Recovery Calibration Log Summarizer

## Task Goal

Add deterministic tooling that regenerates the recovery calibration summary from
committed raw logs, so future audits do not depend on hand parsing or rerunning
stochastic harnesses.

## Active Lenses And Spawned Agents

- Grace: reproducible developer tooling.
- Curie/Fisher: calibration summary fields and failed-seed reporting.
- Rose: claim boundary.
- Spawned agents: none.

## Files Changed

- `sim/summarize_recovery_calibration.jl`
- `test/runtests.jl`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

`sim/summarize_recovery_calibration.jl` parses recovery harness logs and emits a
Markdown summary with:

- seed, convergence, and pass counts by case;
- pass proportion and Wilson 95% interval;
- mean, median, and maximum relative `G` and `R` errors;
- failed seed lists with relative errors.

The script is deterministic and does not call the simulation harnesses.

## Checks Run

- Throttled CLI smoke:

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. sim/summarize_recovery_calibration.jl docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-unstructured.log docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-structured.log
```

Output included the expected case summaries:

- `unstructured`: 10 seeds, 10 converged, 6 passed;
- `factor_analytic`: 10 seeds, 10 converged, 8 passed;
- `lowrank`: 10 seeds, 10 converged, 9 passed.

- First throttled `Pkg.test()` failed because the script used `Printf`, which
  was not available in the package test environment.
- The script now uses dependency-free fixed-width formatting.
- Final throttled `Pkg.test()` passed.
  - Recovery calibration log summarizer testset: 12 checks.
  - Phase 0 scaffold/validation-status block remains 182 checks.
  - Phase 4B structured covariance testset remains 61 checks.
- Final throttled docs build passed with the known Documenter/manual and
  VitePress local-build caveats.

## Tests Of The Tests

`test/runtests.jl` now includes a deterministic summarizer testset. It parses
the committed logs, requires 30 rows, pins the pass counts and selected maximum
errors, and checks the Markdown failed-seed output.

## Public Claim Audit

Allowed:

- deterministic log-summary tooling exists;
- committed logs can regenerate the calibration case table and failed-seed list.

Blocked:

- no simulation rerun;
- no new recovery evidence;
- no broad multi-seed calibration claim;
- no R-facing syntax;
- no bridge payload or `result_payload()` change.

## Next Actions

1. Use the summarizer for future calibration reruns before copying summary
   numbers into docs.
2. Keep future stochastic calibration runs opt-in and throttled on interactive
   machines.

# 2026-06-14 Local Recovery Run Throttling

## Task Goal

Record a safer local command pattern for opt-in recovery and calibration runs so
long stochastic harnesses do not monopolize an interactive workstation.

## Active Lenses And Spawned Agents

- Grace: developer workflow and reproducibility.
- Curie/Fisher: opt-in recovery evidence hygiene.
- Rose: claim boundary.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/decisions/2026-06-14-multivariate-recovery-calibration-protocol.md`
- `sim/phase4_multivariate_reml_recovery.jl`
- `sim/phase4b_structured_covariance_recovery.jl`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

The calibration protocol now requires recording the local resource profile for
interactive runs. Both recovery harness docstrings and the multivariate docs
show the recommended throttled command prefix:

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15
```

## Public Claim Audit

Allowed:

- future local recovery harness runs should use a one-thread / lower-priority
  command form on interactive machines;
- run plans should record the resource profile.

Blocked:

- no new recovery evidence;
- no simulation rerun;
- no broad calibration claim;
- no R-facing syntax;
- no bridge payload or `result_payload()` change;
- no capability-status promotion.

## Checks

- `git diff --check`: passed.
- Throttled `~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed.
  - Recovery calibration log summarizer testset remains 12 checks.
  - Phase 0 scaffold/validation-status block remains 182 checks.
  - Phase 4B structured covariance testset remains 61 checks.
- Throttled `~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.

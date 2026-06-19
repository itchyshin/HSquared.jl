# 2026-06-14 Multivariate Recovery Calibration Execution

## Task Goal

Execute the predeclared multivariate recovery calibration protocol and record
the complete result, including failures, without promoting any capability beyond
the evidence.

## Active Lenses And Spawned Agents

- Curie/Fisher: seed-level recovery result and pass-proportion summary.
- Gauss: REML recovery interpretation.
- Kirkpatrick: structured covariance / factor-analytic boundary.
- Grace: raw output preservation and reproducibility.
- Rose: claim-vs-evidence boundary.
- Spawned agents: none.

## Files Changed

- `docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-run-plan.md`
- `docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-unstructured.log`
- `docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-structured.log`
- `docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-summary.md`
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

## What Ran

The run plan fixed the engine SHA, Julia/platform, commands, seeds, thresholds,
iteration caps, and DGP settings before execution. The executed commands were:

```sh
~/.juliaup/bin/julia --project=. sim/phase4_multivariate_reml_recovery.jl --seeds=20260616,20260617,20260618,20260619,20260620,20260621,20260622,20260623,20260624,20260625
~/.juliaup/bin/julia --project=. sim/phase4b_structured_covariance_recovery.jl --case=both --seeds=20260614,20260615,20260616,20260617,20260618,20260619,20260620,20260621,20260622,20260623
```

Both commands exited non-zero because at least one seed failed the predeclared
thresholds. Raw output was still captured and committed.

## Result

The calibration protocol was executed and did **not** pass.

| case | seeds | converged | passed | Wilson 95% interval | max G error | max R error |
| --- | ---: | ---: | ---: | --- | ---: | ---: |
| unstructured | 10 | 10 | 6 | 0.312674-0.831820 | 0.478375 | 0.206494 |
| factor_analytic | 10 | 10 | 8 | 0.490162-0.943318 | 0.577749 | 0.252226 |
| lowrank | 10 | 10 | 9 | 0.595850-0.982124 | 0.422179 | 0.262608 |

Failed seeds:

- unstructured: `20260618`, `20260619`, `20260621`, `20260625`;
- factor_analytic: `20260616`, `20260619`;
- lowrank: `20260619`.

## Checks Run

These checks were run after the heavy harness execution with one-thread
BLAS/OpenMP/Julia settings and lower scheduling priority:

- `git diff --check`: passed.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed.
  - Phase 0 scaffold/validation-status block is now 182 checks.
  - Phase 4B structured covariance testset remains 61 checks.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.

## Public Claim Audit

Allowed:

- the recovery calibration protocol was executed on predeclared seed lists;
- all fits converged;
- the run did not pass the predeclared threshold gate;
- the raw logs and seed-level summary are recorded under
  `docs/dev-log/recovery-checkpoints/`.

Blocked:

- no broad multi-seed calibration claim;
- no status promotion for `V4-MV-REML` or `V4-FA`;
- no R-facing multivariate or covariance-structure syntax;
- no bridge payload or `result_payload()` change;
- no covariance standard errors or likelihood-ratio tests;
- no external comparator parity.

## Tests Of The Tests

`test/runtests.jl` now requires `V4-MV-REML` evidence to say the calibration
protocol did not pass and to include the `6/10 passed` result. It also requires
`V4-FA` evidence to say the calibration protocol did not pass and to include the
`8/10` and `9/10` structured results.

## Coordination Notes

No R repository code was edited. The R twin should treat this as a wording guard:
seed-list support exists, and a predeclared calibration run exists, but it is
negative evidence rather than a calibration pass.

## Runtime Note

The calibration harness was heavy enough to affect the workstation. Any
remaining local Julia verification in this thread should be run with:

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15
```

## Known Limitations

- The DGPs are still scripted Gaussian half-sib fixtures, not external
  comparator parity.
- The run did not explore alternative sample sizes, records per animal, or
  thresholds.
- No optimizer tuning or threshold revision was performed after seeing results.

## Next Actions

1. Keep `V4-MV-REML` and `V4-FA` partial.
2. Decide whether the next recovery slice should increase data size, revise the
   DGP, or treat these thresholds as intentionally stringent stress evidence.
3. Keep external comparator parity on the R-lane issue track.

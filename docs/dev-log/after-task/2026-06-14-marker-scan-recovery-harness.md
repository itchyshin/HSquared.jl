# After Task: Marker Scan Recovery Harness

Date: 2026-06-14

## Task Goal

Add an opt-in Phase 5 marker-scan recovery harness for existing direct Julia
fixed, supplied-variance mixed, and supplied LOCO marker-scan helpers, while
keeping RNG out of the package test suite and keeping public claims partial.

## Active Lenses And Agents

- Active lenses: Ada, Shannon, Curie, Fisher, Grace, Rose.
- Spawned subagents: none.
- Lane: Julia engine lane only.

## Files Changed

- Added `sim/phase5_marker_scan_recovery.jl`.
- Added
  `docs/dev-log/recovery-checkpoints/2026-06-14-phase5-marker-scan-recovery.log`.
- Added
  `docs/dev-log/scout/2026-06-14-marker-scan-recovery-harness-scout.md`.
- Updated `src/validation_status.jl` and validation-status tests in
  `test/runtests.jl`.
- Updated `README.md`, `ROADMAP.md`, `docs/src/index.md`,
  `docs/src/roadmap.md`, `docs/src/genomics-qtl-gpu-hpc.md`,
  `docs/src/validation-status.md`, `docs/src/mission-control.md`, and
  `docs/src/changelog.md`.
- Updated `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md`,
  `docs/design/06-public-claims-register.md`,
  `docs/dev-log/coordination-board.md`, and
  `docs/dev-log/check-log.md`.

## Checks Run

- `git diff --check`: passed.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. sim/phase5_marker_scan_recovery.jl`:
  passed. Default seed `20260614` recovered causal marker `m08` as the top
  marker in fixed, mixed, and LOCO cases. Effect relative errors were
  `0.008513`, `0.000349`, and `0.019075` against the committed loose smoke
  threshold `0.350`; top LOD-equivalent scores exceeded the committed minimum
  `4.000`.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test(test_args=["Phase 5 fixed-effect single-marker scan"])'`:
  passed. The test runner executed the suite; Phase 5 fixed-effect
  single-marker scan testset is now 415 checks.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed.
- `rm -rf docs/build && env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local docs caveats remained: 8 unrelated docstrings not in the
  manual, local deployment skipped, VitePress default substitutions, missing
  local logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.
- Narrow Rose grep for high-risk marker/GWAS/QTL/eQTL wording found only
  planned, negative, or explicitly blocked examples.
- Remote CI for pushed commit `03eaae2` on draft PR #34:
  - CI `27514543334`: success on
    <https://github.com/itchyshin/HSquared.jl/actions/runs/27514543334>.
  - Documenter `27514543328`: success on
    <https://github.com/itchyshin/HSquared.jl/actions/runs/27514543328>.
  - Known non-failing Node.js 20 deprecation annotations were emitted by
    upstream actions forced onto Node.js 24.

## Public Claim Audit

Allowed claim: `sim/phase5_marker_scan_recovery.jl` provides opt-in,
outside-CI marker-signal recovery smoke for the direct Julia fixed,
supplied-variance mixed, and supplied LOCO marker-scan helper paths.

Blocked claims remain blocked: calibrated GWAS/QTL/eQTL validation, calibrated
or correlated-marker genome-wide thresholds, p-value calibration,
PVE/model-R2 calibration, public R `marker_scan()` syntax, `gwas_table()` /
`qtl_table()` / `eqtl_table()` activation, bridge payload changes, plotting
backend claims, and comparator parity.

## Tests Of The Tests

The package test suite remains deterministic. It does not run the RNG recovery
harness. Instead, the validation-status tests assert that the harness file
exists, names the three direct helper calls, keeps an unknown-argument guard,
and states that its thresholds are not calibrated genome-wide thresholds.

## Coordination Notes

The R twin was checked read-only and remained clean on `main` at `3666363`.
This slice edits no R code, does not change the bridge payload, and does not
change public R syntax. R-lane coordination should happen through GitHub issue
comments after the Julia PR exists.

## What Did Not Go Smoothly

- One public-claims patch missed because the row text had already drifted; the
  row was reopened and patched against the current file.
- One broad grep entered generated `docs/build` HTML and was stopped. A narrow
  source-file grep was used for the audit.
- Local Documenter still emits the known non-failing VitePress/npm/docstring
  warnings.

## Known Limitations

- Single default seed only; no broad multi-seed calibration claim.
- Strong single-causal-marker smoke scenario only.
- Supplied variance components only for mixed and LOCO scans.
- No external comparator parity.
- No R-facing `marker_scan()` syntax or bridge payload change.

## Next Actions

- Review draft PR #34 and merge only after the stacked Phase 5 PR chain is
  ready.
- Comment on Julia/R coordination issues if R-lane marker work starts: this is
  Julia-only recovery smoke and not public R marker-scan activation.

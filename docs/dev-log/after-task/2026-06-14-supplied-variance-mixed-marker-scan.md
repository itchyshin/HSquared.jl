# After-Task Report: Supplied-Variance Mixed-Model Marker Scan

## Task Goal

Add a direct Julia relationship-corrected marker-screening helper that uses
supplied variance components and a supplied relationship precision, without
adding R syntax, bridge payload changes, LOCO, p-value calibration, plotting, or
a broad GWAS/QTL claim.

## Active Lenses And Agents

- Gauss: GLS covariance and linear algebra.
- Fisher: Wald estimand and no calibration overclaim.
- Curie: deterministic tests and guardrails.
- Grace: low-core local checks and Documenter build.
- Shannon: R/Julia boundary.
- Rose: claim-vs-evidence gate.
- Spawned subagents: none.

## Files Changed

- `src/HSquared.jl`
- `src/genomic.jl`
- `src/validation_status.jl`
- `test/runtests.jl`
- `README.md`
- `ROADMAP.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/src/validation-status.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-14-supplied-variance-mixed-marker-scan.md`

## Checks Run

- First low-core `Pkg.test()` attempt after implementation failed because a
  duplicated fixed-effect design guard used a numerically soft weighted
  Cholesky check. The helper now checks `rank(X) == size(X, 2)` before fitting.
- Second low-core `Pkg.test()` attempt passed after implementation and before
  final ledger/docs edits. Phase 5 fixed-effect single-marker scan testset was
  123 checks.
- Third low-core `Pkg.test()` attempt after adding the new validation row failed
  because the validation-status row-count assertion still expected 29 rows. The
  expected count is now 30.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block is now 206 checks; Phase 5
  fixed-effect single-marker scan testset is now 123 checks; Phase 4B structured
  covariance remains 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats remained: 8 docstrings not included in the manual,
  local deployment skipped, VitePress default substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.

## Public Claim Audit

Allowed claim: `mixed_model_marker_scan()` is a dense validation-scale,
supplied-variance Julia helper. It forms
`V = sigma_a2 * Z * A * Z' + sigma_e2 * I` from supplied variance components and
a supplied relationship precision, then runs marker-by-marker GLS Wald tests
conditional on `X`.

Disallowed claims remain explicit: this is not marker-scan variance-component
estimation, not LOCO, not a sparse production scan, not calibrated mixed-model
p-values, not genomic-inflation diagnostics, not interval mapping, not a
plotting backend, not an R `marker_scan()` formula term, not a bridge payload
change, and not comparator evidence.

## Tests Of The Tests

The deterministic tests pin:

- reduction to `single_marker_scan()` when the random-effect design contributes
  zero covariance;
- agreement with an independent GLS calculation on a pedigree-covariance
  fixture;
- Bonferroni/BH and LOD-score identities over mixed-scan p-values;
- compatibility with `marker_manhattan_data()` and `marker_qq_data()`;
- guards for variance components, dimensions, positive-definite `Ainv`,
  rank-deficient `X`, and marker collinearity under the supplied covariance.

The validation-status tests assert that the new `V5-MARKER-MIXED` row names
`mixed_model_marker_scan()` and keeps the dense supplied-variance / no
calibration / no bridge-change claim boundary.

## Coordination Notes

No R repo files were edited. The R-facing `marker_scan()` formula term remains
planned/reserved only. No bridge payload or `result_payload()` shape changed.

## What Did Not Go Smoothly

- The first guard for rank-deficient `X` was too permissive under a weighted
  Cholesky check. It is now an explicit matrix-rank check.
- The validation-status row-count assertion correctly failed after the new row
  was added and has been updated.

## Known Limitations

- Dense validation-scale helper only.
- Supplied variance components only.
- No LOCO, calibration, genomic-inflation diagnostics, plotting backend,
  external comparator parity, R syntax, or bridge activation.

## Next Actions

- Add LOCO or marker-scan variance-component estimation only as separately
  gated slices with explicit estimands and tests.
- Coordinate any R-facing marker API through GitHub issues before changing the
  bridge contract.

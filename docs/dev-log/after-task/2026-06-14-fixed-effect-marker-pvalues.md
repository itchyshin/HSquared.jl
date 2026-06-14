# 2026-06-14 Fixed-Effect Marker-Scan P-Values

## Task Goal

Add p-values to the direct Julia fixed-effect marker-screening utility while
keeping the scope honest: supplied-variance Gaussian/Wald p-values only, no R
formula activation, and no mixed-model marker-scan claim.

## Active Lenses And Spawned Agents

- Fisher: Wald p-value interpretation.
- Curie: deterministic tests and edge cases.
- Grace: throttled local checks.
- Rose: claim-vs-evidence audit.
- Spawned agents: none.

## Files Changed

- `src/genomic.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/src/changelog.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/src/validation-status.md`
- `ROADMAP.md`
- this report

## What Landed

`single_marker_scan()` now returns `p_values`, approximate two-sided
Gaussian/Wald p-values computed from the existing z-scores. The implementation
uses a self-contained Abramowitz-Stegun normal-CDF approximation to avoid
adding a statistics dependency. The `z = 0` symmetry case returns exactly
`1.0` after the first test run caught the approximation error at zero.

Tests now pin:

- hand-fixture p-values for the two-marker deterministic example;
- known z-value behavior at `z = 0` and `z = 1.96`;
- consistency between covariate-adjusted scan p-values and the helper;
- the non-finite z guard.

## Public Claim Audit

Allowed:

- `single_marker_scan()` reports approximate two-sided Gaussian/Wald p-values
  for direct fixed-effect screening with supplied residual variance.

Blocked:

- no calibrated mixed-model p-values;
- no LOD scores;
- no LOCO;
- no multiple-testing correction;
- no relationship or population-structure correction;
- no mixed-model GWAS/QTL/eQTL claim;
- no R `marker_scan()` formula activation;
- no bridge payload or `result_payload()` change;
- no external comparator parity.

## Checks

- `git diff --check`: passed.
- First throttled `Pkg.test()` attempt failed because the p-value helper
  returned `0.9999999989503827` rather than exactly `1.0` for `z = 0`.
- Final throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed.
  - Phase 0 scaffold/validation-status block remains 193 checks.
  - Recovery calibration log summarizer remains 21 checks.
  - Phase 5 fixed-effect single-marker scan testset is now 27 checks.
  - Phase 4B structured covariance remains 61 checks.
- Throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.

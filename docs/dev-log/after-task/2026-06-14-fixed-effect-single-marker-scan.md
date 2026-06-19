# 2026-06-14 Fixed-Effect Single-Marker Scan

## Task Goal

Add a small Phase 5 marker-screening utility on the Julia engine side, while
keeping the public R formula contract untouched and the claim boundary explicit.

## Active Lenses And Spawned Agents

- Ada/Shannon: slice scope and R/Julia coordination.
- Jason/Fisher/Curie: marker-screening scope, deterministic validation, and
  simulation restraint.
- Grace: local checks and docs build.
- Rose: claim-vs-evidence audit.
- Spawned agents: none.

## Files Changed

- `src/genomic.jl`
- `src/HSquared.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `docs/src/api.md`
- `docs/src/validation-status.md`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/changelog.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/scout/2026-06-14-fixed-effect-marker-scan-scout.md`
- `ROADMAP.md`
- this report

## What Landed

`single_marker_scan(y, X, markers; sigma_e2 = 1.0, marker_ids = nothing,
allele_frequencies = nothing)` is now exported as a direct Julia utility.
It centers biallelic marker dosages with the existing VanRaden centering path,
residualizes `y` and each marker against `X`, then returns marker IDs, effects,
supplied-variance standard errors, z-scores, chi-square statistics,
denominators, allele frequencies, and the VanRaden scale.

The test fixture is deterministic and hand checked: intercept-only effects are
`17/14` and `0.5`, denominators are `2.8` and `4.0`, and the covariate-adjusted
path is cross-checked against an independent residualization calculation in the
test.

## Public Claim Audit

Allowed:

- direct Julia fixed-effect Gaussian marker screening exists;
- results are deterministic for tiny fixtures and use supplied residual
  variance;
- `V5-MARKER-FIXED` may be described as partial/experimental engine evidence.

Blocked:

- no mixed-model GWAS, QTL, or eQTL claim;
- no relationship or population-structure correction;
- no LOCO path;
- no p-values, LOD scores, or multiple-testing correction;
- no external comparator parity;
- no R `marker_scan()` formula activation;
- no bridge payload or `result_payload()` change.

## Checks

- `git diff --check`: passed.
- Throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed.
  - Phase 0 scaffold/validation-status block is now 193 checks.
  - Recovery calibration log summarizer remains 21 checks.
  - New Phase 5 fixed-effect single-marker scan testset is 20 checks.
  - Phase 4B structured covariance remains 61 checks.
- Throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.

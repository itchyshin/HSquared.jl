# 2026-06-14 Fixed-Effect Marker-Scan Manhattan Plot Data

## Task Goal

Add deterministic Manhattan plot-data preparation for the direct Julia
fixed-effect marker scan while preserving the twin-lane boundary: no R code
edits, no public `marker_scan()` formula activation, no plotting dependency,
and no mixed-model GWAS/QTL claim.

## Active Lenses And Spawned Agents

- Florence: plot-data ergonomics.
- Fisher: p-value display semantics.
- Curie: deterministic tests and edge cases.
- Grace: throttled local checks.
- Shannon: R/Julia bridge boundary and coordination surface.
- Rose: claim-vs-evidence audit.
- Spawned agents: none.

## Files Changed

- `src/HSquared.jl`
- `src/genomic.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `README.md`
- `ROADMAP.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/src/validation-status.md`
- this report

## What Landed

`marker_manhattan_data()` is now exported as a direct Julia plot-data helper for
`single_marker_scan()` results. It returns:

- `marker_ids`;
- `chromosomes`;
- `positions`;
- `plot_positions`;
- `p_values`;
- `neglog10_p_values`;
- `order`;
- `p_floor`.

If chromosome or position metadata is omitted, the helper uses chromosome `"1"`
and sequential positions. If p-values contain zero, only the display
`-log10(p)` value is floor-capped; the raw p-values are preserved.

Tests now pin:

- default chromosome/position/plot-position output;
- `-log10(p)` values for the direct scan;
- custom chromosome ordering and cumulative offsets;
- p-floor behavior for a zero p-value;
- guardrails for missing scan fields, marker/p-value length mismatches,
  chromosome and position length mismatches, negative positions, invalid
  p-floor, and negative chromosome gap.

## Public Claim Audit

Allowed:

- direct Julia `single_marker_scan()` results can be converted to deterministic
  Manhattan plot data;
- `V5-MARKER-FIXED` remains partial/experimental direct Julia engine evidence.

Blocked:

- no actual plotting backend;
- no mixed-model GWAS/QTL/eQTL claim;
- no relationship or population-structure correction;
- no LOCO path;
- no interval-mapping or mixed-model LOD workflow;
- no calibrated mixed-model p-values;
- no correlated-marker or genome-wide calibration claim;
- no external comparator parity;
- no R `marker_scan()` formula activation;
- no bridge payload or `result_payload()` change.

## Checks

- `git diff --check`: passed before and after this report was added.
- First throttled `Pkg.test()` attempt failed because status-row assertions
  still expected the pre-plot-data claim wording.
- Second throttled `Pkg.test()` attempt failed because the default p-floor used
  non-Julia `realmin(Float64)`.
- Final throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed.
  - Phase 0 scaffold/validation-status block is now 194 checks.
  - Phase 5 fixed-effect single-marker scan testset is now 63 checks.
  - Phase 4B structured covariance remains 61 checks.
- Throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.
  - This was rerun after this report was added.

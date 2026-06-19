# 2026-06-14 Marker-Map-Backed Manhattan Plot Data

## Task Goal

Connect direct Julia fixed-effect marker-scan plot data to already-validated
marker-map metadata while preserving the boundary: no R code edits, no public
`marker_scan()` formula activation, no marker-file parser, no plotting backend,
and no mixed-model GWAS/QTL claim.

## Active Lenses And Spawned Agents

- Florence: plot-data ergonomics and scan/map ordering.
- Shannon: R/Julia boundary and bridge non-change.
- Rose: claim-vs-evidence audit.
- Curie: deterministic tests and edge cases.
- Grace: low-core local checks.
- Spawned agents: none.

## Files Changed

- `src/genomic.jl`
- `src/validation_status.jl`
- `test/runtests.jl`
- `README.md`
- `ROADMAP.md`
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
- this report

## What Landed

`marker_manhattan_data()` now has direct Julia overloads for:

- `marker_manhattan_data(scan, marker_spec::HSMarkerMapSpec; ...)`
- `marker_manhattan_data(scan, data::HSData; ...)`

The scan marker IDs must be unique and must match marker-map IDs exactly. The
returned arrays stay aligned to scan marker order, while chromosome display
order follows the validated marker-map order. This lets a scan over genotype
columns such as `["m1", "m2"]` use a map stored as `["m2", "m1"]` without
silently assigning the wrong chromosome or position metadata.

## Public Claim Audit

Allowed:

- direct Julia fixed-effect scan output can be paired with already-validated
  `HSMarkerMapSpec` / `HSData` marker metadata for Manhattan plot data;
- the helper remains experimental and under `V5-MARKER-FIXED`.

Blocked:

- no marker-file parser;
- no actual plotting backend;
- no mixed-model GWAS/QTL/eQTL claim;
- no relatedness or population-structure correction;
- no LOCO path;
- no interval-mapping or mixed-model LOD workflow;
- no calibrated mixed-model p-values;
- no correlated-marker or genome-wide calibration claim;
- no external comparator parity;
- no R `marker_scan()` formula activation;
- no bridge payload or `result_payload()` change.

## Checks

- `git diff --check`: passed before final checks.
- Initial throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed after implementation and before final ledger/docs edits.
  - Phase 5 fixed-effect single-marker scan testset is now 72 checks.
- Final throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed after ledger/docs sync.
  - Phase 0 scaffold/validation-status block is now 195 checks.
  - Phase 5 fixed-effect single-marker scan testset is now 72 checks.
  - Phase 4B structured covariance remains 61 checks.
- Final throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`: passed.
  - Known local caveats remained: 8 docstrings not included in the manual;
    local deployment skipped, VitePress default substitutions, missing local
    logo/favicon/package.json substitutions, and 4 npm audit advisories in
    generated docs dependencies.

## Tests Of The Tests

The new tests fail loudly for the main risk cases:

- marker map stored in a different order from scan marker IDs;
- `HSData` with no marker metadata;
- duplicate scan marker IDs when matching a marker map;
- scan marker IDs missing from the map, or map IDs missing from the scan.

## Coordination Notes

The R repository was not edited. No R bridge or syntax action is requested from
this slice. A coordination comment should be posted after the PR and remote
checks are green.

## What Did Not Go Smoothly

No implementation failure so far. The main design choice was ordering:
scan-order arrays are preserved for field alignment, but chromosome display
order comes from the marker map because that is the genome-order metadata
source.

## Known Limitations

The helper consumes validated in-memory marker metadata only. It does not read
PLINK/BIM/VCF files, infer marker positions, sort chromosome labels
biologically, draw Manhattan plots, run a mixed model, or calibrate association
statistics.

## Next Actions

- Run final low-core package tests and docs build after this report lands.
- Push a stacked draft PR on top of `codex/phase5-marker-plot-data`.
- Coordinate Julia issue #7 and R issue #9 once remote checks are green.

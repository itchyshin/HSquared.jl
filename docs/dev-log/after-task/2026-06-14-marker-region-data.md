# Marker Regional Data Helper

## Task Goal

Add a deterministic direct-Julia helper for extracting one-chromosome or
coordinate-window regional marker-scan data from already-computed scan results
and marker metadata.

## Active Lenses And Spawned Agents

- Fisher: regional-data boundary versus GWAS/QTL/fine-mapping claims.
- Pat: ergonomic window arguments and returned fields.
- Curie: deterministic order, flank, p-floor, and malformed-input tests.
- Shannon: R/Julia boundary.
- Grace: low-core local checks and Documenter build.
- Rose: public claim audit.
- Spawned agents: none.

## Files Changed

- `src/HSquared.jl`
- `src/genomic.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `README.md`
- `ROADMAP.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/src/validation-status.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

- Exported `marker_region_data`.
- Added a direct metadata-keyword method:
  `marker_region_data(scan; chromosomes, positions, chromosome, start, stop,
  flank, total_variance, p_floor)`.
- Added `HSMarkerMapSpec` and `HSData` overloads that align chromosome/position
  metadata to scan marker IDs by exact marker ID.
- Reused `marker_scan_table()` validation so regional data carries the same
  checked scan statistics, allele variances, marker-variance contributions,
  optional total-variance proportions, and optional mixed/LOCO fields.
- Returned rows are filtered to the requested chromosome/window, ordered by
  position, and preserve original scan indices.

## Checks

- Initial focused Phase 5 test command failed once because the custom-region
  assertion expected `-log10(1.0)` while the fixture p-value was `0.5`; the
  assertion was corrected.
- Focused rerun passed:
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test(test_args=["Phase 5 fixed-effect single-marker scan"])'`.
  The runner executed the suite; the Phase 5 testset was 353 checks.
- Full test suite passed:
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`.
  Phase 0 was 230 checks, Phase 5 was 353 checks, and Phase 4B remained 61
  checks.
- Documenter build passed:
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`.
  Known local caveats remained: 8 unrelated docstrings not included in the
  manual, local deployment skipped, VitePress default substitutions, missing
  local logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.
- `git diff --check`: passed.
- Remote CI passed for pushed commit `6c92ae6`: CI run `27513014295`
  (<https://github.com/itchyshin/HSquared.jl/actions/runs/27513014295>) and
  Documenter run `27513014305`
  (<https://github.com/itchyshin/HSquared.jl/actions/runs/27513014305>).
  Earlier Documenter run `27512999115` was cancelled by workflow concurrency
  and superseded by the successful Documenter run. Remote runs emitted the
  known non-failing Node.js 20 deprecation annotation for upstream actions
  forced onto Node.js 24.

## Tests Of The Tests

- Deterministic checks cover map-backed region extraction, scan-index
  preservation, window start/stop/flank handling, p-floor display values, and
  exact `HSData` / `HSMarkerMapSpec` metadata alignment.
- Guard checks cover missing metadata, metadata length mismatch, invalid
  chromosome/position values, invalid region bounds, invalid flank, invalid
  p-floor, empty selected regions, and missing marker metadata in `HSData`.

## Public Claim Audit

Allowed:

- `marker_region_data()` prepares deterministic direct-Julia regional data from
  already-computed marker-scan fields and already-supplied marker metadata.

Blocked:

- no R `marker_scan()` formula activation;
- no `gwas_table()`, `qtl_table()`, or `eqtl_table()` activation;
- no `regional_plot()` or fine-mapping activation;
- no calibrated p-values, calibrated PVE/model R², threshold selection, or
  comparator parity;
- no bridge payload or `result_payload()` change.

## Coordination Notes

No R repository code was edited. This is Julia-lane groundwork only. The R lane
should continue treating GWAS/QTL/eQTL output tables, regional plots, and
fine-mapping front ends as reserved/planned until a deliberate bridge/public
surface slice is opened.

## Known Limitations

- Requires already-computed direct scan results.
- Requires chromosome/position metadata; it does not parse marker maps.
- The helper prepares data only; it does not draw figures.
- The p-values remain the scan's approximate supplied-variance Wald values.

## Next Actions

1. Push this as a draft PR stacked on the marker-scan-table helper.
2. Coordinate the no-R-syntax-change boundary on Julia issue #7 and R issue #9.
3. Continue Phase 5 by choosing between threshold/reporting stubs, public-table
   bridge design, or further direct Julia plot-data preparation.

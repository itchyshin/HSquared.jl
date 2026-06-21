# R GWAS Table Sync

## Task Goal

Record the R twin's hsquared PR #82 (`934269a`) scan-result table surface in
Julia-owned status and contract docs, so the twins agree that
`gwas_table(scan)` and `lod_scores(scan)` are banked R views of existing
`hs_gwas` objects while threshold and map-table gates stay open.

## Active Lenses

- Ada + Shannon: cross-lane sequencing and lane boundary.
- Hopper + Boole + Emmy: bridge/result-surface contract wording.
- Jason + Fisher: marker-scan validation and comparator boundary.
- Pat: user-facing status clarity.
- Grace: test/docs reproducibility.
- Rose: claim-vs-evidence boundary.

Spawned agents: none.

## Files Changed

- `src/validation_status.jl`
- `docs/src/validation-status.md`
- `docs/design/03-engine-contract.md`
- `ROADMAP.md`
- `test/runtests.jl`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-r-gwas-table-sync.md`
- `docs/dev-log/after-task/2026-06-21-r-gwas-table-sync.md`

## Checks Run

- `julia --project=. -e 'using Pkg; Pkg.test()'`
  - Passed.
- `julia --project=docs docs/make.jl`
  - Passed; existing local warnings remained (20 docstrings not in the manual,
    local deployment skipped, no optional Vitepress logo/favicon, and npm audit
    warnings in the local docs toolchain).
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-r-gwas-table-sync.md`
  - Passed.
- `git diff --check`
  - Passed.

## Public Claim Audit

Clean with limitations. The sync records that the R package now has
scan-result views for already-computed `hs_gwas` objects. It does not claim
new Julia computation, calibrated thresholds, map joins, formula syntax, or
external scan comparator evidence.

`V5-MARKER-MIXED` remains `partial`. #48 remains the calibrated threshold gate.

## Tests Of The Tests

The validation-status regression now asserts that the `V5-MARKER-MIXED` row
mentions hsquared PR #82 and `gwas_table(scan)`, and that the claim boundary
keeps R scan-result table views as thin views rather than calibrated or
map-annotated workflows.

## Coordination Notes

The closed #45 GitHub issue body was updated with `gh issue edit` after the
GitHub app connector returned a 403 for issue mutation. The new body marks the
Julia post-fit marker-scan payload and the R scan-result table surface as
complete, while leaving formula-level `marker_scan()`, calibrated thresholds,
and map-annotated fit-level tables open.

No `hsquared` files were edited by this Julia slice.

## What Did Not Go Smoothly

The GitHub app integration could read issue metadata but could not update #45;
the local `gh` authenticated path succeeded.

## Known Limitations

- `gwas_table(scan)` and `lod_scores(scan)` are R-side views, not Julia
  behavior changes.
- No calibrated genome-wide significance threshold is activated.
- No map-annotated `gwas_table(fit)` / `qtl_table(fit)` / `eqtl_table(fit)`
  workflow is claimed.
- No external PLINK/GenABEL/qvalue-style scan comparator has been run.

## Next Actions

- Let the R lane continue its comparator-manifest / genomic-target availability
  slice from clean `hsquared` main.
- On the Julia side, the next evidence-producing slice remains #49 external
  comparator execution when an executable-backed same-estimand environment is
  available, or #48 threshold payload/calibration evidence without promotion.

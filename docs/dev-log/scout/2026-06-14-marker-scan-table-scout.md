# Marker-Scan Table Scout

## Question

Should the direct Julia marker-scan utilities expose a row-aligned scan table
before the R-facing `marker_scan()` / `qtl_table()` / `gwas_table()` /
`eqtl_table()` surfaces exist?

## Sources Checked

- R twin `hsquared`: `marker_effects()` and `marker_variance_explained()` are
  live only for the opt-in SNP-BLUP path, while `qtl_table()`, `gwas_table()`,
  `eqtl_table()`, and scan plots remain reserved output vocabulary.
- R twin `docs/design/15-qtl-extension-boundary.md`: keeps core extractor
  vocabulary separate from future optional QTL/GWAS/eQTL scan infrastructure.
- Local sister projects `DRM.jl`, `GLLVM.jl`, `drmTMB`, and `gllvmTMB`: no
  directly reusable marker-scan table helper was found; the transferable lesson
  is status discipline, compact result helpers, and a hard split between live,
  partial, and planned claims.
- Project scout map `quantgen-scout/references/packages.md`: JWAS, sommer,
  BLUPF90, AGHmatrix, and related tools remain future comparator references,
  not evidence for this table-preparation helper.
- Local checkout search found `gllvmTMB` variants, but no `PMTMB`, `TMBGLL`, or
  `GLLMTMB` checkout under `/Users/z3437171/Dropbox/Github Local` during this
  pass.

## Relevant Lesson

The existing direct Julia scan results already contain the row-level quantities
users will need for downstream summaries: effects, standard errors, Wald
statistics, p-values, adjusted p-values, LOD-equivalent scores, denominators,
allele frequencies, and marker IDs. A table helper should therefore preserve
the scan order and expose those fields consistently; it should not sort,
threshold, plot, calibrate p-values, estimate variance components, or imply a
public GWAS/QTL/eQTL workflow.

## HSquared.jl Action

Add `marker_scan_table(scan; total_variance = nothing)` with overloads for
validated `HSMarkerMapSpec` and `HSData` marker metadata. The helper preserves
original scan order, adds `scan_indices`, allele variances, marker-variance
contributions, optional total-variance proportions, optional mixed/LOCO fields
when present, and exact marker-map chromosome/position alignment.

## Claim Risk

Allowed: deterministic row-aligned table preparation over already-computed
direct Julia marker-scan fields.

Blocked: `gwas_table()` / `qtl_table()` / `eqtl_table()` activation, R
`marker_scan()` syntax, plotting, fine-mapping, interval mapping, p-value
calibration, calibrated PVE/model R2, marker-scan variance-component
estimation, bridge payload changes, and comparator parity.

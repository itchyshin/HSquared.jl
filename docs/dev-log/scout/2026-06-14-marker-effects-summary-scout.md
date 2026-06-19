# Scout: Marker-Effects Summary Helper

## Question

Should the direct Julia marker-scan utilities expose a compact marker-effect
summary before adding formula-driven GWAS/QTL workflows?

## Sources Checked

- R twin `hsquared/R/extractors.R`: `marker_effects()` is already the
  R-facing extractor name for opt-in SNP-BLUP marker effects.
- R twin `hsquared/docs/design/15-qtl-extension-boundary.md`: keeps
  `marker_effects()` and `marker_variance_explained()` in core output
  vocabulary while leaving QTL/GWAS/eQTL scan infrastructure to later core or
  extension work.
- Local sister search across `DRM.jl`, `GLLVM.jl`, `drmTMB`, and `gllvmTMB`:
  no closer marker-scan table helper was found; useful transferable pattern is
  the fitted/planned separation and extractor naming discipline.
- Local project map `quantgen-scout/references/packages.md`: JWAS, sommer,
  BLUPF90, and related tools remain future comparator references, not evidence
  for this table-formatting helper.
- Local package search found no `PMTMB`, `TMBGLL`, or `GLLMTMB` checkout under
  `/Users/z3437171/Dropbox/Github Local` during this pass.

## Relevant Lesson

The direct Julia scan helpers already return marker effects, standard errors,
Wald summaries, p-values, adjusted p-values, LOD-equivalent scores, and marker
IDs. A small `marker_effects()` helper should therefore be an extractor-like
summary over existing fields, not a new statistical procedure.

Naming it `marker_effects()` keeps the Julia engine vocabulary aligned with the
R-facing output contract. The helper should validate scan-like fields, sort or
subset them deterministically, optionally align validated marker-map metadata,
and keep `target` provenance.

## HSquared.jl Action

Add `marker_effects(scan; sort_by = :p_value, top_n = nothing)` with overloads
for validated `HSMarkerMapSpec` and `HSData` marker metadata. Keep it direct
Julia only and compatible with fixed, supplied mixed-model, and supplied LOCO
scan outputs.

## Claim Risk

Allowed: deterministic marker-effect summary over already-computed direct scan
statistics.

Blocked: GWAS/QTL/eQTL fitting, p-value calibration, threshold selection,
fine-mapping, plotting, R `marker_scan()` syntax activation, bridge payload
changes, and comparator parity.

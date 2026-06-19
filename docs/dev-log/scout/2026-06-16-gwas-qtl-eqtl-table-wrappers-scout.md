# GWAS/QTL/eQTL Table Wrapper Scout

Date: 2026-06-16

Active lenses: Jason, Fisher, Pat, Rose.
Spawned subagents: none.

## Question

How should `HSquared.jl` expose early `gwas_table()`, `qtl_table()`, and
`eqtl_table()` outputs without overstating the current Phase 5 marker-scan
engine?

## Sources Checked

- Local `HSquared.jl` direct marker helpers:
  `single_marker_scan`, `mixed_model_marker_scan`,
  `loco_relationship_precisions`, `loco_mixed_model_marker_scan`,
  `marker_scan_table`, `marker_effects`, `marker_variance_explained`,
  `marker_manhattan_data`, `marker_region_data`, `marker_qq_data`,
  `marker_significance_summary`, and `marker_genomic_inflation`.
- Local sister packages:
  - `gllvmTMB/R/predictive-diagnostics.R`
  - `gllvmTMB/R/diagnostic-tables.R`
  - `GLLVM.jl/src/phylo_branch_re.jl`
  - `drmTMB`, `DRM.jl` quick search for marker/GWAS table helpers
- Project scout map at `.agents/skills/quantgen-scout/references/packages.md`.

## Lessons

- No local sister package has a GWAS/QTL/eQTL table helper to copy directly.
- The useful reusable pattern is diagnostic discipline: return explicit data
  objects with provenance fields, keep plotting and interpretation separate,
  and block calibrated-threshold wording until validation exists.
- `marker_scan_table()` already has the row-aligned data needed for first
  table outputs. The safest next layer is semantic labelling, not a new scan
  engine.

## Action For HSquared.jl

- Add `gwas_table()`, `qtl_table()`, and `eqtl_table()` as thin wrappers over
  existing direct marker-scan table data.
- Preserve existing scan fields and marker-map alignment.
- Add only `analysis = :gwas | :qtl | :eqtl` plus optional trait or
  expression-feature metadata.
- Keep these functions direct-Julia utilities only.

## Claim Risk

High-risk wording to avoid:

- "runs GWAS"
- "detects QTL"
- "eQTL workflow"
- "calibrated genome-wide threshold"
- "fine mapping"
- "expression-wide scan"
- "R `marker_scan()` support"

Allowed wording:

- "labels already-computed direct marker-scan tables as GWAS/QTL/eQTL output"
- "semantic wrappers over `marker_scan_table()`"
- "direct Julia table-preparation utilities"

# HSData Marker Metadata Validation

Date: 2026-06-13

Active lenses: Ada, Shannon, Emmy, Jason, Pat, Rose, Grace.

Spawned subagents: none.

## Goal

Align Julia `HSData` metadata validation with the R twin's marker-map and
genotype-marker alignment checks while keeping the bridge payload and modelling
surface unchanged.

## R Handoffs

R commits:

- `5923fcd Validate hs_data marker maps`;
- `d1eb174 Validate genotype marker alignment`;
- `b1a4e48 Summarize hs_data marker status`.

Reported R evidence:

- R-CMD-check `27460445869`: success;
- pkgdown `27460445866`: success;
- Pages `27460479795`: success;
- R-CMD-check `27460602501`: success;
- pkgdown `27460602502`: success;
- Pages `27460635647`: success;
- R-CMD-check `27460847536`: success;
- pkgdown `27460847546`: success;
- Pages `27460886355`: success.

R behavior:

- `hs_data(markers = ...)` validates marker ID, chromosome, and finite
  non-negative numeric position columns using common aliases;
- when `genotypes` and `markers` are both supplied, genotype marker columns
  must match marker-map IDs exactly;
- order may differ;
- missing or extra marker IDs error;
- `summary(hs_data(...))` now reports marker-status diagnostics on the R side;
- this is metadata validation and R-only diagnostic reporting.

## Julia Implementation

Added internal:

- `HSMarkerMapSpec`;
- `HSGenotypeMarkerSpec`.

`HSData` now validates:

- marker-map aliases for marker ID, chromosome, and position;
- unique, non-missing marker IDs;
- non-missing chromosomes;
- finite non-negative marker positions;
- explicit `genotype_marker_ids` for matrix-like genotype inputs when markers
  are supplied;
- genotype marker names matching marker-map IDs exactly, with order recorded
  through `marker_map_index`.

## Files Changed

- `src/data.jl`;
- `test/runtests.jl`;
- `README.md`;
- `ROADMAP.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/09-hsdata-contract.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/src/api.md`;
- `docs/src/changelog.md`;
- `docs/src/data.md`;
- `docs/src/roadmap.md`.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 324 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: returned no matches.
- Claim scan: found only expected guardrail and roadmap wording around
  metadata validation, file formats, and planned genotype/genomic/QTL work.

Remote checks: pending.

## Public Claim Audit

Allowed wording:

- `HSData` validates marker-map metadata;
- `HSData` validates genotype-marker alignment against marker maps;
- this mirrors R-side metadata hygiene from `hs_data()`.

Blocked wording:

- genotype parsing is implemented;
- PLINK/VCF ingestion is implemented;
- imputation is implemented;
- marker scanning, genomic fitting, QTL/eQTL fitting, or relationship
  construction from genotypes is implemented;
- bridge payload shape changed.

Rose verdict: locally clean with limitations; pending remote CI and deployed
docs evidence.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- The R summary-diagnostic handoff after `d1eb174` is R-only and does not
  require Julia changes.
- The R marker-status summary handoff at `b1a4e48` is also R-only and does not
  require Julia changes in this slice.

## Next Actions

1. Run Documenter and mechanical checks.
2. Push and watch CI.
3. Record remote evidence.

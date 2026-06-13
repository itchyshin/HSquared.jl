# HSData Genotype Diagnostics

Date: 2026-06-13

Active lenses: Ada, Emmy, Jason, Pat, Hopper, Karpinski, Rose, Grace.

Spawned subagents: none.

## Scope

Mirror the R twin's `hs_data()` genotype-status diagnostics in Julia `HSData`.

This is metadata diagnostics only. It does not add genomic fitting, marker
scans, QTL/GWAS/eQTL models, automatic genotype-to-relationship construction,
GLLVM workflows, GPU workflows, bridge payload changes, or file-backed
genotype storage.

## R Handoff

R repo `itchyshin/hsquared` reported:

- implementation commit `fd0cbd9`;
- evidence commit `f067cd9`;
- issue update:
  <https://github.com/itchyshin/hsquared/issues/8#issuecomment-4698325286>.

R diagnostics report:

- genotype rows;
- genotype IDs;
- genotype marker-column count;
- named genotype marker-column count;
- unnamed genotype marker-column count;
- duplicate named genotype marker-column count;
- missing genotype value count;
- genotype component type.

## Implementation

Added:

- `HSDataGenotypeStatusRow`;
- `genotype_status` on `HSDataStatus`;
- genotype-status diagnostics for table-like genotype components;
- genotype-status diagnostics for matrix-like genotype components;
- stored `genotype_id` in `HSData` so table-like marker columns can be counted
  after excluding the ID column;
- missing-genotype-value counting for in-memory matrix and table-like genotype
  inputs.

Plain Julia matrices are reported as matrix components with unnamed marker
columns because base matrices do not carry marker names.

## Files Updated

- `src/HSquared.jl`
- `src/data.jl`
- `test/runtests.jl`
- `README.md`
- `ROADMAP.md`
- `docs/src/api.md`
- `docs/src/data.md`
- `docs/src/index.md`
- `docs/src/roadmap.md`
- `docs/src/changelog.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/09-hsdata-contract.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`

## Validation

Local checks:

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 453 checks; the Phase 1 HSData ID container testset has 113 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: returned no matches.
- Claim-boundary scan: found only expected guardrail and blocked-wording hits
  around genotype parsing, genotype-to-relationship construction, marker
  scans, genomic fitting, QTL/GWAS/eQTL, GLLVM workflows, GPU workflows, and
  existing backend speed-claim guardrails.

## Public Claim Audit

Allowed wording:

- `data_status(::HSData)` reports genotype rows, genotype IDs, marker-column
  counts, named/unnamed marker-column counts, duplicate named marker-column
  counts, missing genotype value counts, and component type for in-memory
  genotype components.

Blocked wording:

- PLINK/VCF or dosage files are parsed;
- genotypes are imputed;
- genomic relationship matrices are constructed from genotypes;
- marker scans, QTL, GWAS, or eQTL models are fitted;
- GLLVM or GPU workflows are implemented;
- bridge payloads consume genotype components.

## Known Limitations

- Matrix-like genotype inputs need explicit `genotype_ids` for ID matching.
- Base Julia matrices are reported with unnamed marker columns.
- Dictionary-like inputs do not have a reliable row count in this diagnostic
  surface and report `not_available` for genotype rows.
- File-backed arrays, sparse genotype matrices, PLINK/VCF, dosage, HDF5, Zarr,
  and chunked/streamed genotype storage remain planned.
- Marker-map alignment remains under `genotype_marker_ids` plus `markers`.

## Next Actions

1. Commit and push the implementation.
2. Watch CI, Documenter, and Pages.
3. Update the issue ledger.

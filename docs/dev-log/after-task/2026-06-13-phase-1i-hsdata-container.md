# Phase 1I HSData Input Container

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Emmy, Jason, Karpinski, Grace, Rose.

Spawned subagents: none.

## Scope

Mirror the R `hs_data()` input-container contract in Julia after the R twin
reported `hsquared` commit `644c75e`.

This slice is a data-contract slice only. It is not file-backed storage,
relationship construction, QTL/eQTL support, or model fitting.

## Implementation

Added:

- `HSData`
- `HSDataIDMap`
- `id_map(data)`

The ID map records:

- `phenotype_ids`
- `pedigree_ids`
- `genotype_ids`
- `expression_ids`
- `phenotypes_without_pedigree`
- `phenotypes_without_genotypes`
- `phenotypes_without_expression`
- `genotypes_without_phenotypes`
- `expression_without_phenotypes`

Matching is exact. The Julia mirror deliberately does not coerce `1` to `"1"`
or otherwise rewrite IDs across sources.

## Tests

Added tests for:

- repeated phenotype IDs;
- normalized `Pedigree` inputs;
- raw table-like pedigree IDs;
- matrix genotype inputs with explicit row IDs;
- expression ID columns;
- phenotype, genotype, and expression mismatch fields;
- missing phenotype IDs;
- pedigree missing phenotyped IDs;
- matrix genotypes without explicit IDs;
- genotype ID length mismatches;
- duplicate genotype IDs;
- missing phenotype ID column.

Local checks:

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 140 checks.
- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only blocked-wording/audit rows, not public claims that
  file-backed storage, QTL/eQTL, genomic relationship construction, live
  R-to-Julia marshalling, sparse production fitting, AI-REML, or GPU support
  are implemented.

## Documentation

Added:

- `docs/src/data.md`
- `docs/design/09-hsdata-contract.md`

Updated:

- README
- ROADMAP
- engine contract
- v0.1 contract
- capability status
- validation debt
- coordination board
- API reference
- changelog

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- Julia has an in-memory `HSData` container aligned to the R `hs_data()`
  ID-map vocabulary.

Blocked wording:

- file-backed storage is implemented;
- genomic relationship construction is implemented;
- QTL/eQTL/GWAS support is implemented;
- live R-to-Julia data-container marshalling works;
- `HSData` can fit models.

## Next Work

1. Add live R-to-Julia marshalling for `hs_data()` to `HSData`.
2. Add file-backed storage design before implementing large genotype formats.
3. Keep `HSData` separate from modelling claims until it feeds an engine spec
   through tested bridge code.

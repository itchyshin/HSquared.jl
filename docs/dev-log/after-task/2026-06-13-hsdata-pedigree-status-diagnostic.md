# HSData Pedigree Status Diagnostic

Date: 2026-06-13

Active lenses: Ada, Shannon, Emmy, Hopper, Henderson, Karpinski, Pat, Rose,
Grace.

Spawned subagents: none.

## Goal

Mirror the R twin's pedigree-status diagnostics in Julia for `HSData` objects
while keeping bridge payloads, relationship construction, and model fitting
unchanged.

## R Handoff

R commit:

- `3fafa08 Summarize hs_data pedigree status`.

Reported R evidence:

- focused hs-data tests: 55 pass;
- full tests: 263 pass;
- `pkgdown::check_pkgdown()`: no problems;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- R-CMD-check `27461235870`: success;
- pkgdown `27461235877`: success;
- Pages `27461267695`: success.

R behavior:

- `summary(hs_data(...))` includes a `pedigree_status` table when pedigree data
  are supplied;
- `data_status()` carries the same pedigree diagnostics;
- diagnostics report rows, unique IDs, phenotype coverage, founders,
  nonfounders, parent-link counts, missing known parent IDs, duplicate
  pedigree IDs, self-parent rows, and same-known-parent rows.

## Julia Implementation

Added:

- `HSDataPedigreeStatusRow`;
- `pedigree_status` field on `HSDataStatus`;
- pedigree-status rows from `data_status(::HSData)`.

`data_status()` now reports:

- `pedigree_rows`;
- `pedigree_ids`;
- `phenotype_ids_with_pedigree`;
- `pedigree_only_ids`;
- `founders`;
- `nonfounders`;
- `known_sire_links`;
- `known_dam_links`;
- `missing_known_parent_ids`;
- `duplicate_pedigree_ids`;
- `self_parent_rows`;
- `same_known_parent_rows`.

For normalized `Pedigree` inputs, rejected conditions such as duplicate IDs,
missing known parents, self-parent rows, and same-known-parent rows report as
zero because the object cannot contain them. For raw table-like pedigree
inputs, duplicate IDs are allowed so the diagnostic can report them before
engine normalization.

## Files Changed

- `src/HSquared.jl`;
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
  to 351 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: returned no matches.
- Claim scan: found only expected guardrail and blocked-wording hits around
  diagnostics, bridge payloads, raw-pedigree Ainv construction, relationship
  construction, fitted animal-model support, genomic fitting, marker scanning,
  and QTL/eQTL fitting.

## Public Claim Audit

Allowed wording:

- `data_status(::HSData)` reports pedigree diagnostics;
- raw pedigree tables can be inspected for duplicate IDs, missing known
  parents, self-parent rows, and same-known-parent rows;
- normalized `Pedigree` remains the validated engine representation.

Blocked wording:

- bridge payload shape changed;
- raw `HSData` pedigree tables are normalized for engine use;
- `Ainv` construction from `HSData` is implemented;
- relationship construction, genotype parsing, marker scanning, genomic
  fitting, QTL/eQTL fitting, or general animal-model fitting is implemented.

Rose verdict: clean with limitations. This is a diagnostic parity slice only.
It does not widen the bridge or promote fitted-model capability.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- The R twin is separately working on formula ergonomics for
  `animal(1 | id)` resolving pedigree from `data = hs_data(...)`; this Julia
  slice does not require an engine API change.

## Next Actions

1. Commit and push the diagnostic slice.
2. Watch CI and Documenter, then record remote evidence.

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

Remote checks for implementation commit `41470ea`:

- CI `27461589231`: success.
- Documenter `27461589180`: success.
- Pages deploy `27461624269`: success.
- Live data page `https://itchyshin.github.io/HSquared.jl/dev/data`: HTTP 200
  and contains `pedigree_status`, `duplicate IDs`, and `normalize_pedigree`.
- Live API page `https://itchyshin.github.io/HSquared.jl/dev/api`: HTTP 200
  and contains `HSDataPedigreeStatusRow` and `data_status`.
- Live roadmap page `https://itchyshin.github.io/HSquared.jl/dev/roadmap`:
  HTTP 200 and contains `pedigree status` and `marker-alignment status`.

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
- The R twin separately landed formula ergonomics in `hsquared` heads
  `74eef82` and `39ca990`: `animal(1 | id)` can resolve pedigree from
  `data = hs_data(..., pedigree = ped)`.
- Julia docs record this as R parser/data-container ergonomics only. The
  explicit `animal(1 | id, pedigree = ped)` spelling remains the shared
  portable contract, and this does not require a Julia engine API or bridge
  payload change.
- After recording that handoff, `Pkg.test()`, Documenter, `git diff --check`,
  additions-only ASCII scan, and shorthand/claim scan were rerun locally and
  passed.

## Next Actions

1. Commit and push the remote-evidence plus formula-ergonomics coordination
   note.
2. Watch CI, Documenter, and Pages for the evidence commit.

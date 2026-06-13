# HSData Data Status Diagnostic

Date: 2026-06-13

Active lenses: Ada, Shannon, Emmy, Jason, Pat, Rose, Grace.

Spawned subagents: none.

## Goal

Mirror the R twin's `data_status()` diagnostics in Julia for `HSData` objects
while keeping the bridge payload and modelling surface unchanged.

## R Handoff

R commit:

- `1fe0f4c Add data_status diagnostics`.

Reported R evidence:

- focused hs-data tests: 46 pass;
- full tests: 254 pass;
- `pkgdown::check_pkgdown()`: no problems;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- R-CMD-check `27461011499`: success;
- pkgdown `27461011484`: success;
- Pages `27461044101`: success.

R behavior:

- exported `data_status()` for `hs_data()` objects;
- reports component presence;
- reports ID-overlap diagnostics;
- reports marker-map/genotype-marker alignment status;
- diagnostics only, no bridge payload change.

## Julia Implementation

Added:

- `HSDataIDOverlapRow`;
- `HSDataMarkerStatusRow`;
- `HSDataStatus`;
- `data_status(::HSData)`.

`data_status()` reports:

- component names present in the `HSData` object;
- ID-overlap counts for phenotype, pedigree, genotype, and expression IDs;
- marker-map marker count;
- genotype marker-column count;
- aligned marker-column count;
- chromosome count;
- marker position range;
- alignment status.

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
  to 334 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: returned no matches.
- Claim scan: found only expected guardrail and blocked-wording hits around
  diagnostics, bridge payloads, genotype parsing, relationship construction,
  marker scanning, genomic fitting, and QTL/eQTL fitting.

Remote checks: pending.

## Public Claim Audit

Allowed wording:

- `data_status()` reports `HSData` diagnostics;
- component presence, ID-overlap counts, and marker-alignment status are
  covered;
- this mirrors R-side diagnostics.

Blocked wording:

- bridge payload shape changed;
- genotype parsing is implemented;
- relationship construction from genotypes is implemented;
- marker scanning, genomic fitting, or QTL/eQTL fitting is implemented.

Rose verdict: locally clean with limitations; pending remote CI and deployed
docs evidence.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- R `summary(hs_data(...))` marker-status diagnostics and `data_status()` are
  R-side surfaces; Julia now mirrors `data_status(::HSData)` only.

## Next Actions

1. Run Documenter and mechanical checks.
2. Push and watch CI.
3. Record remote evidence.

# R hs_data Parser Integration Sync

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Emmy, Rose, Grace, Pat.

Spawned subagents: none.

## Goal

Mirror the R twin's `hs_data()` parser integration in Julia docs and design
memory without changing Julia code, bridge payload fields, or public fitting
claims.

## R Handoff

R commit:

- `36efbf3 Connect hs_data to parser`.

Reported R evidence:

- R-CMD-check `27460091544`: success;
- pkgdown `27460091551`: success;
- Pages `27460131691`: success.

R behavior:

- `model_spec()` and `hsquared()` can accept an `hs_data()` object as `data`;
- model variables are read from `data$phenotypes`;
- formula components such as `pedigree = pedigree` are resolved from the
  `hs_data()` bundle;
- bridge payload shape is unchanged: `y`, `X`, sparse `Z`, normalized
  pedigree/ID metadata, method, family, and Julia target metadata.

## Julia Action

Updated:

- `docs/design/01-v0.1-contract.md`;
- `docs/design/03-engine-contract.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/09-hsdata-contract.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/src/data.md`;
- `docs/src/roadmap.md`;
- `docs/src/changelog.md`;
- `ROADMAP.md`;
- `README.md`.

No Julia code changed.

## Checks

- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum to
  294 checks.
- `git diff --check`: passed.
- Edited-file ASCII scan: no matches.
- Claim scan: clean with limitations. Hits were expected guardrail wording
  around no file-backed storage, no genotype/omics automatic model
  construction, no production bridge hardening, no general fitting, and no
  live Julia `HSData` object marshalling.

Remote checks: pending.

## Public Claim Audit

Allowed wording:

- R `hs_data()` can feed the v0.1 R parser.
- R can read model variables from `data$phenotypes` and resolve `pedigree`
  from the bundle.
- The bridge payload shape is unchanged.
- Julia `HSData` remains the in-memory mirror and live object marshalling is
  planned.

Blocked wording:

- file-backed storage is implemented;
- genotype or omics fields automatically construct model terms;
- the production bridge is hardened;
- general fitting is available through `hs_data()`;
- Julia receives or fits a live `HSData` object.

Rose verdict: clean with limitations after local checks; remote evidence
pending. Claim scope is documentation-only and guarded.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- This mirrors R head `36efbf3`.
- The next data-container bridge change should decide explicitly whether Julia
  receives low-level payloads only or a live `HSData` object.

## Known Limitations

- Documentation/status only.
- No Julia API change.
- No new numerical validation.

## Next Actions

1. Run local docs/test checks.
2. Push and watch CI.
3. Record remote evidence.

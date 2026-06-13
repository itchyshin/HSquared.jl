# Validation Status Diagnostic

Date: 2026-06-13

Active lenses: Ada, Shannon, Henderson, Mrode, Fisher, Curie, Rose, Grace.

Spawned subagents: none.

## Goal

Add a Julia-side validation evidence diagnostic that makes the current
validation ladder queryable while preserving claim boundaries.

## Implementation

Added:

- `ValidationStatusRow`;
- `ValidationStatus`;
- `validation_status()`;
- Documenter page `docs/src/validation-status.md`;
- API docs entries.

The diagnostic records covered, external, partial, and planned validation rows.
It does not run comparator packages, fit models, or promote any planned
capability.

## Validation Rows

The first table includes:

- package loading;
- pedigree normalization;
- tiny sparse `Ainv` checks;
- external R-side `nadiv::Mrode9` / `nadiv::makeAinv()` pedigree inverse
  comparator evidence;
- Gaussian likelihood tiny checks;
- sparse REML identity;
- Henderson MME supplied-variance solve;
- dense output extractors;
- missing fitted Mrode animal-model outputs;
- missing external fitted-model comparators;
- missing genomic/QTL/eQTL validation.

## Files Changed

- `src/HSquared.jl`;
- `src/validation_status.jl`;
- `test/runtests.jl`;
- `README.md`;
- `ROADMAP.md`;
- `docs/design/04-validation-canon.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`;
- `docs/make.jl`;
- `docs/src/api.md`;
- `docs/src/changelog.md`;
- `docs/src/index.md`;
- `docs/src/roadmap.md`;
- `docs/src/validation-status.md`.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum
  to 307 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `git diff --check`: passed.
- Additions-only ASCII scan: no matches. Full edited-file scan sees
  pre-existing approximate-equality test operators in `test/runtests.jl`, not
  new text.
- Smoke check:

```text
11
V1-AINV-MRODE9
covered_external
V1-MRODE-FIT
Fitted Mrode validation is not covered.
```

- Claim scan: clean with limitations. Hits were expected status, planned, and
  blocked wording, not claims that `validation_status()` runs comparators, fits
  models, covers fitted Mrode outputs, or adds genomic/QTL support.

Remote checks: pending.

## Public Claim Audit

Allowed wording:

- `validation_status()` reports the validation evidence ladder;
- Mrode9/nadiv is external pedigree inverse evidence;
- fitted Mrode outputs remain planned;
- external fitted-model comparator parity remains planned.

Blocked wording:

- `validation_status()` runs comparator packages;
- fitted Mrode validation is covered;
- ASReml/BLUPF90/DMU/WOMBAT/sommer/MCMCglmm fitted parity exists;
- production sparse fitting is validated;
- genomic, marker, QTL, or eQTL support is implemented.

Rose verdict: clean with limitations after local checks; remote evidence
pending.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- The R-only `hs_data()` summary and marker-map validation handoffs require no
  Julia action because they do not change the bridge payload.

## Next Actions

1. Push and watch CI.
2. Record remote evidence.
3. Use this diagnostic to keep issue #7 focused on fitted Mrode output
   validation rather than pedigree-Ainv evidence alone.

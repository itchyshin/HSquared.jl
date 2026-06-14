# Validation-status docs sync

Active lenses: Grace/Rose. Spawned subagents: none.

## Goal

Bring `docs/src/validation-status.md` back into alignment with the current
`validation_status()` rows after the Phase 2-4 evidence ladder expanded.

## Files Changed

- `docs/src/validation-status.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

The static "Current Rows" table now includes the current Phase 2, Phase 3,
Phase 4, and Phase 4B rows, including:

- genomic relationship / GBLUP / SNP-BLUP / single-step rows;
- repeatability and two-effect rows;
- multivariate supplied-covariance and REML rows;
- structured multivariate covariance (`V4-FA`).

The boundary text now explicitly says that Phase 4 multivariate evidence is
Julia-engine evidence only: opt-in recovery and a target fixture exist, but no
sommer/ASReml/JWAS/BLUPF90 multi-trait comparator parity is claimed.

## Public Claim Audit

Allowed:

- the validation-status documentation reflects the current validation ladder;
- Phase 4 rows list their current internal evidence and limitations.

Blocked / not claimed:

- no new computational capability;
- no external multi-trait comparator parity;
- no R-facing multivariate syntax;
- no bridge payload change;
- no production sparse multivariate fitting.

## Checks

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
- `git diff --check`: passed.

Docs build caveats are unchanged from earlier slices: 8 unrelated docstrings are
not included in the manual, local deployment is skipped outside CI,
logo/favicon/package.json substitutions are absent, and VitePress reports 4 npm
audit advisories in generated docs dependencies.

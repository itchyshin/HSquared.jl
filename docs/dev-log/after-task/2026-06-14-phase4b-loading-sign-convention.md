# Phase 4B: loading sign convention for structured covariance

Active lenses: Kirkpatrick/Noether, Gauss/Fisher, Hopper, Rose. Spawned
subagents: none.

## Goal

Make returned loading metadata deterministic for Phase-4B `:lowrank` and
`:factor_analytic` fits without changing fitted covariances, widening the bridge
contract, or claiming factor rotations are identified.

## Files Changed

- `src/multivariate.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `ROADMAP.md`
- `docs/design/03-engine-contract.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- this report

## What Landed

`fit_multivariate_reml(...; genetic_structure = :lowrank | :factor_analytic)`
now returns sign-canonicalized `genetic_loadings`. For each factor column, the
largest-absolute loading is non-negative.

This is metadata canonicalization only. Because `ΛΛ'` is invariant to factor
sign flips, the fitted `genetic_covariance` is unchanged by the convention.

## Validation

Committed deterministic tests now cover:

- direct canonicalization of two loading columns with negative largest-absolute
  entries;
- no mutation of the input loading matrix;
- covariance invariance under canonicalization;
- empty loading matrices error with `ArgumentError`;
- returned low-rank and factor-analytic loading columns have non-negative
  largest-absolute entries;
- returned structured covariances reconstruct from returned loading metadata.

`V4-FA` remains `partial`.

## Checks

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  Phase-4B structured covariance testset = 41 checks.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
- `git diff --check`: passed.

Docs build caveats are unchanged from earlier Phase-4B slices: 8 unrelated
docstrings are not included in the manual, local deployment is skipped outside
CI, logo/favicon/package.json substitutions are absent, and VitePress reports
4 npm audit advisories in generated docs dependencies.

## Public Claim Audit

Allowed:

- returned `genetic_loadings` for low-rank and factor-analytic fits use a
  deterministic sign convention;
- the sign convention is covered by deterministic tests;
- no covariance estimate changes are implied by the metadata convention.

Blocked / not claimed:

- no R-facing covariance-structure syntax;
- no bridge payload or `result_payload()` change;
- no rotation or lower-triangular identification convention;
- no unique factor interpretation for rank greater than 1;
- no covariance standard errors or likelihood-ratio tests;
- no published multi-trait fixture;
- no multi-seed calibration;
- no sommer/ASReml/BLUPF90 comparator parity;
- no production sparse factor-analytic fitting.

## Coordination Notes

No R repository code was edited. The R twin only needs issue-level awareness:
Julia loading metadata is now sign-canonicalized, but rotation/interpretation
and any future R syntax remain coordinated future work.

## Next Actions

1. Prepare a shared deterministic multi-trait fixture for R-side comparator
   parity.
2. Decide whether a future rotation/lower-triangular convention is required
   before exposing loading extractors publicly.
3. Keep covariance-structure syntax out of the R bridge until the R lane opens
   that contract deliberately.

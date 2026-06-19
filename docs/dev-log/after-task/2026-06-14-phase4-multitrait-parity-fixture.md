# Phase 4: shared multi-trait parity fixture

Active lenses: Shannon/Hopper, Gauss/Fisher, Curie, Rose. Spawned subagents:
none.

## Goal

Serialize a deterministic two-trait animal-model fixture for future R-lane
sommer/ASReml/BLUPF90 parity work, without editing the R repository and without
claiming external comparator evidence.

## Files Changed

- `test/fixtures/phase4_multitrait_parity/README.md`
- `test/fixtures/phase4_multitrait_parity/pedigree.csv`
- `test/fixtures/phase4_multitrait_parity/phenotypes.csv`
- `test/fixtures/phase4_multitrait_parity/expected_genetic_covariance.csv`
- `test/fixtures/phase4_multitrait_parity/expected_residual_covariance.csv`
- `test/fixtures/phase4_multitrait_parity/expected_beta.csv`
- `test/fixtures/phase4_multitrait_parity/expected_heritability.csv`
- `test/fixtures/phase4_multitrait_parity/expected_metadata.csv`
- `test/fixtures/phase4_multitrait_parity/expected_ebv.csv`
- `test/runtests.jl`
- `src/validation_status.jl`
- `ROADMAP.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `docs/src/multivariate-models.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- this report

## What Landed

`test/fixtures/phase4_multitrait_parity/` stores a plain CSV fixture with:

- 20 animals;
- 80 records;
- 2 traits;
- a shared intercept + numeric `x` fixed-effect design;
- pedigree, phenotype, Julia REML target covariance, fixed-effect, EBV, h², and
  log-likelihood files.

The fixture is intended for R-lane comparator work. It is easy to read from R
without Julia-specific serialization.

## Validation

The regular Julia test suite reads the CSV files, rebuilds `Ainv`, `X`, `Z`, and
`Y`, and checks fast self-consistency at the stored Julia target covariances:

- `multivariate_mme` beta equals the serialized target;
- `multivariate_mme` EBVs equal the serialized target;
- h² from stored `G0`/`R0` equals the serialized target;
- `_multivariate_reml_loglik` at stored `G0`/`R0` equals the serialized target;
- genetic and residual correlations equal the serialized metadata.

The test deliberately does not re-run the dense optimizer in CI.

## Checks

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  New testset "Phase 4 shared multi-trait parity fixture" = 13 checks.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
- `git diff --check`: passed.
- Claim scan for accidental external-comparator / production sparse
  multivariate promotion found only explicit negative/boundary statements.

Docs build caveats are unchanged from earlier slices: 8 unrelated docstrings are
not included in the manual, local deployment is skipped outside CI,
logo/favicon/package.json substitutions are absent, and VitePress reports 4 npm
audit advisories in generated docs dependencies.

## Public Claim Audit

Allowed:

- a deterministic two-trait CSV fixture exists for future R-lane comparator
  work;
- Julia target values are serialized and self-consistency-checked in CI;
- the fixture can be used as a sommer/ASReml/BLUPF90 parity input by the R lane.

Blocked / not claimed:

- no sommer/ASReml/BLUPF90 result has been run or matched here;
- no external comparator parity;
- no R-facing multivariate syntax;
- no bridge payload or `result_payload()` change;
- no covariance SEs or likelihood-ratio tests;
- no published Mrode multi-trait estimate;
- no production sparse multivariate fitting.

`V4-MV-REML` remains `partial`.

## Coordination Notes

No R repository code was edited. The R twin should consume this fixture only
through its own comparator work and report results back through GitHub issues.

## Next Actions

1. Ask the R lane to run sommer/ASReml/BLUPF90 comparisons against the fixture.
2. Keep any tolerance claims tied to the R-lane comparator evidence, not to this
   Julia target fixture alone.
3. Continue Phase-4B/Phase-5 work only behind explicit evidence gates.

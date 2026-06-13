# Phase 1N Sparse REML Identity And Mrode9 Ainv Sync

Date: 2026-06-13

Active lenses: Ada, Shannon, Henderson, Gauss, Fisher, Curie, Mrode, Grace,
Rose.

Spawned subagents: none.

## Goal

Add a sparse supplied-variance REML likelihood identity for Julia validation
work and mirror the R twin's optional Mrode9/nadiv pedigree-Ainv comparator
evidence.

## Files Changed

- `src/HSquared.jl`
- `src/likelihood.jl`
- `test/runtests.jl`
- `README.md`
- `ROADMAP.md`
- `docs/design/03-engine-contract.md`
- `docs/design/04-validation-canon.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/index.md`
- `docs/src/pedigree-ainv.md`
- `docs/src/quickstart.md`
- `docs/src/roadmap.md`

## Implementation

Added:

- `sparse_reml_loglik(spec, sigma_a2, sigma_e2)`;
- a shared sparse MME-system builder used by both `henderson_mme()` and the
  sparse REML identity path.

The sparse REML identity evaluates:

```text
log |V| + log |X' V^-1 X| = log |R| + log |G| + log |C|
```

where `C` is the Henderson mixed-model-equation coefficient matrix.

No `fit_animal_model()` dispatch or `result_payload()` field changed.

## Tests

Added tests that:

- compare `sparse_reml_loglik()` with dense `gaussian_loglik(...; method =
  :REML)` on the simple identity-relationship fixture;
- compare `sparse_reml_loglik()` with dense REML on the existing Henderson MME
  validation fixture;
- check non-positive variance errors;
- check saturated REML design errors.

## R Twin Handoff

Verified read-only from the sibling R repo:

- `hsquared` `f0e71c7 Add Mrode9 Ainv comparator`;
- `hsquared` `369d14a Record Mrode9 comparator CI evidence`.

The R fixture uses `nadiv::Mrode9`, documented by `nadiv` as adapted from Mrode
example 9.1. It computes `nadiv::makeAinv()` and compares it with Julia
`normalize_pedigree()` plus `pedigree_inverse()` at tolerance `1e-10`.

## Checks Run

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed with 192 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.

## Public Claim Audit

Allowed wording:

- sparse REML likelihood identity at supplied variance components;
- dense-vs-sparse REML equivalence on tiny fixtures;
- optional R-side Mrode9/nadiv pedigree-Ainv comparator evidence.

Blocked wording:

- sparse production REML/ML fitting is implemented;
- AI-REML is implemented;
- variance components are estimated by the sparse path;
- fitted Mrode animal-model validation is covered;
- Mrode EBVs, h2, or variance-component outputs are validated;
- ASReml, BLUPF90, DMU, or WOMBAT comparison is covered;
- large-pedigree readiness or performance is demonstrated.

## Tests Of The Tests

The sparse REML tests compare against the existing dense evaluator, so they
guard the algebraic identity rather than an independent fitted-model
comparator. The Mrode9/nadiv evidence lives in the R twin because it depends on
the optional R package `nadiv`.

## Known Limitations

- No sparse optimizer yet.
- No AI-REML score/information implementation yet.
- No Julia-native bundled Mrode9 fixture, avoiding copying optional R package
  data into the MIT Julia repo.
- No fitted Mrode animal-model expected outputs yet.

## Next Actions

1. Add a fitted Mrode model fixture with response, fixed effects, estimator
   target, expected variance components, EBVs, and heritability.
2. Use the sparse REML identity as a stepping stone toward a sparse optimizer
   only after fitted-model validation targets are explicit.
3. Keep PEV/reliability payload widening in lockstep with the R twin.

Rose verdict: clean with limitations.

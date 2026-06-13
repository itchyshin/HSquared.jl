# Phase 1M Sparse Henderson MME Supplied-Variance Solve

Date: 2026-06-13

Active lenses: Ada, Henderson, Gauss, Karpinski, Fisher, Mrode, Grace, Rose.

Spawned subagents: none.

## Scope

Add a sparse Henderson mixed-model-equation solve at supplied variance
components, and record the R twin's sparse `Z` bridge marshalling handoff.

## Implementation

Changed:

- `src/HSquared.jl`
- `src/likelihood.jl`
- `test/runtests.jl`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-v0.1-contract.md`
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
- `docs/src/quickstart.md`
- `docs/src/roadmap.md`

Added:

- `HendersonMMEResult`;
- `henderson_mme(spec, sigma_a2, sigma_e2)`;
- `fixed_effects(result::HendersonMMEResult)`;
- `breeding_values(result::HendersonMMEResult)`;
- `fitted_values(result::HendersonMMEResult)`.

The solver builds Henderson's equation system from sparse `X`, sparse `Z`, and
sparse `Ainv`, then solves for fixed effects and animal effects at supplied
positive variance components.

## R Handoff

The R twin reports:

- `hsquared` commit `2a9ba37`: sparse `Z` bridge marshalling is consumed;
- `hsquared` commit `398e019`: sparse bridge CI evidence recorded;
- R now sends `Matrix::dgCMatrix` slots through
  `HSquared.sparse_csc_matrix(...; index_base = :zero)`;
- `hs_fit_julia_payload()` no longer takes or uses `max_dense_cells`;
- local live bridge tests passed with 116 pass, 0 fail, 0 warnings, 0 skips;
- R-CMD-check `27457295759`, pkgdown `27457295761`, and Pages `27457326836`
  were green.

Recorded boundary: sparse `Z` marshalling only. No production sparse fitting,
large-data readiness, relationship-object marshalling beyond `Z`, performance
benchmark, or Mrode validation claim.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 180 checks.
- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only blocked/planned/historical-audit wording, not public
  claims that sparse production fitting works, Mrode validation is complete,
  AI-REML is implemented, or PEV/reliability are returned through the bridge
  payload.

## Tests Of The Tests

The Henderson fixture now checks:

- fixed effects from `henderson_mme()`;
- animal effects from `henderson_mme()`;
- fitted values with and without random effects;
- preservation of `spec`, `sigma_a2`, and `sigma_e2`;
- invalid additive and residual variance errors.

## Public Claim Audit

Allowed wording:

- sparse Henderson MME solving exists at supplied variance components;
- R consumes Julia `sparse_csc_matrix()` for sparse `Z` bridge marshalling.

Blocked wording:

- variance components are estimated by the sparse MME path;
- AI-REML is implemented;
- production sparse fitting works;
- R bridge has large-data readiness;
- relationship objects beyond `Z` are marshalled;
- Mrode or external comparator validation is complete;
- `result_payload()` includes PEV or reliability.

## Known Limitations

- Supplied variance components only.
- No factorization reuse or sparse diagnostics are exposed.
- No Mrode textbook example or external comparator was added.
- No R files were edited.
- `result_payload()` was intentionally unchanged.

## Next Actions

1. Add Mrode/simple animal-model validation.
2. Decide lockstep R/Julia PEV/reliability payload widening.
3. Design sparse production optimizer or AI-REML path.
4. Add relationship-object marshalling beyond sparse `Z`.

Rose verdict: clean with limitations.

# R Internal Julia Bridge Smoke Sync

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Lovelace, Emmy, Grace, Rose.

Spawned subagents: none.

## Scope

Record the R twin's internal JuliaCall smoke evidence in the Julia repository
without changing Julia result payload fields or claiming public fitting support.

## R Handoff

The R twin reports `hsquared` commit `c837f2d` with:

- internal `hs_fit_julia_payload()` using JuliaCall;
- the existing R bridge payload sent to the sibling local `HSquared.jl`;
- Julia call path:
  `normalize_pedigree()` -> `pedigree_inverse()` ->
  `fit_animal_model(y, X, Z, Ainv; ids = ..., method = ...)` ->
  `result_payload()`;
- internal normalization of the Julia result into an `hsquared_fit`;
- public `hsquared()` still stopping before fitting.

Reported R evidence:

- R-CMD-check `27456664820`: success.
- pkgdown `27456664821`: success.
- Pages `27456696277`: success.
- R issue #6 evidence comment:
  `https://github.com/itchyshin/hsquared/issues/6#issuecomment-4697510171`.

## Julia Documentation Sync

Updated:

- README
- ROADMAP
- `docs/design/01-v0.1-contract.md`
- `docs/design/02-formula-grammar.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/coordination-board.md`
- docs roadmap/index pages

Local checks:

- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only planned/blocked wording, not public claims that
  `hsquared()` fits through Julia, full sparse bridge marshalling is complete,
  stable user-facing engine controls exist, or Mrode validation is complete.

## Contract Decision

Kept `result_payload()` field names stable:

- `variance_components.sigma_a2`
- `variance_components.sigma_e2`
- `heritability`
- `breeding_values.ids`
- `breeding_values.values`
- `fixed_effects`
- `random_effects.animal.ids`
- `random_effects.animal.values`
- `loglik`
- `df`
- `nobs`
- `predictions`
- `diagnostics`
- `converged`

Dense PEV and reliability remain Julia extractors only. They are not added to
`result_payload()` until the R result contract explicitly grows those fields.

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- R has an internal JuliaCall smoke over the current Julia payload path.
- Julia result payload fields are stable for the current R internal fit object
  contract.

Blocked wording:

- public `hsquared()` fits through Julia;
- sparse relationship-object marshalling beyond `Z` is implemented;
- stable user-facing engine controls exist;
- Mrode validation is complete.

## Next Work

1. Relationship-object marshalling beyond sparse `Z`.
2. Stable user-facing engine control design.
3. Mrode validation before public fitting claims.
4. Decide with the R twin when PEV/reliability enter the bridge result payload.

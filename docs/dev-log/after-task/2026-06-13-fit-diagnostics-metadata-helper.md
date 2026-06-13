# Fit Diagnostics Metadata Helper

Active lenses: Ada, Shannon, Hopper, Emmy, Karpinski, Grace, Rose, Pat.
Spawned subagents: none.

## Goal

Mirror the R twin's `fit_diagnostics()` idea in Julia as a metadata-only
extractor over existing low-level result objects.

## Files Changed

- `src/HSquared.jl`
- `src/likelihood.jl`
- `test/runtests.jl`
- `README.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/index.md`
- `docs/src/quickstart.md`
- `docs/src/roadmap.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-13-fit-diagnostics-metadata-helper.md`

## Implementation

Added:

- `fit_diagnostics(fit::AnimalModelFit)`
- `fit_diagnostics(result::HendersonMMEResult)`

The helper returns a compact `NamedTuple` with metadata already stored on the
result object:

- engine;
- result type;
- target;
- method;
- family;
- convergence flag;
- optimizer status;
- iterations;
- log-likelihood or `nothing`;
- degrees of freedom or `nothing`;
- number of observations;
- dense/sparse path flags;
- variance-component source.

`result_payload()` is unchanged.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed after code/test
  edits. Testset totals sum to 515 checks and the dense fit extractor testset
  has 76 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; Vitepress dependency installation reported the existing
  generated/transient npm advisory noise.
- `git diff --check`: passed.
- Additions-only ASCII scan: no matches.
- Claim-boundary scan: expected blocked/status wording only.

CI and live-site evidence are recorded in the check log after push.

## Public Claim Audit

Allowed wording:

- `fit_diagnostics()` reports metadata for `AnimalModelFit` and
  `HendersonMMEResult`.
- The helper is separate from `result_payload()`.

Blocked wording:

- production diagnostics are implemented;
- gradient or information diagnostics are implemented;
- backend or device diagnostics are implemented;
- `result_payload()` now includes diagnostics extras;
- the helper adds fitting capability or production sparse support.

## Tests Of The Tests

The dense fit extractor testset checks `fit_diagnostics()` values against
fields on constructed `AnimalModelFit` and `HendersonMMEResult` objects. It
also keeps the existing `result_payload()` property-name test unchanged, so
payload widening would fail independently.

## Coordination Notes

R head `060988d` added R-side `fit_diagnostics()`. Julia mirrors only the
metadata extractor concept. Any future bridge requirement to include these
fields in `result_payload()` needs a separate coordinated contract change.

## Known Limitations

- No gradient norm is exposed yet.
- No Hessian/information diagnostics are exposed yet.
- No backend/device diagnostics are exposed yet.
- The Henderson MME target deliberately reports `loglik = nothing` and
  `df = nothing`.

## Next Actions

1. Decide whether R should call Julia `fit_diagnostics()` opportunistically on
   live bridge results.
2. Add gradient/information diagnostics only after the optimizer or sparse
   solver exposes tested values.
3. Continue toward fitted Mrode validation and production sparse diagnostics.

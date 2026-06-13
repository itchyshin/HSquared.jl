# Repeatability / Permanent-Environment MME (Phase 3 start)

Active lenses: Henderson, Falconer, Mrode, Gauss, Curie, Rose (inline).
Spawned subagents: none. Math prototyped and cross-checked locally before
implementation.

## Goal

Open Phase 3 (standard quantitative-genetic models) with the simplest
two-random-effect model: the repeatability / permanent-environment animal model,
as a **supplied-variance** Henderson solve — the same staged approach GBLUP took
(supplied-variance engine first; REML estimation and the R model-spec later /
coordinated).

## Files Changed

- `src/likelihood.jl` (`repeatability_mme`)
- `src/HSquared.jl` (export `repeatability_mme`)
- `test/runtests.jl` (testset; `length(validation)` 21→22)
- `src/validation_status.jl` (row `V3-REPEAT`)
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/after-task/2026-06-13-repeatability-mme.md`

## Implementation

`repeatability_mme(y, X, Z, Ainv, sigma_a2, sigma_pe2, sigma_e2; ids)` solves

    y = X·β + Z·a + Z·pe + e,  a ~ N(0, σ²a·A), pe ~ N(0, σ²pe·I), e ~ N(0, σ²e·I)

by assembling the mixed-model equations for the stacked random effect `[a; pe]`
with a block-diagonal relationship precision `blockdiag(Ainv/σ²a, I/σ²pe)` and
solving. It is **additive** — a new function that does not modify the validated
single-random-effect path (`henderson_mme`). Returns a `NamedTuple`
`(beta, animal_effects, permanent_effects, variance_components)`. `Z` is the
record→animal incidence, shared by `a` and `pe`; identifiability of `a` vs `pe`
requires repeated records.

## Checks

- `Pkg.test()`: passed, 691 total. New testset = 11 checks. The strong anchor is
  an **independent marginal-GLS** computation of the `a` and `pe` BLUPs
  (`û = σ²a·A·Z'·V⁻¹·r`, `p̂e = σ²pe·Z'·V⁻¹·r`, `V = Z(σ²a·A)Z' + Z(σ²pe·I)Z' +
  σ²e·I`), agreeing with `repeatability_mme` to ~1e-9; plus pinned hand values
  and a reduction-to-animal-model check as σ²pe→0.

## Public Claim Audit

Allowed: a supplied-variance two-random-effect (additive + permanent-environment)
MME solve (experimental, engine-internal), validated against an independent
marginal-GLS BLUP and the σ²pe→0 reduction.

Blocked: REML estimation of the three variance components (needs a
≥3-component optimizer — not yet); the R `permanent()` / repeatability model-spec
mapping (contract, coordinated); maternal / common-environment / sire models and
the general multi-random-effect engine; comparator parity.

## Tests Of The Tests

The marginal-GLS cross-check is an algebraically independent route to the same
BLUPs (catches a wrong MME block structure or precision); the reduction check
ties the new path to the validated animal model; the pinned values are
hand-reproducible.

## Coordination Notes

Engine-internal; no bridge / `result_payload` / model-spec change. The R
`permanent()` / repeatability formula mapping and REML estimation are
contract-touching and remain coordinated with the R twin (Phase 3 is on the
coordinated list).

## Known Limitations

- Supplied variance components only (no REML for the 3 components yet).
- Single permanent-environment effect; no maternal / common-environment / general
  multi-random-effect support.
- Dense/sparse validation-scale; no large-data or comparator validation.

## Next Actions

1. A ≥3-component REML optimizer to estimate (σ²a, σ²pe, σ²e), then `h²` and
   repeatability `t = (σ²a+σ²pe)/(σ²a+σ²pe+σ²e)` with intervals.
2. Coordinate the R `permanent()` / repeatability model-spec with the R twin.

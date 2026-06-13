# General Two-Random-Effect MME (common environment / maternal)

Active lenses: Henderson, Falconer, Mendel, Gauss, Curie, Rose (inline).
Spawned subagents: none.

## Goal

Generalize the repeatability kernel into the general supplied-variance
two-independent-random-effect MME, so common-environment and
maternal-environment models reuse one validated solver.

## Files Changed

- `src/likelihood.jl` (`two_effect_mme`; `repeatability_mme` refactored to delegate)
- `src/HSquared.jl` (export `two_effect_mme`)
- `test/runtests.jl` (testset; `length(validation)` 23→24)
- `src/validation_status.jl` (row `V3-TWOEFFECT`)
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/after-task/2026-06-13-two-effect-mme.md`

## Implementation

`two_effect_mme(y, X, Z1, Ainv1, Z2, Ainv2, sigma1, sigma2, sigma_e2)` solves
`y = Xβ + Z1·u1 + Z2·u2 + e` with `u1 ~ N(0, sigma1·A1)`, `u2 ~ N(0, sigma2·A2)`,
via the MME with block-diagonal precision `blockdiag(Ainv1/sigma1, Ainv2/sigma2)`.
The standard models are special cases: repeatability (`Z2=Z1, A2=I`),
common-environment (`Z2`=group incidence, `A2=I`), maternal-environment
(`Z2`=dam incidence, `A2=I`). `repeatability_mme` now delegates to it (the
existing repeatability tests guard the refactor).

## Checks

- `Pkg.test()`: passed, 712 total. New testset = 8 checks; the strong anchor is an
  independent marginal-GLS BLUP on a common-environment fixture (~1e-9), plus the
  `repeatability_mme == two_effect_mme(Z2=Z1, A2=I)` equality.

## Public Claim Audit

Allowed: a general supplied-variance two-independent-random-effect MME for
common-environment / maternal-environment / repeatability (experimental,
engine-internal), GLS-validated.

Blocked: correlated direct–maternal genetic effects (need a 2×2 genetic
covariance / kron structure); REML estimation of the variances (a follow-on);
the R `common_env()` / maternal model-spec; comparator parity.

## Coordination Notes

Engine-internal; no bridge / `result_payload` / model-spec change. The R
`common_env()` / maternal mapping stays coordinated.

## Known Limitations

- Two INDEPENDENT effects only (no direct–maternal genetic correlation).
- Supplied-variance (no REML for the two-effect model yet — a generalization of
  `fit_repeatability_reml`).
- Dense/sparse validation-scale.

## Next Actions

1. Generalize `fit_repeatability_reml` to estimate the two-effect-model variances
   (common-environment / maternal).
2. Correlated direct–maternal genetic model (2×2 G) — Phase-4-flavored.
3. Coordinate the R `common_env()` / maternal model-spec with the R twin.

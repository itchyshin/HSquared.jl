# Repeatability REML Variance-Component Estimation

Active lenses: Gauss, Fisher, Henderson, Falconer, Curie, Rose (inline).
Spawned subagents: none. Prototyped and recovery-checked before shipping.

## Goal

Turn the supplied-variance `repeatability_mme` into a full estimator: REML
estimation of (σ²a, σ²pe, σ²e) and the **repeatability coefficient**
`t = (σ²a + σ²pe) / total`, the key parameter for repeated-records models.

## Files Changed

- `src/likelihood.jl` (`_repeatability_dense`, `fit_repeatability_reml`)
- `src/HSquared.jl` (export `fit_repeatability_reml`)
- `test/runtests.jl` (testset; `length(validation)` 22→23)
- `src/validation_status.jl` (row `V3-REPEAT-REML`; `V3-REPEAT` missing updated)
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/decisions/2026-06-13-rng-recovery-test-harness.md` (resolved),
  `docs/dev-log/after-task/2026-06-13-repeatability-reml.md`

## Implementation

`fit_repeatability_reml` maximizes the dense two-random-effect REML
log-likelihood `ℓ(σ²a, σ²pe, σ²e) = −0.5(log|V| + log|XᵀV⁻¹X| + yᵀPy)`,
`V = σ²a·ZAZᵀ + σ²pe·ZZᵀ + σ²e·I`, over the log-variances (NelderMead via Optim),
then returns the VCs, `t`, `h²`, β, and the `a`/`pe` BLUPs computed from `V` at
the optimum. Dense/validation-scale (forms `V`).

## Validation (the hybrid: deterministic CI + one-off recovery)

Deterministic (committed, 13 checks):
- the dense loglik reduces to the animal-model REML (matched up to a constant
  against `sparse_reml_loglik`, the validated 2-component path) when σ²pe=0;
- the dense BLUPs equal the sparse `repeatability_mme` BLUPs at a supplied
  interior point (~1e-15);
- the optimizer converges, returns valid VCs with `t ≥ h²` in [0,1], and its
  optimum beats a ±30% grid (near-global);
- guards (positive initials, dimensions).

One-off seeded recovery (NOT committed — the CI suite is deliberately RNG-free,
per the decision note): n=70 animals (10 founders + 60 offspring), true
(σ²a, σ²pe, σ²e) = (1.0, 0.6, 1.5) recovered as ≈ (0.94, 0.83, 1.48), `t`
0.516 → 0.545.

## Public Claim Audit

Allowed: experimental REML estimation of the three repeatability variance
components and the repeatability coefficient, with deterministic correctness
checks and a documented one-off recovery.

Blocked: a committed (CI) recovery test; uncertainty intervals for `t`/`h²`;
external-comparator parity; large-data / production scale (dense `V`); the R
`permanent()` model-spec.

## Coordination Notes

Engine-internal; no bridge / `result_payload` / model-spec change. The R
`permanent()` / repeatability mapping stays coordinated.

## Known Limitations

- Dense `V` (validation-scale); NelderMead (no AI/Newton for 3 components).
- Small data can yield a boundary optimum (σ²a or σ²pe → 0); identifiability
  needs relationship contrast + replication.
- No committed recovery harness; no `t`/`h²` intervals.

## Next Actions

1. A committed seeded-recovery harness (opt-in or loose-bound) per the decision
   note, then `t`/`h²` intervals (finite-difference Hessian of the dense loglik).
2. Generalize to common-environment / maternal models (a general two-effect MME).
3. Coordinate the R `permanent()` / repeatability model-spec with the R twin.

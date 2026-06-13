# Phase 4 start: multivariate (multi-trait) animal model (supplied covariance)

Active lenses: Henderson, Kirkpatrick, Falconer, Noether, Gauss, Curie, Rose
(inline).

## Goal

Open Phase 4 with the smallest safe multivariate engine slice: a supplied-(co)variance
multi-trait animal-model MME, the multi-trait analogue of `henderson_mme` /
`two_effect_mme`. No covariance-matrix estimation (that is a later REML/EM slice).

## What landed

- `src/multivariate.jl` (new), included in `HSquared.jl` and exported:
  - `multivariate_mme(Y, X, Z, Ainv, G0, R0; ids, traits)` — balanced multi-trait
    animal model at supplied `t×t` genetic (`G0`) and residual (`R0`) covariances.
    Kronecker MME, records ordered individual-major (trait fastest): genetic
    precision `Ainv ⊗ G0⁻¹` on the random block, residual precision `I ⊗ R0⁻¹`.
    Returns per-trait `beta` (`p×t`), `breeding_values` (`q×t` EBVs, with `ids` and
    `traits`), the supplied covariances, and derived genetic/residual correlations.
  - `genetic_correlation(C)` / `genetic_correlation(result)` — covariance →
    correlation matrix (PD/symmetry guards).

## Validation (deterministic, comparator-free)

New testset (23 checks), RNG-free fixture (4-animal pedigree, balanced 2 traits).
All four numerical references are asserted to a committed `1e-10` tolerance; the
observed agreement is machine precision (~1e-14):

1. **Independent loop-built MME** — β/EBVs match a from-scratch element-wise MME
   assembly (validates the Kronecker plumbing and reshape).
2. **Independent marginal-GLS BLUP** — β/EBVs match `(X'V⁻¹X)⁻¹X'V⁻¹y` and
   `(A⊗G0)Z'V⁻¹(y−Xβ)` with `V = Z(A⊗G0)Z' + I⊗R0` (validates the estimand
   independent of MME assembly).
3. **Univariate reduction** — at `t=1` equals the standard animal-model MME.
4. **Diagonal decoupling** — diagonal `G0`/`R0` give per-trait EBVs identical to
   `t` independent single-trait fits.
5. `genetic_correlation` hand-checked; trait labels propagate; symmetry / PD /
   dimension / `ids`-length guards fire.

`validation_status()` 25 → 26 (`V4-MULTIVARIATE`, partial).

## Checks

- `Pkg.test()`: passed (full suite). `julia --project=docs docs/make.jl`: green
  (new "Multivariate models" page with a runnable balanced two-trait example).

## Status surfaces (lockstep)

- `src/validation_status.jl`: new `V4-MULTIVARIATE` row (partial).
- `docs/design/capability-status.md`: new experimental row.
- `docs/design/validation-debt-register.md`: `V3-MV` → `V4-MV`, planned → partial.
- `docs/src/api.md`, `docs/src/changelog.md`, `docs/src/multivariate-models.md`,
  `docs/make.jl`, `docs/dev-log/check-log.md`, this report.

## Public claim audit (Rose, inline)

Allowed: an **experimental, validation-scale** balanced multi-trait MME at a
**supplied** covariance, backed by four independent numerical references + guards.
Every status surface says experimental / not-public-default / supplied-covariance.

Blocked / still pending: covariance-matrix **estimation** (multivariate REML/EM);
**unbalanced / missing-trait** records and a long-format interface; per-trait
designs; a published Mrode multi-trait fixture and external-comparator parity
(sommer / ASReml / JWAS); the R-facing multivariate model-spec. None are claimed.

## Coordination notes

This is engine-internal and does not change the R-Julia bridge contract. The R
lane owns when (and whether) a multivariate model-spec is exposed; flagged for the
next phase-boundary coordination note. Stacked PR on the v0.1-gate / ROADMAP train
(`main` ← v0.1-gate ← roadmap ← phase4) for conflict-free maintainer merge.

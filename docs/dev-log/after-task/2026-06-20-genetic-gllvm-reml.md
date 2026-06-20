# After-task — Genetic-GLLVM REML over G_lat (#50 slice 3)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/genetic-gllvm-reml`. Genetic GLLVM (#50) slice 3 — the estimation layer,
completing the descriptors → solve → marginal → REML arc ("all of 1", `/goal` push).

## Summary

Landed `fit_gllvm_laplace_reml(Y, Ainv, family; rank, X)` (internal,
`src/genetic_gllvm.jl`) — ESTIMATES the rank-`K` latent loadings `Λ` (so
`G_lat = ΛΛ'`) by maximizing the K-factor Laplace marginal
([`gllvm_laplace_marginal_loglik`], slice 2) over `vec(Λ)` (NelderMead). The marginal
depends on `Λ` only through `G_lat = ΛΛ'`, so it is ROTATION-INVARIANT; the result
reports the rotation-invariant `genetic_covariance` / `latent_structure`, never the
raw `Λ̂` (an arbitrary point on the rotation manifold).

## Validation (correctness, not recovery)

- **`K=1, T=1` Poisson** reduces to the single-factor `fit_laplace_reml`
  (`σ²a = λ̂²`, rtol 2e-3) — the genetic-GLLVM REML recovers the trusted single-factor
  REML estimate.
- **Multi-trait Poisson rank-1** converges and the optimum improves over the start
  (objective is maximized).
- **Gaussian self-consistency**: the optimum's marginal equals
  `_multivariate_reml_loglik` at the estimated `Λ̂Λ̂'` (`R0 = σ²e·I`, rtol 1e-7).

These are correctness checks (reductions + optimum-improvement + self-consistency),
**NOT a known-truth recovery claim** — structured non-Gaussian REML recovery is a
separate opt-in study, and the multivariate FA recovery has not passed, so recovery
is explicitly not claimed.

## Definition of Done

- implementation — `fit_gllvm_laplace_reml` in `src/genetic_gllvm.jl` (reuses the
  module's `Optim`/`NelderMead`); internal (not exported).
- tests — "Genetic-GLLVM REML over G_lat (#50 slice 3)": 12 assertions (the K=1
  Poisson reduction, multi-trait convergence + optimum-improvement, Gaussian
  self-consistency, guards). Full suite green.
- documentation — docstring (estimator + rotation-invariance + the explicit
  no-recovery caveat); capability-status row (NEW) + `V6-GGLLVM-REML` validation-debt
  (NEW) + `validation_status()` (NEW → **41 rows**; count + `[end].id` updated). No
  `api.md` change (internal).
- check-log — `docs/dev-log/check-log.d/2026-06-20-genetic-gllvm-reml.md`.
- after-task — this file.
- Rose audit — inline (below).
- clean local checks — `Pkg.test()` + `docs/make.jl`.
- clean CI — gated on the PR.

## Rose audit (claim-vs-evidence)

Rose-lens audit (inline). **CLEAN.** The estimator's correctness is validated by an
independent-path reduction (`fit_laplace_reml`), optimum-improvement, and
Gaussian-marginal self-consistency; the docs are emphatic that this is NOT a recovery
claim (recovery is unproven for structured non-Gaussian REML). Rotation-invariance is
honoured by construction (the objective and the reported functionals depend only on
`ΛΛ'`; the raw `Λ̂` is never surfaced as identified). Honest status: a distinct
`V6-GGLLVM-REML` row, experimental, internal, `GLLVM-style animal models` stays
`planned`, nothing covered.

## Claim boundary

Experimental, dense/validation-scale, low-rank `G_lat` only, one family for all traits,
balanced/fully-observed `Y`, INTERNAL. No known-truth recovery, no factor-analytic
(`+Ψ`) structure, no fitted-object/EBV extractor surface, no per-trait families, no R
model-spec/bridge. Nothing promoted to covered.

## Next ("all of 1" complete)

The genetic-GLLVM descriptors → Gaussian solve → non-Gaussian marginal → REML arc is
now landed (supplied-loadings / low-rank, internal). Remaining genetic-GLLVM work:
a known-truth recovery study, the FA (`+Ψ`) structure, a fitted-object/EBV extractor +
`nongaussian_result_payload` analogue, per-trait families, unbalanced/missing records,
the external GLLVM.jl/gllvmTMB comparator, and the R model-spec (gated on #50 Q1/Q2).

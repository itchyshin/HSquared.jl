# After-task — Genetic-GLLVM Gaussian latent solve (#50 slice 2)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/genetic-gllvm-gaussian-solve`. Genetic GLLVM (#50), slice 2 (Gaussian part)
of the descriptors → supplied-covariance solve → REML plan.

## Summary

Landed `genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, loadings, R0; uniqueness, ids)`
(exported, `src/genetic_gllvm.jl`). Key identity: under a Gaussian response the
genetic-GLLVM latent layer gives trait-level breeding values `u[i,·] = Λ g[i,·]`
with `Cov(vec(U)) = G_lat ⊗ A`, `G_lat = ΛΛ'(+diag Ψ)` — so the **Gaussian genetic
GLLVM is EXACTLY the multivariate animal model at `G0 = G_lat`**. The function
builds `G_lat` from supplied loadings and delegates to `multivariate_mme`, returning
that solve augmented with the rotation-invariant `latent_structure`
(`genetic_gllvm_descriptors`) and `n_latent_factors`.

The solve's numerical correctness therefore **reduces to `multivariate_mme`** (V4-MV,
already validated) — this slice's own claim is the construction + the defining
identity, not a new solver. `G_lat` must be PD (positive `Ψ` or full-rank loadings);
a pure low-rank `G_lat` (`K < t`, no `Ψ`) is singular and rejected.

## Definition of Done

- implementation — `genetic_gllvm_gaussian_mme` in `src/genetic_gllvm.jl`; exported.
- tests — "Genetic-GLLVM Gaussian latent solve (#50 slice 2, supplied G_lat)": 15
  assertions — the defining identity (`== multivariate_mme` at `G0 = G_lat`, exact
  β + EBVs); the full-rank low-rank case; rotation invariance (`Λ→ΛQ`); the
  `t=1, K=1` reduction to the univariate `henderson_mme` (β + EBVs); `latent_structure`
  consistency + shape; guards (trait mismatch; singular-`G_lat` rejection). Full
  suite green.
- documentation — docstring (the identity + the PD requirement + honest caveats);
  `docs/src/api.md`; capability-status + `V6-GGLLVM-DESC` validation-debt +
  `validation_status()` rows EXTENDED (folded into the slice-1 row — no inflated new
  validation row, since the solve correctness reduces to `multivariate_mme`).
- check-log — `docs/dev-log/check-log.d/2026-06-20-genetic-gllvm-gaussian-solve.md`.
- after-task — this file.
- validation-debt — `V6-GGLLVM-DESC` extended; `validation_status()` stays **39 rows**.
- Rose audit — see below.
- clean local checks — `Pkg.test()` + `docs/make.jl`.
- clean CI — gated on the PR.

## Rose audit (claim-vs-evidence)

Rose-lens audit (inline review perspective, session-limit-frugal). **Verdict: CLEAN,
no blockers.** Every claim is backed: the defining identity, rotation invariance, and
the `t=1, K=1` → `henderson_mme` reduction are all directly asserted; the docs are
explicit that the solve correctness REDUCES to `multivariate_mme` (no over-claim of
an independently-validated new solver); the PD requirement is documented and the
singular-`G_lat` rejection is tested; honest status preserved by FOLDING into
`V6-GGLLVM-DESC` rather than adding a new validation row (which would have implied
independent validation). Supplied-covariance only, nothing estimated, nothing
promoted to covered.

## Claim boundary

Supplied-covariance Gaussian solve only — `Λ`/`Ψ`/`R0` NOT estimated (that is slice
3); the NON-Gaussian latent marginal (Poisson/Bernoulli/Binomial) is the remainder
of slice 2 and is not built here; no R model-spec or bridge payload. `GLLVM-style
animal models` stays `planned`.

## Next

The non-Gaussian latent marginal (`G_lat ⊗ A` into the Laplace/VA marginal, K>1
factors) — the genuinely new gap (§3 of the scope doc); then slice 3 REML over
structured `G_lat`. Cross-team Q1/Q2 (#50) + #44/#37 gate the R bridge.

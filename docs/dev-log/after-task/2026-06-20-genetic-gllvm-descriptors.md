# After-task — Genetic-GLLVM latent-structure descriptors (#50 slice 1)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/genetic-gllvm-descriptors`. Genetic GLLVM (#50), slice 1 of the
descriptors → supplied-covariance → REML plan (`docs/dev-log/scout/2026-06-20-genetic-gllvm-scope.md`).

## Summary

Landed `genetic_gllvm_descriptors(loadings; uniqueness = nothing)` (exported, new
`src/genetic_gllvm.jl`) — the rotation-INVARIANT descriptors of a genetic-GLLVM
latent layer from SUPPLIED `traits × K` loadings `Λ` (+ optional positive
uniqueness `Ψ`). Returns a NamedTuple `(genetic_covariance, genetic_variances,
genetic_correlation, communality, genetic_pca, g_max, rank, n_latent_factors)`,
where `Σ_g = ΛΛ' (+ diag Ψ)` and `communality = (ΛΛ')_tt / Σ_g[t,t]` (the per-trait
fraction of genetic variance from the common latent factors — the one genuinely new
GLLVM descriptor). Pure composition of existing numerics; no new estimation.

## Reuse (per the scope doc — reuse, don't reinvent)

- `lowrank_covariance` / `factor_analytic_covariance` / `genetic_correlation`
  (`src/multivariate.jl`);
- `genetic_pca` / `g_max` (`src/evolvability.jl`).

All guards (dimension / positivity / rank) are delegated to those functions.

## Definition of Done

- implementation — `genetic_gllvm_descriptors` in `src/genetic_gllvm.jl`; exported;
  included after `evolvability.jl`.
- tests — "Genetic-GLLVM latent-structure descriptors (#50 slice 1, supplied Λ)":
  24 deterministic RNG-free assertions — the five scope-doc gates (exact `Σ_g`
  agreement; communality bounds + definition; rotation invariance; the `K=t, Λ=I,
  Ψ=0` reduction; delegated guards) plus shape/`propertynames`. Full suite green.
- documentation — docstring (honest caveats); `docs/src/api.md`; capability-status
  row added + the planned `GLLVM-style animal models` row cross-linked.
- check-log — `docs/dev-log/check-log.d/2026-06-20-genetic-gllvm-descriptors.md`.
- after-task — this file.
- capability-status row — new experimental "Genetic-GLLVM latent-structure
  descriptors (supplied loadings)" row.
- validation-debt — new `V6-GGLLVM-DESC` (partial) row; `validation_status()` now
  **39 rows** (test assertion updated 38 → 39; `[end].id` → `V6-GGLLVM-DESC`).
- Rose audit — see below.
- clean local checks — `Pkg.test()` + `docs/make.jl`.
- clean CI — gated on the PR.

## Rose audit (claim-vs-evidence)

Rose-lens audit (run inline as a review perspective, not a spawned subagent —
session-limit-frugal; the slice is a pure composition of already-validated numerics
with deterministic exact-equality gates). **Verdict: CLEAN, no blockers.** Every
claim is backed by a test assertion: the NamedTuple shape (`propertynames`); exact
`Σ_g` agreement with `lowrank_covariance`/`factor_analytic_covariance`; the
communality definition + bounds; the rotation-invariance gate (`Σ_g` proven
invariant under `Λ→ΛQ`, and every returned quantity is a deterministic function of
the invariant `Σ_g`/`common`); no raw-loadings leakage (the returned tuple has no
`Λ` field); and honest status (capability row `experimental`, `V6-GGLLVM-DESC`
`partial`, `validation_status()` 39 rows, `GLLVM-style animal models` stays
`planned`, nothing covered).

## Claim boundary

DESCRIPTIVE, supplied-covariance only — `Λ`/`Ψ` are NOT estimated; there is no
marginal, likelihood, or fit; no R model-spec or bridge payload; only
rotation-INVARIANT functionals of `Σ_g` are returned (never the raw loadings,
which are rotation-nonidentified). First foundation step of the genetic GLLVM
(#50); the `GLLVM-style animal models` capability stays `planned`. Nothing
promoted to covered.

## Next

Slice 2 — the supplied-covariance genetic-GLLVM latent marginal/solve (`G_lat ⊗ A`
into the non-Gaussian marginal), reduction-validated against `nongaussian` (K=1)
and `multivariate_mme` (Λ=I); then slice 3 — genetic-GLLVM REML over structured
`G_lat`. Cross-team Q1/Q2 (#50) and #44/#37 gate the full build / R bridge; slice 1
was cross-team-independent.

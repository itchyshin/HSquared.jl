# 2026-06-20 Genetic-GLLVM non-Gaussian K-factor latent marginal (#50 slice 2)

- **Goal:** build the genuinely new genetic-GLLVM capability — the non-Gaussian
  K-factor latent Laplace marginal (the gap §3 of the scope doc). `/goal` push
  ("finish all of 1") with ultracode adversarial verification.
- **Active lenses:** Gauss (numerics/Laplace) + Noether (design/ordering) + Curie
  (validation) + Kirkpatrick (latent factors) + Rose (claims, mandatory).
- **What landed (`src/genetic_gllvm.jl`, internal):**
  `gllvm_laplace_marginal_loglik(Y, Ainv, loadings, family; X)` — Laplace marginal of
  `vec(g) ~ N(0, I_K ⊗ A)`, `η[i,t] = (Xβ)[i,t] + Σ_k Λ[t,k] g[i,k]`, `y|η ~ family`.
  Generalizes the single-factor `laplace_marginal_loglik` via `(W, I_K ⊗ Ainv)` (the
  Λ-weighted latent design + block-diagonal precision); penalized-IRLS Newton + Laplace.
  Include moved AFTER `nongaussian.jl` (needs `ResponseFamily`/`_fam_*`).
- **TDD:** targeted reductions verified to machine precision BEFORE the formal testset.
- **Gates (11 assertions):** (1) `K=1,T=1` → `laplace_marginal_loglik` (`σ²a=λ²`) EXACT
  for Gaussian + Poisson (Laplace affine-invariance); (2) Gaussian full-rank-`Λ` (`K=T`)
  → `_multivariate_reml_loglik` at `G0=ΛΛ'` (exact); (3) Bernoulli/Binomial convergence
  + `‖∇‖<1e-8`; shapes (`beta` p×T, `g` q×K); dimension/count guards.
- **Docs:** docstring; capability-status row (new) + `V6-GGLLVM-MARGINAL` validation-debt
  (new) + `validation_status()` (new → 40 rows; count + `[end].id` updated); no `api.md`
  (internal). `docs/make.jl` clean.
- **Honest status:** SUPPLIED loadings (NOT estimated — slice 3), one family for all
  traits, balanced/fully-observed, internal/not-exported, no R model-spec/bridge.
  Nothing covered.
- **Ultracode verification:** bounded 3-lens Workflow (Gauss/Noether/Curie) + Rose
  synthesis — verdict [FILLED ON COMPLETION].

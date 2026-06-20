# 2026-06-20 Genetic-GLLVM REML over G_lat (#50 slice 3)

- **Goal:** complete "all of 1" — the genetic-GLLVM estimation layer: REML over the
  K-factor Laplace marginal.
- **Active lenses:** Gauss (optimizer/numerics) + Kirkpatrick (latent factors /
  rotation) + Fisher (estimation) + Rose (claims).
- **What landed (`src/genetic_gllvm.jl`, internal):**
  `fit_gllvm_laplace_reml(Y, Ainv, family; rank, X)` — estimates the rank-`K` loadings
  `Λ` (`G_lat = ΛΛ'`) by NelderMead over `vec(Λ)` maximizing
  `gllvm_laplace_marginal_loglik`. Rotation-invariant objective ⇒ reports
  `genetic_covariance`/`latent_structure` only (never raw `Λ̂`). Reuses module `Optim`.
- **TDD:** targeted reductions verified BEFORE the formal testset (K=1 Poisson match,
  optimum-improvement, Gaussian self-consistency).
- **Gates (12 assertions):** K=1,T=1 Poisson → `fit_laplace_reml` (`σ²a=λ̂²`, rtol 2e-3);
  multi-trait Poisson rank-1 converges + optimum ≥ start; Gaussian optimum marginal ==
  `_multivariate_reml_loglik` at `Λ̂Λ̂'` (rtol 1e-7); shapes; rank/initial guards.
- **Docs:** docstring (no-recovery caveat); capability-status (new) + `V6-GGLLVM-REML`
  validation-debt (new) + `validation_status()` (new → 41 rows; count + `[end].id`
  updated); no `api.md` (internal). `docs/make.jl` clean.
- **Honest status:** a correctness-validated ESTIMATOR (reductions + optimum +
  self-consistency) — NOT a known-truth recovery claim (recovery unproven for
  structured non-Gaussian REML). Low-rank only, one family, balanced, internal. Nothing
  covered.
- **Rose audit:** CLEAN (inline). No-recovery framing explicit; rotation-invariance by
  construction; distinct V6-GGLLVM-REML row; nothing covered.

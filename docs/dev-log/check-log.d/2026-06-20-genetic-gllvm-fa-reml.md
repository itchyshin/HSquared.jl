# 2026-06-20 Genetic-GLLVM REML: factor-analytic (+Ψ) structure (#50)

- **Goal:** extend the genetic-GLLVM REML (slice 3, #103) with the factor-analytic
  latent structure (`G_lat = ΛΛ' + diag(Ψ)`), completing FA parity with the
  descriptors / Gaussian solve.
- **Active lenses:** Gauss (optimizer) + Kirkpatrick (latent factors) + Rose (claims).
- **What landed (`src/genetic_gllvm.jl`, internal):** `fit_gllvm_laplace_reml` now takes
  `structure = :lowrank | :factor_analytic` (+ `initial_uniqueness`). FA estimates a
  per-trait `Ψ > 0` (log scale) by augmenting the loadings to `[Λ | diag(√Ψ)]`
  (`ΛΛ' + diag(Ψ)`) and reusing `gllvm_laplace_marginal_loglik` UNCHANGED. Result now
  carries `uniqueness` (`Ψ̂` / `nothing`).
- **TDD:** FA path verified BEFORE the formal tests (Gaussian self-consistency, FA≥lowrank,
  Poisson FA convergence, lowrank-unchanged).
- **Gates:** testset 12 → 21 assertions — Gaussian FA self-consistency (marginal ==
  `_multivariate_reml_loglik` at `Λ̂Λ̂'+Ψ̂`); `communality < 1` (Ψ̂>0); FA loglik ≥ lowrank
  loglik (FA nests lowrank); Poisson FA converges with Ψ̂>0; `uniqueness` length;
  structure / Ψ-length guards; lowrank still `uniqueness===nothing`.
- **Docs:** docstring; capability-status + `V6-GGLLVM-REML` validation-debt +
  `validation_status()` rows EXTENDED (no new row; stays 41 rows); no `api.md`
  (internal). `docs/make.jl` clean.
- **Honest status:** correctness-validated estimator (reductions + self-consistency) —
  NOT a recovery claim. Low-rank + FA, one family, balanced, internal. Nothing covered.
- **Rose audit:** CLEAN (inline). Exact augmentation reuses the verified marginal;
  rotation-invariance preserved; folded into V6-GGLLVM-REML (no inflated row).

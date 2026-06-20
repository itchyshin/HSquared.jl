# 2026-06-20 Genetic-GLLVM latent-structure descriptors (#50 slice 1)

- **Goal:** land genetic-GLLVM slice 1 — `genetic_gllvm_descriptors(Λ; uniqueness)`,
  the rotation-invariant descriptors of a supplied-loadings latent layer
  (`docs/dev-log/scout/2026-06-20-genetic-gllvm-scope.md`).
- **Active lenses:** Kirkpatrick (latent genetic axes / rotation invariance) +
  Fisher (identifiability) + Gauss (numerics) + Rose (claims, mandatory).
- **What landed (exported, `src/genetic_gllvm.jl`):**
  `genetic_gllvm_descriptors(loadings; uniqueness = nothing)` →
  `(genetic_covariance Σ_g = ΛΛ'(+diag Ψ), genetic_variances, genetic_correlation,
  communality = (ΛΛ')_tt/Σ_g[t,t], genetic_pca, g_max, rank, n_latent_factors = K)`.
  Pure composition of `lowrank_covariance`/`factor_analytic_covariance`/
  `genetic_correlation` (multivariate.jl) + `genetic_pca`/`g_max` (evolvability.jl);
  guards delegated. Only rotation-INVARIANT functionals returned (never raw Λ).
- **TDD:** test-first — confirmed RED (`genetic_gllvm_descriptors` undefined) before
  implementing. New testset green; full `Pkg.test()` green.
- **Gates (24 assertions, RNG-free):** (1) exact `Σ_g == lowrank_covariance(Λ)`
  (Ψ absent) / `== factor_analytic_covariance(Λ, Ψ)`; (2) `communality == 1` at
  Ψ=0, `== (ΛΛ')_tt/Σ_g[t,t]` strictly in (0,1) with positive Ψ; (3) **rotation
  invariance** — orthogonal `Q`, `Λ→ΛQ` leaves Σ_g/variances/communality/correlation/
  genetic_pca eigenvalues invariant; (4) reduction `K=t, Λ=I, Ψ=0` → `Σ_g=I`,
  communality 1, eigenvalues all 1; (5) delegated dimension/positivity/rank guards;
  plus `propertynames` shape.
- **Docs:** docstring (honest-status caveats); `docs/src/api.md`; capability-status
  row added (+ planned GLLVM row cross-linked); `V6-GGLLVM-DESC` validation-debt row;
  `validation_status()` 38 → **39 rows** (test count assertion + `[end].id` updated);
  `docs/make.jl`.
- **Honest status:** DESCRIPTIVE, supplied-covariance only — Λ/Ψ NOT estimated, no
  marginal/fit, no R model-spec/bridge. `GLLVM-style animal models` stays `planned`.
  Nothing covered-promoted.
- **Cross-lane:** slice 1 is cross-team-independent (reuses only HSquared code). The
  full build + R bridge are gated on #50 Q1/Q2 + #44/#37 (#61); not touched here.
- **Rose audit:** CLEAN (inline Rose-lens perspective, session-limit-frugal). Every
  claim backed by a deterministic test; no raw-loadings leakage; honest status
  (experimental / `V6-GGLLVM-DESC` partial / 39 rows / nothing covered).

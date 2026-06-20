# 2026-06-20 Genetic-GLLVM Gaussian latent solve (#50 slice 2)

- **Goal:** land genetic-GLLVM slice 2 (Gaussian part) — `genetic_gllvm_gaussian_mme`,
  the supplied-`G_lat` Gaussian latent solve.
- **Active lenses:** Kirkpatrick (latent axes / rotation) + Gauss (numerics) +
  Henderson (MME) + Rose (claims, mandatory).
- **Key identity:** under a Gaussian response `Cov(vec(U)) = G_lat ⊗ A`, so the
  Gaussian genetic GLLVM IS the multivariate animal model at `G0 = G_lat = ΛΛ'(+Ψ)`.
- **What landed (exported, `src/genetic_gllvm.jl`):**
  `genetic_gllvm_gaussian_mme(Y, X, Z, Ainv, loadings, R0; uniqueness, ids)` builds
  `G_lat` and delegates to `multivariate_mme`, returning the solve (β,
  breeding_values, covariances/correlations, traits) + the rotation-invariant
  `latent_structure` (`genetic_gllvm_descriptors`) + `n_latent_factors`. `G_lat` must
  be PD (positive Ψ or full-rank Λ); singular pure-low-rank `G_lat` rejected.
- **TDD:** targeted RED→GREEN; new testset 15 assertions green; full `Pkg.test()` green.
- **Gates:** defining identity (`== multivariate_mme` at `G0 = G_lat`, exact β+EBVs);
  full-rank low-rank case; rotation invariance (`Λ→ΛQ`); `t=1, K=1` reduction to the
  univariate `henderson_mme` (β+EBVs); `latent_structure` consistency + `propertynames`;
  guards (trait mismatch; singular-`G_lat` rejection).
- **Docs:** docstring; `docs/src/api.md`; capability-status + `V6-GGLLVM-DESC`
  validation-debt + `validation_status()` rows EXTENDED (folded into slice 1 — no new
  validation row, since solve correctness reduces to `multivariate_mme` / V4-MV);
  `docs/make.jl` clean.
- **Honest status:** supplied-covariance Gaussian solve only — Λ/Ψ/R0 NOT estimated
  (slice 3), non-Gaussian marginal not built, no R model-spec/bridge. `validation_status()`
  stays 39 rows; `GLLVM-style animal models` stays `planned`; nothing covered.
- **Rose audit:** CLEAN (inline). Solve correctness honestly reduces to `multivariate_mme`;
  no inflated validation row; PD requirement documented + tested.

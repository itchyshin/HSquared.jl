# 2026-06-20 Random-regression REML (#54, slice 3)

- Goal: slice 3 of the random regression capability — dense REML estimation of the
  coefficient genetic covariance `K_g` and the homogeneous residual `σ²e`, building
  on slice 1 (descriptors) + slice 2 (supplied-covariance MME). The direct analogue
  of `fit_multivariate_reml`.
- Lenses: Henderson (mixed-model equations) + Gauss (REML numerics) + Karpinski
  (Julia perf) + Rose (claim gate) — all run as actual subagents (3-lens adversarial
  review via an ultracode workflow; Henderson reviewed separately first).

## What was done

- `src/random_regression.jl` (exported): `fit_random_regression_reml(y, X, Phi, Z,
  Ainv; initial, iterations, ids)` maximizes the REML log-likelihood over a
  log-Cholesky parameterization of `K_g` (k×k PD) + `log σ²e` by Nelder–Mead on the
  marginal `V = W(A⊗K_g)Wᵀ + σ²e I` (`W = face-splitting(Z, Phi)`), reusing the
  multivariate `_chol_params_to_cov`/`_cov_to_chol_params`. EBVs/β via the GLS BLUP
  form at the estimate. Helpers: `_rr_build_Vchol`, `_rr_reml_loglik_core`,
  `_rr_gls_blup`.
- Correctness GATE (RNG-free, deterministic): (a) reported REML loglik (full
  `(n−p)·log(2π)` constant, package-wide scale) matches an INDEPENDENT dense marginal
  oracle at the estimate (~1e-6) and beats deliberately off-optimum points; (b) the
  degree-0 (`k=1`) reduction recovers `fit_sparse_reml` via `K_g[1,1] = 2σ²a`
  (φ_0² = 1/2) — equal `σ²e` (rtol 1e-3), equal loglik (~1e-8) at an interior-σ²a
  fixture; (c) fitted BLUPs/β equal `random_regression_mme` at the estimate (~1e-7).
- Tests: "Phase 3 random-regression REML (#54 slice 3)" (21 assertions).
  `validation_status()` 35 → 36 (`V3-RR-REML`; V6-LAPLACE stays last). api.md +
  capability-status (new row + slice-1/slice-2 note updates) + validation-debt
  V3-RR-DESC updated; roadmap note marks slice 3 DONE.
- Review fixes applied before merge: two stale "RR REML is a later slice" deferral
  claims corrected (the `random_regression_mme` docstring + the descriptors
  capability-status row + the file-header comment); docstring comparator list made
  consistent (`WOMBAT/ASReml/JWAS`); a non-finite-objective screen added to
  `negloglik` (cholesky on a non-finite V does not throw → map any non-finite value
  to the +Inf reject sentinel); an honest `O(1/σ²e)` boundary-conditioning caveat
  added to the docstring.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (RR REML testset 21/21; `validation_status()` 36 rows; oracle + degree-0 +
  MME-BLUP gates green).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (exit 0)** (incl. the
  new `fit_random_regression_reml` api.md entry). CI on a clean checkout is the
  authoritative gate (Dropbox working-tree desync caveat).

## Claim boundary

EXPERIMENTAL, dense/validation-scale, REML-only, Gaussian, homogeneous residual, no
permanent-environment term. Validated by deterministic self-consistency + an
independent oracle + the univariate-reduction only — `K_g` known-truth recovery and
any WOMBAT/ASReml/JWAS comparator are NOT exercised; no R `rr()` model-spec or bridge
payload. No capability moved to covered.

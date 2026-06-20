# After-task — Random-regression REML (#54, slice 3)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/s54c-rr-reml`. Slice 3 of the random-regression / reaction-norm capability.

## Summary

Added `fit_random_regression_reml(y, X, Phi, Z, Ainv)`: dense REML estimation of the
random-regression coefficient genetic covariance `K_g` (k×k) and the homogeneous
residual variance `σ²e` of the polynomial reaction-norm animal model. Log-Cholesky
Nelder–Mead on the marginal `V = W(A⊗K_g)Wᵀ + σ²e I` (`W = face-splitting(Z, Phi)`),
reusing the multivariate `_chol_params_to_cov`/`_cov_to_chol_params` core; EBVs/β via
the GLS BLUP form at the estimate. This completes the estimation half of the RR
capability (slice 1 = descriptors, slice 2 = supplied-covariance MME).

## Definition of Done

- implementation — `fit_random_regression_reml` + `_rr_build_Vchol` /
  `_rr_reml_loglik_core` / `_rr_gls_blup` in `src/random_regression.jl`; exported.
- tests — "Phase 3 random-regression REML (#54 slice 3)" (21 assertions): independent
  marginal oracle + beats-off-optimum + degree-0 `k=1` reduction to `fit_sparse_reml`
  (`K_g[1,1] = 2σ²a`) + BLUP/β agreement with `random_regression_mme`; guards.
- documentation — docstring; `docs/src/api.md`; capability-status row (+ slice-1/2
  note updates); validation-debt `V3-RR-DESC` update; `V3-RR-REML` in
  `validation_status()` (35 → 36); roadmap note slice 3 = DONE.
- example / not-public note — EXPERIMENTAL caveats throughout; no R model-spec.
- check-log — `docs/dev-log/check-log.d/2026-06-20-random-regression-reml.md`.
- after-task — this file.
- capability-status row — added (Random-regression REML).
- validation-debt row — `V3-RR-DESC` extended + `V3-RR-REML` in the in-code ladder.
- Rose audit — ran (verdict fix_then_merge); the two must-fix stale-deferral claims +
  the two missing DoD artifacts addressed; nit (comparator list) fixed.
- clean local checks — `Pkg.test()` (21/21, 36 status rows) + `docs/make.jl` exit 0.
- clean CI — gated on the PR (authoritative on a clean checkout).

## Review (3-lens adversarial, actual subagents)

- Henderson (mixed-model equations): verdict **correct** — confirmed the marginal V /
  REML criterion scale, the degree-0 `K_g[1,1]=2σ²a` mapping + reshape ordering
  (coefficient-fastest), and GLS-BLUP == MME for PD `K_g`, all by running Julia. Two
  nits (single-start convergence; a docstring cross-ref).
- Gauss (REML numerics): verdict **merge** — reproduced loglik == oracle (~6e-14),
  degree-0 reduction, and discriminating off-optimum gaps. should-fix: a non-finite
  objective screen (cholesky does not throw on a non-finite V) — **applied**; an
  `O(1/σ²e)` boundary-conditioning caveat — **documented**.
- Karpinski (Julia perf): verdict **merge** — dense `kron(A,K_g)` + dense ~98%-zero
  `W` per eval is the expected validation-scale cost; no perf claim is made. Logged as
  a measurement requirement before any future scale/perf claim (not a blocker).
- Rose (claim-vs-evidence): verdict **fix_then_merge** — reproduced all four
  substantive claims in Julia (tolerances conservative, no overclaim); status stays
  experimental/partial. must-fix: two stale "RR REML is a later slice" deferral
  claims + the two missing DoD artifacts — **all addressed**.

## Claim boundary

Dense/validation-scale REML; correctness is self-consistency + univariate-reduction +
independent-oracle validated. NOT validated: known-truth `K_g` recovery, external
comparator (WOMBAT/ASReml/JWAS) parity. No permanent-environment term; homogeneous
residual only; no R-facing model-spec or bridge payload. Nothing promoted to covered.

## Next

The highest-leverage solo engine action (from the ultracode synthesis) is the
multivariate `t ≥ 2` recovery rerun + `test/fixtures/multivariate_comparator/`
serialization (`#47/#49 ↔ R #10/#49`) — the flagship handoff the R lane is pre-staged
for. RR slice 4+ (eigen-function decomposition / permanent-environment / R `rr()`
spec) and a `K_g` recovery harness remain deferred.

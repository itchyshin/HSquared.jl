# Phase 4: multivariate REML (estimate G0/R0)

Active lenses: Gauss, Fisher, Kirkpatrick, Falconer, Mrode, Curie, Rose (inline).

## Goal

Estimate the multi-trait genetic and residual covariance matrices by REML — the
capability that makes multi-trait models useful beyond a supplied covariance.

## What landed

- `src/multivariate.jl`:
  - `fit_multivariate_reml(Y, X, Z, Ainv; initial, iterations, ids, traits)` —
    dense multivariate REML. `G0`, `R0` are parameterized by their lower Cholesky
    factors with log-diagonals (always positive definite); Nelder–Mead maximizes
    the REML log-likelihood of `V = Z(A⊗G0)Z' + R` (`R` block-diagonal over
    individuals, missing-record aware). Returns the estimated covariances, their
    correlations, per-trait `h²`, the breeding values and fixed effects at the
    estimate, the loglik, and convergence.
  - Shared helpers extracted: `_mv_observed`, `_mv_build_Vchol`,
    `_mv_reml_loglik_core`, `_mv_gls_blup`, `_multivariate_reml_loglik`.
  - **Robustness:** EBVs are computed via the GLS BLUP form
    `u = (A⊗G0)Z'V⁻¹(y−Xβ̂)`, which stays well-defined when `G0` is singular at a
    boundary optimum (`rg = ±1` or a zero variance). The first implementation
    routed EBVs through `multivariate_mme`, which requires strict PD and threw on
    boundary estimates; the GLS form fixed that.

## Validation

Committed (deterministic, RNG-free) — testset "Phase 4 multivariate REML
(estimate G0/R0)", 21 checks:

1. **t=1 reduction** — on the interior-optimum 8-animal fixture,
   `fit_multivariate_reml` recovers the univariate `fit_sparse_reml` estimate of
   `(σ²a, σ²e)` to <1%.
2. **REML loglik correctness** — `_multivariate_reml_loglik` (t=1) matches the
   univariate `sparse_reml_loglik` up to an additive constant (~1e-8 on a
   difference-of-differences).
3. **Grid-beating** — a two-trait fit's optimum loglik is ≥ a coarse `(G0, R0)`
   grid.
4. **EBV consistency** — the fit's breeding values equal `multivariate_mme` at the
   estimate (~1e-6, GLS vs MME solve).
5. Missing-record fit; supplied initial values; dimension guards; correlations in
   `[-1, 1]`; `h²` in `[0, 1]`.

`validation_status()` 26 → 27 (`V4-MV-REML`, partial).

One-off (not committed — the suite is RNG-free): a 12-replicate t=2 simulation
(n=400 half-sib design) recovers the generating covariances on average — mean
Ĝ0 ≈ [1.03, 0.61; 0.61, 2.25] vs true [1.0, 0.5; 0.5, 2.0]; mean R̂0 ≈ truth;
mean r̂g ≈ 0.40 vs 0.354; 12/12 converged. Single small samples can sit on a
boundary, as expected for REML with few effective degrees of freedom.

## Checks

- `Pkg.test()`: passed. `julia --project=docs docs/make.jl`: green (new REML docs
  section with an experimental-estimator warning admonition).

## Status surfaces (lockstep)

- `src/validation_status.jl`: new `V4-MV-REML` row; `V4-MULTIVARIATE` missing-field
  updated to point at it.
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`
  (`V4-MV-REML`).
- `docs/src/api.md`, `docs/src/changelog.md`, `docs/src/multivariate-models.md`,
  `docs/dev-log/check-log.md`, this report.

## Public claim audit (Rose, inline)

Allowed: an **experimental** dense multivariate REML estimator whose
**correctness** is established by self-consistency (univariate reduction, loglik
identity, grid-beating, EBV consistency). Every surface marks it experimental and
states that multi-trait **known-truth recovery is one-off only**, with no
external-comparator parity or adversarial review.

Blocked / not claimed: production-scale REML; a committed recovery harness;
covariance standard errors / likelihood-ratio tests; a published Mrode multi-trait
estimate; sommer/ASReml/JWAS parity; independent adversarial review (the workflow
could not run earlier this session — subagent session limits); the R-facing
multivariate model-spec.

## Coordination

Engine-internal; no bridge-contract change. Final slice of the stacked Phase-4
train (`main` ← #10 ← #11 ← #12 ← #14 ← this). Multivariate model-spec mapping is
an R-lane decision — to be raised in the coordination note.

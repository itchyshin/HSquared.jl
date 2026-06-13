# Decision needed: how to report heritability uncertainty (h² intervals)

Status: **resolved — logit-transform delta interval shipped as the experimental
default (same day); profile-likelihood and parametric-bootstrap remain future
alternatives.**
Date: 2026-06-13. Lens: Fisher (inference), Gauss (numerics), Curie (validation).

## Context

`hsquared` is, by name, a heritability package, but `heritability(fit)` currently
returns only a point estimate. The obvious next inference feature is a standard
error / confidence interval for h² = σ²a / (σ²a + σ²e).

`fit_ai_reml` already computes a 2×2 average-information (AI) matrix for
`(σ²a, σ²e)` (`src/likelihood.jl:403`); its inverse is the asymptotic
variance-component covariance, from which a delta-method h² SE follows:

    g = [σ²e, −σ²a] / (σ²a + σ²e)²,   Var(h²) ≈ gᵀ · inv(AI) · g.

## Why the naive version is NOT shippable

A local probe (`/tmp/hsq_h2ci_verify.jl`, not committed) on the 8-animal REML
fixture (σ̂²a = 1.321, σ̂²e = 0.226, ĥ² = 0.854) found:

1. **Degenerate on small data.** The VC covariance is ill-conditioned: SE(σ²a) =
   2.13 on an estimate of 1.32 (≈160%), giving a delta-method 95% h² CI of
   **[−0.55, 2.26]** — outside the valid [0, 1]. A symmetric delta interval
   ignores the boundary and is meaningless here.
2. **AI vs observed information diverge after inversion on small n.** The AI
   matrix and a finite-difference observed-information Hessian of the REML
   log-likelihood agree on the diagonal to ~1–9%, but the *inverse* (hence the
   h² SE) differs ~2× (AI 0.71 vs observed 1.52) because the matrix is
   near-singular. They only agree at large n (cf. the recorded 250-animal sim
   where AI ≈ observed to ~0.99).

## Options (pick before implementing)

- **Boundary-respecting interval.** Logit (or Fisher-z) transform h², build the
  symmetric delta interval on the transformed scale, back-transform → stays in
  (0, 1). Cheap, analytic.
- **Profile-likelihood interval.** Profile the REML log-likelihood over h²;
  asymmetric, boundary-aware, more faithful but more code.
- **Parametric bootstrap.** Most robust, no asymptotics; slowest; needs RNG
  (the suite is currently RNG-free).
- **Information choice.** AI vs observed vs expected — decide which, and require
  large-n validation (small-n SEs are unreliable regardless of method).

## Recommendation

Implement the **logit-transform delta interval** as the default experimental h²
interval (boundary-safe, analytic, reuses the AI matrix), validated on a large
seeded fixture against (a) the observed-information Hessian and (b) a parametric
bootstrap, with an explicit "asymptotic; unreliable at small n" caveat. Hold
until the user/Fisher confirms the approach — this is an inference-design call,
not a mechanical slice.

## Resolution (2026-06-13)

Shipped the **logit-transform delta interval** as the experimental default:
`heritability_interval(fit; level)` (+ `variance_component_covariance`,
`variance_component_standard_errors`, `heritability_standard_error`), built on the
REML AI matrix, with a self-contained Acklam standard-normal quantile. The
interval is always in `(0, 1)` by construction. Validated deterministically
(`test/runtests.jl`): AI matrix ≈ finite-difference REML Hessian (~8%), interval
contains the estimate and nests by level, quantile matches known z-values.

Still open as future work (recorded, not blocking): large-n **coverage
calibration**, **profile-likelihood** and **parametric-bootstrap** alternatives
(the latter needs RNG, which the suite currently avoids), and ML (non-REML)
information. The shipped interval is asymptotic and unreliable at small n — stated
in the docstring and capability rows.

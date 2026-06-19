# After-task — multivariate covariance SEs + LRTs (BT3 #47)

Date: 2026-06-19. Lane: Julia engine. Lenses: Gauss + Noether (numerics),
Fisher (inference), Curie (tests), Rose (claim gate). Closes the
V4-MV-REML / V4-FA "needs covariance SEs / LRTs" gap.

## What was done

Two exported, experimental functions in `src/multivariate.jl`:

- `multivariate_covariance_standard_errors(fit, Y, X, Z, Ainv; fd_step)` —
  asymptotic SEs for an **unstructured** multivariate REML fit. Observed
  information = central finite-difference Hessian of the REML log-likelihood on
  the log-Cholesky parameterization (the scale the optimizer uses); inverted and
  propagated by a finite-difference delta-method Jacobian to the genetic/residual
  covariances, the derived correlations, and the per-trait heritabilities.
- `covariance_structure_lrt(constrained, full)` — nested-structure LRT
  (`2Δℓ`, `df` = covariance-parameter difference, χ²`df` p-value). **Boundary
  aware**: interior null for `:diagonal`-in-`:unstructured` (off-diagonal genetic
  covariances = 0, sign-unconstrained); `boundary = true` for rank/PSD nulls
  (`:lowrank`/`:factor_analytic`), where the χ²`df` p-value is flagged
  asymptotically conservative (true null is a χ² mixture).
- A dependency-free χ² survival `_chisq_sf` (Lanczos `_loggamma` + regularized
  incomplete gamma series/continued-fraction), plus internal FD Hessian/Jacobian
  helpers. No new package dependency.

## Evidence (test/runtests.jl, +30 checks → suite 1822, exit 0)

- χ² survival matches textbook 5% critical values (df 1–4) and `_loggamma`
  matches Γ(5)=24, Γ(½)=√π.
- **Independent cross-check**: at `t=1` the SE for σ²a/σ²e from the
  log-Cholesky + delta-method path matches a from-scratch raw-(σ²a,σ²e)
  FD-Hessian SE (rtol 0.1) — validates the delta method.
- Interior `t=2` fixture (repeated records, n=24): finite, symmetric,
  non-negative SEs; PD information; correlation-SE diagonals = 0.
- LRT: `df` correct, statistic ≥ 0, p-value ∈ [0,1], `boundary` flag correct,
  p-value matches `_chisq_sf`.
- Honest small-n limitation pinned: at n=8 single-record the unstructured
  optimum is on the `rg→±1` boundary → information not PD → the function
  **throws** (SEs unavailable) rather than reporting a spurious number.

## Status discipline

Experimental, asymptotic, dense/validation-scale, not coverage-calibrated.
Structured-fit SEs intentionally absent (rotation-nonidentified loadings).
No capability moved to covered. Capability-status + V4-MV-REML/V4-FA rows updated.

## Next

BT2 bridge readiness (#42–#45) + remaining BT3 (#46 fitted Mrode, #48 calibrated
thresholds, #49 comparator fixtures), per the ultracode workflow.

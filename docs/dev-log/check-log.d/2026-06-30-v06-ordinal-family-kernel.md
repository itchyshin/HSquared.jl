# 2026-06-30 v0.6 ordered-categorical probit (ordinal threshold) family kernel (T1)

## Goal

Lens: Gauss/Noether (numerics) + Curie/Fisher (validation) + Rose (mandatory). Build the pure-Julia
**core of the v0.6 T1 ordinal-threshold arc** (calving ease): the ordered-categorical probit Laplace
family kernel. EXPERIMENTAL/`partial` (the established non-Gaussian-family pattern) — NOT a covered
claim, NO comparator committed, NO recovery gate; the comparator decision and joint cutpoint
estimation are deferred to the maintainer. Autonomous slice on branch
`feat/2026-06-30-v06-ordinal-family` (off `main`), staged for review — NOT merged.

## What was done

- **`src/nongaussian.jl`:** new `OrderedProbitResponse(thresholds)` `<: ResponseFamily` — K ordered
  categories on a standard-normal latent scale, `K-1` SUPPLIED strictly-increasing cutpoints `θ`,
  `P(y=k|η) = Φ(θ_k−η) − Φ(θ_{k-1}−η)`. Kernels `_fam_loglik/_fam_score/_fam_weight` (score
  `(φ(a)−φ(b))/P`; OBSERVED-information weight `score² − (a·φ(a)−b·φ(b))/P`, `>0` since ordered
  probit is log-concave — the binary-probit convention, not the beta-binomial Fisher substitution) +
  a tail-aware `_ordered_interval_prob` (computes `Φ(b)−Φ(a)` in the non-cancelling tail) + `_norm_cdf`
  with a `±∞` short-circuit + `_ord_bounds`/`_ord_pdf` helpers + `_check_counts` (integer `1:K`).
  Reuses the validated `_norm_logcdf`/`_norm_pdf`; no new deps; INTERNAL (not exported).
- **`test/runtests.jl`:** new testset "Phase 6 ordered-categorical probit … (T1, v0.6)" — the exact
  `K=2, θ=[0]` reduction to `BernoulliProbitResponse`, 3-category kernel gates (probs sum to 1,
  zero-mean score, score = central-FD, observed weight = −(second FD) `> 0`), the end-to-end marginal
  reduction, and guards. Count guard `length(validation) == 48 → 49` + a V6-ORDINAL row-content check.
- **Status (all three surfaces, `partial`):** `validation_status()` V6-ORDINAL row (48→49),
  `capability-status.md`, `validation-debt-register.md`.

## Commands / results

- Kernel smoke (pre-suite): reduction (loglik/score/weight) exact; multi-category probs=1,
  E[score]=0, score=dℓ, weight=−d²ℓ>0; end-to-end marginal Δ = 8.9e-16; guards throw.
- `julia --project=. -e 'using Pkg; Pkg.test()'` → PASS at count **49** (count guard + V6-ORDINAL
  row check + the T1 testset all green).
- `julia --project=docs docs/make.jl` → exit 0.

## Claim boundary

EXPERIMENTAL, `partial`, INTERNAL (not exported), dense/validation-scale, Laplace-only, SUPPLIED
thresholds only. `public-covered fitting = 1` UNCHANGED; NOT the public default; NOT wired to R;
NOT a covered claim. `validation_status()` 48→**49** (one new `partial` row; covered count UNCHANGED).
STILL OWED (deferred to the maintainer): joint cutpoint estimation, `:symbol` resolver + `fit_laplace_reml`
wiring, VA kernel, deep-tail log-space loglik, observation-/liability-scale h², a same-estimand
comparator (**`ordinal::clmm`** — glmmTMB does NOT fit cumulative-link ordinal models — MCMCglmm
`threshold` agreement-only), a recovery gate, and R activation. Real Rose audit pending.

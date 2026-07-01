# 20 · v0.6 T1 ordinal-threshold — covered-path design spec

Status: **design proposal** (Claude, 2026-06-30). Blueprint for taking the ordered-categorical
probit family from the experimental kernel ([#212](https://github.com/itchyshin/HSquared.jl/pull/212),
`V6-ORDINAL` `partial`) to a doc-16 covered claim. Proposes; promotes nothing. Companion to
`16-promotion-gate-predicates.md` (the covered bar) and `19-h2-scale-contract.md` (the h² scales).

## Where the kernel is now (#212)

`OrderedProbitResponse(thresholds)` (internal): K ordered categories on a standard-normal latent
scale, `K-1` **SUPPLIED** strictly-increasing cutpoints θ, `P(y=k|η) = Φ(θ_k−η) − Φ(θ_{k-1}−η)`.
Exact log-concave kernels (observed-information weight), validated by the K=2/θ=[0]→`BernoulliProbit`
reduction + finite-difference gates + an end-to-end marginal reduction. Consumable via
`laplace_marginal_loglik`. **Missing for covered:** joint cutpoint estimation, the R-reachable fit
surface, a same-estimand comparator, a recovery gate, and scale-labelled h².

## Step 1 — Joint cutpoint + variance estimation (the estimator)

The current kernel treats θ as fixed. Covered needs θ **estimated** jointly with σ²a.

**Identifiability (the load-bearing design point).** With a probit link the residual variance is fixed
at 1, and an intercept in η is confounded with a location shift of all cutpoints. The identified
parameterization fixes the location: **drop the intercept from `X`** (or equivalently fix `θ_1 = 0`)
and estimate `θ_2 < … < θ_{K-1}`, the fixed effects `β` (non-intercept), and `σ²a`. Enforce the
ordering by optimizing over **increments**: `θ_1 = 0`, `θ_j = θ_{j-1} + exp(δ_j)` for `j ≥ 2`, so the
unconstrained `δ ∈ ℝ^{K-2}` maps to a strictly-increasing θ (a standard cumulative-link reparam).

**Optimization.** Extend `fit_laplace_reml` to an outer optimize over `(log σ²a, δ)` of the Laplace
marginal `laplace_marginal_loglik(y, X, Z, Ainv, σ²a, OrderedProbitResponse(θ(δ)))` — the inner
penalized-IRLS Newton is unchanged (the kernel already exists). β is flat-integrated as today. Return
a `NonGaussianFit`-shaped object carrying `σ²a`, the estimated cutpoints, and the EBVs.

**Deterministic gates (in-suite, RNG-free):** (a) the `K=2` identified fit reduces to the existing
`:bernoulli_probit` `fit_laplace_reml` (same σ²a, same loglik) — the reduction oracle at the estimator
level; (b) the marginal at the returned optimum beats deliberately off-optimum `(σ²a, δ)` points;
(c) the estimated θ round-trip through the increment reparam.

## Step 2 — Same-estimand comparator (⚠ NOT glmmTMB)

**`glmmTMB` does NOT fit cumulative-link ordinal models.** The correct same-estimand tool is
**R `ordinal::clmm`** (Christensen) — a Laplace-ML cumulative-link mixed model:

```r
ordinal::clmm(ordered(y) ~ 1 + (1 | id), data = d, link = "probit")
```

Its `Theta` (cutpoints) and the `id` random-effect SD² map directly to the engine's `θ` and `σ²a`
(same probit latent scale, same Laplace-ML estimand). Protocol = the BLUPF90/sommer isolation-packet
pattern: serialize one deterministic fixture (`test/fixtures/ordinal_parity/`), fit with both, compare
cutpoints + σ²a + fixed effects. `MCMCglmm` `threshold` / `THRGIBBS` are Bayesian **agreement-only**
(never the same-estimand leg). This is a **Codex baton** (live R).

## Step 3 — Pre-declared recovery gate (doc-16 G11)

Mirror the genomic/MV precedent (`sim/phase6_threshold_recovery.jl` is the binary analogue). Pre-declare
BEFORE the run: a half-sib DGP with an ordered-categorical response (K = 3–4, e.g. calving-ease-like
cutpoints), q ≈ 300+ (ordinal is more informative than binary — a real reason K ≥ 3 helps), 48 cold-start
seeds; aggregate criteria: 48/48 converged, `|bias| ≤ 2·MCSE` on σ²a **and each estimated cutpoint**,
EBV accuracy floor, an MCSE ceiling. Read as "no detectable bias", never "unbiased". A pre-run
Curie/Fisher/Mendel panel (as in v0.4). Compute: Totoro.

## Step 4 — Scale-labelled h² (per doc-19)

Surface **latent-scale** h² = σ²a/(σ²a + 1) (probit residual = 1) and the **observation-scale** h² via
the QGglmm/de Villemereuil transform for a threshold trait (the liability-scale → observed-category
mapping; `19-h2-scale-contract.md` §threshold). Never a single unlabeled h².

## Step 5 — Surface + R activation (last)

Wire `:ordered_probit` into `_resolve_single_family` (carrying the `thresholds`/`K` contract, analogous
to `:binomial`'s `n_trials`), then `fit_laplace_reml`, then `nongaussian_result_payload` (a
`cutpoints` field, NO single h² — scale-labelled), then the R `hsquared` ordinal formula + a Julia-free
normalizer parity test. R activation is **engine-covered ≠ R-public-covered** — the R surface stays
experimental until its own gate.

## Sequencing + fences

1 (estimator) → 2 (comparator, Codex) ∥ 3 (recovery gate, Totoro) → doc-16 covered flip (maintainer G10)
→ 4/5 (h² + R, as-you-go). Steps 1/3 are Claude-solo pure-Julia; 2/5 need a Codex baton. **Do NOT start
Step 1 until #212 (the kernel) is reviewed/merged** — it builds directly on it. Public-covered fitting
stays **1** until the maintainer flips it; every step is experimental/`partial` until the gate passes.

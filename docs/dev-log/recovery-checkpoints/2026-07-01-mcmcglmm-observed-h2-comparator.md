# V6-NS-H2 — MCMCglmm external comparator for the OBSERVATION-scale h² (Poisson, A = I) — 2026-07-01

The **second** same-estimand EXTERNAL comparator for HSquared.jl's non-Gaussian
**observation-scale** heritability (`nongaussian_heritability`), discharging the **MCMCglmm**
item that doc-19 §5 and the QGglmm checkpoint
(`2026-07-01-qgglmm-probit-observed-comparator.md`) list as still owed. Complements the
deterministic QGglmm transform leg with an INDEPENDENT END-TO-END Bayesian fit. Promotes
nothing — V6-NS-H2 stays `partial`, `validation_status()` = 50 UNCHANGED, public-covered
fitting = 1 UNCHANGED.

## Distributional, not machine-precision (the honest frame)

Where the QGglmm leg feeds *identical* `(V_A, μ)` into two implementations of the *same closed
form* (agreement ~1e-6, a check on the transform math), this leg fits an MCMCglmm Poisson GLMM,
pushes the WHOLE posterior through the QGglmm transform, and asks whether the engine's
asymptotic point lands within the resulting posterior. MCMCglmm is Bayesian; the engine point is
an asymptotic Laplace-REML estimate; both share the Poisson-GLMM information limit. Agreement
means **"the engine's point sits within MCMC error of an independent Bayesian fit"** — NOT
machine precision, NOT a validation of unbiasedness.

## Setup
- DGP (`comparator/mcmcglmm_observed/generate.jl`, seed 20260701): **A = I / repeated-records**
  Poisson — N=300 individuals × 6 records = 1800, `a_i ~ N(0, σ²a=0.5)` iid (A=I ⇒ the animal
  effect IS an iid `id` random intercept), `μ=0.8`, `y_ij ~ Poisson(exp(μ + a_i))`, **no
  record-level over-dispersion**. Engine fit: `fit_laplace_reml(y, X, Z, Ainv=I; family=:poisson)`
  → `nongaussian_heritability(fit).h2_observation`.
- Comparator (`comparator/mcmcglmm_observed/run_mcmcglmm.R`): MCMCglmm 2.36 `count ~ 1,
  random = ~id, family = "poisson"`, units residual ESTIMATED; posterior transformed by
  **de Villemereuil's documented QGglmm workflow** (QGglmm 0.8.0 vignette *"Integrating over a
  posterior prediction"*): `var.a = VCV[,"id"]`, `var.p = rowSums(VCV)` (id + units),
  `QGparams(model="Poisson.log")` per draw. Chain 260000/60000/100 → 2000 samples. R 4.6.0.
- Reproduce (~2.5 min): run `generate.jl`, then `Rscript …/run_mcmcglmm.R 260000 60000 100`.

## Why Poisson + A = I + repeated records (the design rationale)
1. **A = I** makes the breeding value a plain iid `id` random effect — both engines fit the same
   random-intercept GLMM, no pedigree.
2. **Repeated records** identify σ²a for counts AND let MCMCglmm estimate its units
   (over-dispersion) residual SEPARATELY. With a no-over-dispersion DGP that residual → ~0, so
   `var.p = rowSums(VCV) ≈ V_A`, matching the engine's integration convention (predictor variance
   `V_A + V_fixed`; doc-19 §2.2). This removes the over-dispersion-scale gap that the fitting
   comparators (`comparator/poisson_mcmcglmm/`) can only report, not close.
3. **Poisson `var.p` is unambiguous** (no link constant added). The **probit route is a trap**
   (checked, not assumed): MCMCglmm's `threshold` model carries a fixed units residual of 1 that
   `rowSums(VCV)` would put in `var.p`, but the engine's validated `binom1.probit` uses
   `var.p = V_A` — `QGparams(var.p=V_A+1)` gives 0.102 vs the engine's 0.170 (μ=0.5, V_A=0.4),
   a large *convention* artifact unrelated to MCMC error. Poisson sidesteps it.

## Result (recorded run 2026-07-01)

| quantity | value |
|---|---|
| engine `sigma_a2` (Laplace REML) | 0.4939 (truth 0.5) |
| engine `mu` | 0.8153 (truth 0.8) |
| **engine `h2_observation` (POINT)** | **0.501739** |
| MCMCglmm V_id mean | 0.5018 |
| MCMCglmm V_units mean | **0.0132 (≈0 ⇒ var.p ≈ V_A)** |
| MCMCglmm `h2.obs` mean / median / sd | 0.485185 / 0.485982 / 0.016934 |
| MCMCglmm `h2.obs` 95% credible interval | **[0.449053, 0.515349]** |
| engine point vs posterior | **inside 95% CI**; +0.98 posterior SD; 83.5% of mass below |
| mixing | ESS[id]=455, ESS[units]=56 (2000 samples) |

**The engine's observation-scale h² point (0.5017) lies inside the MCMCglmm 95% credible
interval [0.4491, 0.5153]**, ~1 posterior SD above the posterior mean. The small +0.98-SD offset
is the tiny residual over-dispersion (V_units≈0.013) inflating `var.p` and nudging MCMCglmm's
posterior just below the engine's zero-over-dispersion point — the genuine Bayesian-vs-asymptotic
difference, not a transform error. `PASS`.

## Verdict / scope
The engine's Poisson observation-scale h² AGREES with an independent MCMCglmm Bayesian fit
+ QGglmm transform **within MCMC error** (engine point inside the 95% CI). This discharges the
**MCMCglmm** external-comparator item on V6-NS-H2 (doc-19 §5), as a DISTRIBUTIONAL agreement.

STILL OWED for the row's covered path: the QGglmm comparator for the **ordinal (K>2)** and
**Gamma (data)** observation scales (non-builtin); a **Fisher/Falconer** sign-off on the exact
decomposition; the single-trial Bernoulli bias correction; intervals/SEs; an R-facing surface;
and the maintainer **G10**. This is ONE design, ONE family (Poisson), validation-scale, opt-in.
NOT a covered claim; `validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED.

## Tooling banked
- **MCMCglmm 2.36** installed (CRAN 2026-07-01, macOS arm64 binary) — the Bayesian GLMM engine
  for the end-to-end h² comparator; joins **QGglmm 0.8.0** (the transform reference).

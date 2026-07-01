# MCMCglmm observation-scale h² comparator (V6-NS-H2, the MCMCglmm leg)

The second same-estimand EXTERNAL comparator for HSquared.jl's non-Gaussian
**observation-scale** heritability (`nongaussian_heritability`), complementing the
deterministic QGglmm transform comparator (`comparator/qgglmm_probit_observed/`).
It discharges the **MCMCglmm** item that doc-19 §5 and the QGglmm checkpoint list
as still owed.

Where the QGglmm comparator feeds *identical* `(V_A, μ)` into two implementations of
the *same closed-form transform* (agreement to ~1e-6 — a check on the transform
math), this comparator runs an **independent END-TO-END Bayesian fit**: it fits an
MCMCglmm Poisson GLMM to a simulated dataset, pushes the whole posterior through the
QGglmm transform, and asks whether the engine's asymptotic point estimate lands
within the resulting posterior.

> **DISTRIBUTIONAL agreement, NOT machine precision, NOT unbiasedness.** MCMCglmm is
> Bayesian; the engine point is an asymptotic Laplace-REML estimate. Both share the
> Poisson-GLMM information limit, so "agreement" here means *the engine's point sits
> within MCMC error of an independent Bayesian fit* — nothing stronger. This is
> deliberately weaker than the QGglmm leg and promotes nothing.

## Why this design (A = I / repeated records, Poisson)

- **A = I** ⇒ the additive breeding value is a plain iid random intercept, identical
  to an `id` random effect in MCMCglmm. No pedigree is needed; both engines fit the
  same random-intercept GLMM.
- **Repeated records** per individual (i) identify σ²a for count data and (ii) let
  MCMCglmm estimate its latent units (over-dispersion) residual *separately* from
  σ²a. The DGP has **no** record-level over-dispersion, so that residual concentrates
  near 0 and MCMCglmm's `var.p = rowSums(VCV) ≈ V_A`.
- **Poisson (log link)** is the family whose `var.p` convention is *unambiguous*: for
  `Poisson.log` no link constant is added to `var.p` (QGglmm vignette). The probit
  route is a trap — MCMCglmm's `threshold` model reports a fixed units residual of 1
  that de Villemereuil's `rowSums(VCV)` recipe would put into `var.p`, whereas the
  engine's validated `binom1.probit` uses `var.p = V_A` (predictor variance) — a large
  *convention* artifact unrelated to MCMC error. Poisson avoids it entirely, so the
  only latent-scale difference from the engine is the genuine (≈0) over-dispersion.

## Two steps

```sh
PATH="$HOME/.juliaup/bin:$PATH" julia --project=. comparator/mcmcglmm_observed/generate.jl
Rscript comparator/mcmcglmm_observed/run_mcmcglmm.R [nitt burnin thin]
```

`generate.jl` simulates a deterministic A = I / repeated-records Poisson dataset
(N=300 individuals × 6 records, σ²a=0.5, μ=0.8, seed 20260701), fits
`fit_laplace_reml(family=:poisson)` with `Ainv = I`, and serializes `data.csv` (long
format) and `engine_h2.csv` (the engine's `h2_observation` point + σ²a + μ + design).

`run_mcmcglmm.R` fits `count ~ 1, random = ~id, family = "poisson"`, transforms the
posterior to the observation scale via de Villemereuil's documented QGglmm workflow
(QGglmm vignette *"Integrating over a posterior prediction"*: `var.a = VCV[,"id"]`,
`var.p = rowSums(VCV)`, `QGparams(model="Poisson.log")` per draw), and reports the
posterior of `h2.obs`, its 95% credible interval, and where the engine point falls.

## What is / isn't comparable

- **The engine `h2_observation` point falling inside the MCMCglmm 95% credible
  interval is the agreement metric** — a distributional (within-MCMC-error) check.
- **It is not a machine-precision identity** (that is the QGglmm leg's job) and **not
  a validation of unbiasedness**: both methods inherit the same Poisson-GLMM
  information limit.

## Boundary

Bayesian/MCMC agreement at validation scale, **one design, one family (Poisson)**.
NOT a same-estimand REML parity, NOT interval calibration, NOT a covered-status
promotion. V6-NS-H2 stays `partial`; `validation_status()` = 50 UNCHANGED;
public-covered fitting = 1 UNCHANGED. Still owed on the row's covered path: the
QGglmm comparator for the ordinal(K>2)/Gamma-data observation scales, a Fisher/
Falconer sign-off, and the maintainer G10. Generated CSVs are git-ignored; the
recorded numbers live in `docs/dev-log/recovery-checkpoints/`.

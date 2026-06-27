# NotebookLM scout: SW/Satterthwaite calibration for mixed-model intervals

Date: 2026-06-27

Notebook:
`Fast & Accurate Algorithms for Mixed & Latent-Variable Model Fitting (HSquared · DRM · GLLVM)`
(`3b3d2ec5-7779-41ee-b968-22623c80278b`).

Status: method scout note. No HSquared.jl interval implementation, default, R
surface, or public claim changes.

## Query

NotebookLM was asked for algorithmic notes relevant to small-sample Gaussian
animal-model intervals, t calibration, Satterthwaite/Welch degrees of freedom,
Kenward-Roger corrections, variance-component or heritability intervals, and
mixed-model REML inference.

## Relevant Notebook Sources

The notebook source list includes:

- `A Corrected Welch-Satterthwaite Equation. And: What You Always Wanted to Know
  About Kish's Effective Sample Size but Were Afraid to Ask.`
- `An Improved Satterthwaite Effective Degrees of Freedom Estimator for Weighted
  Syntheses of Variance.`
- `Denominator degrees of freedom for mixed models - Stata.`
- `Kenward-Roger` (mmrm vignette).
- `Kenward-Roger approximation for linear mixed models with missing covariates.`
- `Small-Sample Confidence Intervals for Variance Components and Random-Effect
  Parameters in Hierarchical and Latent-Variable Models.`
- `Restricted Maximum Likelihood Estimation in Generalized Linear Mixed Models.`

## Takeaways for HSquared.jl

1. REML remains the correct base estimator for this slice. The notebook frames
   REML as the finite-sample correction to ML variance-component downward bias.
2. For variance components, plain Wald intervals are structurally weak in small
   samples: symmetric, boundary-insensitive, and dependent on asymptotic SEs.
   Profile likelihood and parametric bootstrap remain the stronger interval
   families.
3. Satterthwaite/Welch logic is relevant, but for variance components the
   natural form is a method-of-moments effective df for a scaled chi-square
   reference distribution, not necessarily a t interval.
4. Kenward-Roger and most mixed-model Satterthwaite denominator-df machinery in
   software primarily targets fixed-effect t/F inference. It adjusts
   denominator df and, for KR, inflates the fixed-effect covariance matrix to
   reflect variance-component uncertainty. That is not the same target as
   `sigma_a2` or `h2` intervals.
5. Boundary-proximal behaviour is a risk. If the additive variance estimate is
   near zero, df approximations can become unstable and must report failures or
   clamps rather than silently returning confident intervals.

## Candidate Implications

The current `residual_df_probe` and `family_df_probe` are baselines, not serious
final candidates.

More defensible next candidates:

- `sigma_a2_satterthwaite_chisq_probe`: moment-match the additive-variance
  estimator to a scaled chi-square distribution, with
  `df_eff = 2 * estimate^2 / Var(estimate)` as the starting probe. This needs a
  chi-square quantile path and explicit boundary guards.
- `h2_satterthwaite_delta_probe`: only a lower-priority exploratory candidate.
  Heritability is a bounded ratio, so directly borrowing a variance-component df
  is not justified without simulation evidence.
- `fixed_effect_satterthwaite` / `fixed_effect_kenward_roger`: out of scope for
  `V1-HERIT-TCAL` unless HSquared.jl later adds fixed-effect interval tests or
  R-facing fixed-effect inference.

## Decision Boundary

Do not implement a public t-calibrated animal-model interval from the NotebookLM
analogy alone. The safe next step is a prototype-only Satterthwaite/scaled-chi
probe inside the simulation harness, followed by the predeclared coverage grid.
Only coverage evidence can decide whether it survives.

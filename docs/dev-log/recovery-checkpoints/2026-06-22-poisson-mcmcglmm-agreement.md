# Recovery checkpoint — Poisson MCMCglmm agreement comparator (#44 gate 2)

Date: 2026-06-22 · lane: Julia engine (`HSquared.jl`) · status: **Bayesian/MCMC
agreement, `partial` — no promotion**

## What

Independent **MCMCglmm** (Bayesian) cross-method check of the engine's Poisson
(log-link) animal-model fit. Companion to the binomial comparator
(`2026-06-22-binomial-mcmcglmm-agreement.md`). **Agreement on breeding values,
not same-estimand REML parity** — the same-estimand REML comparator gate
(BLUPF90/AIREMLF90/ASReml/WOMBAT) remains open (executables absent).

## How

`comparator/poisson_mcmcglmm/generate.jl` (engine target + data) +
`comparator/poisson_mcmcglmm/run_mcmcglmm.R` (MCMCglmm fit + comparison).

- Design: deterministic half-sib, q=345, `u ~ N(0, A·σ²a)` log-scale, σ²a=1.0,
  μ=0, `y ~ Poisson(exp(μ+u))` (mean count 1.77), seed 20260622.
- Engine: `fit_laplace_reml(...; family = :poisson)`.
- MCMCglmm: `count ~ 1`, `random = ~animal`, `family = "poisson"`, standard
  Henderson A-inverse from the pedigree, units residual fixed `R = 1`,
  parameter-expanded prior on the additive variance, `pr = TRUE`. Chain
  `nitt=130000, burnin=30000, thin=100` (1000 samples).

## Result (julia 1.10.0 / MCMCglmm 2.36)

| quantity | value |
| --- | --- |
| engine σ²a (Laplace REML, no units residual) | 0.8360 |
| MCMCglmm animal variance (latent, R fixed=1) | mean 0.3033, 95% HPD [0.0835, 0.5566], ESS 1000 |
| **EBV correlation (engine vs MCMCglmm, n=345)** | **0.9275** |

## Interpretation

- **Strong cross-method agreement on breeding values** (EBV cor 0.928; ESS 1000,
  well-mixed) — the engine's Poisson EBVs match an independent Bayesian fit.
- The engine σ²a (0.836) shows the mild Laplace-for-Poisson downward bias already
  documented (`sim/phase6_poisson_recovery.jl`, rel ≤ 0.323).
- **Additive-variance magnitudes are NOT directly comparable** (0.836 vs 0.303):
  MCMCglmm's Poisson latent scale carries a fixed units residual (`R = 1`) the
  engine's Laplace Poisson does not. The EBV correlation is the scale-robust metric.

## Boundary

Bayesian agreement at validation scale, one design. NOT same-estimand REML
parity, NOT interval calibration, NOT a covered-status promotion. Non-Gaussian
stays `partial` (`V6-LAPLACE`/`VA`). Generated CSVs git-ignored.

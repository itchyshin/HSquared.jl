# Recovery checkpoint — Binomial MCMCglmm agreement comparator (#44 gate 2)

Date: 2026-06-22 · lane: Julia engine (`HSquared.jl`) · status: **Bayesian/MCMC
agreement, `partial` — no promotion**

## What

An independent **MCMCglmm** (Bayesian) cross-method check of the engine's
per-record varying-trial Binomial animal-model fit (`BinomialVectorResponse`;
R activation in itchyshin/hsquared#101). This is **agreement on breeding values**,
**not** same-estimand REML parity — the same-estimand REML comparator gate
(BLUPF90/AIREMLF90/ASReml/WOMBAT) remains open (executables absent).

## How

`comparator/binomial_mcmcglmm/generate.jl` (engine target + data) +
`comparator/binomial_mcmcglmm/run_mcmcglmm.R` (MCMCglmm fit + comparison).

- Design: deterministic half-sib, q=345, `u ~ N(0, A·σ²a)` logit, σ²a=1.0, μ=0,
  per-record `nₐ ~ U{1..30}` (mean n=15.1), seed 20260622.
- Engine: `fit_laplace_reml(...; family = :binomial, n_trials = nt)`.
- MCMCglmm: `cbind(successes, failures) ~ 1`, `random = ~animal`,
  `family = "multinomial2"`, standard Henderson A-inverse from the pedigree,
  units residual fixed `R = 1`, parameter-expanded prior on the additive
  variance, `pr = TRUE`. Chain `nitt=130000, burnin=30000, thin=100` (1000
  samples).

## Result (julia 1.10.0 / MCMCglmm 2.36)

| quantity | value |
| --- | --- |
| engine σ²a (Laplace REML, no units residual) | 0.9512 |
| MCMCglmm animal variance (latent, R fixed=1) | mean 0.3352, 95% HPD [0.1574, 0.5464], ESS 1139 |
| **EBV correlation (engine vs MCMCglmm, n=345)** | **0.895** |

(A short `nitt=13000` chain gave EBV cor 0.896 / animal var 0.340 — stable.)

## Interpretation

- **Strong cross-method agreement on breeding values** (EBV cor 0.895; ESS 1139,
  well-mixed): the engine's per-record varying-trial Binomial EBVs match an
  independent Bayesian fit.
- **The additive-variance magnitudes are NOT directly comparable.** MCMCglmm's
  binomial latent scale carries a fixed units residual (`R = 1`) the engine's
  Laplace binomial does not, so the two `σ²a` sit on different latent scales
  (0.951 vs 0.335). This is the overdispersion-residual convention, not a
  substantive disagreement; the EBV correlation is the scale-robust metric.

## Boundary

Bayesian agreement at validation scale on one design. NOT same-estimand REML
parity, NOT interval calibration, NOT a covered-status promotion. Non-Gaussian
stays `partial` (`V6-LAPLACE`/`VA`). Generated data/result CSVs are git-ignored
(regenerable). The `V6-BINOMIAL` register note for this evidence is a merge-time
follow-up (deferred here to avoid a cross-PR conflict with the gradient PR #155,
which edits the same row).

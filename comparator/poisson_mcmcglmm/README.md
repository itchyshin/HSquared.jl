# Poisson MCMCglmm agreement comparator (#44 gate 2)

Opt-in cross-method check for the **Poisson (log-link)** animal model. Compares
the engine `fit_laplace_reml(...; family = :poisson)` fit against an independent
**MCMCglmm** (Bayesian) fit of the same data. Companion to
`comparator/binomial_mcmcglmm/`.

**Bayesian/MCMC AGREEMENT, NOT same-estimand REML parity.** The same-estimand
REML comparator gate (BLUPF90/AIREMLF90/ASReml/WOMBAT) remains open (executables
absent).

## Two steps

```sh
PATH="$HOME/.juliaup/bin:$PATH" julia --project=. comparator/poisson_mcmcglmm/generate.jl
Rscript comparator/poisson_mcmcglmm/run_mcmcglmm.R [nitt burnin thin]
```

`generate.jl` simulates a deterministic Poisson animal model (q=345 half-sib,
σ²a=1.0 log-scale, μ=0, seed 20260622), fits `fit_laplace_reml(family=:poisson)`,
and serializes the data, pedigree, and engine target (σ²a, EBVs).
`run_mcmcglmm.R` fits `count ~ 1`, `random = ~animal`, `family = "poisson"` on the
same pedigree (standard Henderson A-inverse) and compares.

## What is / isn't comparable

- **EBV correlation is the scale-robust agreement metric** (primary).
- **Additive-variance magnitudes are NOT directly comparable**: MCMCglmm's Poisson
  latent scale carries a fixed units residual (`R = 1`) that the engine's Laplace
  Poisson does not, so the two `σ²a` sit on different latent scales. The gap is the
  overdispersion-residual convention, not a substantive disagreement.

## Boundary

Bayesian agreement at validation scale, one design. NOT same-estimand REML
parity, NOT interval calibration, NOT a covered-status promotion. Non-Gaussian
stays `partial` (`V6-LAPLACE`/`VA`). Generated CSVs are git-ignored; recorded
numbers live in the recovery checkpoint.

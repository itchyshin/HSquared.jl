# Binomial MCMCglmm agreement comparator (#44 gate 2)

Opt-in cross-method check for the **per-record varying-trial Binomial** animal
model (engine `BinomialVectorResponse`; R activation in itchyshin/hsquared#101).
It compares the engine `fit_laplace_reml` fit against an independent **MCMCglmm**
(Bayesian) fit of the same data.

**This is Bayesian/MCMC AGREEMENT, NOT same-estimand REML parity.** The
same-estimand REML comparator gate (BLUPF90/AIREMLF90/ASReml/WOMBAT) remains open
— those executables are absent on this machine.

## Two steps

```sh
# 1. engine target + data (Julia 1.10; juliaup on PATH)
PATH="$HOME/.juliaup/bin:$PATH" julia --project=. comparator/binomial_mcmcglmm/generate.jl

# 2. MCMCglmm fit + comparison (R; MCMCglmm + Matrix)
Rscript comparator/binomial_mcmcglmm/run_mcmcglmm.R [nitt burnin thin]
```

`generate.jl` simulates a deterministic per-record varying-trial Binomial animal
model (q=345 half-sib, σ²a=1.0 logit, μ=0, `nₐ ~ U{1..30}`, seed 20260622), fits
`fit_laplace_reml(...; family = :binomial, n_trials = nt)`, and serializes the
data, pedigree, and engine target (σ²a, EBVs). `run_mcmcglmm.R` fits
`cbind(successes, failures) ~ 1`, `random = ~animal`, `family = "multinomial2"`
on the same pedigree (standard Henderson A-inverse) and compares.

## What is and isn't comparable

- **EBV correlation is the scale-robust agreement metric.** Recorded run (full
  chain, ESS ≈ 1139): **cor(engine EBV, MCMCglmm EBV) ≈ 0.895** on 345 animals.
- **Additive-variance magnitudes are NOT directly comparable.** MCMCglmm's
  binomial latent scale carries a fixed units residual (`R = 1`, the standard
  MCMCglmm binomial setup) that the engine's Laplace binomial does not, so the
  two `σ²a` live on different latent scales (recorded: engine 0.951 vs MCMCglmm
  animal variance ≈ 0.335 [0.157, 0.546]). The gap is the overdispersion-residual
  convention, not a substantive disagreement; do not read it as variance parity.

## Boundary

Bayesian agreement on breeding values at validation scale, one design. NOT
same-estimand REML parity, NOT interval calibration, NOT a covered-status
promotion. Non-Gaussian stays `partial` (`V6-LAPLACE`/`VA`). Generated data and
result CSVs are git-ignored (regenerable); the recorded numbers live in
`docs/dev-log/recovery-checkpoints/2026-06-22-binomial-mcmcglmm-agreement.md`.

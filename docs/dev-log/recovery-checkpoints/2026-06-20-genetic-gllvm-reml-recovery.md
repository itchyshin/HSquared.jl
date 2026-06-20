# Genetic-GLLVM REML — known-truth recovery checkpoint (2026-06-20)

Opt-in harness: `sim/phase6_gllvm_recovery.jl` (outside CI; the committed suite stays
RNG-free). This records the FIRST known-truth recovery evidence for the genetic-GLLVM
REML estimator (`fit_gllvm_laplace_reml`).

## Design (ADEMP-style)

- **Data-generating process:** half-sib pedigree (`nsire=20, ndam=40, noffspring=180`,
  `q=240`); `A = inv(Ainv)`; `K=1` genetic latent factor `g ~ N(0, A)`;
  `η[i,t] = μ + Λ[t]·g[i]` with **truth `Λ = [1.0, 0.7, 0.5]`** (`T=3`, `K=1`), `μ=1.0`;
  `y[i,t] ~ Poisson(exp(η[i,t]))` (Knuth sampler).
- **Estimand:** the rotation-INVARIANT among-trait genetic covariance
  `G_lat = ΛΛ'` (a `3×3` rank-1 matrix). The loadings themselves are
  rotation-nonidentified, so recovery is measured on `G_lat`, NOT on `Λ`.
- **Method:** `fit_gllvm_laplace_reml(Y, Ainv, PoissonResponse(); rank=1)` (NelderMead
  over `vec(Λ)` maximizing the K-factor Laplace marginal).
- **Performance metric:** relative Frobenius error `rel = ‖Ĝ − G‖_F / ‖G‖_F` per seed,
  plus the per-trait variance recovery `diag(Ĝ)` vs `diag(G)`.
- **Predeclared:** seeds `20260620..20260624`; loose gate `rel ≤ 0.45 AND converged`.

## Result (RAN — 2026-06-20)

| seed | q | converged | rel(G_lat) | diag(Ĝ) vs diag(G) = [1.0, 0.49, 0.25] |
| --- | --- | --- | --- | --- |
| 20260620 | 240 | true | 0.0405 | [1.022, 0.525, 0.227] |
| 20260621 | 240 | true | 0.1428 | [0.810, 0.442, 0.272] |
| 20260622 | 240 | true | 0.0191 | [1.011, 0.502, 0.259] |
| 20260623 | 240 | true | 0.0716 | [1.033, 0.564, 0.245] |
| 20260624 | 240 | true | 0.1825 | [1.226, 0.534, 0.290] |

**mean `rel(G_lat) = 0.091`; passed 5/5** (`rel ≤ 0.45 AND converged`).

## Honest interpretation

- **Positive:** the genetic-GLLVM REML **recovers the rank-1 Poisson `G_lat` well** —
  ~9% mean relative Frobenius error, 5/5 seeds, with per-trait variances tracking
  truth. This is genuine known-truth recovery evidence, not just a correctness check.
- **Scope / caveats (NOT a broad claim):** this is ONE specific setup — **rank-1,
  Poisson, `q=240`, `T=3`, one family, balanced/fully-observed**. It is NOT a broad
  multi-rank / multi-family / FA(+Ψ) calibration, NOT an external-comparator parity, and
  the loadings remain rotation-nonidentified (recovery is on `G_lat`). With a rank-1
  truth the implied among-trait genetic correlations are `±1` by construction, so the
  correlations are not a recovery target here. Higher ranks, the FA structure, smaller
  `q`, and Bernoulli/Binomial (where the single-trial variance is downward-biased) are
  expected to be harder and are left to future predeclared runs.
- **Status:** `V6-GGLLVM-REML` stays `partial` — this strengthens its evidence (first
  recovery study, positive) but does not promote it to `covered` (which still requires
  broad calibration + an external comparator).

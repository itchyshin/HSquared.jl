# Recovery checkpoint — Binomial information gradient (#44 gate 2 evidence)

Date: 2026-06-22 · lane: Julia engine (`HSquared.jl`) · status: **descriptive
characterization, `partial` — no promotion**

## What

Demonstrates the **information effect** that motivates the per-record
varying-trial activation (#44 gate 1, hsquared PR #101): how Laplace-REML
recovery of the latent additive variance `σ²a` improves as Bernoulli trials per
record grow. The same estimator and the same simulated breeding values `u` are
reused across an `n_trials` ladder, so each rung differs only in trials/record.

This is the gradient that ties together the two existing single-point recovery
gates (`sim/phase6_bernoulli_recovery.jl` at m = 1;
`sim/phase6_binomial_recovery.jl` at common m = 20 and per-record n ∈ 1:30).

## How

Script: `sim/phase6_binomial_information_gradient.jl` (opt-in, outside CI — uses
RNG; descriptive, not a CI pass/fail gate).

```sh
PATH="$HOME/.juliaup/bin:$PATH" JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  OMP_NUM_THREADS=1 julia --project=. sim/phase6_binomial_information_gradient.jl
```

ADEMP: half-sib pedigree (15 sires, 30 dams, 300 offspring; q = 345);
`u ~ N(0, A·σ²a)` on the logit scale, σ²a = 1.0, μ = 0.0; per rung m,
`yₐ ~ Binomial(m, logistic(μ + uₐ))`; per-record rung draws `nₐ ~ U{1..30}`
(the general `cbind(successes, failures)` GLMM via `BinomialVectorResponse`).
Estimand σ²a + EBV cor(û, u); method `fit_laplace_reml(...; family = :binomial,
n_trials = m)`; performance = mean over seeds `[20260618 … 20260622]`.

## Results (julia 1.10.0, 5 seeds)

| trials/rec | mean σ̂²a (truth 1.0) | mean rel-bias | mean cor(û,u) | converged |
| --- | --- | --- | --- | --- |
| 1 (Bernoulli) | 0.583 | 0.417 | 0.623 | 5/5 |
| 2 | 0.747 | 0.253 | 0.687 | 5/5 |
| 5 | 0.955 | 0.131 | 0.786 | 5/5 |
| 10 | 1.018 | 0.094 | 0.855 | 5/5 |
| 20 | 0.951 | 0.085 | 0.908 | 5/5 |
| per-record n ∈ 1:30 (mean n = 15.2) | 0.954 | 0.139 | 0.869 | 5/5 |

Gradient: mean rel-bias(σ̂²a) **0.417 → 0.085** from m = 1 to m = 20; EBV
cor **0.623 → 0.908**. All rungs converged 5/5.

## Interpretation

- The single-trial Bernoulli endpoint is sharply **downward-biased** (σ̂²a ≈ 0.58
  vs truth 1.0) — the classic binary-data information limit, not an estimator
  flaw. Bias shrinks monotonically as trials/record grow.
- The **per-record varying-trial case** (the newly-activated R path / engine
  `BinomialVectorResponse`) recovers σ²a well (σ̂²a ≈ 0.95, rel ≈ 0.14, cor ≈ 0.87),
  consistent with its mean trial count (~15) sitting between the m = 10 and
  m = 20 rungs.

## Boundary (honest status)

Descriptive recovery characterization on a single half-sib design at validation
scale. **NOT** a CI gate, **NOT** external comparator evidence (no
gllvm/MCMCglmm/ASReml/BLUPF90 parity), **NOT** interval calibration, and **NOT**
a covered-status promotion. Non-Gaussian remains `partial` (`V6-LAPLACE`/`VA`).
The remaining gate-2 items are an external agreement comparator (MCMCglmm,
Bayesian — not same-estimand REML parity) and interval calibration (binomial
intervals do not yet exist in the engine; `laplace_reml_interval` is Poisson-only).

# Genetic-GLLVM REML — known-truth recovery checkpoint (2026-06-20)

Opt-in harness: `sim/phase6_gllvm_recovery.jl` (outside CI; the committed suite stays
RNG-free). The FIRST known-truth recovery evidence for the genetic-GLLVM REML estimator
(`fit_gllvm_laplace_reml`), now across TWO scenarios (rank-1 and rank-2).

## Design (ADEMP-style)

- **DGP:** half-sib pedigree; `A = inv(Ainv)`; `K` genetic latent factors
  `g[·,k] ~ N(0, A)`; `η[i,t] = μ + Σ_k Λ[t,k] g[i,k]`; `y[i,t] ~ Poisson(exp(η))`
  (Knuth sampler); `μ = 1.0`.
- **Estimand:** the rotation-INVARIANT `G_lat = ΛΛ'` (loadings rotation-nonidentified,
  so recovery is on `G_lat`).
- **Method:** `fit_gllvm_laplace_reml(...; rank = K)`.
- **Metrics:** relative Frobenius error `rel = ‖Ĝ − G‖_F / ‖G‖_F`; for the rank-2
  scenario also the mean off-diagonal genetic-correlation error `mean |ρ̂ − ρ|`.
- **Loose gate:** `rel ≤ 0.45 AND converged`.

## Results (RAN — 2026-06-20)

### Scenario A — rank-1 (`K=1`), `q=240`, `Λ = [1.0, 0.7, 0.5]`

| seed | rel(G_lat) |
| --- | --- |
| 20260620 | 0.0405 |
| 20260621 | 0.1428 |
| 20260622 | 0.0191 |
| 20260623 | 0.0716 |
| 20260624 | 0.1825 |

**mean `rel(G_lat) = 0.091`; 5/5 passed.** (Rank-1 ⇒ `±1` genetic correlations by
construction, so recovery is assessed on `G_lat`.)

### Scenario B — rank-2 (`K=2`, NON-degenerate ρ), `q=120`, `Λ = [1 0; 0.5 0.8; 0.3 0.9]`

| seed | rel(G_lat) | mean \|Δρ\| |
| --- | --- | --- |
| 20260620 | 0.2510 | 0.1816 |
| 20260621 | 0.1558 | 0.0719 |
| 20260622 | 0.2669 | 0.0374 |
| 20260623 | 0.1875 | 0.0249 |
| 20260624 | 0.1628 | 0.1280 |

**mean `rel(G_lat) = 0.205`, mean `|Δρ| = 0.089`; 5/5 passed.**

## Honest interpretation

- **Positive:** the genetic-GLLVM REML recovers `G_lat` across BOTH a rank-1
  (`rel ≈ 0.09`) and a genuine rank-2, non-degenerate-correlation structure
  (`rel ≈ 0.20`, **genetic correlations recovered to `|Δρ| ≈ 0.09`**) — real
  known-truth recovery, with graceful degradation as the structure hardens / `q`
  shrinks (rank-2 here uses the smaller `q=120`).
- **Scope / caveats (NOT a broad claim):** Poisson only, balanced/fully-observed,
  loadings rotation-nonidentified (recovery on `G_lat`). NOT a factor-analytic(+Ψ)
  recovery, NOT Bernoulli/Binomial (where the single-trial variance is downward-biased),
  NOT an external-comparator parity, and the rank-2 correlation error at `q=120` (some
  seeds `0.13–0.18`) would tighten with larger `q`. These are left to future predeclared
  runs.
- **Status:** `V6-GGLLVM-REML` stays `partial` — this strengthens its evidence (two
  positive recovery scenarios incl. correlation recovery) but does not promote it to
  `covered` (which still requires FA/family breadth + an external comparator).

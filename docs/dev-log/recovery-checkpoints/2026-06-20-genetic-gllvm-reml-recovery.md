# Genetic-GLLVM integrated-Laplace: oracle-start exploratory checkpoint (2026-06-20)

Opt-in simulation script: `sim/phase6_gllvm_recovery.jl` (outside CI; the committed suite stays
RNG-free). Every fit in this exploratory study starts from the true loadings.
`fit_gllvm_laplace_reml`: every fit starts from the true loadings. It covers four
scenarios: two Poisson (rank-1 and rank-2), one Bernoulli rank-1, and one
Binomial(20) rank-1. It does not establish ordinary-start recovery, signed bias,
EBV-rank accuracy, or a causal explanation for differences between families.

## Design (ADEMP-style)

- DGP: half-sib pedigree; `A = inv(Ainv)`; `K` genetic latent factors
  `g[·,k] ~ N(0, A)`; `η[i,t] = μ + Σ_k Λ[t,k] g[i,k]`; response sampled from the
  chosen family (Poisson: Knuth sampler; Bernoulli/Binomial: logistic link).
- Estimand: the rotation-invariant `G_lat = ΛΛ'` (loadings rotation-nonidentified,
  so recovery is on `G_lat`).
- Method: `fit_gllvm_laplace_reml(...; rank = K, initial = copy(Λtrue))` (oracle start).
- Metrics: relative Frobenius error `rel = ‖Ĝ − G‖_F / ‖G‖_F`; for the rank-2
  scenario also the mean off-diagonal genetic-correlation error `mean |ρ̂ − ρ|`.
- Loose gate for scenarios A, B, and D: `rel ≤ 0.45 AND converged`.
- Scenario C (Bernoulli): reported descriptively; these five oracle-start replicates
  are descriptive and do not establish bias direction.

## Results (run 2026-06-20)

### Scenario A: Poisson rank-1 (`K=1`), `q=240`, `Λ = [1.0, 0.7, 0.5]`, `μ = 1.0`

| seed | rel(G_lat) |
| --- | --- |
| 20260620 | 0.0405 |
| 20260621 | 0.1428 |
| 20260622 | 0.0191 |
| 20260623 | 0.0716 |
| 20260624 | 0.1825 |

Mean `rel(G_lat) = 0.091`; 5/5 passed. Rank-1 gives `±1` genetic correlations by
construction, so recovery is assessed on `G_lat`.)

### Scenario B: Poisson rank-2 (`K=2`, non-degenerate ρ), `q=120`, `Λ = [1 0; 0.5 0.8; 0.3 0.9]`, `μ = 1.0`

| seed | rel(G_lat) | mean \|Δρ\| |
| --- | --- | --- |
| 20260620 | 0.2510 | 0.1816 |
| 20260621 | 0.1558 | 0.0719 |
| 20260622 | 0.2669 | 0.0374 |
| 20260623 | 0.1875 | 0.0249 |
| 20260624 | 0.1628 | 0.1280 |

Mean `rel(G_lat) = 0.205`, mean `|Δρ| = 0.089`; 5/5 passed.

### Scenario C: Bernoulli rank-1 (`K=1`), `q=240`, `Λ = [0.9, 0.6, 0.4]`, `μ = 0.0` (logit link)

> Reported descriptively, not gated. These five estimates have a mean relative Frobenius error
> of 0.540 under oracle starts. The unsigned metric does not establish bias direction;
> EBV rank was not measured.

| seed | rel(G_lat) | note |
| --- | --- | --- |
| 20260620 | 0.3902 | converged |
| 20260621 | 1.1506 | converged |
| 20260622 | 0.3674 | converged |
| 20260623 | 0.2967 | converged |
| 20260624 | 0.4953 | converged |

Mean `rel(G_lat) = 0.540`; 3/5 below threshold. These results are descriptive; no gate claim is made.
Seed 20260621 has relative error above one, meaning only that the Frobenius error
exceeds the Frobenius norm of the truth. This unsigned metric cannot determine
whether the fitted covariance is larger or smaller.

### Scenario D: Binomial(20) rank-1 (`K=1`), `q=240`, `Λ = [0.9, 0.6, 0.4]`, `μ = 0.0` (logit link)

| seed | rel(G_lat) |
| --- | --- |
| 20260620 | 0.2112 |
| 20260621 | 0.1264 |
| 20260622 | 0.0207 |
| 20260623 | 0.0852 |
| 20260624 | 0.0763 |

Mean `rel(G_lat) = 0.104`; 5/5 met the exploratory threshold. The difference
from the Bernoulli results is descriptive only; these five oracle-start replicates
and unsigned errors do not establish an information mechanism or rule out structural
problems.

## Honest interpretation

### What is positive

- **Poisson scenarios (A, B):** recovery holds across rank-1 and rank-2 non-degenerate
  structures. Mean rel ≈ 0.09 (rank-1) and ≈ 0.21 (rank-2); genetic correlations
  recovered to `|Δρ| ≈ 0.09`.
- **Binomial(20) scenario (D):** the five oracle-start replicates had mean relative
  error ≈ 0.10 and met the exploratory threshold. This is not a general recovery claim.
- All four scenarios converged on all 5 seeds.

### Bernoulli results

- The Bernoulli cell is deliberately NOT gated. Mean relative error is 0.540; one
  seed has error greater than the norm of the truth. The unsigned metric cannot
  establish direction, and EBV rank was not measured.
- Because fits start at the true loadings, these results do not establish user-start
  optimization or separate approximation error from other error sources.
- A follow-up needs non-truth starts, signed covariance contrasts, retained failures,
  and enough replicates for calibration before explaining family differences.

### Scope / caveats

Balanced/fully-observed `Y` only; all starts equal the truth; rotation-nonidentified
loadings (error measured on `G_lat`); no FA(+Ψ), external comparator, signed bias,
EBV-rank metric, or general calibration claim.

### Status

`V6-GGLLVM-REML` stays `partial`; these four oracle-start scenarios do not establish
general recovery and do not promote the capability to `covered`. FA/family breadth
and an external same-objective comparator remain outstanding.

# Recovery checkpoint — H1 negative-binomial (NB2) σ²a recovery (2026-06-22)

Opt-in, outside CI. Harness: `sim/phase6_nbinom_recovery.jl`. Engine:
`fit_laplace_reml(...; family = :nbinom)` (NB2, log link, joint `(σ²a, θ)` profile).

## Design (pre-declared BEFORE running)

- Half-sib pedigree, `q = 165` animals, ONE record per animal (`Z = I`).
- DGP: `u ~ N(0, A·σ²a)`, `μᵢ = exp(μ + uₐ)`, NB2 counts via the Poisson–Gamma
  mixture `λᵢ ~ Gamma(θ, μᵢ/θ)`, `yᵢ ~ Poisson(λᵢ)` (dependency-free
  Marsaglia–Tsang Gamma sampler).
- Truth: `σ²a = 0.5`, `μ = 1.5`, `θ = 3.0`. Seeds `20260618..20260622`.
- HARD GATE (the reliable signal, following the `V6-BERNOULLI` precedent for
  hard count/binary families): `converged ∧ σ̂²a > 0.01 (interior) ∧ cor(û,u) ≥ 0.5`.
- REPORTED-NOT-GATED: the `σ²a` magnitude (`rel(σ̂²a)`) and `θ̂`.

## Result

```
[PASS] seed=20260618 σ̂²a=0.732 (rel 0.464 mag✗)  θ̂=6.484  cor=0.765
[PASS] seed=20260619 σ̂²a=0.361 (rel 0.277 mag✓)  θ̂=2.243  cor=0.668
[PASS] seed=20260620 σ̂²a=0.330 (rel 0.340 mag✓)  θ̂=1.844  cor=0.715
[PASS] seed=20260621 σ̂²a=0.097 (rel 0.805 mag✗)  θ̂=1.844  cor=0.613
[PASS] seed=20260622 σ̂²a=0.452 (rel 0.096 mag✓)  θ̂=2.056  cor=0.725
SUMMARY gated_pass=5/5 | mag(rel≤0.45)=3/5 reported-not-gated |
        mean σ̂²a=0.395 mean_rel=0.397 min_cor=0.613 θ̂_mean=2.894
```

## Honest reading

- **Reliable gate: 5/5.** All seeds converged to an interior `σ̂²a` with EBV-rank
  recovery `cor(û,u) ∈ [0.61, 0.77]`. The latent-effect RANK is recovered.
- **`σ²a` magnitude: REPORTED-NOT-GATED.** A stricter magnitude gate
  `rel(σ̂²a) ≤ 0.45` passes only **3/5**. Mean `σ̂²a = 0.395` vs truth `0.50`
  (~21% downward), with high per-seed variance — one seed collapses to `0.097`,
  one overshoots to `0.732`. This is the known **Laplace-for-count downward bias**
  plus weak `σ²a`-vs-overdispersion identifiability when there is only ONE record
  per animal (the A-structured genetic variance competes with the independent NB
  overdispersion `θ`).
- **`θ` weakly identified:** `θ̂ ∈ [1.84, 6.48]` (truth `3.0`), mean `2.894` —
  printed, never gated.
- **Same effect as `V6-BERNOULLI`, reducible by information.** The single-trial
  Bernoulli family shows the identical pattern (rank reliable, magnitude biased),
  and `V6-BINOMIAL` (m = 20 trials) recovers `σ²a` tightly (rel ≤ 0.175) — more
  information per animal removes the bias. The NB result is consistent: the
  estimator is correct; the magnitude is information-limited at one record/animal.

## No post-hoc relaxation

The magnitude target was NOT relaxed to manufacture a pass. The hard gate is on
the reliable signal (the established `V6-BERNOULLI` convention); the `rel(σ̂²a) ≤
0.45` magnitude outcome (3/5) is reported verbatim, not hidden. Kernel
correctness is established independently by the in-suite oracle (score/weight vs
finite differences, the Poisson limit `θ→∞`, and the geometric closed form at
`θ = 1`), NOT by this recovery run.

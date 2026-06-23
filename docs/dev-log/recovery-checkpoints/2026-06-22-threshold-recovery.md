# Recovery checkpoint — H3 probit / threshold σ²a recovery (2026-06-22)

Opt-in, outside CI. Harness: `sim/phase6_threshold_recovery.jl`. Engine:
`fit_laplace_reml(...; family = :bernoulli_probit)` (binary threshold / liability,
probit link, Laplace, σ²a profiled by Brent).

## Design (pre-declared BEFORE running)

- Half-sib pedigree, `q = 345` animals (15 sires, 30 dams, 300 offspring), ONE
  record per animal (`Z = I`).
- DGP (classic liability-threshold): `u ~ N(0, A·σ²a)` on the LATENT scale, an
  independent residual `e ~ N(0,1)` (the probit identifiability convention fixes the
  liability residual variance at 1), binary observation `yᵢ = 1[μ + uₐ + eᵢ > 0]`.
- Truth: `σ²a = 1.0` (liability scale), `μ = 0.0`. Seeds `20260618..20260622`.
- HARD GATE (the reliable signal, following the `V6-BERNOULLI`/`V6-NBINOM`
  precedent for binary/overdispersed families): `converged ∧ σ̂²a > 0.01 (interior)
  ∧ cor(û,u) ≥ 0.5`.
- REPORTED-NOT-GATED: the `σ²a` magnitude (`rel(σ̂²a) ≤ 0.45` flag).

## Result

```
[PASS] seed=20260618 σ̂²a=0.833 (rel 0.167 mag✓)  cor=0.762
[PASS] seed=20260619 σ̂²a=0.346 (rel 0.654 mag✗)  cor=0.685
[PASS] seed=20260620 σ̂²a=0.513 (rel 0.487 mag✗)  cor=0.686
[PASS] seed=20260621 σ̂²a=0.644 (rel 0.356 mag✓)  cor=0.613
[PASS] seed=20260622 σ̂²a=0.830 (rel 0.170 mag✓)  cor=0.725
SUMMARY gated_pass=5/5 | mag(rel≤0.45)=3/5 reported-not-gated |
        mean σ̂²a=0.633 mean_rel=0.367 min_cor=0.613
```

## Honest reading

- **Reliable gate: 5/5.** All seeds converged to an interior `σ̂²a` with EBV-rank
  recovery `cor(û,u) ∈ [0.61, 0.76]` — the latent-effect RANK is recovered.
- **`σ²a` magnitude: REPORTED-NOT-GATED, and DOWNWARD-biased as expected.** Only
  3/5 within `rel ≤ 0.45`; mean `σ̂²a = 0.633` vs truth `1.0` (~37% downward), range
  `[0.346, 0.833]`. This is the documented **Laplace-for-binary downward bias**:
  binary single-threshold data carries little information about the latent variance
  (exactly the `V6-BERNOULLI` pattern, and unlike the informative `m = 20`
  beta-binomial `V6-BETABINOMIAL` / binomial `V6-BINOMIAL`, which recover σ²a
  tightly). An ordinal ≥3-category design would be more informative.
- The bias is on the magnitude, not the estimator's correctness: the kernels are
  established independently by the in-suite oracle (Φ to 1e-12, score/weight vs
  finite differences, the independent Gauss–Hermite marginal), NOT by this run.

## No post-hoc relaxation

The gate was pre-declared as the reliable-signal hard gate with the magnitude
REPORTED-not-gated, BEFORE running (the `V6-BERNOULLI`/`V6-NBINOM` convention). The
3/5 magnitude outcome and the ~37% downward mean are recorded verbatim; the gate was
neither tightened nor loosened to manufacture a different headline.

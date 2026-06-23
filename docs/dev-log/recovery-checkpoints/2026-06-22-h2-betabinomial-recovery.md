# Recovery checkpoint — H2 beta-binomial σ²a recovery (2026-06-22)

Opt-in, outside CI. Harness: `sim/phase6_betabinomial_recovery.jl`. Engine:
`fit_laplace_reml(...; family = :beta_binomial, n_trials = m, rho = ρ)`
(overdispersed logit, Laplace, σ²a profiled by Brent at a SUPPLIED FIXED ρ).

## Design (pre-declared BEFORE running)

- Half-sib pedigree, `q = 345` animals (15 sires, 30 dams, 300 offspring),
  ONE record per animal (`Z = I`).
- DGP: `u ~ N(0, A·σ²a)` on the logit scale; per record the success probability
  is OVERdispersed, `pᵢ ~ Beta(αᵢ, βᵢ)` with `αᵢ = mᵢ·s`, `βᵢ = (1−mᵢ)·s`,
  `mᵢ = logistic(μ + uₐ)`, `s = (1−ρ)/ρ` (so `E pᵢ = mᵢ`, intra-class corr ρ),
  then `yᵢ ~ Binomial(m, pᵢ)` (dependency-free Marsaglia–Tsang Gamma → Beta).
- Truth: `σ²a = 1.0` (logit scale), `μ = 0.0`, `m = 20` trials, `ρ = 0.2`.
  Seeds `20260618..20260622`. The fit uses the SAME fixed ρ used to simulate.
- HARD GATE (the reliable signal, following the `V6-BERNOULLI` / `V6-NBINOM`
  precedent for overdispersed families): `converged ∧ σ̂²a > 0.01 (interior) ∧
  cor(û,u) ≥ 0.5`.
- REPORTED-NOT-GATED: the `σ²a` magnitude (`rel(σ̂²a) ≤ 0.45` flag).

## Result

```
[PASS] seed=20260618 σ̂²a=1.256 (rel 0.256 mag✓)  cor=0.819
[PASS] seed=20260619 σ̂²a=0.722 (rel 0.278 mag✓)  cor=0.737
[PASS] seed=20260620 σ̂²a=0.883 (rel 0.117 mag✓)  cor=0.752
[PASS] seed=20260621 σ̂²a=0.958 (rel 0.042 mag✓)  cor=0.736
[PASS] seed=20260622 σ̂²a=0.927 (rel 0.073 mag✓)  cor=0.765
SUMMARY gated_pass=5/5 | mag(rel≤0.45)=5/5 reported-not-gated |
        mean σ̂²a=0.949 mean_rel=0.153 min_cor=0.736
```

## Honest reading

- **Reliable gate: 5/5.** All seeds converged to an interior `σ̂²a` with EBV-rank
  recovery `cor(û,u) ∈ [0.74, 0.82]`.
- **`σ²a` magnitude recovered WELL (reported, not gated): 5/5 within `rel ≤ 0.45`.**
  Mean `σ̂²a = 0.949` vs truth `1.0` (~5% off), mean rel `0.153`, range
  `[0.722, 1.256]`. Unlike single-trial Bernoulli (`V6-BERNOULLI`) and one-record
  NB2 (`V6-NBINOM`), where the magnitude is information-limited and downward-biased,
  the beta-binomial at `m = 20` is INFORMATIVE: 20 trials per record plus a ρ fixed
  at its true value leave the genetic variance well identified, so the magnitude
  lands close. This is the same information effect documented for `V6-BINOMIAL`
  (m = 20 binomial recovers σ²a tightly) — the overdispersion does not destroy it
  when ρ is supplied at truth.
- **Caveat — ρ is supplied at truth here.** This run fixes ρ at the simulating
  value. Joint `(σ²a, ρ)` estimation (deferred) would re-introduce the
  variance-vs-overdispersion identifiability tension; a mis-specified fixed ρ would
  bias σ̂²a. The recovery claim is therefore conditional on a correct supplied ρ.

## No post-hoc relaxation

The gate was pre-declared as the reliable-signal hard gate with the magnitude
REPORTED-not-gated (the `V6-NBINOM` convention), BEFORE running. The magnitude
happened to land well (5/5) and is reported verbatim; the gate was not tightened
after the fact to claim a stronger result, nor loosened. Kernel correctness is
established independently by the in-suite oracle (ρ→0 reduction to
`BinomialResponse`, score vs finite differences, Fisher-weight positivity incl.
the negative-observed-information regime at m=20, and the independent Gauss–Hermite
quadrature of the true marginal), NOT by this recovery run.

# σ²a (G[1,1]) bias vs n — is the W1 Campaign 2 bias systematic or small-sample?

Run: fir job `46237216`, base DGP G0=[1 0.35; 0.35 0.7], R0=[0.8 0.2; 0.2 0.55], records=3,
cold-start, swept over design size + a high-iterations variant; branch `w1/...` @ `1ed73faf`,
julia 1.10.10. `sim/drac/phase4_sigma_a2_bias.sbatch`. **TRIAGE; informs the V4 scoped-finish; no promotion.**

## Result

| q (animals) | seeds | iterations | mean Ĝ[1,1] (true 1.0) | bias | MCSE | within 2·MCSE |
|---|---|---|---|---|---|---|
| 80 | 30 | it=5000 (conv ~239) | 0.9026 | −0.0974 (−9.7%) | 0.0466 | NO |
| 160 | 30 | it=5000 (conv ~279) | 0.9308 | −0.0692 (−6.9%) | 0.0221 | NO |
| 400 | 30 | it=5000 (conv ~286) | 0.9647 | −0.0353 (−3.5%) | 0.0176 | yes |
| 800 | 20 | it=5000 (conv ~354) | 0.9902 | −0.0098 (−1.0%) | 0.0160 | yes |
| 400 | 20 | **it=20000** (conv ~286) | 0.9575 | −0.0425 | 0.0234 | yes |

## Conclusion — small-sample, vanishing; NOT a systematic defect, NOT convergence

1. **The bias shrinks monotonically toward 0 as n grows:** −9.7% (q=80) → −6.9% (q=160) → −3.5%
   (q=400) → −1.0% (q=800). It roughly halves as n doubles — the signature of a small-sample REML
   bias in the additive variance, not a fixed systematic underestimate.
2. **Not a convergence/iteration-cap artifact:** every run reports `converged=true` at ~240–360
   iterations (far below the 5000 cap), and running q=400 at **20000** iterations gives essentially
   the same bias (−0.043 vs −0.035 at 5000, within MCSE). More iterations do not move it.
3. This is **expected REML behavior** — REML reduces but does not fully eliminate variance-component
   bias at very small n; the additive component is mildly underestimated and the bias decays with n.

## What it means for V4 (E10 scoped finish)

- The `fit_multivariate_reml` estimator is **sound**: it converges quickly and is asymptotically
  unbiased; the additive variance is recovered to ~−1% by q=800 and improving.
- The W1 Campaign 2 `size_med` "failure" is **explained**: the small-sample G[1,1] bias became
  *statistically detectable* (|bias| > 2·MCSE) only because the larger design tightened the MCSE —
  not because recovery degraded (it improved; the bias is smaller at size_med's q=160 than at q=80).
- Therefore the broader-DGP recovery supports a **scoped finish** of `V4-MV-REML`: recovery holds on
  the covered scope + balanced/moderate cells, with TWO honest, well-understood caveats to document —
  (a) a small-sample additive-variance downward bias that vanishes with n (quantified here), and
  (b) a single-record × extreme-r_g identifiability boundary. Neither is an estimator defect.
- Still gated: a real **Rose audit** + maintainer **G10** before any covered move. Nothing promoted;
  `V1-HERIT-TCAL` stays planned; public-covered = 1.

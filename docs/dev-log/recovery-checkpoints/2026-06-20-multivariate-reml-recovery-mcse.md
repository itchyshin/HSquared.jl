# Multivariate REML recovery — bias / MCSE / EBV-accuracy study — 2026-06-20

## Question

The V4-MV-REML row records that the multivariate unstructured REML recovery
"calibration protocol was executed ... and did not pass: 6/10". A bare pass count
on a strict per-seed Frobenius relative-error gate does not distinguish a **biased
estimator** (a real defect) from an **unbiased-but-high-variance** estimator at a
small design (a calibration/`n` issue, not a code defect). This checkpoint runs a
larger seed set and reports per-parameter Monte Carlo bias ± 2·MCSE, per-trait EBV
accuracy, and a Wilson interval on the pass proportion, to characterise *which* it
is.

## Setup

- Harness: `sim/phase4_multivariate_reml_recovery.jl` (opt-in, RNG-isolated,
  outside CI). Enhanced this session to also report bias/MCSE, EBV accuracy, and a
  Wilson CI.
- Design: repeated-record half-sib, `q = 80` animals (8 sires × 16 dams × 56
  offspring), 3 records/animal, `n = 240`, `t = 2` traits.
- Truth: `G_true = [1.0 0.35; 0.35 0.7]`, `R_true = [0.8 0.2; 0.2 0.55]`.
- Estimator: `fit_multivariate_reml` (unstructured, log-Cholesky NelderMead),
  warm-started at truth, 5000 iterations.
- Seeds: 20260616–20260627 (12). Per-seed gate: `rel_G ≤ 0.25`, `rel_R ≤ 0.20`,
  converged.

Reproduce:

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
      julia --project=. sim/phase4_multivariate_reml_recovery.jl \
      --seeds=20260616,20260617,20260618,20260619,20260620,20260621,20260622,20260623,20260624,20260625,20260626,20260627

## Result — Monte Carlo recovery (m = 12)

| param | true | mean | bias | MCSE | \|bias\| ≤ 2·MCSE |
| --- | --- | --- | --- | --- | --- |
| G[1,1] | 1.0000 | 0.9988 | −0.0012 | 0.0794 | yes |
| G[1,2] | 0.3500 | 0.3660 | +0.0160 | 0.0463 | yes |
| G[2,2] | 0.7000 | 0.7416 | +0.0416 | 0.0497 | yes |
| R[1,1] | 0.8000 | 0.7939 | −0.0061 | 0.0278 | yes |
| R[1,2] | 0.2000 | 0.2022 | +0.0022 | 0.0119 | yes |
| R[2,2] | 0.5500 | 0.5455 | −0.0045 | 0.0166 | yes |

- EBV accuracy (corr of EBV-hat with the true simulated breeding values):
  trait 1 mean = 0.902 (sd 0.023), trait 2 mean = 0.910 (sd 0.017).
- Convergence: 12/12. Pass (per-seed gate): **7/12 = 0.583**, Wilson 95% =
  **[0.320, 0.807]**.
- Per-seed failures are G-dominated: 4 G-only (`rel_G` 0.33 / 0.42 / 0.48 / 0.41)
  + 1 marginal G+R (seed 20260621: `rel_G` 0.261, `rel_R` 0.206). `rel_R` exceeds
  its 0.20 gate only once, marginally.

## Conclusion (honest, evidence-based)

- **No detectable bias at this design.** Every one of the six covariance
  parameters has `|bias| ≤ 2·MCSE`; the largest standardised bias is G[2,2] at
  0.84·MCSE. This is a *low-power non-rejection* of zero bias at m=12 (MCSE ≈
  0.05–0.08 on G entries, so a systematic bias below ~0.10–0.16 would pass
  undetected) — consistent with an unbiased estimator, not a proof of one. The mean
  estimates track truth (G[1,1] to 0.1%, the off-diagonal and G[2,2] within MCSE).
  EBV accuracy is high (~0.90) and stable. NOTE: the optimizer is warm-started at the
  true `G0`/`R0`, so this characterises sampling behaviour in the basin around truth;
  cold-start basin behaviour is a deferred follow-up.
- **The per-seed gate failure is sampling variance, not a defect.** The genetic
  covariance `G` has high per-replicate sampling variance at `q = 80`/`n = 240`
  (MCSE ≈ 0.05–0.08 on G entries vs ≈ 0.01–0.03 on R), so a strict per-seed
  Frobenius relative-error gate on `G` fails ~40% of the time even though no bias is
  detectable in the across-seed mean. `G` is the hard axis; `R` is essentially always
  recovered.
- **Status implication: stays `partial`, not promoted.** This evidence does NOT
  promote V4-MV-REML to covered — promotion still requires an external-comparator
  parity check (sommer/ASReml/JWAS) and, for a recovery *claim*, either a larger /
  relatedness-richer design that passes a pre-declared gate or a gate re-stated in
  bias/MCSE terms. What it DOES establish, durably, is that the dense multivariate
  REML estimator shows no detectable bias and accurate EBVs at this (truth-warm-
  started) design — the prior bare "6/10 failed" line understated the estimator's
  correctness.

## Follow-ups (not done here)

- A larger / full-sib design (more relatedness contrast, larger `n`) to drive the
  G MCSE down and test a pre-declared pass gate (parallels the Phase 3 `h²`
  identifiability study).
- External-comparator parity against `test/fixtures/phase4_multitrait_parity/`
  (R-lane: sommer/ASReml/BLUPF90) — the remaining covered-blocker.
- A cold-start (not warm-started-at-truth) variant to characterise basin behaviour.

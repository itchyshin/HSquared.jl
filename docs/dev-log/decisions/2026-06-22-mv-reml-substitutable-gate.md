# Decision: V4-MV-REML substitutable promotion gate + pre-declared recovery confirmation

Date: 2026-06-22. Status: **pre-registration + gate ratification.** Promotes
nothing — the `partial → covered` flip requires this gate passing + the honesty
fixes + a Rose claim-vs-evidence audit + the maintainer's explicit sign-off.

## Context

One owner now develops both repos. `hsquared` doc-33
(`33-v4-multivariate-promotion-gate-review.md`, Fisher/Mrode/Curie) reviewed the
`V4-MV-REML` covered gate and found the "second same-estimand REML comparator
**plus** a passing recovery gate" bar **over-strict**: there is **no free CRAN
multivariate-animal-model REML package besides `sommer`** (`MCMCglmm` is Bayesian;
`pedigreemm` univariate; `breedR` bundles BLUPF90; `lme4` cannot fit it), so
requiring a *second* REML comparator hard-couples an open-package covered claim to
a licensed/registration binary.

The `2026-06-14-calibration-failure-response` decision **forbids post-hoc
relaxation** of the failed 6/10 per-seed run. Therefore the recovery gate must be
**pre-declared and run fresh** — this note does that before any new results are read.

## Ratified substitutable gate (V4-MV-REML covered basis)

`sommer` same-estimand REML parity (≤ 8e-5) **+** `MCMCglmm` cross-class agreement
**+** Mrode 5.1 supplied-covariance MME anchor **+ EITHER**

- **(a)** a second independent REML lineage (ASReml/BLUPF90/DMU/WOMBAT), **OR**
- **(b)** a passing **pre-declared** known-truth recovery gate.

The same-estimand-REML **kind** requirement is kept — Bayesian agreement does NOT
substitute. This session takes path **(b)**.

## PRE-DECLARED recovery gate (declared before running)

- Harness: `sim/phase4_multivariate_reml_recovery.jl`, **cold-start** (fitter
  phenotypic-scale default init; no truth warm-start).
- Design (harness default): repeated-record half-sib, 8 sires × 16 dams × 56
  offspring, 3 records/animal → q = 80, n = 240, t = 2. Truth
  `G = [1.0 0.35; 0.35 0.7]`, `R = [0.8 0.2; 0.2 0.55]`, 5000 iterations.
- Replicates: **48 fresh seeds 20260616–20260663**, cold-start.
- **PASS criteria (all must hold):**
  1. 48/48 converged.
  2. All six covariance parameters (`G[1,1]`, `G[1,2]`, `G[2,2]`, `R[1,1]`,
     `R[1,2]`, `R[2,2]`): `|bias| ≤ 2·MCSE` (across-seed Monte Carlo bias within
     two Monte Carlo standard errors of zero).
  3. Per-trait EBV-accuracy mean ≥ 0.85 (corr of EBV-hat with true BV).
  4. MCSE on each `G` entry ≤ 0.045 — a **power floor**: at m=48 this makes the
     no-bias non-rejection able to detect a systematic `G` bias ≳ 0.09, materially
     tighter than the m=12 ~0.10–0.16 floor doc-33 flagged.
- **Why replace the per-seed Frobenius gate:** the per-seed gate measures
  per-replicate **sampling variance** of the estimated `G` at q=80/n=240
  (MCSE ≈ 0.05–0.08 on `G` vs ≈ 0.01–0.03 on `R`), so it fails ~40% of the time
  with no detectable bias — it conflates finite-sample variance of `G` with
  estimator quality. The bias/MCSE + EBV-accuracy gate measures the property the
  covered claim actually asserts.

## Scoped covered-claim wording (only if the gate passes AND Rose clears)

> covered (experimental, validation-scale, opt-in): multivariate unstructured REML
> estimates `G0`/`R0` with **no detectable** across-seed bias (power to ≈0.09 on
> `G`) and high EBV accuracy (≈0.90) at q=80/n=240, with same-estimand `sommer`
> 4.4.5 parity ≤ 8e-5 on the serialized two-trait fixture.

NEVER worded as "unbiased" (it is a low-power non-rejection). NOT the public
default. Deep-inbreeding / high-condition-number pedigrees remain an explicit
boundary (the engine inverts `Ainv` internally).

## Honesty fixes (independent of promotion, per doc-33 rec 3)

- Promote the full-unstructured `sommer` parity to a `skip_on_cran()` +
  `skip_if_not_installed("sommer")` in-suite test (hsquared), or reword the
  capability row so it does not read as a standing CI gate.
- Ensure no covered surface words the recovery as "unbiased".

## Boundary

Pre-registers the gate and ratifies the substitutable basis. Promotes nothing.
The `partial → covered` flip requires: the run passing the above criteria + the
honesty fixes + a Rose audit + the maintainer's explicit sign-off.

# Cross-repo FYI (from the drmTMB session, 2026-07-18): `fit_laplace_reml` IS the Cox–Reid lever — you're ahead; the gap is AGHQ + coverage

> **Informational cross-repo note, not an instruction to act.** A finding from the drmTMB coverage
> programme that reprices where HSquared.jl sits relative to drmTMB/gllvmTMB. Good news: you already
> built the hard part.

## The finding (MEASURED on drmTMB, validated vs glmmTMB/glmer/lme4)

Small-cluster non-Gaussian variance-component bias under ML-Laplace is **two stacked, orthogonal** effects:

1. **Laplace integral error** (1-point-at-the-mode) → fixed by **AGHQ** (k-point quadrature); shrinks with n.
2. **ML finite-cluster variance bias** (present under *exact* integration) → fixed only by a **restricted
   likelihood** = integrate the fixed effects out under a flat prior (exact REML for Gaussian; **Cox–Reid**
   for non-Gaussian); shrinks with clusters M.

drmTMB cumulative_logit decomposition: Laplace −7.3% → +AGHQ −5.0% → +Cox–Reid −0.9%. The restricted
likelihood is the **bigger** lever; AGHQ alone plateaus at −5.0% no matter how many nodes.

## What this means for HSquared.jl (SOURCE-CONFIRMED, reading `src/nongaussian.jl`)

**You have already built the bigger lever.** `fit_laplace_reml` integrates β out under a flat prior — that
**is** the Cox–Reid restricted likelihood — Laplace-approximated for non-Gaussian, and **validated to reduce
EXACTLY to `sparse_reml_loglik` for Gaussian** (`src/nongaussian.jl:6-9, 776-778`; the `−0.5·logdet_H`
curvature penalty at :628 is the restricted-likelihood correction). drmTMB and gllvmTMB both *lack* this
(Gaussian-only REML, non-Gaussian banned) — HSquared.jl is the one repo of the three that has it.

**The remaining gap is the AGHQ half + coverage certification:**
- Your `u`-integration in the Laplace-REML path is **1-point Laplace** (`src/nongaussian.jl:8`). The AGHQ
  lever = upgrade it to **k-point adaptive Gauss–Hermite** for the per-cluster integral. (You already use
  GHQ kernels in the *variational* path — that machinery is a head start, but it's a different path.) By the
  drmTMB numbers this closes the residual ~2 points of integral error that Cox–Reid alone leaves.
- **Coverage certification:** confirm `fit_laplace_reml` reaches *nominal* interval coverage for
  non-Gaussian heritability at small sample (the drmTMB-style pre-registered coverage campaign), not just
  point recovery. This is the honest "does the built lever actually deliver nominal" check.

Net: HSquared.jl does **not** need the drmTMB/gllvmTMB "build both levers" arc — a narrower **AGHQ +
coverage-cert** task on top of the Cox–Reid you already have.

## Sources
- drmTMB evidence: `drmTMB/docs/dev-log/2026-07-18-cumlogit-laplace-diagnosis-and-aghq-next-arc.md`.
- Cross-repo map (vault): `~/shinichi-brain/memory/Two-lever fix for small-cluster non-Gaussian
  variance-component bias (AGHQ + Cox-Reid REML) — cross-repo map.md`.
- Your relevant design: `docs/design/37-nongaussian-heritability-scale-estimand.md` (NG-1), and
  `fit_laplace_reml` in `src/nongaussian.jl`.

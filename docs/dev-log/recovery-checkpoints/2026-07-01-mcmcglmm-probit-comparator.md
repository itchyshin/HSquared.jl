# MCMCglmm same-estimand h² comparator — probit + ordinal RUN + AGREE; Gamma N/A (2026-07-01)

**What.** The MCMCglmm external comparator for the V6-NS-H2 non-Gaussian h² surface (the
QGglmm legs are banked; an MCMCglmm leg was still owed). MCMCglmm is Bayesian → a
**distributional** same-estimand check (engine Laplace *point* inside the Bayesian **95%
CrI**, agreement within MCMC error — NOT machine precision). Harness: `comparator/mcmcglmm_observed/`.

**The convention that makes it work:** the engine's `:bernoulli_probit` / `:ordered_probit`
are unit-residual **threshold/liability** models (`V_link=1`); MCMCglmm `family="threshold"`
with the residual fixed at 1 is the matching estimand for BOTH binary and ordinal.

**Leg 1 — probit binary (K=2), on `main`:** engine point INSIDE the MCMCglmm 95% CrI for
σ²a (0.754 vs 0.788 [0.625,0.967]), h²_liability (0.430 vs 0.439 [0.385,0.492]), h²_observed
(0.274 vs 0.280 [0.245,0.313]). Eff. size ~1000.

**Leg 2 — ordinal (K=3), on the v0.6 integration build:** engine point INSIDE for σ²a
(0.704 vs 0.718 [0.591,0.880]), θ₂ (0.977 vs 0.979 [0.924,1.035]), h²_liability (0.413 vs
0.417 [0.371,0.468]), AND the full per-category observed vector — cat1 0.259 vs 0.261, **cat2
(interior) 0.0038 vs 0.0042 [0.0013,0.0081]**, cat3 0.237 vs 0.239. Eff. size ~1800. The
interior-category agreement independently CONFIRMS Falconer's finding: the interior-category
observed h² is genuinely ~0 under the QGglmm/Stein estimand (both methods agree) — descriptive,
not an independently selectable heritability.

**Leg 3 — Gamma: NOT APPLICABLE.** MCMCglmm has no general Gamma family (only `exponential` =
Gamma shape ν=1). The general-shape engine Gamma cannot be MCMCglmm-compared; the **glmmTMB
`Gamma(link="log")`** comparator (already RUN, `comparator/gamma_glmmtmb/`) is the correct
same-estimand tool. No MCMCglmm Gamma leg is owed.

**Two pitfalls banked** (README): logit `family="categorical"` VR→0 gives VA ~4× off; ordinal
`family="ordinal"` gives σ²a/θ₂ inflated ~1.4–2× — both wrong residual conventions;
`family="threshold"` is the correct match in every case.

**Honesty fence.** Evidence toward the owed MCMCglmm comparator, on the probit + ordinal
liability/observed scales (Fisher/Falconer's flagged primary scales). Does NOT flip covered.
**For the real #221/#223 PR:** the V6-NS-H2 `missing`/`owed` field can move from "an MCMCglmm
comparator [owed]" to "MCMCglmm threshold comparator RUN + AGREES for probit binary + ordinal
K=3 (liability + observed, within MCMC error; `comparator/mcmcglmm_observed/`); Gamma N/A
(MCMCglmm has no general Gamma — glmmTMB is the tool, done)." Still owed independently: the
maintainer Fisher/Falconer sign-off + the maintainer **G10** covered flip. V6-NS-H2 /
V6-ORDINAL / V6-GAMMA stay `partial`; count 50 / public-covered 1 UNCHANGED (ran on `main` +
a worktree + a comparator dir; no engine/status change to `main`).

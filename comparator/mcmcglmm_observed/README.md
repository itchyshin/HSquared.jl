# MCMCglmm same-estimand heritability comparator (V6-NS-H2)

The MCMCglmm external comparator for the non-Gaussian h² surface (the QGglmm legs are
already banked). MCMCglmm is **Bayesian**, so this is a **distributional** same-estimand
check: the engine's Laplace *point* estimate must fall inside MCMCglmm's Bayesian **95%
credible interval** (agreement within MCMC error) — NOT a machine-precision identity.

**Key convention (both legs):** the engine's `:bernoulli_probit` / `:ordered_probit` are
unit-residual **threshold/liability** models (`V_link = 1`, Dempster–Lerner). MCMCglmm
`family="threshold"` with the residual fixed at 1 is the matching estimand. This holds for
BOTH binary (K=2) and ordinal (K≥3) — use `family="threshold"` throughout, not
`family="categorical"` (logit) or `family="ordinal"` (see the pitfalls below).

## Leg 1 — probit binary (K=2): RUN + AGREES

`probit_engine.jl` (runs on `main`; the `:bernoulli_probit` fit is #171) + `probit_fit.R`.
Result (`result.txt`, seed 20260701, eff. size ~1000):

| quantity | engine point | MCMCglmm [95% CrI] | agree |
| --- | --- | --- | --- |
| σ²a | 0.7540 | 0.7875 [0.6250, 0.9672] | **INSIDE** |
| h²_liability | 0.4299 | 0.4392 [0.3846, 0.4917] | **INSIDE** |
| h²_observed | 0.2736 | 0.2795 [0.2447, 0.3129] | **INSIDE** |

## Leg 2 — ordinal (K=3): RUN + AGREES (incl. the per-category vector)

`ordinal_engine.jl` (REQUIRES the v0.6 integration build — the `:ordered_probit` fit (#215)
and the ordinal per-category observed h² (#223) only coexist once the PRs are merged; run
here from a worktree on the integration commit) + `ordinal_fit.R` (`family="threshold"`,
K=3). Result (`ordinal_result.txt`, seed 20260701, eff. size ~1800):

| quantity | engine point | MCMCglmm [95% CrI] | agree |
| --- | --- | --- | --- |
| σ²a | 0.7040 | 0.7183 [0.5909, 0.8800] | **INSIDE** |
| θ₂ (cutpoint) | 0.9771 | 0.9788 [0.9243, 1.0345] | **INSIDE** |
| h²_liability | 0.4132 | 0.4170 [0.3714, 0.4681] | **INSIDE** |
| h²obs category 1 | 0.2586 | 0.2611 [0.2318, 0.2934] | **INSIDE** |
| **h²obs category 2 (interior)** | **0.0038** | **0.0042 [0.0013, 0.0081]** | **INSIDE** |
| h²obs category 3 | 0.2372 | 0.2389 [0.2105, 0.2707] | **INSIDE** |

**The interior-category cross-check** independently confirms Falconer's finding: the interior
category's observed h² is genuinely ~0 under the QGglmm/Stein estimand (both the engine AND
MCMCglmm agree it is tiny), so it must be caveated as **descriptive, not an independently
selectable heritability** — it is a property of the estimand, not an engine bug.

## Leg 3 — Gamma: NOT APPLICABLE via MCMCglmm

MCMCglmm has **no general Gamma family** (its families are gaussian / poisson / categorical /
ordinal / **exponential** / geometric / threshold / … — `exponential` is only Gamma with
shape ν=1). The engine's Gamma is general-shape, so MCMCglmm cannot provide a same-estimand
Gamma comparator. The **glmmTMB `Gamma(link="log")`** comparator (already RUN on the gamma PR,
`comparator/gamma_glmmtmb/`) is the correct same-estimand tool for the Gamma family; an
MCMCglmm `exponential` run would only exercise the ν=1 case, which the engine already validates
internally (the exact ν=1→Exponential reduction test). So no MCMCglmm Gamma leg is owed.

## Pitfalls banked (so they are not re-tread)

1. **Logit `family="categorical"` with VR→0** (binary): VA came out ~4× too small vs the engine
   despite clean mixing — the MCMCglmm categorical fixed-residual convention (the binary residual
   is not identifiable and cannot be pinned to ~0). Use `family="threshold"`.
2. **Ordinal `family="ordinal"`**: gave σ²a and θ₂ both inflated ~1.4–2× vs the engine — a
   different residual/scale convention than the engine's unit-residual liability. Use
   `family="threshold"` (which handles K≥3 via multiple cutpoints and fixes VR=1 cleanly).

## Honesty fence

Evidence toward the owed MCMCglmm comparator for V6-NS-H2, on the probit **liability +
binary-observed** and ordinal **liability + per-category-observed** scales (the primary
threshold-trait scales Fisher/Falconer flagged). It does NOT flip anything to covered:
Bayesian-vs-Laplace **distributional** agreement, not machine precision. Still owed
independently: the maintainer's Fisher/Falconer sign-off, and the maintainer **G10** covered
flip. V6-NS-H2 / V6-ORDINAL / V6-GAMMA stay `partial`.

## Reproduce (from repo root)

```sh
# Leg 1 (probit, runs on main):
julia --project=. comparator/mcmcglmm_observed/probit_engine.jl
Rscript comparator/mcmcglmm_observed/probit_fit.R
# Leg 2 (ordinal, needs the v0.6 integration build for :ordered_probit + ordinal h²):
julia --project=<integration> comparator/mcmcglmm_observed/ordinal_engine.jl
Rscript comparator/mcmcglmm_observed/ordinal_fit.R
```

Requires R with `MCMCglmm` (2.36) + `QGglmm` (0.8.0), installed locally.

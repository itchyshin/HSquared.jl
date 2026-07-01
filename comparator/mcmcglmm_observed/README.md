# MCMCglmm same-estimand heritability comparator (V6-NS-H2)

The last owed external comparator for the non-Gaussian h² surface (the QGglmm legs
are already banked). MCMCglmm is a **Bayesian** GLMM, so this is a **distributional**
same-estimand check: the engine's Laplace *point* estimate must fall inside MCMCglmm's
Bayesian **95% credible interval** (agreement within MCMC error) — NOT a machine-precision
identity like the QGglmm comparators.

## Design: probit LIABILITY (the clean match)

MCMCglmm `family="threshold"` fixes the residual (liability) variance at **1**, which is
*exactly* the engine's probit convention `V_link = 1` (Dempster–Lerner 1950). So a
probit/threshold binary model is the correct same-estimand design, and it exercises the
**primary, selection-relevant** scale (the one Fisher + Falconer flagged as flagship).

Both sides fit the SAME simulated dataset (liability `= μ + u + e`, `e ~ N(0,1)`,
`u ~ N(0, σ²a)`, iid random effect identified by `n=8` records × `G=400` levels):
- **Engine** (`probit_engine.jl`, runs on `main`): `fit_laplace_reml(family=:bernoulli_probit)`
  → σ̂²a, then `h²_liab = σ̂²a/(σ̂²a+1)` and the QGglmm-`binom1.probit` observed h² — the exact
  formulas the PR-branch `nongaussian_heritability` computes (Fisher/Falconer-confirmed).
- **MCMCglmm** (`probit_fit.R`): `family="threshold"`, residual fixed at 1; posterior of
  (VA, μ) → `h²_liab = VA/(VA+1)` and the `binom1.probit` observed h² per posterior draw.

## Result (`result.txt`, seed 20260701, eff. sample size ~1000)

| quantity | engine (Laplace point) | MCMCglmm posterior [95% CrI] | agreement |
| --- | --- | --- | --- |
| σ²a | 0.7540 | 0.7875 [0.6250, 0.9672] | **INSIDE** |
| h²_liability | 0.4299 | 0.4392 [0.3846, 0.4917] | **INSIDE** |
| h²_observed | 0.2736 | 0.2795 [0.2447, 0.3129] | **INSIDE** |

All three engine points fall inside MCMCglmm's Bayesian 95% CrI — the two methods agree
within MCMC error on σ²a, the liability h², and the observation-scale h².

## Pitfall banked: the naive LOGIT comparison does NOT work

A first attempt used the engine's logit `:bernoulli` (on `main`) vs MCMCglmm
`family="categorical"` (logit) with the residual pinned ≈0 (to mimic the engine's pure
logit-normal). Despite clean mixing (eff. size ~1000), MCMCglmm returned VA = 0.284 vs the
engine's σ̂²a = 1.109 on the *same* data (~4× off) — the well-known MCMCglmm categorical
**fixed-residual convention** issue (the binary residual is not identified and cannot be
pinned to ~0 without distorting the latent scale). **Use the probit/threshold design above**,
where the fixed unit residual is the *correct* liability convention, not an approximation.

## Honesty fence

This is **evidence toward** the owed MCMCglmm comparator for V6-NS-H2, on the probit
**liability + binary-observed** scale. It does NOT flip anything to covered:
- Bayesian-vs-Laplace **distributional** agreement (within MCMC error), not machine precision.
- Still owed independently: the MCMCglmm **ordinal** (K>2, `family="threshold"` multi-cutpoint)
  and **Gamma** observation-scale legs; the maintainer's Fisher/Falconer sign-off; and the
  maintainer **G10** covered flip. V6-NS-H2 / V6-ORDINAL / V6-GAMMA stay `partial`.

## Reproduce (from repo root)

```sh
julia --project=. comparator/mcmcglmm_observed/probit_engine.jl   # writes packet_data.csv + engine_points.csv
Rscript comparator/mcmcglmm_observed/probit_fit.R                 # fits MCMCglmm, prints the table
```

Requires R with `MCMCglmm` (2.36) + `QGglmm` (0.8.0), both installed locally.

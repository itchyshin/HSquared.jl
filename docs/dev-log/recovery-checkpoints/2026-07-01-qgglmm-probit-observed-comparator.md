# V6-NS-H2 — QGglmm external comparator for the OBSERVATION-scale h² (logit, probit, Poisson, binomN) — 2026-07-01

Same-estimand EXTERNAL comparator (the doc-19 §5 owed item) for HSquared.jl's non-Gaussian
**observation-scale** heritability, against de Villemereuil's **QGglmm** R package (the reference
implementation of the QGglmm latent/expected/data-scale transform). Discharges the external-comparator
debt for all FOUR QGglmm-builtin observation scales — **logit (Bernoulli)**, **binary-probit**,
**Poisson (count)**, **Binomial n>1 (proportion)**; promotes nothing — V6-NS-H2 stays `partial`,
public-covered fitting = 1.

## Setup
- Engine: `nongaussian_heritability(V_A, μ, <family>; predictor_variance=V_fixed).h2_observation`
  for `<family>` ∈ {`BernoulliResponse()` (logit), `BernoulliProbitResponse()` (probit),
  `PoissonResponse()` (log/count), `BinomialResponse(n)` (logit/proportion)}.
- Comparator: `QGglmm::QGparams(mu=μ, var.a=V_A, var.p=V_A+V_fixed, model=<model>[, n.obs=n])$h2.obs`
  for `<model>` ∈ {`binom1.logit`, `binom1.probit`, `Poisson.log`, `binomN.logit`} (QGglmm 0.8.0 from
  CRAN 2026-07-01; R 4.6.0).
- Harness: `comparator/qgglmm_probit_observed/compare.R` + `engine_h2obs.csv` + `result.txt`.
- Reproduce: write the engine CSV (`mu,V_A,V_fixed,model,n_obs,h2_observation`), then
  `Rscript comparator/qgglmm_probit_observed/compare.R comparator/qgglmm_probit_observed/engine_h2obs.csv`.

## The load-bearing convention (why the external comparator was needed)
QGglmm's `var.p` for the observation-scale integration is the **PREDICTOR** variance `V_A + V_fixed` —
the link's unit/π²-residual is baked into the inverse link, NOT a `var.p` component (doc-19 §2.2). A
first calibration attempt with `var.p = V_A + V_link + V_fixed` DISAGREED (probit h2.obs 0.127 vs
engine 0.212 at μ=0,V_A=0.5); the predictor-variance `var.p` matches to quadrature precision. This is
exactly the convention the external comparator pins that the internal Dempster–Lerner / independent-
quadrature cross-checks could not (they share the predictor-variance integration).

## Result (9 (μ, V_A, V_fixed) cases × 2 links = 18 comparisons)

`binom1.probit` (engine `:bernoulli_probit`): agree to ≤ **4.45e-6** (worst at μ=−0.5,V_A=2,V_f=0.5 —
the two quadratures, engine 20-node Gauss–Hermite vs QGglmm adaptive cubature, differ at the 6th digit
on the large-V_A case). Sample: (0,0.5,0) 0.2122066 vs 0.2122066; (2,0.5,0) 0.0758321 vs 0.0758321.

`binom1.logit` (engine `:bernoulli`): agree to ≤ **2.54e-6**. Sample: (0,0.5,0) 0.1009113 vs 0.1009113;
(0.3,1,0) 0.1687648 vs 0.1687648.

`Poisson.log` (engine `:poisson`, COUNT estimand): agree to ≤ **1.7e-16** (machine precision — the
engine's log-normal–Poisson closed form and QGglmm's cubature coincide). Sample: (0,0.3,0) 0.2478178 vs
0.2478178; (1,0.4,0.2) 0.3654134 vs 0.3654134.

`binomN.logit` (engine `:binomial`, n=10, PROPORTION estimand): agree to ≤ **1.2e-8**. Sample:
(0,0.5,0) 0.5273489 vs 0.5273489; (0.3,1,0) 0.6622238 vs 0.6622238.

**`max |engine − QGglmm| = 4.45e-6`** over all **25** comparisons (18 binom1 + 4 Poisson + 3 binomN;
< 1e-4 threshold). `PASS`. Full table in `result.txt`.

## Verdict / scope
The engine's **logit**, **binary-probit**, **Poisson (count)**, and **Binomial n>1 (proportion)**
observation-scale h² all AGREE with the QGglmm same-estimand external comparator to ≤4.5e-6. This
**discharges the external-comparator debt for all four QGglmm-builtin observation scales** (doc-19 §5)
— the binary-probit scale also has an internal Dempster–Lerner cross-check; the others were previously
only self-checked against internal quadrature/closed-forms.

STILL OWED for the row's covered path: the external comparator for the **ordinal (K>2)** observed scale
(QGglmm ordinal support + the per-category/per-threshold convention need checking) and the **Gamma
(data)** scale (QGglmm has NO built-in Gamma model — needs a CUSTOM model spec: inverse-link `exp`,
var.func `μ²/ν`, d.inv.link `exp` — a careful follow-up, do NOT rush the custom var.func); plus an
MCMCglmm comparator, a Fisher/Falconer sign-off, and the maintainer G10. NOT a covered claim;
`validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED.

# 2026-07-01 v0.6 MCMCglmm external comparator — observation-scale h² (Poisson, A = I)

## Goal
Lens: Fisher/Curie + Rose. Add the **MCMCglmm** same-estimand external comparator for the non-Gaussian
**observation-scale** h² (`nongaussian_heritability`) — the remaining owed h² comparator (the QGglmm
leg is done). Discharges the MCMCglmm item doc-19 §5 + the QGglmm checkpoint list as owed. Extends
`V6-NS-H2` (stays `partial`, count 50, public-covered fitting 1).

## What was done
- **New comparator** `comparator/mcmcglmm_observed/` (generate.jl + run_mcmcglmm.R + README + result.txt
  + .gitignore). An END-TO-END Bayesian leg complementing the QGglmm exact-transform leg.
  - `generate.jl`: deterministic **A = I / repeated-records** Poisson DGP (N=300 × 6 records = 1800,
    σ²a=0.5, μ=0.8, seed 20260701, no record-level over-dispersion); fits
    `fit_laplace_reml(family=:poisson)` with `Ainv=I`; serializes the engine `h2_observation` POINT.
  - `run_mcmcglmm.R`: MCMCglmm 2.36 `count ~ 1, random = ~id, family = "poisson"` (units residual
    ESTIMATED); transforms the posterior by **de Villemereuil's documented QGglmm workflow** (QGglmm
    0.8.0 vignette: `var.a = VCV[,"id"]`, `var.p = rowSums(VCV)`, `QGparams(model="Poisson.log")` per
    draw); checks the engine point against the posterior 95% credible interval.
- **Design rationale (verified, not assumed):** A=I ⇒ the animal effect is a plain iid `id` random
  effect; repeated records + a no-over-dispersion DGP drive MCMCglmm's units residual to ~0 so
  `var.p = rowSums(VCV) ≈ V_A`, matching the engine convention. The **probit route is a trap** —
  `QGparams(binom1.probit, var.p=V_A+1)` = 0.102 vs the engine's 0.170 (a convention artifact, not MCMC
  error); Poisson's `var.p` is unambiguous. Empirically confirmed the engine==QGparams(var.p=V_A) for
  both Poisson (0.40469) and probit (0.17041) before choosing Poisson.
- **Owed field discharged (MCMCglmm now RUN)** on all 3 status surfaces + the `nongaussian.jl` docstring
  + the `_nongaussian_h2_core` code comment + the doc-14 H7 backlog note — in lockstep. Also fixed a
  **pre-existing drift** in `validation_status.jl`'s V6-NS-H2 caveat field ("NO external-comparator
  (QGglmm/MCMCglmm) evidence" — stale since the QGglmm merge) → now states the QGglmm + MCMCglmm evidence.

## Commands / results
- Recorded run (`comparator/mcmcglmm_observed/result.txt`, chain 260000/60000/100 → 2000 samples,
  ESS[id]=455): MCMCglmm V_units mean **0.0132 ≈ 0**; MCMCglmm h².obs mean 0.4852, **95% CI
  [0.449053, 0.515349]**; engine h².obs point **0.501739 INSIDE the 95% CI** (+0.98 posterior SD,
  83.5% mass below). `PASS`.
- `julia --project=. -e 'using Pkg; Pkg.test()'` → **"Testing HSquared tests passed"**; count guard
  `@test length(validation_status()) == 50` holds; V6-NS-H2 test `status == "partial"` holds.
- `julia --project=docs docs/make.jl` → **exit 0** ("build complete").
- `grep public_covered tools/status_cache.json` → **1** UNCHANGED.
- Real `rose-systems-auditor` audit (recorded in the PR / after-task report).

## Claim boundary
A **DISTRIBUTIONAL** agreement (Bayesian posterior vs the engine's asymptotic point) within MCMC error
— NOT machine precision and NOT a validation of unbiasedness (shared Poisson-GLMM information limit).
ONE design, ONE family (Poisson), validation-scale, opt-in (generated CSVs git-ignored). `V6-NS-H2`
stays `partial`; `validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED. Still owed
for the covered path: the ordinal(K>2)/Gamma-data observation-scale comparators, a Fisher/Falconer
sign-off, intervals/SEs, an R surface, and the maintainer G10. NOTE: on the Rose audit
(PROMOTE-WITH-CHANGES) the two now-false "no same-estimand comparator yet" premises in doc-19
(`19-h2-scale-contract.md` line 16 + the §5 fence) were ALSO corrected — the same drift class this
slice fixed in `validation_status.jl`; doc-19's still-owed families table + its point-in-time authoring
count are left as-is (the latter annotated "since grown to 50").

# Decision — random-regression covered aim (k=2) + non-Gaussian family plan (2026-06-30)

Status: **maintainer-directed aim** (Shinichi, 2026-06-30). "Things could change but it is a good aim."
Recorded to the roadmap (board + doc-18). Claims nothing covered; sets the SCOPE for future covered work.

## Part 1 — random regression: cover k=2 first, all families

**AIM: the first covered random-regression model is the LINEAR reaction norm — random intercept + exactly
ONE random slope (`k=2`, genetic coefficient covariance `K_g` a 2×2), for ALL response types: Gaussian,
each non-Gaussian family, and the genetic GLLVM (RR-structured latent factors).**

- **Engine stays general-`k` (experimental).** `fit_random_regression_reml` already estimates a general
  `k×k` `K_g` (any number of slopes via the `Φ` basis). We scope the COVERED CLAIM to `k=2`, not the
  engine capability — a power user can still fit cubic today; it just isn't covered/validated.
- **Why k=2 first:** it is the canonical applied model (G×E / reaction norms), and higher-order `K_g`
  (k≥3) is increasingly ill-conditioned (large sampling variance on the quadratic/cubic coefficients) —
  the same identifiability wall seen on repeatability's σa/σpe split and small-n GREML. We cover where a
  pre-declared recovery gate + comparator pass cleanly.
- **k>2 covered = POST-v1.0, planned (scoped OUT of v1.0, not dropped).** v1.0's bar is "every phase
  covered OR scoped out", so v1.0 ships with k=2 covered and k>2 documented as a planned extension. The
  pinned path for k>2: **reduced-rank / factor-analytic `K_g`** (estimate the leading eigen-functions, not
  the full k×k) — how WOMBAT/ASReml tame high-order RR identifiability — which reuses the v0.4B
  factor-analytic machinery. So k>2 is "RR coefficients meet FA-G", post-v1.0.
- **Sequencing (honest):** Gaussian k=2 (v0.3) is CLOSE — same recipe as two-effect (sommer/WOMBAT
  comparator + a 48-seed bias/MCSE gate, scoped to k=2). Non-Gaussian k=2 (v0.6) and GLLVM k=2 are
  FURTHER — they inherit the non-Gaussian calibration debt (Laplace + a 2×2 coefficient covariance on a
  non-Gaussian likelihood is a harder estimation problem).
- **Still owed (RR slice 4) regardless of order:** the permanent-environment random-regression term (the
  non-genetic individual curve), curve-valued EBV-trajectory PEV/reliability, eigen-function reporting,
  and the R-facing `rr(covariate, order)` model-spec / bridge (mirroring ASReml `leg()`).

## Part 2 — non-Gaussian family plan (priority = animal-breeding relevance)

Reference menus: MCMCglmm, glmmTMB, brms (all general-purpose). HSquared.jl prioritizes by BREEDING
relevance, which differs from those packages' count-heavy emphasis.

**Comparator strategy — and a scarcity to plan around.** glmmTMB is the right SAME-estimand reference
(Laplace-approximate ML on TMB = HSquared.jl's approach), **but it does NOT natively take a pedigree `A`**
(its structures are iid/us/ar1/rr, not "supplied relationship matrix"). So glmmTMB cleanly validates only
the *iid / simple-grouping reduction*; for the genetic (pedigree-`A`) non-Gaussian model it needs a
Cholesky-of-`A` workaround, or we use a **hand-rolled Laplace oracle** (as the Gaussian path used an
independent dense oracle). The tools that do pedigree-`A` non-Gaussian *natively* — MCMCglmm, brms,
BLUPF90 THRGIBBS — are all **Bayesian (agreement-only)**. **Honest evidence path for non-Gaussian covered:**
our own Laplace oracle + a pre-declared known-truth recovery gate (doc-33 path-b), glmmTMB on the iid
reduction, and Bayesian (MCMCglmm/brms) as agreement-only. CAUTION: Laplace is biased for binary/low-count
data and glmmTMB shares that bias (agreement ≠ unbiasedness) — the recovery gate may fail for binary at
small cluster sizes; AGHQ/higher-order or a scoped claim may be needed.

| Tier | Family | Breeding rationale | Status |
|---|---|---|---|
| have | Poisson, Binomial, Bernoulli-**probit** (binary liability), NB2, beta-binomial | counts, proportions, binary threshold, overdispersion | partial (Laplace) |
| **T1 (top)** | **ordinal / categorical threshold** (≥3 categories) | calving ease, disease severity, conformation scores — THE canonical breeding GLMM (Gianola–Foulley; BLUPF90 THRGIBBS). Completes binary→ordinal liability-threshold | owed |
| T2 | Gamma / lognormal | skewed positive continuous (somatic cell, yields) | owed |
| T3 | zero-inflated / hurdle Poisson·NB | excess zeros in fertility / mortality count traits | owed |
| T4 (post-v1.0) | censored / **survival** (Weibull longevity), Tweedie, COM-Poisson | longevity is high-value but usually its own framework (Survival Kit); the rest niche | scoped out |

**Scale-labelled h² contract (non-negotiable for every non-Gaussian family):** report h² on BOTH the
latent/link scale (e.g. liability) AND the observation scale, clearly labelled. The liability-scale h² is
the selection-relevant quantity. Mirror the **QGglmm** (de Villemereuil) scale-conversion convention.

## How this maps to the version ladder

- **v0.3** (standard-QG): Gaussian RR k=2 covered (comparator + gate owed; the close hop).
- **v0.6** (non-Gaussian / GLLVM): the T1–T3 families + non-Gaussian RR k=2 + GLLVM RR k=2, each gated
  behind family calibration + a glmmTMB same-estimand comparator + the scale-labelled h² contract.
- **v0.9** (R↔Julia bridge): the R `rr()` / family model-spec activation (one-way bridge), as-you-go.
- **v1.0**: k=2 RR + the T1–T3 families covered or scoped; k>2 RR and T4 families documented as planned
  post-v1.0 extensions (k>2 via reduced-rank `K_g`).

## References

- MCMCglmm family list: <https://www.rdocumentation.org/packages/MCMCglmm/versions/2.36/topics/MCMCglmm>
- glmmTMB family list: <https://glmmtmb.github.io/glmmTMB/reference/nbinom2.html>
- QGglmm (non-Gaussian h² scale conversion), de Villemereuil et al.; Gianola & Foulley (threshold model);
  Meyer / WOMBAT (random-regression covariance functions); ASReml `leg()`.

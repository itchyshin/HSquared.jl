# Random-regression covered convention lock (k = 2)

Status: **convention lock for the FIRST covered random-regression claim** (ultraplan
Phase 3). Ratifies the reporting/interpretation conventions that a `V3-RR-REML`
`partial → covered` close will be scoped to. Claims nothing covered by itself; it
fixes *what the covered claim will mean* so the recovery gate + comparator + Rose
audit are judged against a stable contract.

Covered aim (from `docs/dev-log/decisions/2026-06-30-rr-aim-and-nongaussian-family-plan.md`):
the first covered RR model is the **linear reaction norm — random intercept + exactly
ONE random slope (`k = 2`, coefficient genetic covariance `K_g` a 2×2), Gaussian,
homogeneous residual**. The engine stays general-`k` and experimental; `k ≥ 3`
covered is post-v1.0 via reduced-rank / factor-analytic `K_g`.

## 1. Basis convention (RATIFIED)

- **Normalized Legendre basis.** The random-regression basis is the normalized
  Legendre family `φ_n(t) = sqrt((2n+1)/2)·P_n(t)`, with `P_n` the ordinary Legendre
  polynomials (Bonnet recurrence), orthonormal on `[-1, 1]`
  (`∫_{-1}^{1} φ_m φ_n = δ_mn`). Engine formula: `legendre_basis`
  (`src/random_regression.jl:46-64`), design builder `legendre_design` /
  `_rr_design` (`src/random_regression.jl:80-86, 269`). For `k = 2` the basis is
  `φ_0(t) = sqrt(1/2)` (constant) and `φ_1(t) = sqrt(3/2)·t` (linear).
- **Covariate standardized to `[-1, 1]` FIRST.** The raw covariate (age, time, an
  environmental gradient) is affinely mapped to `t ∈ [-1, 1]` by
  `standardize_covariate` (`src/random_regression.jl:73-77`,
  `t = 2(a − lower)/(upper − lower) − 1`) before evaluating the basis;
  `legendre_basis` throws for `|t| > 1`. `lower`/`upper` are part of the fitted
  object's provenance — `K_g` is defined relative to this map.
- **`K_g` is NOT comparable across normalization conventions.** Raw/shifted/
  differently-scaled Legendre (or a B-spline / ordinary-polynomial basis) give a
  DIFFERENT `K_g` for the same data. Any external comparator (WOMBAT `leg()`,
  ASReml `leg()`, sommer) must be put on the SAME normalized-Legendre-on-`[-1,1]`
  basis before its `K_g` is compared — comparator basis normalization is a
  SEPARATE later slice, not part of this lock.

## 2. What is reported, and how (RATIFIED)

The estimated object is a `k×k` coefficient genetic covariance `K_g` plus a
homogeneous residual variance `σ²e` (`fit_random_regression_reml`,
`src/random_regression.jl:439`). The reporting contract:

- **`K_g` is reported as a covariance matrix AND a correlation matrix** — the
  interpretable coefficient-level quantities. The correlation matrix is
  `D⁻¹ K_g D⁻¹` with `D = diag(√diag(K_g))`.
- **NOT lme4-style `Std.Dev`/`Corr` random-effect summaries.** The Legendre
  coefficients are basis-artefact quantities, not directly interpretable slopes;
  we do not present a coefficient standard-deviation / correlation table as if the
  coefficients were the estimand. The interpretable quantities are the
  **covariate-indexed functionals**:
  - the additive genetic variance trajectory `v_g(t) = φ(t)ᵀ K_g φ(t)`
    (`rr_genetic_variance`),
  - the genetic covariance/correlation surface `G(t, t') = φ(t)ᵀ K_g φ(t')`
    (`rr_genetic_covariance_surface` / `rr_genetic_correlation_surface`),
  - the heritability trajectory `h²(t)` (`rr_heritability`; §3), and
  - the covariance-function eigenfunctions `ψ_j(t) = φ(t)ᵀ v_j`
    (Kirkpatrick / Lofsvold & Bulmer 1990; `rr_eigenfunctions`), the
    rotation-invariant summary of how many dimensions of genetic variation the
    reaction norm actually carries.
- These are the same rotation-invariant / covariate-indexed reporting choices used
  for the FA-G convention (`docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`):
  report functionals of the covariance, not raw basis coefficients.

## 3. Heritability is ALWAYS a covariate-indexed curve (RATIFIED)

- **`h²` for a random-regression model is a CURVE `h²(t)`, never a scalar.** With
  `K_g` and a residual variance, `h²(t) = v_g(t) / (v_g(t) + σ²e)` varies along the
  covariate. Emitting a single scalar "the heritability" for a reaction-norm fit is
  a category error — it silently picks one covariate value. Both twins compute a
  trajectory (`rr_heritability(object, at, n)` returns a `(covariate, ...)`
  trajectory; R `rr_heritability`, `hsquared/R/extractors.R:2101`).
- **Permanent-environment overstatement caveat (STANDING).** The covered model has
  a **homogeneous residual `σ²e` and NO permanent-environment (PE) random-regression
  term**. So `v_g(t)` (genetic curve variance) is clean, but the residual is a
  single scalar rather than a within-individual curve. Consequently `h²(t)` can
  **overstate** heritability wherever a real PE curve would absorb variance that the
  homogeneous residual cannot: with only `σ²e` in the denominator, permanent-
  environment (non-genetic individual-curve) variance has nowhere else to go and is
  not separated from the genetic curve unless the design's repeated-records
  structure identifies it — which the covered k=2 design does not attempt. The PE
  random-regression term is explicitly deferred (below); `h²(t)` here is
  "heritability given a homogeneous residual", not a PE-adjusted repeatability
  decomposition.

## 4. Frozen and deferred slots (RATIFIED)

- **`(x | g)` raw random slopes are a FROZEN slot — NO estimator.** A raw
  random-slope model (an untransformed covariate `x` with a random slope per group,
  lme4 `(x | g)` / a `us` slope-intercept covariance on the RAW covariate) is a
  **distinct estimand** from the normalized-Legendre reaction norm — different
  parameterization, different `K_g` meaning, different identifiability. It is
  frozen: there is no estimator, it is not part of the covered claim, and it is
  deferred. Do not present the covered reaction-norm result as if it answered a raw
  `(x | g)` random-slope question.
- **`k ≥ 3` stays experimental.** The engine estimates a general `k×k` `K_g`
  (`fit_random_regression_reml`), but only `k = 2` is scoped for covered. Higher
  order (`k ≥ 3`) is increasingly ill-conditioned (large sampling variance on the
  quadratic/cubic coefficients) and stays experimental; the pinned covered path for
  `k ≥ 3` is **reduced-rank / factor-analytic `K_g`** (estimate the leading
  eigenfunctions, reusing the v0.4B FA machinery), a post-v1.0 extension — NOT the
  full `k×k` estimator.
- **Also deferred (RR slice 4, regardless of order):** the permanent-environment
  random-regression term, curve-valued EBV-trajectory PEV/reliability, heterogeneous
  residual structure, and the comparator-basis-normalization slice. These remain
  owed; covered at k=2 does not retire them.

## 5. R surface status (RECONCILED — NOT a covered claim)

The R lane (`hsquared`) ALREADY parses `rr(covariate, order)` on the left-hand side
of `animal()` (`hsquared/R/model-spec.R:998` ff.), builds the bridge payload
(`payload$random_regression`, `hsquared/R/julia-bridge.R:1861`), and returns a
curve-valued heritability (`rr_heritability(object, at, n)`,
`hsquared/R/extractors.R:2101`). So the prior owed-item wording "no R-facing
model-spec or bridge payload" is **stale**. It is reconciled to "an R surface
(`rr()`) exists but is experimental/opt-in, not covered" in
`src/validation_status.jl` (the `V3-RR-REML` `claim_boundary`) and
`docs/design/capability-status.md` (the RR-REML row). This reconciliation is a
factual accuracy fix only — it does **not** change the `partial` status and makes
**no** covered claim about the R surface (engine-covered ≠ R-public-covered; the
V4-MV-REML / Rose-risk-5 layering).

## 6. Scope of the eventual covered claim (for the gate + Rose)

If the pre-declared k=2 `K_g` recovery gate passes, a same-estimand comparator
agrees, and Rose promotes, "covered" will mean: **`fit_random_regression_reml`
correctly implements dense REML estimation of a 2×2 coefficient genetic covariance
`K_g` + homogeneous `σ²e` for the normalized-Legendre linear reaction norm on the
tested identified design** — NOT small-sample accuracy of any single `K_g` entry,
NOT `k ≥ 3`, NOT a permanent-environment decomposition, NOT the R public default,
NOT a production sparse RR solver. `public_covered_count` stays unchanged
(engine-covered ≠ R-public-covered).

## References

- Engine: `src/random_regression.jl` (`legendre_basis`, `standardize_covariate`,
  `legendre_design`, `random_regression_mme`, `fit_random_regression_reml`).
- Covered aim + non-Gaussian family plan:
  `docs/dev-log/decisions/2026-06-30-rr-aim-and-nongaussian-family-plan.md`.
- FA rotation / functionals-not-loadings convention:
  `docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`.
- Kirkpatrick, Lofsvold & Bulmer (1990) covariance-function eigenfunctions;
  Meyer / WOMBAT random-regression covariance functions; ASReml `leg()`.

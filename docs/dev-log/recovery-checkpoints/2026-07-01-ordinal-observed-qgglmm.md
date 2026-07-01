# V6-NS-H2 — Ordinal (K>2) PER-CATEGORY observed-scale h² + QGglmm comparator — 2026-07-01

Implements + externally validates the ordinal (K>2) per-category observation-scale heritability — the
LAST previously-fenced non-Gaussian h² scale. API-shape approved by the maintainer (a new vector field
`h2_observation_by_category`, keeping the scalar `h2_observation = NaN`). Promotes nothing — V6-NS-H2
stays `partial`, public-covered fitting = 1.

## The formula (per-category, validated)
For a K-category ordinal probit trait with cutpoints `θ_1..θ_{K-1}` (`θ_0=−∞`, `θ_K=+∞`), each category
indicator `1[y=k]` is a Bernoulli whose observed-scale h² is, over `η ~ N(μ, V_pred=V_A+V_fixed)`:
```
p_k = E[Φ(θ_k−η) − Φ(θ_{k-1}−η)]           (marginal category probability)
Ψ_k = E[φ(θ_{k-1}−η) − φ(θ_k−η)]           (average ∂P(y=k|η)/∂η)
h²_k = Ψ_k²·V_A / [p_k(1−p_k)]
```
Returned as the K-vector `h2_observation_by_category`; the SCALAR `h2_observation` stays `NaN` (there is
no single ordinal observed h²). `var.p = V_A+V_fixed` (predictor variance; the probit unit residual is
baked into Φ, doc-19 §2.2). Reuses the module's 20-node `_gh_expect` + `_norm_cdf`/`_norm_pdf`.

## External comparator — QGglmm `model="ordinal"`
`comparator/qgglmm_ordinal_observed/compare.R` runs QGglmm's built-in ordinal model
`QGparams(mu, var.a, var.p=V_A+V_fixed, model="ordinal", cut.points=c(-Inf, θ, Inf))$h2.obs` (also a
K-vector) against the engine over 6 cases (K=3 and K=4, varied μ/V_A/V_fixed/cutpoints):

**`max |engine − QGglmm ordinal| = 3.17e-08`** → `PASS`. Sample (μ=0,V_A=0.5,θ=[0,1]): engine
[0.21221, 0.02058, 0.16587] == QGglmm [0.21221, 0.02058, 0.16587]. The category probabilities
(`mean.obs`) also match.

## K=2 reduction (built into the test)
For a single cutpoint (K=2), the two complementary category indicators have EQUAL observed h², and it
equals the `:bernoulli_probit` binary observed-0/1 h² at the same μ, V_A — a self-consistency cross-check.

## Verdict / scope
The ordinal per-category observed h² is implemented + externally validated. This is the LAST fenced h²
scale. ON THIS #221-based branch the Gamma-data scale is still owed (it lands on the sibling #222).
**Once #221 + #222 + this all merge, EVERY non-Gaussian h² scale in the V6-NS-H2 surface is done** —
each externally validated against QGglmm (the four builtins + binary-probit on #221, Gamma latent+data
on #222, ordinal per-category here). STILL owed
for the covered path: an MCMCglmm comparator, a Fisher/Falconer sign-off, intervals/SEs, the R-facing
surface, and maintainer G10. NOT a covered claim; `validation_status()` = 50 UNCHANGED; public-covered
fitting = 1 UNCHANGED.

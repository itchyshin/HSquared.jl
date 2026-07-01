# V6-NS-H2 — Gamma DATA/observation-scale h² + QGglmm custom-model comparator — 2026-07-01

Implements + externally validates the Gamma (log-link) **data/observation-scale** heritability — the
last of the two previously-fenced observation scales (only ordinal K>2 now remains). Promotes nothing —
V6-NS-H2 stays `partial`, public-covered fitting = 1.

## The formula (derived, μ-independent closed form)
Log-link Gamma, mean `μ = exp(η)`, shape `ν`, over `η ~ N(μ₀, V_pred)` with `V_pred = V_A + V_fixed`:
- `Ψ = E[dμ/dη] = E[exp η] = exp(μ₀ + V_pred/2)` (average inverse-link derivative)
- `Var(μ) = (e^{V_pred} − 1) e^{2μ₀+V_pred}` (lognormal variance)
- `E[Var(y|η)] = E[μ²/ν] = e^{2μ₀+2V_pred}/ν` (Gamma conditional variance `μ²/ν`)
- `V_A,obs = Ψ²·V_A`, `V_P,obs = Var(μ) + E[μ²/ν]`

All lognormal, so the ratio reduces to a **μ-independent** closed form:
```
h²_obs = Ψ²V_A / (Var(μ) + E[μ²/ν]) = V_A / [e^{V_pred}(1 + 1/ν) − 1]
```
`0 < h²_obs < 1` (denominator `> V_A` for all `V_pred > 0, ν > 0`). This is the NS-2017 multiplicative
data scale for the Gamma-log family.

## External comparator — QGglmm custom Gamma model
QGglmm 0.8.0 has NO built-in Gamma model, so a CUSTOM model is supplied — **mathematically determined**
by the Gamma-log family (no convention choice):
- `inv.link(η) = exp(η)`, `var.func(η) = e^{2η}/ν` (= `μ²/ν`), `d.inv.link(η) = exp(η)`, `var.p = V_A + V_fixed`.

`comparator/qgglmm_gamma_observed/compare.R` runs `QGparams(..., custom.model=...)$h2.obs` against the
engine over 7 `(μ, V_A, V_fixed, ν)` cases:

| μ,V_A,V_fixed | ν | engine | QGglmm | \|diff\| |
| --- | --- | --- | --- | --- |
| 0.5,0.3,0 | 3 | 0.3750883 | 0.3750883 | 7e-13 |
| 1,0.5,0 | 2 | 0.3394244 | 0.3394244 | 1e-12 |
| 0,0.4,0.2 | 5 | 0.3371139 | 0.3371139 | 6e-13 |
| −0.5,0.2,0 | 10 | 0.5821687 | 0.5821687 | 5e-11 |
| 0.8,0.6,0.3 | 1.5 | 0.1935897 | 0.1935897 | 3e-13 |
| 0,1,0 | 1 | 0.2253997 | 0.2253997 | 4e-13 |
| 1.5,0.8,0.5 | 4 | 0.2230512 | 0.2230512 | 5e-13 |

**`max |engine − QGglmm custom Gamma| = 5.07e-11`** → `PASS`. The engine's closed form matches QGglmm's
independent cubature of the same custom model to quadrature precision.

## Verdict / scope
The Gamma data/observation-scale h² is implemented (`nongaussian_heritability(...; family=:gamma).h2_observation`)
and **externally validated** against QGglmm's custom Gamma-log model. Combined with the Gamma LATENT
scale (trigamma, #222) and the four builtin observation scales (#221), the ONLY remaining observation
scale owed is the **ordinal (K>2)** per-category scale. STILL owed for the covered path: the ordinal
observation scale, an MCMCglmm comparator, a Fisher/Falconer sign-off, and maintainer G10. NOT a
covered claim; `validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED.

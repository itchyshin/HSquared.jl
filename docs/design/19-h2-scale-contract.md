# 19 · The heritability-scale contract (non-Gaussian animal models)

Status: **design contract — pins the convention; claims nothing covered.** Records HOW
`HSquared.jl` defines, computes, and *labels* heritability for non-Gaussian families, so
every family added under the v0.6 plan (and the non-Gaussian RR `k=2` aim) follows ONE
scale convention rather than each slice re-inventing it. The convention is the
**de Villemereuil (QGglmm) / Nakagawa–Schielzeth** framework; it is already implemented
for the four wired families in `src/nongaussian.jl:949–1092` (`nongaussian_heritability`)
and stated as a principle in the family-plan decision
(`docs/dev-log/decisions/2026-06-30-rr-aim-and-nongaussian-family-plan.md`, §Part 2). This
doc makes the principle a precise per-family contract and extends it to the owed families.

**Honesty pins unchanged.** This is a docs/contract slice: no code, no API, no default, no
R wording changes; `validation_status()` stays 48 rows; public-covered FITTING surface
stays **1** (v0.1 univariate Gaussian). Every non-Gaussian h² surface below is
`experimental`/`partial` (no same-estimand QGglmm/MCMCglmm comparator yet).

---

## 1. The rule

> **A non-Gaussian heritability is never reported as a bare `h²`. It always carries an
> explicit scale label — `latent`, `observation`, or `liability` — and the family-uniform
> result payload carries NO `heritability` field at all.**

Off the identity link there is no single heritability: `V_A / (V_A + V_E)` is only the
*latent*-scale ratio, and it is the wrong number to hand a breeder who measured counts or
0/1 outcomes. So:

- `nongaussian_result_payload` is deliberately **family-uniform and h²-free** — it would be
  wrong to "reuse the Gaussian ratio" (`src/nongaussian.jl:1020–1023`).
- Heritability is a **separate, opt-in, self-describing call**, `nongaussian_heritability`,
  returning a `NamedTuple` whose fields name the scale: `h2_latent`, `h2_observation`,
  `var_link`, `var_distribution`, plus `caveat`, `information_limited`, `method`
  (`src/nongaussian.jl:1025–1027`).
- A degenerate scale is returned as **`NaN` with a caveat**, never silently dropped or
  back-filled from another scale (Poisson latent h²; per-record-varying `n_trials`
  observation h²).

This is the cross-cutting, expensive-to-retrofit decision: pin it before adding families.

---

## 2. The three scales

Terminology follows de Villemereuil, Schielzeth, Nakagawa & Morrissey (2016, *Genetics*)
and Nakagawa, Johnson & Schielzeth (2017, *J. R. Soc. Interface*).

**Model.** Linear predictor `η = μ + a + f`, with breeding value `a ~ N(0, A·σ²a)`
(`V_A = σ²a`), fixed-effect contribution `f` (variance `V_fixed`), and a family/link that
maps `η` to the conditional mean `E[y|η] = g⁻¹(η)`.

### 2.1 Latent (link) scale
The scale of `η` itself. Total latent variance adds the link's *implied latent residual*
`V_link` (the "distribution-specific variance"):

```
h²_latent = V_A / (V_A + V_link + V_fixed)
```

`V_link` is a property of the family and link, not of the data: `π²/3` for logit (variance of
the standard logistic), `1` for probit (the classic Gaussian-liability scale), `π²/6` for
complementary-log-log (the Gumbel/extreme-value variance; an owed family), and `σ²e` for the
Gaussian identity link. The **log link is family-dependent**: **`0` for Poisson** — no latent
residual, so its latent h² is **degenerate (`NaN`)** (`src/nongaussian.jl:952–954, 982`), the
exact reason the uniform payload refuses a single h² — but **`ψ₁(ν)` (trigamma of the shape) for
Gamma**, a genuine multiplicative log-scale residual (`Var[log Y] = ψ₁(ν)`), so the **Gamma
latent h² is NON-degenerate** (§3.1). (Link variances verified against Nakagawa & Schielzeth 2017
via the NotebookLM source set: logit π²/3, probit 1, cloglog π²/6; the Gamma `ψ₁(ν)` verified
numerically — §3.1.)

### 2.2 Observation (data) scale
The scale of the measured `y` (counts, proportions). The additive genetic variance is
transported through the *average* inverse-link derivative `Ψ = E[g⁻¹′(η)]`:

```
V_A,obs = Ψ² · V_A                  (Stein's lemma: the variance of the regression of the mean on a)
h²_observation = V_A,obs / ( Var(E[y|η]) + E[Var(y|η)] )
```

with the expectations taken over the **linear-predictor distribution `η ~ N(μ, V_A + V_fixed)`**.

> **The load-bearing subtlety (a documented spec trap).** The integration spreads `η` by the
> *predictor* variance `V_A + V_fixed` **only** — the latent residual `V_link` (e.g. `π²/3`)
> is **NOT** added to the integration variance. `V_link` is an observation-process term; on
> the data scale it reappears as the **sampling variance** `E[Var(y|η)]`, not as predictor
> spread. Adding `π²/3` to the integration variance double-counts it. This matches QGglmm's
> `binom1.logit` (`src/nongaussian.jl:955–962`).

> **Two methods, do not conflate (the genuinely confusing bit).** The engine uses the
> **QGglmm integration** method (de Villemereuil 2016): integrate the inverse-link exactly,
> with the data-scale sampling term `E[Var(y|η)] = E[p(1−p)]` (for Bernoulli `var_dist`); by
> the law of total variance `Var(E[y|η]) + E[Var(y|η)] = p̄(1−p̄)`, the marginal Bernoulli
> variance — the correct data-scale denominator. This is **distinct** from Nakagawa &
> Schielzeth's delta-method **"observation-level variance" `1/[p(1−p)]`**, which is a
> *latent-scale* approximation term (NS 2017 stress it is "clearly different from `π²/3`";
> its minimum is 4). So three different quantities live here and must not be swapped:
> `π²/3` (latent residual, denominator of `h²_latent` only), `E[p(1−p)]` (data-scale sampling
> variance, the engine's `var_dist`), and `1/[p(1−p)]` (NS delta latent term, **not used** by
> the engine). Verified against de Villemereuil 2016 + NS 2017 via the NotebookLM source set.

`Ψ² V_A ≤ Var(E[y|η])`, so `h²_observation ∈ (0,1)` — verified numerically in the suite, not
assumed. **Estimand per family:** PROPORTION for Bernoulli/Binomial, COUNT for Poisson. For
the Gaussian identity link both scales coincide.

> **Non-monotonicity warning.** `h²_observation` is **not** monotone in `σ²a` for some
> families (notably Poisson): raising `V_A` inflates the denominator's sampling term too,
> because the mean–variance coupling moves both. Do not assume "more `σ²a` ⇒ higher data-scale
> h²" (`docs/dev-log/after-task/2026-06-22-h7-*`; the H7 spec error that was corrected).

### 2.3 Liability (threshold) scale
For binary/ordinal traits modelled with a threshold/cumulative link there is an *underlying
continuous liability* `ℓ = η + ε`, observed as `y = 1[ℓ > 0]` (Wright; Dempster & Lerner
1950; Gianola & Foulley for the Bayesian threshold model). The liability scale **is** the
latent scale, with `V_link` the variance of `ε`: **`1` for probit** (Gaussian liability,
the classic Dempster–Lerner scale), `π²/3` for logit (logistic liability).

```
h²_liability = V_A / (V_A + V_link + V_fixed)
```

This is the **selection-relevant** heritability for threshold traits and the natural
estimand for the `:bernoulli_probit` family and the owed ordinal/categorical family (T1).
The observed-0/1 scale connects to it by the Dempster–Lerner transform
`h²_obs = h²_liab · z² / [p(1−p)]` (`z` = standard-normal ordinate at the threshold,
`p` = incidence) — useful as a closed-form cross-check.

---

## 3. Per-family contract

`V_link` = latent residual (§2.1); integration variance is always `V_A + V_fixed` (§2.2).
"Status" is the heritability-surface status, distinct from the family's fitting status.

| Family | Link | `V_link` | Latent h² | Observation/data scale | Liability scale | Estimand | h²-surface status |
|---|---|---|---|---|---|---|---|
| Gaussian | identity | `σ²e` | `V_A/(V_A+σ²e)` | = latent (coincide) | n/a | trait value | **covered** (v0.1) |
| Poisson | log | `0` | **NaN** (degenerate) | log-normal–Poisson closed form: `V_A,obs=λ²V_A`, denom `λ²(e^{V_pred}−1)+λ` | n/a | count | partial |
| Bernoulli | logit | `π²/3` | `V_A/(V_A+π²/3+V_fixed)` | GH quadrature, `Ψ=E[p(1−p)]`, `var_dist=Ψ` | (logit liability) | proportion | partial — `information_limited` |
| Binomial | logit | `π²/3` | same | GH quadrature, `var_dist=Ψ/n_trials` | (logit liability) | proportion | partial |
| **Bernoulli-probit** | probit | `1` | = liability h² | Dempster–Lerner `z²/[p(1−p)]` | **`V_A/(V_A+1+V_fixed)`** | binary→liability | **owed** (follow-up) |
| **Beta-binomial** | logit + Beta | `π²/3` + overdispersion | needs derivation | needs derivation | (logit) | proportion | **owed** |
| **Neg-binomial (NB2)** | log | `0` + overdispersion | needs derivation (NS 2017 NB term) | NS 2017 log-normal form | n/a | count | **owed** |
| **Gamma / lognormal** | log | **`ψ₁(ν)` = trigamma(shape), EXACT** (= Var[log Y]; NOT the `ln(1+1/ν)` lognormal/CV approx) | `V_A/(V_A + ψ₁(ν) + V_fixed)` (non-degenerate, unlike Poisson) | **`V_A/[e^{V_pred}(1+1/ν)−1]`** (NS-2017 multiplicative, EXACT lognormal form; μ-independent; validated vs QGglmm custom Gamma to ~5e-11) | n/a | positive continuous | latent + data both DERIVED + validated; `partial` (§3.1) |
| **Ordinal / categorical** | cumulative probit/logit | `1` (probit) / `π²/3` (logit) | per-threshold liability | category probabilities | **liability (primary)** | ordinal→liability | **owed** (T1, top) |

**Rules for the owed rows (so future slices don't drift):**
1. `V_link` comes from the link's implied latent residual; where an overdispersion parameter
   adds latent variance (beta-binomial, NB2), it is **added to `V_link`** with its own
   derivation (cite the NS 2017 distribution-specific-variance table; do not guess the
   constant).
2. The observation-scale transport is **always** `V_A,obs = Ψ² V_A` integrated over
   `η ~ N(μ, V_A + V_fixed)`; only `Ψ` (the average inverse-link derivative) and the
   sampling term `E[Var(y|η)]` change per family.
3. Threshold families report **liability h² as the primary, selection-relevant scale**; the
   observed scale is secondary and obtained by the Dempster–Lerner transform.
4. Each new family lands `experimental`/`partial` until it has its own Laplace oracle +
   pre-declared recovery gate + a same-estimand comparator (§5).

### 3.1 The Gamma log-scale `V_link` — trigamma, verified (2026-07-01)

The Gamma-log latent residual was tentatively "multiplicative (CV-based)" in the table above; this
resolves it to the **exact** value. On the log link the latent residual is `log Y − log μ =
log(Y/μ)`, whose variance for `Y ~ Gamma(shape ν, mean μ)` is a standard, mean-independent fact:

```
V_link,Gamma = Var[log Y] = ψ₁(ν)      (trigamma of the shape)
```

so the Gamma **latent-scale** heritability is `h²_latent = V_A / (V_A + ψ₁(ν) + V_fixed)` —
**non-degenerate**, unlike the Poisson log link (`V_link = 0`), because the Gamma carries a genuine
multiplicative dispersion. Special case `ν = 1` (exponential): `ψ₁(1) = π²/6 ≈ 1.6449`.

**Numerically verified** (dependency-free, `3×10⁶` Marsaglia–Tsang draws per shape): the empirical
`Var[log Y]` matches `ψ₁(ν)` to 3–4 significant figures across `ν ∈ {0.5, 1, 2, 5}` (e.g. ν=0.5 →
`4.938` vs `ψ₁ = 4.9348`; ν=2 → `0.645` vs `0.6449`), while the **`ln(1+1/ν)` lognormal/CV
approximation is materially wrong** for small `ν` (ν=0.5 → `1.099`, off by ~4.5×). So the exact
`ψ₁(ν)` is the correct `V_link`; the CV/lognormal form is only a large-`ν` asymptotic approximation
and must NOT be used as the constant. This satisfies Rule 1 by **derivation + numerical proof**
(stronger than a table citation).

**Status:** the Gamma **latent**-scale h² (trigamma `V_link`) and the **observation/data**-scale h²
(NS-2017 multiplicative, `V_A/[e^{V_pred}(1+1/ν)−1]`) are BOTH now implemented in
`nongaussian_heritability`, and the data scale is externally validated against QGglmm's custom Gamma
model (~5e-11; `comparator/qgglmm_gamma_observed/`). V6-NS-H2 stays `partial` pending an MCMCglmm
comparator + a Fisher/Falconer sign-off + maintainer G10. The only remaining fenced observation scale
is the **ordinal (K>2)** per-category scale.

---

## 4. Fixed-effect variance (`V_fixed`)

`V_fixed` (the `predictor_variance` keyword) is the variance of the fixed-effect part of the
linear predictor — Nakagawa & Schielzeth's "variance explained by fixed effects" and the
subject of de Villemereuil et al. (2018, *J. Evol. Biol.*) on whether/how to include it.

- Default `0` (no fixed-effect spread beyond the intercept).
- With **>1 fixed effect** the intercept is ambiguous, so `mu` (link-scale population mean)
  is **required** and `predictor_variance` should be supplied
  (`src/nongaussian.jl:1060–1066`).
- Convention: `V_fixed` enters **both** the latent denominator and the observation-scale
  integration variance (it is genuine predictor spread), **unlike** `V_link` which enters
  only the latent denominator. This is the asymmetry that makes the contract non-obvious.

---

## 5. Honesty fences (what blocks "covered")

- **Laplace bias.** The latent `σ²a` from the Laplace/penalized-IRLS fit is downward-biased
  for binary and low-count data (the information effect); the observation- and liability-scale
  h² inherit that bias. Single-trial Bernoulli sets `information_limited = true` with a caveat;
  never present it as clean (`src/nongaussian.jl:1001–1002`). glmmTMB shares the same Laplace
  bias, so glmmTMB *agreement ≠ unbiasedness*.
- **No same-estimand comparator yet.** The h² transform is exact in its closed-form limbs and
  checked against an independent Gauss–Hermite quadrature oracle in `test/runtests.jl`, but it
  has **no external QGglmm/MCMCglmm same-estimand comparator**. Per doc-16 (G11) and doc-04,
  promotion off `partial` needs that comparator + a Fisher/Falconer review
  (`src/nongaussian.jl:1049–1053`).
- **Scope.** Everything here is dense / validation-scale / experimental. None of it is the
  public default; the R bridge does not expose `nongaussian_heritability`.

---

## 6. Mapping to the programme

- **v0.6 (non-Gaussian / GLLVM):** each T1–T3 family lands its h² surface under this contract
  — family calibration + a glmmTMB same-estimand comparator (iid reduction) or own Laplace
  oracle + the scale-labelled report. T1 (ordinal/categorical threshold) is the top target and
  is **liability-scale-primary**.
- **Non-Gaussian RR `k=2`:** the reaction-norm breeding value is curve-valued; h² becomes
  covariate-position-specific, but the *scale* convention (latent/observation/liability) is
  unchanged — report it per evaluation point, scale-labelled.
- **v0.9 (R bridge):** if/when `nongaussian_heritability` is exposed R-side, the scale label
  must travel with the number across the bridge (no bare `h²` in R either).

---

## 7. References (curated; see the NotebookLM page for the seeded set)

**Cornerstones**
- de Villemereuil, Schielzeth, Nakagawa & Morrissey (2016). General methods for evolutionary
  quantitative genetic inference from generalized mixed models. *Genetics* 204:1281–1294. — the
  QGglmm latent/expected/data scales; `Ψ`; Stein's lemma.
- Nakagawa, Johnson & Schielzeth (2017). The coefficient of determination R² and ICC from GLMMs
  revisited and expanded. *J. R. Soc. Interface* 14:20170213. — observation-level / distribution-
  specific variance; delta / lognormal / trigamma for Poisson; the NB term.
- Nakagawa & Schielzeth (2010). Repeatability for Gaussian and non-Gaussian data. *Biol. Rev.*
  85:935–956. — latent vs observed; distribution-specific variance.
- Nakagawa & Schielzeth (2013). A general and simple method for obtaining R² from GLMMs. *MEE*
  4:133–142. — the original variance decomposition.

**Threshold / liability**
- Dempster & Lerner (1950). Heritability of threshold characters. *Genetics* 35:212–236. — the
  observed↔liability transform `z²/[p(1−p)]`.
- Robertson & Lerner (1949). The heritability of all-or-none traits. *Genetics* 34:395–411.

**Fixed-effect variance**
- de Villemereuil, Morrissey, Nakagawa & Schielzeth (2018). Fixed-effect variance and the
  estimation of repeatabilities and heritabilities. *J. Evol. Biol.* 31:621–632.

**Reviews / textbook**
- de Villemereuil (2018). Quantitative genetic methods depending on the nature of the phenotypic
  trait. *Ann. N. Y. Acad. Sci.* 1422:29–47.
- Lynch & Walsh (1998). *Genetics and Analysis of Quantitative Traits*, ch. 25 (Threshold
  characters).

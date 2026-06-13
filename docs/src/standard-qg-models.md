# Standard Quantitative-Genetic Models

`HSquared.jl` covers the standard two-random-effect quantitative-genetic models
(repeatability / permanent environment, common environment, maternal environment)
on top of the same Henderson machinery as the animal model. These are **engine
APIs** — experimental, engine-internal, and **not yet wired to the public R
formula terms** (`permanent()` / `common_env()` still error as planned), with no
external-comparator parity yet. The dense paths are validation-scale.

## Repeatability / permanent environment

`repeatability_mme` solves, at supplied variance components, the model with an
additive genetic effect `a ~ N(0, σ²a·A)` and a permanent-environment effect
`pe ~ N(0, σ²pe·I)` sharing the record→animal incidence `Z` (repeated records are
needed to separate `a` from `pe`).

```@example qg
using HSquared, LinearAlgebra

Ainv = pedigree_inverse([1, 2, 3], [0, 0, 1], [0, 0, 2])
Z = [1.0 0 0; 1 0 0; 0 1 0; 0 1 0; 0 0 1]   # 5 records; animals 1 & 2 repeated
y = [10.0, 11.0, 12.0, 13.0, 9.0]
X = ones(5, 1)
r = repeatability_mme(y, X, Z, Ainv, 1.0, 0.5, 2.0)
(beta = r.beta, animal = round.(r.animal_effects.values; digits = 4),
 pe = round.(r.permanent_effects.values; digits = 4))
```

`fit_repeatability_reml` estimates the three variance components by REML and
returns the **repeatability coefficient** `t = (σ²a + σ²pe)/total` and the
heritability `h² = σ²a/total`:

```@example qg
fit = fit_repeatability_reml(y, X, Z, Ainv)
(variance_components = map(x -> round(x; digits = 4), fit.variance_components),
 repeatability = round(fit.repeatability; digits = 4),
 heritability = round(fit.heritability; digits = 4))
```

(On this tiny illustrative fixture the optimum can sit on a boundary — separating
the components needs replication and relationship contrast.)

## Common environment / maternal environment

`two_effect_mme` is the general kernel for two **independent** random effects,
each with its own incidence, relationship inverse, and variance. Common
environment uses a group incidence with an identity relationship; maternal
environment uses a dam incidence. `repeatability_mme` is the `Z2 = Z1, A2 = I`
special case.

```@example qg
Ainv4 = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
Z1 = Matrix(1.0I, 4, 4)                       # record -> animal
Z2 = [1.0 0; 1 0; 0 1; 0 1]                   # record -> common-env group (2 groups)
yc = [10.0, 11.0, 9.0, 12.0]; Xc = ones(4, 1)
ce = two_effect_mme(yc, Xc, Z1, Ainv4, Z2, Matrix(1.0I, 2, 2), 1.0, 0.5, 2.0)
(beta = ce.beta, animal = round.(ce.effect1.values; digits = 4),
 group = round.(ce.effect2.values; digits = 4))
```

`fit_two_effect_reml` estimates the variances and the two ratios (`ratio1`,
`ratio2` — e.g. `h²` and the common-environment `c²`):

```@example qg
cf = fit_two_effect_reml(yc, Xc, Z1, Ainv4, Z2, Matrix(1.0I, 2, 2))
(variance_components = map(x -> round(x; digits = 4), cf.variance_components),
 ratio1 = round(cf.ratio1; digits = 4), ratio2 = round(cf.ratio2; digits = 4))
```

## Validation boundary

Covered now (self-consistent, comparator-free):

- `repeatability_mme` / `two_effect_mme` match an independent marginal-GLS BLUP
  (~1e-9), and `repeatability_mme` is exactly the `two_effect_mme(Z2=Z1, A2=I)`
  special case;
- `fit_repeatability_reml` / `fit_two_effect_reml` maximize the dense two-effect
  REML log-likelihood (which reduces to the animal-model REML when the second
  variance → 0), the optimum beats a coarse grid, and `fit_repeatability_reml` is
  the reduction of `fit_two_effect_reml`;
- seeded one-off simulations recover the variance components (recorded in the
  after-task reports, not committed — the suite is RNG-free).

Still planned / coordinated:

- the public R `permanent()` / `common_env()` / maternal model-spec mapping;
- correlated direct–maternal genetic effects (a 2×2 genetic covariance);
- variance-ratio uncertainty intervals and a committed recovery harness;
- external-comparator parity (ASReml / sommer / BLUPF90) — R lane.

# Multivariate (Multi-Trait) Models

`HSquared.jl` has a first **multivariate (multi-trait) animal model** engine
slice: `multivariate_mme` solves the balanced multi-trait model at **supplied**
genetic and residual covariance matrices. It is an **engine API** —
experimental, engine-internal, and **not yet wired to the public R formula** —
and it does **not** estimate the covariance matrices (that is a separate
REML/EM slice). The dense path is validation-scale.

## The balanced multi-trait animal model

For `t` traits, `n` records, and `q` related animals:

```math
Y_{i\cdot} = (X B)_{i\cdot} + (Z U)_{i\cdot} + E_{i\cdot},
\quad \mathrm{vec}(U^\top) \sim N(0, A \otimes G_0),
\quad \mathrm{vec}(E^\top) \sim N(0, I_n \otimes R_0),
```

with phenotype matrix `Y` (`n×t`), a fixed-effect design `X` and a record→animal
incidence `Z` **shared across traits**, relationship inverse `Ainv = A⁻¹`
(`q×q`), additive genetic covariance `G0` (`t×t`), and residual covariance `R0`
(`t×t`). Records are ordered individual-major (trait fastest), so the mixed-model
equations carry the genetic precision `Ainv ⊗ G0⁻¹` on the random block and the
residual precision `I_n ⊗ R0⁻¹` throughout.

```@example mv
using HSquared, LinearAlgebra

Ainv = pedigree_inverse([1, 2, 3, 4], [0, 0, 1, 1], [0, 0, 2, 2])
Z = Matrix(1.0I, 4, 4)                       # one balanced record per animal
X = ones(4, 1)                               # shared intercept
Y = [10.0 50.0; 12.0 47.0; 9.0 53.0; 11.0 49.0]   # 4 animals × 2 traits
G0 = [1.0 0.4; 0.4 1.5]                      # additive genetic covariance
R0 = [2.0 0.3; 0.3 1.0]                      # residual covariance

fit = multivariate_mme(Y, X, Z, Ainv, G0, R0; traits = ["trait1", "trait2"])
(beta = round.(fit.beta; digits = 4),
 ebv = round.(fit.breeding_values.values; digits = 4))
```

The per-trait EBVs are the columns of `fit.breeding_values.values` (one row per
animal). The supplied covariances are echoed back, and the corresponding
correlation matrices are derived:

```@example mv
(genetic_correlation = round.(fit.genetic_correlation; digits = 4),
 residual_correlation = round.(fit.residual_correlation; digits = 4))
```

`genetic_correlation` also works directly on any covariance matrix:

```@example mv
round.(genetic_correlation(G0); digits = 4)
```

## Validation boundary

Covered now (self-consistent, comparator-free):

- `multivariate_mme` β and EBVs match an independent **loop-built** multivariate
  MME and an independent **marginal-GLS** BLUP;
- it reduces to the univariate animal model when `t = 1`;
- with diagonal `G0`, `R0` it decouples into `t` independent single-trait fits.

All four checks hold to a committed `1e-10` tolerance (the observed agreement is
machine precision).

Still planned / coordinated:

- **unbalanced / missing-trait records** and a long-format interface (the usual
  reason to fit multi-trait models);
- per-trait fixed-effect and incidence designs;
- multivariate covariance-matrix **estimation** (REML / EM for `G0`, `R0`);
- a published Mrode multi-trait fixture and external-comparator parity (sommer /
  ASReml / JWAS);
- the public R multivariate model-spec mapping — R lane.
```

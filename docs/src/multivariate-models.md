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

## Unbalanced / missing-trait records

Most multi-trait analyses are unbalanced — some animals are not measured on every
trait. Mark an unobserved trait with `missing` or `NaN` in `Y`. That observation
is dropped, and the animal's residual precision uses only its observed-trait
submatrix `inv(R0[Sᵢ, Sᵢ])`. Breeding values are still returned for every animal
and trait (the missing traits borrow information through `G0`):

```@example mv
Ymiss = [10.0 50.0; 12.0 NaN; NaN 53.0; 11.0 49.0]   # animal 2 missing trait2, animal 3 missing trait1
fitm = multivariate_mme(Ymiss, X, Z, Ainv, G0, R0)
round.(fitm.breeding_values.values; digits = 4)
```

With every trait observed this reduces exactly to the balanced solve above.

## Estimating the covariances (REML)

`fit_multivariate_reml` estimates `G0` and `R0` by dense REML — maximizing
`-½(log|V| + log|X'V⁻¹X| + (y−Xβ̂)'V⁻¹(y−Xβ̂))` over a log-Cholesky
parameterization that keeps both matrices positive definite. It accepts the same
inputs (balanced or with missing records) and returns the estimated covariances,
their correlations, per-trait heritabilities, and the breeding values at the
estimate:

```@example mv
fitr = fit_multivariate_reml(Y, X, Z, Ainv)
(genetic_covariance = round.(fitr.genetic_covariance; digits = 3),
 residual_covariance = round.(fitr.residual_covariance; digits = 3),
 heritability = round.(fitr.heritability; digits = 3),
 converged = fitr.converged)
```

!!! warning "Experimental estimator"
    Multivariate REML is **experimental**. Its correctness is checked by
    deterministic self-consistency (the `t = 1` fit recovers the univariate REML
    estimate; the REML log-likelihood matches the univariate package scale; the
    optimum beats a coarse grid). Known-truth recovery for `t ≥ 2`
    is exercised only by one-off simulations and has **no external-comparator
    parity (sommer / ASReml / JWAS) yet**. The multivariate engine has had an
    adversarial review; confirmed robustness findings were fixed and
    regression-tested.
    Treat multi-trait variance estimates as provisional. On small fixtures the
    optimum can sit on a boundary (a genetic correlation of ±1, or a zero
    variance).

## Structured genetic covariance

Phase 4B adds engine utilities for constrained additive genetic covariance
matrices:

```math
G_0 = \mathrm{diag}(\sigma^2), \qquad
G_0 = \Lambda \Lambda^\top, \qquad
G_0 = \Lambda \Lambda^\top + \Psi.
```

The direct matrix builders are `diagonal_covariance`, `lowrank_covariance`, and
`factor_analytic_covariance`:

```@example mv
Λ = reshape([0.8, -0.4], 2, 1)
(diag = diagonal_covariance([1.0, 1.5]),
 lowrank = round.(lowrank_covariance(Λ); digits = 3),
 fa = round.(factor_analytic_covariance(Λ, [0.2, 0.3]); digits = 3))
```

The same structures can constrain the genetic covariance in the dense REML
estimator while leaving the residual covariance unstructured:

```@example mv
fad = fit_multivariate_reml(
    Y, X, Z, Ainv;
    genetic_structure = :factor_analytic,
    rank = 1,
    initial = (loadings = Λ, uniqueness = [0.2, 0.3], R0 = R0),
)
(G0 = round.(fad.genetic_covariance; digits = 3),
 structure = fad.genetic_structure,
 rank = fad.genetic_rank,
 converged = fad.converged)
```

The structured covariance path is **experimental** and dense/validation-scale.
It has deterministic self-consistency tests, but no committed loading-recovery
harness, no covariance standard errors, no external-comparator parity, and no
R-facing covariance-structure syntax.

## Validation boundary

Covered now (self-consistent, comparator-free):

- `multivariate_mme` β and EBVs match an independent **loop-built** multivariate
  MME and an independent **marginal-GLS** BLUP;
- it reduces to the univariate animal model when `t = 1`;
- with diagonal `G0`, `R0` it decouples into `t` independent single-trait fits;
- **unbalanced / missing-trait records** are validated the same way (loop-built
  MME + marginal-GLS with per-individual residual blocks), and reduce to the
  balanced solve when nothing is missing;
- **`fit_multivariate_reml`** is validated by the `t = 1` reduction (recovers the
  univariate REML estimate), the REML log-likelihood matching the univariate
  package scale, the optimum beating a coarse grid, and EBV consistency with the
  MME at the estimate;
- **structured genetic covariance** builders and REML constraints are validated
  by deterministic constructor identities, metadata checks, returned-loglik
  equality to the existing evaluator, PSD/PD covariance checks, and constrained
  fits not exceeding the unstructured REML loglik.

The balanced checks hold to a committed `1e-10` tolerance and the missing-data
checks to `1e-9` (the observed agreement is machine precision).

Still planned / coordinated:

- a long-format interface for the missing-record case;
- per-trait fixed-effect and incidence designs;
- a committed multivariate known-truth recovery harness, covariance standard
  errors, loading sign/rotation conventions, and external-comparator parity
  (sommer / ASReml / JWAS) for the REML and structured-covariance estimators;
- a published Mrode multi-trait fixture;
- the public R multivariate model-spec mapping — R lane.
```

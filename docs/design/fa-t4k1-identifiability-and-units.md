# FA covariance: four traits, one factor, and uniqueness units

Status: Arc A mathematical foundation, 2026-09-27. This note checks a local
algebraic property of the existing Julia FA covariance model. It does not
establish fitted-sample information, interval coverage, an R-facing model
specification, or a broader FA capability.

## Symbol ↔ engine alignment

| Symbol | Meaning and units | Julia representation | Check in `test/runtests.jl` |
| --- | --- | --- | --- |
| `Λ = λ` | Four-by-one loading vector; trait units per unit-variance latent factor | `loadings` in `factor_analytic_covariance` | covariance and sign invariance |
| `Ψ = diag(ψ)` | Specific genetic variances; `ψ_i` has trait `i` squared units | `uniqueness`, `genetic_uniqueness` | recovery from a generic `G`; counterexample |
| `G = λλ′ + Ψ` | Additive genetic covariance; entry `(i,j)` has trait `i` × trait `j` units | `factor_analytic_covariance` and fitted `genetic_covariance` | equality under alternative decompositions |
| `R₀` | Residual trait covariance, distinct from genetic uniqueness | unstructured residual covariance in `fit_multivariate_reml` | no fit is claimed by this algebraic test |

The Gaussian animal-model fit uses this `G` inside the genetic part of its
marginal covariance and estimates a separate `R₀`. Recovering `G` from observed
data also needs a design that separates genetic and residual covariance. The
calculation below assumes `G` is given and asks whether its FA decomposition
is unique locally.

## Separating fitted genetic and residual covariance

The FA Jacobian result above concerns the map `(λ, ψ) ↦ G`; it does not show
that a fitted likelihood can distinguish `G` from `R₀`. In the Gaussian model,
the record covariance is `V = H ⊗ G + I ⊗ R₀`, where `H = ZAZ′`. Let `C_r` be
a full-rank record-level error-contrast basis satisfying `C_r′X = 0`, where
`X` is the record-level fixed design. For trait intercepts, `X = 1_n` and the
response contrast basis is `C_f = C_r ⊗ I_t`, consistent with
`X_f = X ⊗ I_t` and the individual-major, trait-fast ordering. The symmetric
whitened relationship matrix on the record contrasts is

```text
B = (C_r′C_r)⁻¹ᐟ² C_r′ H C_r (C_r′C_r)⁻¹ᐟ².
```

After whitening the record metric, the covariance separates into blocks
`b_j G + R₀` in an eigenbasis of `B`. With an interior unstructured `R₀`,
these components are locally separable when `B` has at least two distinct eigenvalues. If `B` is a scalar
multiple of identity, only that single combination of `G` and `R₀` is observed
on the error contrasts. Therefore the fixed-effects projection, record
replication, and relationship structure matter, even when the FA covariance
map itself has full local rank.

The regression test computes expected Gaussian REML information
`I_ab = ½ tr(P V_a P V_b)` for the 8 FA and 10 unstructured residual
coordinates, using the 12-animal pedigree fixture with two complete records
per animal and trait intercepts. The information is full rank at this
interior generating point under a declared `10⁻⁸` relative eigenvalue
threshold, after scaling each parameter direction by its corresponding trait
standard deviation or variance. This fixed scaling gives the same diagnostic
under simple changes of trait measurement units. The threshold is a numerical
rank criterion. A paired one-record, unrelated-animal design has
`H = I`; after intercept projection its `B` is identity, and the same
information has numerical rank 10 rather than 18 because changes to `G` can be
absorbed by `R₀`. This deterministic check characterizes the two specified
generating covariance designs. The helper is also evaluated at the covariance
returned by the default-plus-balanced optimizer on this fixture. At that
plug-in fit, standardized expected information remains numerical rank 18/18
while the fit diagnostic reports uniqueness near the absolute floor. This is
expected information evaluated at a fitted covariance, not the observed
likelihood Hessian or a calibration result. Neither calculation establishes
population recovery, interval calibration, or general results for other
designs. Near-floor status still limits regular inference.

## Jacobian and rank

For `t=4`, `K=1`, let `λ = (λ₁,…,λ₄)′` and `ψ_i > 0`. The ten distinct entries
of `G` satisfy

```text
G_ij = λ_i λ_j                  i ≠ j
G_ii = λ_i² + ψ_i.
```

The Jacobian of `vech(G)` with respect to the eight coordinates `(λ,ψ)` has
rows

```text
∂G_ij/∂λ_k = 1{k=i} λ_j + 1{k=j} λ_i,
∂G_ij/∂ψ_k = 1{i=j=k}.
```

When every `λ_i` is nonzero, a perturbation that leaves all off-diagonals
unchanged obeys `δλ_i/λ_i + δλ_j/λ_j = 0` for every pair. Any triangle of
traits forces all four loading perturbations to zero; the diagonal equations
then force all `δψ_i = 0`. The Jacobian therefore has rank **8** at such a
point. Equivalently, for distinct `i,j,k` with nonzero off-diagonals,
`λ_i² = G_ij G_ik/G_jk` and `ψ_i = G_ii − λ_i²`. The only remaining loading
ambiguity is a single global sign, `λ → −λ`, which is discrete and does not
remove local rank. The tests pin rank 8 and reconstruct all four `ψ_i`.

The Ledermann slack here is `(4−1)² − (4+1) = 4`, twice the two-dimensional
codimension `10−8`. This dimension count is necessary for a nonsaturated
cell, but it is **not** a pointwise identification proof.

For a concrete failure, take `λ = (1,1,0,0)′`, `ψ = (1,1,1,1)′`, so

```text
G = [2 1 0 0; 1 2 0 0; 0 0 1 0; 0 0 0 1].
```

For any `c` sufficiently close to 1, `λ* = (c,1/c,0,0)′` and
`ψ* = (2−c², 2−c⁻², 1, 1)′` are positive and give **the same `G`**, while
`ψ* ≠ ψ` when `c ≠ 1`. At `c=1` the Jacobian rank is **7**. Thus `Ψ` is
unchanged by a *rotation* of a given loading matrix but is not always
identified by `G`. A fixed rank, positive slack, and a positive `Ψ` alone
cannot support an unconditional uniqueness or regular LRT claim. Other
`(t,K)` cells require their own local-rank analysis.

## Fixed uniqueness floor and scaling

The current fitter uses `ψ_i = 10⁻⁴ + exp(θ_i)` for every trait. The
`10⁻⁴` constant is an **absolute genetic variance** in each trait's squared
measurement units, inherited from the frozen S2 recovery gate. It is not a
dimensionless fraction of `G_ii`, phenotypic variance, or `R₀,ii`. The
constructor `factor_analytic_covariance` accepts any positive `ψ`; the floor
applies to fitted parameterization and initial uniqueness values.

If trait `i` is re-expressed with multiplier `c_i`, let `D=diag(c_i)`.
The covariance model itself transforms exactly:
`Λ* = DΛ`, `Ψ* = DΨD`, and `G* = DGD`. The fitted floor does not transform:
`c_i² ψ_i` can cross below `10⁻⁴` after a change of units. The deterministic
test uses `ψ_i=2×10⁻⁴` and `c_i=1/2`; the transformed covariance is valid,
while the transformed uniqueness `5×10⁻⁵` is refused as a fitter start.
Claims of scale equivariance are therefore confined to the interior where
both parameterizations remain well above the floor. A scale-aware floor would
change the frozen fitting contract and needs a separately predeclared change.

## Inference boundary

At a generic, locally identified, interior `t=4,K=1` null, the FA image can
be a regular lower-dimensional covariance manifold. A classical chi-squared
LRT tail can then be appropriate if the data design identifies `G` separately
from `R₀`, the likelihood information is nonsingular, both fits reach the
relevant optimum, and ordinary asymptotic conditions hold. The present
`covariance_structure_lrt` reports that nominal tail and does **not** test
these conditions. At sparse loadings, an effectively active uniqueness floor,
or a poorly separated genetic/residual design, its p-value is a calculation,
not a validated reference distribution. The existing recovery campaign is
separate evidence; this algebra does not certify its classifier or coverage.

# Genetic GLLVM objective and trait-effect contract

Status: experimental engine contract, 2026-09-27. This note describes the current dense, fully observed implementation in `src/genetic_gllvm.jl`. The R twin has a bounded expert-control Poisson opt-in for the cell below. Neither twin declares broad GLLVM coverage.

## Model and units

Let `Y` have `q` animals and `T` traits, `X` have `p` columns, `A` be the pedigree relationship matrix, and `Λ` be `T × K` loadings. Columns of `F` are independent `N(0, A)` genetic factors. For the factor-analytic option, columns of `D` are independent `N(0, ψ_t A)` trait-specific genetic effects. `F`, `D`, and responses conditional on their linear predictors are independent across these layers. The trait genetic effect is

`U = F Λ′ + D`, with `G = ΛΛ′ + diag(ψ)`; pure low-rank sets `D = 0`. Under column-wise vectorization, `Cov(vec(U)) = G ⊗ A`. The engine stacks traits outermost and animals within trait, matching Julia's column-major `vec(Y)`; permuting traits or animals must permute the corresponding covariance dimensions consistently. `rank = K` means factor count. With positive `ψ`, `G` is full rank even though `K < T`.

For Poisson-log data, `Y_it | U ~ Poisson(exp(X_i β_t + U_it))`. `G` and `U` are on the log-rate scale. No response-scale heritability or covariance is implied. The current fitted `breeding_values` are approximate conditional modes `Û`, not posterior means; for factor-analytic fits they include both `F̂Λ̂′` and `D̂`. Raw factor scores and loadings are rotation-dependent and are not public breeding values.

## Objective actually computed

At fixed covariance parameters, `gllvm_laplace_marginal_loglik` jointly optimizes the `pT` fixed effects and genetic modes, then uses the observed Hessian of **both** blocks at the mode in its Laplace correction. For the pure-low-rank model used by the bounded Poisson cell, with `z = (vec(β), vec(F))`, `P = I_K ⊗ A⁻¹`, and `H = -∂²[ℓ(y | β,F) - vec(F)′P vec(F)/2]/∂z∂z′` at the joint mode, the reported value is

`ℓ(y | β̂,F̂) - 1/2 vec(F̂)′P vec(F̂) + 1/2 log|P| + (pT/2)log(2π) - 1/2 log|H|`.

The factor-analytic extension uses augmented modes `B = [F E]`, augmented loadings `[Λ diag(√ψ)]`, and `D = E diag(√ψ)`, so `U = B[Λ diag(√ψ)]′`. Its mode dimension is `q(K+T)` and its prior precision is `P = I_(K+T) ⊗ A⁻¹`; replace `F` by `B` and `K` by `K+T` in the expression above. The bounded R route described below is pure-low-rank and does not expose this FA extension.

Fisher weights may guide iteration, but an expected-information determinant would be a different approximation for families such as beta-binomial. The fixed effects carry a flat measure in the supplied `X` coordinates. Under a reparameterization `X → XC`, this value shifts by `-T log|det(C)|`; absolute objective comparisons therefore require the same fixed-effect basis/coding and measure. Thus the non-Gaussian value is a fixed-and-genetic-effect **integrated Laplace objective**, rather than ordinary ML that optimizes fixed effects while integrating only random effects. A returned value at a nonconverged outer covariance candidate is only a parameterized objective diagnostic and must be read with its convergence fields, not treated as a fitted optimum. The historical function name `fit_gllvm_laplace_reml` does not change this interpretation. For Gaussian responses, the separate reduction test relates this construction to Gaussian REML. Any comparator must match fixed-effect treatment and basis/measure, integration approximation, relationship matrix, response family, and genetic covariance structure before an optimum or likelihood difference is called parity evidence.

The flat-measure integral requires a full-column-rank `X`. With an intercept,
an all-zero Poisson trait makes it improper: the likelihood approaches a
nonzero constant as that trait intercept tends to minus infinity. A Bernoulli
or binomial trait entirely at either endpoint has the same problem. The kernel
rejects these necessary improper cases, including per-trait family vectors;
other forms of separation may still need detection. For a nonzero-count Poisson trait, it initializes the
intercept at the log trait mean to avoid a zero-start Newton explosion on high
counts. These guards do not establish robustness for every response pattern.
The deterministic `T=3`, `K=2` pedigree fixture converged from the default
and three ordinary loading starts with a fitted objective spread below
`1e-5`; this restart check does not measure population recovery.

The factor-analytic GLLVM fitter uses `ψ = exp(θ)`, while Gaussian FA REML currently uses `ψ = 1e-4 + exp(θ)` in genetic-variance units. Consequently their feasible sets differ near zero; the low-rank model is in the closure of the GLLVM FA model. Global trait-rescaling equivalence fails at the Gaussian fixed floor. These boundaries require explicit alignment or separate disclosure before a cross-engine reduction claim.

## Bounded R opt-in cell

The R twin now exposes Poisson-log, `T = 3`, `K = 2`, pure low-rank `G`, complete balanced records, one pedigree animal effect, and trait intercepts through explicit expert controls. A 12-animal pedigree fixture passed same-input R–Julia parity for `G`, genetic correlations, fixed effects, trait conditional modes, and objective. Its trait correlations need not be ±1, unlike a nonzero rank-one pure low-rank covariance. `GLLVM.jl` and `gllvmTMB` are architectural references; identity-relationship reduction there does not validate pedigree dependence here. Bernoulli, missing records, mixed families, non-Gaussian uniqueness, intervals, rank selection, sparse scalability, and response-scale genetic summaries remain outside this cell.

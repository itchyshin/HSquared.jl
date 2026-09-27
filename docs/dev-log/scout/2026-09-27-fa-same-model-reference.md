# T=4, K=1 pedigree FA: independent fitted REML reference

Date: 2026-09-27. Scope: one tiny Gaussian animal-model fixture and one independently optimized same-model fit. This is an inference review for the candidate `fit_multivariate_reml(...; genetic_structure=:factor_analytic, rank=1)`, not a capability promotion or an interval-calibration study.

## Model and estimand

There are 12 pedigree animals and two records per animal (`n=24` records, `T=4` traits, 96 scalar observations). The genetic and residual covariances are

\[
G=\lambda\lambda^\mathsf{T}+\operatorname{diag}(\psi),\quad
\psi_i=10^{-4}+\exp(\theta_i),\quad R=LL^\mathsf{T},
\]

where `L` is lower triangular with positive diagonal. A separate fixed intercept is fitted for each trait. With records ordered by animal and traits varying fastest, `Z_full=Z ⊗ I_4`, `D=1_24 ⊗ I_4`, and

\[
V=Z_\mathrm{full}(A\otimes G)Z_\mathrm{full}^\mathsf{T}+I_{24}\otimes R.
\]

The reference maximizes the full Gaussian REML log likelihood

\[
\ell_R=-\tfrac12\{(96-4)\log(2\pi)+\log|V|+
\log|D^\mathsf{T}V^{-1}D|+
(y-D\hat\beta)^\mathsf{T}V^{-1}(y-D\hat\beta)\},
\quad \hat\beta=(D^\mathsf{T}V^{-1}D)^{-1}D^\mathsf{T}V^{-1}y.
\]

Thus the residual covariance is estimated as an **unstructured 4×4 matrix**, as in the candidate; this is not the Gaussian genetic-GLLVM model with a fixed scalar residual variance. The comparison uses the same absolute `10^-4` uniqueness floor and same REML constant. The independent R code constructs `A` directly from the sire/dam pedigree recursion, constructs `V` and `D` with Kronecker products, evaluates REML through base-R Cholesky solves, and optimizes 18 coordinates with base-R `optim(method="BFGS")`. It does not call Julia, HSquared likelihood builders, or an R package's FA fitter. The Julia candidate uses its own Nelder–Mead fitter. This is **independent objective construction and independent optimization**, stronger than an objective-only oracle at supplied `G,R`, but still one local numerical comparison.

## Fixture and execution

- R RNG seed `20260927`; founders 1–4. For animals 5–12, `(sire,dam)` is `(1,2),(1,3),(2,3),(3,4),(5,6),(5,7),(6,8),(7,8)`. `A` uses the numerator-relationship recursion and includes inbreeding. Each animal has two records.
- Generating values and the common optimization start: `lambda=(1,.8,.65,.5)`, `psi=(.35,.4,.5,.45)`, `R` diagonal `(1,.9,.85,.8)` with adjacent covariances `R12=.12`, `R23=.08`, `R34=.07`, and other off-diagonals zero. Fixed trait intercepts are `(.3,-.4,.5,1)`. R generates `U=chol(A)' E_g chol(G)` and `E=E_e chol(R)`, with standard-normal entries.
- Candidate checkout: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, HEAD `faed40182cdbba2bf69f3e8dff0c5054be2dd214`, **dirty candidate files**; tested `src/multivariate.jl` SHA-256 `f18a3c5857bce378b65e7efffc48ddedecc5e623a44ee155fb1a204a4f0828fd`. R 4.6.0; Julia 1.10.0. No code in either repository was changed by this reference run.
- Time estimate before fit: under 10 minutes local, four Julia threads and one OpenBLAS thread. Measured R BFGS fit 1.03 s; Julia Nelder–Mead fit 2.49 s after package load (the first run also required about 50 s of isolated-depot compilation). R reported convergence code 0 after 171 function and 90 gradient evaluations; Julia reported `converged=true` after 5,500 iterations of a 10,000 iteration allowance.
- Scratch provenance: `/private/tmp/fa_same_model_reference.R` creates data and independently fits REML; `/private/tmp/fa_same_model_reference.jl` fits the candidate; `/private/tmp/fa_same_model_crosscheck.R` evaluates both estimates and GLS EBVs independently. Run in that order with `Rscript`, `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 JULIA_DEPOT_PATH=/private/tmp/hsq-fa-depot:/Users/z3437171/.julia julia --project=.`, then `Rscript`. Scratch paths are ephemeral; retain the scripts and CSVs with this report if this fixture will become a durable gate.

## Numerical result

| Quantity | Independent R BFGS | Candidate Julia Nelder–Mead |
| --- | ---: | ---: |
| Full REML log likelihood | -149.673026622690 | -149.673015078209 |
| `lambda` | `(1.149495,1.013586,.005954,.391475)` | `(1.149499,1.013587,.005960,.391477)` |
| `psi` | `(.00010509,.00010243,.43873023,.06874739)` | `(.00010005,.00010026,.43873007,.06875257)` |
| `diag(G)` | `(1.321444,1.027459,.438766,.222000)` | `(1.321449,1.027458,.438766,.222007)` |
| `diag(R)` | `(1.379225,1.076627,1.145465,1.027025)` | `(1.379236,1.076631,1.145449,1.027015)` |
| `h²_i=G_ii/(G_ii+R_ii)` | `(.48930252,.48831605,.27695821,.17773861)` | `(.48930141,.48831500,.27696093,.17774442)` |

The maximum absolute entry differences are `7.2491e-6` for `G`, `1.5803e-5` for `R`, and `5.8124e-6` for the derived heritabilities. The log-likelihood difference is `1.15445e-5` in Julia's favour. Independent base-R evaluation at the **Julia** fitted matrices gives `-149.673015078209`, matching Julia to the printed precision. Julia evaluation at the **R** fitted matrices gives `-149.673026622690`, matching independent R to the printed precision. Independent R GLS/BLUP evaluation at the Julia fitted matrices agrees with all Julia EBVs to a maximum absolute difference of `3.22e-15`; using the two separately optimized covariance fits changes an EBV by at most `1.79e-5`.

## Inference risks, ordered by severity

1. **No calibration of uncertainty or recovery.** This single, seed-selected sample supports same-model computational parity near one local solution only. It cannot establish covariance bias, heritability accuracy, EBV reliability, profile/Wald interval coverage, or an FA likelihood-ratio reference distribution. The prior `test/fa_independent_dense_reml.jl` is an objective-only oracle at supplied matrices, not a fitted comparator.
2. **This fit is near a uniqueness boundary.** `psi_1` and `psi_2` approach the absolute `10^-4` floor, and `lambda_3` is about `.006`. Optimizer convergence flags and close matrix agreement do not establish well-conditioned local information, a regular chi-square LRT, or stable decomposition into loadings and uniqueness. The small likelihood difference is consistent with a flat near-boundary direction; no Hessian-rank or profile evidence was run.
3. **Comparator scope is one implementation and one start.** Base-R BFGS is independent code, but it uses the same mathematical model and starts at the generating parameters, as does Julia. It is not an external production FA package comparator, a global optimum proof, or evidence of robust convergence from routine default starts. The `10^-4` floor is in absolute trait-variance units and remains scale-sensitive near the bound.
4. **Derived outputs inherit the fit's limits.** The numerical EBV and per-trait `h²` parity checks validate calculations conditional on this fitted `G,R`. They do not validate breeding-value accuracy, selection response, or confidence statements. No broader G-matrix or genetic-GLLVM claim follows from this fixture.

**Recommendation:** retain the T=4, K=1 Gaussian pedigree FA route as bounded/experimental for user-facing inference claims. This fit is a useful fitted-optimizer comparator and EBV arithmetic check. A promotion argument still needs an interior-information fixture, independent same-model estimator comparisons across starts/designs, predeclared multi-seed recovery with failures retained, and uncertainty calibration for any interval or LRT statement.

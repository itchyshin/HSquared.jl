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

## Exact-current-source rerun and routine-start diagnostic (2026-09-28)

The original comparison above used an older `src/multivariate.jl` hash. To close that provenance gap, the same deterministic comparison was rerun against the active candidate at HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`, with `src/multivariate.jl` SHA-256 `08537788031cd95eb8b7e94100c9f1076071ddfaed6a43a720308b5e495a7201`. Julia 1.10.0 reported `converged=true` after 5,500 iterations; the independent R BFGS objective and Julia objective agreed at both estimates. Maximum absolute differences were `7.2491e-6` for G, `1.5803e-5` for R, `5.8124e-6` for per-trait h2, `3.22e-15` for conditional EBVs evaluated at the Julia estimate, and `1.79e-5` between EBVs at the separately optimized estimates. The matched likelihoods were `-149.673026622690` (R) and `-149.673015078209` (Julia). The estimate was stated before execution as under two minutes after startup; measured fit time was about 2.0 seconds after startup. The rerun scripts and CSVs are in `/private/tmp/fa_same_model_reference.R`, `/private/tmp/fa_same_model_reference.jl`, `/private/tmp/fa_same_model_crosscheck.R`, and `/private/tmp/fa_ref_*.csv`; these are session scratch artifacts, not durable fixtures.

This exact-hash rerun repairs the source-version mismatch for this one truth-start numerical comparison. It does not change the inference limits above: the fit is still near the uniqueness floor and does not establish routine-start reliability or fitted-information adequacy.

The ordinary-start diagnostics below use Julia-generated data from a separate `MersenneTwister` fixture. They are not the R-generated fixture above: matching seed labels do not make the responses or likelihoods comparable.

A five-start diagnostic on the Julia-generated 12-animal, two-record, T=4/K=1 fixture used the ordinary default and four non-default starts. Three non-default starts converged near log likelihood `-143.34075`, with minimum uniqueness from `5.08e-6` to `7.38e-7` above the floor. The default converged at `-143.89042`, with uniqueness at the floor and relative Frobenius differences from the dispersed solution of `0.404` for G and `0.155` for R. A mixed-sign start did not converge at 10,000 iterations and reached `-143.34223`. All values are exploratory observations from one Julia-generated data set. They show that optimizer `converged=true` and the default start do not suffice as reliability evidence; they are not a recovery campaign or evidence of a population-level failure rate. The Julia source hash was the same exact hash above. The scratch script is `/private/tmp/fa-routine-starts-20260928-multistart.jl`.

**Updated A2 disposition: HOLD.** The current-source same-model comparator now has an exact source-hash receipt, while ordinary-start stability, feasible-boundary/stationarity evidence, fitted-information assessment, and recovery remain open. Gauss and Astra/Kirkpatrick agree that the equations and stated identification limits are coherent, but this is not a numerical panel signoff for routine FA fitting.

## Feasible uniqueness profile and floor sensitivity (2026-09-28)

Estimated under two minutes before execution. The deterministic 12-animal,
24-record, four-trait data and independent R BFGS fit above were reused. The
Julia profile evaluator used `src/multivariate.jl` SHA-256
`08537788031cd95eb8b7e94100c9f1076071ddfaed6a43a720308b5e495a7201`; its
NLL at the independent R estimate was `149.6730266226903`, matching the R
objective at printed precision.

With all other fitted parameters fixed, the first two uniqueness estimates
were only `5.0878e-6` and `2.4327e-6` above the `1e-4` floor. Increasing them
from their fitted values by `1e-6` raised NLL by `1.85e-6` and `1.02e-6`,
respectively; increasing by `1e-4` raised NLL by `1.85e-4` and `1.02e-4`.
Reducing their excess above the floor to 2% lowered NLL by `9.24e-6` and
`2.44e-6`. The remaining two uniqueness profiles were steeper. Central finite
differences in the unconstrained loading and residual-covariance coordinates
had maximum absolute component `1.27e-5`; the first two transformed
uniqueness-coordinate gradients were `9.43e-6` and `2.49e-6`. The coordinate
gradient shrinks with the exponential parameterization near the floor, so it
does not establish pointwise information or boundary stationarity in variance
units.

An independent base-R BFGS floor sweep used two fixed non-truth starts at each
floor `1e-5`, `1e-4`, and `1e-3` (six fits total, all returned convergence code
0). At each floor, fitted uniquenesses stayed within at most `3e-5` of the
floor for the first two traits. The NLLs were `149.6728` at floor `1e-5`,
`149.6730` at `1e-4`, and `149.6756` at `1e-3`. Relative to the existing
`1e-4` fit, maximum absolute changes in G and R were below `9.5e-5` and
`5.2e-5` at floor `1e-5`, and below `9.2e-4` and `2.6e-4` at floor `1e-3`.
This single-fixture sweep shows the uniqueness estimates track the imposed
floor while the fitted G and R move less. The saved six-fit table is
`/private/tmp/fa-floor-sensitivity-20260928.csv`; the finite-difference script
is `/private/tmp/fa-boundary-direction-20260928.jl`.

These results apply only to the R-generated fixture. They support a near-floor
constrained solution over the tested floor range, but do not establish a global
optimum, uniqueness identification, or ordinary-start reliability. In
particular, the floor sweep is not a profile likelihood because nuisance
parameters were held fixed during the directional perturbations.

A separate bounded diagnostic then compared the default and a scale-aware
balanced start on three Julia-generated fixtures (seeds 20260927–20260929; six
fits total, estimated under five minutes before execution). On seed 20260927,
both fits reported convergence, but the balanced start improved NLL by 0.550
and changed G/R by relative Frobenius distances 0.404/0.155, reproducing the
earlier start-dependence result. On seed 20260928, the two NLLs differed by
9.3e-7 and G/R by 2.0e-5/2.7e-5, although the balanced fit hit its iteration
limit. On seed 20260929, NLLs differed by 2.5e-7 and G/R by 1.1e-5/1.5e-5.
Every fitted uniqueness was at or very near the absolute floor; this tiny
probe does not establish recovery, a population failure rate, or adequate
information. Together these observations leave two distinct questions open:
boundary behavior on the R fixture and local-start reliability on the Julia
fixtures. Their NLLs must not be compared across RNG fixtures.

A2 stays **HOLD** pending a credible routine-start remedy or explicit usability
boundary, broader interior-information and recovery evidence, and full
numerical panel signoff. Neither the bounded diagnostic nor the independent
R fit is an FA promotion or uncertainty-calibration result.


## 2026-09-29 current-source rerun

The same fixture and independent estimators were rerun after Rose noted that the original source-hash attribution did not establish a match to the current FA multistart implementation. The current-source run used Julia 1.10.0 and R 4.6.0. SHA-256 of `src/multivariate.jl` was `68f1ec986764e06417381008405f492a3bd8da9d8399bbf8511f4467f31ecc55` immediately before and after the Julia fit. R BFGS converged (code 0; 171 function and 90 gradient evaluations; 0.873 s); Julia Nelder-Mead converged (5,500 iterations of 10,000; 2.155 s). Both used the same truth-informed covariance start. The full REML log likelihoods were -149.673026622690 (R) and -149.673015078209 (Julia); maximum absolute covariance differences were 7.2491e-6 for G and 1.5804e-5 for R. Cross-evaluation of each fitted pair in Julia reproduced the corresponding objective to printed precision.

This closes exact-source comparator provenance for one same-model, truth-informed fixture. It does not establish ordinary-start recovery, population reliability, interior uniqueness information, interval calibration, or external package parity. The near-floor uniqueness estimates remain a boundary case. Reproduction logs and data are scratch files: `/private/tmp/fa-same-model-current-20260929-R.log` (SHA-256 `b1fd2a33821d6c741f4fe9f044f9212fcef71eae131499a0f11f2350b3c931bf`) and `/private/tmp/fa-same-model-current-20260929-Julia-rerun.log` (SHA-256 `21cff3661729a8e0e51266dd6b8ebb8df664f64cfd19d09150398309ff1b3460`). The R and Julia harnesses are `/private/tmp/fa_same_model_reference.R` (SHA-256 `af37c74414a31574d7032d3f0db13bbabd384fe7b21879fc36456a79411c9784`) and `/private/tmp/fa_same_model_reference.jl` (SHA-256 `d645a93faaf82213df522c96c4d13e89a7edc222eb2ba330ffa51194bcd90c91`). The generated response matrix hash is `f5ddfd9b0783ac80b87f6135b5e43dde4a0f7748c968ca534d31215b8702a467`; the scratch files are not durable repository fixtures.

# Gaussian FA ordinary-start recovery pre-registration

Status: pre-registered; six development fits at 5,000 are complete. Three converged and met the frozen recovery rules; three exhausted the cap. Same-data 10,000-cap diagnostics for the three nonconverged seeds all converged, but one missed the frozen R-error tolerance. These development results do not estimate a population recovery rate. The 200-seed primary run remains held for approval. This is a bounded recovery check for the existing four-trait rank-one cell. It does not promote FA status or test broad calibration.

The simulation follows ADEMP (aims, data-generating mechanisms, estimands, methods, performance measures; Morris, White & Crowther 2019) and records the Williams et al. (2024) reporting items: [Morris et al.](https://doi.org/10.1002/sim.8086); [Williams et al.](https://doi.org/10.1111/2041-210X.14415).

## A: Aims

Primary aim: estimate how often the default, non-user-informed FA initialization and its built-in restart path recover the pre-specified four-trait, rank-one Gaussian pedigree covariance cell under the existing recovery tolerances.

This evaluates default-start feasibility for this DGP. It is not a comparison with another estimator, external software, interval procedure, or parameterization.

## D: Data-generating mechanism

Use the same fixed DGP as the frozen S2 FA recovery design in `sim/v08_fa_s2_prereg.jl`, but use a fresh seed stream. The pedigree contains 6 founder sires, 12 founder dams, and 42 offspring, for 60 animals. Each animal has 3 complete records on 4 traits. Each trait has an intercept of 1.5. For animal `i` and record `r`:

\[
\operatorname{Cov}(u_i,u_j)=A_{ij}G, \qquad
e_{ir} \sim N_4(0,R), \qquad
y_{ir}=1.5\mathbf 1_4+u_i+e_{ir}.
\]

Equivalently across animals, `U = L_A Z_G L_G'`, implemented as `L_A * randn(q, 4) * L_G'`; residual vectors are drawn independently across records from `N_4(0,R)`. The genetic covariance is `G = ΛΛ' + Diagonal(ψ)`, with `Λ = [0.9, 0.55, -0.35, 0.40]'` and `ψ = [0.35, 0.45, 0.55, 0.50]`. The residual covariance is the fixed positive-definite S2 matrix:

```text
0.85  0.18  0.05  0.06
0.18  0.75 -0.08  0.04
0.05 -0.08  0.65  0.03
0.06  0.04  0.03  0.70
```

There is one cell: `T=4`, genetic rank `K=1`, Ledermann slack `4`, complete balanced records, pedigree relationship, trait intercepts, and estimated unstructured residual covariance. Keep the pre-run seed `20261400` outside the primary stream. The frozen primary seeds are `20261200:20261399` (200 attempted replicates); do not replace failed seeds or tune thresholds after seeing primary results.

The 200-replicate size targets a recovery proportion with Monte Carlo standard error `sqrt(p(1-p)/200)`: at `p=0.8`, MCSE is `0.0283`, so `3 × MCSE = 0.0849`. The study is intended to identify gross recovery shortfall of about 10 percentage points, not small differences or nominal interval coverage. Report the observed fraction, its MCSE, and a binomial interval. The development seed is excluded from these estimates.

## E: Estimands / targets

The main target is the proportion of fresh datasets in this single DGP that pass the fixed per-seed covariance recovery rule under the ordinary default fit. The target is a feasibility/recovery proportion for this cell, not a population-level calibration probability over all FA models.

The data-generating truth is `(G,R)` above and the matching fixed-effect REML objective evaluated by `HSquared._multivariate_reml_loglik` with the same `Y`, `X`, `Z`, `Ainv`, trait order, and complete-response mask as the fitted call. Estimated outputs are `fit.genetic_covariance`, `fit.residual_covariance`, `fit.genetic_uniqueness`, `fit.loglik`, `fit.converged`, `fit.iterations`, and `fit.fa_start_diagnostics`.

Count a seed as recovered only when all of these pre-specified conditions hold:

1. The fit converges and returns finite objective and covariance values with the expected dimensions.
2. Rotation-invariant relative Frobenius errors satisfy `rel_G = norm(Ghat-G)/norm(G) <= 0.45` and `rel_R = norm(Rhat-R)/norm(R) <= 0.25`. These are the frozen S2 diagnostic limits, reused for comparability; they are not an independently validated accuracy standard for ordinary starts.
3. Minimum fitted uniqueness is at least `1e-4`; Ledermann slack is positive.
4. `fit.loglik - truth_loglik >= -1e-6`, using the frozen S2 numerical tolerance. This is a numerical guard, not sufficient evidence of recovery on its own.

Every attempted seed stays in the denominator. Exceptions, nonconvergence, invalid/non-finite outputs, and any failed criterion are counted as non-recovery and retained with a failure classification. Do not compare raw loadings or claim uniqueness identification from fixed rank.

## M: Methods

Fit only `HSquared.fit_multivariate_reml` with `genetic_structure=:factor_analytic`, `rank=1`, and `iterations=5000`, omitting the `initial` keyword entirely. This activates the shipped ordinary start plus built-in balanced restart. No fixed true loading/uniqueness initialization is supplied. No external comparator is included because this is a default-start feasibility test, not a method comparison.

## P: Performance measures

- Recovery fraction: `n_recovered / n_attempted`, counting all failures in `n_attempted`.
- Recovery MCSE: `sqrt(phat * (1 - phat) / n_attempted)`; also report a Wilson 95% binomial interval.
- Among all returned fits, report convergence fraction and counts by failure class; keep exception/non-finite rows.
- Report relative `G` and `R` errors, fitted-vs-truth objective differences, minimum uniqueness, iterations, selected start, per-start validity/convergence, and wall time by seed. Summaries of fit-only errors are explicitly conditional on returning finite fitted outputs.

The development pre-run validates DGP construction, objective alignment, complete failure retention, diagnostic serialization, and elapsed-time measurement only. It does not tune criteria or enter the primary estimates. A same-data diagnostic fit with a 10,000-iteration cap is allowed only to check whether the observed nonconvergence is cap exhaustion; it remains development-only, does not alter the fixed 5,000-iteration primary method, and cannot change thresholds. The first run estimated up to 5 minutes including Julia startup and took 98.4 seconds; it used 92.35 seconds in the fit and did not converge. Before the 200-seed run, estimate total wall time from measured per-seed time plus startup and a 2× margin; if that estimate exceeds 3 hours, stop and show the plan and pre-run result for Shinichi's approval. Cap at 4 Julia threads and 1 BLAS thread. CPU only; no GPU.

## Williams et al. 2024 reporting audit

| # | Item | Status | Where addressed |
|---|---|---|---|
| 1 | Aims | ✅ | A: one primary ordinary-start aim |
| 2 | DGP + n_sim justified | ✅ | D: full DGP, one cell, 200 seeds and MCSE rationale |
| 3 | Estimand / target | ✅ | E: one-cell recovery proportion and estimator output |
| 4 | Methods literature cited | ✅ | Morris et al. 2019 and Williams et al. 2024 above |
| 5 | Performance measures (formulas) | ✅ | P: recovery, MCSE, interval, failure retention, errors, runtime |
| 6 | Software / packages / versions | partial | Driver records Julia version, HSquared candidate SHA, BLAS, host, and thread settings at run time |
| 7 | Code for DGP available | ✅ | `sim/fa_ordinary_start_recovery_20260928.jl` |
| 8 | Code for performance measures | ✅ | Same driver writes row-level metrics and summary |
| 9 | Worked-example case study | gap | Not needed for this narrow recovery gate; no applied case claim |
| 10 | Full performance table | partial | Driver emits one row per attempted seed; summary will be added after the run |
| 11 | MCSE reported alongside | partial | Formula and target fixed here; final MCSE awaits primary results |

## Primary run freeze record

The primary seed stream, 5,000-iteration cap, and recovery criteria remain frozen as above. The corrected candidate source archive SHA-256 was `21712ec08bd84dd577bf77589af564f08225cfd106ab4a751c0124f9941c1a71`; driver SHA-256 was `d96640d3f1d7a1f08e78f76389ed7ff843d6ba195d1c0634accc8f9a62825fdb`. The first transferred archive (`e02791c7…`) failed during Julia parsing before any seed was generated and is not a simulation result.

### Development receipts and runtime gate

All runs used the isolated Totoro directory `/home/snakagaw/hsq_work/fa-ordinary-start-20260928`, Julia 1.10.0, four Julia threads, one BLAS thread, and CPU only. The corrected source archive and driver hashes above match the copied local candidate. Development seeds are excluded from the primary stream.

| Seed | Cap | Outcome | Iterations | Fit seconds | Notes |
|---|---:|---|---:|---:|---|
| 20261400 | 5,000 | nonconverged | 5,000 | 92.35 | Default and balanced starts valid; covariance errors passed the fixed diagnostics; minimum uniqueness was 0.0001118. |
| 20261400 | 10,000 diagnostic | converged | 6,398 | 120.22 | Both starts converged; same-seed extension only diagnoses the 5,000 cap and does not change the primary method. |
| 20261401 | 5,000 | recovered | 4,275 | 64.62 | Balanced start selected. |
| 20261402 | 5,000 | recovered | 2,119 | 42.43 | Default start selected. |
| 20261403 | 5,000 | nonconverged | 5,000 | 93.44 | Both starts exhausted their cap; minimum uniqueness 0.000958. |
| 20261404 | 5,000 | recovered | 3,243 | 65.53 | Both starts converged; balanced start selected. |
| 20261405 | 5,000 | nonconverged | 5,000 | 97.08 | Both starts exhausted their cap; minimum uniqueness 0.000234. |

The six 5,000-cap fits average 75.91 seconds (range 42.43 to 97.08 seconds). Updated conservative planning estimate: 200 × 75.91 seconds × 2, plus startup, about 8.5 hours. This exceeds the three-hour approval threshold. **Primary run is held for Shinichi's approval.** The development results are not a pass-rate estimate and do not alter any primary acceptance rule.

Same-data cap diagnostics, allowed by the preregistration and excluded from the primary seed stream:

| Seed | Cap | Outcome | Iterations | Fit seconds | Notes |
|---|---:|---|---:|---:|---|
| 20261400 | 10,000 | recovered | 6,398 | 120.22 | Both starts converged; uniqueness remained near the absolute floor. |
| 20261403 | 10,000 | recovered | 8,479 | 170.39 | Default converged; balanced start reached the cap. |
| 20261405 | 10,000 | converged, not recovered | 9,133 | 182.72 | Default converged; balanced start reached the cap; relative R error 0.25657 exceeded 0.25. |

The 10,000-cap driver was a diagnostic copy with only ITERATIONS changed from 5,000 to 10,000; its SHA-256 is fca76d24f4e19b21615f798c6eab1a6d529f0ca36d4f51b0ca8f65d51de71e6d. Its output SHA-256 is 235e9fdfbae2e068ef1f489ac660725fbd3e4c07e3cbce52290769d67eedbba3. The driver and output are preserved at /private/tmp/fa_ordinary_start_diagnostic_10k_20260929.jl and /private/tmp/fa-ordinary-start-dev-10k-20261403-20261405-20260929.tsv. The 5,000-cap output for seeds 20261403 to 20261405 is /private/tmp/fa-ordinary-start-dev-20261403-20261405-20260929.tsv.

Across the three same-data diagnostics, all previously nonconverged fits converged at 10,000, but only two met the frozen recovery diagnostics. All three selected fits had minimum uniqueness within 1% of the absolute floor. This supports cap exhaustion as one cause of nonconvergence; it does not establish that a 10,000 default is usable across the target population, nor that uniqueness is accurately estimated.

Receipts: `/private/tmp/fa-ordinary-start-development-20260928.tsv`, `/private/tmp/fa-ordinary-start-development-10k-20260928.tsv`, and `/private/tmp/fa-ordinary-start-development-5k-20260928.tsv`. The primary output path, if approved, is to be set explicitly before launch and recorded here. Do not start primary seeds if the script or criteria change after the pre-run without recording a new freeze and seed stream.

### Integrated candidate checks

On 2026-09-28, the current dirty candidate was copied to `/private/tmp/hsq-integrated-verify-20260928-01`. `diff -qr` confirmed the copied `src/` and `test/` trees matched this worktree before testing. Thread-capped `Pkg.test()` reached the final `Testing HSquared tests passed` marker, including FA trait-unit tests, the independent dense FA REML oracle, the four-start GLLVM check, ordinary GLLVM restarts, and Wave 1/2 contract tests. `julia --project=docs docs/make.jl` rendered the complete local VitePress site and reported `build complete in 5.16s`. Documenter reported 46 docstrings absent from canonical manual blocks; deployment was skipped for the local build. This verifies the copied snapshot's tests and docs build, not CI, deployment, capability promotion, or the held primary recovery campaign.

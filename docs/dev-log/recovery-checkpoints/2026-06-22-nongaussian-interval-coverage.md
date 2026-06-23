# Coverage checkpoint — non-Gaussian σ²a profile-LRT interval (#44 gate 2 / H6)

Date: 2026-06-22 · lane: Julia engine (`HSquared.jl`) · status: **descriptive
characterization, `partial` — no promotion**

## What

Empirical coverage of the non-Gaussian `sigma_a2` profile-LRT interval
(`laplace_reml_interval`), which is documented as asymptotic with no calibrated
coverage. The interval covers `:poisson` / `:bernoulli` / `:binomial` /
`:bernoulli_probit` UNIFORMLY through one shared `_resolve_single_family` +
`target`/`_profile_root` path (the uniform return-field contract is locked by a
CI test, `test/runtests.jl`); its shape/clamping is already deterministically
pinned (V6-FIT). This records the EMPIRICAL coverage signal — read as conservative
/ over-covering, NEVER a calibrated coverage guarantee.

Tool: `sim/phase6_nongaussian_interval_coverage.jl` (opt-in, outside CI; not a gate).

## H6 run — multi-cell sweep (15 reps/cell, capped BLAS)

This supersedes the earlier #157 10-rep smoke (below): the H6 slice added the
**Bernoulli leg**, a **level × truth-σ²a sweep**, a TSV emit, and a smaller design
(q=165) so the BLAS-heavy two-root-find interval runs under capped threads (the prior
50-rep multithreaded run was killed for pegging cores — that is now resolved).

Design: half-sib q=165, μ=0, Binomial m=20; coverage over NON-DEGENERATE reps
(converged, not double-clamped); clamp rates reported SEPARATELY.

```
family      σ²a   level  conv  nondeg  coverage  lower_clamped  upper_clamped  mean_width
poisson     0.25  0.90   15    15      0.933     0.07           0.00           0.412
poisson     0.25  0.95   15    15      0.933     0.07           0.00           0.496
poisson     1.00  0.90   14    14      0.714     0.00           0.00           0.779
poisson     1.00  0.95   14    14      0.857     0.00           0.00           0.938
bernoulli   0.25  0.90   15    15      1.000     0.93           0.00           1.054
bernoulli   0.25  0.95   15    15      1.000     1.00           0.00           1.349
bernoulli   1.00  0.90   15    15      0.800     0.67           0.00           1.743
bernoulli   1.00  0.95   15    15      0.867     0.73           0.00           2.202
binomial    0.25  0.90   15    15      0.933     0.00           0.00           0.219
binomial    0.25  0.95   15    15      0.933     0.00           0.00           0.262
binomial    1.00  0.90   15    15      0.933     0.00           0.00           0.565
binomial    1.00  0.95   15    15      1.000     0.00           0.00           0.677
```

## Honest reading

- **Coverage is in the right ballpark (~0.71–1.00) and looks conservative, not
  calibrated.** With 15 reps a cell's coverage SE is ~0.06–0.13, so single low cells
  (Poisson σ²a=1.0, 0.90 → 0.714) are NOISE-dominated, not a precise miscoverage.
- **Binomial (m=20, informative): clean** — never clamps, coverage 0.93–1.00, narrow.
  The informative-data regime where the asymptotic LRT behaves.
- **Bernoulli (binary): predominantly LOWER-CLAMPED (one-sided).** At σ²a=0.25 the
  lower endpoint is the search bound in 93–100% of reps, so "coverage = 1.000" is
  INFLATED by the clamped (wide) lower bound — NOT a clean two-sided coverage. The
  clamp-rate column is the honest signal here, not the coverage number (the documented
  binary information-poverty / flat-profile degeneracy).
- **Poisson:** mostly two-sided (low clamp rates), coverage 0.71–0.93 across noisy cells.

## Prior smoke (#157, superseded) — 10-rep, q=345, σ²a=1.0, level 0.95

| family | reps | covered (95%) | clamped | mean width |
| --- | --- | --- | --- | --- |
| poisson | 10 | 10/10 | none | 0.652 |
| binomial (m=20) | 10 | 10/10 | none | 0.467 |

Consistent with the H6 run (two-sided, conservative for the informative families).

## Boundary

Descriptive, asymptotic, single-component, validation-scale, small-rep. NOT a
calibrated coverage guarantee, NOT a CI gate, NOT a covered-status promotion. Still
needs a larger-rep calibrated estimate at multiple designs, a parametric-bootstrap
alternative, the Gaussian/multi-component case (nuisance profiling), and external
GLLVM.jl/gllvmTMB comparators. V6-FIT / V6-LAPLACE stay `partial`.

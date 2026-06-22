# Recovery checkpoint — non-Gaussian sigma_a2 interval coverage (#44 gate 2, PRELIMINARY)

Date: 2026-06-22 · lane: Julia engine (`HSquared.jl`) · status: **preliminary
characterization, `partial` — no promotion**

## What

A coverage-calibration harness for the non-Gaussian `sigma_a2` profile-LRT
interval (`laplace_reml_interval`, family = :poisson / :binomial), which is
documented as asymptotic with **no coverage calibration**. This records a
*preliminary* empirical-coverage signal; a fuller calibrated run is future work
(see CPU note below).

Tool: `sim/phase6_nongaussian_interval_coverage.jl` (opt-in, outside CI; not a
gate). Design: half-sib q=345, σ²a=1.0 (latent), μ=0; Poisson `y ~ Poisson(exp(η))`;
Binomial `y ~ Binomial(m=20, logistic(η))`; level 0.95.

## Result (PRELIMINARY — 10-rep smoke)

| family | reps | converged | covered (95%) | lower_clamped | upper_clamped | mean width |
| --- | --- | --- | --- | --- | --- | --- |
| poisson | 10 | 10 | 10/10 | 0.00 | 0.00 | 0.652 |
| binomial (m=20) | 10 | 10 | 10/10 | 0.00 | 0.00 | 0.467 |

## Interpretation (with the honest caveat)

- At this scale the interval is **two-sided with no endpoint clamping** for both
  families (σ̂²a is clear of zero, so the profile crosses χ²₁ on both sides — as
  the V6-FIT note predicts), and the truth was inside the interval in **all 10**
  reps → consistent with a **conservative (over-covering)** interval.
- **This is a 10-rep smoke, NOT a calibrated coverage estimate** (10 reps cannot
  distinguish 0.95 from 1.00). The planned 50-rep run was **killed to free CPU**
  at the maintainer's request — the profile interval is BLAS-heavy (~10s/rep, a
  point fit + two root-finds), so it pegged the machine when multithreaded.
- **Future work (gentle):** a fuller coverage run with capped BLAS threads (or a
  smaller design / more reps over time), to turn "looks conservative" into a
  calibrated coverage number.

## Boundary

Preliminary coverage characterization. NOT a CI gate, NOT a coverage-calibration
*claim*, NOT a covered-status promotion. The interval's shape/bracketing/clamping
remains validated in `test/runtests.jl` (V6-FIT); this only adds a preliminary
coverage signal. Non-Gaussian stays `partial` (`V6-LAPLACE`/`VA`).

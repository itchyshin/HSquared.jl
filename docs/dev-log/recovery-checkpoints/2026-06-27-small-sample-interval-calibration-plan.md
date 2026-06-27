# Small-sample interval calibration plan

Date: 2026-06-27

Status: design checkpoint plus opt-in smoke harness. This is not a capability
promotion and does not change any public interval default.

This plan follows the ADEMP structure of Morris, White, and Crowther (2019) and
records the simulation-reporting items highlighted by Williams et al. (2024).

## Aims

Primary aim: characterize whether any explicitly labelled small-sample
t-quantile probe improves finite-sample coverage for the current Gaussian
heritability and variance-component interval targets, relative to the existing
asymptotic z/delta and profile-LRT paths.

Secondary aims:

- measure the convergence, boundary, and failed-interval rates that would make
  a t-calibrated interval unsafe to expose;
- compare interval width against observed coverage and Monte Carlo standard
  error;
- keep bootstrap percentile intervals in the table as the finite-sample-aware
  reference path, while treating it as opt-in and uncalibrated.

This slice deliberately avoids a public API, a default change, or a covered
status claim.

## Data-generating Mechanism

The first harness uses the v0.1 covered Gaussian animal-model surface:

```text
y = X beta + Z a + e
a ~ Normal(0, sigma_a2 A)
e ~ Normal(0, sigma_e2 I)
h2 = sigma_a2 / (sigma_a2 + sigma_e2)
```

The pedigree design is a small half-sib family generator with founder sires,
founder dams, and one-record-per-animal phenotypes. The relationship matrix is
generated through the existing `normalize_pedigree()` and `pedigree_inverse()`
path, then dense `A` is used only for simulating `a`.

The smoke default is intentionally tiny. A calibration run should expand it
before any claim:

- at least 200 Monte Carlo replicates per condition for triage;
- preferably 500 or more for a promotion-grade coverage table;
- multiple small designs, not only one `n`;
- at least three truth points, including a low-heritability condition where
  boundary behaviour is likely.

## Estimands

The inferential targets are:

- `h2`, the narrow-sense heritability on the Gaussian scale;
- `sigma_a2`, the additive genetic variance component.

Coverage is evaluated against the truth used to simulate each replicate. EBVs,
fixed effects, and prediction intervals are out of scope for this checkpoint.

## Methods

Reference methods are the current shipped interval paths:

- `*_delta_z`: current delta/Wald interval using the standard-normal quantile;
- `*_profile_chisq`: current profile-LRT interval using a chi-square(1)
  cutoff;
- `*_bootstrap_percentile`: existing parametric-bootstrap percentile interval,
  opt-in and finite-sample-aware but not calibrated by this plan.

The t paths are probes only:

- `*_t_residual_df_probe`: a common residual-df shortcut, included as a
  deliberately weak comparator and not treated as a design recommendation;
- `*_t_family_df_probe`: a design-proxy df based on the number of founder
  families and fixed-effect rank, included to test whether family-level
  information is the right scale.

Both t probes use the same standard-error estimates as the delta path. The
quantile in the harness is a labelled approximation for simulation triage; a
production implementation would need an exact, documented quantile dependency
or an independently tested quantile routine.

Local precedent: `freqTLS` successfully used Bates-Watts profile-t / Wald-t
calibration with `qt(df)` and `qt(df)^2` cutoffs, backed by an in-repo coverage
simulation. That supports considering the cutoff form, but not importing the df
rule. The freqTLS rule is `n_obs - length(par)` and its own code comments say
this can overstate df for random-effects fits. HSquared.jl must choose df from
animal-model evidence, not from the analogy.

NotebookLM mixed-model scout: Satterthwaite/Welch and Kenward-Roger corrections
are relevant, but mostly as fixed-effect denominator-df and covariance-adjustment
machinery in standard mixed-model software. For variance components, the better
candidate family is Satterthwaite-style moment matching to a scaled chi-square
reference distribution. Therefore the current t probes are baselines; the next
prototype candidate should be explicitly labelled as a Satterthwaite/scaled-chi
variance-component probe, with separate treatment for heritability.

## DF Probe Rationale

This checkpoint does not choose a degrees-of-freedom rule. It keeps two
deliberately labelled probes so the first grid can falsify easy shortcuts before
any interval method exists:

| Probe | Harness formula | Interpretation |
| --- | --- | --- |
| `residual_df_probe` | `n_animals - rank(X) - 2` | A common residual-df shortcut with two variance-component scalars subtracted. It is a weak comparator, not an animal-model recommendation, because the random effects are integrated out. |
| `family_df_probe` | `n_sire + n_dam - rank(X) - 2` | A half-sib design proxy for family-level information. It is only meaningful for this harness DGP and is not a general effective-df derivation. |

A df candidate survives only if it improves empirical coverage without hiding
non-convergence, boundary/clamp behaviour, or severe width inflation across
small, medium, and low-heritability conditions.

Candidate hierarchy after the NotebookLM scout:

1. Existing profile-LRT and bootstrap remain the strongest interval families to
   calibrate.
2. For `sigma_a2`, the prototype-only Satterthwaite scaled-chi-square probe is
   now in the harness as `sigma_a2_satterthwaite_chisq_probe`; the first
   200-replicate grid found it unstable in low-h2 small designs, so it is not a
   promotion candidate.
3. For `h2`, treat t/logit-delta probes as exploratory because h2 is a bounded
   ratio, not a variance estimator.
4. Keep Kenward-Roger out of this row unless fixed-effect inference enters scope.

## Predeclared Triage Grid

The harness now accepts named half-sib designs via
`--designs=label:nsire:ndam:noffspring`. A lightweight local triage run should
start with no bootstrap, because profile and delta/t wiring are the first target:

```sh
julia --project=. sim/phase1_small_sample_interval_calibration.jl \
  --reps=200 \
  --bootstrap=false \
  --designs=tiny:4:8:24,small:8:16:96,medium:16:32:192 \
  --h2=0.1,0.4,0.7 \
  --levels=0.9,0.95 \
  --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage.tsv
```

At `reps=200`, nominal 95% coverage MCSE is about 1.5 percentage points, so
this is triage, not promotion-grade evidence. A bootstrap subset should then be
run separately to keep compute bounded:

```sh
julia --project=. sim/phase1_small_sample_interval_calibration.jl \
  --reps=50 \
  --nboot=49 \
  --designs=tiny:4:8:24,small:8:16:96 \
  --h2=0.1,0.4 \
  --levels=0.95 \
  --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset.tsv
```

Promotion-grade evidence would need a predeclared larger run, likely on DRAC,
with at least 500 replicates per cell and enough bootstrap replicates that
bootstrap Monte Carlo noise is not mistaken for interval-calibration behaviour.

## Performance Measures

For every target, method, truth point, and confidence level, the harness reports:

- total replicates;
- converged-fit count;
- successful interval count;
- empirical coverage;
- observed and nominal Monte Carlo standard errors;
- mean interval width.

Promotion-grade interpretation must compare empirical coverage to the
predeclared nominal target with MCSE, inspect interval-failure and convergence
rates, and review width inflation. Passing a smoke run is only an executable
check of the harness.

## Williams-style Reporting Self-audit

| Item | Current checkpoint |
| --- | --- |
| Research question | Explicit: finite-sample calibration of Gaussian h2 and sigma_a2 intervals. |
| Data-generating process | Explicit small half-sib Gaussian animal model; broader designs still owed. |
| Estimands | Explicit: `h2` and `sigma_a2`. |
| Methods compared | Existing z/delta, profile-LRT, bootstrap, and two labelled t probes. |
| Simulation factors | Initial smoke factors are narrow; promotion-grade grid is owed. |
| Number of replicates | Smoke is tiny by design; 200-500+ per condition owed before claims. |
| Random seeds | Harness accepts and records a seed. |
| Software versions | Check-log entry must record Julia and HSquared.jl commit for each run. |
| Performance measures | Coverage, MCSE, width, fit success, interval success. |
| Monte Carlo uncertainty | Observed and nominal MCSE are emitted in the summary table. |
| Availability | Harness lives under `sim/`; generated smoke output is committed only as evidence, not as a claim. |

## Claim Fence

This plan creates a validation-debt runway only. Any public wording must still
say the shipped Gaussian intervals are asymptotic unless and until a
predeclared coverage run, Fisher/Curie review, and Rose audit support a
documented change.

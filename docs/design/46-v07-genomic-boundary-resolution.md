# 0.7 genomic GREML boundary-resolution amendment

**Status:** preregistered amendment; implementation and holdout evidence do not
yet exist. This document does not activate the public R route or change a
capability row.

**Depends on:** docs 45, 45a, and 45b and the create-once discovery seal from
Julia execution commit `5d14acd1023db8148fba1dbb0b2d0de17e04b363`.

## Why this amendment exists

The frozen discovery campaign completed all 928 attempts (58 datasets by 16
atomic arms) on Totoro. Under the frozen numerical oracle and tolerances, the
independent base-R classifier found all 29 control datasets to be strict
interior optima and all 29 historical engine-failure datasets to be endpoint
optima: 18 lower and 11 upper. There were no unresolved oracles. Increasing
the AI cap, adding five EM steps, and changing starts therefore cannot be
selected as an honest interior-optimizer repair.

The create-once outcome is `BOUNDARY_POLICY_REQUIRED`, with discovery digest
`33c31a474fc2f0e996d3bd6489a53d055cc753727b69f0625fc30811777c7caf`.
The commits, environment, denominators, artifact hashes, and bounded claim are
recorded in
`docs/dev-log/check-log.d/2026-07-12-v07-optimizer-localization-discovery.md`.
This is evidence about those 58 datasets and that oracle, not a mathematical
proof about all datasets.

The earlier label "failed seeds" described the engine outcome, not the
scientific optimum under the frozen oracle. This amendment does not alter a
discovery row or threshold.

## Scope and staging

The candidate is internal and narrow. It applies only to the frozen genomic
activation shape: Gaussian REML, one genomic random intercept, one record per
aligned genotyped individual, full-rank `X`, and a positive-definite supplied
genomic precision. It is not a general variance-component boundary API and is
not production-scale evidence.

The existing public `fit_ai_reml()` behavior remains unchanged. A positive
holdout permits internal and explicit-experimental R integration of a new
Julia boundary-aware wrapper. Default public R routing remains disabled until
the later recovery and review gates pass. No public optimizer control is added.

## Frozen statistical rule

Write

\[
V=tH(r),\qquad H(r)=rK+(1-r)I,\qquad 0\le r\le1.
\]

At fixed `r`, profile the REML scale:

\[
\hat t(r)=\frac{y^\top P_{H(r)}y}{n-p}.
\]

The profile log likelihood is

\[
\ell_R(r)=-\frac12\{(n-p)[1+\log(2\pi\hat t(r))]
+\log|H(r)|+\log|X^\top H(r)^{-1}X|\}.
\]

The candidate must reproduce the doc-45b oracle algorithm term for term:

1. Run the unchanged AI-REML fit first.
2. Reconstruct `K` from the positive-definite precision and classify the
   closed domain for every fit, including an AI fit reporting convergence.
   This prevents a converged endpoint from being called interior.
3. Evaluate `r = 0:0.0025:1`.
4. Find the best non-endpoint grid point and refine the bracket one grid step
   below and above it using bounded optimization with tolerance `1e-12`.
5. Compare lower, refined-interior, and upper candidates with likelihood tie
   tolerance `n * 1e-10`.
6. Compute endpoint derivatives using `delta = 1e-6`, scaled per observation.
7. A refined value `r <= 1e-7` or `r >= 1-1e-7`, including equality, is
   endpoint-adjacent and never a strict interior candidate. A tie with any
   distinct candidate in `(1e-7, 1-1e-7)` is unresolved.
8. The lower KKT rule is `D0/n <= 1e-8`; the upper KKT rule is
   `D1/n >= -1e-8`.
9. Return `boundary_lower` or `boundary_upper` only when likelihood and KKT
   agree. Return `interior_rescued` only for a distinct strict interior
   optimum. Every other result is `boundary_unresolved` and non-converged.

When the classifier confirms a strict interior optimum and the AI fit meets
the doc-45 objective, component, ratio, and gradient tolerances, the returned
AI components remain numerically unchanged. A classifier-interior AI fit
outside those tolerances becomes `interior_rescued` only if the profiled
components pass; otherwise it is unresolved.

## Exact endpoint versus numerical MME representation

For a scientific endpoint, `t_hat` and the profile likelihood are evaluated at
exactly `r=0` or `r=1` in floating-point arithmetic. The existing MME and
result payload require positive variance components, so the numerical MME uses

```text
boundary_epsilon = 1e-7
lower: sigma_g2 = epsilon * t_hat; sigma_e2 = (1-epsilon) * t_hat
upper: sigma_g2 = (1-epsilon) * t_hat; sigma_e2 = epsilon * t_hat
```

The epsilon components are a computational representation, not a strict
interior scientific estimate.

The internal result contract is:

```text
boundary_status = boundary_lower | boundary_upper | interior | interior_rescued | boundary_unresolved
profile_ratio = 0 | 1 | strict interior profile estimate | missing
numerical_ratio = epsilon representation | AI/profile interior estimate | missing
boundary_epsilon = 1e-7
profile_loglik
lower_derivative_per_observation
upper_derivative_per_observation
```

For `boundary_lower`/`boundary_upper`, every field is finite,
`profile_ratio` is exactly 0/1, `numerical_ratio` is `1e-7`/`1-1e-7`,
`converged=true`, and `termination_reason` equals the boundary status. For
`interior` and `interior_rescued`, the ratios, profile likelihood, and both
endpoint derivatives are finite; termination is `ai_interior` or
`profile_interior`. For `boundary_unresolved`, `converged=false`, termination
is fail-closed, and quantities not established are missing rather than
invented.

The public genomic-ratio extractor returns the scientific `profile_ratio`.
Print and summary show both the scientific ratio and, for a boundary, the
epsilon numerical representation. Ordinary variance-component fields contain
the positive numerical representation and are labelled accordingly. The ratio
is a genomic variance ratio on `K_lambda`, never pedigree, narrow-sense,
population heritability.

For a boundary in this first candidate, uncertainty intervals and all
prediction-derived outputs (GEBV, PEV, reliability, accuracy) are suppressed.
They may not be interpreted from the epsilon MME.

## Failure and resource rules

- Inputs require finite `y`, `X`, and `Q`; `n > p`; full-rank `X`; square,
  symmetric, positive-definite `Q`; exactly identity `Z`; matching ID/kernel
  hashes; successful precision inversion and Cholesky operations; finite
  positive `t_hat`; successful refinement; and finite derivatives. Failure of
  any condition returns `boundary_unresolved`.
- `n > 2,000` (both observations and genomic levels in this shape) returns
  `boundary_unresolved`; dense reconstruction is forbidden above that bound.
- Endpoint pair ties, ties with a distinct interior candidate, and
  likelihood/KKT disagreement are unresolved.
- Dense reconstruction supports no production-scale claim.
- The endpoint representation cannot be used by a non-genomic route.

## Tests of the tests

Unit and integration gates must turn red when any of these are mutated:

- reverse either endpoint KKT sign;
- change `1e-7` to `0`, `1e-6`, or `1e-8`;
- omit endpoint likelihood comparison or accept an endpoint/interior tie;
- label the epsilon representation as a scientific interior estimate;
- remove or alter boundary fields in the R result;
- skip closed-domain classification for an AI-converged fit;
- expose endpoint prediction or uncertainty output;
- permute IDs or alter the kernel hash.

## Create-once candidate seal

Before any holdout file is materialized, a create-once seal must bind:

- the doc-46 commit and SHA-256;
- a clean exact Julia implementation commit descending from the Julia docs 45
  and 46 commits;
- a clean exact R implementation commit whose frozen metadata binds the Julia
  implementation commit and the doc-46 commit and SHA-256;
- driver and independent-oracle SHA-256 values;
- exchange schema and candidate ID;
- epsilon, grid, refinement, tie, derivative, and KKT settings;
- the unchanged holdout seed formula and manifest hash; and
- host, Julia/R versions, project/manifest hashes, and thread settings.

The seal must assert that holdout outputs did not exist before creation. A
candidate that sees these 240 outcomes is spent: if it fails, it cannot be
revised and rerun on them.

## Sealed holdout

The holdout seeds frozen in doc 45 remain unread until the candidate seal
exists. There are 48 seeds in each of the five discovery cells (240 datasets).
Each dataset runs the unchanged default AI path and the sealed boundary-aware
candidate. The independent base-R oracle remains the judge.

Every doc-45 holdout gate remains binding, including:

- at least 95% valid termination among oracle-interior cases in every cell;
- all interior objective, component, ratio, and normalized finite-difference
  gradient tolerances;
- no loss of a default-valid case;
- zero losses, at least one discordant pair, and a one-sided 95%
  Clopper-Pearson lower bound greater than 0.5; and
- candidate p95 runtime at most three times default within each cell.

Additional boundary gates are:

- zero `oracle_unresolved` datasets;
- correct lower/upper status for every oracle boundary;
- `interior` or valid `interior_rescued` for every oracle interior;
- for `interior_rescued`, every doc-45 interior tolerance passes;
- for a boundary, profile ratio, `t_hat`, profile likelihood, endpoint
  derivatives, and KKT classification agree with the independent oracle:
  profile ratio exactly, `t_hat` and each epsilon-represented component within
  `1e-8 + 1e-7 * abs(oracle_value)`, and each per-observation endpoint
  derivative within absolute `1e-8`;
- candidate/oracle likelihood gap is at most `1e-8` per observation;
- every unchanged interior AI result agrees component-wise with the candidate
  to `1e-10`; and
- all attempted seeds remain in the denominator.

Any failure keeps default R routing held. Thresholds cannot be relaxed after
inspection.

## What a positive holdout permits

A positive holdout permits the preregistered nine-cell fresh-seed recovery and
explicit experimental bridge integration to restart with endpoint accounting.
It does not itself activate default R routing, change `public_covered_count`,
or support a production-scale claim. Until the final gate, the public claims
register, capability status, validation-debt ledger, README/article wording,
and count must continue to say default genomic fitting is not activated.
Activation remains conditional on recovery, live cross-twin tests, independent
recomputation, and Fisher/Darwin/Grace/Rose review.

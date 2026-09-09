# H1-two S10 no-go — resolution card

## Evidence

The sealed S10 smoke (`988eec84248964287c4d363bfb598554f48b0822`) retained
the fixed tiny H1-two cell at `n=19`, seed `21270914`, level 0.95. Both ratio
rows had `fit_success=true` but `fit_converged=false` and
`interval_success=false`; the required `ratio1` sentinel denominator is zero.
This is a `PATH_ONLY` no-go, not a coverage result.

This matches the engine contract: `two_effect_ratio_interval` is an
asymptotic, delta-method interval and explicitly warns that small data can have
a flat REML surface/boundary optimum. The existing positive two-effect interval
test and 48-seed recovery evidence use an independently grouped, substantially
larger identified design (`q=200` or larger), not the S10 tiny fixture.

## What cannot happen automatically

- The ratified `H1T-DIAG-S10-FIXED-TINY-01` fixture cannot be replaced with a
  larger cell merely because it failed.
- A zero-success interval denominator cannot be interpreted, pooled, removed,
  or converted to coverage.
- S11/DRAC, claim promotion, versioning, and release remain blocked.

## Maintainer decision required

Choose one explicit next scientific contract:

1. **Hold H1-two calibration out of 0.9.0.** Keep the existing engine capability
   opt-in/asymptotic and remove its calibration claim from the 0.9 release
   bundle. H3 and other admitted claims would still need their own evidence.
2. **Ratify a new identified H1-two calibration fixture.** Supersede the tiny
   diagnostic as a path gate (retain its failure), state the exact larger
   fixture, seed block, success rule, and why it is the target estimand rather
   than a post-hoc rescue. That begins a new S9/S10/S11 chain; it cannot reuse
   the failed S10 as calibration evidence.

No third option—silent fixture widening or sentinel relaxation—is admissible.

## B selected — proposed exact replacement awaiting fixture ratification

Use the already committed deterministic positive-control fixture from
`test/runtests.jl`'s “Phase 3 two-effect ratio interval” test:

- master seed `20260701`; 20 sire founders, 200 offspring, 40 random groups;
- additive pedigree effect and group assignment independent by construction;
- truth `(sigma1, sigma2, sigma_e2) = (1.0, 0.5, 1.0)` and intercept `3.0`;
- one record per offspring, 95% logit-delta intervals for `ratio1` and `ratio2`;
- S10 success: both intervals finite and strictly interior, both `boundary=false`,
  fit convergence true, and `claim_eligible=false`.

This is not selected from the failed tiny S10 output: it pre-existed as a
deterministic passing engine test. It is a replacement **path** fixture only;
the future calibration campaign must still use a fresh seed block and retain
all scheduled failures.

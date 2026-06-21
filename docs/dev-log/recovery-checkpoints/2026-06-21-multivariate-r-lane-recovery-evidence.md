# Multivariate REML R-lane recovery checkpoint — 2026-06-21

## Question

`V4-MV-REML` had a failed strict per-seed recovery calibration gate but later
Julia evidence showed no detectable covariance bias in a 12-seed bias/MCSE
study. The R lane then ran a larger 100-rep cold-start known-truth study. This
checkpoint records how that R-lane evidence changes the Julia validation story.

## Setup

- Evidence source:
  `/Users/z3437171/Dropbox/Github Local/hsquared/data-raw/multivariate-recovery-study.R`
- Design: 420 animals, two traits, one record per animal.
- Starting values: `G0 = R0 = diag(2)`.
- Replicates: 100.
- Target summaries: six G0/R0 covariance entries, `rg`, and two `h2` values.

The R study was not rerun in this Julia slice. The recorded R result block and
R2 coordination note are treated as sibling-lane evidence, not as a fresh local
execution.

## Result

- 100/100 fits converged.
- Every reported target had 0 inside bias +/- 2*MCSE.
- EBV accuracy was 0.790 for trait 1 and 0.742 for trait 2.

## Status Implication

This removes stale wording that multivariate REML recovery lacks broader
corroborating evidence. The old strict per-seed gate still did not pass and is
not re-declared here, but the combined Julia 12-seed and R 100-rep bias/MCSE
evidence now supports a narrower statement: no detectable bias at validation
scale in the recorded designs.

## Remaining Blockers

- Published Mrode-style multi-trait estimate or equivalent textbook target.
- Another independent comparator leg beyond the reproduced `sommer` fixture
  run, such as ASReml, BLUPF90, JWAS, or equivalent.
- Production sparse multivariate fitting.
- Covered/public-default R-facing model specification.

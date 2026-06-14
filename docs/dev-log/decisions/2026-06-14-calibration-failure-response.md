# 2026-06-14 Calibration Failure Response

## Decision

The 2026-06-14 multivariate recovery calibration run is negative evidence. It
must not be converted into a calibration pass by silently relaxing thresholds,
dropping failed seeds, or changing the run plan after seeing results.

`V4-MV-REML` and `V4-FA` remain partial until a new, predeclared, evidence-gated
run passes or an explicitly revised validation target is justified and recorded
before execution.

## What Failed

All fits converged, but the predeclared relative-error thresholds were not met
for every seed:

- unstructured: 6/10 passed;
- factor-analytic: 8/10 passed;
- low-rank: 9/10 passed.

Raw logs and the deterministic summary are recorded in
`docs/dev-log/recovery-checkpoints/`.

## Allowed Next Responses

Allowed future responses must be declared before running:

- increase information in the DGP, such as more animals, more records per
  animal, or stronger balanced structure;
- revise thresholds with a scientific/statistical justification recorded before
  execution;
- add optimizer diagnostics to distinguish sampling variability from optimizer
  failure;
- run external comparator parity for the existing deterministic fixture;
- define a narrower claim, such as "single-seed recovery smoke" or "stress-run
  convergence", without using broad calibration wording.

## Disallowed Responses

- remove failed seeds from the summary;
- rerun new seeds until the pass count looks better without declaring the new
  seed list first;
- cite only max-passing subsets;
- promote `V4-MV-REML` or `V4-FA` to calibrated / covered;
- imply R-facing calibration or comparator parity from Julia-only stress runs.

## Current Claim

The current honest claim is:

> The recovery harnesses support explicit seed lists, and a predeclared
> calibration run was executed. The run did not pass, so broad multi-seed
> calibration remains validation debt.

# 2026-06-14 Multivariate Recovery Calibration Protocol

## Decision

The Phase 4 and Phase 4B recovery harnesses can run explicit seed lists, but
seed-list support is not the same as broad multi-seed calibration. Before any
status row or public-facing document says multivariate REML recovery is
multi-seed calibrated, the calibration run must satisfy the protocol below and
be recorded in a check-log plus after-task report.

## Scope

This protocol applies to:

- `sim/phase4_multivariate_reml_recovery.jl`
- `sim/phase4b_structured_covariance_recovery.jl`
- validation rows `V4-MV-REML` and `V4-FA`

It does not apply to R-facing syntax, bridge payloads, `result_payload()`,
external comparator parity, covariance standard errors, likelihood-ratio tests,
or loading rotation/interpretation.

## Inferential Target

The target is known-truth covariance recovery for the implemented dense
validation-scale estimators under the scripted Gaussian half-sib data-generating
processes.

This protocol does not estimate:

- coverage of intervals;
- Type I error or power;
- external package agreement;
- biological interpretability of factor loadings;
- production sparse or GPU performance.

## Required Run Plan

A calibration run must record, before execution:

- repository commit SHA;
- Julia version and platform;
- exact commands;
- seed list;
- case list;
- iteration cap;
- thresholds for relative `G` and `R` errors;
- data-generating parameters: trait count, sire count, dam count, offspring
  count, records per animal, generating `G` / `R` / loading / uniqueness
  matrices;
- any intentional parameter-grid variation.

The minimum broad-calibration gate is:

- at least 10 seeds for the unstructured Phase 4 harness;
- at least 10 seeds for each requested structured Phase 4B case
  (`factor_analytic` and/or `lowrank`);
- the default iteration cap unless a different cap is declared before the run;
- no seed cherry-picking after seeing results.

## Required Summary

The report must include, for each case:

- number of seeds requested and completed;
- number and proportion passing;
- number converged;
- mean, median, and maximum relative `G` error;
- mean, median, and maximum relative `R` error;
- seed-level table with convergence, iterations, relative errors, thresholds,
  and pass/fail;
- a simple simulation-error interval for the pass proportion, such as a Wilson
  or exact binomial interval;
- all failed seeds and raw command output, not just a filtered summary.

## Claim Rule

Allowed before this protocol is executed:

- "the opt-in recovery harness supports explicit seed lists";
- "historical/default seeds pass through the seed-list path";
- "broad multi-seed calibration remains future work".

Allowed only after the protocol passes and is recorded:

- "the recovery harness passed a recorded multi-seed calibration under the
  specified DGP and thresholds".

Still blocked after this protocol unless separate evidence exists:

- external comparator parity;
- covariance standard errors or LRTs;
- public R-facing multivariate or covariance-structure syntax;
- production sparse/GPU readiness;
- factor-loading biological interpretation.

# H3 r_am scheduler-failure recovery decision

## Observed failure

Narval `r_am` array job `2791966` retained 489 successful rows for tasks 1–489.
Tasks 490–494 each terminated with scheduler exit code 135 and a Julia `SIGBUS`
on node `nc10901`; no task reached Julia's normal failure handler, so no row was
written. The remaining tasks were cancelled under the campaign's stop-on-failure
rule. Completed neighbouring tasks ran on other nodes, so this record treats the
five exits as an external node failure, not a change to the H3 fixture or model.

## Authorized source-inert recovery

The recovery retains tasks 490–494 exactly once as non-interval rows with
`failure_reason = scheduler_sigbus_nc10901`. Those seeds are never rerun or
replaced. A successor Narval array may run only the untouched task indices
495–2000 and must exclude `nc10901`. The original 2,000-seed range, separate
`r_am` reporting, 1,800 interval-success floor, `interval_success` coverage
denominator, MCSE band, fixture, estimator, and `claim_eligible=false` remain
unchanged.

This is not authority for promotion, versioning, tags, registry action, merge,
or release.

## Launcher recovery extension

Recovery array `2833083` exposed a separate source-inert launcher defect before
any fit began: tasks 495–504 could not load `Optim` because their depot path
omitted the existing H1 offline depot. Those ten tasks are retained exactly once
as `launcher_missing_optim_depot` non-interval failures and are never rerun.
The corrected launcher fixes its depot path to the H3 writable depot followed by
the H1 read-only offline depot and sets `JULIA_PKG_OFFLINE=true`. A no-fit
remote package-load precompile is required before only untouched tasks
505–1000, then 1001–2000, may run. The original scientific fixture, seed
universe, estimator, denominators, and release prohibitions remain unchanged.

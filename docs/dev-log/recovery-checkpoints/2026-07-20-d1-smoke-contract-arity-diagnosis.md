# D1 reseal4 smoke contract arity diagnosis

**Date:** 2026-07-20

**Status:** static diagnosis complete; D1 remains paused.
**Scope:** read-only comparison of the sealed R launcher at `hsquared@5325e95`,
the retained D1 controller, and the launcher tests. No Totoro connection, root
read, seed allocation, admission, panel, stage launch, or retry occurred.

## Named failure mode

`SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH`.

The controller treated its `16` argument as a request for 16 smoke attempts.
The `smoke-n-ladder` launcher mode treats that positional argument as the
number of parallel **workers**, then emits one manifest row per distinct `n`.
For the four-rung D1 manifest this is exactly four official attempts. The
controller then called `recommend-workers`, whose first contract is at least
16 completed attempt files. Its failure is therefore deterministic:

```text
|unique(manifest$n)| = 4
smoke-n-ladder output rows = 4
recommend-workers minimum attempt files = 16
4 < 16  ->  RC=21: fewer than 16 completed smoke attempts
```

This explains the recorded four-versus-sixteen outcome without needing to
attribute it to seed quality, model fitting, capacity, or Totoro.

## Static proof

At the sealed R head `5325e95`,
`tools/run-v07-genomic-recovery-v3.sh` defines `manifest_n_ladder()` with
`!seen[$n_col]++`, printing the first `(cell_id, seed)` pair for each distinct
`n`. The D1 manifest has four distinct values (`120`, `300`, `600`, `1200`), so
that function emits four pairs.

The same script's `smoke-n-ladder` case binds `workers=${1:-1}` and pipes
`manifest_n_ladder` to `run_official_pairs "$workers"`; it does not assert a
row count. The retained controller invoked this mode as
`smoke-n-ladder ... 16`, but its own comment described that call as producing
16 rows. Immediately afterward it invoked `recommend-workers`. That function
counts `attempts/<stage>/**/*.tsv` and aborts when `length(paths) < 16L`, before
the later all-rungs and RSS checks. The four retained attempt files therefore
necessarily take the documented `RC=21` branch.

The four actual smoke attempts are consistent with this selection rule: one
for each of `n = 120, 300, 600, 1200`. This is a launcher/controller contract
arity error, not an incomplete or failed fit among an intended 16-row batch.

## Correction to the initial hypothesis

The proposed direction was right—producer cardinality and consumer cardinality
disagree—but the source does **not** show that the verifier expects a complete
four-rung ladder *per seed*. `recommend-workers` enforces a global minimum of
16 files and separately checks that their observed `n` values cover the
manifest's rungs. The demonstrated defect is instead that the controller
confused a worker-count argument with an attempt-count guarantee.

## Test coverage gap

At `5325e95`, the relevant smoke assertions in
`tests/testthat/test-v07-genomic-recovery-v3-launcher.R` are textual checks for
the mode names and diagnostic strings; the file has no composed behavioral
assertion for the path
`smoke-n-ladder -> recommend-workers` on a four-rung manifest, nor assert that
the producer's output count satisfies the consumer's lower bound. Consequently
the two individually visible guards could coexist while their composition was
impossible.

## Boundaries and next gate

This names the D-68 prerequisite failure mode. It does **not** validate any
repair, justify a fifth attempt, allocate replacement seeds, or change the
retirement of `d1-reseal4` and `2028000000/101:148`. A future, separately
authorized planning slice must first decide and preregister the intended smoke
cardinality, then add a static composed-contract regression test that fails
before any official draw when producer and consumer arities differ.

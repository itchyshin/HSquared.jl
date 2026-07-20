# After-task — v0.7 D1 smoke contract arity diagnosis

**Date:** 2026-07-20 · **Lane:** HSquared.jl static diagnostic · **Executor:** Codex

## Task goal

Name the failure mode behind the retired D1 reseal4 four-versus-sixteen smoke result without touching Totoro,
the retired root, or any D1 seed.

## Outcome

Confirmed `SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH`. The controller passed `16` to a launcher
mode where it means workers, not rows. That mode emitted one row for each of the four distinct `n` rungs, then
the controller called a consumer that unconditionally requires at least 16 attempt files.

## Active lenses and agents

Codex performed the source audit. Rose performed a read-only claim audit and returned
**CLEAN-WITH-LIMITATIONS**; its wording limitation on the test description was applied. No remote controller
or compute worker was used.

## Files changed

- This report, the recovery checkpoint, the per-slice check log, and the live coordination/roadmap wording.
- No executable launcher, R/Julia engine, seed ledger, deployment, or generated evidence was changed.

## Checks run and exact outcomes

- Read sealed `hsquared@5325e95` launcher functions `manifest_n_ladder`, `smoke-n-ladder`, and
  `recommend_workers`: producer cardinality is four; consumer minimum is 16.
- Read the retained controller invocation: it supplies `16` as the mode's first positional argument before
  calling `recommend-workers`.
- Read the sealed launcher test: it does not execute the composed producer/consumer path.
- No computation was run and no seed was drawn.

## Public claim audit

No public claim changed. D1 remains unadjudicated; `ordinary_auto_genomic` remains held,
V2-GRM/V2-GINV remain partial, and `public_covered_count=5`.

## Tests of the tests

The diagnosis identified the missing composition assertion: a future repair must prove, statically and
pre-draw, that the selected smoke producer returns enough rows for its immediate consumer. No repair test was
written in this paused diagnostic slice.

## Coordination notes

This completes the failure-naming prerequisite in brain decision D-68. It is not a successor design or a
release of authority to use a new root or seed space.

## What did not go smoothly

The pre-draw panel covered many environmental and provenance risks but not this inter-mode arity contract;
the mismatch became visible only after four official smoke seeds had been consumed.

## Known limitations

The static proof identifies the immediate deterministic stop, not a safe remediation. It makes no claim about
the correct future smoke sample size, scheduler configuration, or the reliability of a repaired campaign.

## Next actions

Keep D1 paused. Only a separately authorized and preregistered planning slice may consider a successor, with
a composed-contract regression test before any fresh admission or official draw. The retired root and seed
space remain untouched.

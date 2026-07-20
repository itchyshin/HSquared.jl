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

## Correction note (appended 2026-07-20) — controller provenance unresolved

**Status:** this note records an unresolved documentation contradiction found during a later
read-only sweep. It does not reopen, repair, or extend D1 work, and it does not investigate
which explanation below is correct. Per owner directive (Shinichi, 2026-07-20): note it, do not
investigate it.

**The contradiction.** This checkpoint's own Scope line (lines 6–8) states: "read-only comparison
of the sealed R launcher at `hsquared@5325e95`, **the retained D1 controller**, and the launcher
tests. No Totoro connection, root read, seed allocation, admission, panel, stage launch, or retry
occurred." The Static proof section (lines 41–43) then reports the controller's own internal
wording: "The retained controller invoked this mode as `smoke-n-ladder ... 16`, but its own
comment described that call as producing 16 rows." A controller's comment can only be quoted by
opening that file. The Scope line asserts no root read occurred; the Static proof section reports
what a controller file's comment said. These two statements cannot both be literally true as
written.

**Sweep evidence.** A read-only sweep this session searched for the controller script in both
working trees and full git history:

- `grep -rn "smoke-n-ladder"` across the HSquared.jl working tree returns only prose references —
  `ROADMAP.md`, the coordination board, dev-log entries, handovers, and this checkpoint — no
  controller script.
- `grep -rln "smoke-n-ladder"` in hsquared returns exactly two files: `tools/run-v07-genomic-recovery-v3.sh`
  (the sealed launcher) and `tests/testthat/test-v07-genomic-recovery-v3-launcher.R` (the launcher
  tests).
- `git log --all -S"smoke-n-ladder"` over full history in both repositories returns only commits
  touching the launcher, its tests, or documentation (hsquared: `c8da16b`; HSquared.jl: doc commits
  `02722a8f` through `5a5faec4`). No commit introduces a controller script.
- No file matching `*controller*` exists in either repository.
- `docs/dev-log/check-log.d/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md:9` names the
  operational script as `d1_reseal4_campaign.sh`; that name likewise is not a committed file in
  either repository.

The controller this checkpoint describes reading was never committed to either repository.

**Three explanations, none asserted.** (a) The controller was a deploy-time artifact that existed
only on the retired Totoro root (`/home/snakagaw/hsq_work/d1-reseal4`, offsets `2028000000/101:148`),
and the diagnosis author read it from a local copy or a campaign log captured before retirement —
no fence breach, only loose wording in the Scope line. (b) The retired root was read as a
diagnostic input after retirement, which the fence at
`docs/dev-log/handover/2026-07-20-claude-handover.md:19` forbids ("do not repair, restart, resume,
subset, pool, read as a diagnostic input, or reuse them"). (c) The diagnosis inferred the
controller's probable intent from the observable four-versus-sixteen outcome and attributed that
inference to a file comment it did not actually read. This note asserts none of the three.

**Unresolvable without breaching the fence; owner directive.** Distinguishing (a)/(b)/(c) would
require exactly the action the fence prohibits — reading `d1-reseal4` / `2028000000/101:148` as a
diagnostic input. Shinichi directed (2026-07-20): note the contradiction, do not investigate it.
This note complies: it records the contradiction and stops there.

**Forward-reading risk.** A future session reading only the checkpoint text above could reasonably
conclude that the "retained D1 controller" is a file it can locate and open. It is not. No
controller script is committed to either repository, and none should be read even if a local copy
surfaces later, since the retired root and its offsets remain fenced regardless of where a copy is
found. Any successor controller — none of which this note authorizes — must be version-controlled
in-repo from the outset, precisely so that a future diagnosis never again needs to describe an
uncommitted, unreproducible artifact as part of its evidentiary chain.

**What does not change.** D-70 stands. The named failure mode
`SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH` is independently provable from the sealed
launcher source alone and does **not** depend on the controller citation: at `hsquared@5325e95`,
`tools/run-v07-genomic-recovery-v3.sh` shows `manifest_n_ladder()` deduplicating on `n`
(`!seen[$n_col]++`, line 376), so a manifest with four distinct `n` values yields four rows; the
`smoke-n-ladder` case (lines 613–619) binds its sole positional argument to `workers`, not attempt
count; and `recommend_workers()` (line 543) hard-fails below 16 completed attempt files
(`if (length(paths) < 16L) stop("fewer than 16 completed smoke attempts", call. = FALSE)`). This
chain uses only the launcher source and the known D1 manifest content (four rungs: `120`, `300`,
`600`, `1200`, as already stated in the Static proof section above) — no controller evidence enters
it. `public_covered_count=5` is unchanged; `ordinary_auto_genomic` remains held; V2-GRM/V2-GINV
remain partial; D1 remains paused.

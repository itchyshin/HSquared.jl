# Handover — Retry-6 terminal; seed-free route repair landed

Meta: 2026-07-15 MDT · `TARGET = codex` · `AUTHOR = codex` · sole sequential H² lane

## Start here

Retry 6 is finished as a negative infrastructure endpoint, not as a scientific
pass:

`UNADJUDICATED_POSTRUN_ADJUDICATOR_ROUTE_BLOCKER`.

Read the full evidence record first:

`docs/dev-log/recovery-checkpoints/2026-07-15-v07-d0f-retry6-postrun-adjudicator-route-blocker.md`.

## What happened

All pre-RNG gates were green. D0F then completed 576 official R fits, 576
independent base-R recomputations, and 576 exact Julia replays. The three
complete summaries agree. The first post-run receipt writer failed before
writing a receipt because Julia rows were correctly admitted as
`julia_profile_replay` and then re-admitted under `ordinary_auto_genomic` by a
summary helper. Exact diagnostics found zero malformed evidence rows.

The entire Totoro root is immutable and retired. No post-run receipt or
adjudication receipt exists; D1/D2 never opened. Do not repair, resume, subset,
pool, or adjudicate this root.

## Current landed repair

The R twin has a seed-free prospective repair:

- `b8096e5`: thread the declared route through D0F and D1 summary
  reconstruction; keep the ordinary-R default and explicitly bind Julia replay;
- `562b93e`: retire all Retry-6 phenotype/bootstrap seeds and remove the
  proposed D0F retry stage.

Synthetic tests prove correct-route green and wrong-route/wrong-driver red.
This repair changes no scientific or public contract and cannot pass Retry 6.

## Hard guards

1. Spend no fresh seed. There is no successor D0F base.
2. Preserve all retired Retry-1 through Retry-6 roots and complete seed spaces.
3. Preserve the H2-2 Retry-5 drafts in both worktrees; they are uncommitted user
   state and remain unstaged.
4. Preserve the quarantined untracked Julia scaffold
   `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`, SHA-256
   `30838979b9f3aad7d3442204fb4a4a30345f24950000d7ecb23a20d63cad6155`.
5. Do not activate, promote, merge, release, change
   `public_covered_count = 5`, or claim G10.
6. Any later successor needs a new preregistered contract, mutation controls,
   exact reviews, clean deploy, preseal, independent chronology audit, and an
   explicit disjoint seed-lock amendment before RNG.
7. Compute is Totoro/DRAC only, never GitHub Actions.

## Lane ownership lesson

H2-2 was archived, not deleted. This task is the sole active H² lane. A Codex
task created for a handover must be announced with its task name, ownership,
and whether the source task is being archived; otherwise the user can
reasonably interpret it as a concurrent lane. The durable memory note is
`20260715-072226-h2-single-thread-handoff-guard.md`.

## Next immediate steps

1. Wait for exact-head R CI and final Julia docs/package/preamble checks.
2. Land and push the cross-twin terminal closeout; keep both PRs draft.
3. Stop. Do not mint a Retry-7 contract or seed allocation without a distinct
   next goal and fresh review cycle.

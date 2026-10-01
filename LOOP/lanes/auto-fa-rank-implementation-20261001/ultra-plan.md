# Approved full programme

Authority: Shinichi approved the complete paired programme with Ultra Plan and Unlazy, then said "let's go".

Read `docs/design/auto-fa-rank-implementation-arc-20261001.md`, `docs/design/auto-fa-rank-contract.md` and `docs/design/auto-fa-rank-validation-plan.md` for the frozen interfaces, numerical rules, failure behavior and O1-O11 independent acceptance cases.

Models: fresh numerical producer gpt-6-sol high; fresh R producer and independent tests gpt-6-luna medium. Parent handles bounded consolidation. At most three active children. Completion panel: two fresh Luna medium plus one fresh Sol high. All workers own disjoint paths and must preserve others' work. Six-producer checkpoint budget; completion panel separate.

Timing: A0 120 minutes; A1 120; A2 90; integration/repair 90; close 30. Total inferred engineering 6-10 hours. First real selector fixture has a ten-minute owned timeout, JULIA_NUM_THREADS=1, OPENBLAS_NUM_THREADS=1; measured runtime replaces assumptions. No campaigns or remote compute.

Unlazy ledger is authored before dispatch, checked with explicit execution CWD, and replayed before completion. Manual judgments are evidence-backed. Required failures are repaired, never silently abandoned. Final reports distinguish bounded experimental mechanics from selection reliability and conditional from selection-adjusted uncertainty.

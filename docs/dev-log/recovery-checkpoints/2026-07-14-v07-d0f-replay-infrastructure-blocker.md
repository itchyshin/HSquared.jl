# v0.7 D0F replay-infrastructure blocker and fresh-retry checkpoint

## Verdict

The first official D0F corpus is complete on the R side but permanently
**unadjudicated**. It is a `REPLAY_INFRASTRUCTURE_BLOCKER`, not recovery
evidence and not a negative estimator result.

## Immutable blocked corpus

- Totoro root: `/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-official-0a9d882-1a538212`
- Official R attempts and base-R recomputations: 576/576 each.
- Julia replay rows: 0.
- Preseal: `2498301ca09949c584e74aa7bed0d468cd49cee893b1d6ded42d4785e30e1a32`.
- Corpus lock: `dee0bb91f40bf0e9183ff6ccd8525b3ba97271edae8819413f90d57fa94bb963`.
- Provisional R summary: `3f09b47037e8cfccb090efb2ea76bfa0825e1f01aed8ebacabd8b17731c577c2`.
- Presealed Julia commit/tool: `1a538212e258ca8e355ecd07420351a5097e3111` /
  `c8b4d2ceb4c01f807efa610002763fc1f5416c35a666427975a7f7972a3b0826`.

The replay preflight called `only()` on the eight phenotype rows belonging to
each fixed panel and stopped before inspecting or writing a replay estimate.
Because the old preseal binds those exact broken bytes, no repaired post-hoc
replay can admit that corpus.

## Prospective repair

The validator now requires exactly ranks `1:8`, verifies every fixed-panel
field and fingerprint is common across the eight rows, and then projects rank 1
as the canonical 72-row representative. A valid 576-to-72 fixture passes;
changed fixed precision, duplicate/missing rank, and changed rank-8 fingerprint
mutations turn red. The fresh phenotype-seed base is `2032000000`; the R-owned
fresh bootstrap base is `2033000000`.

The R twin now retires the exact original 3-design by 24-panel by 8-phenotype
grid at base `2029000000` and the three original bootstrap seeds at base
`2031000000`. The fresh spaces are proven unique, in range, and disjoint.

## Admission boundary

Before any retry phenotype, both repaired twins must be committed, five fresh
hash-bound Fisher/Noether/Hopper/Grace/Rose receipts must pass, and a new root
and preseal must be minted. D1 remains paused until fresh D0F independent
recomputation and adjudication pass. No recovery, activation, capability move,
G10, release, or count change follows from this checkpoint;
`public_covered_count` remains 5.

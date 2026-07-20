# After-task — v0.7 D1 reseal4 post-draw smoke retirement

**Date:** 2026-07-20 · **Lane:** HSquared.jl live-toolchain / Totoro · **Executor:** Codex (sole owner)

## Task goal

Run the already-admitted D1 recovery-v3 campaign through a final receipt only after a fully GREEN panel,
while treating every post-draw terminal failure as a root-and-seed retirement event.

## Outcome

**Terminal negative result.** The unique controller started `smoke-n-ladder` at 08:36:12 UTC. Four official
attempts completed, then its smoke verifier terminated `RC=21` at 10:48:17 UTC: `fewer than 16 completed
smoke attempts`. The controller itself wrote the prescribed `POSTDRAW_TERMINAL_FAILURE` line. There is no
D1 adjudication receipt and no claim of D1 success.

## Active lenses and agents

- Codex alone controlled Totoro. Rose, Curie, Gauss, and Shannon contributed read-only pre-draw GREEN
  reviews; none launched or modified a stage.
- Melissa was asked for a read-only plan-vs-actual reconciliation after the terminal result.

## Evidence and checks

- Done marker: `/home/snakagaw/hsq_work/d1_reseal4_campaign.DONE` = `RC=21`.
- Controller log captured the exact error and retirement line; post-terminal inventory contained 70 files,
  four attempt TSV/sidecar pairs and their four packet trees, with no final-stage artifacts or live D1 PID.
- `d1-reseal4` deployed heads remained R `5325e95` / Julia `418be984`; canonical predecessor receipt was
  `e88207e5…`.
- Local validator regression selftest passed after adding the mandated marker-ratio mutation coverage.

## Files changed

- D1 preregistration, coordination board, capability status, validation-debt register, this report, and
  `check-log.d` record the retirement and maintain the public fence.
- `sim/phase2_v07_genomic_recovery_v3_stage_replay.jl`: synthetic `_validate_manifest` regression cases.

## Public claim audit

No public claim strengthened: `public_covered_count=5`; `ordinary_auto_genomic` remains held;
V2-GRM/V2-GINV remain partial. The four smoke seeds are official and spent, but they are not an adjudicated
D1 result.

## Tests of the tests

The new synthetic selftest proves both sides of the tolerance (`+5e-13` accepts; `+1.1e-12` rejects) and
separately tests non-finite value, `n`, `m`, ratio code, ordering, duplicate seed, missing row, and seed
formula mutations.

## Coordination notes

Codex was the sole Totoro driver. The four panel lenses were read-only; the post-terminal Melissa
reconciliation classified the retirement as protocol-conformant/adaptive and required revoking stale active
authorization language. The R-twin seed-lock retirement amendment must add this D1 space rather than
silently dropping it.

## What did not go smoothly

The smoke controller expected at least 16 completed attempts but the launched n-ladder smoke set materialized
only four. This is a post-draw campaign failure, not a pre-draw warning, and was not repaired in place.

## Known limitations and next actions

The static investigation has named the immediate failure
`SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH`; see
`docs/dev-log/recovery-checkpoints/2026-07-20-d1-smoke-contract-arity-diagnosis.md`. Do not use the retired
root or `2028000000/101:148` for diagnosis or a successor. Any successor needs fresh seed allocation, fresh
preseal/admission, mutation controls, a new panel, and explicit authorization. The failed root remains
preserved on Totoro as negative evidence.

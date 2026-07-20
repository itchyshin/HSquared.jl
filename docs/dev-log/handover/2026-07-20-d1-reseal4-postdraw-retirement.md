# Handover — D1 reseal4 post-draw terminal retirement

## Status

**STOP: do not resume or launch a D1 stage.** The sole authorised Totoro controller completed with
`/home/snakagaw/hsq_work/d1_reseal4_campaign.DONE = RC=21` on 2026-07-20 10:48:17 UTC. Its terminal log
states `Error: fewer than 16 completed smoke attempts`, followed by
`POSTDRAW_TERMINAL_FAILURE: retire root /home/snakagaw/hsq_work/d1-reseal4 and seed space
2028000000/101:148`.

## What happened

- Canonical D0F predecessor reseal4 was PASS/COMPLETE: receipt `e88207e5…`, R `5325e95`, Julia `418be984`.
- D1 `prepare → preseal → preflight` was seed-free PASS; Rose/Curie/Gauss/Shannon pre-draw panel was GREEN.
- `smoke-n-ladder` was the first official draw. Four official seeds completed: `2028020101`, `2028110101`,
  `2028200101`, `2028290101`.
- The smoke controller required 16 completed attempts, stopped fail-closed, and did not run the full corpus.
  The retained root has four attempts and four packet trees, but no corpus lock, recomputation, replay,
  summaries, lineage, post-run reviews, adjudication, or final receipt.

## Non-negotiable boundaries

- Preserve `/home/snakagaw/hsq_work/d1-reseal4` immutable as negative evidence.
- Retire all D1 `2028000000/101:148`, not only the four observed seeds. No retry, resume, pooling, subset,
  or in-place fix.
- No public activation, no `ordinary_auto_genomic`, no V2-GRM/V2-GINV promotion; `public_covered_count=5`.
- A successor, if ever pursued, requires a new root, disjoint allocation, new pre-registration, launcher
  contract investigation, fresh mutation controls/reviews/preseal, and explicit authorization.

## Local closure evidence

- Terminal report: `docs/dev-log/after-task/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md`.
- Check entry: `docs/dev-log/check-log.d/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md`.
- `21fd2425` adds the deferred D1 manifest marker-ratio mutation coverage; its synthetic Julia selftest passed.
- Preserve the existing unrelated protected carryovers; do not stage them.

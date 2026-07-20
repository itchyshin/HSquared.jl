# v0.7 D1 reseal4 — post-draw smoke terminal failure and retirement

**Date:** 2026-07-20. **Executor:** Codex, sole Totoro controller owner. **Outcome:** negative evidence;
root and seed space retired, no receipt.

- The fresh `d1-reseal4` root passed `prepare → preseal → preflight` seed-free against canonical D0F
  reseal4 (`e88207e5…`; R `5325e95`, Julia `418be984`). The documented Rose/Curie/Gauss/Shannon panel was
  unanimously GREEN, so the standing conditional authorization admitted the one controller.
- `d1_reseal4_campaign.sh` started `smoke-n-ladder` at **08:36:12 UTC**. It drew four official seeds:
  `2028020101`, `2028110101`, `2028200101`, and `2028290101`, each with an attempt TSV and immutable packet
  pair. These are official consumed seeds, not a seed-free smoke check.
- At **10:48:17 UTC** the controller wrote `RC=21`: `Error: fewer than 16 completed smoke attempts`, then
  `POSTDRAW_TERMINAL_FAILURE: retire root /home/snakagaw/hsq_work/d1-reseal4 and seed space
  2028000000/101:148`. Capture at 10:48:45 UTC found no live D1 process and 70 retained files.
- No full 576-fit corpus, corpus lock, independent base-R recomputation, Julia replay, summaries, lineage,
  post-run review, adjudication, or `validate-final` receipt exists. The root is **UNADJUDICATED** and is
  preserved; no repair/restart/resume/subset/pool is authorized.
- Status fence: no public route activation, no V2-GRM/V2-GINV promotion, and `public_covered_count=5`.

Local Julia regression coverage was added separately in `21fd2425`: `_validate_manifest` accepts
marker-ratio `+5e-13` and rejects `>1e-12`, non-finite values, `n`/`m`/code/order/duplicate/missing-row,
and seed mutations. `julia --project=. sim/phase2_v07_genomic_recovery_v3_stage_replay.jl --mode=selftest`
passed (synthetic only; no official RNG).

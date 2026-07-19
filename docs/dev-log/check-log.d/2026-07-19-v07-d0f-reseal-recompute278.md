# v0.7 D0F RE-SEAL (recompute.R:278 fix, C_fix 5325e95) — PASS/COMPLETE, identical fits

**2026-07-19. Julia-lane docs + R-lane fix; run on Totoro; SOLO platform = Claude. No seed drawn.**

## Why re-seal

A zero-seed D1 admission step (`prepare d1`) failed fast on the certified retry8 deployment because
`hsquared/tools/v07_genomic_recovery_v3_recompute.R:278` set `r_recomputer_path = script` (a self-locator
that, under D1's inline predecessor re-validation, collapses onto the driver via `commandArgs("--file=")`).
The fix derives the path by name (matching sibling paths and the driver's own sealer). Two unconditional
git-identity gates in `v3p_validate_stage_preseal` (preseal.R:967 clean-tree; :972–976 HEAD==sealed R
commit) bind the whole R worktree, so the fix cannot be applied without re-sealing D0F. Root cause +
route: `docs/dev-log/2026-07-18-d1-blocker-recompute-278-reseal-required.md`.

## The receipt (Totoro: `reseal-d0f/stage_adjudication_receipt.tsv`)

- `schema_version` `v07-genomic-recovery-v3-adjudication-2`, `stage` d0f, **verdict PASS, stage_decision
  COMPLETE**. sha `0f5fbb5437b30a09cd80e62e0ebd017e4b0b54121d259a1f8fd07dc06c87cd56`.
- `adjudicate` sha == `validate-final` sha (RC=0) — new receipt byte-reproduced within-run.
- `attempt_max_diff = 3.1832314562052488e-12` — bit-identical to retry8. Tally 556 interior / 10 lower /
  10 upper — identical. 5 post-run reviews (fisher/noether/hopper/grace/rose) CLEAN.
- Identity fields (vs retry8 `04cc0740`): `r_driver_commit`=`r_recomputer_commit` `a23b15b→5325e95`,
  `r_recomputer_sha256` `cef0b993→eb29c8f4`, `preseal_sha256` `7dafa2b7→b209ec0c`, `adjudication_key_sha256`
  `→88d4cf2f`; `r_driver_sha256` `d1a7d930` and `julia_replay_commit`/`sha256` `976814`/`fb5d5dff` unchanged.

## summary_max_diff — investigated, benign

`summary_max_diff` moved `7.1054e-15 → 2.2737e-13` (both ≪ the 1e-10 gate). Gauss traced it: the summary
parity set includes `median`/`p95` `runtime_seconds` and `peak_rss_mb` (excluded only from
`attempt_max_diff`); the forced re-run re-measured those; the max cell is a runtime/RSS median where R
`(a+b)/2` and Julia `a+0.5(b−a)` differ by exactly 1 ULP. Both values are exact powers of two
(`2^-47`, `2^-42`; ratio 32) — a single-ULP reshuffle whose magnitude rose from a ~tens-of-seconds runtime
to a ~1024 MB peak-RSS. `recompute.R:278` is identity-only; no scientific quantity moved. Detail:
`scratchpad` Gauss finding (session-local).

## Supersede + close-out

12-doc supersede applied via a verified apply-list (a 39-agent inventory+adversarial-verify workflow, which
overrode the raw inventory on 3 files to avoid corrupting frozen records). Live citations moved
(`04cc0740→0f5fbb54`, `a23b15b→5325e95`, `summary 7.11e-15→2.27e-13`); the blocker note, both handovers,
the 2026-07-17 pre-regs, the retry8 after-task/check-log.d, and the archive were left untouched (append-only
for check-log.md; retry8 snapshot archived verbatim before the AGENTS block was replaced). Spawned-Rose
close-out **CONFIRMED-WITH-CAVEATS** (PASS holds; required the summary-figure update + this caveat).

## Bounds

`public_covered_count` stays **5**; no route/count move; `ordinary_auto_genomic` not activated;
V2-GRM/V2-GINV stay partial; R↔Julia contract unchanged. NEXT = D1 (pre-reg predecessor now `0f5fbb54`;
preflight → adversarial panel → conditional draw).

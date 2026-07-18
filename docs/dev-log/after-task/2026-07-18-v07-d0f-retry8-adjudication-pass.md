# After-task — Retry-8 D0F genomic-recovery-v3: adjudication receipt PASS/COMPLETE

**Date:** 2026-07-18 · **Lane:** Julia engine (HSquared.jl) + R lane (hsquared), executed together this
session on Totoro · **Executor:** Claude (user-authorized).

## Task goal

Produce a sealed, byte-reproducible D0F adjudication receipt (`v07-genomic-recovery-v3-adjudication-2`) for the
Retry-8 root by running the validated `run-official` pipeline all the way through `adjudicate` + `validate-final`
— whatever the verdict — such that the receipt re-derives byte-identical and survives its own `validate-final`.
Preserve root-forfeit discipline; spawned-Rose close-out; `public_covered_count` stays 5.

## Outcome (met)

Receipt `retry8-prep/d0f/stage_adjudication_receipt.tsv`: **verdict PASS, stage_decision COMPLETE**, sha
`04cc074071a02b58fa269f3a4b65a8455314bb40b97b2b9c7b6af91f485d7e80`; `validate-final` re-derived it byte-identical
(RC=0, same sha). First COMPLETE receipt across the whole recovery arc (retries 4–7 all died in this tail).

## Active lenses and spawned agents

- **Adversarial pre-draw verification panel** (Workflow, 3 rounds, 4 lenses each: env-fix, pristine, seed-lock,
  contract). Panels 1 & 2 = NO-GO (caught two real pre-draw blockers); panel 3 = GO (all GREEN). Gated the draw.
- **Spawned-Rose systems auditor** (`rose-systems-auditor`, fresh context) for the close-out: verdict
  **CONFIRMED** — receipt sha-exact, all seals/commits/reviews/summaries/lineage match live files, both lanes
  git-clean, `public_covered_count` held at 5, route un-activated, nothing overstated.

## Files changed (committed a5f9b853, pushed to origin)

- `AGENTS.md` — Live Phase Snapshot replaced (old entry archived verbatim first).
- `docs/design/capability-status.md` — header records Retry-8 PASS/COMPLETE within pre-registered bounds.
- `docs/dev-log/phase-snapshot-archive.md` — prior snapshot appended.
- `docs/dev-log/check-log.d/2026-07-18-v07-d0f-retry8-adjudication-pass.md` — new check-log entry.
- (Totoro, not in repo: the sealed d0f corpus + receipt; the env-fix scripts/snapshot under `hsq_work/envfix/`.)
- Left untouched (CARRIED-OVER, not this session's): 2 modified retry5 docs + untracked `sim/…downstream_replay.jl`.

## Checks run and exact outcomes

- **Env fix reproducibility:** embedded `hs_julia_setup` `ok=TRUE` 3/3 (with the fix), FALSE without; then 5/5
  loads keeping `julia_root` git-clean (byte-identical to sealed 976814).
- **Draw:** run-official 576/576 fits `status=success, converged=true` (556 interior, 10 lower, 10 upper), all
  finite `scientific_ratio`.
- **Cross-checks:** recompute-base-r 576/576 (RC=0); replay-julia 576/576, replay-vs-official max-abs-diff ~1e-13;
  verify-replay "verified complete quiescent replay rows=576".
- **Adjudication:** triple parity attempt max-diff 3.183e-12, summary 7.105e-15 (both ≤ 1e-10); adjudicate RC=0;
  validate-final RC=0, byte-identical.
- **Reviews:** 5/5 (fisher/noether/hopper/grace/rose) CLEAN, RC=0.
- **Seal integrity (post-run, independently + via Rose):** manifest `73656022…`, corpus_lock `262aedb6…`,
  preseal `7dafa2b7…`, commits a23b15b / 976814393043 — all match; both lanes `git status --porcelain` empty.
- `tools/preamble_cap.sh` — CAP OK (1 snapshot entry).

## Public claim audit

The public surface is unchanged and correctly bounded. `public_covered_count` stays **5**; the
`ordinary_auto_genomic` route is NOT activated/merged/released; V2-GRM/V2-GINV stay partial. A COMPLETE D0F PASS
only **opens D1/D2**. Rose confirmed no capability row was flipped to covered. No fitting/performance/GPU claim
was made beyond the evidence.

## Tests of the tests

- The pre-draw panel is adversarial-by-construction (each lens tries to REFUTE "safe to draw"); it earned its
  keep by returning NO-GO twice on real defects before any seed was spent.
- validate-final IS the test-of-the-receipt: it re-derives the receipt from the locked corpus and requires
  byte-identity; the 5 reviews each independently re-run the full adjudication before signing.
- The env fix was verified by the exact failing path (`hs_julia_setup`) plus a negative control (fails without
  the fix), not by a proxy.

## Coordination notes

- Executed on branch `codex/2026-07-13-v07-performance-localization` (the twin-coordination channel), pushed.
- R lane (hsquared) was consumed read-only by the campaign; both twins at their sealed commits.
- The env fix touched only the NON-sealed global JuliaCall bridge env and the gitignored `julia_root` Manifest —
  no shared-contract or tracked change; nothing for the R twin to mirror.

## What did not go smoothly

- The 8-retry Totoro blocker was mis-framed for weeks as TMPDIR/mkpidlock; real cause was a global-vs-project
  OrderedCollections **version** split. The prior session had also contaminated the tracked `Project.toml`.
- A sustained/intermittent `claude-opus-4-8` Bash-safety-classifier outage blocked issuing commands for long
  stretches; mitigated by running the pipeline detached on Totoro so compute progressed regardless of my access.
- One transient interruption of hopper's post-run review (run_final.sh went down mid-run); recovered by a clean
  re-run (RC=0). Deterministic step → no effect on the receipt.
- Two harness frictions worth noting: `pgrep -f run_final`/`…write-postrun-review` self-matched my own ssh
  command lines (use `ps -C R` to isolate real workers); and each review/adjudicate step is ~30 min
  single-threaded (the final phase ran ~3.5 h). Reviews are independent and could be parallelized in future
  (projection check does not read postrun_receipts contents), but I kept the validated sequential path.

## Known limitations

- The receipt PASS is a D0F result only; it does not establish bias/coverage/recovery and does not license any
  public capability. D1/D2 are merely opened, not run.
- The runtime environment (Julia package versions) is archived at `hsq_work/envfix/env-snapshot/` but is not part
  of the sealed record (the contract pins interpreter versions + RNG + threads, not package versions).
- Old orphan R processes remain on Totoro from earlier stages; an age-filter kill was (correctly) blocked on the
  shared server — they need exact-PID confirmation before cleanup.

## Next actions

- (Optional) User confirms the orphan Totoro R PIDs are theirs so I can clear them.
- D1/D2 are now open per the pre-registration; a future session can pre-register and run D1.
- No further action required for D0F: receipt is banked, byte-reproducible, and Rose-confirmed.

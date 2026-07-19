# Claude handover — v0.7 D0F re-seal DONE (committed); D1 is next

**2026-07-19. SOLO platform = Claude. Branch `codex/2026-07-13-v07-performance-localization` (the `codex/`
name is leftover; Claude owns this arc). This handover resumes at the D1 lane with a clean, committed D0F
re-seal behind it.**

## Where we are (all verified this session)

- **D0F RE-SEAL DONE + committed `f4c899ad`** (HSquared.jl, local; **push HELD** — Grace reproducibility
  flag, awaits explicit user OK; the R-lane fix `5325e95` in `hsquared` is likewise unpushed).
- **New D0F receipt** (Totoro `~/hsq_work/reseal-d0f/stage_adjudication_receipt.tsv`):
  sha `0f5fbb5437b30a09cd80e62e0ebd017e4b0b54121d259a1f8fd07dc06c87cd56`, **verdict PASS,
  stage_decision COMPLETE**, byte-reproduced within-run by `validate-final` (RC=0). Supersedes retry8
  `04cc0740…`. Identity fields: `r_driver`/`r_recomputer_commit` `5325e95`, `r_recomputer_sha` `eb29c8f4`,
  `preseal` `b209ec0c`, `adjudication_key` `88d4cf2f`; driver bytes `d1a7d930` + Julia replay `976814`
  unchanged.
- **Identical fits, new receipt identity** (NOT byte-identical to 04cc0740): attempt_max_diff `3.18e-12`
  bit-identical to retry8; tally 556 interior / 10 lower / 10 upper identical; 5 post-run reviews CLEAN.
- **summary_max_diff `7.11e-15 → 2.27e-13` is BENIGN** — a 1-ULP reshuffle on re-measured runtime/RSS
  medians (both exact powers of two, ratio 32); Gauss: `recompute.R:278` identity-only, no scientific
  quantity moved. Full: `scratchpad/gauss-summary-max-diff-finding.md`.
- **12-doc supersede applied + Rose CONFIRMED-WITH-CAVEATS.** Verified apply-list:
  `scratchpad/d0f-reseal-supersede-applylist.md`. Live citations moved (`04cc0740→0f5fbb54`,
  `a23b15b→5325e95`, `summary 7.11e-15→2.27e-13`); frozen/history/archive untouched; retry8 snapshot
  archived verbatim. After-task: `docs/dev-log/after-task/2026-07-19-v07-d0f-reseal-recompute278.md`.
- **Totoro deployment READY:** `~/hsq_work/retry8-prep/hsquared` @ `5325e95` (clean),
  `~/hsq_work/retry8-prep/HSquared.jl` @ `976814` (clean), `reseal-d0f/` receipt present.
- **`public_covered_count` = 5.** Both lanes git-clean **except** pre-existing prior-session leftovers that
  are NOT mine — `M docs/dev-log/{after-task,check-log.d}/2026-07-15-…retry5-post-preseal-tree-blocker.md`
  and `?? docs/dev-log/2026-07-18-two-lever-news-…md`, `?? sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`
  (D2+). **Leave all four; do not commit or touch them** (D-60).

## D1 plan — bind the NEW D0F root; draw is LAST, panel-gated

Pre-registration (already repointed to `0f5fbb54`): `docs/dev-log/2026-07-18-d1-campaign-preregistration.md`.
Bind **`D0F_ADJUDICATION_ROOT = ~/hsq_work/reseal-d0f`**. Orchestrator (Totoro-side, NOT in either repo):
`~/hsq_work/retry8-prep/hsquared/tools/run-v07-genomic-recovery-v3.sh`.

**Exact D1 command signatures (from orchestrator `usage`):**
```
prepare   OUT d1 R_ROOT JULIA_ROOT RECEIPT_ROOT MAX_WORKERS D0F_ADJUDICATION_ROOT
preseal   OUT d1 R_ROOT JULIA_ROOT R_AUTO_ROUTE_COMMIT JULIA_CANDIDATE_COMMIT D0F_ADJUDICATION_ROOT
preflight OUT d1 R_ROOT JULIA_ROOT
# then: smoke-n-ladder → recommend-workers → run-official WORKERS → lock-corpus → recompute-base-r WORKERS
#       → summarize-r → replay-julia WORKERS → verify-replay → summarize-julia → write-route-lineage
#       → 5× write-postrun-review (fisher noether hopper grace rose CLEAN <UTC>) → adjudicate → validate-final
```
`R_ROOT=~/hsq_work/retry8-prep/hsquared`, `JULIA_ROOT=~/hsq_work/retry8-prep/HSquared.jl`, `OUT=~/hsq_work/d1`.

**RESOLVED ARGS (driver-verified against `v07_genomic_recovery_v3.R:305-313`; supersedes the stale
coordination-board `RECEIPT_ROOT=retry8-prep/d0f`, which is WRONG):**
- `prepare` **RECEIPT_ROOT** = **a fresh dir of 5 pre-run review receipts** (`fisher/noether/hopper/grace/
  rose.tsv` + `.sha256`), created via the orchestrator `write-review` mode — mirror
  `~/hsq_work/reseal_prerun_reviews.sh` (the D0F re-seal's, which built `~/hsq_work/reseal-reviews`), updating
  only the deployed commit/sha values for the current `5325e95`/`976814` heads. The driver copies these into
  `OUT/receipts/`. **It is NOT the D0F corpus.** `MAX_WORKERS` = 96 (D0F used 96).
- `prepare`/`preseal` **D0F_ADJUDICATION_ROOT** = `~/hsq_work/reseal-d0f` (the re-seal predecessor, sha
  `0f5fbb54`). **Never `retry8-prep/d0f`** (old `04cc0740`, `a23b15b`/`cef0b993` — re-triggers the blocker).
- `preseal` **R_AUTO_ROUTE_COMMIT** = `01ad843c8a2968b9180188f70bf9955cf433908c` (fixed provenance commit;
  the D0F re-seal used it even at head `5325e95`), **JULIA_CANDIDATE_COMMIT** = `976814393043d3a4af5ce343d8ac4b05c43eac41`.
- **STILL TO READ (classifier permitting):** the exact `write-review` 13-arg values from
  `~/hsq_work/reseal_prerun_reviews.sh` (doc49 sha + the driver/recomputer/replay commits+shas at the current
  heads). Then build `d1-reviews/` and run `prepare … RECEIPT_ROOT=~/hsq_work/d1-reviews … reseal-d0f`.
- **`OUT` = `~/hsq_work/d1`** (distinct+non-nested from `reseal-d0f`).
- **NOTE (pre-reg §8):** `smoke-n-ladder` DRAWS official seeds — it is the FIRST irreversible command, POST-GO,
  immediately before `run-official`. It is NOT a pre-draw probe. The zero-seed pre-draw gate is `preflight`.

**Green-gate PRE-1…PRE-6 (pre-reg §3; ALL zero-seed, all fail-closed):** PRE-1 dry `v3r_validate_final`
on `reseal-d0f` (identical fits, sha `0f5fbb54`); PRE-2 driver `preflight` (the real pre-draw gate,
stage_replay.jl:547-552); PRE-3 seed-lock `v07s_selftest` (DONE PASS); PRE-4 deployment head `5325e95`/
`976814`; PRE-5 D1 mutation/route suite; **PRE-6 env freeze `ok=TRUE` + clean precompile (RE-VERIFY in the
exact worker path)**. Smoke (§8) is a scale/RAM probe, not a PRE-item.

**D1 seeds (enforced):** `2_028_000_000 + 10_000·cell_index + offset`, `offset ∈ 101:148`, 12 interior
cells = **576 fits, NO bootstrap**. Window `2_028_020_101…2_028_350_148`, verified disjoint from every
retired/downstream space.

**THE DRAW is irreversible and LAST** — behind a shown-GREEN adversarial pre-draw panel **AND** the user's
durable conditional-GO ("**Auto-proceed IF panel is GREEN**"; halt-and-surface on ANY flag). A pre-draw
blocker does NOT spend seeds. Acceptance is **outcome-neutral**: `stage_decision` = per-cell tally
(`ELIGIBLE=n;…`), attempt & summary max-diff ≤1e-10, each `julia_profile_replay` under its own route,
5 reviews CLEAN, byte-reproduce. **`public_covered_count` STAYS 5** (D1 authorizes no route/count move).

## Discipline
Every long stage **detached** on Totoro (`nohup … > log 2>&1 &` + DONE marker + poll; survives opus-4-8
classifier outages). ControlMaster socket: `ls ~/.ssh/cm-*totoro*`. Isolate real workers with `ps -C R`
(`pgrep -f` self-matches). Leftover `fit_one_sensitivity.R` / `run-o3-cumlogit-coverage.R` jobs are
UNRELATED — do not touch. Julia-lane edits only in HSquared.jl.

## Resume command
Read this handover + the pre-reg + `scratchpad/{d0f-reseal-supersede-applylist,gauss-summary-max-diff-finding}.md`.
Re-verify env `ok=TRUE`. Assemble the exact D1 `prepare`/`preseal` args from `~/hsq_work/reseal_d0f_block1.sh`.
Run D1 `prepare` **detached** (zero-seed; this is the exact step the re-seal unblocked — its PASS proves the
fix) → `preseal` → `preflight` → PRE-1…6 → smoke → adversarial pre-draw panel → **if GREEN, the draw** →
full pipeline → adjudicate → validate-final → spawned-Rose close-out.

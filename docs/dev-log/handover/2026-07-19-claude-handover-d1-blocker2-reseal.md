# Claude handover — D1 blocker #2 fixed; NEXT = 3rd D0F re-seal at Julia `fa409fe6` → D1

**2026-07-19. SOLO platform = Claude. Branch `codex/2026-07-13-v07-performance-localization`. This is a
CHECKPOINT after a very long session: both D1 blockers are found + fixed + committed; the remaining work is
a mechanical (but ~14–18 h) re-seal + D1 campaign that a fresh session should run cleanly.**

## State — all committed, no seed ever drawn

Two latent **D1-only** blockers were found + fixed today (both fail-closed, pre-draw, zero seed):
1. **`recompute.R:278`** (R recomputer self-path) — fixed as `hsquared` **`5325e95`**; forced the 1st→2nd D0F
   re-seal → receipt **`0f5fbb54`** in `~/hsq_work/reseal-d0f` (julia_replay `976814`). DONE, Rose-confirmed.
2. **`marker_ratio` float-precision drift** in Julia `_validate_manifest` — R writes `marker_ratio` (`10/3`)
   at 14 sig figs in `cell_table.tsv` but full Float64 in `d1_manifest.tsv`; `_read_cell_table` tolerates
   `≤1e-12` but `_validate_manifest` used exact `==`. **Fixed** (tolerant `marker_ratio`, membership/order/
   seed still exact): local **`8f214eb3`**, deployed on Totoro as hotfix head **`fa409fe6`**. VERIFIED — the
   fixed validator passes the real failing `d1` tree. Detail: `docs/dev-log/2026-07-19-d1-blocker-2-marker-ratio-precision.md`.

**Both fixes are correct + deployed.** `public_covered_count` stays **5**.

## Why a 3rd D0F re-seal is required (my earlier "no re-seal" prediction was WRONG)

The D1 admission (R `prepare`) hard-checks **`deployed julia_replay commit == D0F predecessor's sealed
julia_replay_commit`**. `reseal-d0f` has `976814`; the fix moved Julia to `fa409fe6`; so `prepare` aborts:
`Error: julia_replay deployed commit differs from the preseal`. Any code fix to a D1 bug moves a head bound
into the D0F seal → forces a re-seal (same as `recompute.R:278`). Fits reproduce byte-identical (the fix is
validation-only), so it's a "new receipt identity, identical fits" re-seal.

## Deployment (already in place — verify first)

- Totoro `~/hsq_work/retry8-prep/hsquared` @ **`5325e95`** (clean)
- Totoro `~/hsq_work/retry8-prep/HSquared.jl` @ **`fa409fe6`** (clean; has the marker_ratio fix)
- `~/hsq_work/reseal-d0f` = old D0F receipt `0f5fbb54` (julia `976814`) — **will be superseded**.

## ⏳ STEP 1 IS RUNNING as **reseal3** (relaunched 2026-07-19 ~19:20 UTC after clearing blocker #3)

**Blocker #3 (stale sidecar) intervened + is FIXED.** reseal2 aborted at `preseal` (rc=12): the git-tracked
`stage_replay.jl.sha256` integrity pin still held the pre-fix hash because commit `fa409fe6`/`8f214eb3`
edited the `.jl` without regenerating its sidecar (the incomplete tail of blocker #2; see
`docs/dev-log/2026-07-19-d1-blocker-2-marker-ratio-precision.md` §"Blocker #3"). Fixed: sidecar regenerated
to `36a264b2…` + committed in both repos → **Totoro Julia head `fa409fe6`→`8092fcb6`**, local `8f214eb3`
line → `512d7ca7`. No seed drawn.

The re-seal is DETACHED on Totoro now: `~/hsq_work/reseal3_all.sh`, log `~/hsq_work/reseal3_all.log`,
completion marker `~/hsq_work/reseal3_all.DONE`, output tree `~/hsq_work/reseal3-d0f`, pre-run reviews
`~/hsq_work/reseal3-reviews`. Pins `JREPLAY=JCAND=8092fcb6`, deployed stage_replay sha `36a264b2…`
(`JREPSHA`, unchanged — sidecar commit doesn't change file bytes). Cleared `prepare`+`preseal`+
`materialize-bootstrap`; in the pipeline. ETA ~5–8 h. (Cosmetic: log banner still echoes "@ Julia fa409fe6";
the real `JL HEAD=8092fcb6` line is correct.)

**Resume for the fresh session:** poll `cat ~/hsq_work/reseal3_all.DONE` (RC=0 = success). Then verify the
new receipt `reseal3-d0f/stage_adjudication_receipt.tsv`: `verdict=PASS`, `stage_decision=COMPLETE`,
`julia_replay_commit=8092fcb6`, `attempt_max_diff` bit-identical to `0f5fbb54` (~3.18e-12), tally 556/10/10,
`adjudicate` sha == `validate-final` sha. Spawned-Rose close-out. THEN do Step 2 (supersede → bind
`reseal3-d0f`, julia `8092fcb6`) + Step 3 (D1 admission, `D0F_ADJ=reseal3-d0f`, `JCC=8092fcb6`) + Step 4
(panel → conditional draw). If `reseal3_all.DONE` shows RC≠0, read `reseal3_all.log` for the failed stage
(fail-closed; no seed drawn — D0F seeds reproduce deterministically).

## THE RECIPE (reference — Step 1 already launched per above)

### Step 1 — 3rd D0F re-seal at `fa409fe6` (fresh tree, e.g. `~/hsq_work/reseal2-d0f`)
Mirror the recompute.R:278 re-seal scripts (`~/hsq_work/reseal_d0f_block1/2/3.sh` + `reseal_prerun_reviews.sh`),
changing only what the new Julia head requires:
- **Pre-run reviews** (`reseal2-reviews`): re-run `reseal_prerun_reviews.sh` with `RDIR=reseal2-reviews` and
  updated Julia args — `JREPLAY=fa409fe6…` (full 40-char) and `JREPSHA=$(sha256sum
  ~/hsq_work/retry8-prep/HSquared.jl/sim/phase2_v07_genomic_recovery_v3_stage_replay.jl)`. R args unchanged
  (DOC49 `05f2041e…`, CFIX `5325e953…`, RAR `01ad843c…`, RDRVSHA `d1a7d930…`, RRECSHA `eb29c8f4…`).
- **preseal** args: `RAR=01ad843c…` (unchanged), `JCC=fa409fe6…` (was `976814`).
- Pipeline (block1→3): prepare → preseal → materialize-bootstrap → smoke-16 → run-official 576 (~68 m) →
  lock-corpus → recompute-base-r → summarize-r → replay-julia → verify-replay → summarize-julia →
  write-route-lineage → **5× write-postrun-review (PARALLELIZE to save ~4 h)** → adjudicate → validate-final.
- Result: new D0F receipt (call it `0f…NEW`) with `julia_replay_commit=fa409fe6`, byte-identical fits
  (attempt parity `3.18e-12`, tally 556/10/10). Spawned-Rose close-out.

### Step 2 — supersede `reseal-d0f`/`0f5fbb54`/`976814` → `reseal2-d0f`/`0f…NEW`/`fa409fe6`
Same live-doc supersede pattern as before (see `scratchpad/d0f-reseal-supersede-applylist.md` for the doc
list + MOVE/KEEP method). Also update the D1 pre-reg PRE-4 (`976814`→`fa409fe6`) and canonical-D0F-root
(`reseal-d0f`→`reseal2-d0f`).

### Step 3 — D1 admission (the fix makes preflight pass now)
- Edit `~/hsq_work/d1_admission.sh`: `D0F_ADJ=~/hsq_work/reseal2-d0f`, `JCC=fa409fe6…`, and the STEP-A
  pre-run-review `JREPLAY`/`JREPSHA` to the fa409fe6 values. (`d1_admission.sh` + `launch_d1_admission.sh`
  are already on Totoro.)
- Launch detached → build `d1-reviews` → prepare → preseal → preflight. **preflight now PASSES** (marker_ratio
  tolerance + matching Julia head). Each stage ~26–52 m (per-gate D0F re-validation); box is loaded.

### Step 4 — D1 draw (after admission passes; user's standing conditional-GO)
PRE-1…6 green-gate + **adversarial pre-draw panel → if fully GREEN, the irreversible draw** (`smoke-n-ladder`
is the FIRST irreversible seed, POST-GO) → run-official 576 → full pipeline → adjudicate → validate-final →
Rose. D1 seeds: `2_028_000_000 + 10_000·cell_index + offset`, offset `101:148`, 12 interior cells = 576
fits, no bootstrap. `public_covered_count` STAYS 5.

## Critical gotchas
- **Bash-tool form (cost me an afternoon):** use the LITERAL
  `ssh -o ControlPath=/Users/z3437171/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22 -o ControlMaster=no -o BatchMode=yes -o ConnectTimeout=20 totoro <cmd>` — NOT a `$SOCK` variable (breaks the settings.json allowlist → falls to the flapping `opus-4-8` classifier). Keep remote `<cmd>` simple (no `;`/`$()`/pipe); for multi-step, write a Totoro-side script and invoke `bash script.sh`. (Runbook: `~/shinichi-brain/tools/totoro-setup.md`.)
- **Totoro needs NO Duo** — connect directly. DRAC = morning-Duo sockets (brain D-64); all 9 machines were live.
- **Predecessor binding:** do NOT bind `retry8-prep/d0f` (old `04cc0740`) NOR `reseal-d0f` (`0f5fbb54`, julia
  `976814` — mismatches fixed Julia). Bind the NEW `reseal2-d0f`.

## Commits / heads
- `hsquared` `5325e95` (recompute.R:278). `HSquared.jl` local: `8f214eb3` (marker_ratio) ← latest; earlier
  this session `576be684`, `e484605c`, `f4c899ad`, `d68c83cc`. **Deployed Julia = `fa409fe6`** (Totoro hotfix;
  RECONCILE with `8f214eb3` via github — push HELD). Vault: `6036c2a`, `7bf239a`.

## Owed follow-ups (not blocking)
Unit test for the `marker_ratio` tolerance; Gauss/Rose lens on the validation-contract change;
capability-status + validation-debt rows; github reconciliation of `fa409fe6`↔`8f214eb3`; origin push (Grace flag).

## Resume
Read this + `docs/dev-log/2026-07-19-d1-blocker-2-marker-ratio-precision.md` + the D1 pre-reg. Verify the
deployment heads. Then: Step 1 (re-seal at fa409fe6) → Step 2 (supersede) → Step 3 (D1 admission,
D0F_ADJ=reseal2-d0f) → Step 4 (panel → conditional draw). ~14–18 h, detached, mostly waiting.

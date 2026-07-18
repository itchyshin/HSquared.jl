# Handover: D0F RE-SEAL in flight (at C_fix) → then D1 — 2026-07-18 (Claude)

**You are the next Claude.** A latent R-lane bug blocked D1; fixing it forced a full D0F re-seal, which is
**running detached on Totoro right now**. Your job: drive the re-seal to a new adjudicated D0F receipt, apply
the supersede-ledger, then run D1. **No seed for D1 has been drawn; `public_covered_count` = 5 throughout;
the D1 draw still needs a fresh GREEN panel + explicit user GO.**

## The one-paragraph situation

`prepare d1` failed on a **latent bug**: `hsquared/tools/v07_genomic_recovery_v3_recompute.R:278` set
`r_recomputer_path = script`, which under D1's inline predecessor re-validation mis-resolved to the *driver*
(via `commandArgs("--file=")`), so the recomputer got checked against the driver's hash → false
`frozen SHA-256 mismatch`. Fixed by deriving the path by name from `r_root` (matches the driver's own sealer
at `v07_genomic_recovery_v3.R:340`). The pipeline's git-identity gates (`preseal.R:967` git-clean +
`972-976` HEAD==sealed-commit) make any R-lane edit require **re-sealing D0F** (the old receipt `04cc0740`
binds `a23b15b`). The fix = hsquared commit **`C_fix = 5325e9532f93117a47b26acf7b126f02a74d0d5a`**
(reviewed CLEAN by Rose + NO-NUMERIC-CHANGE by Gauss), deployed clean to Totoro `retry8-prep/hsquared` via a
**local git bundle (NOT pushed to origin — pending user auth)**. The D0F re-seal reproduces the scientific
core exactly (driver bytes unchanged `d1a7d930`) and mints a NEW D0F receipt superseding `04cc0740`.

## CRITICAL — the Totoro JuliaCall env must be WARM before any fit

The fits go through JuliaCall. Concurrent workers **cold-precompiling** RCall (global env) or HSquared
(julia_root) race on `mkpidlock` and fail — this is the recurring nemesis. **Fix = warm BOTH caches SERIALLY
first**, then workers load-only:
- global env: `julia --project=~/.julia/environments/v1.10 -e 'using Pkg; Pkg.precompile()'` then verify
  `using RCall` (was `RCall_OK 0.14.13`). Script: `~/hsq_work/envfix2.sh`.
- julia_root: `julia --project=~/hsq_work/retry8-prep/HSquared.jl -e 'using Pkg; Pkg.precompile()'` then
  verify `using HSquared` (was `HSquared_OK`). Script: `~/hsq_work/envfix3.sh`.
OrderedCollections is **2.0.1** in both (correct — do NOT chase TMPDIR). If precompile races recur after any
depot change, re-run envfix2 + envfix3 before relaunching a fan-out.

## State on disk (Totoro `~/hsq_work/`)

- **Deployment (sanctioned, C_fix):** `retry8-prep/hsquared` @ `5325e95` (git-clean; recompute.R `eb29c8f4`,
  driver `d1a7d930`), `retry8-prep/HSquared.jl` @ `976814` (unchanged). Use these as R_ROOT/JULIA_ROOT.
- **Pre-run reviews (DONE, 5/5 CLEAN):** `~/hsq_work/reseal-reviews/{fisher,noether,hopper,grace,rose}.tsv`
  bound to C_fix (r_driver/r_recomputer_commit=5325e95, r_recomputer_sha256=eb29c8f4, doc49=05f2041e...).
- **D0F re-seal tree:** `~/hsq_work/reseal-d0f/` — prepare/preseal/materialize-bootstrap DONE; smoke-16
  passed; manifest = 576 rows. **Block 2 running** (`reseal_d0f_block2.sh`, marker `reseal_d0f_block2.DONE`,
  log `reseal_d0f_block2.log`): run-official 576 → lock-corpus → recompute-base-r → summarize-r →
  replay-julia → verify-replay → summarize-julia.

## Your steps

1. **Poll Block 2** to `reseal_d0f_block2.DONE == RC=0` (check `reseal_d0f_block2.log`; each review/adjudicate
   stage is single-threaded ~30 min; run-official ~10-15 min at 16 workers). If it fails on a precompile race,
   re-warm (envfix2/3) and relaunch (run-official skips already-present seeds).
2. **Block 3 — post-run reviews (genuine 5-lens, per user directive):** spawn fisher/noether/hopper/grace/rose
   to review the re-run corpus + summaries + triple-parity, each CLEAN/BLOCKED; then write each with
   `run-...sh write-postrun-review reseal-d0f d0f R_ROOT JULIA_ROOT <reviewer> CLEAN <UTC>`.
3. **Adjudicate + validate-final:** `run-...sh adjudicate reseal-d0f d0f R_ROOT JULIA_ROOT` then
   `validate-final`. Confirm the new receipt `reseal-d0f/stage_adjudication_receipt.tsv` = `verdict=PASS,
   stage_decision=COMPLETE`, re-derived byte-identical by validate-final. **Record its ACTUAL sha** (do NOT
   assume; Rose caution). Spawned-Rose close-out.
4. **Supersede ledger (Rose's cautions):** update ONLY the 12 live-state HSquared.jl docs that cite `04cc0740`
   (ROADMAP, AGENTS snapshot, capability-status, validation-debt-register, coordination-board,
   2026-07-18-d1-campaign-preregistration, this/the blocker note, the d1-predraw-readiness-audit,
   check-log.md, the D0F retry8 after-task + its check-log.d sibling, the earlier 2026-07-18 handover). Do
   **NOT** touch frozen history (retry7/retry8 pre-regs, phase-snapshot-archive, superseded handovers) or the
   `adjudication-2` schema name. Wording: "identical fits, new receipt identity" — never "04cc0740 re-derived
   byte-identical". Also fix the cosmetic `</new_string></invoke>` artifact at the EOF of the blocker note
   `docs/dev-log/2026-07-18-d1-blocker-recompute-278-reseal-required.md`.
5. **Then D1** (the D1 pre-registration `docs/dev-log/2026-07-18-d1-campaign-preregistration.md` is committed,
   HELD-at-S4). D1 invocation (now unblocked by C_fix):
   `prepare reseal-d1 d1 R_ROOT JULIA_ROOT <D0-official-root=v07-...-d0-official-cdb33dc-4c5e54de> 96
   <NEW-d0f-receipt-root=reseal-d0f>` → `preseal reseal-d1 d1 R_ROOT JULIA_ROOT 01ad843... 976814... reseal-d0f`
   → `preflight` → **fresh GREEN adversarial pre-draw panel + explicit user GO** → smoke-n-ladder (FIRST DRAW)
   → run-official → … → adjudicate → validate-final. D1 seed space = pre-reserved `2028000000/101:148` (12
   interior cells × 48 = 576). smoke DRAWS seeds → it sits AFTER the GO.

## Key contracts (verified this session)

- **RECEIPT_ROOT for D0F prepare = the pre-run reviews dir** (`reseal-reviews`), NOT the D0 root (the D0 root
  is hardcoded in the driver at `v07_genomic_recovery_v3.R:313`). For D1 prepare, the 5th arg RECEIPT_ROOT =
  the D0-official root, and D1 adds a 7th arg `D0F_ADJUDICATION_ROOT` = the new reseal-d0f receipt root.
- **write-review** (13 args): `R_ROOT PATH REVIEWER CLEAN DOC49_SHA R_DRIVER_COMMIT R_RECOMPUTER_COMMIT
  JULIA_REPLAY_COMMIT R_AUTO_ROUTE_COMMIT JULIA_CANDIDATE_COMMIT R_DRIVER_SHA R_RECOMPUTER_SHA JULIA_REPLAY_SHA`.
- Values: doc49=`05f2041e12500e01fcd1874b125cdbd80ce534016078283b2de1c53e927cc50e`; C_fix=`5325e953...`;
  julia=`976814393043...`; r_auto_route=`01ad843c8a...`; r_driver_sha=`d1a7d930...`;
  r_recomputer_sha=`eb29c8f408ee273761b76523a6e9049612a9cbb170b2fff25ff96b8bfd7216c7`;
  julia_replay_sha=`fb5d5dff6be807ccda1673618a360d708dd7447aab4dad2cde7d04cb42820c37`.
- **Smoke draws official seeds** (`smoke-16`/`smoke-n-ladder` share the `run-one` RNG path) — for D1, smoke is
  post-GO. For D0F re-seal it re-draws the seed-locked 2042/2043 (reproduction, authorized by the re-seal).

## Landing / git

- hsquared: `C_fix = 5325e95` committed LOCAL (branch `codex/2026-07-13-v07-performance-localization`), **NOT
  pushed** (deployed to Totoro via bundle; public push withheld pending user OK — Grace flagged this as a
  reproducibility gap to close by D1). Carried-over: 2 retry5 M docs in hsquared — DO NOT stage.
- HSquared.jl commits landed local: `06fb7c08` (D1 pre-reg+doc refresh), `8d3fa153` (pre-draw audit),
  `e89e3a6b` (deployment resolved), `4a30a4cf` (blocker note), `2101c724` (blocker review corrections), +
  this handover. Also **NOT pushed**. Carried-over retry5 M docs + untracked files — DO NOT stage.
- Session scratchpad scripts (Totoro copies exist): `d1_predraw*.sh`, `reseal_prerun_reviews.sh`,
  `reseal_d0f_block1.sh`, `reseal_d0f_smoke2.sh`, `reseal_d0f_block2.sh`, `envfix2.sh`, `envfix3.sh`.

## PROGRESS UPDATE (2026-07-18, later in session)

- **Block 2 COMPLETE (rc=0):** 576 official + 576 base-R + 576 Julia replay; verify-replay "complete quiescent
  rows=576". The re-run reproduces retry8's D0F scientific core **exactly** — a diff of `reseal-d0f/d0f_summary_r.tsv`
  vs `retry8-prep/d0f/d0f_summary_r.tsv` shows 0 non-provenance diffs; tally **556 interior / 10 lower / 10 upper**
  == `04cc0740`. Noether's independent tri-lane recomputation over all 576: scientific core bit-identical,
  derived fields max **3.18e-12** (== retry8's `attempt_max_diff`), 0/576 seed-formula mismatches.
- **Post-run 5-lens gate: 5/5 CLEAN** (fisher/noether/hopper/grace/rose — genuine reviews of the actual corpus).
- **Block 3 RUNNING** (`reseal_d0f_block3.sh`, marker `reseal_d0f_block3.DONE`, log `reseal_d0f_block3.log`):
  writes the 5 post-run receipts (all CLEAN, reviewed-at-utc) → `adjudicate` → `validate-final` → **new D0F
  receipt** at `reseal-d0f/stage_adjudication_receipt.tsv`. **~3.5h** (each review/adjudicate/validate-final
  re-runs the full adjudication ~30 min single-threaded). A background watch (`buuxtm2l1`) is armed for its DONE.
- **When Block 3 lands:** confirm the new receipt = `verdict=PASS, stage_decision=COMPLETE`, byte-reproduced by
  validate-final; **record its ACTUAL sha** (do NOT pre-write). Then spawned-Rose close-out + the 12-doc supersede.
- **Rose wording correction (use this):** do NOT say "only 5 receipt fields change" — that undercounts. Say:
  "the scientific fields + PASS verdict reproduce exactly; the provenance/identity set changes by design"
  (r_driver_commit, r_recomputer_commit, r_recomputer_sha256, preseal_sha256, r_summary_sha256,
  julia_summary_sha256, base_r_inventory_sha256, corpus_lock_sha256, adjudication_key_sha256 — all provenance).
- **D1 optimization:** the 5 post-run reviews are independent/parallel-safe — for D1, run write-postrun-review
  in parallel (and the 5 review lenses concurrently) to cut ~2h off the final phase.

## Guardrails

- `public_covered_count` STAYS 5. A COMPLETE new D0F receipt only OPENS D1/D2 (like 04cc0740). D1 alone moves
  no count/route (needs the full D0→D4 ladder + Rose activation + G10).
- Julia lane edits only HSquared.jl; the R-lane fix was authorized this session (goal = Claude runs both lanes).
- Every long stage detached + poll; smoke-first; the D1 draw is the point of no return (GO required).
- Detail: `docs/dev-log/2026-07-18-d1-blocker-recompute-278-reseal-required.md`,
  `docs/dev-log/2026-07-18-d1-predraw-readiness-audit.md`, the D1 pre-registration, and this session's
  scratchpad review docs.

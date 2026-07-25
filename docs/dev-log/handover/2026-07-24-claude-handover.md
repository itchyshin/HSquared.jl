# Handover → next Claude (HSquared.jl, Julia engine lane) — 2026-07-24 (canonical entrypoint)

**You are the next Claude**, resuming the `HSquared.jl` Julia engine lane. This is the canonical
session-entrypoint handover (the `AGENTS.md` snapshot points here; it supersedes the earlier same-day
engine-performance and eigen handovers). **Branch:** `codex/2026-07-13-v07-performance-localization` @
`114ae24c` (pushed, in sync) · **PR:** #274 (DRAFT — do not auto-merge) · **From:** Claude (this
session) · **Mode:** landed — everything committed + pushed; working tree clean except the 4
pre-existing FOREIGN files (never commit; listed below).

## Critical context (know this or it goes wrong)
- **This is the JULIA ENGINE lane.** The R lane (`hsquared`) is a SEPARATE repo — do NOT edit it from
  here. Anything R-facing is an R-lane handoff (see the coordination board's Active Lane Split).
- **TWO engine fitters now carry STAGED experimental→covered evidence for the owner's G10, and the
  owner chose to KEEP BOTH STAGED (no flip).** `public_covered_count` STAYS **5** — engine-covered ≠
  R-public-covered; the count moves only when the R bridge lands. **Do NOT flip any capability without
  a FRESH promote-specific Rose audit + explicit owner G10.**
  1. **Eigen-once (`fit_eigen_reml`, `V1-EIGEN-REML`)** — G11 discharged (48-seed×2-arm recovery gate
     PASS + `sommer` AGREE 7.77e-9); staged; owes the R `method="eigen"` bridge + G10.
  2. **Production-scale sparse (`fit_ai_reml`, the "V1-REML" production path)** — **THIS session.** The
     pre-declared recovery-at-scale gate PASSES (v2), `sommer` AGREE, 2× Rose clean; staged; **owner
     G10 = KEEP STAGED**; owes the R bridge + G10.
- **D1 genomic PAUSED (D-68). TMB deferred. F6 deferred.** Do not conflate D1 with the eigen/sparse work.

## Goals / mission (the durable why)
`HSquared.jl` is the Julia **engine** twin of the R package `hsquared`; R owns the public user
language, Julia owns the engine reality. No fitting/perf claim without the full evidence chain; repo
state (not chat) is truth. The **public covered fitting surface = 1** (the v0.1 univariate Gaussian
animal model). The load-bearing adoption lever is the one-way **R↔Julia bridge** (R audience + Julia
speed) — which is why "expose staged engine work via the R bridge" keeps surfacing as the next step.

## What was accomplished (this session — the production-scale sparse fitting arc)
Ultra-plan `keen-orbiting-horizon`, Claude end-to-end (owner-directed), Totoro + local R. Assembled +
STAGED the production-scale evidence for `fit_ai_reml` — **nothing promoted**:
- **S1** — verified the 3 "un-merged" branches were actually merged/superseded → **deleted** them
  (owner-approved). Confirmed the src map; pinned doc-18-vs-capability-status drift.
- **S2 (F0)** — the direct sparse path scales on low-fill (q=300k/2.3s) but **walls on adversarial
  high-fill** (Totoro q=20k = 1529s, fill 471, selinv-driven). F6 = the deferred high-fill-tail lever.
- **S3** — `Pkg.test()` green; F1/F3/#114/#182 all present.
- **S5 (F5)** — pre-declared gate **v1 FAILED (banked negative)** on Leg C boundary (6/8) → diagnosed
  as a Leg-C **test-design flaw**, NOT a fitter defect (near-constant y legitimately converges to a
  tiny valid σ²). NOT relaxed. A corrected, freshly re-declared **v2 gate PASSED** all four legs:
  recovery **0.19%/0.065% @ q=100,000** (48/48), deep-15-gen unbiasedness, boundary 8/8, eigen≡AI 1.18e-7.
- **S6 (F8)** — direct `sommer`≡`fit_ai_reml` **AGREE 3.6e-5**.
- **S7** — TWO real spawned Rose audits: package = **CLEAR-WITH-CHANGES** (applied); v1→v2 integrity =
  **LEGITIMATE CORRECTION** (not a relaxation). Melissa reconcile clean. Staged in capability-status
  row 108; check-log + status.json done; 3 stale branches deleted.

Detail (do not duplicate — read these): `docs/dev-log/after-task/2026-07-24-wave-f-production-sparse-evidence.md`,
`docs/dev-log/recovery-checkpoints/2026-07-24-f5-scale-recovery-gate-{predeclaration,result,v2-predeclaration,v2-result}.md`,
`…-f0-adversarial-highfill-decision.md`, `…-f8-sommer-aireml-comparator.md`,
`docs/dev-log/handover/2026-07-24-claude-wave-f-production-sparse-handover.md` (the arc-specific handover).

## Plans / roadmap (beyond the immediate steps)
The engine leads the R-public surface (~13 engine-covered rows vs public count 5). The highest-leverage
direction is **R-bridge activation** (expose staged engine work — eigen + ai_reml — to R users; that is
what moves the public count). Then: production-sparse for the multivariate/two-effect/genomic models
(after the univariate pattern lands); F6 (wire the existing PCG) for the high-fill tail; GPU (Track B).
Authoritative: `ROADMAP.md`, `docs/design/18-programme-plan-2026-06.md`, `docs/design/capability-status.md`.

## Current working state
- **Working / landed:** all this-session commits pushed (`533cf0f8`..`114ae24c`); branch in sync; `Pkg.test()` green.
- **In progress:** none.
- **Blocked:** nothing — the owner made the pending calls (keep staged; branches deleted; hygiene done).
- **Foreign never-commit files (NOT this lane's; leave untouched):**
  `docs/dev-log/after-task/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`,
  `docs/dev-log/check-log.d/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`,
  `docs/dev-log/2026-07-18-two-lever-news-fit-laplace-reml-is-the-cox-reid-lever.md`,
  `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`.

## Key decisions & rationale
- **STAGE, not flip** — owner G10 for `fit_ai_reml` = KEEP STAGED (hold until the R bridge, so the flip
  + public-count move land together; the eigen-thread pattern). Count stays 5.
- **F5 v1 banked, v2 corrected** — v1's failure is preserved; v2 fixed only the demonstrably-wrong Leg-C
  criterion on fresh seeds with recovery criteria unchanged (Rose verdict: LEGITIMATE, not a relaxation).
- **F6 deferred** to the high-fill n>20k tail (the direct path suffices for the common low-fill case).

## Landing State (git ledger)
| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `HSquared.jl` `codex/2026-07-13-v07-performance-localization` `114ae24c` | y | y | #274 (draft) | **LANDED** |
| 4 foreign dirty files (above) | n | n | — | **NOT OURS — leave** |

## Next immediate steps (ordered; none blocking)
1. **R lane (R twin — separate repo; do NOT edit `hsquared` from here):** implement the opt-in R routes
   for BOTH staged engine fitters — `method="eigen"` (eigen bridge contract) AND the production-scale
   `fit_ai_reml` path — mark EXPERIMENTAL, confirm the count stays 5. Ledger: Julia #5/#6 ↔ R #2/#5.
2. **Owner (G10):** flip-or-hold for eigen AND ai_reml (both staged; owner already chose HOLD for
   ai_reml). A flip needs a FRESH promote-specific Rose + the R bridge.
3. **F6 follow-on (deferred):** wire the v0.8-S2 matrix-free PCG into the AI-REML fit loop for the
   high-fill n>20k tail, if/when a real high-fill large pedigree needs it.
4. **Deferred menu (carried forward, not dropped):** the eigen Szymek close-out (owner sends); the
   `check-log`/`status.json` are now DONE; the corrected-boundary-gate is DONE (v2 passed — no longer owed).

## Blockers / open questions
None blocking. All owner decisions for this arc are made.

## Gotchas & failed approaches
- **Freeze BEFORE running** — gate integrity anchors: F5 v1 `77ecad3a`, v2 `4fb6fb66` (both frozen
  before the Totoro run; the result docs carry the erratum for v1's stale header).
- **Leg-A criterion:** a bias/MCSE test is pathological at q=1e5 (MCSE→0 makes it fail on negligible
  bias) — use a relative-recovery criterion at scale, keep bias/MCSE for moderate n (Leg B).
- **Never write a result number before the run produces it.** This session I briefly wrote predicted
  PASS numbers into a doc before the Totoro run finished — caught and blanked it. Numbers come ONLY
  from the committed run logs (`sim/drac/results/f5_gate_v{1,2}.log`, `f0_adv_q{10,20}k.tsv`).
- **High-fill exact-cov Leg B is expensive** (dense inv+chol at n=4500 × 48 ≈ 15 min on Totoro).
- **Totoro clone tracks only `main`** — `git fetch origin <branch>` explicitly, checkout the commit;
  julia is `~/.juliaup/bin/julia` (1.12.6); socket `SOCK=$(ls ~/.ssh/cm-*totoro* | head -1)` (no Duo).
- **The engine is NOT broken** — the earlier "REML broken/slow" engine-perf handover was a stale
  checkout + no-signal data; on current code `fit_ai_reml` converges in 5–7 iterations
  (`docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md`). Do not re-open it.

## How to resume (TARGET = claude)
1. Run the **`hsquared-rehydrate`** skill (live git/CI + ROADMAP + coordination board + check-log +
   newest after-task + capability-status + validation-debt).
2. Read the `AGENTS.md` Live Phase Snapshot, THIS doc, then the detail set linked above.
3. **Before ANY public/capability claim or a promotion flip, spawn a REAL Rose subagent** (mandatory
   G8; a lens is not enough).
4. **Division of labour:** Claude plans/refactors/writes prose + runs pure-logic/CI checks; hand the
   LIVE toolchain (real fits, `R CMD check`, sims, Totoro campaigns) to the in-session compute you
   drive or to a Codex session. Skills live in `.claude/skills/`.

### One-command resume (paste in an authenticated terminal, from the repo root)
- Interactive: `claude "Rehydrate with hsquared-rehydrate + docs/dev-log/handover/2026-07-24-claude-handover.md + the AGENTS.md snapshot. Two engine fitters (eigen fit_eigen_reml + production-sparse fit_ai_reml) carry STAGED experimental→covered evidence for G10; owner chose KEEP STAGED; public_covered_count=5. Continue with the Next Immediate Steps: the R bridge (R lane, separate repo) + owner G10. Fences: no capability flip without a FRESH Rose + G10; D1 PAUSED (D-68); TMB deferred; do NOT touch the 4 foreign dirty files."`
- Autonomous, clean context: the same prompt via `claude -p "…" --max-budget-usd <cap>`.

## Mission-control summary
| Repo / lane | Branch / state / CI | Shipped this session | Next by leverage |
|---|---|---|---|
| HSquared.jl (Julia engine — production-sparse) | `codex/2026-07-13-…` @ `114ae24c`, PR #274 draft; `Pkg.test` green | F5 v2 gate PASS (recovery 0.19% @ q=1e5); F8 sommer AGREE 3.6e-5; 2× Rose CLEAR/LEGITIMATE; staged experimental | R bridge → owner G10 → F6 (high-fill tail) |
| HSquared.jl (Julia engine — eigen, prior thread) | same branch; staged | G11 discharged (gate + sommer 7.77e-9); staged | R `method="eigen"` bridge → owner G10 |
| hsquared (R twin) | separate repo, untouched | R-bridge contracts handed off (eigen + ai_reml) | implement opt-in routes (count stays 5) |
| D1 genomic-recovery | PAUSED (D-68), same branch | — | separate thread; do not conflate |

> Detail companions: this session's after-task + the arc handover (`…-wave-f-production-sparse-handover.md`);
> prior thread: `2026-07-24-claude-eigen-promotion-evidence-handover.md`. Ledger: Julia #5/#6 ↔ R #2/#5.

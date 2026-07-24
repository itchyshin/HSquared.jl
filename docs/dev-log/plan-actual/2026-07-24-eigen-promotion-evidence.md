# Plan-vs-actual — `fit_eigen_reml` experimental→covered EVIDENCE PACKAGE (2026-07-24)

**Plan:** `~/.claude/plans/giggly-questing-thimble.md` · **Actual:** commits `1d9ec57d`..`a9d8c01e` on
`codex/2026-07-13-v07-performance-localization` (pushed, in sync with origin) + uncommitted S8
consolidation in the working tree at reconciliation time. **Reconciler:** Melissa (Sonnet), light pass,
deterministic from the routing receipt (after-task + handover + check-log) cross-checked against git.

> **Post-reconcile RESOLUTION (2026-07-24, after this pass):** all five deviations below were addressed in
> the S8 consolidation commit that followed this reconcile. The G8 Rose audit completed **CLEAR-WITH-CHANGES**
> (the doc now exists at the cited path; its 3 wording changes are applied across all docs); the check-log /
> after-task / handover were made consistent with the real verdict; `docs/make.jl`-not-run (no Documenter-
> source changed) and G3-deferred-to-promotion were explicitly recorded; and the orchestrator-inline routing
> rationale was logged for Ada. Melissa's point-in-time findings are preserved below **unaltered**.

## One-line summary

The two G11 evidence legs (recovery gate PASS, sommer comparator AGREE) and the S4 threshold study
landed clean, well-evidenced, and fence-honest (no capability flip, count stays 5, foreign files
untouched); the material gaps are in **how** the package was assembled, not **what** it produced — three
of seven planned agent-dispatch slices ran in-session instead of spawned, and the G8 Rose-audit
close-out is internally inconsistent (two docs correctly flag it pending, one asserts it is done and
points at a file that does not exist).

## Scope

**Planned:** fold three follow-ons (Szymek close-out, G11 promotion-evidence package, `:auto` threshold
refinement) into one campaign; spine = the promotion-evidence package; STAGE not flip.
**Actual:** matches exactly — all three follow-ons delivered, framed as staged throughout every document.
**Nothing material.**

## Evidence / verification

1. **G11 recovery gate.** Planned: pre-declared 48-seed × 2-arm gate, frozen before run, smoke-first.
   Actual: `1d9ec57d` (freeze, includes embedded local-smoke output) precedes `d61f79e0` (Totoro result,
   6 min later) by commit timestamp; `GATE: PASS` both arms, 48/48 converged, `|bias|≤2·MCSE` (max
   1.01·MCSE), eigen≡AI-REML ≤2.18e-7. Two-arm WS/HF design matches the plan's recommended DGP exactly;
   seeds `20267000-047`/`20267100-147` are a sensible disjoint split of the plan's candidate range.
   **Nothing material — delivered as pre-declared.**
2. **G11 comparator.** Planned: sommer (primary) or blupf90+ on one gate seed, agree ~1e-4. Actual:
   sommer 4.4.5 AGREE to 7.77e-9 on Arm-WS seed 20267000 — tighter than plan's target and tighter than
   prior covered promotions (V3/V4 recorded ~1e-4/1e-5). High-fill agreement established transitively,
   not directly — recorded honestly as such in the comparator doc. **Nothing material.**
3. **G8 Rose audit — MATERIAL, inconsistent.** Plan DISCIPLINE line: "a real spawned Rose audit gates
   the package (G8)"; S7 is the plan's one Opus-ceiling child; `SEQUENTIAL: ... S8←S7`. Actual: the
   after-task (`docs/dev-log/after-task/2026-07-24-eigen-promotion-evidence-package.md:27,75`) and the
   handover (`docs/dev-log/handover/2026-07-24-claude-eigen-promotion-evidence-handover.md:39`) both mark
   the G8 verdict `[FINALIZE — verdict from docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md]`
   — an explicit unresolved placeholder. The check-log
   (`docs/dev-log/check-log.d/2026-07-24-eigen-promotion-evidence.md:24`) instead states, unhedged,
   "Rose G8 audit: see `docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md` — verdict recorded
   there." **That file does not exist anywhere in the repository** (`find . -iname "*rose-eigen*"` and
   `docs/dev-log/scout/` listing both empty). All three documents are uncommitted at reconciliation time,
   so nothing false has shipped yet — but the check-log's phrasing is inconsistent with its own siblings
   and would be a false evidence pointer if committed as-is. Either Rose's audit genuinely has not
   completed (S8 started before its S7 dependency resolved) or it completed and its output was never
   written/linked correctly. No reason for the inconsistency is recorded anywhere.
   **TAG: drift. OWNER: Rose.**
4. **G3 not-public-yet note — MATERIAL, silently absent.** Plan's own bar table flagged G3 `⚠` at session
   start ("API-referenced; add explicit not-public-yet note") and S8's slice line explicitly promised
   "G3 not-public-yet note" as a consolidation deliverable. Actual: `docs/src/api.md` has zero uncommitted
   diff (still a bare `@docs` listing, no caveat); the `fit_eigen_reml` docstring in `src/likelihood.jl`
   is byte-identical to before this session (`git diff 8b3809c6..HEAD -- src/` is empty) and already said
   "Experimental" pre-session; the capability-status.md row extension adds G11 language but no new
   "not-public-yet" phrasing beyond what pre-existed. The after-task's "Outcome (met)" and "Files changed"
   sections do not mention G3 at all — not delivered, and not flagged as skipped either. Substance-level
   mitigation already exists (pre-existing "NOT the public default" / "not wired into the R bridge"
   phrasing), which lowers practical risk, but the specific promised deliverable is missing without
   acknowledgment. **TAG: unclear (leans drift — promised item silently absent from its own closing
   accounting). OWNER: Rose.**
5. **VERIFY's docs/make.jl leg — MATERIAL, undocumented.** Plan's VERIFY row requires both `Pkg.test()`
   AND `docs/make.jl` green. Actual: after-task and check-log both document `Pkg.test()` PASSED (0
   failures) with specifics; neither mentions `docs/make.jl` or a Documenter build anywhere. Practical
   risk is low — no `docs/src/` file changed this session — but the specified check is unevidenced.
   **TAG: drift (minor). OWNER: Rose.**

## Model routing

Plan's slice table dispatched S1 (Gauss, Sonnet·high), S4's design half (Karpinski, Sonnet·high), and S5
(Mrode+Fisher, Sonnet·med) as spawned Agents; only S2/S3 (Curie) were explicitly planned as in-session
Bash. **Actual** (per the after-task's own "Active lenses and spawned agents" accounting): real spawns
were 3× recon (Haiku, pre-planned), 1× Szymek (Sonnet, S6, matches plan), 1× Rose (Opus, S7, matches
plan) — Gauss/Karpinski/Mrode/Fisher are explicitly listed as "review lenses (perspectives, not spawned)."
S1, S4's design half, and S5's authoring half were done in-session by the orchestrator instead of
dispatched. Of the plan's own fan-out budget ("new children this arc: S1,S4,S5,S6,S7,S8,RECONCILE = 7"),
3-4 materialized as real spawns (S6, S7, RECONCILE, +recon pre-spent).

This is not cost-free to wave through — S1 (the gate DGP/acceptance rule) and S5 (the comparator) are
exactly the correctness-critical, independent-eyes slices a Sonnet dispatch would normally buy a second
perspective on — but it is also not clean drift: the plan's own DISCIPLINE line ("judgment on Opus/Fable")
textually sanctions orchestrator-authored judgment work, the fan-out-budget note explicitly worried about
exceeding the 6/checkpoint cap across 7 children, and S1-S2-S3 are a tightly sequentially-coupled build
chain (script → smoke → freeze → Totoro run) that is awkward to split across agent context boundaries.
No document records *why* the Agent dispatch was skipped for these three slices, and the after-task does
not flag this as a deviation from its own slice table at all. **TAG: unclear. OWNER: Ada** (ratify
orchestrator-inline execution as standard practice for tightly-coupled build slices, or tighten the plan
template so a Dispatch=Agent cell is either honored or re-negotiated with a recorded reason).

## Safety gates

Smoke-first (DISCIPLINE: "1 seed, non-empty/in-range THEN scale") and freeze-before-run both honored:
local smoke (n=250, 2 seeds/arm) is embedded in the predeclaration doc that IS commit `1d9ec57d`, and the
Totoro gate run (`d61f79e0`) was executed against that frozen commit 6 minutes later per timestamps. The
Phase 0.25 sweep receipt was present in the plan itself (baked in before execution, not owed). Opus
ceiling (1, Rose) not breached per the documented spawn accounting. **Nothing material.**

## Public claims

`docs/design/capability-status.md` and `docs/design/validation-debt-register.md` diffs confirmed
line-by-line: the status column stays `experimental` / `partial` in both old and new text; every
document (after-task, handover, check-log, coordination-board, the two status-doc diffs) explicitly and
repeatedly states `public_covered_count` stays 5 and no capability row is flipped. No head-to-head ASReml
claim was checked into the Szymek draft framing (per the after-task's own claim-audit section; not
independently re-read line-by-line here as it is out of the G11/fence-critical path). **Nothing
material — fence held.**

## Handoff state

Handover doc (`docs/dev-log/handover/2026-07-24-claude-eigen-promotion-evidence-handover.md`) follows the
repo's handover template fully (Critical Context, Accomplished, Working State, Key Decisions, Landing
State table, Next Steps, Blockers, Gotchas, one-command resume, mission-control summary) and correctly
marks the S8 commit as "LANDING" (not yet landed) and the 4 foreign files as "CARRIED-OVER (foreign;
leave alone)." Its one defect is the same G8 placeholder already recorded under evidence/verification
above (not double-counted here). Git hygiene confirmed: each commit staged explicit paths (no `-A`); the
4 foreign dirty files (`2026-07-15-v07-d0f-retry5-*` ×2, `2026-07-18-two-lever-*`,
`sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`) show byte-identical `git status` markers
(`M`/`M`/`??`/`??`) before and after this session and are touched by none of the 5 session commits
(`git log --stat` confirms only eigen-scoped paths); D1/genomic and TMB paths appear nowhere in the
session diff; the R twin (`hsquared`) is a separate repository, structurally untouched from here.
**Nothing material beyond the G8 item already flagged.**

## Adaptive (for completeness — not drift)

- **S4 threshold kept at 60, not changed.** Plan phrasing implied replacement ("replace conservative
  threshold-60 ... with measured rule"); actual outcome is KEEP, with a fully quantified, cross-referenced
  rationale (measured crossover brackets 60 on both sides at n=2000 and n=4000; n-adaptive refinement
  explicitly scoped and deferred with reason) consistent across the crossover doc, after-task, handover,
  and check-log, and a routing-test comment-only update (`test/runtests.jl`, verified via `git show
  a9d8c01e -- test/runtests.jl`: comment lines only, no assertion changed). **TAG: adaptive — justified,
  recorded. OWNER: n/a** (Karpinski/Gauss lane; no action needed, evidence sufficient).

## Tally

| Tag | Count | Items |
|---|---|---|
| drift | 2 | G8 Rose-audit inconsistency (check-log vs. nonexistent file); VERIFY's undocumented `docs/make.jl` leg |
| unclear | 2 | Model-routing collapse (S1/S4-design/S5 not spawned); G3 not-public-yet note silently absent |
| adaptive | 1 | S4 threshold kept at 60 (well-justified, well-recorded) |

**Most important:** the G8 Rose-audit inconsistency — drift, owner **Rose**. The plan's one mandatory,
Opus-ceiling audit gate is the load-bearing check for the whole package's "staged for the owner's
promotion call" claim; right now one of its three closing references (check-log) asserts completion
against a file that does not exist, while the other two correctly hedge as pending. This should be
resolved (real Rose verdict obtained and all three documents made consistent) before the S8 consolidation
commit lands.

> Related: `docs/dev-log/after-task/2026-07-24-eigen-promotion-evidence-package.md` ·
> `docs/dev-log/handover/2026-07-24-claude-eigen-promotion-evidence-handover.md` ·
> `docs/dev-log/check-log.d/2026-07-24-eigen-promotion-evidence.md` ·
> `~/.claude/plans/giggly-questing-thimble.md`.

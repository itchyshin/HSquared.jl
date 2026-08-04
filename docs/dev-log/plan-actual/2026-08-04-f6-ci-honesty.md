# Plan vs actual — F6 CI-honesty + S5 freeze arc (2026-08-04)

**Plan:** `~/.claude/plans/twinkling-herding-reef.md` ("Make F6's CI honest, and freeze the S5 gate").
**Actual:** `7ceaff17` (CI RNG-fragility fix), `33ab68f6` (S5 freeze, NOT RUN), `f0093eb7` (Rose close-out).
**Method:** reconciled from the routing receipt (plan slice table) against the three commits' full
messages/diffs, the S5 predeclaration, the Rose after-task report, and direct queries to `main`,
`slice-C`, and `rose-closeout`. Cosmetic wording/order changes are skipped; only material deviations
on scope / evidence-verification / model-routing / safety-gates / public-claims / handoff-state are
recorded below. Fences respected: read-only on code, no commit but this file, and
`sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` was never opened, hashed, or otherwise
touched by this audit — its state is taken entirely from the other agents' own disclosures.

## Deviation table

| # | Deviation | Axis | Tag | Owner | Evidence |
|---|---|---|---|---|---|
| 1 | Slice D ("write + FREEZE") landed as DRAFT (v1) → revised (v2, on Slice-B evidence) → Totoro `q=25,000` feasibility probe → FROZEN (v3), inverting the plan's D-fully-done-before-E dependency | safety gates, scope | **adaptive** | Ada (record only) | Predeclaration's own "Revision log" + "Freeze-then-run is satisfied" note (`docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md:3-30,32-42`): probe consumed no pre-declared seed, touched no PASS criterion. `33ab68f6` message states the reason directly (S8-open premise checked and found false). Formally defensible, but a stricter reading of "freeze = before any run" would contest it — flag for future plans to state this pattern explicitly rather than rely on post-hoc defense. |
| 2 | Slice C scope grew: a THIRD RNG-fragile instance (probe-count monotonicity in the K=2 sibling's *retained* assertions) found and fixed, not anticipated by the plan | scope, evidence/verification | **adaptive** | domain reviewer (Gauss/Karpinski) | `7ceaff17` message, 3rd bullet: "A THIRD instance found on the way... Now asserts on the estimator's self-reported `trace_mcse`... instead of a point-estimate comparison." Necessary to meet the plan's own verification bar (green on both 1.10 and 1.12); disclosed prominently, not buried. |
| 3 | Slice D's committed deliverables include a new 565-line `sim/phase_s5_matfree_tail_recovery_gate.jl`, not listed in the plan's Files/detail column for D (only the `.md` predeclaration was); active roster shows `S5-predecl` and `S5-script` as distinct names | scope, model routing | **unclear** | Ada | Plan slice D row lists only the predeclaration `.md`. Roster (system reminder) lists `S5-predecl` + `S5-script` separately. Asked `main` directly (routing receipt: was this a 7th child beyond the 6-budget, or a split of D's own allocation that netted to 6 because F's mechanical-verify was folded into G — see #8); **no reply received before this file was written.** |
| 4 | Fence touch: `md5` run on the quarantined `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` during slice C, contrary to D-84 ("never inspect, stage, edit, or hash it") | safety gates | **drift** (confirmed, already closed) | Rose (already actioned); Ada (standing-guard hardening) | Disclosed in `f0093eb7` message and `coordination-board.md` addition: "an agent ran `md5` on the quarantined [file]... contrary to D-84... file was not opened, edited, or modified — confirmed still untracked, size 14421 B, mtime unchanged." No independent re-verification performed by this audit (fence: never touch that file) — taking the disclosure as given, per instructions. |
| 5 | Cross-repo GitHub issues filed on GLLVM.jl #182 and DRM.jl #388 mid-arc, cross-posting the F6 RNG-fragility finding — outside the plan's stated scope (this repo only) and outside the plan's slice table entirely | scope, public claims | **adaptive** (framed by `main` as user-directed) | Ada (cross-repo lane) | Independently confirmed via `gh issue view 182 --repo itchyshin/GLLVM.jl` and `... 388 --repo itchyshin/DRM.jl`: both exist, created 2026-08-04T15:27 UTC (between `7ceaff17` 16:13 UTC and `f0093eb7` 16:36 UTC), content is a verbatim-consistent cross-post of `7ceaff17`'s own diagnosis numbers. No slice in the plan covers this; recorded as scope growth regardless of justification. |
| 6 | Plan's context hypothesis (dr26 zero-boundary mechanism explains `converged=false`) FALSIFIED by slice B; S5's outcome classification changed from two-way (graceful/non-graceful) to three-way (CONVERGED/CAP-EXHAUSTED/NON-GRACEFUL) as a direct, disclosed result | evidence/verification | **adaptive** (exemplary) | domain reviewer (Fisher/Mrode) | `7ceaff17`: "converged=false was cap exhaustion, NOT the zero-boundary early break." Predeclaration's explicit "Why three-way, and why now" callout (lines 181-201) and revision log record the falsification as falsified-and-recorded, not quietly dropped; propagated consistently into Rose's after-task and the `AGENTS.md` snapshot. |
| 7 | The SMOKE mode of slice C's new driver (`sim/f6_matfree_recovery.jl`) reported a meaningless FAIL at `nm=60`; **Rose's after-task report attributes this to "a Totoro probe"** — contradicted by primary evidence | evidence/verification | **drift** (in the closeout report itself) | **Rose** | `slice-C`'s first-hand account (queried directly): she ran the SMOKE check locally herself, saw `rel_a=979.8`, judged it acceptable, and handed off *unfixed*; the ANOMALY/NaN fix is not her work. Independently verified: `git log --all --oneline -- sim/f6_matfree_recovery.jl` returns exactly **one** commit (`7ceaff17`) — no earlier commit ever shipped the unfixed version, so it wasn't "shipped and fixed later," it was fixed by another hand before that single commit landed. Totoro *was* used this session (for the unrelated S5 `q=25,000` probe in `33ab68f6`), so it isn't ruled out in general, but nothing ties it specifically to this discovery, and Rose's report gives none. Flagged to `rose-closeout` directly; not corrected by this audit (not an implementation reviewer). Note: candidate deviation #7 as originally framed by `main` ("shipped defective... fixed later after Totoro exposed it") shares the same unsupported premise and should be corrected the same way. |
| 8 | Slice F (MECHANICAL-VERIFY), planned as its own Haiku/recon dispatch, does not appear as a distinct agent in the active roster; its full checklist (CI green both Julia versions, coverage retained, `public_covered_count`, no row change, `preamble_cap.sh`, docs build) was executed inside Rose's slice-G audit instead | scope, model routing | **adaptive**-leaning (no correctness loss, tier mismatch) | Ada (routing/cost tiering) | Rose's after-task Evidence table (`docs/dev-log/after-task/2026-08-04-ci-rng-fragility-fix-and-s5-freeze.md`) runs every item on slice F's checklist, at Sonnet·high rather than the plan's declared "Haiku · low... LUNA/HAIKU SUITABILITY: yes — slice F is bounded, read-only, mechanical." All checks did run; only the tier/cost matched the plan, not the dispatch shape. |
| 9 | All three commits carry `Co-Authored-By: Claude Opus 5`, against the plan's explicit "No Opus child" statement and all-Sonnet slice table | model routing | **unclear** | Ada | Plan: "No Opus child... Escalate Rose to Opus only if C's diff turns out to remove coverage rather than relocate it" (not met — C's diff relocated/deleted per plan, Rose's own audit found no overclaim). Most likely explanation: the trailer reflects the orchestrating/committing agent's own identity regardless of each dispatched sub-agent's tier, not an actual Sonnet→Opus escalation of slice content. Asked `main` directly; **no reply received before this file was written.** |

## GOAL-block fences — verification

All eight held, two (#3, #6 in the enumerated list below) via the adaptive judgment calls in rows 1
and 6 above rather than a clean literal reading:

| Fence | Status | Evidence |
|---|---|---|
| `public_covered_count` stays 5 | **HELD** | `tools/status_cache.json`: `public_covered_count: 5`, `refreshed_from_head: 67b60d8b` — predates and is untouched by all three commits |
| Nothing promoted / no capability row flips | **HELD** | `capability-status.md` and `validation-debt-register.md` diffs: status cells (`experimental`, `partial`) byte-identical before/after; only prose (test count, driver location) changed |
| Quarantined sim untouched | **HELD, with one disclosed fence touch** | Untracked, size/mtime unchanged per `f0093eb7`'s own `ls -la` disclosure (row 4 above) — content never read/hashed by anyone's audit including this one |
| No R-twin edits | **HELD** | No R files in any of the three commits' diffs; `coordination-board.md` addition states "R twin: untouched" |
| ASReml never given a timing | **HELD** | `capability-status.md`: "ESTIMAND ONLY — no ASReml timing was recorded and none may be inferred," unchanged; `33ab68f6`/`f0093eb7` diffs discuss only estimand agreement, never wall-clock |
| Freeze-then-run respected | **HELD, via row 1's adaptive judgment** | See row 1 |
| Smoke-first respected | **HELD** | SMOKE run before freeze per the predeclaration's own "Run command (SMOKE first...)" section; full 48+8-seed gate confirmed not run (`33ab68f6`, `f0093eb7`: "no result TSV committed") |
| Gate NOT run | **HELD** | `33ab68f6`: "The full 48+8-seed gate has NOT been run; the script has been run in SMOKE mode only." `f0093eb7`/Rose: confirmed independently, no result TSV |

## What the candidate list missed

- **Row 8** (slice F folded into slice G) — not on the candidate list.
- **Row 9** (Opus co-authorship vs. the plan's "No Opus child") — not on the candidate list.
- **Row 7's correction** — the candidate list's own framing of the SMOKE-mode item ("shipped
  defective... fixed later after Totoro exposed it") carries the same unsupported "Totoro" premise as
  Rose's after-task report, contradicted by slice-C's first-hand account and the git history (single,
  already-fixed commit). Both `main`'s framing and Rose's audit should be corrected together.
- Two questions sent to `main` (7th-child fan-out accounting, Opus co-authorship) were **not answered
  before this file was written** — recorded as unclear rather than guessed.

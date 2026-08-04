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
| 3 | Slice D's committed deliverables include a new 565-line `sim/phase_s5_matfree_tail_recovery_gate.jl`, not listed in the plan's Files/detail column for D (only the `.md` predeclaration was); active roster shows `S5-predecl` and `S5-script` as distinct dispatches | scope, model routing | **adaptive, with a named plan defect** | Ada (owns it — self-identified) | **Resolved by `main`:** S5-script was a real additional dispatch (Sonnet, default effort) — the plan's Files column was the thing that was wrong, not the dispatch: the predeclaration defines "freeze" as text committed byte-identical to a named script at a frozen hash, so the goal was not completable without one. Net producer count stays **6** (C, D, E, S5-script, G, H) — not 7 — because slice F never got its own child (see row 8), so the composition shifted but the total didn't. |
| 4 | Fence touch: `md5` run on the quarantined `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` during slice C, contrary to D-84 ("never inspect, stage, edit, or hash it") | safety gates | **drift** (confirmed, already closed) | Rose (already actioned); Ada (standing-guard hardening) | Disclosed in `f0093eb7` message and `coordination-board.md` addition: "an agent ran `md5` on the quarantined [file]... contrary to D-84... file was not opened, edited, or modified — confirmed still untracked, size 14421 B, mtime unchanged." No independent re-verification performed by this audit (fence: never touch that file) — taking the disclosure as given, per instructions. |
| 5 | Cross-repo GitHub issues filed on GLLVM.jl #182 and DRM.jl #388 mid-arc, cross-posting the F6 RNG-fragility finding — outside the plan's stated scope (this repo only) and outside the plan's slice table entirely | scope, public claims | **adaptive** (framed by `main` as user-directed) | Ada (cross-repo lane) | Independently confirmed via `gh issue view 182 --repo itchyshin/GLLVM.jl` and `... 388 --repo itchyshin/DRM.jl`: both exist, created 2026-08-04T15:27 UTC (between `7ceaff17` 16:13 UTC and `f0093eb7` 16:36 UTC), content is a verbatim-consistent cross-post of `7ceaff17`'s own diagnosis numbers. No slice in the plan covers this; recorded as scope growth regardless of justification. |
| 6 | Plan's context hypothesis (dr26 zero-boundary mechanism explains `converged=false`) FALSIFIED by slice B; S5's outcome classification changed from two-way (graceful/non-graceful) to three-way (CONVERGED/CAP-EXHAUSTED/NON-GRACEFUL) as a direct, disclosed result | evidence/verification | **adaptive** (exemplary) | domain reviewer (Fisher/Mrode) | `7ceaff17`: "converged=false was cap exhaustion, NOT the zero-boundary early break." Predeclaration's explicit "Why three-way, and why now" callout (lines 181-201) and revision log record the falsification as falsified-and-recorded, not quietly dropped; propagated consistently into Rose's after-task and the `AGENTS.md` snapshot. |
| 7 | The SMOKE mode of slice C's new driver (`sim/f6_matfree_recovery.jl`) reported a meaningless FAIL at `nm=60` — provenance took FOUR rounds to settle (Rose's report → this audit's flag → slice-C's partial counter → `main`'s correction → Rose's retraction → **Rose's reinstatement of the original attribution, `c0d35d5e`**) | evidence/verification | **adaptive, settled (final)** | closed — `main` + `rose-closeout` | **Final settled sequence, per `c0d35d5e`'s primary-evidence citation** (`HSQ_F6_SMOKE=1 ... sim/f6_matfree_recovery.jl` → `host=totoro julia=1.10.0`, `exact: sigma_a2=0.0000 sigma_e2=0.7044 h2=0.0000 converged=false iterations=100`, `GATE: FAIL`, correctly nm=60-scaled — this resolves the citation mismatch this audit flagged against `main`'s earlier, wrongly-cited q=25,000 numbers): slice-C saw `rel_a≈980` in her own local SMOKE run, judged it acceptable against F5-v2 precedent, did **not** fix it → the Totoro SMOKE run hit the SAME file (copied from the uncommitted working tree, not from git) and surfaced `GATE: FAIL` to the orchestrator → the orchestrator fixed it and verified on both Julia versions before the single commit landed. **This audit's own reasoning error, owned plainly:** row 7 originally leaned on `git log --all --oneline -- sim/f6_matfree_recovery.jl` returning one commit as evidence the defective version "could not have shipped or been run on Totoro." That inference does not hold — git history records committed snapshots, not working-tree state; an uncommitted file can be copied to a remote host, run, found broken, and fixed in place before its first (and only) commit, leaving zero git trace of the broken intermediate. Per `c0d35d5e`: "two independent agents [this audit and `rose-closeout`'s own retraction] converged confidently on a wrong conclusion by reasoning from git history about work that was still uncommitted." Correct, and worth carrying forward: **absence from `git log` is not absence from the session.** `rose-closeout` kept her own retraction visible rather than erasing it (`3e00eaae` → `c0d35d5e`, both separate commits, none amended) — same convention followed here. |
| 8 | Slice F (MECHANICAL-VERIFY), planned as its own Haiku/recon dispatch, does not appear as a distinct agent in the active roster; its full checklist (CI green both Julia versions, coverage retained, `public_covered_count`, no row change, `preamble_cap.sh`, docs build) was executed inside Rose's slice-G audit instead | scope, model routing | **adaptive, cost-tier mismatch** (confirmed by `main`) | Ada (routing/cost tiering) | Rose's after-task Evidence table runs every item on slice F's checklist, at Sonnet·high rather than the plan's declared "Haiku · low." `main` confirms: F was never dispatched — she ran the mechanical checks inline herself (`preamble_cap.sh`, `status_cache.json`, before/after status-word counts, both `Pkg.test()` runs), and Rose re-ran both suites again during her audit. Haiku-grade work ran on the orchestrator; all checks did run, only the tier/cost matched the plan. |
| 9 | All three commits carry `Co-Authored-By: Claude Opus 5`, against the plan's explicit "No Opus child" statement and all-Sonnet slice table | model routing | **resolved — not a deviation** | n/a | `main`: the trailer is the *orchestrator's* authorship tag, required by her own base instructions on every commit she authors, independent of which sub-agent produced the content — it appears on all three commits regardless. **No Opus child was ever spawned**: `model: sonnet` was passed explicitly to slice-C, S5-predecl, totoro-smoke, S5-script, rose-closeout, and this audit; Phase-0 recon ran Sonnet+Haiku; Phase-2 plan review ran Sonnet. The Rose-escalation trigger ("C removes rather than relocates coverage") never fired, independently confirmed by Rose's own audit. Fence held cleanly; the flag was a misread of commit-trailer convention, not a real routing gap. |

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

- **Row 8** (slice F folded into slice G) — not on the candidate list; confirmed by `main`.
- **Row 9** (Opus co-authorship vs. the plan's "No Opus child") — not on the candidate list; resolved
  as a non-deviation (orchestrator authorship convention, not a routing signal).
- **Row 7's correction** — the candidate list's original framing ("shipped defective... fixed later
  after Totoro exposed it") turned out closer to right than this audit's first-pass skepticism gave it
  credit for, but needed three rounds (Rose → this audit → slice-C → `main`) to settle the precise
  sequence and drop one mismatched supporting citation along the way. See row 7's evidence column.

## Resolution addendum (same session)

`main` answered the two open routing-receipt questions and issued a correction on row 7's provenance
after this file's first commit (`124e8ada`):

- **Row 3** (possible 7th child): resolved — real dispatch, plan defect, not a budget overrun. Tag
  updated `unclear` → `adaptive, with a named plan defect`.
- **Row 9** (Opus co-authorship): resolved — orchestrator tag, no Opus child spawned, fence held. Tag
  updated `unclear` → `resolved — not a deviation`.
- **Row 7** (SMOKE provenance): `main` supplied a settled sequence; this audit recorded it with one
  flagged citation mismatch. `rose-closeout` then went one step further and **reinstated her original
  Totoro attribution** (`c0d35d5e`, after her own `3e00eaae` retraction), on primary evidence this
  audit did not have: the driver ran from the *uncommitted working tree* on Totoro, so `git log`
  showing one commit proves nothing about what ran before that commit. That also resolves this
  audit's citation-mismatch flag — `c0d35d5e`'s citation is correctly nm=60-scaled, not the q=25,000
  numbers `main` cited first. Tag settled at `adaptive, settled (final)`.

**Standing lesson, owned by this audit, not just observed in Rose's:** row 7's original text treated
`git log --all` returning a single commit as proof the defective version was never run anywhere. That
inference is invalid — git records commits, not working-tree state or remote-host activity on
uncommitted files. This audit and `rose-closeout`'s own retraction both made the same error
independently. Noting it here rather than in `PLAN-DRIFT-LEDGER.md`, since that ledger is for
recurring classes aggregated monthly and this is a single instance so far — but it is exactly the
shape of thing to watch for a second occurrence of.

No row's underlying technical substance changed as a result of either addendum —
`public_covered_count` stays 5, no capability flip, nothing shipped defective, all eight GOAL fences
held throughout. Only attribution/provenance precision changed, across four rounds, on one low-stakes
detail.

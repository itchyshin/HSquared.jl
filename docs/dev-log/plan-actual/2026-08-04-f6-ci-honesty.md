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
| 7 | The SMOKE mode of slice C's new driver (`sim/f6_matfree_recovery.jl`) reported a meaningless FAIL at `nm=60`; the bug/fix/no-impact substance was undisputed across every account throughout; the discovery mechanism took six rounds to close on falsifiable, independently-reproduced evidence rather than another citation | evidence/verification | **CLOSED — adaptive, verified** | closed | **Closed on machine state, reproduced by this audit independently, not accepted on any agent's say-so** (the orchestrator's own instruction: "run the command yourself... don't close it on my say-so"). This audit ran, via the standing Totoro `ControlMaster` socket: `ssh ... totoro 'ls -la ~/hsq_work/grace-f6smoke/sim/; grep -c "on_boundary\|ANOMALY" ~/hsq_work/grace-f6smoke/sim/f6_matfree_recovery.jl'` → **`f6_matfree_recovery.jl`, 5810 B, Aug 4 09:13; grep returns `0`** — an exact match to the orchestrator's predicted result, now also recorded in the after-task's Finding 6 (`docs/dev-log/after-task/2026-08-04-ci-rng-fragility-fix-and-s5-freeze.md:173-186`) so the check is reproducible from the record, not just cited into it. Cross-checked locally: the current in-repo `sim/f6_matfree_recovery.jl` contains `on_boundary`/`safe_rel`/`ANOMALY` (`grep -c` → 10, nonzero). **Why this is decisive and the earlier transcript-quote was not:** the fix introduced those three tokens; the Totoro-deployed copy has none of them and predates `7ceaff17`'s commit time (09:13 local vs. the 10:13:52 commit) — it is provably the pre-fix version, deployed and run before the fix existed, independent of any agent's memory or paraphrase. **Settled sequence, now closed:** slice-C saw `rel_a≈980`(later reconciled: Totoro's own original run actually reported **40925.4**, a naive absolute-denominator figure from before a later local re-run with a tighter `1e-8` cutoff produced the ≈980 number — two different runs, two different denominators, conflated in earlier retellings including this audit's) in her own local run, judged it acceptable against F5-v2 precedent, did not fix it → the Totoro SMOKE run (working-tree copy, not a git checkout) hit the same file and surfaced `GATE: FAIL` to the orchestrator → the orchestrator fixed it and verified both Julia versions before the single commit landed. |
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
  flagged citation mismatch. The orchestrator then went one step further and reinstated the original
  Totoro attribution (`c0d35d5e`), on evidence this audit did not have: the driver ran from the
  *uncommitted working tree* on Totoro, so `git log` showing one commit proves nothing about what ran
  before that commit. This audit marked the row `adaptive, settled (final)` on that basis — **too
  soon.**

- **Round 5 — `rose-closeout` reopened it, correctly, on two points.** (a) Attribution: `c0d35d5e` is
  the orchestrator's commit, not hers — she authored only the retraction, `3e00eaae`; already fixed
  upstream in `86e59a04`, which this audit's file had not yet caught up to when it last replied to
  her. (b) Substantive: `c0d35d5e`'s own "primary evidence" — the quoted terminal transcript — exists
  **only inside that commit's message**, with no standalone artifact anywhere in the repo (this audit
  searched: no log file, no TSV, no `*totoro*` output). **This audit's "settled (final)" call was a
  second reasoning error, not a fix of the first one:** showing that the git-log counter-argument was
  invalid does not make the original claim true — it only removes one piece of evidence *against* it.
  A more detailed quote is not more verified than a vague one; this audit treated specificity as a
  proxy for veracity, which is the same mistake in different clothes. **Downgraded back to open**,
  pending `rose-closeout`'s direct check with `totoro-smoke` for a first-hand confirmation or the
  actual log — the same standard this audit should have applied to `c0d35d5e` from the start instead
  of accepting an orchestrator's commit message as self-authenticating.

- **Round 6 — closed, on falsifiable machine state this audit reproduced itself.** The orchestrator
  did not restate the claim; she checked the deployed artifact on Totoro directly (`9833c481`) and
  handed this audit the exact command, inviting independent falsification rather than asking for
  trust: "run the command yourself... don't close it on my say-so." This audit ran it via the standing
  Totoro `ControlMaster` socket and got an exact match to the predicted result (file present, 5810 B,
  Aug 4 09:13, `grep -c "on_boundary\|ANOMALY"` → `0`), cross-checked against the current in-repo file
  (same grep → `10`, nonzero). The Totoro copy predates the fix and predates `7ceaff17`'s commit time —
  provable from file content and mtime, not from anyone's account of it. Closed row 7 on that basis.
  Also folded in: the orchestrator's own correction of a secondary conflation she'd been repeating
  (Totoro's original run reported `40925.4`, not the `≈980` figure quoted in most retellings — two
  different runs, two different denominators).

**Standing lesson, now in three parts, all owned by this audit rather than left as something Rose or
`main` found on their own:** (1) row 7's original text treated `git log --all` returning a single
commit as proof the defective version was never run anywhere — invalid, since git records commits,
not working-tree or remote-host state. (2) Round 4 then treated "the counter-argument against a claim
is invalid" as equivalent to "the claim is verified" — also invalid; a quoted transcript with no
independent artifact is exactly the same evidentiary category as the "found via a Totoro probe"
phrase that started this whole thread, no matter how detailed. (3) **The structural cause of the
repeated misattribution, per `main`:** every commit in this swarm carries identical `Author`/
`Co-Authored-By` trailers regardless of which sub-agent produced the content (row 9's finding,
independently), so `git blame`/`git log` cannot answer "who did this" at all — only the swarm's own
task-routing record can, which is exactly why the `c0d35d5e` misattribution happened twice (once by
this audit, independently caught and fixed once by `main` in `86e59a04`) before anyone said so
explicitly. All three are noted here rather than in `PLAN-DRIFT-LEDGER.md` (that ledger aggregates
recurring classes monthly; each is one instance so far within a single arc's closeout, not yet a
cross-arc pattern), but all three are exactly the shape of thing to watch for a second occurrence of —
(3) in particular is a standing structural fact about this swarm, not a one-off, and the next
reconciliation that needs to attribute a specific commit to a specific sub-agent should expect to hit
it again.

No row's underlying **technical** substance changed across any of the six rounds —
`public_covered_count` stays 5, no capability flip, nothing shipped defective, all eight GOAL fences
held throughout, and the bug/fix/no-impact facts were undisputed by every account from round one.
What moved, six times, was attribution/provenance precision on one low-stakes detail — genuinely open
at every intermediate round, not performatively so, and closed in the end on a falsifiable check this
audit reproduced itself rather than on any agent's account of it, including this audit's own earlier
ones.

# Plan vs. actual — H² twin test campaign, wave 4 (FINAL) and campaign close

- Date: 2026-09-13
- Plan: `/Users/z3437171/shinichi-brain/projects/H2-twin/ultra-plan.md`
- Wave-4 addendum: `/Users/z3437171/shinichi-brain/projects/H2-twin/briefs/wave4-addendum.md`
- GOAL block: `/Users/z3437171/shinichi-brain/projects/H2-twin/GOAL.md`
- Wave: 4 of 4. This is the final wave by the stopping rule's own clause (ii), and Rose's
  audit also fires clause (i) (2 new clusters, below the 3-cluster floor). The campaign is
  closed.
- Reconciler: Melissa. Read-only against the plan, `GOAL.md`, the wave-4 addendum, my own
  wave-1 to wave-3 records, the six wave-4 lane receipts, the wave-4 mechanical-verify
  receipt, Rose's wave-4 audit and its campaign close-out section, `MISSION-CONTROL.md`,
  `checkpoint.md`, `AGENT_LOG.md`, `DECISIONS.md` (D-262), live GitHub state measured this
  session (`gh issue list`, `gh issue view --json comments`, `gh label list`), a local-path
  grep on the two new issue bodies and the five newest comment bodies, and the wave-4
  Workflow's own agent metadata files. This document is the only file this session wrote.

Cross-checked live, this session: 2 new issues since the wave-3 count
(`HSquared.jl#333`, `#334`, both `createdAt 2026-09-13T16:29:0[6-7]Z`) and 5 new comments
(on `hsquared#214`, `#212`, `#210`, `HSquared.jl#331`, `#327`, all `createdAt
2026-09-13T16:29:0[0-5]Z`) — 7 items, one short of Rose's stated "7 items" posting order
(2 new issues + 5 comments = 7; matches exactly). Cumulative since 2026-09-13: 15 issues
(`hsquared#208`–`#218`, `HSquared.jl#327`, `#331`, `#333`, `#334`; `gh issue list --search
"created:>=2026-09-13"` on both repos, this session) + comment counts on the nine named
threads (`hsquared#201`: 4 total, 1 pre-campaign; `#208`: 2; `#210`: 1; `#211`: 1; `#212`: 2;
`#214`: 2; `HSquared.jl#53`: 3 total, 2 pre-campaign; `#327`: 3; `#331`: 1 — `gh issue view
--json comments` on each, this session) sum to 16 campaign comments. **15 + 16 = 31 filed
items**, matching `MISSION-CONTROL.md`'s "Items filed (final): 31" and D-262's outcome note
exactly. `gh label list` on both repos still returns no `test-campaign` label. All 7 bodies
grepped for `/Users/z3437171|shinichi-brain|claude-503`: **0** hits in every case.

## Wave-4 planned vs. actual, per lane

| Lane | Addendum focus | What ran | Receipt | Drafts → Rose verdict | Filed |
| --- | --- | --- | --- | --- | --- |
| L1 Simulator | (a) second independent seed for `multi_effect`/`random_regression` parity; (b) `initial`/`iterations` sweep across `henderson_mme`, `sparse_reml`, `single_step`, `single_step_construct`, `metafounder_single_step`, `repeatability`, `multivariate`, and the interval helpers; (c) one unbalanced repeated-records `repeatability` design | All three ran exactly as specified, plus the standing negative control. Second seeds: `multi_effect` and `random_regression` both EXACT (0.000e+00) again, confirming wave 3 was not a one-seed fluke. Sweep: `single_step_construct`/`metafounder_single_step` drop `iterations` only (`initial` genuinely honoured, confirmed by pushing to `1e6`); `multi_effect_ratio_interval` drops both, via a separate refit code path; six other targets confirmed honouring. Unbalanced repeatability (90 animals, 374 records, 2–6 per animal): EXACT parity | `updates/2026-09-13-simulator-w4.md` | 1 comment draft (extends `#212`) → **MERGE** | comment on `hsquared#212` |
| L2 Data Fitter | (a) re-check whether wave 3's VanRaden-convention caveat transfers to the BTdata `sommer` reference; (b) one more real dataset (`PlodiaPO` or `milk` subset) through `repeatability`, **with a reference fitter third**; (c) campaign-synthesis table across all four waves | (a) `nadiv::makeA()` vs. `HSquared.jl`'s exported `pedigree_inverse()` on the identical `BTped` pedigree agree to `1.554e-15`; caveat does not transfer, and wave 2's ~0.5% gap is attributed to REML estimation, not matrix construction. (b) `MCMCglmm::PlodiaPO` fit through `repeatability`: zero-replication structural non-identifiability slips past the boundary-flag tolerance; **no reference fitter was obtained** for this dataset, contrary to the addendum's explicit third-leg ask. An unplanned extra run (a natural full-sib `two_effect` spelling) was also done. (c) done, 10-row table | `updates/2026-09-13-fitter-w4.md` | 1 draft (repeatability-no-replication-check) → **DROP** (refuted by `man/hs_control.Rd:88`) | none (not posted; file kept as vault evidence) |
| L3 Doc Reader | (a) run `julia --project=docs docs/make.jl`, confirm `docs/build` is the only diff via `git status --porcelain`; (b) cold-read "the 14 Julia Documenter pages not yet read"; (c) campaign-synthesis table of all 21 R articles and the Julia pages | (a) build ran (~58 s); **the addendum's own premise was false** — `docs/src/validation-status.md` is tracked and is rewritten with a timestamp-only diff on every run, confirmed deterministic from the generator source, not just the one observed run. (b) **only 3 pages remained, not 14** — wave 2 and 3 had already read 16 of the 19 `docs/src/*.md` files; L3 read the 3 that remained (`progression-evidence.md`, `twin-boundary.md`, `validation-status.md`) and recorded the addendum's miscount as "a campaign-bookkeeping slip in an addendum, not a repo defect." (c) done | `updates/2026-09-13-docreader-w4.md` | 1 new-issue draft (docs-build-dirties-tracked-file) → **KEEP** | `HSquared.jl#334` (new issue) |
| L4 Mathematician (Opus) | (a) run the metafounder Γ = 0 collapse check; (b) GBLUP↔SNP-BLUP equivalence at 3 seeds, default ridge; is the gap ridge-induced (compare ridge = 0 and 1e-6)?; (c) chi-bar mixture weights for `#331`'s LRT if cheap, else state direction and stop; (d) campaign-synthesis estimand ledger | Exceeded all three literal asks. (a) ran on **both** twins (Julia native and the public R `metafounder()` route), not just "run it": collapse exact (bit-identical Julia; `5.2e-15` through R) on a pedigree with genuine inbreeding. (b) ran 3 seeds × 2 variance ratios × **4** ridges (0, 1e-6, 0.01, **and 0.1**, not just the two named): equivalence exact (`3.1e-15`–`1.4e-14`) against a GLS reference; the gap through `fit_gblup` tracks the ridge linearly, confirming wave 3's 1.7% figure was ridge-induced. (c) went beyond "state direction and stop": computed the exact two-point mixture attainability test and found the `:lowrank` reported p-value **is not attainable by any chi-bar mixture at all** | `updates/2026-09-13-mathematician-w4.md` | 4 drafts (2 new issues, 2 comments) → **1 KEEP + 3 MERGE** | `HSquared.jl#333` (new issue); comments on `HSquared.jl#331`, `HSquared.jl#327`, and (retargeted by Rose from `hsquared#201`) `hsquared#210` |
| L5 Code Reviewer | (a) sweep ~15 `julia_command()` call sites in `R/julia-bridge.R` for the raw-Julia-trace pattern (`#214` class), one invalid input each, comment draft with the table; (b) `tau`/`omega`/`blend_weight` knobs and `hs_data()`-bundle resolution for `single_step(1 \| id)`; (c) final ship/blocked/stop tally over all 96 exports and all `hs_control()` targets | All three ran exactly as asked. (a) confirmed the pattern **narrows, does not generalise**: 14 of 17 payload functions are protected by centralised R-side validators; `genomic()`/`snp_blup()` survive the identical hostile input that breaks `single_step()`'s construction path, because of a nonzero default ridge the latter lacks. (b) knobs honoured (a `blend_weight` isolation moved the fit result smoothly, `0.159`→`0.082`); `hs_data()`-bundle resolution byte-identical to the explicit call. (c) tally reported as 82 ship / 13 blocked / 1 confirmed-reserved / 0 stop | `updates/2026-09-13-codereviewer-w4.md` | 1 comment draft → **MERGE** | comment on `hsquared#214` |
| L6 Speed | (a) extend the corrected replicated design to q = 20,000 and 50,000, `HSquared.jl` vs. `pedigreemm`, agreement first, stop at 30 min; (b) three process repeats at q = 5,000 for both engines; (c) campaign-synthesis timing ledger and the exact sentence a maintainer may/may not say about ASReml | All three ran exactly as asked, well under the 30-minute cap. (a) agreement holds to ≤1.2e-6 relative difference at every size 1,000–50,000; `HSquared.jl` is ~29× faster cold and ~61× faster warm than `pedigreemm` at q = 50,000 on identical data — a comparator fact stated as such, not an ASReml claim. (b) spread at q = 5,000 is small (`HSquared.jl` cold range ~2.5% of the mean; `pedigreemm` ~23%, one outlier repeat). (c) ASReml opinion unchanged, vault-only, "unknown within 3×" | `updates/2026-09-13-speed-w4.md` | 0 (4th consecutive wave with zero drafts) | none |
| V1 mech-verify | Gate re-run: receipt structure, `compute_minutes`, draft front-matter (including the `kind:` column wave 3 lacked), worktree cleanliness, GitHub state, speed-label check, campaign file counts | 6/6 receipts have `compute_minutes` (10/4/14/9/14/8, summing to 59, correctly totalled); 5 of 6 have an exact `## Campaign synthesis` heading (docreader-w4 has the content under `## (c) Campaign synthesis` instead — a heading-level mismatch, not a missing section); 8/8 new drafts structurally complete; 2 of 8 lack an explicit `kind:` field but both have filed issues, which the tool correctly notes satisfies the intent; both worktrees clean; issue-count check matched expectations before posting | `updates/2026-09-13-mech-verify-w4.md` | — | — |
| V2 Rose (Opus) | Claim-vs-evidence audit of the 8 drafts, plus a campaign-level close-out across all four waves | Re-ran the load-bearing repro for 3 of 7 cleared drafts, verified the rest from source/logs with named exceptions. Corrected 3 drafts in place (line numbers, a widened claim, a rewritten "why this matters" paragraph that had argued from the addendum itself rather than from the repo). Retargeted 1 comment from `hsquared#201` to `hsquared#210`. Refuted the one DROP by running the public API/citing `man/hs_control.Rd:88` directly. Corrected two counting errors: her own wave-3 "27 drafts" (arithmetic gives 29) and the wave-4 addendum's "fourteen already filed" (live GitHub gives 13 issues + 2 comment threads = 15 filed targets/15 clusters). **KEEP 2 · MERGE 5 · DROP 1** | `articles/2026-09-13-rose-audit-w4.md` | — | — |
| V3 Melissa | This reconciliation | This document | this file | — | — |

## Wave-4 deviations

| Axis | Deviation | Tag | Owner | Evidence |
| --- | --- | --- | --- | --- |
| Scope | L2's addendum item (b) explicitly asked for a reference fitter "third" on the new dataset. No reference fitter was obtained for `PlodiaPO`; the lane says so directly | ADAPTIVE | domain reviewer (L2) | `briefs/wave4-addendum.md` L2 item (b); `updates/2026-09-13-fitter-w4.md` "NOT COVERED" ("A reference fitter for `PlodiaPO`'s full-sib model. No third-party... fit was attempted this wave") |
| Scope | L2 ran an unplanned extra analysis (a natural full-sib `two_effect` model on `PlodiaPO`) not named in the addendum, and found it a design limitation, not a defect | ADAPTIVE | domain reviewer (L2) | `updates/2026-09-13-fitter-w4.md` "Agreed" §(b), second bullet |
| Scope | L4 exceeded the literal ask on all three of its named items: ran the Γ = 0 check on both twins (not just "run it"), swept 4 ridge values instead of the 2 named, and computed an exact chi-bar attainability result instead of "stating the direction and stopping" | ADAPTIVE (positive) | domain reviewer (L4) | `briefs/wave4-addendum.md` L4 items (a)-(c); `updates/2026-09-13-mathematician-w4.md` "What ran" |
| Evidence / verification | The wave-4 addendum itself carried a false premise about the repo: it stated `docs/make.jl` "writes only under `docs/build`, which is untracked." L3 tested this directly and found `docs/src/validation-status.md`, a tracked file, is rewritten with a timestamp-only diff on every run | DRIFT | Ada (addendum author) | `briefs/wave4-addendum.md` L3 item (a); `updates/2026-09-13-docreader-w4.md` "(a) `docs/make.jl` build" |
| Evidence / verification | The wave-4 addendum's L3 item (b) named "the 14 Julia Documenter pages not yet read." Waves 2-3 had already read 16 of the 19 `docs/src/*.md` files; only 3 remained. L3 read the 3 and recorded the miscount as "a campaign-bookkeeping slip in an addendum" | DRIFT | Ada (addendum author) | `briefs/wave4-addendum.md` L3 item (b); `updates/2026-09-13-docreader-w4.md` "(b) Cold-read the remaining Julia Documenter pages" |
| Evidence / verification | The wave-4 addendum's own framing said "NEW clusters beyond the fourteen already filed." Live GitHub, read by Rose and independently re-derived this session, gives 13 issues + 2 comment threads = 15 filed targets across 15 clusters before wave 4, not 14 by either reading | DRIFT | Ada (addendum author) | `articles/2026-09-13-rose-audit-w4.md` "Summary," "A counting correction"; `gh issue list --search "created:>=2026-09-13"` on both repos, this session |
| Evidence / verification | L5's campaign-synthesis tally (82 ship / 13 blocked / 1 reserved / 0 stop over 96 exports) does not reconcile with the only classification artifact on disk, `codereview-final-classification.tsv` (66 ship / 14 blocked / 11 not-tested / 3 stop, plus one malformed row). Rose flags this as unresolved and says it "must not be quoted as a campaign result" | UNCLEAR | L5 / Ada | `articles/2026-09-13-rose-audit-w4.md` §"What this campaign did NOT establish," last bullet |
| Model routing | The wave-4 Workflow (`wf_eb56f9a8-3cf`) dispatched 5 of the plan's 6 lanes; L2 Data Fitter was refused by the auto-mode classifier inside the Workflow and relaunched as a standalone dispatch, producing a 6th receipt outside the Workflow's own agent records | ADAPTIVE (recovered without loss; same classifier-friction class noted in earlier waves' `gh` calls, now hitting agent dispatch) | Ada | 5 `agent-*.meta.json` files under `wf_eb56f9a8-3cf` (models: sonnet ×4 — `curie-validation-tester`, `pat-user-tester`, `gauss-numerical-engineer`, `rose-systems-auditor`; opus ×1 — `noether-math-reviewer`); `MISSION-CONTROL.md` wave-4 row ("Five via Workflow... the Data Fitter relaunched standalone after a classifier refusal"); no `fitter`-lane agent file exists in that Workflow directory |
| Safety gates | `.unlazy/h2-test-campaign/GATES.md` in this Dropbox checkout still reflects only wave 1: G8's evidence names the wave-1 KEEP set only, and G10–G12 still read "pending," despite the plan's own DISCIPLINE line requiring gates "re-run with `--reverify`." Whether the campaign lane re-ran an equivalent ledger elsewhere (e.g. `/private/tmp/h2camp-lane`) is not established from this checkout, which sits on branch `claude/h2-three-scale-naming-20260908`, not a campaign branch | UNCLEAR | Ada | `.unlazy/h2-test-campaign/GATES.md` (this session); `git status --short --branch` (this session); `ultra-plan.md` DISCIPLINE line |
| Safety gates | The pre-authorised `test-campaign` GitHub label still does not exist on either repo, unchanged since wave 1 | ADAPTIVE (recurring, unresolved) | Ada | `gh label list --repo itchyshin/hsquared \| grep -i test` and the HSquared.jl equivalent, both empty this session |
| Safety gates | Rose's one DROP this wave is the sixth instance across four waves of the identical lane failure shape (a "the R man pages do not name X" claim from checking 2-3 pages, refuted by a page the lane did not check). Not a gate failure or a MUST STOP, but the recurrence itself is the wave's clearest evidence that the standing reminder ("ask the package before concluding") is not sufficient on its own | DRIFT (process) | Rose / lanes | `articles/2026-09-13-rose-audit-w4.md` §"One DROP..." and §(c) "The one process lesson" |
| Handoff state | Wave 4's Workflow lanes started at 09:40:24 local (`agent-a4d61778d58f0a484.meta.json` earliest timestamp); this reconciliation's own predecessor file (Melissa w3) has mtime 09:39:37 local, 47 seconds earlier. The between-wave gate in `GOAL.md` ("wave N+1 starts only after wave N's V1, V2, and V3... are green") is honoured on its own terms, but by a margin too thin to call comfortable | UNCLEAR | Ada | `stat -f "%Sm"` on both files, this session |

No deviation found on the **public claims** axis: Rose's grep of all eight wave-4 drafts for
speed/ASReml wording found only two benign wall-time disclosures, and no draft, issue, or
comment posted this wave carries a speed or capability claim. Rose went further than the L6
receipt itself: the receipt had offered, conditionally, that a maintainer "could" say
`HSquared.jl` agrees with `pedigreemm` to better than 1e-5 relative difference across
1,000-50,000 animals; Rose's audit explicitly declines to let the campaign license even that
sentence, on the grounds that it rests on one host and one thread configuration and has never
been through a claim-vs-evidence gate as a public agreement claim. This is the audit
tightening what the campaign will license, not a deviation from the envelope.

## CAMPAIGN — plan vs. actual across all four waves

### GOAL block deliverable list

The plan's Deliverable line names two parts. **(A)** the 2026-09-13 handover closed on disk:
done in wave 1 (PR #325 merged; check-log entry landed in PR #326; `gh pr view 325 --json
state,mergedAt` this session confirms `MERGED`). **(B)** the H² twin test campaign opened and
run hands-off to its stopping rule, with charter, vault Mission Control, a bridge-liveness
receipt, six lane receipts per wave, a speed-opinion receipt, and real GitHub issues/comments
for every Rose KEEP: all delivered. Charter `docs/design/57-h2-test-campaign-charter.md`
(landed, corrected once); vault `projects/H2-twin/` current; bridge-liveness receipt
`updates/2026-09-13-bridge-gate-w1b.md` (7/7 PASS); 24 lane receipts across four waves (6 × 4,
matching D-262's "24 lane runs"); four speed receipts, each ending in an AGENT-INFERRED,
vault-only opinion; 31 items live on GitHub (15 issues + 16 comments), confirmed this session.

`GOAL.md`'s own "Definition of done" adds five conditions beyond the stopping rule itself:

1. **Gates G1-G12 green for the last wave.** UNMEASURED as a single artifact. The only gate
   ledger this session could locate, `.unlazy/h2-test-campaign/GATES.md` in this Dropbox
   checkout, still shows wave-1 evidence for G8 and "pending" for G10-G12; it was not found
   re-run for waves 2, 3, or 4 in this checkout. The individual claims each gate checks (no
   tracked-file edits, drafts filed only after Rose's KEEP, speed labelled AGENT-INFERRED,
   explicit models per dispatch) were each independently re-verified by this and the prior
   three Melissa records through other evidence, so the underlying facts are not in doubt; the
   single-file "gates green" artifact the plan names is what is missing or elsewhere.
2. **`MISSION-CONTROL.md` current.** Confirmed: reads "CAMPAIGN CLOSED," item counts match
   live GitHub exactly.
3. **After-task report validated.** Not yet done for wave 4 at the time of this reconciliation
   — `checkpoint.md` sequences it after this file, which is expected, not a deviation.
4. **`memory/AGENT_LOG.md` and `memory/DECISIONS.md` updated.** Both confirmed current: the
   2026-09-13 `AGENT_LOG.md` entry narrates the campaign through this reconciliation's own
   start ("Melissa w4 + campaign reconciliation... in flight at this log line"), and `DECISIONS.md`
   D-262 carries a dated "Outcome" paragraph matching the live counts exactly.
5. **Informational report to Shinichi.** Not yet sent at the time of this reconciliation, per
   `checkpoint.md`'s own sequencing (this file, then after-task, then the report).

### Stopping rule

Fired twice over, per Rose's audit: clause (i) (wave 4's KEEP set added 2 new clusters,
below the "fewer than 3" floor) and clause (ii) (wave 4 is complete). Cumulative posted items,
31, stayed far under clause (iii)'s 60-item ceiling. No MUST STOP trigger (clause iv) fired at
any point in the campaign, confirmed by four waves of clean worktree checks and no
capability/version/release action.

### Envelope

**Nothing found outside the envelope.** No release, tag, version bump, capability-status or
validation-debt row change, Julia General or CRAN action, speed/ASReml public wording, edit to
`src/`, `R/`, `test/`, or `tests/` of either repo, DRAC use, destructive git operation, or
personal data in a public issue, across any of the four waves — confirmed this session via the
same worktree/label/comment checks used for wave 4 above, and via each prior Melissa record's
own independent confirmation for its wave. Fan-out stayed inside `≤5 live children, ≤1 Opus
ceiling child per checkpoint` in every wave this reconciliation could check by name (wave 1's
own record showed the 5-live cap "actually bound something"; wave 4's 5 Workflow agents plus 1
sequential standalone relaunch, confirmed above, never exceeded 5 concurrently).

**One envelope condition never had occasion to bind.** The "two Rose DROPs of the same lane in
a row" pause trigger fired mechanically once (L1, wave 1) and worked as designed. L2's
DROP-KEEP-mixed-DROP sequence across waves 1, 2, 3, and 4 never produced two literal
consecutive DROPs within a single wave-to-wave pairing in the way the rule contemplates, though
Rose recommended a discretionary re-brief in wave 3 on the same grounds; since wave 4 was the
last wave regardless, this was never tested to its conclusion.

**Everything pre-authorised inside the envelope that had come due was used.** Direct filing
after Rose's KEEP (no per-wave approval loop), merge-when-green on six docs-only PRs (#325,
#326, #328, #329, #330, #332, all confirmed `MERGED` this session), continuing waves to the
stopping rule without sign-off, and local vault commits throughout. The one pre-authorised item
not yet exercised is the final records PR (after-task w4 + plan-actual w4-final); it is
explicitly sequenced after this document by `checkpoint.md`, not overdue.

### Estimate vs. actual

The plan's ESTIMATE line states "~4.5-5.5 h wall (C1 ≈ 1 h incl. Wave 0; C2 ≈ 2.5-3 h; C3 ≈
1 h)," and the plan's own Phase-2 slice table maps C2 to dispatching wave 1's six lanes and C3
to that wave's verification — i.e., the estimate as written covers the handover close plus
**one** wave, not four. The actual campaign ran **four** waves in roughly 4 h 45 min wall
(`DECISIONS.md` D-262: opened "2026-09-13 ~06:00," outcome recorded "same day, 2026-09-13
~10:45"; `MISSION-CONTROL.md`: "Four waves in one day (06:00-10:45 local)"). The four Workflow
runs themselves were fast: wave 1 24 min, wave 2 31 min, wave 3 23 min, wave 4 17 min
(`MISSION-CONTROL.md` per-wave rows), 95 minutes of lane-wall-time across the whole campaign.
The remaining ~3.9 hours went to charter/handover work, four Rose audits, four rounds of
posting, four PRs, and four Melissa reconciliations. Net: the entire four-wave campaign
finished inside the wall-clock budget the plan allotted to one wave, a large positive
deviation, tag ADAPTIVE, owner Ada, evidence as cited.

### Fan-out budget vs. actual, per checkpoint

The plan's FAN-OUT BUDGET line names three checkpoints for the plan's own C1-C3 shape (C1 new
children 2/6; C2 lanes 6/6, ≤5 live, ceiling 1; C3 verify 3/6, scout 1, ceiling 1); waves 2-4
came from addenda rather than a re-budgeted slice table, so this reconciliation checked each
wave's actual dispatch against the same `≤5 live / ≤1 Opus ceiling` rule directly rather than
against the plan's wave-1-specific numbers. Wave 1: 6 lanes in one Workflow, 5-live cap
confirmed binding (wave-1 Melissa record: `l6-speed` queued until `l3-doc-reader` freed a
slot). Wave 2: 6 lanes, sonnet ×5 + opus ×1, no fan-out deviation recorded. Wave 3: 6 lanes,
same shape, no fan-out deviation recorded. Wave 4: 5 lanes live in one Workflow (sonnet ×4,
opus ×1, confirmed by name from `wf_eb56f9a8-3cf`'s agent meta files) plus 1 lane (L2)
relaunched standalone strictly after the other five had already finished (Workflow agents'
last activity ~09:57 local; the standalone fitter receipt's file mtime 10:09 local) — never 6
concurrently live. No fan-out deviation found in any wave.

### Recurring-class ledger, all four waves

| Class | First seen | Wave 2 | Wave 3 | Wave 4 |
| --- | --- | --- | --- | --- |
| `AGENT_LOG.md` goes stale mid-campaign | W1 candidate 3 | RECURRED | RECURRED (3rd time) | **FIXED** — the 2026-09-13 entry is current through this reconciliation's own start |
| Between-wave V3-gate honoured before the next wave launches | W2 candidate 7 | violated (wave 3 launched before wave-2 Melissa finished) | explicit and honoured (checkpoint.md states the rule for wave 4) | honoured again, by a 47-second margin |
| Posting-hygiene local-path sweep applied to every posted body | W2 candidate 5 | partial (2 of 7) | **FIXED** (9 of 9 clean) | **FIXED again** (0 hits on all 7 wave-4 posted bodies, confirmed this session) |
| Mechanical verifier reads `compute_minutes` correctly | W2 candidate 6 | broken (misread a present field as absent) | **FIXED** (6/6 read, summed to 76) | **FIXED again** (6/6 read, summed to 59) |
| Mechanical verifier's schema covers the addendum's own requirements (`kind:` column) | W3 (new) | n/a | gap found (no `kind:` column; Rose's manual read caught 3-4 missing) | **FIXED** (column added; 2 of 8 flagged, both already had filed issues) |
| Routing-audit tooling sees Workflow-internal dispatch names / dual-named lenses don't collapse silently | W1 candidates 1, 4 | UNMEASURED | UNMEASURED | UNMEASURED by the named tool again, but independently confirmed this wave by direct inspection of the Workflow's own agent metadata files (a method not used in waves 2-3) |
| A tester concludes about the whole surface after checking part of it (Rose's DROP-cause) | W1 (3 DROPs, shared one cause) | 1 DROP (disclosed boundary behaviour, different cause) | 1 DROP (refuted directly by running the API) | 1 DROP, **6th instance of the same shape**; Rose proposes mechanising the check rather than repeating the reminder |
| `test-campaign` GitHub label never created | W1 | absent | absent | absent, confirmed again this session |
| Acceptance ledger (`.unlazy/.../GATES.md`) re-run per wave | not previously named | not verified in the W2 record | not verified in the W3 record | still shows only wave-1 state in this checkout (see deviations table); status elsewhere UNCLEAR |
| Brief/addendum premises about repo state are factually correct | not previously named | n/a | n/a | **NEW**: three separate false premises this wave (docs/build "untracked," "14 pages remaining," "fourteen already filed") |
| A lane's own synthesis tally reconciles with its own artifact | not previously named | n/a | n/a | **NEW**: L5's 82/13/1/0 tally does not reconcile with `codereview-final-classification.tsv`'s 66/14/11/3; unresolved |

## Verdict

The campaign delivered what the plan and `GOAL.md` asked for. Both handover items and the full
test-campaign apparatus (charter, vault Mission Control, bridge gate, four waves of six lane
receipts each, four vault-only speed opinions) are in place; the stopping rule fired on both
its own clauses in wave 4; 31 items sit live on both repos, all timestamped after Rose's audit,
all swept clean of local and vault-absolute paths on independent re-check this session; no
MUST STOP trigger fired in any wave; and the fan-out, compute, and posting-authority envelope
held in every wave this reconciliation could check, including wave 4's own classifier-refusal
recovery. Two of the campaign's longest-running weaknesses were fixed and held a second time
this wave: `AGENT_LOG.md` is current for the first time in the campaign rather than stale, and
the local-path posting sweep is clean for the second wave running. Against that, wave 4 is the
first wave in which the addendum briefing the lanes was itself wrong three separate times about
repo state, which the lanes and Rose caught and corrected rather than propagated; the
single-file acceptance-ledger artifact `GOAL.md` names as a closing condition could not be
located in a current, per-wave form in this checkout; and Rose's sixth same-shape DROP shows
the standing "ask the package" reminder is not, by itself, sufficient after four waves of
saying so. None of this reaches a MUST STOP, none of it changed a filed item's disposition
after the fact, and the campaign's own honest self-accounting, both this reconciliation's and
Rose's, is itself evidence the hands-off design worked: findings were filed, corrected in the
open, and closed on the record rather than smoothed over.

## Process rules for the next campaign

1. **Generate any addendum's factual claims about repo state from a live command run at
   brief-writing time, not from memory.** Traceable to wave 4's three false addendum premises:
   the "docs/build is untracked" claim, the "14 Julia pages remaining" count (actual: 3), and
   the "fourteen already filed" cluster count (actual: 15).
2. **A claim of "unreachable," "undocumented," "no way to," "nowhere," "cannot," or
   "inconsistent" must ship with the exact command and full output that establishes the
   negative, not a paraphrase of having checked.** Traceable to Rose's sixth same-shape DROP
   this wave and the three DROPs of wave 1 that shared the same cause.
3. **Re-run and re-record the acceptance ledger at the close of every wave, not only at
   campaign launch.** Traceable to this session finding `.unlazy/h2-test-campaign/GATES.md`
   reflecting only wave 1, with G8 and G10-G12 never refreshed.
4. **Diff the mechanical verifier's schema against the current wave's addendum requirements
   before the wave runs.** Traceable to wave 2's misread `compute_minutes` field and wave 3's
   missing `kind:` column, both fixed only after the fact.
5. **When a lane produces a running synthesis tally from its own notes, cite the artifact file
   it was computed from, and reconcile a late-campaign restatement against that file before
   filing it.** Traceable to L5's wave-4 tally not matching `codereview-final-classification.tsv`.
6. **Log a classifier-refused, standalone-relaunched lane in the same place the Workflow's own
   agent records live, not only in a narrative log line.** Traceable to wave 4's Data Fitter
   relaunch, confirmed only via `MISSION-CONTROL.md` prose and the absence of a sixth agent
   file in the Workflow directory.
7. **Build more than a sub-minute margin into the between-wave gate.** Traceable to the
   wave-3-to-wave-4 transition, which honoured the rule by 47 seconds.

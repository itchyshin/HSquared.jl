# Plan vs. actual — H² twin test campaign, wave 3

- Date: 2026-09-13
- Plan: `/Users/z3437171/shinichi-brain/projects/H2-twin/ultra-plan.md`
- Wave-3 addendum: `/Users/z3437171/shinichi-brain/projects/H2-twin/briefs/wave3-addendum.md`
- Wave: 3 of a possible 4 (stopping rule not fired: 4 new clusters, threshold is fewer
  than 3). Wave 4 is the final wave by rule (ii).
- Reconciler: Melissa. Read-only against the wave-3 addendum, the plan's stopping rule
  and envelope, my own wave-1 and wave-2 records, the six wave-3 lane receipts, the
  mechanical-verify receipt, Rose's wave-3 audit, live GitHub state measured in this
  session (`gh issue list`, `gh issue view --comments`, `gh label list`), a local-path
  grep on the four new issue bodies and the five newest comments, and
  `checkpoint.md`/`MISSION-CONTROL.md`/`memory/AGENT_LOG.md` for the handoff axis.
  Waves 1 and 2 were not re-audited, per the same convention my own wave-2 record used.

## Planned vs. actual, per lane

| Lane | Addendum focus | What ran | Receipt | Drafts → Rose verdict | Filed |
| --- | --- | --- | --- | --- | --- |
| L1 Simulator | (a) full independent-reconstruction parity for `multi_effect`/`random_regression` with genuine (non-degenerate) DGPs; (b) bivariate r_g=±0.95 through the R bridge at n=300, 20 seeds; (c) `initial`/`iterations` honoured-or-ignored on `two_effect`, `multi_effect`, `genomic`, `random_regression`, one call each | All three items ran as specified, plus the standing negative control inline. (a): both routes EXACT (0.000e+00) parity with real random-effect variance, retiring wave 2's `converged=FALSE`/implausible-`h2(t)` results as DGP artefacts, not defects. (b): 40/40 converged (20/20 each direction) through the R bridge, qualitatively consistent with wave 2's native-Julia grid. (c): `multi_effect` silently drops both `initial` and `iterations` (same mechanism as `#212`); `two_effect`/`genomic`/`random_regression` all honour theirs | `updates/2026-09-13-simulator-w3.md` | 1 comment draft (extends `#212`) → **MERGE** | comment on `hsquared#212` |
| L2 Data Fitter | `sommer::DT_cpdata` genomic route + sommer GBLUP reference; one AGHmatrix pedigree via `relmat()`; Mrode Ch.3 (3.1) and Ch.4 (sire model); re-attempt `nadiv::warcolak`/`pedigreemm::milk` under a 15-min cap, subsetting and saying so | DT_cpdata run raw (fails on `-1/0/1` coding) then recoded (converges); sommer GBLUP reference run, disagreed 2.8x, resolved by adding an unplanned third comparator (`AGHmatrix::Gmatrix`) which sided with `hsquared`, not `sommer` — the intended defect draft was written then deleted before filing once the correction surfaced. Mrode 3.1 animal model matched published EBVs to ~8 dp. The addendum's "Ch. 4 (sire model)" ask was met via Mrode Ch.3 **Example 3.2** (the textbook sire model, filed by the lane as "this wave's Ch. 4-shaped task"), tried through `relmat()` and reported unreachable. `warcolak` subsetted to n=650 (3-way agreement); `milk` subsetted to 120 and 400 cows (400 = 2.84x over the dense-cell cap, ran to completion, no guard). AGHmatrix's own example pedigree turned out to be the same pedigree as Mrode 3.1 and was not run separately | `updates/2026-09-13-fitter-w3.md` | 3 drafts (marker-coding, repeatability-cap, sire-model) → **2 KEEP + 1 DROP** (sire-model refuted: `animal(1 \| sire, pedigree=)` + `henderson_mme` reproduces Mrode 3.2 to every digit) | `hsquared#216` (genomic-marker-coding-undocumented), `hsquared#217` (repeatability-dense-cap-not-enforced); sire-model draft not posted |
| L3 Doc Reader | Execute the 10 not-yet-run R articles; cold-read remaining Julia Documenter pages; check cross-links both ways; file Julia-side findings only for new clusters; comment sibling vignette drift on `#208` | All 10 named articles executed chunk-by-chunk (21/21 R articles now run cumulative); 2 of 10 share `#208`'s placeholder-object defect (`genomic-prediction.Rmd`, `qtl-gwas-eqtl-status.Rmd`), correcting wave 2's own guess as "half right." 14 Julia Documenter pages cold-read, all cross-links resolve (source-file existence only, not live-URL fetch), one `@example` block spot-executed. Zero new Julia-side clusters found, none filed (per instruction) | `updates/2026-09-13-docreader-w3.md` | 1 comment draft → **MERGE** | comment on `hsquared#208` |
| L4 Mathematician (Opus) | Adjudicate FA (`V4-FA`), metafounder Γ, GWAS/LOCO, SNP-BLUP equivalence, repeatability; vary `#327`'s start value (3 starts × 20 seeds × Poisson, literal ask); run (not read) the Gamma/nbinom rails | Metafounder Γ, LOCO wiring, GBLUP↔SNP-BLUP ridge gap, repeatability decomposition, and evolvability functionals all checked and found correct/consistent (documented caveats noted, none filed). Found and filed a genuine internal contradiction: `ledermann_slack` and `_mv_nparams` disagree by `K(K−1)/2` on the FA free-parameter count, refusing/misreporting a cell the package's own gate calls valid. Start-value sweep exceeded the literal ask: ran 240 fits (2 designs × 2 DGPs × 3 starts × 20 seeds, not the addendum's 60), finding a 57% start-dependent swing at one null-DGP cell. `:gamma`/`:nbinom` rails run (not read): `:gamma` shares `#327`'s rail, `:nbinom` has none | `updates/2026-09-13-mathematician-w3.md` | 4 drafts (2 new issues, 2 comments) → **2 KEEP + 2 MERGE** | `HSquared.jl#331` (structured-lrt-df), `hsquared#218` (fa-uniqueness-wording); comments on `HSquared.jl#327`, `hsquared#201` |
| L5 Code Reviewer | Remaining `hs_control()` targets (`sparse_reml`, `henderson_mme`, `single_step`, `single_step_construct`, `metafounder_single_step`); `H^Γ` single-step variant of `metafounder_groups()`/`gamma_matrix()`; `lowrank`/`factor_analytic` `genetic_structure` live; ≤3 finishes | All named targets and the `H^Γ` variant run as live calls exactly as asked. All behave per `hs_control()`'s own documented contract; 0 stop findings. One rough edge: `single_step_construct`/`metafounder_single_step` surface a raw untranslated Julia `ArgumentError` at default `ridge=0` — same convention gap as `#214`, but with a working documented lever (`ridge`) that `#214`'s case lacked | `updates/2026-09-13-codereviewer-w3.md` | 1 comment draft → **MERGE**, L5's first draft to pass Rose's gate in three waves | comment on `hsquared#214` |
| L6 Speed | Fix the wave-2 row-indexed y-generator bug; re-run pedigreemm vs `HSquared.jl` on the corrected design at q=1k/5k, agreement first; add `sommer::mmer` at q=1k as a second reference | Generator fixed (animal-indexed, single source of data for both fitters via CSV export, no re-implementation in R); caught and fixed a second, unrelated CSV-writer bug (sire/dam indices written as if labels) before trusting any number. Agreement holds at both sizes (≤5e-7 relative difference, 3-way at q=1k including sommer). Cold/warm/peak-RSS timing table produced as asked. No defect surfaced; 0 drafts (third consecutive wave) | `updates/2026-09-13-speed-w3.md` | 0 | none |
| V1 mech-verify | Gate re-run: receipt structure, draft front-matter, worktree cleanliness, GitHub state, compute caps | 6/6 receipts with `## NOT COVERED`; all six carry real `compute_minutes` values this wave (10/22/20/4/11/9, summing to 76 — the "not set" misread wave 2 flagged does not recur); 10/10 new drafts structurally checked (repo/cluster/labels/twins/repro columns all PASS); 9/10 drafts carry at least one local path pre-sweep (expected — the sweep runs at posting time, not draft time); worktrees clean; issue check shows only the 15 pre-wave-3 issues before posting. The verifier's own schema has no column for the addendum's `kind:` requirement on comment drafts — see deviations | `updates/2026-09-13-mech-verify-w3.md` | — | — |
| V2 Rose | Claim-vs-evidence audit of the 10 drafts | Re-ran the load-bearing repro for every KEEP and MERGE (8 of 10; 2 verified from source without re-execution, both recorded as such). Corrected 5 drafts in place (a false "no R-facing route" claim, a wrong call-site enumeration, a reversed documentation citation, a misattributed source-comment line range, a not-quite-meaningful speed-sounding ratio). Refuted the sire-model DROP by running the public API herself. **KEEP 4 · MERGE 5 · DROP 1.** No lane trigger fired mechanically, but flagged L2 for a discretionary re-brief (DROP-KEEP-DROP pattern, not literally "two DROPs in a row") | `articles/2026-09-13-rose-audit-w3.md` | — | — |
| V3 Melissa | This reconciliation | This document | this file | — | — |

Cross-checked live: 4 new issues (`HSquared.jl#331`; `hsquared#216`, `#217`, `#218`,
createdAt all `2026-09-13T15:32:2[5-9]Z`) and 5 comments (on `HSquared.jl#327`,
`hsquared#212`, `#214`, `#208`, `#201`, all createdAt `2026-09-13T15:32:3[0-4]Z`) — 9
items, matching Rose's KEEP 4 + MERGE 5. Cumulative: 13 issues + 11 comments = **24**,
matching `checkpoint.md`'s own count and independently re-derived from `gh issue view
--json comments` on every named issue (`hsquared#201` 4 comments total, 1 pre-campaign
+ 3 campaign; `#208` 2; `#211` 1; `#212` 1; `#214` 1; `HSquared.jl#327` 2;
`HSquared.jl#53` 3 total, 2 pre-campaign + 1 campaign → 11 campaign comments; 13 new
issues since 2026-09-13 across both repos). `gh label list` on both repos still shows
no `test-campaign` label. `grep -c "/Users/z3437171\|shinichi-brain\|claude-503"` on
all 4 new issue bodies and the 5 newest comment bodies returned **0** in every case —
the posting-time local-path sweep held for 100% of this wave's posted items.

## Deviations

| Axis | Deviation | Tag | Owner | Evidence |
| --- | --- | --- | --- | --- |
| Scope | L1 read the addendum's "3 independent groups" for `multi_effect` as animal + 2 bare i.i.d. groups (3 blocks total, AGENT-INFERRED), not the stricter "3 groups besides animal" (4 blocks); the stricter reading was not run | ADAPTIVE | domain reviewer | `updates/2026-09-13-simulator-w3.md` "What ran" item 1 and "NOT COVERED" ("stricter '4 total blocks' reading... not run") |
| Scope | L2's ask to run one AGHmatrix example pedigree through `relmat()` was not executed as a separate dataset; `AGHmatrix::ped.mrode` turned out to be the same pedigree already covered via Mrode 3.1, so the lane used the textbook source instead of a duplicate run | ADAPTIVE | Ada | `updates/2026-09-13-fitter-w3.md` "What ran" ("AGHmatrix example pedigrees were not run as a separate dataset this wave...") |
| Scope | The addendum's "Mrode... Ch. 4 (sire model)" ask was fulfilled via Mrode (2014) **Ch. 3, Example 3.2** — no Ch. 4 content was run under that chapter number; the lane itself labelled this "this wave's Ch. 4-shaped task," so the substitution is disclosed, not silent | ADAPTIVE | domain reviewer | `updates/2026-09-13-fitter-w3.md` item 3 heading: "Mrode (2014) Ch. 3, Example 3.2 (the sire model, this wave's Ch. 4-shaped task)" |
| Scope | L2 added an unplanned third comparator (`AGHmatrix::Gmatrix`) beyond the addendum's ask, after the planned `sommer` GBLUP reference disagreed 2.8x with `hsquared`'s genomic route; this reversed the lane's own initial framing (a draft accusing `hsquared` of a defect was written, then deleted before filing once the third comparator sided with `hsquared`) | ADAPTIVE | domain reviewer | `updates/2026-09-13-fitter-w3.md` "Agreed" bullet 1 and "Issues" ("A fourth draft... was written and then deleted by me before filing") |
| Scope | L4's start-value sweep for `#327` ran 240 fits (2 designs × 2 DGPs × 3 starts × 20 seeds) against the addendum's literal 60-fit ask ("3 start values × 20 seeds × Poisson") | ADAPTIVE | Ada | `updates/2026-09-13-mathematician-w3.md` "What ran" bullet 4; `briefs/wave3-addendum.md` L4 focus line |
| Evidence / verification | The wave-3 addendum's own posting contract requires a comment draft to name its target issue in `kind:`; the mechanical verifier's drafts table checks repo/cluster/labels/twins/repro/`## Repro`/`Cluster:` but has no `kind:` column, and reports "All front-matter keys present" — yet Rose's manual read found `kind:` missing on 3 of 10 drafts (plus the dropped sire draft) and an H1 title missing on the same set plus a fourth | DRIFT | Ada | `updates/2026-09-13-mech-verify-w3.md` "Drafts table" (no `kind` column; "All front-matter keys present. All labels valid. Status: PASS"); `articles/2026-09-13-rose-audit-w3.md` "Posting order" § "Front-matter defects to fix before posting"; `briefs/wave3-addendum.md` "Unchanged rules" ("a comment draft names its target issue in `kind`") |
| Evidence / verification | `updates/2026-09-13-mech-verify-w3.md`'s receipts table lists `compute_minutes` per file (10/22/20/4/11/9) but has no summed total row; the campaign's "76 total minutes" figure appears in `checkpoint.md`/session framing, not as a value the mechanical tool itself computed or displayed | UNCLEAR | Ada | `updates/2026-09-13-mech-verify-w3.md` "Receipts table" (per-file values only, no Total row); independently re-summed this session: 10+22+20+4+11+9=76 |
| Evidence / verification | Rose applied five in-place corrections to KEEP/MERGE drafts before clearing them (a false "no R-facing route is affected" claim on `structured-lrt-df-1`; a wrong call-site enumeration and a reversed documentation citation on `repeatability-dense-cap-not-enforced-1`; a misclassified condition type and an unverifiable inline comparator on `genomic-marker-coding-undocumented-1`; a misattributed source-comment line range on `convergence-fence-3`) | ADAPTIVE | Rose | `articles/2026-09-13-rose-audit-w3.md` "Summary" ("Two KEEPs needed material corrections...") and the four "Correction applied in place" / "Two corrections applied" passages under the per-draft notes |
| Safety gates | The pre-authorised `test-campaign` GitHub label still does not exist on either repo, unchanged since wave 1; every wave-3 item continues to carry the `[test-campaign]` title-tag workaround | ADAPTIVE (recurring, unresolved) | Ada | `gh label list --repo itchyshin/hsquared \| grep -i test` and the `HSquared.jl` equivalent (both empty, this session) |
| Safety gates | The envelope's literal "two Rose DROPs of the same lane in a row" pause trigger did not fire for L2 (its sequence across three waves is DROP → KEEP → DROP), so no mechanical pause applies; Rose nonetheless judged this the same recurring failure mode as wave 1's trigger and recommended a discretionary re-brief outside any rule the envelope states | UNCLEAR | Ada | `articles/2026-09-13-rose-audit-w3.md` "Lane triggers" § L2 ("Not two in a row; the envelope's pause condition is not met... But... this lane has now made the same error twice... I recommend a re-brief") |
| Handoff state | `memory/AGENT_LOG.md`'s single 2026-09-13 H2-twin entry (mtime `08:55:36`) predates the wave-3 audit's completion (`articles/2026-09-13-rose-audit-w3.md` mtime `09:31:32`) and has not been extended with wave-3's outcome (Rose KEEP 4/MERGE 5/DROP 1, the 9 items filed, or the 24-item cumulative count) | DRIFT | Ada | `stat -f "%Sm %N"` on both files (this session); `memory/AGENT_LOG.md` 2026-09-13 entry text ends at "wave 3 launched (`wf_77fb4a27-c87`)... Records PR... in flight" |
| Handoff state | `MISSION-CONTROL.md`'s "Current" table is accurate and current for wave 3 (24 items, Rose 4/5/1), but its append-only "Log" section's last entry ("09:45 wave 3 lanes complete... Rose w3 running") still predates Rose's actual completion and the item-filing event — the same two-clocks pattern wave 2's own record flagged as an open, unresolved candidate | DRIFT | Ada | `MISSION-CONTROL.md` "## Log" (last line ends "Rose w3 running") vs "## Current — 13 September 2026, wave 3 closed" table above it |
| Handoff state | `checkpoint.md`'s top `STATE:` line is current and correctly gates wave 4 on this document's existence ("DO NOT launch wave 4 until Melissa w3's file exists"), but its `ARCS DONE` / `ARC IN PROGRESS` / `NEXT` subsections are unedited since the wave-2 write-up, generalizing the log-staleness pattern to a third durable-state file in the same session | DRIFT | Ada | `checkpoint.md` full text (this session): top line names wave 3 closure; `ARCS DONE`/`NEXT` sections still read "Wave 3 Workflow (six lanes...)... NEXT: (a)... (b) when wave 3 returns..." |

No deviation found on the **model routing** axis measurable this wave: the campaign
framing states 6 agents, sonnet ×5 + opus ×1 (mathematician), matching the plan's
"Sonnet by default, Opus for the Mathematician" exactly, and no receipt or verdict
contradicts it. Whether the mechanical verifier or Workflow dispatch used the
roster's specific named agent types is **UNMEASURED** again this wave — no
Workflow-JSON path was among this session's inputs, the same gap wave 2 could not
close either (wave 1's recurring candidates 1 and 4 remain open questions, not
re-confirmed or ruled out).

No deviation found on the **public claims** axis: Rose's own grep of all ten drafts
for `asreml|faster|slower|speed|wall.clock|wall time|benchmark|performance|throughput`
found six hits, all benign (repro wall-time disclosures, one filename, and two
mechanism-not-speed uses), with one genuine near-miss tightened in place (a
"~40x slower than the guard's own fast-fail" comparison, replaced with a plain wall-time
statement) before it could read as a performance claim. The speed receipt carries one
explicit `AGENT-INFERRED` heading and files zero drafts for the third consecutive wave,
so its vault-only ASReml opinion cannot reach either tracker. No `capability-status.md`
or `validation-debt-register.md` row moved; both worktrees measured clean at their
pinned SHAs before and after every script this session.

## Verdict

Wave 3 delivered materially what the addendum asked, and slightly more: L1 retired two
of wave 2's open DGP-artefact questions with exact parity under genuine random-effect
variance and closed its own predicted `multi_effect` extension of `#212`; L2 closed the
loop on `warcolak`'s dense-cap finding with a clean 3-way agreement at validation scale,
caught its own near-miss defect claim on the genomic route before filing it, and
produced this wave's one DROP when its sire-model draft's universal "unreachable" claim
was refuted by Rose running the public formula interface herself; L3 finished all 21 R
articles and the full Julia Documenter cold read with zero new Julia-side findings; L4
was again the strongest lane, finding a genuine internal contradiction between
`ledermann_slack` and `_mv_nparams` that needs no external citation, and retiring an
AGENT-INFERRED flag on the Gamma/nbinom rails by running rather than reading them; L5
passed Rose's gate for the first time in three waves; L6 fixed both its own wave-2
generator bug and a self-caught CSV-writer bug, then delivered a genuine three-fitter
agreement result with no defect to file. Rose's audit produced KEEP 4/MERGE 5/DROP 1,
adding exactly 4 new clusters (above the stopping-rule floor of 3, so wave 4 — the
final wave by rule (ii) — remains open), and this reconciliation independently
re-derived her 9-item, 24-cumulative count from live GitHub state and confirmed the
posting-time local-path sweep held on all 9 items with zero exceptions, a full recovery
from wave 2's partial (2-of-7) compliance. Against that, three classes of durable-state
staleness recurred (`AGENT_LOG.md`, `MISSION-CONTROL.md`'s Log section, and now
`checkpoint.md`'s own secondary sections), the `test-campaign` label remains
uncreated, and the mechanical verifier's front-matter schema does not check the
addendum's own `kind:` requirement — a gap Rose's manual read, not the mechanical gate,
is what caught it. None of this reaches a MUST STOP: no tracked file in either
worktree was touched, no capability, version, or release claim moved, no speed or
ASReml wording reached either tracker, and — the one item this wave specifically asked
after — the between-wave sequencing gate that fired as a drift entering wave 3 is now
being honoured going into wave 4: `checkpoint.md` explicitly withholds the wave-4
launch pending this document.

## Recurring-class candidates

1. **Posting hygiene (wave-2 candidate 5) — FIXED.** Wave 2 found the sweep applied to
   only 2 of 7 posted items. This wave, the sweep was applied before posting (per
   `checkpoint.md`'s own note) and this reconciliation independently confirmed **zero**
   local-path hits across all 4 new issue bodies and all 5 newest comments — full
   compliance, not partial.
2. **Between-wave gate (wave-2 candidate 7) — recurred once more (already recorded),
   now shows a fix taking hold.** Wave 3 was launched before wave 2's Melissa finished
   (this was wave 2's own drift finding, not new here). For the wave-3→wave-4
   transition specifically, the gate is now explicit and honoured:
   `checkpoint.md`'s top line states "DO NOT launch wave 4 until Melissa w3's file
   exists," and the known facts for this session confirm the orchestrator is waiting.
   Whether this holds is only confirmable at the next transition.
3. **Mid-campaign `AGENT_LOG.md` staleness (wave-1 candidate 3) — RECURRED a third
   time.** The single 2026-09-13 entry still ends at "wave 3 launched... records PR...
   in flight," with no wave-3 outcome folded in, exactly as waves 1 and 2 both
   predicted and observed. This has now recurred in every wave of the campaign and has
   generalized: `MISSION-CONTROL.md`'s Log section and `checkpoint.md`'s secondary
   sections show the identical two-clocks pattern this wave (see deviations table).
4. **Compute-minutes bookkeeping (wave-2 candidate 6) — FIXED for the field it named,
   with an adjacent gap surfacing in the same class.** Wave 2's specific complaint (the
   verifier reports "(not set)" for a `compute_minutes` field that is actually present)
   does not recur: all six wave-3 receipts carry the field and the verifier reads all
   six correctly, summing to the stated 76. But the same general risk — a mechanical
   schema check silently omitting a field the addendum requires — reappeared in a new
   place this wave: the verifier's drafts table has no `kind:` column, and Rose's
   manual read is what caught 3-4 drafts missing it.

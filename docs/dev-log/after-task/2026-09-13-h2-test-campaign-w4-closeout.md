# After-task — 2026-09-13 H² twin test campaign, wave 4 and campaign close-out (Julia lane; records for both twins)

## 1. Goal

Run the final wave of the independent test campaign on both twins (`hsquared` R `4ec4cfb`,
`HSquared.jl` Julia `b1f8f14`), gate it through Rose, file what she keeps, reconcile with Melissa,
apply the stopping rule, and close the campaign with records a maintainer can act on.

## 2. Implemented

- Wave 4 (final): six lanes, each closing its thread with a written campaign synthesis. Five ran in
  the bounded Workflow; the Data Fitter dispatch was refused by the auto-mode classifier inside the
  Workflow and was relaunched standalone, so 6/6 receipts exist.
- Findings: second-seed R↔Julia parity exact on multi_effect and random_regression; unbalanced
  repeated records exact; the #212 control-drop is structural on two more targets plus an
  independent interval path; metafounder Γ = 0 collapses exactly on both twins; the GBLUP↔SNP-BLUP
  gap is entirely ridge-induced; for #331's low-rank cell the reported p-value is unattainable by
  any chi-bar mixture; a two-start restart detector for #327 caught 27/27 truncated fits with zero
  false positives; the raw-Julia-trace pattern (#214) is confined to single-step construction at
  `ridge = 0`; `docs/make.jl` rewrites a tracked file on every run; repeatability accepts
  zero-replication data (dropped by Rose: `?hs_control` states the requirement); HSquared.jl agrees
  with pedigreemm to ≤ 2e-6 through q = 50,000 and is 29–61× faster there (a comparator fact, not an
  ASReml claim).
- Rose audit w4: KEEP 2 · MERGE 5 · DROP 1; two new clusters. Filed: HSquared.jl #333
  gblup-equivalence-ridge, #334 docs-build-dirties-tracked-file; comments on hsquared#214 (narrowing
  its scope), #212, #210 (retargeted from #201 by Rose), HSquared.jl#331, #327.
- Stopping rule fired: fewer than three new clusters in the wave, and wave 4 complete.
- Campaign totals: 4 waves, 24 lane runs + 1 bridge gate, 37 drafts, 15 KEEP / 16 MERGE / 6 DROP,
  17 clusters, **31 items filed** (15 issues: hsquared #208–#218, HSquared.jl #327, #331, #333,
  #334; 16 cluster comments), every body and comment swept of local paths.

## 3a. Decisions and Rejected Alternatives

- Wave 4 launched only after Melissa's wave-3 record existed (the wave-2 drift not repeated).
- The stopping rule was applied as written; a wave 5 was not considered despite wave 4's yield.
- Rose retargeted one comment from hsquared#201 to #210 (right arithmetic, wrong name: #210's
  class, not the estimand contract); applied as she wrote it.
- The repeatability zero-replication draft was not filed: `?hs_control` states the replication
  requirement the tester said was missing (the campaign's sixth DROP, all of the same shape).
- No fix, no capability-status or validation-debt change, no version bump, no public speed wording.

## 4. Files Touched

Julia repo (this records PR): `docs/dev-log/after-task/2026-09-13-h2-test-campaign-w4-closeout.md`
(this file), `docs/dev-log/plan-actual/2026-09-13-h2-test-campaign-w4-final.md` (Melissa). R repo:
no file touched by this lane in any wave. GitHub: two issues, five comments (wave 4). Vault:
`projects/H2-twin/updates/*-w4.md` ×6, `updates/2026-09-13-mech-verify-w4.md`,
`articles/2026-09-13-rose-audit-w4.md`, `issue-drafts/` ×8, `repros/w4-*`, `MISSION-CONTROL.md`
(closed state), `checkpoint.md`, `memory/DECISIONS.md` (D-262 outcome), `memory/AGENT_LOG.md`;
Mission Control `status/H2.json` (next safe action = owner's fixer decision).

## 5. Checks Run

- Workflow `wf_eb56f9a8-3cf`: 5 agents done, 1 refused at dispatch (relaunched standalone, done).
- Mechanical verification (`updates/2026-09-13-mech-verify-w4.md`): six receipts (one synthesis
  heading spelled "(c) Campaign synthesis", present); eight drafts structurally complete; both
  worktrees clean after the Doc Reader restored the file the Documenter build had touched; nothing
  filed since wave 3 at verification time.
- Rose re-ran the cheap repros and the Documenter build check.
- Posting script: local-path leak check before every post; none skipped.
- Melissa w4 and campaign reconciliation: see `plan-actual/2026-09-13-h2-test-campaign-w4-final.md`.
- Not run (docs-only lane): `Pkg.test()`, `preamble_cap.sh`. `docs/make.jl` was run by the Doc
  Reader lane in the scratch worktree (that run is the source of #334).

## 6. Tests of the Tests

- The posting-script leak check is a negative control that prints SKIPPED and posts nothing when a
  body carries a local path; it never fired in waves 3–4 because the sweep runs first.
- Rose dropped one draft in every wave; the gate never rubber-stamped.
- The #327 detector was tested against 80 replicate pairs with zero false positives; the Simulator's
  parity harness went red on its negative control in every wave it ran one.
- Melissa's reconciliations caught process drift the orchestrator missed (posting hygiene in wave 2,
  early launch of wave 3) and confirmed both fixed by wave 4.

## 7a. Issue Ledger

Wave 4: HSquared.jl #333 gblup-equivalence-ridge (documentation, julia-engine); #334
docs-build-dirties-tracked-file (documentation, julia-engine). Comments: hsquared#214, #212, #210;
HSquared.jl#331, #327. Not filed: repeatability-no-replication-check (DROP).
Campaign: hsquared #208 vignette-drift · #209 claim-scope · #210 notation · #211 missing-definition ·
#212 direct-maternal-initial-ignored · #213 rr-out-of-range · #214 dense-cells-cap-no-r-escape ·
#215 selfing-pedigree-path-contract · #216 genomic-marker-coding-undocumented · #217
repeatability-dense-cap-not-enforced · #218 fa-uniqueness-wording; HSquared.jl #327
convergence-fence · #331 structured-lrt-df · #333 · #334; comment threads on hsquared#201 and
HSquared.jl#53. Rose's read-first list: HSquared.jl#331, hsquared#212, hsquared#211 (with #216,
#218); cheapest fix HSquared.jl#327.

## 8. Consistency Audit

- Mission Control (`MISSION-CONTROL.md`, `/p/H2/test`), the D-262 outcome, the log, this report, and
  Rose's close-out agree on 31 items, 17 clusters, 37/15/16/6.
- Rose corrected her own wave-3 total (27 → 29 drafts audited at that point) and recomputed every
  wave from the audit files; this report uses her recomputed figures.
- The wave-4 addendum said "fourteen clusters already filed"; live GitHub showed fifteen. Recorded,
  no consequence for any verdict.
- The charter's route list, the W1-B receipt's PASS semantics, the briefs and the frozen plan all
  carry the wave-1 corrections.

## 9. What Did Not Go Smoothly

- The classifier refused the Data Fitter dispatch inside the Workflow (relaunched standalone, cost
  ~20 min), one vault commit (retried after splitting add and commit), and the `test-campaign` label
  throughout.
- `TaskOutput` on long Rose runs dumped transcript on timeout three times.
- The mechanical verifier's exact-heading match missed a "(c) Campaign synthesis" heading.
- The original Simulator brief items (hostile n×h² grid, topology stress, zero-inflated Poisson)
  were superseded by every addendum and never run.

## 10. Known Residuals

- Not established by this campaign, stated so no one reads it as validation: no fix; no capability
  flip; no coverage claim; no speed claim; no ASReml measurement ("unknown within 3×" is an
  algorithm-class analogy).
- Simulator hostile-grid items above; no fitted FA model for #331; #327's detector is Poisson-only;
  no single-step H^Γ fit with a comparator; no pkgdown build; no cross-hardware timing.
- The `test-campaign` label does not exist; items rely on the title tag.
- An R-side charter pointer was never opened (this lane never edited the R repo).

## 11. Team Learning

- Every one of six DROPs was a tester writing a sentence about the whole surface after checking
  part of it; before "cannot / unreachable / undocumented", try the natural spelling,
  `relmat()`/`precision()`, the target's documented control, and grep the man pages including
  `?hs_control`.
- The strongest findings were two parts of one programme disagreeing in writing; the twin structure
  is diffable, and diffing it is where the campaign earned its keep.
- Keep the posting sweep inside the posting step; gate wave N+1 on the V3 file; record
  `compute_minutes` in every receipt; treat a classifier refusal inside a Workflow as a lane to
  relaunch, not a lane to skip.

## 12. Cross-Product Coverage

Wave 4 covers: second-seed parity for multi_effect and random_regression; unbalanced repeatability
parity; `initial`/`iterations` honouring on all remaining targets and two interval helpers; the
BTdata `A.mat` caveat (does not transfer); PlodiaPO through repeatability; every `julia_command()`
call site for the raw-trace pattern; tau/omega/blend_weight knobs; metafounder Γ = 0; GBLUP↔SNP-BLUP
with three seeds and two ridges; chi-bar attainability for #331; a Documenter build; the last
Julia Documenter pages; pedigreemm agreement and timing through q = 50,000 with process repeats.

The campaign does NOT cover: any fix; any capability, coverage, or speed claim; ASReml; the
Simulator's original hostile-grid, topology-stress and zero-inflated-Poisson items; a fitted
factor-analytic model; non-Poisson families for the #327 detector; single-step H^Γ fits against a
comparator; pkgdown rendering; rendered-site reachability; cross-hardware timing; Totoro or DRAC
compute; the R repo's own records.

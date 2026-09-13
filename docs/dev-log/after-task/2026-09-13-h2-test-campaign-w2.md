# After-task — 2026-09-13 H² twin test campaign, wave 2 (Julia lane; records for both twins)

## 1. Goal

Run wave 2 of the independent test campaign on both twins (`hsquared` R `4ec4cfb`, `HSquared.jl`
Julia `b1f8f14`) from the wave-2 addendum, gate every finding through Rose, file what she keeps, and
decide the stopping rule.

## 2. Implemented

- Six lanes in one bounded Workflow (5 live; Sonnet ×5, Opus ×1): six receipts, eight drafts.
- Simulator (re-briefed after two wave-1 DROPs): R↔Julia parity exact on common_env, genomic and
  direct_maternal once starting values match; the apparent direct_maternal mismatch traced to a real
  contract bug (`engine_control$initial`/`$iterations` silently ignored for that target); bivariate
  r_g = ±0.95 converges 20/20 at n = 300; negative control confirmed the parity check is sensitive.
- Data Fitter: gryphon through the public `relmat()` route matches Wilson et al. 2010 to four
  decimals; BTdata bivariate agrees with an independent `sommer` fit within ~0.5 %; a routine
  5,400-animal dataset hits the dense-cells cap with a raw Julia trace and no R lever.
- Doc Reader: four more articles share the never-defined-placeholder drift; three-way covered-count
  mismatch measured (dropped by Rose as already visible in `current-limits.Rmd`).
- Mathematician (Opus): #327 characterised (240/240 `converged = true`, 73 on the bracket bound;
  Gaussian AI-REML path honest); R clamps the random-regression Legendre basis where Julia throws.
- Code Reviewer: no `relmat`/`precision` blind spot in the wave-1 survey; three previously untested
  live paths ship honestly; zero stop findings.
- Speed: no valid two-sided comparator at 1k/5k (pedigreemm cannot fit the saturated design;
  MixedModels.jl has no pedigree API); a replicated-design disagreement traced to the lane's own
  generator, so no timing reported; "unknown within 3×" stands, AGENT-INFERRED, vault-only.
- Rose audit: KEEP 4 · MERGE 3 · DROP 1; four new clusters. Filed: hsquared #212, #213, #214, #215;
  comments on HSquared.jl#327, hsquared#208, hsquared#211. Fifteen items cumulative.
- Mission Control gained an H² Test surface at `/p/H2/test` mirroring the DRM Test surface
  (vault commit `32b03f10`; reads `projects/H2-twin/` and live GitHub).

## 3a. Decisions and Rejected Alternatives

- Stopping rule evaluated and not fired (4 new clusters ≥ 3; 15 of 60 items; wave 2 of 4) → wave 3
  launched with `briefs/wave3-addendum.md`. Rejected: stopping early on the grounds that wave 2's
  numerical findings were fewer than wave 1's (the rule is written on clusters, not on severity).
- Covered-count-drift draft not filed (Rose: already disclosed by the R twin's own limits article).
- Rose's posting-hygiene instruction (basename instead of vault-absolute repro path; drop scratchpad
  paths) was applied to only two of seven items at posting time; the remaining bodies and the six
  campaign comments were rewritten in place afterwards (see §9).

## 4. Files Touched

Julia repo (this records PR): `docs/dev-log/after-task/2026-09-13-h2-test-campaign-w2.md` (this file),
`docs/dev-log/plan-actual/2026-09-13-h2-test-campaign-w2.md` (Melissa). R repo: no file touched.
GitHub: four issues, three comments, and in-place edits of filed bodies/comments to remove local paths.
Vault: `projects/H2-twin/updates/*-w2.md` ×6, `updates/2026-09-13-mech-verify-w2.md`,
`articles/2026-09-13-rose-audit-w2.md`, `issue-drafts/` ×8, `repros/w2-*`, `briefs/wave3-addendum.md`,
`MISSION-CONTROL.md`, `checkpoint.md`, `memory/AGENT_LOG.md`; Mission Control server
`Shinichi/Dashboards/mission-control/live/{h2_test_surface.py,serve_multi.py,status/H2.json}`.

## 5. Checks Run

- Workflow `wf_49fb2954-60a`: 6 agents, 6 receipts, 0 errors, 1.14 M tokens, 31 min wall.
- Mechanical verification (`updates/2026-09-13-mech-verify-w2.md`): six receipts each ending NOT
  COVERED; eight drafts structurally complete; both scratch worktrees zero tracked changes; no issue
  filed before the audit.
- Rose audit re-ran every cheap repro; the dense-cells guard verified from the code path.
- Mission Control: 38/38 unit tests pass after the new module; `/p/H2/test` and `/p/drmTMB/test`
  both answer 200 with their own titles after a launcher restart.
- Not run (docs-only lane): `Pkg.test()`, `docs/make.jl`, `preamble_cap.sh`.

## 6. Tests of the Tests

- The Simulator's negative control (one perturbed DGP constant) turned parity red as required.
- The Speed lane refused to report a timing for a cell that disagreed numerically and traced the
  disagreement to its own generator: agreement-first held under pressure to produce a number.
- Rose dropped one draft and merged three; the gate is not rubber-stamping.
- Melissa's reconciliation caught two process failures the orchestrator had not: partial application
  of the posting-hygiene instruction, and wave 3 launched before V3 finished.

## 7a. Issue Ledger

Filed 2026-09-13 (wave 2): hsquared #212 direct-maternal-initial-ignored (bug, bridge); #213
rr-out-of-range (bug, bridge, r-package); #214 dense-cells-cap-no-r-escape (bug, documentation,
r-package, bridge); #215 selfing-pedigree-path-contract (pedigree, bridge). Comments: HSquared.jl#327
(boundary-ride characterisation), hsquared#208 (four sibling articles), hsquared#211 (r_g SE without
an interval definition). Not filed: covered-count-drift (DROP). Cumulative campaign items: 15.

## 8. Consistency Audit

- Every wave-2 draft names its twin(s) and a repro; filed bodies and comments were swept for local
  paths after Melissa's finding and rewritten where needed.
- Mission Control's Current table, Log, and the `/p/H2/test` NOW strip agree on the counts (15 items,
  four new clusters, stopping rule not fired).
- The wave-3 addendum carries every filed cluster so no lane re-files a class.
- `memory/AGENT_LOG.md` was stale for wave 2 (as wave 1's record predicted) and has been extended.

## 9. What Did Not Go Smoothly

- Posting hygiene: Rose's instruction to replace vault-absolute repro paths and drop scratchpad paths
  was applied to two of seven items at posting time; fixed in place afterwards with `gh issue edit`
  and comment PATCHes; the wave-3 posting step now runs the path sweep before every post.
- Sequencing: wave 3 was launched while Melissa's wave-2 reconciliation was still running, against
  the written "V1–V3 green before N+1" gate. Reversible (wave 3 lanes cannot post), but drift. Wave 4
  waits for V3.
- The mechanical verifier reported `compute_minutes` absent where two receipts carried it; four lanes
  did not record it at all. The wave-3 receipt contract names it as required.
- The Speed lane's replicated design was not identifiable (y generated by row, not by animal); the
  fix is diagnosed and is wave 3's first item for that lane.
- The `test-campaign` label still cannot be created from this session.

## 10. Known Residuals

- Melissa w2: 4 ADAPTIVE / 4 DRIFT / 3 UNCLEAR (`plan-actual/2026-09-13-h2-test-campaign-w2.md`).
- Simulator parity covered three of five named routes fully; multi_effect and random_regression only
  by liveness with degenerate DGPs (wave 3 item).
- Data Fitter: warcolak and milk fits killed at 20 min unresolved; DT_cpdata, AGHmatrix, Mrode tables
  not attempted (wave 3 items).
- Doc Reader: 10 of 21 R articles and 14 of 15 Julia Documenter pages not yet executed or cold-read.
- Mathematician: FA, metafounder, GWAS/LOCO, SNP-BLUP, repeatability estimands not adjudicated;
  Gamma/nbinom rails read only.
- No comparator timing at q ≥ 1k exists on a valid design; the ASReml opinion is unchanged and
  must not be quoted as evidence of parity.

## 11. Team Learning

- Run the local-path sweep as a mechanical step before every post; an auditor's written posting
  instruction is a gate, not advice.
- The between-wave gate must be mechanical: do not launch wave N+1 until the V3 file exists.
- Record `compute_minutes` in every receipt's front-matter; the cap is unenforceable otherwise.
- A parity mismatch that appears before starting values are matched is a control-contract finding,
  not a marshalling defect; check the control path first.

## 12. Cross-Product Coverage

Wave 2 covers: R↔Julia parity on common_env, genomic and direct_maternal at validation scale;
bivariate r_g = ±0.95 convergence natively in Julia; gryphon via public `relmat()`; BTdata bivariate
with a sommer reference; four more R articles executed cold; the wave-1 96-export survey re-checked
for the `relmat`/`precision` blind spot; three previously untested export live paths; #327
characterised across two designs and three families; random-regression out-of-range behaviour on the
public path.

Wave 2 does NOT cover: multi_effect and random_regression parity with real random-effect variance;
the r_g grid through the R bridge; DT_cpdata, AGHmatrix and Mrode datasets; warcolak and milk to
completion; the remaining 10 R articles and 14 Julia Documenter pages; FA, metafounder, GWAS/LOCO,
SNP-BLUP and repeatability estimands; the remaining `hs_control()` targets (sparse_reml, henderson_mme,
single_step, single_step_construct, metafounder_single_step) and lowrank/factor_analytic as live
calls; Gamma, nbinom, ordinal and variational paths for the convergence defect; any valid comparator
timing at q ≥ 1k; any GPU, Totoro or DRAC compute; the R repo's own records; and any fix.

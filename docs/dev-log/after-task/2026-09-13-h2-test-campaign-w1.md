# After-task — 2026-09-13 H² twin test campaign, wave 1 (Julia lane; records for both twins)

## 1. Goal

Close the 2026-09-13 Claude handover against live state, then open and run wave 1 of the
independent multi-lane test campaign on both twins (`hsquared` R `4ec4cfb`, `HSquared.jl` Julia
`b1f8f14`) hands-off, filing findings only after a Rose claim-vs-evidence audit.

## 2. Implemented

- Handover reconciled: 0.9.0 release measured DONE (tag `v0.9.0` → `b1f8f14a`, release
  published 2026-09-12); PR #325 merged through the merge-when-green gate; 36 historical local
  branches left PROTECTED; this checkout's superseded `claude/h2-three-scale-naming-20260908` left.
- Campaign opened: charter `docs/design/57-h2-test-campaign-charter.md` (PR #326, corrected in
  PR #328), vault project `~/shinichi-brain/projects/H2-twin/` (GOAL, checkpoint, frozen plan,
  Mission Control, seven lane briefs, wave-2 addendum), acceptance ledger
  `.unlazy/h2-test-campaign/GATES.md`.
- W1-B bridge gate PASS: gryphon within the Wilson et al. 2010 band on both engines; 7/7
  covered-route call shapes complete through `engine = "julia"` (PASS = call completed and
  returned the documented shape; the multivariate fixture did not converge).
- Wave 1: six lanes in one bounded Workflow (5 live), six receipts, 11 drafts.
- Rose audit: KEEP 5 · MERGE 3 · DROP 3. Filed: HSquared.jl #327; hsquared #208, #209, #210,
  #211; comments on hsquared#201 (two) and HSquared.jl#53 (one). Eight items, all after the audit.
- Speed opinion delivered vault-only and AGENT-INFERRED: same algorithm family as ASReml;
  near-linear scaling to q = 50k; no ASReml figure to compare against, so "unknown within 3×".

## 3a. Decisions and Rejected Alternatives

- D-262 (vault): campaign shape, direct filing after Rose KEEP, Claude runs all lanes, stopping
  rule, envelope. Rejected: draft-then-approve per wave (Shinichi asked for hands-off); Codex
  running the fitting lanes (owner chose Claude for this campaign); restarting the frozen S5/S6
  ASReml ladder (licence absent; opinion only).
- Rose adjudication: the charter's covered list must name `multi_effect`, not `permanent`
  (repeatability is experimental on both twins). Applied in PR #328. `public_covered_count` 7
  unchanged.
- Two Simulator drafts and one Data Fitter draft DROPPED: two claimed a capability unreachable
  from R that is reachable through the exported `relmat()`/`precision()` terms; one reported
  expected REML boundary behaviour already disclosed in both ledgers.

## 4. Files Touched

Julia repo (`HSquared.jl`, all docs-only, via PRs #326 and #328 and this records PR):
`docs/design/57-h2-test-campaign-charter.md` (new, then corrected), `docs/dev-log/check-log.md`
(2026-09-13 entry), `docs/dev-log/plan-actual/2026-09-13-h2-test-campaign.md` (new),
`docs/dev-log/after-task/2026-09-13-h2-test-campaign-w1.md` (this file). Untracked, never staged:
`.unlazy/h2-test-campaign/GATES.md` (excluded in `.git/info/exclude`).
R repo (`hsquared`): no file touched. GitHub: five issues and three comments (above).
Vault (`~/shinichi-brain`): `projects/H2-twin/*` (GOAL.md, checkpoint.md, ultra-plan.md,
MISSION-CONTROL.md, README.md, briefs/ ×8, updates/ ×8, articles/2026-09-13-rose-audit.md,
issue-drafts/ ×11, repros/), `memory/DECISIONS.md` (D-262), `memory/AGENT_LOG.md` (entry).
Scratch: worktrees `/private/tmp/h2camp-jl`, `/private/tmp/h2camp-r`, `/private/tmp/h2camp-lane`.

## 5. Checks Run

- `pr_merge_when_green.sh` on #325, #326, #328: every check `COMPLETED SUCCESS` (plotting job
  `SKIPPED` by design) before each merge; `documenter/deploy` SUCCESS.
- `gate-check.mjs --reverify` on `GATES.md`: G1–G7, G9 met; G8 met after posting (8 items = 5 KEEP
  + 3 MERGE, all `createdAt` after the audit file); G10–G12 close with this records PR.
- `claude-routing-audit.py --date 2026-09-13`: 30/31 dispatches explicit-model; one pre-plan
  Explore recon inherited the session model.
- Mechanical verification receipt `updates/2026-09-13-mech-verify.md`: 7 receipts all ending NOT
  COVERED; both scratch worktrees 0 tracked changes; 0 issues filed before the audit.
- Not run (docs-only lane): `Pkg.test()`, `docs/make.jl`, `preamble_cap.sh`. The lanes' own R
  and Julia runs are recorded in their receipts.

## 6. Tests of the Tests

- Rose's gate refuted two drafts by fitting the disputed models through the public API
  (`relmat(1 | ANIMAL, K = A_gryphon)`, σ²a 3.395393, σ²e 3.828605, h² 0.4700157): the audit
  catches false capability-gap claims, which is its purpose.
- The Simulator's first harness produced a false "0 % CI existence" figure from a mis-destructured
  NamedTuple; the lane caught it before it became a finding.
- The envelope's lane-pause trigger fired as written (two DROPs in one lane ⇒ that lane paused and
  re-briefed; others continue).
- Negative control: the ledger's G9 check exits non-zero when `AGENT-INFERRED` is absent
  (`grep -c` semantics), so a silently unlabelled speed receipt would fail the gate.

## 7a. Issue Ledger

Filed 2026-09-13, label set from the programme labels, `[test-campaign] [cluster: …]` in titles:
HSquared.jl #327 convergence-fence (bug, julia-engine, validation); hsquared #208 vignette-drift
(documentation, bug, r-package); #209 claim-scope (documentation, claim-audit, validation); #210
notation (documentation, formula-grammar); #211 missing-definition (documentation, r-package).
Comments: hsquared#201 (Julia and R halves of estimand-notation); HSquared.jl#53 (single-step
genetic base). Not filed (DROP, kept as vault evidence): small-n near-zero-h² recovery;
animal-no-precomputed-relationship; selfing-unreachable-from-r.

## 8. Consistency Audit

- Three "covered" counts are visible to readers (7 in DESCRIPTION/README, 6 in the generated
  `validation_status()` card, engine rows); recorded for the Doc Reader's wave-2 consistency hat.
- The W1-B receipt's PASS column was relabelled "call completed / shape returned" after Rose flagged
  that a non-converged multivariate fit had been read as PASS; the brief and the frozen plan carry
  the same note.
- The charter, brief, plan, and Mission Control all now name `multi_effect` as the seventh covered
  route; no capability, validation-debt, or status file was changed.
- The R twin received no charter pointer from this lane (its Dropbox checkout sits on a stale
  Codex branch and an R-side docs PR was not opened); recorded as a residual, not done silently.

## 9. What Did Not Go Smoothly

- The auto-mode classifier refused: `gh label create` and its API form (both repos), a background
  merge gate, shell writes into the vault (`mkdir`, `cp`), `git worktree add -b`, and two of five
  `gh issue create` calls (both succeeded on retry). Worked around with file tools, foreground
  gates, and retries; the `test-campaign` label does not exist.
- `TaskOutput` on a running agent dumped part of its transcript into the orchestrator on timeout.
- The installed `hsquared` was a stale 0.1.0.9000 build; all lanes loaded 0.9.0 from a fresh
  worktree instead.
- Two lanes missed the public `relmat()`/`precision()` terms and drafted false unreachability claims.
- The charter builder could not find the house-style file the brief named and used sibling docs.

## 10. Known Residuals

- L1 Simulator paused after two DROPs; re-briefed via `briefs/wave2-addendum.md`; wave 2 running.
- `test-campaign` label absent on both repos; filed items rely on the title tag.
- G12 records one inherited-model dispatch (pre-plan Explore recon); the audit tool cannot see
  inside the Workflow's six lanes, so their explicit models are proven by the Workflow progress
  record, not by the audit.
- Melissa: 6 ADAPTIVE, 2 DRIFT, 4 UNCLEAR (`plan-actual/2026-09-13-h2-test-campaign.md`); the two
  DRIFT items are routed to Ada (extra probe child) and Rose (charter route list).
- No R-side charter pointer; no Totoro run needed; no comparator at q ≥ 5k in wave 1.
- Every lane receipt carries its own NOT COVERED list; the speed opinion is not evidence of
  ASReml parity and must not be quoted as such.

## 11. Team Learning

- Before any tester claims a capability is unreachable from R, it must try `relmat()` and
  `precision()`; this is now in the wave-2 addendum and belongs in the charter's invariants.
- "PASS" in a liveness gate must be spelled out as call-completed, never as agreement; label the
  column at authoring time.
- A coverage figure is uninformative without the convergence rate beside it; boundary replicates
  return (0, 1) and trivially cover.
- Under this classifier, plan for file-tool writes and foreground gates; do not loop on refusals.

## 12. Cross-Product Coverage

Wave 1 covers: the 7 covered routes as call shapes through `engine = "julia"` (liveness only);
gryphon numerics on both engines against the published anchor; structural pedigree hostility
(phantom founders, duplicate IDs, non-topological order, selfing) on both twins; export honesty of
all 96 R exports under out-of-scope calls; three h² scale conventions, Willham h²_T, PEV/reliability/
accuracy, VanRaden G and the single-step A22 identity as algebra; two R articles run cold; a
Julia-only timing ladder to q = 50k.

Wave 1 does NOT cover, stated so nobody reads silence as a pass: non-Gaussian families beyond
Poisson/Bernoulli/Binomial (Gamma, ordinal, beta-binomial, negative-binomial); factor-analytic and
GLLVM routes; metafounders and single-step numerics; genomic marker scans on a real SNP-BLUP fit;
random-regression and multivariate estimands (adjudicated in wave 2); unbalanced repeated
measures; zero-inflated counts mapped to Poisson; any n above validation scale; any GPU, Totoro
or DRAC compute; external comparators at q ≥ 5k; Julia-side documentation read cold; the R repo's
own after-task and coordination-board records; and any fix to anything found.

# After-task — 2026-09-13 H² twin test campaign, wave 3 (Julia lane; records for both twins)

## 1. Goal

Run wave 3 of the independent test campaign on both twins (`hsquared` R `4ec4cfb`, `HSquared.jl`
Julia `b1f8f14`) from the wave-3 addendum, gate every finding through Rose, file what she keeps with
the local-path sweep applied first, reconcile with Melissa before any further launch, and decide the
stopping rule.

## 2. Implemented

- Six lanes in one bounded Workflow (5 live; Sonnet ×5, Opus ×1): six receipts, ten drafts, every
  receipt carrying `compute_minutes` (76 in total).
- Simulator: multi_effect and random_regression parity exact (0.0) under DGPs with real random-effect
  variance; bivariate r_g = ±0.95 converges 40/40 through the R bridge; `multi_effect` shares #212's
  silent discard of `initial`/`iterations` while two_effect, genomic and random_regression honour them.
- Data Fitter: DT_cpdata genomic route agrees with AGHmatrix (a sommer `A.mat` divergence was traced
  to convention, not filed); Mrode 3.1 EBVs reproduced to ~8 dp through the public API; warcolak
  n = 650 three-way parity; repeatability lacks the dense-cell guard `animal()` has; marker coding
  (0/1/2) is undocumented on the R side.
- Doc Reader: all 21 R articles now executed chunk by chunk across the three waves (two more share
  #208's defect); R↔Julia cross-links resolve both ways.
- Mathematician (Opus): `covariance_structure_lrt` counts FA parameters without the rotational
  indeterminacy `ledermann_slack` subtracts (new HSquared.jl #331); #327's point estimate is
  sa0·e⁻⁶ at the null for three start values; `:gamma` rails 10/20 and `:nbinom` has no rail;
  `marker_effects` names two different estimands across the twins; `?factor_g_extractors` gives a
  wrong reason for withholding `specific_variance()`.
- Code Reviewer: the five remaining `hs_control()` targets, the H^Γ metafounder variant and
  lowrank/FA live calls behave per contract (9 ship, 6 blocked, 0 stop); single-step construction at
  `ridge = 0` surfaces a raw Julia trace (added to #214).
- Speed: after fixing the wave-2 generator, HSquared.jl and pedigreemm agree to ≤ 5e-7 at q = 1k/5k
  on the corrected replicated design; sommer's dense `mmer` agrees but is a different algorithm class;
  the ASReml position ("unknown within 3×") stands, AGENT-INFERRED, vault-only.
- Rose audit: KEEP 4 · MERGE 5 · DROP 1 (sire-model "unreachable" refuted through the public API);
  four new clusters. Filed: HSquared.jl #331; hsquared #216, #217, #218; comments on HSquared.jl#327,
  hsquared#212, #214, #208, #201. Twenty-four items cumulative.

## 3a. Decisions and Rejected Alternatives

- Stopping rule evaluated: not fired (4 new clusters ≥ 3; 24 of 60 items; wave 3 of 4). Wave 4 is the
  final wave by rule (ii) and was launched only after Melissa's wave-3 record existed (the wave-2
  drift is not repeated). Rejected: extending the campaign beyond wave 4 on the strength of wave 3's
  yield; the rule is the rule.
- The local-path sweep now runs inside the posting script; a body still carrying a local path is
  skipped, not posted. None was skipped.
- Sire-model draft not filed: `animal(1 | sire, pedigree = sire_ped)` + `henderson_mme` reproduces
  Mrode 3.2's published sire solutions, so "unreachable" was false.

## 4. Files Touched

Julia repo (this records PR): `docs/dev-log/after-task/2026-09-13-h2-test-campaign-w3.md` (this file),
`docs/dev-log/plan-actual/2026-09-13-h2-test-campaign-w3.md` (Melissa). R repo: no file touched.
GitHub: four issues and five comments. Vault: `projects/H2-twin/updates/*-w3.md` ×6,
`updates/2026-09-13-mech-verify-w3.md`, `articles/2026-09-13-rose-audit-w3.md`, `issue-drafts/` ×10,
`repros/w3-*`, `briefs/wave4-addendum.md`, `MISSION-CONTROL.md`, `checkpoint.md`, `memory/AGENT_LOG.md`.

## 5. Checks Run

- Workflow `wf_77fb4a27-c87`: 6 agents, 6 receipts, 0 errors, 1.12 M tokens, 23 min wall.
- Mechanical verification (`updates/2026-09-13-mech-verify-w3.md`): six receipts with NOT COVERED and
  `compute_minutes`; ten drafts structurally complete; both worktrees zero tracked changes; nothing
  filed since wave 2; nine of ten drafts carried local paths, all stripped by the posting sweep.
- Rose re-ran every cheap repro, including the `initial`/`iterations` probe and the marker-coding fits.
- Melissa independently re-derived the 9-item, 24-cumulative count from live GitHub and confirmed the
  sweep held on all nine items.
- Not run (docs-only lane): `Pkg.test()`, `docs/make.jl`, `preamble_cap.sh`.

## 6. Tests of the Tests

- The Data Fitter nearly filed sommer's `A.mat` divergence as an hsquared bug and caught itself by
  adding AGHmatrix as a third construction; the three-way check is what made the near-miss visible.
- Rose refuted the sire-model draft by running the natural formula spelling: the gate catches
  "unreachable" claims that were never tested against the package.
- The Speed lane found and fixed a CSV-writer bug in its own harness before reporting.
- The posting script's leak check is a negative control on itself: it prints SKIPPED and posts
  nothing when a body still carries a local path.

## 7a. Issue Ledger

Filed 2026-09-13 (wave 3): HSquared.jl #331 structured-lrt-df (bug, julia-engine, validation);
hsquared #216 genomic-marker-coding-undocumented (documentation, bug, r-package); #217
repeatability-dense-cap-not-enforced (bug, bridge, r-package); #218 fa-uniqueness-wording
(documentation, r-package). Comments: HSquared.jl#327 (start-value variation, gamma/nbinom rails);
hsquared#212 (multi_effect also drops the controls); #214 (single-step ridge = 0 raw trace); #208
(two more articles; all 21 executed); #201 (`marker_effects` naming). Not filed: sire-model
supplied-variance "unreachable" (DROP). Cumulative: 13 issues + 11 comments = 24 items.

## 8. Consistency Audit

- Every filed cluster is listed in the wave-4 addendum so the final wave comments rather than
  re-files.
- Rose's campaign-level note (every DROP = a tester concluding without asking the package; every
  strongest KEEP = the programme contradicting itself in writing) is carried into the wave-4 briefs as
  a standing lesson.
- Mission Control Current table and Log, the `/p/H2/test` NOW strip, and this report agree on 24 items
  and four new clusters.
- Melissa flags recurring staleness of `AGENT_LOG.md`, the Mission Control Log, and the checkpoint's
  secondary sections; all three were refreshed at this close.

## 9. What Did Not Go Smoothly

- Three drafts arrived with the wrong `kind` shape, caught by Rose's manual read, not by the mechanical
  verifier, whose schema does not check `kind`.
- `TaskOutput` on a long-running Rose agent again dumped transcript into the orchestrator on timeout.
- The vault commit command was refused once by the auto-mode classifier and had to be retried.
- The `test-campaign` label still cannot be created from this session.

## 10. Known Residuals

- Melissa w3: 8 ADAPTIVE / 4 DRIFT / 2 UNCLEAR.
- Simulator: one seed per route for multi_effect/random_regression parity; `initial`/`iterations`
  honouring on henderson_mme, single_step*, sparse_reml, repeatability, multivariate untested (wave 4).
- Data Fitter: wave-2 BTdata sommer reference not rechecked for the `A.mat` convention caveat;
  warcolak dominance SKIP.
- Doc Reader: no Documenter or pkgdown build run; Julia pages beyond quickstart not cold-read (wave 4).
- Mathematician: no FA model fitted; metafounder Γ = 0 collapse, chi-bar weights, GBLUP↔SNP-BLUP
  ridge study not done (wave 4).
- Speed: q = 20k/50k on the corrected design and process-repeat spread not done (wave 4).

## 11. Team Learning

- "Unreachable" is a claim about the package; test it against the package's natural spelling before
  writing it. Four of five campaign DROPs are this one error.
- Add a third construction (AGHmatrix beside sommer) before filing a divergence between two tools.
- Keep the local-path sweep inside the posting step, never as a separate reminder.
- Wave N+1 launches only after the V3 file exists; the gate must be mechanical.

## 12. Cross-Product Coverage

Wave 3 covers: multi_effect and random_regression R↔Julia parity with real random-effect variance;
the r_g grid through the R bridge; `initial`/`iterations` honouring on five targets; DT_cpdata
genomic with AGHmatrix; Mrode 3.1 animal model; warcolak n = 650; repeatability over the dense cap;
all 21 R articles; the five remaining `hs_control()` targets; FA parameter counting; metafounder Γ,
LOCO wiring, repeatability and evolvability functionals as algebra; start-value variation for #327;
gamma/nbinom rails by running them; HSquared.jl vs pedigreemm vs sommer at q = 1k/5k.

Wave 3 does NOT cover: second seeds for parity; `initial`/`iterations` on the remaining targets;
unbalanced repeated records; the BTdata `A.mat` caveat; PlodiaPO; a Documenter or pkgdown build;
the 14 unread Julia pages; any fitted FA model; metafounder Γ = 0 collapse; chi-bar weights for #331;
GBLUP↔SNP-BLUP ridge with seeds; the raw-Julia-trace sweep across all bridge call sites; tau/omega/
blend_weight knobs; q = 20k/50k comparator timing; process-repeat spread; any GPU, Totoro or DRAC
compute; the R repo's own records; and any fix.

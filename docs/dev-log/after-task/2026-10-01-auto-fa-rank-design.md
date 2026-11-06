# Automatic Gaussian genetic FA-rank design closeout

## 1. Goal

Complete the approved design-only automatic Gaussian genetic FA-rank arc with Ultra Plan and Unlazy: a reviewed contract and validation plan, without production code or numerical runs.

## 2. Implemented

Wrote the bounded T4 complete-response pedigree contract and the staged validation plan. Updated the approved arc, follow-on and roadmap pointers; retained three producer reports, three independent completion reviews, final source/protection checks and the five-gate acceptance ledger. Design V0 is complete. The selector is not implemented or scientifically validated.

## 3a. Decisions and Rejected Alternatives

Compare shared factor counts K0 and K1. K0 retains positive diagonal genetic variance. Use a future internal diagonal route with the same uniqueness floor as FA; the existing public diagonal mapping stays intact. Freeze the experimental common-X `reml_aic_covariance` rule with nominal q values 14 and 18, D=C1-C0, a predeclared numerical tie band and smaller-rank tie rule. These engineering tolerances have not been measured on a selector implementation.

Both ranks must be eligible and converged. One diagonal start plus two ordinary FA starts and at most one specified FA retry gives four starts maximum. Preserve all failures; a sole eligible candidate cannot win. Near-floor candidates remain eligible when admissible and flagged, superseding the stricter initial user scout proposal. Intervals remain conditional on chosen rank. Marginal ML-AIC needs actual ML fits; pedigree BIC sample-size and calibrated probabilities are deferred.

Independent method review added a stronger identification requirement: genetic and residual kernels must separate after removing the fixed-effect space. An all-half-sib intercept-only design is a refusal witness despite its relatedness. The review also added the retry trigger for a higher finite unconverged FA start.

## 4. Files Touched

`ROADMAP.md`; `docs/design/auto-fa-rank-design-plan-20261001.md`, `auto-fa-rank-follow-on.md`, `auto-fa-rank-contract.md`, `auto-fa-rank-validation-plan.md`; `docs/dev-log/check-log.md`; `docs/dev-log/coordination-board.md`; this report; `docs/dev-log/source-review/2026-10-01-auto-fa-rank-design-independent.md`; three reports under `docs/dev-log/scout/2026-10-01-auto-fa-rank-design/`; and the receipts under `docs/dev-log/check-log.d/2026-10-01-auto-fa-rank-design/`. Ignored goal/checkpoint/ledger files under `.unlazy/auto-fa-rank-design-20261001/` support execution; their final acceptance ledger is retained in the tracked receipt directory.

## 5. Checks Run

Independent method, user/claim and mechanical reviews pass at V0 only. Initial HOLD findings and inspected resolutions remain in the receipts. Unlazy `--reverify` with explicit repository `--cwd` passes all five gates: four executable artifact/preservation checks replayed, and one separate manual method/claim acceptance. No abandoned gate. The executable presence checks alone do not establish scientific acceptance.

Source/test/Project/capability/debt diff from approved base `28f90e09` is empty. Protected main and original numerical-candidate HEAD/status/tracked-diff hashes match the earlier snapshot. Documentation links, prose, whitespace, preamble and task-local after-task structure are checked in the final verification receipt. No Julia/R fit, package test, simulation, benchmark or build was run. Such tests cannot validate an unimplemented selector.

The required shared closeout compiler exits 1: its root anchoring invokes acceptance checks in the brain repository, outside this task. The task-local R validator exits 0 and reports four ledger files with every gate satisfied. The final receipt distinguishes these outcomes; no shared tool or unrelated ledger was changed.

## 6. Tests of the Tests

The first leaf replay used the ledger directory as its implicit working directory, so three artifact checks failed. Its apparent preservation PASS is rejected as evidence because those Git pathspecs also resolved from the wrong directory. All unchanged CHECK/EXPECT commands were approved and rerun with the actual repository root; every runnable gate then passed. This retained negative result shows why execution location is part of an oracle.

Independent review supplied the half-sib contrast-space counterexample and the mixed converged/better-unconverged retry witness. The validation plan requires independent dense objective/score references and deliberate wrong-floor, wrong-order, wrong-penalty, sole-winner and interruption controls. These are future tests, not executed numerical evidence in this arc.

## 7a. Issue Ledger

R0/C0/F0/B0 have explicit design dispositions. Resolved: inconsistent variance floors recognized; REML projection in identification checks; missing retry trigger; conflicting historical user recommendations; ambiguous unattempted rows; stale bounded R-bridge statement. The earlier user recommendation is explicitly superseded while its substantive alternatives remain preserved. One relative link was corrected during consolidation.

Deferred implementation obligations: internal floor-matched diagonal mapping, exact nonzero retry initializer, projected-kernel rank/scaling threshold, near-floor flag definition and cancellation/ledger transport. Selection reliability and post-selection inference require new evidence under separate approval.

## 8. Consistency Audit

The two final artifacts agree on the model, likelihood, candidate range, parameter counts, tie and failure rules, bounded starts, visible floor/unit dependence and conditional uncertainty. The final independent receipt pins their hashes and carries implementation limits. Neighbouring plan/follow-on/roadmap pointers now describe V0 completion without claiming automatic fits.

The immutable landed R fixed-rank bridge at `e82f5c95` was used instead of the older dirty sibling checkout. Existing GLLVM and protected gllvmTMB source receipts were reused; their selection scores, unconverged-fit policy and simulation claims were not transferred. Protected checkouts and the frozen 200-attempt FA campaign remain untouched. No capability/debt row changed; public covered count stays seven.

## 9. What Did Not Go Smoothly

An early Graft interpretation confused Gaussian FA spans with a separate non-Gaussian fitter. The source scout corrected this; no unsupported stale-graph claim remains. Producer lease registration printed GRANTED despite a permission error and release found no registered lease; that is recorded as registry friction, not proof of registration. Producer ownership was disjoint. The parent successfully renewed its registered scoped consolidation lease after workers finished.

The first ledger replay had the wrong working-directory anchor and was retained as failed. The historical user proposal conflicted with the controlling contract until explicitly superseded. Independent scientific review found two substantive omissions and both were repaired before acceptance. One context compaction occurred; subsequent work stayed within this design milestone. The required daily lifecycle audit exits 1 for other persisted sessions with excess compactions/reviews; this task is not named among those failures. Its receipt is retained. The next implementation milestone belongs in a fresh task.

## 10. Known Residuals

The REML score is a bounded experimental heuristic for a singular model comparison. It gives no biological-rank probability, consistency guarantee or marginal predictive-optimality claim. Tolerances, optimization reliability and numerical identification controls remain unmeasured. Absolute uniqueness floors depend on trait units. All future fits need estimates before launch; the proposed ten-minute first-dataset measurement is not launched. Serious replicated CPU work belongs on Totoro or an appropriate queued DRAC job, with caps; projected runs over three hours need a pre-run-supported approval.

This branch remains local, with no new hosted checks or publication. Its completed design is reviewable in the repository; no unfinished implementation is left running. The next implementation proposal needs a fresh task and an explicit scope decision. No push, merge, tag, release, submission, GPU or protected-lane action occurred.

## 11. Team Learning

Actual producers: engine scout Luna medium, user scout Luna medium, method scout Sol high. Actual independent completion panel: method Sol high plus user and mechanical Luna medium. Native explicit model/effort dispatch was used; no tiered CLI enforcement or additional agent tree is claimed. The hard judgment was likelihood/identification; mechanical work used Luna. Initial production ownership was disjoint; the parent consolidated after completion.

Memory receipt: operating contract, brain index and vault-first search, route manifest, WHAT-WORKS, model/compute guidance, Ultra Plan, Unlazy, symbolic/statistical and validation instructions were read before substantive work. Recall returned no specific prior automatic-rank decision. The older calibration-first manifest did not override the explicit approved design scope. Existing sibling receipts were recalled instead of rescanning protected lanes. Durable method choices are filed in the linked design contract and review receipts; no private memory or hub files were edited.

Golden Set: no existing implementation-regression class was modified in this documentation-only arc. No numerical Golden Set run is claimed. Planned known-answer and negative witnesses are explicit in the validation plan.

## 12. Cross-Product Coverage

This task covers the design contract for complete T4 Gaussian pedigree, trait-intercept, one-record K0/K1 selection; its future attempt schema; explicit fixed-rank compatibility obligations; same-data REML score conventions; and a predeclared validation/compute plan. It does NOT cover implementation, executed selector tests, measured rank recovery, post-selection interval calibration, R automatic grammar or payload activation, missingness, repeatability, other traits/ranks, genomic/custom providers, Poisson genetic GLLVM, protected sibling promotion, GPU, campaigns, hosted deployment, release, registry, tag or submission. V0 design acceptance is the highest proven status.

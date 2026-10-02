# Automatic FA-rank twin implementation programme

Status: bounded paired programme complete locally, 2026-10-02. The bounded Julia selector and R expert route pass all six technical gates and all three independent V7 source reviews. G8 final reconciliation, mandatory whole report validation and local commits are complete; all eight gates pass. Current evidence is recorded in the [implementation receipts](../dev-log/check-log.d/2026-10-01-auto-fa-rank-implementation/README.md). The completed [design contract](auto-fa-rank-contract.md) and [validation plan](auto-fa-rank-validation-plan.md) remain the starting evidence. Shinichi chose Julia and R together during implementation planning.

## Programme ladder

Mode: size. Recommended target 7.5 hours, plausible range 6 to 10 hours. This is an inferred engineering estimate, not a measured selector runtime or a requirement to fill time. All rungs advance the same transition from reviewed design to tested experimental mechanics and transport.

| Order | Target budget | Observable outcome | Evidence / dependency |
| --- | ---: | --- | --- |
| Arc 0: engine foundation | 120 min | Selector-only matched-floor diagonal context and complete per-start result capture exist; public fixed-rank behavior preserved. | Independent covariance/objective witnesses and fixed-rank regressions; no selector usability claim. |
| Rung 1: selector | 120 min | Explicit Julia selector returns selected/unavailable/refused results with complete ledgers and bounded retry policy. | Deterministic O1-O10 policy, objective, identification and interruption witnesses pass. Depends on Arc 0. |
| Rung 2: R transport | 90 min | Explicit expert control returns a selection object with the selected fit or NULL, plus every reason and row. | Manufactured transport fixtures and conditional-fit extraction checks; uses the frozen Julia payload. Can overlap late Rung 1 under disjoint ownership. |
| Rung 3: integrated verification and repair | 90 min | At least one ordinary-start selected-fit fixture agrees across Julia and R; unavailable/refusal/interrupt paths preserve diagnostics. | Mandatory live bridge, O11, full package checks and independent method/claim review. No passing skips. |
| Integrate and close | 30 min | Exact-source logs, reviewed status/debt records, replayed gates, after-task report and local commits retained. | All required acceptance gates pass or a concrete incomplete checkpoint names unresolved work. |
| Total work budget | 450 min | Tested bounded experimental Julia/R route. | Calendar time may differ because owners can work in parallel. |

## ARC CARD: Arc 0, engine foundation

Mode: size.

Requested outcome: not quantified by the user; first usable foundation for the complete two-rank twin selector.

Mechanism authority: the prior go-ahead and explicit Julia-and-R choice cover reversible local implementation, the experimental R expert-control API and short checks in isolated owned lanes. Ordinary FA covariance formula activation and production/default promotion are excluded. This sizing task itself makes documentation only. No remote computation, external message, publication or release action is authorized.

Recommended arc: 120 minutes; estimate confidence inferred.

Time contract: a planning target rather than fixed capacity. Re-estimate at a material overrun; elapsed time alone cannot satisfy implementation acceptance.

Arc 0 outcome: matched-floor K0 and full per-start results are independently checked without changing the public fixed-rank routes.

State transition: reviewed design at V0 becomes a tested numerical foundation for V1; covered count stays seven.

Executable rung and evidence: implement internal floor mapping and optimizer-attempt capture, run independent covariance/REML witnesses and fixed-route compatibility regressions, retain the actual logs.

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 15 | Recheck clean Julia base, source spans, leases and exact R base; establish separate file owners. |
| Core | 70 | Shared context, matched K0 mapping, full per-start result capture and independent fixtures. |
| Verify | 15 | Focused deterministic references plus exact existing fixed-rank compatibility checks. |
| Repair reserve | 15 | Resolve a local failed witness; retain red and repaired results. |
| Closeout | 5 | Checkpoint the usable foundation and calibrate the remaining programme. |
| Total | 120 | Arc 0 only; this does not close the full twin goal. |

In scope: internal Julia foundation, its independent references, fixed-rank compatibility.

Not in Arc 0: R activation, selector recovery claims, larger rank ranges, campaigns or release work.

Risk branch: if preserving the existing optimizer start vectors or fixed-fit outputs requires changing numerical behavior, stop extending the selector, retain the regression failure and resolve or re-estimate that foundation before Rung 1. Do not broaden scope or weaken the test to fit the time target.

Done when: the new internal mapping and per-start record machinery pass independent witnesses and the established fixed-rank regressions; source and logs are pinned.

First action: in the fresh implementation task, run `bash /Users/z3437171/shinichi-brain/tools/lane_preflight.sh` on the execution checkout, verify the intended base and claim only the assigned source/test paths before editing.

## Implementation choices for the full programme

These choices complete the earlier design obligations. Their numerical feasibility remains to be tested.

### Julia engine

Add experimental `select_fa_rank(Y, X, Z, pedigree::Pedigree; ids=nothing, traits=nothing, iterations=2000)`. The existing fixed-rank fitter retains its signature and behavior. Derive Ainv from the actual pedigree, validate canonical ID order, and build one shared context for the two candidates. A raw precision matrix is not sufficient proof of pedigree provenance.

Preflight requires finite complete four-trait data, an all-ones intercept column, one unique unit entry per Z row, no repeated observed animal and at least three records. Unsupported input returns two unattempted candidate-summary rows and zero optimizer attempts. Missing observations, genomic/custom providers, repeated records, other traits/ranks/families and other fixed effects remain refused.

The selector-only K0 mapping is `psi_i=c+exp(theta_i)`, c=1e-4, matching FA. Capture complete optimizer results and G/R for each existing default/balanced FA start at the private optimizer seam; wrapping only the final public fit loses needed attempts. Preserve the start vectors and fixed-route selection behavior in compatibility tests.

For identification use orthonormal Helmert contrasts Q, B=ZA Z', H=Q'BQ and J=I. Screen the two unit-Frobenius columns vec(H) and vec(J) by SVD; refuse nonfinite/zero H or smallest/largest singular-value ratio <=1e-8. This dimensionless engineering check operates on REML contrasts and catches identity and compound-symmetry half-sib designs. It does not establish useful finite-sample information.

From the eligible K0 fit, the sole FA retry has `l_i=0.1*(-1)^(i-1)*sqrt(g_i-c)`, `psi_i=g_i-l_i^2` and the same fitted R. Verify finite nonzero loadings, strict floor admissibility, unchanged diagonal and the declared off-diagonal perturbation before optimization. An unrepresentable initializer is a retained failed retry, without clamping or a hidden fallback.

Use the contract's q={14,18}, penalties={28,36}, D=8-2*(ell1-ell0) and tau=1e-6 criterion units. Independently reevaluate same-covariance loglik with dense Cholesky GLS and require absolute difference <=1e-8. Both ranks must be converged and eligible; retain all attempts, the nesting guard and the better-unconverged retry trigger. At most four optimizer starts.

Reject uniqueness floor distance <=0; flag positive distance <=1e-6. `boundary_sensitive` records either chosen within-rank candidate's near-floor condition. `start_sensitive` flags a finite FA likelihood range >tau/2 or a better finite unconverged attempt; return continuous covariance disagreements without inventing a calibrated threshold.

### R expert interface and interruption

The included R API addition is an explicit experimental expert control, `rank_selection="auto"`; this is part of the paired implementation outcome chosen by Shinichi. It does not activate ordinary `cov=fa(K)` syntax or change the default estimator. Use existing multivariate syntax with `control=hs_control(engine="julia", engine_control=list(target="multivariate", rank_selection="auto"))`. Branch before fixed-rank defaults materialize. Reject explicit rank, initial or genetic_structure alongside auto; omitted rank does not activate auto. Preserve the fixed-rank bridge and existing formula grammar.

Reuse the bridge's `normalize_pedigree(id,sire,dam)` and canonical ID check, then pass the pedigree object directly to the selector. Return class `hsquared_fa_rank_selection` with selection metadata and `selected_fit`, an ordinary hsquared_fit on success or NULL otherwise. Add print and fit_diagnostics methods; use existing fit extractors on selected_fit. Unavailable objects cannot dispatch as fitted covariance, EBV, logLik or AIC results.

Candidate summaries retain both ranks, including preflight-unattempted ranks. Attempts contain actual starts only. Serialize plain fields with matching missing-value semantics, reasons, covariance/EBV order, criteria and boundary/start flags. Returned uncertainty is conditional on the chosen rank.

A private request-local ledger sink receives snapshots before and after optimizer starts. The R bridge holds a request-local Julia reference; on interruption, retain the active interrupted row and candidate-level unattempted states, retrieve the partial ledger into the propagated R interruption condition, and return no completed selection. This behavior must pass controlled Julia and R interruption tests before the route is accepted.

## Acceptance, ownership and compute

Ultra Plan owns decomposition and the new implementation goal; Unlazy owns predeclared executable acceptance gates. Use disjoint numerical and R owners plus independent testing/review ownership. The numerical change needs Gauss/Karpinski/Noether review; the bridge needs Hopper/Boole/Emmy; validation needs Curie/Fisher/Mrode; experimental public wording requires Rose. These are required review lenses, not claims that all named agents run concurrently. Keep bounded native batches within the skill's model/effort budget.

Reuse the clean Julia design lineage at commit `56536532`. The existing R checkout is dirty and must remain untouched; create a separate owned execution checkout from verified landed R source, with e82f5c95 as the minimum reviewed fixed-rank bridge reference. Refresh live refs and compare any drift before edits. Do not alter protected GLLVM/gllvmTMB worktrees or the frozen FA campaign.

Execute O1-O11 from the validation plan, including deliberately wrong floors/orders/penalties, exact and near ties, identity/half-sib refusal, sole-survivor rejection, higher-unconverged retry, floor-boundary rows, cancellation and missing-field round trips. The live bridge must require Julia and fail on skips. A successful ordinary-start selected-fit fixture and explicit unavailable/refusal fixtures are necessary for the full programme. Artifact presence or manufactured winners alone cannot close it.

Prior fixed-rank full-suite receipts are 417.16-466.95 seconds; live bridge receipts are 22.73-28.03 seconds. Those support a bounded verification allowance only. New selector fitting cost is unknown. Before real selector acceptance fits, state that uncertainty and use the first ordinary-start fixture with a ten-minute owned timeout, one Julia thread and one BLAS thread. Inspect non-empty candidate/start rows immediately; stop and re-report an overrun or unusable output. Measure before estimating later checks. Do not reuse the old fixed-rank timing as a selector-runtime claim.

Serious replicated CPU work is a later Totoro or DRAC proposal. No remote run is approved by this card. A projected numerical run over three hours needs a pre-run-supported plan and approval. The 7.5-hour estimate is total engineering work, not permission for an unbounded numerical job.

Full programme closes only with executable numerical/policy tests, mandatory paired live parity, current full package checks, independent judgments, exact-source logs, replayed gates, status/debt/docs and local commits. Keep capability experimental and covered count seven. No rank-reliability, inference-calibration, default/public-formula, GPU, version, registry, submission, tag, push or deployment claim follows.

## Evidence and actuals

Sizing evidence: source/bridge planning scouts inspected Julia56536532 and immutable R e82f5c95; their findings are consolidated above. The design and validation plan have independent V0 acceptance. [Design closeout](../dev-log/after-task/2026-10-01-auto-fa-rank-design.md) records the current starting state. The main check log carries the cited fixed-rank timing receipts. No close numerical implementation analogue measures the core build estimate, so confidence stays inferred.

Recommended / actual: programme 450 minutes / bounded programme complete locally. Calendar time exceeded the target across approval waits, the deadline checkpoint and accepted repairs; active engineering time was not independently measured. The plan does not require filling that estimate. Current focused V7 acceptance passes 249 assertions across 13 testsets; historical V5 passed 236/13. The observed interval from the implementation-loop commit at 17:24 Edmonton to the 21:33 checkpoint is about 4 hours 9 minutes; it includes implementation, verification, repairs and approval waits and is not an active-engineering-hours measure. No final under-run or completed-programme calibration is claimed.

Requested / used: complete paired programme approved / three disjoint native producers, parent consolidation, fresh numerical/bridge/evidence panels V2 and V3, and a separate mechanical receipt audit. The overnight instruction supplied a deadline of October 2 at 5 a.m. Edmonton. The user then extended work with "contiune till all passes"; the deadline interruption is preserved. No fixed token budget was requested.

Rungs completed: prior V0 design accepted. Julia and R implementation exist. V4 root replay passed G1-G6, including mandatory live transport/interruption and full packages. V5 fixes two parent-discovered false-positive test comparisons; its focused 236/13 proof and affected Julia replay pass. The later O1 production-comparator repair passes 249/13 at Julia 3ef362b1. V7 root replay passes G1-G6 and all three V7 source reviewers pass G7. G8 final reconciliation and mandatory whole report validation pass; all eight gates are complete.

Under-run event: none declared while acceptance is incomplete.

Calibration: V4 final root log records a 722.49-second interval, about 12 minutes, within the 15-20 minute estimate. R full check has zero errors/warnings/notes; its test phase records 3871 passes, 26 test warnings and 48 existing opt-in skips. These broad opt-in skips are separate from required-live acceptance. Final R source is 2108c0d. Historical V5 test candidate 45ae9216 includes engine repair 526c85b7; current V7 test candidate is 3ef362b1. Engine and R interface remain unchanged since V3.

Metric movement: initial focused Julia 147; first repaired log 208/12, correcting an unsupported 220/11 assertion; combined V4 controls 232/13; V5 controls 236/13; current O1 comparator controls 249/13. Counts come from independently parsed retained logs. R mandatory-live producer reports 128 passes with zero warnings/skips; parent G4 at the same sources passed. Count growth alone cannot establish acceptance. Both ordinary optimizer witnesses selected K0; ordinary selected K1 remains untested and rank reliability is deferred.

Result: bounded paired implementation locally accepted. Source-review V2 found a genuine rejected-score defect and missing controls, which were repaired. V3 bridge/evidence passed; numerical review requested the now implemented near-floor and persistent-nonnesting controls. Parent then repaired two test comparisons that evaluated a 14-element K0 vector with the 18-element K1 objective. The final acceptance establishes bounded local mechanics; capability promotion and broader scientific claims remain deferred.

Next action: no original bounded-programme requirement remains. Any later scientific reliability or publication work starts from a separately approved proposal. All original requirements are proved and the prior pending audit permission was explicitly approved.

HAND TO ULTRA PLAN: paired automatic FA-rank implementation, target 7.5 hours (inferred 6 to 10), Arc 0 120 minutes, complete T4 Gaussian pedigree K0/K1 mechanics plus experimental R transport, mandatory tests and ledgers, no promotion/campaign/release/protected-lane work. Use Unlazy for acceptance; keep the complete paired outcome intact across checkpoints.

Final result, 2026-10-02: whole bounded paired programme complete locally. Focused repaired acceptance is 249/13; full Julia/R checks, live bridge, all three V7 source lenses, mechanical reconciliation and full report validation pass. All eight original gates are met with no abandonment. Source candidate remains Julia 3ef362b1/R 2108c0d. No broader rank, reliability, default activation, campaign, promotion, release or publication claim follows. Earlier evidence states retain their original checkpoints.

Previous closeout checkpoint next action, retained verbatim for receipt history:

Next action: finish G8 mechanical reconciliation, full after-task acceptance and local documentation commits. The explicit source-review approval was accepted and the original deadline was honored. V6 identified the missing O1 comparator control; the test-only repair and fresh complete V7 panel resolved it. A separate final external mechanical audit was rejected by automatic approval review; its specific authorization question remains pending while local closeout continues. All eight original requirements remain binding.

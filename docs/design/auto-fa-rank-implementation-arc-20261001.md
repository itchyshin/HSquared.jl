# Automatic FA-rank twin implementation programme

Status: sized implementation programme, 2026-10-01. Execution has not started. Automatic rank selection is not implemented and no auto-rank fit or test has run. The completed [design contract](auto-fa-rank-contract.md) and [validation plan](auto-fa-rank-validation-plan.md) remain the starting evidence. Shinichi chose Julia and R together during implementation planning.

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

Recommended / actual: programme 450 minutes / not started; Arc 0 120 minutes / not started.

Requested / used: no fixed capacity requested / no implementation time used.

Rungs completed: V0 design is prior work; no implementation rung completed.

Under-run event: none.

Calibration: complete here at each implementation checkpoint; record core work, verification, repair and waiting separately.

Metric movement: none yet; implementation state remains reviewed design only.

Result: sized programme awaiting the execution task; no auto-rank test result.

Next arc: Arc 0 engine foundation, followed by the retained ladder.

HAND TO ULTRA PLAN: paired automatic FA-rank implementation, target 7.5 hours (inferred 6 to 10), Arc 0 120 minutes, complete T4 Gaussian pedigree K0/K1 mechanics plus experimental R transport, mandatory tests and ledgers, no promotion/campaign/release/protected-lane work. Use Unlazy for acceptance; keep the complete paired outcome intact across checkpoints.

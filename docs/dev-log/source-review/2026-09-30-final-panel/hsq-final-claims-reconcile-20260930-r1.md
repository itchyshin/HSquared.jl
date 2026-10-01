# Final claim and plan reconciliation

Date: 2026-09-30
Reviewer lens: Rose claims audit; Melissa plan versus actual
Scope: read-only review of the approved bounded FA/GLLVM twin programme. No fit, simulation, GPU work, submission, tag, release, or source edit was performed.

## Pins and evidence boundary

- Julia candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260`. The disposition inventory lists 24 tracked `src/` files; all 24 current SHA-256 values match `2026-09-30-final-integrated-source-dispositions.json`. `test/runtests.jl` matches recorded runner SHA-256 `723f060911f55941b88a7c20fcb4d61dbdbf6f2d0ce90793894ab80ac0105d06` at inspection.
- R candidate: `/private/tmp/hsquared-fa-gllvm-20260927`, HEAD `fa98c262eb21694d672e671c9672491ce3369cec`. Both candidates have intentional dirty changes in source, docs, tests, or receipts; HEAD alone does not identify the reviewed bytes. Julia's integrated source pin is byte-attested, but runner and documentation pins are due to refresh after the current fixes.
- `docs/dev-log/source-review/2026-09-30-final-integrated-source-dispositions.md` explicitly limits its component approvals: A2/E1/V3 and overall programme signoff remain open. It states public covered count 7 and 56 validation ID/status records unchanged.
- Root reports the current full Julia package check stopped at 436 passing and 3 failing assertions in 41 seconds. Failures concern generated validation-status documentation being stale and two exact-text assertions retaining old false claims. Root is correcting semantics and regenerating the page; no test deletion or weakening is reported. Therefore the current package-check gate is HOLD. I did not run or alter tests.

## Public claim audit

**Conditional PASS for the inspected source wording and route-specific field meanings. Rendered-surface review remains HOLD.**

- Both twins retain the experimental 0.9.0 label and `public_covered_count = 7`. Julia README prominently says not production and not Julia General; it describes the Julia repository as the computational engine and directs formula users to the R twin. R README, `current-limits`, `multivariate`, and `genetic-gllvm` articles describe the two routes as opt-in, partial, experimental, and dense/validation-scale. No reviewed source wording promotes either new route to covered or implies 0.10/0.11 is an authorized release.
- FA is stated as the narrow complete-response Gaussian pedigree cell with four traits and K=1, unstructured residual covariance, and explicit expert control. The public caveats state that rank does not identify every loading/uniqueness configuration, loadings and loading inference are unavailable, and convergence plus positive Ledermann slack are not local-identification evidence. `genetic_rank` is requested rank. The 200 attempts remain in the denominator: 110 met the declared covariance diagnostics, 20 G-threshold errors, 11 R-threshold errors, and 59 nonconverged. The reported MCSE is 0.03517812 and Wilson 95% interval [0.480756, 0.617359]. The preregistration has no campaign-wide aggregate cutoff, so 55% is descriptive usability evidence and does not establish a pass threshold, coverage, or reliability claim. Public current-limits prose gives the recovery denominator and start/convergence caveat; the deeper panel receipt carries the detailed failure taxonomy.
- Genetic GLLVM is stated as complete balanced Poisson-log, three traits, K=2, pure low-rank pedigree covariance. Public output meanings align across the article/manual and the Julia disposition: genetic covariance/correlations are link-scale covariance quantities; `breeding_values()` returns trait genetic conditional modes on the log-rate/link scale, not factor scores, posterior means, or response-scale heritabilities. Diagnostics expose outer and inner convergence details. The integrated Laplace objective is not ordinary non-Gaussian ML or REML, and generic `logLik()`/`AIC()` are unavailable. Current-source replay is one same-seed 50-fit cell, not independent replication or calibration; the separate four-scenario recovery retains the reported-not-gated Bernoulli contrast. Neither supports a broad GLLVM claim.
- Experimental-route limits are visible in the R manuals/vignettes and Julia README/status pages: no automatic rank, arbitrary rank/family, missing or repeated responses, loading inference, calibrated intervals, production sparse scaling, or GPU execution. Automatic FA rank and unusual-inheritance fitting remain queued. GPU status diagnostics are metadata, not execution evidence.
- Scope qualification: route-specific FA/GLLVM output semantics reviewed cleanly, but this is not a global bridge-payload PASS. The exact-current Julia payload review records unresolved direct-maternal result-shape mismatch with the R extractor and unvalidated `coefcov` metadata; the current-candidate bridge tests are focused evidence, and V3 remains open. This is accurately retained in the source-review/gate records.
- The public status sources are not yet a rendered-surface confirmation. The local R pkgdown site and Julia Documenter source builds are recorded as completed components, but no live-site inspection was performed in this audit. Root's current generated Julia validation page is stale relative to the semantic corrections under way; hold rendered/check-log closure until regeneration and exact rerender.

## Plan versus actual

The approved plan in `docs/dev-log/arc-program/2026-09-27-fa-gllvm.md` set arcs A through E and expressly deferred GPU, unusual inheritance, broader cells, submissions, and tags. Actual disposition against the programme gates:

| Arc/gate | Planned outcome | Evidence-based actual status |
| --- | --- | --- |
| A1 | FA identifiability, boundary, ordering, scale, and status contract | Checked in `GATES.md`; supporting source and interpretation amendments are recorded. |
| A2 | Full FA engine review and panel verdict | HOLD. The 200-seed scientific diagnostic portion is accepted only within bounded scope. Remaining exact-current source/R-route spans, comparator change-impact reconciliation, wording cleanup, and whole-wave/panel signoff remain. Do not turn the scientific subcomponent PASS into whole A2. |
| B1 | Four-trait Gaussian K=1 R opt-in with parity and diagnostics | Checked in `GATES.md`; current focused live bridge recheck is documented as 213/213. This is route evidence, not whole V3 or release readiness. |
| C1/C2 | Correct objective/reduction and ordinary-start checks for selected Poisson cell | Checked in `GATES.md`; 50/50 current-source same-seed replay is reproducibility evidence for one cell, not independent replication, broad recovery, calibration, or external same-objective agreement. |
| D1 | Three-trait Poisson-log K=2 R opt-in, link-scale conditional modes, limits | Checked in `GATES.md`; same bounded-scope limitation as B1. |
| E1 | Pinned complete core source/bridge review with findings resolved or carried | HOLD. Inventory and many bounded component reviews exist, but the final integrated disposition explicitly leaves E1 open. P2 marker-scan issues and cross-bridge payload findings remain among carried items. |
| V1 | Julia package suite on current integrated candidate | Prior checked status is superseded by current 436-pass/3-fail report. HOLD until semantic fixes, regenerated page, and rerun evidence are pinned. |
| V2 | Current Julia documentation source build | Recorded checked at source time, but generated status page is now stale after current semantic corrections. Rebuild/review remains needed before final closure. No live rendered check was made here. |
| V3 | Final R package, bridge, docs/status synchronization, reports, Rose and hosted-check reconciliation | HOLD. R CMD check and focused bridge/parity evidence exist; no single whole-gate pass follows from those component results. Exact final docs/source synchronization, generated Julia page, broad bridge findings, and remaining panel/signoff state must close. Hosted CI was not dispatched in this lane. |
| V4 | Stop before submission/release/tag | Met as a stop condition. This does not mean V1-V3 or the overall programme is complete. |

The estimated arc time boxes are workstream targets, not completion evidence. The work exceeded the original short arc sequence and was adapted into many bounded repairs/reviews. The record preserves those extensions. The actual lane reports escalate difficult mathematical/numerical questions to Sol/Astra reviewers; my Luna-medium remit here was mechanical reconciliation and wording-to-evidence matching. No new numerical judgment was made from pass counts alone. Parent confirms final-panel Luna/Astra routing is still pending; this report is not author approval or final-panel signoff.

## Disposition

- **Source claim audit:** conditional PASS on the exact 24-file Julia source inventory and the route-specific public claims/field meanings listed above; scope does not include a global bridge pass.
- **Rendered/public surface:** HOLD pending refreshed generated status page and exact local render review; live-site state was not checked here.
- **Overall programme:** HOLD with A2, E1, V1, V2 refresh, and V3 outstanding. B1/C1/C2/D1 checked within their stated cells. V4 stop condition met.
- **Release boundary:** no 0.9.0 status change, new CRAN submission, tag, registry action, or GPU claim. Root records the existing 0.9.0 CRAN submission as a separate owner-managed lane.

## Provenance

Read-only inputs included the approved Julia arc plan; GATES.md (status only); the Julia final integrated source disposition and JSON inventory; Julia capability/debt/status/README and relevant public guides; the FA campaign and comparator receipts; GLLVM current-source replay receipt; and R README, manual, current-limits, multivariate, and genetic-GLLVM articles. Scratch inventory: `/private/tmp/hsq-final-claims-reconcile-20260930-inventory.md`.

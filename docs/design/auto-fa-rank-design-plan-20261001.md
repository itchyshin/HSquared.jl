🎯 GOAL

Solo platform: Codex.
Deliverable: a reviewed, bounded automatic FA-rank contract and the validation plan required before implementation.
HEADLINE: make the meaning of rank, the comparison rule and failed-candidate behavior explicit.
IN PARALLEL: refresh the fixed-rank engine contract and inspect selection references under separate read-only ownership.
DEFER: implementation, simulation, public grammar activation, protected GLLVM lanes, GPU, releases, tags, submissions and covered-status changes.
DISCIPLINE: verify equations against source and independent review; compute is not required; close when every contract decision has an owner and evidence.

# Automatic FA-rank design and coordination plan

Status: completed design-only arc, 2026-10-01. Shinichi approved execution in this chat and explicitly requested Ultra Plan with Unlazy. This approval covers the design outputs and their review; implementation and simulation remain outside scope. Initial estimate: 60 to 90 minutes. Three producer children and a separate three-person completion panel each stay within the Ultra Plan batch ceiling; the independent panel repeats neither implementation nor compute. V3 closure is complete; the design arc now runs against base `28f90e09` in the existing isolated checkout.

## Destination

Produce `docs/design/auto-fa-rank-contract.md` and `docs/design/auto-fa-rank-validation-plan.md`, independently reviewed for the complete-response, pedigree, Gaussian FA model. Fix the rank range, objective and penalty, tie rule, candidate refusals, retry budget, returned attempt table, uncertainty wording and acceptance tests. Preserve explicit fixed-rank fitting. If a criterion cannot be justified, record the decision and its missing evidence instead of silently choosing one.

## Decisions settled by the design arc

V3 has ordinary Julia and R landing evidence. Candidate `365f173f`, Julia implementation merge `829e86ce`, closure merge `570f49ba`, R merge `e82f5c95`; live receipts are under `docs/dev-log/check-log.d/2026-10-01-v3-live-refresh/`. Scientific scope remains experimental and public count seven.

The useful sibling pattern is a selected fit plus every attempted rank and its status. GLLVModels.jl main `7b2f1554` retains candidates that are unconverged by default; that policy is a question for this model, not an inherited default. Its site-count BIC and Binomial ridge are not HSquared evidence. gllvmTMB PR #1337 landed only into its protected implementation branch; no edits or messages to that lane are authorized.

The reviewed contract compares only K=0 diagonal genetic covariance and K=1 shared genetic factor in the T4 complete Gaussian pedigree cell. The diagonal candidate needs a new internal floor-matched route; public fixed-rank fitting keeps its meaning. K=0 permits positive genetic variance. K=2 is excluded by the covariance dimension screen, and zero genetic signal is a separate boundary witness.

The proposed criterion is explicitly experimental `reml_aic_covariance`, with common fixed design, nominal covariance parameter counts 14 and 18, and signed difference D=C1-C0. Both candidates must be eligible and converged. Exact/numerical ties choose K0; failures produce an unavailable selection with a full attempt table. Detailed decisions and implementation obligations are in [the contract](auto-fa-rank-contract.md). Final independent judgments and their carried limits are retained in [the completion receipt](../dev-log/source-review/2026-10-01-auto-fa-rank-design-independent.md).

| Ticket | Disposition | Evidence |
| --- | --- | --- |
| R0 | K0 uses an internal diagonal route with the same floor as FA; zero-column public FA remains refused. | Engine scout and contract model section. |
| C0 | Common-X REML with nominal covariance penalty is a bounded heuristic; ML/BIC and calibrated rank claims are deferred. | Method recommendation, primary references and contract criterion section. |
| F0 | Both ranks require eligible converged results; one FA retry within four total starts; all failures remain visible. | Contract eligibility and returned table. |
| B0 | Floor/start flags and conditional uncertainty are visible; future bridge must retain every attempt and reason. | Contract schema and user review. |

The design records exact scope and failure outcomes. Implementation must still specify and test the internal floor mapping, retry initializer, numerical identification check and cancellation transport before real selection fits.

## Out of scope

Poisson genetic GLLVM automatic ranks, broader traits, genomic/default routes, missing responses, general FA identifiability, inference calibration, GPU execution, automatic public R activation and all releases/submissions are excluded. No new campaign or rerun of the frozen 200-seed FA primary belongs to this design arc.

## Symbolic alignment required first

For identical observed records, fixed design and pedigree precision across candidates:

`Y = XB + ZU + E`. In the engine's record-major order, `vec(U') ~ N(0, A ⊗ G_K)` and `vec(E') ~ N(0, I ⊗ R)`. The contract fixes this ordering and the full design matrices.

`G_K = L_K L_K' + diag(psi)` and R is unstructured. The shared component has K axes; psi remains genetic trait-specific variance. Candidate count after fixing rotational redundancy is `q_G(K) = T K - K(K-1)/2 + T`; `q_R = T(T+1)/2`. At T=4, q_G is 4, 8 and 11 for K=0,1,2, against 10 independent entries in G. This dimension calculation is necessary but does not prove identifiability of either genetic or residual covariance. The K=0 to K=1 limit is singular: loadings vanish and their local directions are not identified at the smaller model. Ordinary likelihood-ratio or information-criterion regularity must not be assumed at that boundary. Pedigree information must distinguish genetic G from residual R; identity or weakly informative relationships can defeat that separation. Shared constants and fixed-effect parameter treatment must be shown before comparing criteria. Do not use the number of pedigree members as an effective independent sample size without justification.

| Symbol | Planned engine contract | Future data-generating draw | Future extractor | Truth |
| --- | --- | --- | --- | --- |
| XB | same trait-intercept design for all ranks | declared B and common X | fitted trait coefficients | fixed B |
| L_K L_K' | rank candidate under review | ordinary factor draw with A | loadings and reconstructed G | declared covariance and K |
| diag(psi) | positive genetic uniqueness, including diagonal comparator | independent genetic trait effects with A | genetic_uniqueness | declared psi |
| R | same unstructured residual model at every K | residual multivariate normal | residual_covariance | declared R |
| selected K | rule and eligibility to be frozen | retained true-rank and boundary labels | full attempt table and criterion difference | rank label, without biological certainty |

## Bounded work sequence

| Step | Member and planned model/effort | Dispatch | Time | Output and dependency |
| --- | --- | --- | --- | --- |
| 1. Recon | Shannon; Luna medium | native/explicit, fresh | 10 min | Verify exact main, branch drift, owned paths and the existing receipts; no protected-lane edits. |
| 2. Model contract | Kirkpatrick/Noether lens; Sol high | native/explicit, fresh | 25 min | Rank range and likelihood/penalty derivation. Sol is warranted because wrong rank meaning or likelihood changes every later result. Depends on step 1. |
| 3. User contract | Hopper/Pat lens; Luna medium | native/explicit, fresh | 15 min | Attempt-table schema, candidate rejection/retry policy, fixed-rank escape and reader examples. May inspect current fixed-rank payload in parallel with step 2; freezes after its derivation. |
| 4. Consolidate | Ada, current owner | local | 15 min | Write both design artifacts, include all decisions and a future pre-run proposal. No implementation. |
| 5. Verify and reconcile | Fresh independent method, user and mechanical panel: one Sol high, two Luna medium | native/explicit, separate completion batch | 15 to 25 min | Check equations, failure table, scope and planned-vs-actual record; after-task report. |

SCOUT SUITABILITY: yes, the exact-ref/ownership refresh is mechanical.
Fan-out limit: at most three fresh children and one Sol judgment child per batch. Production and independent completion are separate batches; this arc runs no additional agent tree. Record actual models and evidence rather than inferring tiers from lens names.

## Required acceptance content

The rank contract must define exactly which candidates were requested and attempted; the likelihood method, normalisation and penalty; exact and near-tie rules; eligibility versus convergence; finite-value and positive-definiteness checks; model nesting checks; retry budget and starts; floor/boundary flags; and all-rejected behavior with the complete attempt table. A fixed rank must remain available.

The validation plan must name deterministic criterion/parameter-count references, true rank-zero diagonal and separately no-signal cases, weak and separated factors, upper-bound selection, exact and near ties, trait permutation, unit changes, ordinary and alternative starts, runtime/platform stability, invalid-input and unsupported-scope refusals, and selected-rank/R-Julia parity. Retain every failed, interrupted, unconverged and unattempted outcome. Inference is conditional on the selected rank; rank selection is not proof of biological dimension.

No numerical pass threshold is assigned after viewing results. Each proposed future recovery threshold needs a scientific purpose, sample-size ladder and denominator rule before implementation. This arc writes the plan only. A later fit or simulation gets an estimate before launch; above three hours requires a pre-run result and owner approval. Serious CPU work belongs on Totoro or DRAC with launch thread caps, never GitHub Actions.

## Prior-work and coordination receipt

The current task inspected `git status`, `git log --all`/branch refs, worktree inventory and stashes; discovered the already merged closure rather than rebuilding it. Brain search preceded sibling scouts and returned no task-specific automatic-rank note. This repository's existing follow-on design was read before planning. Fresh GLLVM and protected R-lane receipts are retained with exact refs; future work reuses them and refreshes only material drift. No protected checkout was changed.

## What the brain already knows

The R twin owns public language, Julia owns engine reality. Existing FA evidence is fixed-rank T4/K1 and experimental. The LOAD-FIRST calibration-first pointer is older than the explicit bounded task; no broad calibration is added here.

## What Shinichi told us

Finish only owed V3 closure; plan the automatic-rank design and coordination arc. Preserve protected/untracked work, covered status and release/GPU boundaries. Do not launch simulations above three hours without pre-run evidence and approval.

## What the team raised

Actual Rose/Grace review found the final independent hosted-landing receipt missing despite technical landing evidence. This task retains the live receipts and final audit. The two actual Luna scouts found GLLVM's selector is on Julia main while the protected R auto-d work remains off main. Actual method, engine and user scouts now have retained producer receipts. Their recommendations differ on near-floor eligibility; the owner recommends eligible-but-flagged under the experimental rule, with independent method and user review required for closure.

## Ada's recommendation

Complete the approved design-only arc with the bounded contract and predeclared validation plan. Keep explicit fixed-rank fitting intact. The next implementation proposal must resolve the named numerical obligations and pass independent deterministic references before fitting.

## Decisions locked

Current fixed-rank status and seven covered rows remain unchanged. No protected sibling edits, campaign, GPU, external messages, push, merge, tag or submission is authorized by this proposed arc.

## Remaining evidence

The design tickets have recommended dispositions in the contract. The independent completion panel accepted the final files for V0 only; all five design acceptance gates are met. Selection performance, numerical tolerance feasibility and future implementation details remain unmeasured; this design arc supplies their acceptance obligations and tests.

## Approved envelope for this design arc

Approved in chat: scoped design-file edits, read-only source/reference searches, routine structural/prose checks, local checkpoints and commits. Remote authority: none. Stop before production code, fits/simulations, public API/status changes, external messages, protected-lane work or publication. Execute the design-only arc to its acceptance gates.


## Active execution record

Unlazy owns the acceptance ledger at `.unlazy/auto-fa-rank-design-20261001/`.
The approved goal and checkpoint are on disk there. The existing isolated
worktree is reused; a second launcher or persistent permission hook is unnecessary.
Actual workers: engine-contract scout (Luna medium), user-contract scout
(Luna medium), method recommendation (Sol high). Each owns one report under
`docs/dev-log/scout/2026-10-01-auto-fa-rank-design/`. The producer-stage parent lease excluded those files. After every scout finished, the owner renewed a scoped consolidation lease including them. The one method child needs Sol because likelihood, rank meaning and
boundary judgments govern every downstream result. A fresh completion panel has been dispatched: independent method (Sol high), user/claim review (Luna medium) and mechanical review (Luna medium). No numerical run is scheduled in this arc. Final receipts and acceptance results are linked from [the after-task report](../dev-log/after-task/2026-10-01-auto-fa-rank-design.md).

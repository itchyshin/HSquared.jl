🎯 GOAL

Solo platform: Codex.
Deliverable: a reviewed, bounded automatic FA-rank contract and the validation plan required before implementation.
HEADLINE: make the meaning of rank, the comparison rule and failed-candidate behavior explicit.
IN PARALLEL: refresh the fixed-rank engine contract and inspect selection references under separate read-only ownership.
DEFER: implementation, simulation, public grammar activation, protected GLLVM lanes, GPU, releases, tags, submissions and covered-status changes.
DISCIPLINE: verify equations against source and independent review; compute is not required; close when every contract decision has an owner and evidence.

# Automatic FA-rank design and coordination plan

Status: proposed design-only arc. This file is the requested next plan, not authorization to implement or simulate. Estimated duration: 60 to 90 minutes, one session, three fresh bounded reviewers at most. The current closure work did not start this arc.

## Destination

Produce `docs/design/auto-fa-rank-contract.md` and `docs/design/auto-fa-rank-validation-plan.md`, independently reviewed for the complete-response, pedigree, Gaussian FA model. Fix the rank range, objective and penalty, tie rule, candidate refusals, retry budget, returned attempt table, uncertainty wording and acceptance tests. Preserve explicit fixed-rank fitting. If a criterion cannot be justified, record the decision and its missing evidence instead of silently choosing one.

## Decisions so far

V3 has ordinary Julia and R landing evidence. Candidate `365f173f`, Julia implementation merge `829e86ce`, closure merge `570f49ba`, R merge `e82f5c95`; live receipts are under `docs/dev-log/check-log.d/2026-10-01-v3-live-refresh/`. Scientific scope remains experimental and public count seven.

The useful sibling pattern is a selected fit plus every attempted rank and its status. GLLVModels.jl main `7b2f1554` retains candidates that are unconverged by default; that policy is a question for this model, not an inherited default. Its site-count BIC and Binomial ridge are not HSquared evidence. gllvmTMB PR #1337 landed only into its protected implementation branch; no edits or messages to that lane are authorized.

Start with the existing T=4 Gaussian pedigree cell. Do not claim a meaningful automatic selector over the singleton existing rank set {1}. Proposed comparison is diagonal genetic covariance versus one shared genetic factor, labelled K=0 and K=1 only if the engine contract supports that distinction. Rank zero with positive uniqueness is not zero genetic variance. A no-genetic-signal case is a separate boundary witness. Rank two is excluded from this starting cell by the generic covariance parameter-count check below. Extending traits or ranks requires a separate scope decision.

Proposed exact tie policy: choose the smaller admissible rank; numerical near-ties must use a separately declared tolerance and return the criterion difference. Boundary and uniqueness-floor flags must remain visible. These proposals require domain review before freezing.

## Not yet specified

| Ticket | Kind and owner | Decision to resolve | Output |
| --- | --- | --- | --- |
| R0 | research; Kirkpatrick + Noether | Is a zero-column factor representation admitted, or must the diagonal model have its own engine route? | rank-zero contract and source map |
| C0 | research; Fisher + Gauss | Which same-data likelihood and penalty are defensible for selecting genetic covariance rank? Compare marginal ML criteria and common-fixed-design REML criteria; justify every parameter count. | criterion derivation with primary references |
| F0 | decide with owner recommendation; Fisher + Pat | Should all unconverged candidates be excluded, or may a flagged provisional choice be returned? What happens when no candidate is eligible? | failure and return table |
| B0 | research; Kirkpatrick + Hopper/Boole/Emmy | How do boundary/floor cases and conditional uncertainty appear in Julia and the future R payload? | schema and caveat examples |

The route to a design artifact is known. The route to production code is not yet specified; this design arc ends with a reviewed decision map.

## Out of scope

Poisson genetic GLLVM automatic ranks, broader traits, genomic/default routes, missing responses, general FA identifiability, inference calibration, GPU execution, automatic public R activation and all releases/submissions are excluded. No new campaign or rerun of the frozen 200-seed FA primary belongs to this design arc.

## Symbolic alignment required first

For identical observed records, fixed design and pedigree precision across candidates:

`Y = XB + ZU + E`, `vec(U) ~ N(0, G_K ⊗ A)`, `vec(E) ~ N(0, R ⊗ I)`.

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
| 5. Verify and reconcile | Rose/Fisher lenses, independent review | reuse existing bounded reviewer or one reviewed completion dispatch | 15 to 25 min | Check equations, failure table, scope and planned-vs-actual record; after-task report. |

SCOUT SUITABILITY: yes, the exact-ref/ownership refresh is mechanical.
Fan-out limit: at most three fresh children in one batch, at most one Sol judgment child. Record actual models and evidence rather than inferring tiers from lens names.

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

Actual Rose/Grace review found the final independent hosted-landing receipt missing despite technical landing evidence. This task retains the live receipts and final audit. The two actual Luna scouts found GLLVM's selector is on Julia main while the protected R auto-d work remains off main. Proposed Kirkpatrick and Fisher design lenses have not yet reviewed a selection criterion; do not attribute a criterion decision to them.

## Ada's recommendation

Approve a design-only arc with the two-rank diagonal-versus-one-factor question and an explicit model-specific criterion review. Keep the current fixed-rank route unchanged. Settle the criterion and failure policy before code or simulation.

## Decisions locked

Current fixed-rank status and seven covered rows remain unchanged. No protected sibling edits, campaign, GPU, external messages, push, merge, tag or submission is authorized by this proposed arc.

## Questions still open

The tickets R0/C0/F0/B0 are method decisions for the design arc. The user need not decide equations or worker models now. The arc must bring back a concrete recommended contract and any choice requiring the user's scientific preference.

## Approval envelope for the next arc

After explicit approval: scoped design-file edits, read-only source/reference searches, routine structural/prose checks, local checkpoints and commits. Remote authority: none. Stop before production code, fits/simulations, public API/status changes, external messages, protected-lane work or publication. Next action: approve this design-only arc.

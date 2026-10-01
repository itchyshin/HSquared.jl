# Automatic FA-rank selection: proposed user contract

Status: historical user-contract recommendation, superseded by the controlling [bounded automatic genetic FA-rank contract](../../../design/auto-fa-rank-contract.md). No selector is implemented or fitted. Current fitted support is fixed-rank Gaussian FA in an experimental validation-scale cell; automatic rank selection is future work. `fit_multivariate_reml` accepts explicit `genetic_structure` and `rank`, with factor-analytic rank constrained to 1 through the number of traits (`src/multivariate.jl:936-948`, `src/multivariate.jl:1010-1021`). Its `genetic_rank` reports the requested factor count, not an estimated covariance rank (`src/multivariate.jl:965-969`). The bounded experimental R fixed-rank expert-control route is present at immutable merge `e82f5c95e514028a7126fdd667c4ac7a840c9e6b` (`hsquared@e82f5c95:R/julia-bridge.R:2976-2983,3043-3114,5863-5975`). No automatic selector exists in either route.

## Final disposition: controlling contract

The recommendations below are retained as historical context. The final contract controls any future implementation and overrides conflicting prose or examples later in this note.

| Topic | Final controlling disposition |
| --- | --- |
| Result status | Use `selected`, `unavailable`, or `unsupported_input`. `unavailable` returns no selected rank or fit, a reason, and retained results. |
| Required candidates | Both K=0 and K=1 must be eligible before selecting either rank. A sole successful candidate never wins by default. |
| Candidate ledger | `candidate_summary` has one row for each requested rank, including ranks not attempted. `attempts` contains actual starts only. Do not create synthetic optimizer-start rows for unattempted ranks. |
| Criterion | Use the frozen experimental `reml_aic_covariance`, with `q_G(0)=4`, `q_G(1)=8`, `q_R=10`, and penalties 28 and 36. Report `D=C_1-C_0=8-2*(ell_1-ell_0)`, both scores, q, and penalties. This rule is experimental and does not establish biological rank or calibrated selection. |
| Numerical agreement and ties | Require returned log likelihood to agree with same-covariance reevaluation within `1e-8` absolute units. Use `tau=1e-6` criterion units. If `abs(D)<=tau`, select K=0 and set `near_tie=true`; exact ties are included. |
| Starts and retries | One diagonal start. FA uses its default and balanced starts, with at most one extra deterministic nonzero-loading retry only under the final contract's failure, convergence, or non-nesting conditions, including a better finite unconverged FA result than the best eligible converged start. Total maximum is four starts, unequally allocated by design. |
| Floor and boundary | Near-floor candidates may remain eligible and must set `boundary_sensitive=true`. At or numerically below the shared floor is an admissibility failure. The public fixed-rank diagonal route remains unchanged; K=0's automatic candidate uses the internal floor-matched fit. |
| Uncertainty and fit | Return a selected fit only when both candidates are eligible. Uncertainty is conditional on selected rank. Retain all attempted and preflight-unattempted outcomes with their distinct semantics. |
| Interruption | Propagate cancellation promptly while preserving the partial attempt ledger and marking interrupted or unattempted rows. |

These dispositions come from the frozen final contract, including its exact score, tie band, eligibility, retries, retained-row semantics, and interruption obligation (`docs/design/auto-fa-rank-contract.md:30-68,70-90,94-98`).

## Intended scope

The first automatic selector should compare only two genetic covariance candidates for the existing complete-response, four-trait Gaussian pedigree model with trait intercepts and the same unstructured residual covariance in both candidates:

| Candidate label | Julia fit represented | Meaning |
| --- | --- | --- |
| `K = 0` | `genetic_structure = :diagonal` | Trait-specific positive genetic variances with no shared factor. This is not a zero-genetic-variance model. |
| `K = 1` | `genetic_structure = :factor_analytic, rank = 1` | One shared genetic factor plus positive trait-specific genetic uniquenesses. |

The engine currently rejects `rank = 0` for `:factor_analytic`; therefore K=0 must use the diagonal structure, not a zero-column FA workaround (`src/multivariate.jl:693-704`). A no-genetic-signal case is a distinct boundary condition and should be represented separately in validation. The T=4, K=2 candidate is outside this starting comparison. Other trait counts, ranks, missing responses, genomic relationships, non-Gaussian models, repeatability models, and non-intercept fixed-effect designs are outside this selector's eligibility fence. The underlying fixed-rank route stays available as the explicit opt-out.

This boundary follows the design plan's warning that comparing a singleton existing rank set is not selection, and that rank zero means diagonal covariance when uniquenesses are positive (`docs/design/auto-fa-rank-design-plan-20261001.md:22-26,41-57`).

## Result shape

Return the selected fit and a complete attempt ledger together. A proposed Julia shape is:

```text
selection = (
  status,                 # selected | no_eligible_candidate | preflight_refusal
  selected_rank,          # 0, 1, or nothing
  criterion = (name, value, penalty, status),
  criterion_difference,   # selected/runner-up difference when defined
  near_tie,
  attempts,                # one row per rank and start, including failures
  uncertainty_scope,       # conditional_on_selected_rank
)
```

Each `attempts` row should contain at least:

| Field | Purpose |
| --- | --- |
| `rank`, `genetic_structure`, `start_id`, `retry_index` | Identify the requested model and deterministic start. |
| `attempted`, `status`, `reason` | Separate preflight exclusion from an optimizer attempt, and state why it failed or was excluded. |
| `converged`, `iterations`, `optimizer_status` | Report optimizer termination independently of eligibility. |
| `criterion`, `criterion_value`, `loglik` | Preserve the comparison evidence when finite and defined. |
| `finite_objective`, `finite_genetic_covariance`, `finite_residual_covariance` | Make finite-value checks explicit. |
| `genetic_covariance_pd`, `residual_covariance_pd` | Record covariance checks. K=0 and K=1 require admissible genetic covariance; the shared residual covariance must be positive definite. |
| `minimum_uniqueness`, `uniqueness_floor_distance`, `near_uniqueness_floor` | Expose the FA uniqueness floor rather than hiding near-boundary fits. Use `nothing` for K=0. |
| `boundary_flags`, `eligible`, `selected` | Show boundary or floor concerns, final eligibility, and the selected row. |

The top-level criterion name and value must be repeated per row only when that candidate has a valid value. Use a missing value plus a reason for failures. Do not encode failed attempts as zero, drop them during conversion to a data frame, or replace the ledger with an exception. Current FA diagnostics already demonstrate per-start status and floor-distance fields, but current fit selection can fall back to the best finite unconverged fit if no start converged (`src/multivariate.jl:761-768,1137-1165`). That behavior is not a suitable automatic-selection rule without a separate decision.

## Eligibility, convergence, and failure behavior

Eligibility is not the same as convergence. A row may have a finite objective and positive-definite residual covariance but still be ineligible because the optimizer did not converge, a covariance check failed, or the fitted FA uniqueness is at or too near the absolute floor. Conversely, `converged = true` alone does not make a candidate eligible. The selector should report each check and its reason.

Recommended starting policy for review: select only a converged candidate with finite objective and covariance estimates, an admissible genetic covariance, positive-definite residual covariance, and no unresolved floor or boundary flag. Record finite but unconverged candidates in the ledger as ineligible. Record singular, nonfinite, or optimizer-failed attempts with explicit statuses. Treat a floor- or boundary-flagged result as visible but ineligible until the model and selection criterion review decides otherwise. The existing FA floor is `1e-4` in absolute trait-specific variance units and is explicitly not scale-equivariant (`src/multivariate.jl:941-948`); its flag and distance must therefore be visible in returned results.

If neither rank has an eligible candidate, return `status = no_eligible_candidate`, `selected_rank = nothing`, no selected fit, and the full attempt table. If the input fails the selector's scope checks before fitting, return or raise a structured preflight refusal that names the unsupported condition. A bare optimizer error that loses attempts is not an acceptable user-facing result.

## Starts and retry budget

Use a fixed, deterministic, bounded start budget per candidate. Proposed ceiling: two starts per rank, one standard start and one declared alternative, for at most four optimizer starts total in this two-candidate cell. Report every start and do not add retries opportunistically until one rank wins. A retry must retain the same data, model, residual structure, and criterion. If a future implementation cannot define a reproducible alternative start for the diagonal candidate, use its documented single start and report the unequal budget explicitly rather than suggesting equal robustness.

This budget is a proposal, not evidence of global optimization. The current fixed-rank FA fitter uses standard and balanced starts by default, or one user-controlled start when `initial` is supplied; its documentation describes this as a decomposition sensitivity check, not broad multistart protection (`src/multivariate.jl:950-963`).

## Ties and criterion status

The model-selection criterion remains provisional until the method review recommends the same-data ML or common-fixed-design REML comparison and justifies the penalty and parameter counts. The current design plan explicitly leaves that choice open and notes that the K=0 to K=1 limit is singular, so ordinary likelihood-ratio or information-criterion regularity cannot be assumed (`docs/design/auto-fa-rank-design-plan-20261001.md:32-35,43-49`). Do not borrow GLLVM BIC penalties or another package's selector defaults as HSquared evidence (`docs/design/auto-fa-rank-design-plan-20261001.md:20-26`).

Once a criterion and numerical tolerance have been justified:

1. For an exact tie under the recorded comparison precision, select the smaller eligible rank.
2. For a near tie, apply a separately declared tolerance on the criterion difference, report that difference and set `near_tie = true`. The numeric tolerance is intentionally unresolved here.
3. Preserve both candidate rows and their values. A near tie is not evidence that the biological dimensions are known or that the candidates are equivalent.

No result should call the selected rank “the true rank.” It is the candidate preferred by the declared rule among eligible models.

## Uncertainty wording

Any standard error, interval, or derived uncertainty produced after selection must state that it is conditional on the selected rank. It does not include uncertainty from choosing the rank. The selector itself should not imply calibrated rank probabilities or biological certainty.

Suggested wording: “The selected rank is the candidate preferred by this rule among the eligible models. This is a model-selection result, not proof of the biological number of genetic dimensions. Any interval or standard error is conditional on the selected rank and does not include uncertainty from selecting the rank.”

When candidates are near tied, add: “The leading candidates were close under the stated criterion; see the attempt table for both results.”

## Small user examples (historical, superseded where noted)

These examples illustrate result behavior only. Values are placeholders, not a chosen criterion or tolerance.

If both candidates have equal eligible criterion values, return K=0 as the selected smaller rank, retain both rows, and set `near_tie = true`. Record the exact tie and tie rule used.

**Superseded example:** If K=1 has the lower value but lies at the uniqueness floor, mark that attempt `eligible = false`, set its floor flag and reason, and select K=0 if K=0 is eligible. Do not hide the failed K=1 candidate because it has the numerically best criterion. The final contract allows a near-floor candidate to remain eligible with `boundary_sensitive = true`, and requires both ranks eligible before selecting; a sole eligible K=0 does not win by default.

If K=0 is non-converged and K=1 has a non-finite objective, return `status = no_eligible_candidate`, `selected_rank = nothing`, and both attempts with their distinct reasons. The caller can inspect the ledger and decide whether to revise the fit setup; there is no misleading selected fit and no bare error that discards the attempt history. The final status token is `unavailable`, with no selected rank or fit, and the candidate summary also records any requested rank that was not attempted.

## Fixed-rank compatibility and future R/Julia mapping

Automatic selection must be an explicit opt-in. Existing calls with a fixed `genetic_structure` and `rank` must retain their meanings and result fields. Do not reinterpret omitted `rank` as automatic selection. For the future R interface, an explicit automatic selector control must be distinct from the existing fixed-rank argument, and unsupported combinations must fail clearly.

There is no current R automatic-rank contract. The exact landed R merge `e82f5c95e514028a7126fdd667c4ac7a840c9e6b` contains a bounded experimental fixed-rank FA bridge: its transport passes `rank` only for `factor_analytic` and returns the requested rank, uniqueness, and per-start diagnostics (`hsquared@e82f5c95:R/julia-bridge.R:2976-2983,3043-3114`); its validator and route checks restrict that path to rank one and the complete Gaussian pedigree T4 cell (`hsquared@e82f5c95:R/julia-bridge.R:5863-5975`). The retained R design says the ordinary `cov = fa(K = ...)` formula grammar remains unsupported (`hsquared/docs/design/54-fa-grammar-freeze.md:30-38,99-103`). Preserve this fixed-rank route. Automatic selection and its attempt ledger need a separately reviewed future bridge extension. A generic bridge compatibility table says raw FA loadings are not a current payload contract (`docs/design/12-bridge-compatibility.md:42-43,88-89`); this does not remove the bounded fixed-rank expert-control route. The local sibling checkout was on an older July branch with extensive dirty state, and its validator differed from the exact landed merge. I therefore used the immutable merge commit as the source for the existing R bridge and did not modify the sibling checkout. The mapping below is future selector design only, not a proposed API activation:

| Julia engine result | Future R representation | Parity requirement |
| --- | --- | --- |
| `selection.status` | diagnostics selection status | Same value and refusal meaning. |
| `selection.selected_rank` | diagnostics selected rank | Same integer or missing value. |
| `selection.criterion` and difference | named diagnostics fields | Same criterion name, value, penalty metadata, and difference. |
| `selection.near_tie` | diagnostics near-tie flag | Same boolean and tolerance metadata. |
| `selection.attempts` | attempt data frame | Preserve every attempted row, reason, convergence, covariance checks, floor/boundary flags, criterion values, and selected marker. |
| `selection.uncertainty_scope` | diagnostics uncertainty scope | State `conditional_on_selected_rank`. |

Use plain data across the bridge. Do not send Julia structs or expose loading matrices as part of this selector contract without a separately reviewed bridge design. Before any R grammar or payload changes, both twins need matching fixtures and parity checks. The landed R fixed-rank adapter already transports per-start diagnostics as aligned plain fields, which is a useful shape precedent but not an automatic-selector schema (`hsquared@e82f5c95:R/julia-bridge.R:3091-3114`). Future selector parity must retain failed rows, status, reasons, criterion values, and boundary flags in the same order and with matching missing-value semantics. Preserve the bounded fixed-rank bridge during any later extension.

## Compatibility limits and open decisions

This note recommends a user-facing ledger and bounded failure behavior. It does not settle the statistical criterion, a numeric near-tie tolerance, the exact floor-exclusion threshold, or whether a future boundary candidate may ever be eligible. Those decisions require the method recommendation and validation plan before implementation. No source, R bridge, API grammar, capability-status row, or validation status changes follow from this proposal.

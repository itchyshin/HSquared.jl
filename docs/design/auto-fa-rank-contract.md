# Bounded automatic genetic FA-rank contract

Status: design frozen for future implementation review, 2026-10-01. No automatic selector is implemented or validated by this document. The current fixed-rank Gaussian FA route remains experimental, and public covered count stays seven. Approved scope and execution record: [design arc](auto-fa-rank-design-plan-20261001.md).

## Model and candidates

The first selector is explicit opt-in and compares only shared genetic factor counts `K={0,1}` for four complete Gaussian traits, pedigree relationships, one record per observed animal, trait intercepts and an unstructured residual covariance. The same records, labels, units, X, Z and Ainv are used for both candidates. Explicit fixed-rank calls keep their current meaning; omission of rank does not invoke selection. Missing responses, other trait counts/ranks, other fixed effects, genomic/custom relationships, repeatability and non-Gaussian models are refused before fitting. K=2 is outside this design.

Write `Y=XB+ZU+E`. For the engine's record-major order, `y=vec(Y')`, `u=vec(U')`, `X_full=X⊗I_4`, `Z_full=Z⊗I_4`,

`Cov(u)=A⊗G_K`, `Cov(vec(E'))=I_n⊗R`,

`V_K=Z_full(A⊗G_K)Z_full'+I_n⊗R`,

`G_K=L_K L_K'+diag(psi)`, `psi_i=c+exp(theta_i)`, `c=1e-4` in squared units of trait i.

| Candidate | Shape and future implementation mapping | Genetic parameters |
| --- | --- | ---: |
| K=0 | Diagonal G with positive trait-specific genetic variances. Selector-internal floor-matched diagonal fit; no loading columns. | 4 |
| K=1 | Existing FA shape with four loadings and four positive uniquenesses; rank-one shared component. | 8 |

K measures shared factors, not the rank of G, which is positive definite when uniquenesses are positive. K=0 still permits genetic variance. Zero genetic signal is a separate boundary case, outside the fitted strictly-positive family.

The existing public diagonal route uses `exp(theta)` without c, while FA uses `c+exp(theta)`. A direct call to the current diagonal fitter is therefore not a floor-matched nested comparator. Future implementation must add the matched internal candidate without changing the public fixed-rank diagonal route, the FA rank guard or the existing floor. It must retain ten identical residual log-Cholesky coordinates in both candidates. Exact source findings: [engine review](../dev-log/scout/2026-10-01-auto-fa-rank-design/engine-contract.md), `src/multivariate.jl:660-723,844-856,1010-1055` at base `28f90e09`.

Identifiability is a property of the covariance and record design. With one record per animal, Z=I and A=I, only G+R is identifiable. That design is refused for automatic selection; its likelihood is retained as a deterministic negative witness. The identification screen must compare genetic and residual kernels on the REML contrast space: use Q with Q'X_full=0 and inspect Q'V_K Q, not raw A versus I alone. Exact or numerically unresolved proportional kernels on that space must refuse selection with a design-identification reason. For intercept-only one-record data, the informative-looking half-sib matrix A=(1-rho)I+rho*11' becomes (1-rho)I after removing the intercept direction; G and R remain confounded. This is a second deterministic refusal witness. Relatedness alone does not establish good finite-sample information. The future pre-run must freeze a numerical kernel-rank check and its unit convention before real selection fits; no numerical conditioning threshold is claimed validated here.

For general K the nominal genetic dimension is `4K-K(K-1)/2+4`. At K=2 it exceeds the ten-dimensional ambient symmetric G space. This dimension screen does not prove identifiability at K=1. At L=0 the derivative of LL' is zero; diagonal-to-FA nesting is singular, so the score below is not a regular four-df likelihood-ratio test.

## Criterion and numerical comparison

Freeze criterion name `reml_aic_covariance` as an experimental comparison rule on the common fixed-effect contrast space:

`C_K=-2*ell_REML,K+2*q_K`, `q_K=q_G(K)+q_R`, `q_R=10`.

The exact engine REML normalization is

`ell_REML=-0.5*((4n-p_full)*log(2*pi)+logdet(V)+logdet(X_full' V^-1 X_full)+y'P y)`,

`P=V^-1-V^-1 X_full (X_full'V^-1 X_full)^-1 X_full'V^-1`, `p_full=4`.

The four common fixed intercepts are removed by REML and not counted in q. The displayed q values are 14 and 18; penalties are 28 and 36. Counting common intercepts in both penalties would shift scores equally but is not this declared convention. Residual parameters are counted and displayed even though they cancel in the difference.

Define signed difference `D=C_1-C_0=8-2*(ell_1-ell_0)`. Negative D favors K=1. Away from numerical ties, K=1 wins when `2*(ell_1-ell_0)>8`. Report both full C values and D; calculate D directly from the likelihood difference to reduce cancellation. Reevaluate both objectives on the identical input model before ranking.

Freeze numerical tie band `tau=1e-6` criterion units for the initial moderate-scale validation cell. Require each returned loglik to agree with independent same-covariance reevaluation within `1e-8` absolute loglik units before selection. Thus the two objective discrepancies can contribute at most `4e-8` to D under this check, below tau; this discrepancy budget is a check convention, not a proof of all floating-point or optimizer error. If the future pre-run cannot meet it, stop and revise the numerical contract before any campaign. Do not enlarge it after seeing selected ranks.

If `abs(D)<=tau`, choose K=0 and set `near_tie=true`; an exact tie is included. If D is below -tau choose K=1; otherwise choose K=0. Return tau and the objective discrepancies. This band handles numerical ambiguity; it is not an evidence-strength cutoff or a calibrated confidence interval. Weak substantive separation remains visible as the raw D, even when outside tau.

This is a restricted-likelihood covariance comparison with nominal parameter penalties and a singular smaller model. It does not establish consistency, correct biological dimension, marginal predictive optimality or calibrated rank probabilities. Gurka discusses ambiguities in REML model selection; the chosen bounded rule needs its own selection study. [Gurka (2006)](https://www.tandfonline.com/doi/abs/10.1198/000313006X90396).

The mixed-model selection review motivates keeping the likelihood target, covariance boundaries and effective sample size explicit. [Müller, Scealy and Welsh (2013)](https://arxiv.org/abs/1306.2427). BIC is deferred because no pedigree-specific effective sample-size rule has been justified. [Delattre, Lavielle and Poursat (2014)](https://doi.org/10.1214/14-EJS890). The singular boundary also prevents treating D as an ordinary chi-square test. [Self and Liang (1987)](https://doi.org/10.1080/01621459.1987.10478472). These sources motivate limits; none validates this exact selector.

Marginal ML-AIC would require a genuinely fitted ML objective for both candidates. Evaluating ML only at REML estimates is excluded. Conditional AIC, BIC, rank probabilities and automatic criterion switching are outside this first contract.

## Starts, eligibility and failure policy

Fit the floor-matched diagonal candidate from the documented phenotype-based default; fit FA from its existing default and balanced starts. Neither uses generating truth. Permit at most one additional FA retry, only when the initial FA candidate is failed, unconverged or materially non-nested relative to the eligible diagonal candidate, or when a better finite unconverged FA attempt exceeds the best eligible converged FA loglik by more than tau/2. Thus the first budget is one diagonal optimizer start and at most three FA starts, four total. The unequal budget is declared; it does not imply equal optimization robustness.

The additional FA start uses the diagonal covariance as a target with a deterministic, nonzero loading perturbation and corresponding floor-safe uniquenesses, preserving the covariance as closely as feasible. The implementation must write the exact initializer and verify it before fitting. A zero-loading start is excluded because its first-order loading gradient vanishes. No extra retries, changed data, changed floor or hidden warm starts are allowed. Retain the initial attempt even if the retry succeeds.

Each candidate uses its best eligible converged start within this budget. Eligibility requires finite objective and estimates, positive-definite G and R, the shared floor constraint, convergence, matched inputs/normalization and successful objective reevaluation. A better finite unconverged start exceeding the chosen converged loglik by `tau/2` makes selection unavailable after the one allowed retry. Start covariance disagreement and objective ranges remain visible; they do not certify a global optimum.

With a matched floor, the FA family contains the diagonal covariance at L=0. If the best eligible FA loglik remains below the diagonal loglik by more than `tau/2`, flag a nesting/optimization failure and refuse selection. The nested witness is an objective evaluation at L=0, not a successful FA optimization claim.

All tau/2 comparisons above use loglik units because tau is defined in criterion units. Both candidate ranks must be eligible to select a rank. If either fails after its budget, return `selection_status=unavailable`, no selected rank/fit, a reason and all attempts. A sole successful candidate does not win by default. The user may request an explicit fixed rank independently; no silent fallback fit is made.

Near-floor candidates can remain eligible under the experimental score, with `boundary_sensitive=true`. The floor flag is defined for both candidates because both now share c. It is not a claim of uniqueness identification. At or numerically below the bound is an admissibility failure. The fixed absolute floor is unit-dependent; no silent standardization, rescaling or new preprocessing is introduced. Unit-change validation must identify where selection changes because constraints change.

## Returned object and future bridge

Return `selected_fit` alongside plain selection metadata:

| Field | Required meaning |
| --- | --- |
| selection_status, reason | selected, unavailable or unsupported_input, with a clear explanation. |
| requested_ranks, selected_rank | Always requested {0,1}; selected integer or missing. |
| criterion, criterion_status, q, penalties | reml_aic_covariance, experimental; per-candidate counts and scores. |
| criterion_difference, tie_tolerance, near_tie | D=C1-C0, tau and numerical tie flag. |
| records/design/relationship fingerprint | Demonstrate identical model inputs across candidates. |
| candidate_summary | One row per requested rank, including unattempted/failed ranks and eligibility reason. |
| attempts | One row per start/retry, preserving failures and diagnostic fields. |
| boundary_sensitive, start_sensitive | Visible flags derived from retained fits and attempts. |
| uncertainty_scope | conditional_on_selected_rank; no selection-adjusted uncertainty claim. |

Each attempt row records rank, structure, start ID, retry index, attempted status, failure reason, converged, optimizer status/iterations, finite-value/PD checks, returned and reevaluated loglik, q/criterion when defined, per-trait uniqueness and floor distances, near-floor flags, eligibility and selected marker. Failed values are missing with reasons, never zero. The candidate summary separates the chosen within-rank start from the selected rank.

The candidate_summary is the authoritative retained row for every requested rank, including preflight-unattempted ranks. The attempts table contains actual starts only; no synthetic optimizer-start rows are created for unattempted ranks. Preflight refusals mark both candidate-summary rows unattempted with the reason. Interrupts abort promptly and propagate cancellation; the future wrapper/harness must retain its partial attempt ledger and mark interrupted/unattempted rows without pretending to return a completed selection. The interruption mechanism is an implementation acceptance item, not permission to swallow an interrupt.

Proposed function name `select_fa_rank` is reserved for design discussion. It is not an implemented export or approved R grammar. Any future R expert-control payload must preserve the full table, missing reasons, scores, flags and selected covariance/EBVs in original label order. The existing bounded R fixed-rank transport is verified at immutable R merge `e82f5c95`; automatic-selection fields are new work. [User-contract review](../dev-log/scout/2026-10-01-auto-fa-rank-design/user-contract.md).

Suggested summary: “This rule preferred zero shared genetic factors (diagonal genetic covariance) / one shared genetic factor among the two eligible candidates. The attempt table shows the comparison and any boundary or start sensitivity. Uncertainty from the fitted model is conditional on this chosen rank.” Avoid describing K as the true number of biological dimensions.

## Freeze and remaining implementation obligations

The candidate set, model shape, experimental score/parameter convention, signed difference, tie rule, strict two-candidate eligibility, retry ceiling and returned semantics are frozen for this bounded implementation proposal. The numerical acceptance tolerances above are predeclared engineering checks, not measured successes.

The internal diagonal floor, actual retry initializer, numerical kernel-identification screen and interruption transport must be implemented and independently checked before running selection fits. They are specified acceptance obligations with clear failure outcomes, not current capabilities. Broader statistical selection performance, defaults and public promotion require the separate validation plan. No source/test, capability, validation-debt or release change is made here.

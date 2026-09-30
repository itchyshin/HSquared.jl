# VS-4 legacy Ordinal/Gamma objective-label review

Date: 2026-09-30. Reviewer: Noether, independent mathematical challenge. Scope: the legacy Ordinal/Gamma comparator wording only. Artifact owner: this scratch report. No live source, driver, status label, historical receipt, campaign, covered count, or R interface was changed.

## 1. Disposition

**PASS: classify the July comparisons as numerical comparisons of corresponding model parameters under different fitting objectives. HOLD: any claim that they demonstrate same-objective Laplace-ML parity or discharge a same-objective comparator prerequisite.** The present engine integrates fixed effects under a flat measure as well as genetic effects under a normalized Gaussian density. Conventional profiled-fixed-effect Laplace-ML integrates only genetic effects and optimizes the fixed effects. These are generally different objectives and estimators.

The existing `V6-ORDINAL` and `V6-GAMMA` `covered` labels are historical owner approvals and remain unchanged. This review neither demotes those rows nor retroactively supplies a missing equivalence proof. Current documentation can accurately record the historical approval and evidence while explicitly carrying the unresolved same-objective comparator debt. The already recorded R-public count stays 7. This is a mathematical wording disposition, not whole-engine E1 approval.

## 2. Exact pins and inspected spans

Candidate root: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`. Measured HEAD: `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`. Parent-supplied frozen source-tree digest: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`; this review independently remeasured the two relevant file hashes, not the whole-tree digest.

| File | Measured SHA-256 | Relevant spans |
| --- | --- | --- |
| `src/nongaussian.jl` | `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00` | 609–637 necessary propriety guards; 640–648 objective docstring; 650–735 mode/Hessian/objective; 1378–1390 ordinal result; 1391–1423 Gamma outer optimization/result |
| `src/validation_status.jl` | `95f90c3a166f7ead65afc4205d5139155f86c002c697045388a1b2d383d14010` | 479–487 ordinal row; 488–496 Gamma row; 546–557 normalization |
| `comparator/ordinal_clmm/generate_and_fit.R` | `964f10c5532b0c87fabf3edcb2f2ee0e7d02d679dba6ab48d9bf3def609c4034` | 8–20 data, model call, parameter extraction |
| `comparator/gamma_glmmtmb/generate_and_fit.R` | `1bff69d5619c37add5e4ed44f0916ca803c90085063fe62acc4e9af8ae88042b` | 7–19 data, model call, shape conversion |
| `docs/dev-log/recovery-checkpoints/2026-07-01-ordinal-clmm-comparator.md` | `bf3c1cbd8c3b1c185b2151570fe15e54f35ae359c8b727dfe0903de672408c52` | 12–22 matching model/parameterization; 29–36 numerical results; 40–46 unsupported objective interpretation |
| `docs/dev-log/recovery-checkpoints/2026-07-01-gamma-glmmtmb-comparator.md` | `6406ef8a585d338d1f67dcf5a7005ce3d9e488759d47569ff4ab8586ee743a9a` | 11–20 matching model; 24–31 numerical results; 35–44 unsupported attribution |

Reused current component review: `docs/dev-log/source-review/2026-09-30-nongaussian-current-review.md`, at the same non-Gaussian source hash. It already records the joint fixed/random determinant, Gaussian reduction tests, and incomplete proper-integral guards. VS-4 context came from `/private/tmp/e1-validation-status-exact-review-20260930.md`. Current GLLVM objective contract, `docs/design/genetic-gllvm-objective-contract.md:15–30`, provides compatible flat-measure wording; this review does not extend the GLLVM scope.

## 3. Mathematical definition of the actual objective

Let `α` collect parameters optimized outside the integral: genetic variance `s = σ²a`, plus Gamma shape `ν` or the free ordinal cutpoint spacings as applicable. Let `u ∈ R^q`, `β ∈ R^p`, `G = s A`, and `Q = G⁻¹`. At fixed `α`, define

`F(β,u;α) = ℓ(y | Xβ + Zu, α) − u′Qu/2`.

The exact intended flat-measure integral is

`I(α;X) = ∫_{R^p} ∫_{R^q} exp(ℓ(y | Xβ+Zu,α)) φ_q(u;0,G) du dβ`.

The measure `dβ` has density one in the supplied coefficient coordinates. It is not a normalized probability prior. Thus `I` is not an ordinary marginal sampling density for `y`; its arbitrary fixed-effect measure normalization must be retained when comparing absolute values.

Write `(β̂_J,û_J) = argmax F` and `H = −∂²F/∂(β,u)²` at that mode. The source computes the one-step joint Laplace value

`J(α) = F(β̂_J,û_J;α) − ½ log|G| + (p/2) log(2π) − ½ log|H|`.

Because `log|G| = q log(s) − log|Ainv|`, this is exactly source lines 732–733. The Gaussian prior contributes `−q log(2π)/2`; integration over `p+q` coordinates contributes `(p+q) log(2π)/2`, leaving **`+p log(2π)/2`**, with no omitted random-effect constant. Conditional response normalization remains in `ℓ` and cannot be dropped when it depends on an outer parameter, such as Gamma shape.

The final determinant uses observed response curvature (source 722–731). Define

`B = X′WX`, `D = X′WZ`, `C = Z′WZ + Q`,

`H = [ B  D ; D′  C ]`, `S = B − D C⁻¹ D′`.

For positive-definite `H`, `|H| = |C| |S|`. The extra fixed-effect integration term is therefore **`(p/2)log(2π) − ½log|S|`**. In general `S` depends on `α`, through the prior precision and the mode-dependent response curvature. It is not merely an additive constant independent of variance/shape/cutpoints.

## 4. Exact comparison with conventional profiled Laplace-ML

At each fixed `β,α`, let `û_β = argmax_u F(β,u;α)` and let `C_β = −∂²F/∂u²` there. The random-effect-only Laplace approximation is

`L_LA(β,α) = F(β,û_β;α) − ½log|G| − ½log|C_β|`.

Conventional profiled Laplace-ML uses `L_prof(α) = max_β L_LA(β,α)`, with optimizer `β̂_ML`. At a regular joint mode, `û_{β̂_J} = û_J`, so the algebraic relation between the two approximations is

`J(α) − L_prof(α) = (p/2)log(2π) − ½log|S_J| + [L_LA(β̂_J,α) − L_LA(β̂_ML,α)]`.

The bracket is nonpositive when the stated global maximum exists. It is generally nonzero: maximizing `F` makes its fixed-effect score vanish, whereas maximizing `L_LA` also differentiates `−½log|C_β|`. Consequently it would be incomplete to describe the difference from **profiled** Laplace-ML as only the Schur determinant evaluated at the engine mode. The Schur matrix above is the Hessian of the profiled penalized conditional log density `F(β,û_β)`, not generally the negative Hessian of the determinant-corrected `L_LA`.

Likewise, sequentially applying a further Laplace approximation to `∫exp(L_LA(β,α))dβ` can yield a different finite-order approximation from the source's single joint Laplace step. A comparator must specify which construction it implements. Adding a Gaussian-style correction to a comparator's final ML value without matching its mode and curvature is not an equivalence proof.

Special case `p=0`: `S` is an empty determinant equal to one, there is no fixed-effect optimization/integration difference, and this particular objective distinction disappears. That does not describe the historical intercept-containing Ordinal/Gamma fixtures.

## 5. Gaussian reduction and normalization

For Gaussian observations with residual covariance `R`, set `V = R + ZGZ′` and

`P = V⁻¹ − V⁻¹X(X′V⁻¹X)⁻¹X′V⁻¹`.

The likelihood is quadratic, Laplace is exact, `S = X′V⁻¹X`, and `β̂_J = β̂_ML` equals generalized least squares. The resulting objective is

`J_G = −½[(n−p)log(2π) + log|V| + log|X′V⁻¹X| + y′Py]`.

This is the Gaussian REML convention used by this package. Other residual-contrast normalizations can differ by a constant depending on `X` but not on covariance parameters. Source test locations `test/runtests.jl:8730–8738,8771–8785` check Gaussian objective and mode reductions; these tests were inspected, not rerun here. The Gaussian result does not establish a general non-Gaussian REML definition or a fixed direction for Ordinal/Gamma variance differences.

For a nonsingular, parameter-independent basis change `X_new = XT`, `β = Tγ`, using density-one `dγ` gives `J_new = J_old − log|det(T)|`. This shifts absolute values but not the outer optimum. Comparing different fixed-effect spaces, parameter-dependent basis transformations, or differently normalized measures requires explicit treatment. A likelihood-ratio interpretation across different fixed-effect spaces is not supplied by this integral.

## 6. Proper-integral and output assumptions

The interpretation above requires finite valid data and parameters, positive-definite proper genetic covariance, full column rank of `X`, a finite fixed-effect integral, and a finite regular interior mode with positive-definite observed joint Hessian. Mode convergence and a positive local Hessian do not alone prove global integrability or approximation accuracy. Separation or endpoint responses can make ordinal/binary flat integrals improper. The guards at 609–637 reject enumerated cases only and explicitly do not diagnose general separation; the existing current review retains that limitation. A search rail on outer variance parameters does not repair an improper integral over `β`.

For Gamma at fixed finite `ν>0`, strictly positive finite responses and full-column-rank `X` give integrable fixed-effect tails: each response density decays at both ends of its linear predictor, and an invertible `p`-row submatrix bounds the integral uniformly over the remaining predictor offsets. A proper Gaussian prior then gives a finite double integral. This does not guarantee a well-identified joint optimum over `ν,s`, safe optimizer behavior, or calibration.

Ordinal identification fixes the first cutpoint to zero; only `K−2` spacings are freely optimized outside the integral, while location lies in the integrated intercept. The returned vector has `K−1` cutpoints, including its fixed zero. The historical transformation `β = −θ¹_clmm`, `θ_j = θʲ_clmm − θ¹_clmm` aligns corresponding model parameters. It does not turn integration over that location into profiling. For Gamma, shape `ν` is also an outer parameter, not an integrated coordinate.

The returned `beta` and `u` are the joint penalized modes at the reported outer parameters (source 1387–1390 and 1419–1423). They are not automatically conventional marginal-ML fixed-effect estimates or posterior means. The retained `fit_laplace_reml` identifier is compatibility syntax and does not define the non-Gaussian objective.

## 7. What the July comparisons establish

The recorded Ordinal fixture has 80 animals × 4 records, `A=I`, three probit categories, and aligned threshold location. Reported absolute differences are cutpoint spacing 0.0044, genetic variance 0.0241, and location 0.0119. The Gamma fixture has 40 animals × 4 records, `A=I`, a log link, and matched shape convention; reported differences are shape 0.0032, genetic variance 0.0167, and intercept 0.0322. These are historical receipts, not fresh source-current fit results.

Those results support the parameter mapping and document close numerical estimates on the two specified packets under different fitting criteria. Calling the population parameters corresponding is reasonable; using “same-estimand” as shorthand for equal objectives, equivalent estimators, or a discharged objective-parity prerequisite is not. The receipts supply no decomposition proving that the observed variance/intercept gaps arise wholly from fixed-effect integration, no theorem predicting their sign or size, and no likelihood/gradient parity check at common parameters.

The historical 48-seed recovery evidence remains separate evidence with its original scope. Neither a recovery pass nor close cross-objective estimates establishes same-objective numerical correctness, broader recovery, uncertainty calibration, or a new covered status. Existing observation-scale heritability transform checks concern supplied-parameter transformations and are not invalidated by this fitting-objective distinction.

## 8. Precise recommended replacement strings

These are proposals for integration after the parent releases the source freeze. Keep row IDs, status fields, and numerical historical results. Apply to the raw strings directly; do not retain a mapper that relabels the new text as Laplace-ML. The independent VS-3 count cleanup can be composed with these changes.

### Ordinal row, source 484

Replace the opening gate sentence through “recovery gate.” with:

> COVERED (SCOPED, validation-scale, opt-in; historical owner approval; R-public covered count remains 7). The July approval cited the joint estimator, a numerical comparison with `ordinal::clmm`, and a passing pre-declared 48-seed recovery gate. The comparator profiles fixed effects, whereas this engine flat-integrates them; it is cross-objective evidence and does not establish same-objective Laplace-ML parity. The historical covered label is retained; same-objective comparator validation remains unestablished.

Replace `a 2nd same-estimand comparator (MCMCglmm `threshold` is Bayesian-agreement-only and does NOT discharge the leg)` with:

> an independently verified comparator for this joint integrated-Laplace objective (the historical `ordinal::clmm` comparison uses a different fixed-effect treatment; MCMCglmm `threshold` supplies Bayesian agreement only)

Replace the entire `SAME-ESTIMAND COMPARATOR RUN (2026-07-01): ...` sentence ending with the ordinal receipt path with:

> CROSS-OBJECTIVE PARAMETER COMPARISON (2026-07-01): `ordinal::clmm` profiled-fixed-effect Laplace-ML and this engine's joint fixed-and-genetic-effect integrated Laplace fit were compared on the same A=I, K=3 packet (80 animals × 4 records), after aligning threshold location. The receipt reports absolute differences of 0.0044 for cutpoint spacing, 0.0241 for σ²a, and 0.0119 for the aligned intercept, with both fits reporting convergence (`docs/dev-log/recovery-checkpoints/2026-07-01-ordinal-clmm-comparator.md`). These values document numerical proximity on that packet; equal objectives and the cause of the differences were not demonstrated.

### Ordinal missing field, source 485

Replace the complete field with:

> The `:symbol` payload (`nongaussian_result_payload` cutpoints field, scale-labelled h²); a variational/ELBO kernel; a deep-latent-tail log-space `logsubexp` loglik for categories whose probability underflows; an independently verified comparator matching the joint integrated-Laplace objective, fixed-effect measure and parameterization; broader-DGP/pedigree-A recovery; and R ordinal formula/bridge activation. The July `ordinal::clmm` cross-objective comparison, the historical pre-declared 48-seed recovery gate, and the liability/per-category observation-scale h² transforms are recorded evidence. They do not establish same-objective comparator parity; Bayesian MCMCglmm/THRGIBBS agreement would not establish it either.

### Gamma row, source 493

Replace the opening gate sentence through “recovery gate.” with:

> COVERED (SCOPED, validation-scale, opt-in; historical owner approval; R-public covered count remains 7). The July approval cited the joint estimator, a numerical comparison with `glmmTMB Gamma(link="log")`, and a passing pre-declared 48-seed recovery gate. The comparator profiles fixed effects, whereas this engine flat-integrates them; it is cross-objective evidence and does not establish same-objective Laplace-ML parity. The historical covered label is retained; same-objective comparator validation remains unestablished.

Replace `a 2nd same-estimand comparator (MCMCglmm has NO general Gamma family — glmmTMB is the same-estimand tool; a 2nd REML leg is owed)` with:

> an independently verified comparator for this joint integrated-Laplace objective (the historical `glmmTMB` comparison uses a different fixed-effect treatment)

Replace the entire `SAME-ESTIMAND COMPARATOR RUN (2026-07-01): ...` sentence ending with the Gamma receipt path with:

> CROSS-OBJECTIVE PARAMETER COMPARISON (2026-07-01): `glmmTMB Gamma(link="log")+(1|id)` profiled-fixed-effect Laplace-ML and this engine's joint fixed-and-genetic-effect integrated Laplace fit were compared on the same A=I packet (40 animals × 4 records). The receipt reports absolute differences of 0.0032 for shape ν, 0.0167 for σ²a, and 0.0322 for the intercept, with both fits reporting convergence (`docs/dev-log/recovery-checkpoints/2026-07-01-gamma-glmmtmb-comparator.md`). These values document numerical proximity on that packet; equal objectives and the cause of the differences were not demonstrated.

### Gamma missing field, source 494

Replace the complete field with:

> The `:symbol` payload (`nongaussian_result_payload` shape field, scale-labelled h²); an independently verified comparator matching the joint integrated-Laplace objective, fixed-effect measure and parameterization; broader-DGP/pedigree-A recovery; and R Gamma formula/bridge activation. The July `glmmTMB` cross-objective comparison, the historical pre-declared 48-seed recovery gate, Rose audit, and maintainer G10 approval remain recorded evidence (PR #229). They do not establish same-objective comparator parity. Gamma observation-scale transforms have separate evidence in `V6-NS-H2`; fitted uncertainty and calibration are not supplied by those transforms.

### Both claim-boundary fields, source 486 and 495

Replace the common first sentence with:

> Experimental, dense/validation-scale, INTERNAL family. The reported non-Gaussian value approximates an integral over fixed effects under a flat measure in the supplied X coordinates and genetic effects under a normalized pedigree Gaussian density, using the joint observed-curvature Hessian at their mode. It is not conventional profiled-fixed-effect Laplace-ML, REML, or AI-REML. The historical `fit_laplace_reml` name is retained for compatibility; exact REML applies to its Gaussian reduction. The July external comparison is cross-objective numerical evidence and does not establish same-objective parity. The integral must be proper; local convergence alone does not prove this.

Retain the existing internal/legacy/outside-three-field-delivery/R-activation limits, and apply VS-3's current-count replacement to the remainder. Preserve the existing ordinal weak-identification caveat. Correct both ordinal counting phrases “σ²a + the K−1 cutpoints” and “estimates σ²a AND the K−1 cutpoints jointly” so they distinguish the K−1 returned cutpoints from the K−2 free spacings. Use “optimizes σ²a and K−2 free cutpoint spacings, returns K−1 cutpoints with θ₁ fixed at zero, and obtains β from the joint mode used in the integrated objective.” This is a notation correction, not a parameterization change.

### Mapper, source 546–557

Remove the Ordinal/Gamma `elseif` replacement branches after updating the raw strings. They currently replace “ML-vs-REML” with “cross-engine Laplace-ML difference” and “2nd REML leg” with “2nd same-estimand Laplace-ML comparator”; both preserve the wrong objective implication. Keep the separate GLLVM normalization branch unchanged. Alternatively, use a single explicit common integrated-objective fence, but do not rely on fragment replacement to define the objective.

## 9. Required documentation synchronization

Apply the same comparator qualifications to `docs/design/capability-status.md:151–152`, `docs/design/validation-debt-register.md:107–108`, and regenerate `docs/src/validation-status.md` from the corrected source. Replace any current “same-estimand comparator done”, “2nd REML comparator”, “expected ML-vs-REML gap”, and “Laplace-ML” label for the engine with the exact integrated-objective wording above. Preserve measured differences and dated recovery outcomes.

Keep the historical July receipts verbatim. Add a dated current interpretation note linking this derivation, and point current status/capability/debt readers to it. Exact suggested note:

> Objective clarification (2026-09-30): the July Ordinal/Gamma receipts compare corresponding model parameters under different objectives. HSquared.jl flat-integrates fixed effects and applies one joint fixed/random Laplace correction; the recorded external fits use profiled-fixed-effect Laplace-ML. Their numerical differences remain historical evidence, but the receipts do not establish equal objectives or explain those differences as an ML-versus-REML convention. Historical owner-approved covered labels remain unchanged. A comparator matching the integrated objective and fixed-effect measure is still unestablished.

Extend the legacy `laplace_marginal_loglik` docstring at source 640–648 with the measure, joint-Hessian formula, and proper-integral qualification in sections 3 and 6; use “flat measure” rather than “flat prior” alone. This prevents the shorter “marginal log-likelihood” label from hiding the fixed-effect treatment. No API rename or new output field is required to close this wording issue.

## 10. Verification and remaining gate

The derivation was checked with a deterministic scalar Gaussian identity calculation, no fit or simulation: `n=2,p=q=1`, `X=(1,1)′`, `Z=(1,0)′`, `y=(1,3)′`, and supplied `(s,σ²e)=(1,1),(2,1),(0.5,2)`. The direct joint-Hessian expression and closed Gaussian REML expression agreed to at most `4.44e−16`. The integrated-minus-profile values were respectively `0.716205979151`, `0.775097496979`, and `0.971618791034`, confirming that the correction varies with covariance parameters. This checks algebra/normalization only.

No current or historical fit was rerun; no package tests, campaign, GPU, network comparator installation, or live edit occurred. Parent source freeze remains in force. Existing current non-Gaussian source-review HOLD items remain owned by their original review.

Closing VS-4's **wording** issue requires the approved qualification, synchronized current ledgers, and generated-page verification. Closing **same-objective comparator parity** would require an independent implementation/evaluation with the same normalized conditional density, prior, fixed-effect coordinates/measure, integration approximation, parameter constraints and usable-mode policy, then common-parameter objective/derivative and fitted-output checks at a declared scope. That work is not authorized or launched by this report. It need not block retaining the historical status with an explicit debt.

## 11. Process and handoff

Lane preflight and the short routing manifest were read. This agent owns only the named scratch report; the candidate remains the parent's active lane. Graft was queried before source inspection; it returned a stale-cache warning because refreshing `.cache/.sync.lock` was denied. The graph supplied navigation only; exact current file spans and hashes supplied evidence. Its two reported full-file-baseline savings estimates total 270,963 tokens; this is not a measurement of actual review work saved. The engine-contract skill supplied the contract lens; no extra agents were started for this narrow mathematical question. Memory was used only to route the read-only scope; the mathematical conclusions come from current pinned source and derivation.

Parent integration owns repo-visible after-task/check-log records and any later source or documentation change. This report is a bounded component disposition and must not be cited as fresh whole-file, comparator-runtime, inference, or campaign approval.

# Independent matrix helper finite-contract review

## 1. Verdict and exact scope

**Selected-inverse trace revision 1: HOLD. Revision 2: bounded PASS. Evolvability proposal: bounded PASS.** These approvals cover the two isolated finite-contract patches, their exact source pins, preserved numerical bodies, and the named controls below. They do not close E1, A2, V3, fitting, calibration, GPU, release, or public bridge acceptance.

Parent reports account for all 453 original selected-inverse lines and all 314 original evolvability lines in disjoint spans. Those are the parent's complete-source review receipts. This independent review inspected the proposed changes, relevant numerical and domain neighbors, exact unchanged-body witnesses, caller graph, and fresh no-fit controls; it is not an independent approval of every line or an entire specialist panel.

## 2. Ownership and state

No live source, runner, or author proposal was mutated. Reviewer writes are confined to this report and `/private/tmp/e1-matrix-helper-finite-independent-20260930/`. At final verification live HEAD remained `6271cfd58651e69cd27a64dcf02cb8960a29e260`, with the two original helper source pins below unchanged. Parent announced unrelated likelihood/iterative integration explicitly; it did not affect these source witnesses. Pedigree authoring in this agent is separate from this independent review.

## 3. Exact artifacts

| Artifact | SHA-256 |
| --- | --- |
| Trace original | `38a07e2e34da2f4a295e52e25b1f1d067a0b7e1b2893bdef8c73f1f78c704782` |
| Trace revision 1 prepared, HOLD | `92229743288e97ecc0f324105060aafaacf785767225ab5e26e624d91d90ba93` |
| Trace revision 1 patch | `654cd3cfef0fab90040cfe93f05b8e6336f3d0839e18a48f4321d493b19bdb29` |
| Trace revision 1 primary test | `8d02b94442b13ff0b14aec18addec09ac9f8be2feb08aca02225085d9218ca52` |
| Trace revision 2 prepared, PASS | `3ac12ece1d095852f0937d63c97a03333665560a2c4876c138b4c547fec4e0ed` |
| Trace revision 2 patch | `1b7af93b73cd2ad23f9eea3cadf7536566c3792d3bf0d4653fbeeabfdb37c0f4` |
| Trace revision 2 primary test | `10ff2a39b9159de5082614ac7b5b00c9d5823853aacb53beac48d3f426c35f65` |
| Trace revision 2 pins manifest | `210120f0bd69669e7570821018dfc147dc00fdac905f3d2cdb8ebae7856a01e2` |
| Evolvability original | `fd49987ee69c1f9b6e3335bdb6e4f8c73b6f0cdab3da4b7263cf4e87b6577ff3` |
| Evolvability prepared, PASS | `4dc5b5e0b1f51abaa97bdee77b3205129470ca5107628390cf3ef1578452306f` |
| Evolvability patch | `b63e9554555c10d7758443b7ab9e8f7517bef96d64cca25b56f58b2e678d7721` |
| Evolvability primary test | `abee4ba7d21bf6cb46e35c46351f319f5f43ad33e2c24379e54a2dfdf99d5f88` |

All initial 9 trace and 11 evolvability author manifest entries were independently verified. Revision 2 has 16 verified manifest entries, including preserved revision 1 artifacts. Scratch `git apply --check` and patch replay reproduce each prepared source exactly. All numerical logs and independent script hashes are in `review-pins.json` within the reviewer scratch directory. The author's current `green.log` retains revision 1 results; the revision 2 run is correctly named `revision-2-green.log`. Fresh reviewer logs below remove any ambiguity.

## 4. Source graph and reuse

Graph skeletons and exact callers were obtained before new source inspection for `selinv_trace_against`, `selinv_block_traces`, and the evolvability API. The graph locates single- and multi-effect sparse AI-REML trace callers; no fitting experiment is inferred from that edge. Relevant original trace spans 312–453 and descriptive geometry spans 94–194 were read at their exact locations, plus the covariance and direction validators.

Byte comparisons confirm the entire selected-inverse source prefix through the recursion, materialization, and diagonal extraction (original lines 1–311) remains unchanged. Evolvability covariance validators, scale-safe direction normalization, conditional inverse metric, autonomy, PCA, mean, and plotting tail are unchanged. Changes are confined to trace ingress/result guards, three derived-result finite checks, and visible documentation. No recurrence, eigenvalue, condition, inverse, optimizer, or scale acceptance policy was silently changed.

## 5. Reproduced revision 1 defects

**MH01 — original nonzero off-pattern weight became a permitted structural zero.** With a 2×2 identity sparse Cholesky factor and `Q=sparse([1],[2],[big"1e-400"],2,2)`, original single and block trace helpers throw `ArgumentError` because the nonzero weight is outside the selected pattern. Revision 1 converts it to Float64 zero and returns `0.0` / `[0.0]`. This violates the documented original nonzero support contract.

**MH02 — a representable scaled trace was silently lost.** With scalar factor matrix `[1e-200]` and weight `[big"1e-400"]`, original BigFloat multiplication returns a value whose Float64 conversion is approximately `1e-200`. Revision 1 returns zero after weight conversion. A finite converted weight alone is therefore insufficient to prevent a false-zero answer.

These are witnessed in retained `trace-challenge.jl` and `trace-challenge.log`: 21 diagnostic assertions pass, including assertions of the wrong revision 1 outputs. That green diagnostic log is evidence of HOLD, not numerical acceptance. Fresh supplied revision 1 checks were 52/52; they did not cover these defects.

## 6. Revision 2 disposition and trace controls

Revision 2 checks original finite real weights, converted finite Float64 weights, and rejects each original nonzero weight whose conversion is zero. This happens before selected-inverse recursion. Both defects now throw; the visible Float64 acceptance boundary is an explicit refusal rather than a general BigFloat arithmetic promise.

Fresh supplied checks: **29 new + 33 existing = 62/62 PASS** in `selinv-revision2-62.log`. Fresh independent checks: **28/28 PASS** in `trace-revision2-challenge.log`, including the original failure witnesses, dense signed indefinite weights against `tr(Q*inv(C))`, two block offsets, negative trace preservation, NaN/±Inf/conversion overflow, original explicit stored zero off-pattern, and actual positive and negative `nextfloat(0.0)` weights. A Float64 subnormal that remains nonzero is accepted when its product is finite. Weights need not be covariance matrices or positive definite: signed linear traces remain supported.

The selected-pattern lookup and permutation convention are preserved. No support was gained by substituting zero for missing inverse entries.

## 7. Evolvability disposition and independent geometry controls

Fresh supplied checks: **7 new + 18 existing = 25/25 PASS** in `evolvability-25.log`. Fresh independent checks: **29/29 PASS** in `evolvability-challenge.log`.

For `G=diag(7,2)` and direction `(1,2)`, independent analytic answers are evolvability 3, respondability √13, conditional evolvability 7/3, autonomy 7/9, and raw index variance 15. Direction sign invariance and scale controls at 1e-300 and 1e300 pass. Zero covariance with raw finite contrasts as large as Float64 maximum returns zero. Raw scale-compensated cases `G=1e-300, beta=1e154` and `G=1e300, beta=1e-200` preserve finite answers approximately 1e8 and 1e-100. The scalar Float64 maximum is retained for unit-direction variance and response. Overflowing raw variances and malformed/indefinite inputs refuse as expected. A finite exact-null contrast at ordinary covariance scale remains zero.

The finite-result checks distinguish a usable finite answer from arithmetic overflow; they do not impose a practical size cutoff or a new covariance condition threshold. No fitted-G uncertainty or inference interpretation follows from these descriptive answers.

## 8. Retained numerical and metadata boundaries

Trace support validation still occurs after recursion for representable weights, so invalid patterns can waste kernel work. This existing timing issue remains open. Weight quantization, raw underflow, ill conditioning, fill, allocations, and finite-precision cancellation accuracy remain outside this bounded repair. Overflow of an intermediate product or sum is refused even when cancellation could make the mathematical answer finite; arbitrary precision and rescaled accumulation are not implemented.

Likewise, `G=fill(1e307,2,2), beta=(1e308,-1e308)` has mathematically zero raw index variance but overflowing intermediate arithmetic; the independent test confirms the explicit refusal, not universal finite-answer recovery. The evolvability `max(0,value)` admissible-roundoff clamp and prior PSD/PD thresholds are unchanged.

The source-review parent's plotting debts remain: strict axis integer/error taxonomy, label uniqueness, and optional h2 finite provenance are not addressed. Caller-supplied annotations do not certify fitted heritability or trait order. Latent rotations preserving G and supplied trait-coordinate scaling remain distinct biological interpretations.

## 9. Execution discipline

The independent no-fit invocations were estimated below one minute before launch, with `JULIA_NUM_THREADS=1` and `OPENBLAS_NUM_THREADS=1`. They completed within the estimate. Standalone source modules avoid optimizer and package-wide work. No full package suite, simulation campaign, remote compute, GPU, or historical performance rerun occurred. Reviewer 2 scripted unchanged-body span checks were initially overbroad and included the changed respondability function; the check was narrowed to exact conditional/autonomy definitions and rerun successfully. This was a review-harness assertion, not a source defect.

## 10. Remaining acceptance work

These exact patches may proceed to parent integration and the already planned integrated checks. Acceptance does not transfer to changed source bytes, wider helpers, fitting callers, or metadata. Parent complete-source review coverage and these independent bounded numerical approvals should be recorded separately. E1/A2/V3 and the non-GPU inheritance fitting queue remain open.

## 11. Handoff and ownership

Revision 1 HOLD artifacts are preserved in both author `revision-1/` and reviewer `selinv/`; revision 2 evidence is in reviewer `selinv-revision-2/`. No live mutation is included in this handoff. Reproduce the reviewer revision 2 checks with the copied `run.jl` and `trace-revision2-challenge.jl`; reproduce descriptive controls with `evolvability-challenge.jl`, all under the stated one-thread environment. Parent owns integration, runner edits, and wider programme receipts.

# Independent mathematical review: non-Gaussian h2 descriptor repair

## 1. Goal

Review only the proposed heritability helper against the declared symbolic model, with emphasis on parameter meanings, original/converted domain guards, zero genetic variance, and constant/varying trial representations. This is the requested independent mathematical challenge; the filename is the assigned artifact name, not a claim that a different model tier was used.

## 2. Verdict and implementation reviewed

**PASS for the bounded arithmetic and ingress repair. HOLD for complete prose/number alignment until the small zero-limit wording corrections below are composed.** No arithmetic correction is required by this review. The parent already owns the separately preserved helper docstring correction.

Verified SHA256 pins:

- Proposed `src/nongaussian.jl`: `a9cc2b986da539a0108985c625e4e7694337e2cb55ffd33025f5a87ee25d27dc`.
- Final patch: `e255f85afdb3b68e77d7a5e303c7f46109340464aad52fcbb9e0315c682780c8`.
- Regression: `6ef180997073e24708df93f1fbdd400413d140875d0aa85806649be3fe9e9986`.
- Symbolic design: `ff81f37688c4c750e8dc7ae467385f23fb4f85412bf2ab2264051c3ebf0dd9f6`.

The source and final patch include the original Gaussian-spread guard. `source.diff` is an older intermediate artifact and omits that final guard; compose from the pinned final patch/source.

## 3. Mathematical consistency

With jointly Gaussian reference contributions, zero covariance, and eta = mu + a + f, V_eta = V_A + V_F and Cov(a,Y) = V_A E[m'(eta)]. Thus the variance of the linear projection on a is V_A E[m'(eta)]^2. The core retains this target, rather than replacing it with all variance of the nonlinear mean. No erroneous V_F >= V_A restriction is present.

- Gaussian preserves the conditional ratio V_A/(V_A+sigma_e2). Both entries reject nonzero original V_F, including positive BigFloat spread that converts to zero; the core rejects nonzero converted spread. The denominator is positive and finite after validation.
- Poisson retains lambda = exp(mu+V_eta/2), numerator lambda^2 V_A, and denominator lambda^2 (exp(V_eta)-1)+lambda. Its latent NaN and zero link variance conventions remain intact.
- Bernoulli/binomial retain p_bar, E[p(1-p)], and Var(p) integrated over V_eta. Sampling variance is E[p(1-p)]/n on the proportion scale. Constant trial vectors reduce to the same scalar core and preserve complete summaries, family identity, and information flags.
- Binary probit retains the average normal-density derivative and marginal indicator denominator p_bar(1-p_bar). Ordered probit uses the correctly signed difference of threshold densities, squared in each category projection. Its scalar observation summary remains NaN.
- Gamma uses shape nu with Var(Y|eta)=exp(2eta)/nu, giving h2_obs = V_A/[exp(V_eta)(1+1/nu)-1]. Its latent residual remains trigamma(nu), excluded from observation integration. Mean cancellation is preserved by the underlying formulas at ordinary numerical scales.
- Negative-binomial and beta-binomial heritability remain unsupported; this repair does not add their transforms.

All supported zero-V_A observation projections return zero directly. This is the continuous projection value for the declared model. It does not certify all other fields as finite at extreme inputs.

## 3a. Required notation and wording fixes

1. **Zero-limit ordering:** proposed source line 1699 returns a binary-probit caveat saying `always < h2_latent`; doc-19 lines 150–153 similarly say always smaller. At V_A=0 the returned values are both zero. Say `h2_observation <= h2_latent, with equality at V_A=0 under the exact finite-moment model`; strict inequality can be stated for positive V_A. Do not imply exact quadrature ordering over arbitrary extreme inputs.
2. **Zero-inclusive bound:** unchanged source preamble line 1584 says h2_obs is in `(0,1)`. Replace with the model-level nonnegative bound, conditional on positive finite observation variance. Numerical tests at a finite set of points do not prove a universal quadrature bound.
3. **Conditional Gamma notation (inherited adjacent wording):** source lines 1730/1750 and doc-19 call trigamma(nu) `Var[log Y]`. Precisely it is `Var(log Y | eta)`, equivalently the variance of the additive log-scale residual. Under the declared random predictor, marginal Var(log Y) is V_eta + trigamma(nu). The implementation uses the correct residual; this is a notation clarification, not an arithmetic defect.

The parent-owned helper docstring must retain the explicit Gaussian exception, additional-spread definition, joint-Gaussian/zero-covariance assumption, common versus varying trial rule, and zero-inclusive interpretation described in the design. This review does not demand a wider status-table cleanup or a new calibration campaign.

## 4. Files touched

Created only this assigned review report. No live source, proposal source, test, patch, git index, or other lane artifact was changed.

## 5. Checks run

Fresh deterministic regression rerun, estimated under one minute before launch:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia \
julia --compiled-modules=no --startup-file=no --project=. \
test/nongaussian_h2_descriptor_regression.jl
```

Working directory: `/private/tmp/hsq-nongaussian-h2-descriptors-fix-20260930`.

Result: **170/170 assertions passed; exit 0; test summary 1.3 seconds**. No fit, optimizer, mode solve, simulation, GPU, remote compute, package update, or full package test was run.

Read the exact helper/body, focused regression, symbolic design, final patch, and changed doc-19 contexts. A narrow Graft lookup routed to another checkout's older helper, so the assigned pinned artifact supplied technical evidence. Fresh SHA256 checks confirmed the assigned pins.

## 6. Tests of the tests

The rerun independently confirms the final 170 assertions. The earlier red runs are retained implementation evidence; this reviewer did not repeat them. The suite contains independent moderate logit quadrature, closed-form Poisson/Gamma controls, complete scalar/vector equality, original-domain negative underflow, original Gaussian positive-underflow rejection, converted overflow, finite-sum overflow, and malformed stored metadata checks.

## 7a. Issue ledger

- NG-07: arithmetic/ingress PASS for conditional Gaussian fence.
- NG-08: PASS for scalar/constant-vector equality; genuinely varying trials retain finite latent output and NaN observation output.
- NG-09: PASS for original finite/nonnegative variance and finite mean validation, converted domains, positive family fields, cutpoint validation, and finite derived totals.
- Complete prose alignment: HOLD for the three precise notation corrections above and separately owned docstring composition.

## 8. Consistency audit

The public overloads validate variance/mean before the varying-trial early return. The original-value Gaussian guard closes the one edge that converted validation alone cannot close. Nonnegative variance underflow to zero is explicitly accepted by design; positive family-field underflow is rejected. This is a deliberate Float64 descriptor convention, not evidence that the original tiny positive variance was mathematically zero.

Trial values must be positive integer-valued Real numbers representable as Int. Constant vectors share their scalar representation. Variable vectors are not averaged, and no invalid-input path bypasses the applicable variance/mean/total guards. Family parameterization, method tags, and result field shapes are preserved. The GLLVM R response-h2 route stays deferred.

## 9. What did not go smoothly

The intermediate `source.diff` was stale relative to the final source and patch. Review conclusions use final pinned bytes. Broad memory retrieval gave no relevant mathematical contract; the provided symbolic design and code were sufficient.

## 10. Known residuals

Finite inputs can still produce overflow, underflow, or degenerate probabilities in existing moment expressions. This was explicitly carried by the design; no wider numerical-range approval follows from ingress checks or zero-limit handling. GH20 approximation is not globally validated here. No coverage, intervals, fitted identifiability, optimizer robustness, covariance stationarity, response-scale GLLVM support, or full A2/E1/V3/release completion is certified.

## 11. Team learning

Preserving a continuous zero projection makes strict prose inequalities newly visible. Review returned caveats and source comments alongside formulas: correct numbers can still carry a false mathematical explanation. The correct Gaussian original-value check also shows why model-domain validation must precede lossy conversion.

## 12. Cross-product coverage and handoff

Reviewed both public entries, internal core, stored and keyword trial paths, positive/zero/invalid variance domains, original and converted domains, family metadata, and all supported transform branches. Parent should compose the final pinned patch plus its separate docstring changes, incorporate the small notation repairs, then rerun the same deterministic suite on the composed artifact. No new broad test gate is requested.

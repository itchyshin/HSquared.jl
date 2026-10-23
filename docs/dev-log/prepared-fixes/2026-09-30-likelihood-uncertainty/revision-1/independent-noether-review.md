# Independent likelihood uncertainty review

## 1. Goal and reviewer identity

Narrow independent mathematical/source challenge of LH-05, LH-06, LH-07, and LH-09 in the prepared likelihood uncertainty patch. The existing Noether agent performed this review. The assigned `astra-review` filename is not evidence of an Astra model invocation; the parent was notified that this agent cannot change its own model tier.

## 2. Verdict at the supplied pin

**HOLD: one reproducible LH-07 derived-step validation bypass remains.** LH-05 selector semantics, LH-06 full-denominator derivative, and the three LH-09 wording repairs pass this bounded review. Fresh 192/192 regressions and 3/3 additional independent correlated-information derivative checks pass, but they do not cover the bypass.

Verified SHA256:

- Prepared likelihood: `4662affd4eadb5651ac6870f860f2e506b13298a23ce85e5bf443d08bcab07f6`.
- Patch: `b36a17ff71f3ab88e15b8ad1b55cb7df4ea37e13ba94e3fd4e3de3354db92b46`.
- Focused regression: `4f8d491599ce975171cf54cecb78d6e2c90de7d355d60a4b8cf340865640faf9`.

## 3. Required repair: derived invalid step can be hidden by ratio rail

In prepared `src/likelihood.jl:2281–2290`, `multi_effect_sum_ratio_interval` validates the original/converted scalar step and supplied variances, then returns `na` when the ratio lies on its tolerance rail. The component-step check `h = fd_step .* max.(abs.(theta), 1e-3)` is downstream in the covariance helper at lines 2113–2115. An individually finite positive scalar step can produce an infinite component step and bypass this required domain check.

Reproducer, no fitting or objective evaluation needed:

```julia
using HSquared
effects = [(ones(1,1), ones(1,1)), (ones(1,1), ones(1,1))]
HSquared.multi_effect_sum_ratio_interval(
    [1.0], ones(1,1), effects, [2.0,2.0], 1.0;
    fd_step=floatmax(Float64), boundary_tol=.9)
```

Observed output:

```text
(estimate = 0.8, lower = NaN, upper = NaN, se = NaN,
 lower_clamped = false, upper_clamped = false, boundary = true)
```

The same call with `boundary_tol=1e-6` throws:

```text
ArgumentError: fd_step must produce finite positive component steps
```

Here h for each random variance is `floatmax(Float64)*2 = Inf`. This contradicts the stated contract that component steps remain finite and positive and malformed controls cannot be hidden by ratio rails. It is an input-domain classification issue, independent of any demand to improve finite-difference accuracy at extreme scales.

Required change: validate the derived component steps before the ratio-rail return, preferably with one shared helper reused by covariance ingress and the FD core. Add a regression for overflowed h with a rail return, and a corresponding underflow-to-zero h case. Retain the ordinary valid near-zero-information behavior. No wider algorithm change is requested.

## 3a. Mathematical checks that pass

For r(theta)=theta_i/T with T=sum(theta), inactive coordinates B remain fixed at their supplied values. For retained k in A,

    dr/dtheta_k = (1{k=i} T - theta_i)/T^2.

The repaired gradient at lines 1633–1634 is this derivative. The retained information block I_AA describes curvature with inactive parameters fixed, so its inverse is the corresponding conditional local covariance approximation. It is not the AA subblock of inverse(I) and does not profile nuisance coordinates.

For theta=[2,1,3], boundary_tol=.2, active coordinates are [1,3]. The estimate remains 1/3, derivative is [4,-2]/36, and identity-information SE is sqrt(20)/36. Both the analytic and central-derivative fixtures pass. An additional non-diagonal positive-definite information matrix

    [2 .1 .3; .1 4 .2; .3 .2 3]

also gives the delta SE predicted by central derivatives and inverse(I_AA). Three independent assertions passed. Interior and exact-zero controls in the focused suite remain valid.

For a unique selector set S, N=sum(theta[S]), the summed-ratio gradient is (1{k in S}T-N)/T^2. The helper uses that expression. Rejecting duplicates, noninteger entries, Booleans, empty selectors, and indices outside 1..K aligns the numerator with the derivative. Reversed unique selectors retain the same result.

LH-09's revised AI statement is correct for covariance linear in variance components: observed information is y'P V_i P V_j P y minus half the trace, expected information is half the trace, and their average is half the quadratic. The corrected precision block Ainv_i/sigma_i agrees with sigma_i denoting the effect variance in that docstring. Optimizer convergence does not certify identifiability, as the revised prose now states.

## 4. Files touched

Created only this assigned review report. No live source, prepared source, tests, patch, git state, or other lane artifact was edited.

## 5. Checks run

The focused suite plus independent central-derivative checks were estimated under one minute before launch and ran on the prepared artifact with Julia/BLAS each capped at one thread, offline, compiled modules disabled:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 JULIA_PKG_OFFLINE=true \
JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia \
julia --compiled-modules=no --startup-file=no --project=. -e '...'
```

Working directory: `/private/tmp/hsq-likelihood-uncertainty-fix-20260930/prepared`.

Observed results:

- Likelihood uncertainty contracts: **192/192**, test summary 6.8 seconds.
- Independent correlated information derivative: **3/3**, test summary 0.1 seconds.
- Combined command exit 0.
- Separate direct finite-derived-step counterexample reproduced the inconsistent return/throw classification; command exit 0.

No fitter, optimizer, recovery campaign, GPU, remote compute, or full package suite was run. The 192-case suite includes finite positive-definite covariance at a supplied point, bundled/single parity, and valid near-zero unavailable-information controls.

## 6. Tests of the tests

The existing 87-pass/105-fail red evidence is builder evidence and was not rerun independently. Fresh green evidence is confirmed here. The added derivative checks use a correlated information matrix and central derivatives with inactive coordinate unchanged; they independently challenge both the selected information-block meaning and the full denominator. The newly found edge explains why passing the raw-invalid-step cases is insufficient to prove all derived-step ingress paths.

## 7a. Issue ledger

- LH-05: PASS for the declared selector domain and summed numerator/gradient alignment.
- LH-06: PASS for the full reported ratio with inactive coordinates held fixed; no calibration claim.
- LH-07: HOLD for the derived-step bypass above. Original/converted variance checks and raw fd_step checks otherwise match their declared domains in the reviewed paths.
- LH-09: PASS for the three scoped docstring corrections.
- LH-01–04/LH-08: outside this patch verdict; parent retains their second-wave dispositions.

## 8. Consistency audit

The patch correctly treats zero or negative supplied variances, nonfinite values, conversion overflow and positive conversion underflow as malformed inputs in supplied-point covariance/ratio routes. Valid small positive values that cannot support the central-difference stencil retain unavailable-information behavior. The remaining bypass is specifically between raw and derived step validation and the early ratio return.

The ratio method remains conditional on an algorithmically selected active set. It does not establish that inactive variance estimates are scientifically known constants. Existing rejection when fewer than two active coordinates remain is conservative inherited behavior, not evidence that a ratio with other nonzero fixed coordinates has no mathematical derivative.

## 9. What did not go smoothly

The finite-derived-step guard was present and looked complete in the covariance helper, but one caller can return before reaching it. Review of call order exposed a case that all 192 tests omit.

## 10. Known residuals

No whole likelihood-file approval, model-ingress approval, nonconverged-fit approval, uncertainty calibration, identifiability guarantee, or release completion follows. Cancellation, large finite perturbations, positive-definite information at arbitrary points, and boundary confidence-interval coverage remain conditional limitations. The step-domain bypass should be closed before claiming the scoped LH-07 contract complete.

## 11. Team learning and handoff

Derived-domain checks must dominate every unavailable-result return as well as objective evaluation. Parent should return the single bypass to the builder, obtain a new source/patch/test pin with the focused regressions, then request a bounded recheck. The reviewed mathematical derivative does not need redesign.

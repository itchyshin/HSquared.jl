# Independent Noether recheck: likelihood uncertainty revision 2

## 1. Goal

Recheck only the revision-1 LH-07 derived-step bypass, preserve the prior LH-05/LH-06/LH-09 mathematical review, and independently rerun the focused suite plus central-derivative and bypass controls. This is Noether's review; no Astra execution is claimed.

## 2. Verdict and exact pins

**PASS for this bounded LH-05/LH-06/LH-07/LH-09 repair at the following prepared pins. The revision-1 derived-step HOLD is closed.** No live integration or whole-file approval follows.

Verified SHA256:

- Prepared `src/likelihood.jl`: `342b029fa482cbb9101f2f924badca31ebdec7b8f8838facb96bb0317d013f7c`.
- Final patch: `ab3c98610c0a735aea7712521ad7ddf4cb7c6fc547f16af43ffadc15eaf029b8`.
- Regression: `88af1ddd7943a59965708926f11ebc131021fae82f2c6c7f536f3ccf7f3c46bc`.

## 3. Source verification

The complete revision-1-to-revision-2 source diff has four hunks: a shared `_uncertainty_component_steps` helper; replacement of duplicated validation in `_reml_fd_information`; replacement of duplicated validation in covariance ingress; and invocation before the summed-ratio early return. Ratio mathematics and the previous selector/docstring repairs are unchanged.

The helper validates scalar step in original and Float64 domains, computes h_i = fd_step * max(abs(theta_i),1e-3), and rejects nonfinite or nonpositive h_i. Its call at prepared line 2288 precedes the ratio rail at 2295. Covariance ingress calls it at 2119 before unavailable-information classification, and the FD core calls it at 1686 before objective evaluation.

The finite-positive theta domain is checked by each relevant caller first. The bundled uncertainty route reaches covariance ingress before any unavailable ratio result. Consequently both identified derived-domain failures now reject consistently rather than becoming boundary information.

## 3a. Mathematical checks

The full-denominator ratio r=theta_i/sum(theta) retains inactive estimates in its denominator while active coordinates vary. Its gradient is (1{k=i}T-theta_i)/T^2. For theta=[2,1,3], tolerance .2, active indices [1,3], this remains [4,-2]/36 and the estimate remains 1/3.

Three independent checks using positive-definite correlated information `[2 .1 .3; .1 4 .2; .3 .2 3]` passed: estimate, central-derivative delta SE using inverse(I_AA), and analytic-gradient delta SE using the same conditional curvature. This distinguishes inverse of the active information block from a block of the full inverse.

Unique-selector summed ratios, average-versus-observed information wording, inverse-relationship MME precision, and convergence-versus-identifiability wording retain the earlier scoped PASS.

## 4. Files touched

Created only this assigned recheck report. No live/prepared source, tests, patch, git state, or other lane artifact was edited.

## 5. Fresh checks run

Estimated under one minute before launch. Used the prepared project, offline, startup and compiled modules disabled, one Julia thread and one OpenBLAS thread. Command included the focused test file followed by seven independent assertions.

Observed output, exit 0:

```text
Likelihood uncertainty contracts                 192/192   6.7s
Derived component step precedes rail returns       22/22    0.3s
Independent revision-2 checks                       7/7     0.2s
```

Thus the supplied suite passed **214/214**, and independent additions passed **7/7**.

Independent additions comprise the three correlated-information derivative checks plus four direct overflow/underflow rejection checks: theta=[2,2,1] with floatmax(Float64) step, and theta=fill(1e-4,3) with nextfloat(0.0) step, each at boundary tolerances .9 and 1e-6. Every call returned ArgumentError containing `finite positive component steps`.

No fit, optimizer, simulation campaign, GPU, remote compute, package update, or full package test ran.

## 6. Tests of the tests

Revision 1's directly observed inconsistency is preserved in the earlier independent report and archived builder material. Revision 2 changes the same overflow reproducer from a boundary NaN return to the explicit domain error. The added suite also checks underflow to zero, unavailable=:nothing, bundled uncertainty, no objective evaluation on bad component steps, and preservation of valid ordinary/near-zero rail behavior.

## 7a. Issue ledger

- LH-05 selector domain: PASS within declared unique integer selection contract.
- LH-06 reported ratio/gradient consistency: PASS, including inactive positive fixed coordinate and exact-zero/interior controls.
- LH-07 original/converted scalar and variance domains, plus derived-step classification: PASS for this bounded repair; revision-1 bypass closed.
- LH-09 three wording fixes: PASS, unchanged from reviewed revision 1.
- LH-01–04/LH-08: outside this review and unchanged in their broader dispositions.

## 8. Consistency audit

Invalid derived controls are rejected before both the rail return and covariance unavailable classification. Valid positive components whose stencil reaches zero retain their existing unavailable-information convention. The ratio estimand remains conditional on the retained-coordinate approximation; no new weighting, denominator, or estimator was introduced by revision 2.

## 9. What did not go smoothly

No new discrepancy found. The archived revision-1 source allowed a complete small diff check instead of re-auditing unrelated likelihood code.

## 10. Known residuals

No finite-difference accuracy guarantee across arbitrary finite inputs; no boundary coverage, optimizer convergence, identifiability, nonconverged-fit acceptance, whole E1/A2/V3 closure, or release approval. LH-01–04 and LH-08 remain governed by the parent's separate work. Public/live claims require evidence from the composed artifact.

## 11. Handoff

The parent may compose this pinned uncertainty patch within the authorized work and run the required focused checks on the composition. No further repair is requested by this narrow review. The earlier Noether HOLD is superseded only for the precise bypass and pins documented here.

# Independent non-Gaussian finite-ingress review

Date: 2026-09-30. Implementation verdict: **PASS for the isolated constructor and shared response-ingress guards**. Final receipt reviewed at SHA-256 `505c1d5d4e15b450ac92374aefa371ba745bdbddebf87919b21f360415b89e29`. Integration and composition remain open. No live files were changed.

## Exact reviewed pins

Prepared root: `/private/tmp/hsq-nongaussian-finite-ingress-fix-20260930`. Independent check copy: `/private/tmp/e1-nongaussian-finite-ingress-independent-20260930`.

| Artifact | SHA-256 |
| --- | --- |
| Patch | `2e3aa1fac2f1a5b1567113bd9e986992315b756faf3350df83678d657aa102db` |
| Frozen nongaussian | `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00` |
| Prepared nongaussian | `e96694a2dbd6cb1c416833a073fe0d38928eeb1ad2deeb0bc19a692cc351bd0a` |
| Regression test | `1947ae4f703436392d0a3556fefdfeec69bfd7eee5e704db833c021e366f9ab3` |
| Frozen source tree | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| Prepared source tree | `4f4ae6a15862b7afb85c21e7025e26ad0d6100810d5ddd5aaaf1dd0122951eb7` |

Every final inventory entry matched independently, including Project, Manifest, unchanged genetic_gllvm and red/green logs. Both source trees reproduced the src-relative path/NUL/bytes/NUL algorithm. Source, patch and test pins still match after the independent run, and the live source tree remains frozen. `git apply --check` passes without applying the patch. Any authorized parent documentation-only HEAD advance leaves this exact source evidence unchanged.

## Constructor and response checks

Original source spans modified: Gaussian constructor 31–35, NB constructor 84–88, ordered thresholds 153–157, Gamma constructor 171–175, shared count checks 556–606. The patch preserves original positive-domain comparisons and adds original finiteness plus finite/strict-positive Float64 results for Gaussian residual variance, NB theta and Gamma shape. Thus invalid values fail during construction before family numerical methods can consume their stored fields. Positive finite values that overflow to Inf or underflow to zero are rejected; the smallest representable positive Float64 subnormal remains accepted.

OrderedProbitResponse retains nonempty and original strict-increasing requirements. It checks every original and converted threshold for finiteness, including singleton vectors, then requires strict order after conversion. This catches originally distinct BigFloat thresholds that collapse to the same Float64. A singleton finite threshold that rounds to zero remains valid because thresholds have no strict-positive domain.

The new finite-response helper is called by the generic ResponseFamily count check and every specialized count method. Existing binary/count/category/positive-response restrictions remain after that check. BinomialVectorResponse still checks trial-vector length first. Gaussian finite negative responses remain allowed; zero is admitted for the relevant count families and rejected for Gamma. Family positive-field zero remains invalid. Genetic variance validation is unchanged and is not widened by this patch.

## Independent tests and baseline evidence

Estimate stated before launch: under one minute, Julia 1.10.0, one Julia and one BLAS thread, copied Manifest, --startup-file=no --compiled-modules=no and approved depot order. The exact supplied regression file passed **141/141**, 2.9 seconds, exit 0. No fit, optimizer, statistical mode iteration, Hessian or family-kernel numerical evaluation ran. Existing scalar/GLLVM kernels perform input/precision validation before reaching the test sentinel.

Coverage totals: 51 positive-family-field assertions; 19 ordered-threshold assertions; 64 finite-response/domain and unchanged beta-binomial controls; six ingress-path assertions; one dispatch-cleanup assertion. Controls include NaN/±Inf, BigFloat overflow and underflow, original order and converted-order collapse, singleton thresholds, normal/subnormal positive fields and retained per-family response domains. Kernel tests exercise Gaussian/Gamma scalar and GLLVM rejection, Gaussian VA ingress rejection, and a finite Gaussian positive-variance path stopped before mode work. The sentinel invokes the actual proper-integral helper; it is deleted in finally and generic dispatch restoration is asserted.

The verified supplied frozen-source red log records 114 pass / 27 fail / 0 error. This review reproduced the exact green test and verified the red log hash rather than rerunning baseline. The failures are consistent with omitted constructor finiteness/representability checks, singleton/converted ordered thresholds, generic Gaussian/Gamma nonfinite responses and the corresponding ingress routes. Valid fields and unrelated count-domain controls remain green.

## Composition compatibility and scope

The earlier C1/basic C4 test file `/private/tmp/hsq-gllvm-input-fix-20260930/test/gllvm_input_guard_regression.jl` constructs GaussianResponse(Inf) inside the tuple at lines 32 and 34. With this stronger constructor, tuple evaluation throws before its loop-level test assertions. At composition, remove those invalid-constructor tuple entries and add constructor-level @test_throws ArgumentError assertions; retain the remaining bad-data/family controls. Composition requires this test adaptation. The other bundle was not edited.

This patch changes no h2, payload, VA equations, family score/weight/log-density equations, optimizer, proper-integral endpoint logic, mathematical estimand, outer failure classification, GPU support or capability status. Finite ingress does not establish numerical stability for every valid extreme value, arbitrary-design propriety, inference/calibration or fitted readiness. Direct internal family methods retain their existing contracts; validation here occurs at constructors and shared numerical-entry count checks.

## Remaining gate

No implementation defect found within the declared scope. The final receipt agrees with the bounded evidence and explicitly carries the C1/C4 compatibility requirement. Compose after the source freeze with the separately reviewed endpoint/docstring/C1 guards, update the two constructor-dependent C1/C4 controls, register the test and repin the combined source. General mathematical/propriety and outer-failure debts remain open. Exact bounded source context was already available; no new Graft lookup or broad source audit was needed.

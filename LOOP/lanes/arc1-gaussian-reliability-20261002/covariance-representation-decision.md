# Arc1 covariance representation decision

Status: awaiting Shinichi's decision. This note authorizes no change to numerical admissibility.

## Observed problem

Astra independently verified two representation problems in the retained engineering examples. Adding a positive uniqueness excess to the `1e-4` floor can round back to the floor; the present subtraction-based guard then refuses it. Residual covariance construction as a Float64 matrix can lose positive definiteness even when its positive-diagonal Cholesky factor defines a positive-definite matrix. All 22 retained numerical-gradient failures had a residual perturbation that was positive definite at 256-bit reconstruction but failed the Float64 matrix check. Selected reconstructions agreed at 256 and 512 bits.

These findings explain specific numerical pathologies. They do not establish the cause of all 238 line-search failures. The retained records lack the rejected coordinates and terminal line-search reasons needed to partition every failure. Full report: `.unlazy/arc1-gaussian-reliability/evidence/fa-failure-astra-diagnosis/review.md`. All six inspected source/test hashes remained unchanged during the 642.692-second review.

## Recommended clarification

Use the positive mathematical transform and retained covariance factors as authoritative for admissibility and bootstrap generation. Return the rounded covariance matrices with explicit precision and conditioning diagnostics. Make the evaluator, independent certificate, selector, result transport, and bootstrap use the same representation contract. A local relaxation of the optimizer's floor check is insufficient.

Keep the likelihood, variance floor, analytic derivatives, starts, BFGS/Hager-Zhang algorithm, iteration budgets, gradient thresholds, nesting checks, competitor refusal and scientific acceptance margins unchanged. Add no jitter, clipping, penalty or replacement samples. Genuine singular, nonfinite, overflow and underflow cases retain explicit refusal statuses.

This clarification changes the interpretation of the plan's existing matrix-based refusal rules. It therefore requires the user's decision before implementation. It may remove avoidable refusals; its effect on fitting reliability and interval formation remains unproved.

## Alternative

Keep the current strict predicates on the returned Float64 matrices. Representational boundary cases continue to be refused, even when their retained factors are mathematically positive. Preserve those failures in every denominator. The current engineering results do not qualify a validation pilot.

## Work that can proceed before the decision

Repair the independent profile and evidence-checker defects. Prepare observation-only diagnostics that preserve rejected evaluator and line-search reasons, copied coordinates, direction, step, value, slope and counters without changing numerical execution. Verify observation does not alter results or counts. Compare fixed retained coordinates with an independent higher-precision likelihood and gradient, including genuine invalid-proposal controls. No optimizer correction or study is implied by those checks.

Astra's initial fixed-coordinate pre-run estimate is 20 to 60 seconds, capped at 60 seconds with one Julia thread and BLAS one. This is provisional and must stop and be re-estimated if exceeded. Only after those checks and the representation decision may a separately scoped engineering replay assess a candidate correction. Confirmation still requires qualified pilots and approval of any campaign projected above three hours.

## Proposed user decision

"Use retained positive factors with explicit matrix-precision diagnostics, while preserving the statistical model, numerical thresholds, fixed starts and scientific acceptance criteria."

The user has been asked to choose this clarification or retain the strict rounded-matrix predicates. No response is recorded yet.

## Fixed-coordinate evidence retained

Luna's bounded pre-run completed all three requested retained inner-bootstrap witnesses in 8.53 seconds, with one Julia thread and BLAS one. Independent 256-bit blockwise REML objectives agreed with 384-bit evaluations to about 1e-77. Central gradients using steps 1e-14 and 1e-18 agreed to about 1e-29 and matched the frozen analytic gradients within 5.6e-17. Selected Float64 perturbations were refused while the independent high-precision objectives remained finite. A well-conditioned dense control agreed with the spectral evaluator within 1.8e-15.

The parent inspected the independent objective, full fixed-effect correction, central-difference calculation, generator reconstruction and controls, then verified all five recorded source hashes still matched. The inner responses were reconstructed from retained outer fits and exact seeds; their original consumed bytes were not retained, so bit identity cannot be proved. Finite-parameter underflow and overflow controls remain refused by the production evaluator. Their finite high-precision values do not authorize accepting them. Evidence: `.unlazy/arc1-gaussian-reliability/evidence/fa-fixed-coordinate-prerun/receipt.md` and `results.toml`.

These checks strengthen the evidence for the representation issue. They establish neither a corrected optimizer nor population reliability, and do not resolve the pending user decision.

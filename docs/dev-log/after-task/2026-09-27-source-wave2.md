# After-task: Julia source-review wave 2

## 1. Goal
Review multivariate, genetic GLLVM, non-Gaussian, and random-regression sources against baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214`, preserving unresolved model and inference risks.

## 2. Implemented
Scoped follow-up repaired beta-binomial observed curvature for final Laplace determinants, explicit constant-endpoint flat-effect refusals, and honest labels distinguishing ELBO, exact Gaussian REML, and variational-Laplace objectives. Coordinator wired observed-curvature and endpoint guards into GLLVM. A further W2-03 repair validates relationship precision and RR covariance across the reviewed entries. The four-file review remains **HOLD**; other findings remain carried.

## 3a. Decisions and Rejected Alternatives
Fisher information remains for scoring; observed curvature is used for the final determinant and non-positive-definite curvature is refused. Retained the historical numeric `elbo` field for compatibility while identifying the actual objective. General non-intercept separation and covariance fixed-point convergence were not represented as solved.

## 4. Files Touched
Review packet: `docs/dev-log/source-review/2026-09-27-wave2.md`. Reviewer follow-up: `src/nongaussian.jl`, `test/wave2_nongaussian_contracts.jl`; coordinator owns `src/genetic_gllvm.jl` wiring and shared integration. This report adds no model implementation.

## 5. Checks Run
Packet reports test-first 17 pass/20 fail/0 errors, then 37/37 for the initial single-field regressions, and a final focused 183/183 after GLLVM wiring and affected existing slices. No full-package run is attributed to this review packet.

## 6. Tests of the Tests
Observed curvature is compared with central differences of the score and the final determinant with an independent finite-difference joint log-density Hessian. Endpoint cases include Poisson/Bernoulli/binomial constant responses with an intercept and valid no-fixed-effect cases. Gaussian reduction and objective labels have dedicated assertions.

## 7a. Issue Ledger
W2-03 now has bounded independent signoff: 71/71 persistent assertions and Astra's 19/19 extra probes. Carried findings include repeatability inference model-class refusal (W2-04), extractor/heritability contracts (W2-07), inference prerequisites (W2-08), and GLLVM family/input validation (W2-09). The scale-relative PSD check (W2-06) has a separate coordinator repair. W2-02 remains open for non-intercept separation and other family cases; W2-05 covariance-loop convergence remains open. Full panel signoff is open.

## 8. Consistency Audit
All four assigned Julia source files were reviewed in full at the recorded candidate hashes. FA identifiability, GLLVM trait-mode reconstruction, Gaussian covariance ordering, and RR coefficient ordering were checked within stated spans. This does not certify the open findings or establish inference calibration or capability promotion.

## 9. What Did Not Go Smoothly
Initial package load could not write a compiled-cache pidfile in the sandbox; the deterministic probe succeeded with `--compiled-modules=no`. Graft had no matching nodes and cache refresh was blocked, so exact source reads supplied the evidence.

## 10. Known Residuals
The repair ledger is partial. Full-family boundary/separation handling, covariance validation across every entry point, inference gating, and independent specialist signoffs remain unresolved. No GPU, simulation, or full-package test claim is made for this review.

## 11. Team Learning
Keep the optimization curvature used for iteration distinct from the observed curvature required by a Laplace determinant. An objective field name is not an estimand; store and document the objective actually computed.

## 12. Cross-Product Coverage
This wave covers the four reviewed Julia source files and the scoped regressions named above. It does NOT cover every family/design boundary, all covariance and uncertainty entry points, R live parity, or validation calibration. The review remains HOLD pending dispositions and panel signoff.

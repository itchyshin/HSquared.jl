# FA foundations, candidate report

## 1. Goal

Align the Gaussian genetic FA model, local identifiability, trait units, uniqueness boundary, and engine evidence before the bounded R route is claimed.

## 2. Implemented

The four-trait, one-factor pedigree cell now has a written symbolic contract. A Jacobian rank check distinguishes locally identified interior cells from a positive-uniqueness counterexample with rank deficiency. The Gaussian FA variance floor is recorded in genetic trait units; the GLLVM FA parameterization has a different near-zero boundary. Source and validation wording now state those limits.

## 3a. Decisions and Rejected Alternatives

Fixing factor rank was not treated as a proof of uniqueness identification. A sign convention for returned metadata was retained, while inference on raw loadings remains withheld. FA and GLLVM uniqueness boundaries were disclosed separately rather than asserting a false cross-engine equivalence. `cov = fa()` grammar remains closed in R.

## 4. Files Touched

`src/multivariate.jl`, `test/runtests.jl`, `test/test_331_structured_lrt_df.jl`, `test/fa_independent_dense_reml.jl`, `docs/design/fa-t4k1-identifiability-and-units.md`, `docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`, `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`, `docs/src/validation-status.md`, `src/validation_status.jl`, `ROADMAP.md`, `GATES.md`, and `docs/dev-log/check-log.md`.

## 5. Checks Run

The local identifiability/scale checks passed 15/15. An independent dense Cholesky REML objective oracle passed 7/7 at generated and perturbed parameters. The final full `Pkg.test()` suite passed from a writable content-identical source copy (`/private/tmp/hsq-fa-gllvm-pkg-test-20260927-final4.log`); `src/` and `test/` checksum comparison found only timestamp differences. The final local documentation build exited 0 (`/private/tmp/hsq-fa-gllvm-docs-20260927-final2.log`). `preamble_cap.sh` passed.

## 6. Tests of the Tests

The rank-deficient positive-uniqueness example fails the same Jacobian identification condition that the chosen interior cell passes. The independent REML objective uses dense covariance Cholesky evaluation rather than the FA fitter's optimization implementation. Two exploratory optimizations on a four-animal fixture did not converge. A later 12-animal independent base-R BFGS fit matched the candidate G within 7.25e-6 and R within 1.58e-5, with cross-evaluated REML objectives and EBVs agreeing; see `docs/dev-log/scout/2026-09-27-fa-same-model-reference.md`. The comparison is a single near-boundary fixture.

## 7a. Issue Ledger

Fixed: rank-alone identification claim, trait-unit floor drift, and unconditional FA likelihood-ratio χ² language. A one-fixture independently fitted same-model comparison now passes. Open: an interior or external-package comparison, broad recovery/calibration, final source review, and CI.

## 8. Consistency Audit

The Julia capability row, validation debt, generated validation-status page, roadmap, and R twin partial status were checked together. The public count remains seven. Rose's final claim audit is clean with limitations for the bounded partial routes; it blocks broader covered and release claims.

## 9. What Did Not Go Smoothly

The independent four-animal fit has 12 REML contrasts against many covariance parameters; optimization from two starts did not establish an independent optimum. The source graph in the managed worktree needed exact-file fallback for changed spans.

## 10. Known Residuals

The engine's historical FA covered row is limited to its own previous evidence. This foundation adds no broad R coverage. CI, interior/external comparator evidence, and source-review panel signoff remain open. The full suite and documentation build passed from a writable source copy after the near-PSD guard and unexported VA cross-reference were corrected.

## 11. Team Learning

Memory receipt: `route.py HSquared.jl`, brain D-293, and the repo FA capability/debt rows supplied the model boundary. The owner-priority note for coverage calibration was superseded for this task by Shinichi's explicit FA/GLLVM plan; no new covered claim was made. Golden Set: not run; the negative Jacobian example and objective oracle are the scoped regressions. Rank selection and covariance identifiability must be checked separately.

## 12. Cross-Product Coverage

Covers: the symbolic Gaussian T=4, K=1 pedigree FA covariance and residual model, local identification checks, and genetic-unit uniqueness floor.

This foundation does NOT cover identification for every loading pattern, raw-loading inference, non-Gaussian uniqueness, automatic rank selection, nominal interval coverage, or a new release claim.

## 1. Goal

Obtain a scoped exact-current numerical review of the sparse Gaussian REML objective and its fitted-result contract while continuing the HSquared twin programme.

## 2. Implemented

No code changed. The reviewer confirmed the REML determinant algebra and constant under stated assumptions and recorded four ranked numerical/input/scale findings. The exact pins and scope are in the source-review packet.

## 3a. Decisions and Rejected Alternatives

Kept this as a read-only component review. Did not edit `src/likelihood.jl` because lane preflight found nine refs with work absent from this checkout. Did not infer full Wave 1 or E1 signoff from a scoped algebra review.

## 4. Files Touched

Evidence only: `docs/dev-log/source-review/2026-09-30-sparse-reml-exact-component-review.md`, `docs/dev-log/check-log.d/2026-09-30-sparse-reml-exact-component-review.md`, `GATES.md`, and this report.

## 5. Checks Run

The reviewer checked five SHA-256 pins before and after; no tests, fits, or simulations were run by the reviewer. The coordinator verified current hashes, ran lane preflight on the reviewed source and evidence paths, and checked the exact review spans. Check-log regeneration and its `--check`, `preamble_cap.sh`, and `git diff --check` passed. The after-task structural checker passed; its acceptance phase correctly returned unmet because `GATES.md` and the `hsq-gllvm-foundation`, `hsq-w105`, and `hsq-wave2-bridge` ledgers still contain open programme gates. The prose checker passed with zero findings after absolute paths were supplied.

## 6. Tests of the Tests

The review matched claimed checks to the direct tests for hand values, dense/sparse parity, fitted optimum and multistart, boundary tolerance, cached/direct equality, and large-intercept stability. It found that the current boundary assertion does not establish stationarity or optimizer convergence, rank-deficient `X` lacks an input-specific test, and final optimizer output validity is not checked.

## 7a. Issue Ledger

- Open: catch non-`PosDefException` numerical failures and validate the final objective/result.
- Open: assess convergence and the unattained zero-variance boundary against a reference.
- Open: reject or clearly diagnose rank-deficient fixed-effect designs.
- Open: measure dense-precision conversion allocation and sparse fill before any scale claim.
- Open: nine refs carry source changes absent from this checkout; E1 and Wave 1 remain open.

## 8. Consistency Audit

The source documents sparse REML as a validation path rather than the default production fitter. This review did not change capability rows, validation debt, release status, or GPU status. GATES.md records the component result without closing A2, E1, or V3.

## 9. What Did Not Go Smoothly

The project-local `tools/lane_preflight.sh` and LOAD-FIRST manifest are absent from this worktree. The canonical lane preflight was run from the brain tools directory and reported nine refs with missing work on `src/likelihood.jl`; that correctly prevented source edits in this slice. The first prose-check attempt used relative paths, which the checker resolved against its own directory; the checks were rerun with absolute paths.

## 10. Known Residuals

Scope is one Julia engine component. It does NOT cover all spans of `src/likelihood.jl`, the whole sparse or matrix-free engine, AI-REML, production scaling, the full bridge, all tracked source files, the pending FA recovery campaign, or final twin integration. No test run is inferred from a static review.

## 11. Team Learning

For transformed-parameter optimizers, separately verify the objective returned at the final minimizer and the optimizer's convergence claim. Boundary cases need an explicit reference and stationarity criterion; a small parameter difference alone is not evidence of a boundary optimum.

Memory receipt: no second-brain decision or memory file was changed. Golden Set: no new fixture was added.

## 12. Cross-Product Coverage

This is a Julia engine component review. It does NOT cover R source, formula grammar, R-Julia payload parity, user-facing FA/GLLVM documentation, external release state, or whole-source-wave signoff. E1, A2, and V3 remain open.

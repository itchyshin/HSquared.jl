# After-task report: FA fitted-likelihood information design check

## 1. Goal

Make the T4/K1 fitted-likelihood G-versus-R design identifiability condition reproducible and precise, while keeping the broader FA acceptance gate open.

## 2. Implemented

- Added expected Gaussian REML information for eight FA and ten unstructured residual covariance directions.
- Checked a repeated pedigree design and a deliberately confounded one-record unrelated design.
- Standardized information directions by trait SDs, variances, and pairwise trait scales; added a trait-unit invariance assertion.
- Corrected the design note to distinguish record-level contrasts from trait-expanded contrasts and separated relationship operator `H` from FA rank `K`.
- Registered the new test through the already registered FA multistart test file.
- No fitted capability or validation status was promoted.

## 3a. Decisions and Rejected Alternatives

- Kept the expected-information calculation in the test as an independent dense matrix oracle instead of adding a production API for one pinned design diagnostic.
- Did not use a finite-difference Hessian. The expected information is directly assembled from covariance derivative matrices, avoiding optimizer and step-size noise.
- Kept the test nested in the FA test file because `test/runtests.jl` is shared with other active work and has many unseen branch references. The existing runner includes the parent test file.
- Retained a declared relative eigenvalue threshold of `1e-8`; standardized coordinates reduce unit dependence, but the threshold remains a numerical rank diagnostic.

## 4. Files Touched

- `docs/design/fa-t4k1-identifiability-and-units.md`
- `test/test_fa_likelihood_information.jl`
- `test/test_multivariate_fa_multistart.jl`
- `GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/source-review/2026-09-29-fa-likelihood-information-design.md`
- This report

`test/runtests.jl` was inspected but not edited in this slice; it already includes the parent FA test file in the working tree.

## 5. Checks Run

- `JULIA_DEPOT_PATH=/private/tmp/hsq-fa-julia-depot:/Users/z3437171/.julia julia --project=. -e 'include("test/test_fa_likelihood_information.jl")'`: passed 4/4 in 0.5 s.
- The registered parent route, `include("test/test_multivariate_fa_multistart.jl")`, passed 69/69 in 1m58s and included the fitted-point expected-information assertions. Afterward, only the comment was changed to say "near-floor constraint concern"; the test logic was unchanged.
- `git diff --check` on the changed design and test paths: passed.
- Exact source and test SHA-256 values are recorded in `docs/dev-log/source-review/2026-09-29-fa-likelihood-information-design.md`.
- No package-wide test, docs build, simulation campaign, remote compute, or hosted CI was run for this isolated diagnostic.
- The after-task structure validator passed. The integrated closeout compiler remains red because the unlazy ledgers for this goal, Wave 1, and the Wave 2 bridge still contain unmet programme gates; it does not report a structural error in this slice's report.

## 6. Tests of the Tests

The repeated design has a relationship contrast spectrum with at least two values and its standardized expected information has numerical rank 18/18. The returned default-plus-balanced estimate on the repeated pedigree fixture also has standardized plug-in expected-information rank 18/18, while the fit diagnostic reports uniqueness near the absolute floor. The counterexample uses `Z=I`, `A=I` and one record per unrelated animal; after intercept projection it identifies only `G+R`, so the 8 FA tangent directions are contained in the 10-dimensional residual covariance tangent and numerical rank is 10/18. A further assertion confirms standardized information eigenvalues are invariant to the tested positive trait-unit rescaling. These are direct checks of the equations and pinned fixtures; no deliberate code mutation was performed.

## 7a. Issue Ledger

- Fixed: record-level and trait-expanded contrast notation had been mixed in the design note.
- Fixed: the symbol `K` was overloaded for the relationship matrix and FA factor rank; the relationship operator is now `H` in this section.
- Confirmed: algebraic FA Jacobian rank does not by itself establish likelihood separation of `G` and `R`.
- Still open: broad weak-direction and uncertainty diagnostics, routine-start recovery, inference calibration, and full A2 review. One plug-in expected-information calculation at a returned fit is recorded in this slice.

## 8. Consistency Audit

The expected covariance, derivative blocks, trait-intercept design, and ordering were checked against `src/multivariate.jl`. Noether and Fisher independently reviewed the mathematical formulation, standardization, numerical rank interpretation, and registration chain. They also reviewed the fitted-point check and confirmed that the note distinguishes plug-in expected information from observed likelihood curvature. Their reviews accepted this bounded diagnostic but did not sign off A2. The source fitter was not changed.

## 9. What Did Not Go Smoothly

The first Julia invocation could not write a compiled-module pidfile in the default depot. Re-running with a task-local writable depot passed. Review caught the contrast-basis dimension notation and requested an explicit statement that the eigenvalue cutoff is numerical; both were corrected before the final hashes were recorded.

## 10. Known Residuals

- The plug-in check at a returned estimate uses expected information, not the observed likelihood Hessian.
- The `1e-8` rank threshold is numerical, even after trait-scale standardization.
- This one design pair does not establish general identifiability, recovery, interval coverage, or LRT calibration.
- Whole A2, Julia E1, bridge parity, and the twin programme remain open.
- No release submission, public tag, GPU work, or CI result is claimed.

## 11. Team Learning

In multivariate covariance notes, define contrasts on record-level fixed effects first, then construct trait-expanded contrasts using the stated Kronecker order. Use distinct symbols for relationship and latent rank. Expected REML information at a returned covariance remains a plug-in calculation; observed curvature, recovery, and inferential calibration are separate gates.

Memory receipt: `route.py` was run but no LOAD-FIRST manifest existed for this worktree; repo documentation was used as technical truth. No cross-project scout or external literature campaign was part of this slice. Golden Set: no recovery or reference-fit result was generated.

## 12. Cross-Product Coverage

This slice covers a deterministic Julia Gaussian T4/K1 expected-REML-information design check and its documentation. It does NOT cover the public R fit route, GLLVM, missing responses, other trait/rank cells, fitted-estimate uncertainty, population recovery, interval calibration, release readiness, or remaining engine and bridge review.

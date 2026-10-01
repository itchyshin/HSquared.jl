## 1. Goal

Repair three confirmed matrix-free REML defects found during the bounded Julia
source review: scale-dependent stochastic Lanczos breakdown, loss of fixed
effects when exact log-likelihood evaluation is skipped, and missing validation
of relationship precision inputs.

## 2. Implemented

The Lanczos breakdown check now uses machine precision relative to the current
operator scale. The no-log-likelihood result wrapper retains the fitted fixed
effects while leaving the uncomputed likelihood as `NaN`.

Added a small-scale and unit-scale REML oracle test, a test that compares the
public fixed-effect extractor with the underlying matrix-free fit, and invalid
precision tests spanning the solver, trace, fit, likelihood, and information
routes, including the single-effect animal-model PCG path. Matrix-free precision
validation checks finiteness and symmetry without dense conversion, averages
only tolerance-level asymmetry before sparse Cholesky using scale-before-add to
avoid overflow for large finite entries, and reuses the same canonical
precision in downstream operations. The iterative fit validates once at entry
and reuses sparse precision log-determinants in its optional likelihood to
avoid repeated factorization.

## 3a. Decisions and Rejected Alternatives

Kept the Lanczos stopping rule relative to the latest `C*v` norm instead of
adding a user-facing tolerance. This preserves the existing API and addresses
the demonstrated unit-scale defect.

Kept the no-log-likelihood sentinel only for the unavailable likelihood. The
fixed effects are already estimated and remain valid without the optional
factorization.

Kept positive-definiteness validation sparse. Sparse Cholesky can add material
fill, but a one-time check is needed because MME curvature and PCG convergence
do not prove the supplied relationship precision is valid. The iterative fit
does this once per public fit rather than once per EM iteration. Symmetry uses
`100*q*eps(Float64)*||Ainv||∞`; tolerance-level asymmetry is averaged so
factorization and matvecs use the same matrix. This is stricter than the dense
multivariate validator's 1e-10 tolerance.

## 4. Files Touched

- `src/iterative_solve.jl`
- `test/wave1_numerical_contracts.jl`
- `test/test_matfree_reml_inci_pins.jl`
- `docs/dev-log/source-review/2026-09-27-wave1.md`
- `docs/dev-log/after-task/2026-09-28-wave1-matrixfree-fixes.md`

The Julia `GATES.md`, `docs/dev-log/check-log.md`, and coordination board were
not changed because their current lease or cross-branch ownership is held by
another lane.

## 5. Checks Run

- Red `julia --project=. -e 'using Test, HSquared; include("test/wave1_numerical_contracts.jl")'`:
  **43 passed, 1 failed**. The small-scale likelihood missed its independent
  reference by `0.0588915`; the unit-scale control passed.
- Red `julia --project=. -e 'using Test, HSquared; include("test/test_matfree_reml_inci_pins.jl")'`:
  **17 passed, 2 failed**. The public fixed-effect result was `[NaN]` instead
  of the direct fit coefficient `[10.053735076160319]`.
- Red invalid-precision regressions: **46 passed, 6 failed**. The old solver
  accepted invalid precisions on zero-RHS paths; the likelihood either accepted
  them or leaked a `PosDefException` rather than the input-contract error.
- Green `test/wave1_numerical_contracts.jl`: **79/79** assertions passed,
  including single-effect rejection, tiny-scale symmetry, canonicalization,
  fitted/direct likelihood parity, and finite canonicalization at `1e308`.
- Green `test/test_matfree_reml_inci_pins.jl`: **19/19** assertions passed.
- `Pkg.test()` from the managed candidate worktree stopped at comparator tests
  that attempted to write a packet under the read-only checkout.
- After the overflow-safe averaging repair, `Pkg.test()` from the writable
  copy `/private/tmp/hsq-wave1-precision-final4` exited 0 with
  `Testing HSquared tests passed`. Its `src/iterative_solve.jl` and
  `test/wave1_numerical_contracts.jl` SHA-256 hashes match the candidate
  (`83fdc2d2…ba45557` and `741d8af7…9cf5cc`). The copy had no Git metadata, so the
  comparator preflight emitted two Git-directory warnings; its testset passed.
- Gauss, Karpinski, and Noether signed off on the W1-12 precision-validation
  change. Their limits remain: sparse Cholesky can create substantial fill,
  the dimension-scaled symmetry threshold is a sparse-assembly policy, and the
  outer exact likelihood in `fit_matrix_free_reml` still refactors `Ainv`.
- Rose verified the writable copy against all three changed source/test files
  by SHA-256 and independently reran `Pkg.test()`; PASS for this code/test
  slice, not whole-wave signoff.
- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: `CAP OK` after W1-12 edits.
- One capped local sparse-factor microbenchmark on a synthetic banded SPD
  precision with `q=20,000` and 99,994 nonzeros took 29.4 ms for validation
  and factorization. This does not represent pedigree fill or establish broad
  scaling.
- After-task structure check: passed. The combined acceptance-ledger check
  failed closed because it could not read this checkout's `GATES.md`; programme
  acceptance state is unverified in this slice. The file is held by the
  separate FA closeout lane and was not changed.
- CI and the documentation build were not run. No documentation API changed.

## 6. Tests of the Tests

The original SLQ test failed on the small-scale oracle while passing at unit
scale; the original fixed-effect test failed on finiteness and coefficient
parity. The first invalid-precision regression set failed on acceptance/type
behavior for asymmetric, indefinite, and nonfinite matrices. Panel review then
found the omitted single-effect route, inconsistent tolerance-level symmetry
handling, and a duplicate factorization. Added regressions cover those routes
and fixes; the attempted temporary rollback to manufacture another red run was
rejected by the automatic review because it would reopen the confirmed defect.
The completed focused and package tests are green.

## 6a. Public Claim Audit

No public capability, validation status, or release claim changed. These tests
support the matrix-free precision input contract only; they do not establish
broader sparse scaling, pedigree-fill cost, or public fit coverage.

## 7a. Issue Ledger

- W1-10 fixed: absolute Lanczos stopping threshold biased small-scale log
  determinants while reporting zero probe Monte Carlo error.
- W1-11 fixed: disabling likelihood evaluation replaced estimated fixed
  effects with `NaN`.
- W1-12 repaired: single- and multi-effect public matrix-free precision routes
  reject nonsquare, nonfinite, materially asymmetric, or non-positive definite
  inputs. Tiny accepted asymmetry is canonicalized. Factor reuse is limited to
  the multi-effect matrix-free optional-likelihood path; the outer
  `fit_matrix_free_reml` exact-likelihood path still refactors `Ainv`. A narrow
  banded microbenchmark does not establish pedigree-scale cost.
- The wider wave remains open for other recorded defects, unreviewed source
  spans, exact-head CI, and panel signoff.

## 8. Consistency Audit

Checked `_lanczos_logquad`, its use in `matrix_free_reml_loglik`, the variance
and determinant terms in the two-dimensional closed-form oracle,
`fit_matrix_free_reml`, `solve_animal_model_pcg`, `fixed_effects(::AnimalModelFit)`,
and all public multi-effect matrix-free precision consumers. The sparse matrix
accepted by the validator is the one used in solves and quadratics; the same
factor supplies `log|Ainv|`, and the fit passes its computed precision
log-determinants to its private optional-likelihood path. The fixes do not
alter the R bridge or public capability status.

## 9. What Did Not Go Smoothly

The first package-wide test run could not write comparator packet files inside
the managed worktree. Re-running from a writable copy resolved the filesystem
constraint. The full run passed, though the Git-less copy printed two
comparator preflight warnings.

## 10. Known Residuals

The full package test result is from a writable copy, not from the managed
checkout; comparator checks printed two expected Git-metadata warnings. The
exact likelihood returned by `fit_matrix_free_reml` still refactors the
canonical precision in `sparse_reml_loglik`; factor reuse is limited to the
multi-effect matrix-free likelihood path described above. The
combined after-task closeout remains gated because the acceptance checker
could not read `GATES.md` from this checkout. Exact-head CI is unverified. The FA
start-dependence and uniqueness-boundary issues, GLLVM
comparator and recovery gaps, R bridge closeout, remaining Julia source-review
waves, and final panel signoff remain open. No GPU execution or release action
was performed. The code/test edits remain uncommitted on the shared
candidate branch while the separate FA closeout lane is active.

## 11. Team Learning

Read the project instructions and the TDD, systematic-debugging, and
verification-before-completion procedures. The registered candidate worktree
had no LOAD-FIRST manifest: `route.py` returned “NO manifest” for both the
managed worktree and repo path. Path-scoped leases allowed these files to be
reviewed and changed without touching the active FA closeout paths.

Golden Set: no memory-regression tool was run. This slice did not edit a named
failure-taxonomy rule; its two regressions were established directly by red
tests. No claim of broader memory regression clearance is made.

## 12. Cross-Product Coverage

Covers: Julia's single- and multi-effect matrix-free Gaussian precision-input
contract, likelihood, trace estimator, fitter, AI information, and animal-fit
fixed-effect extractor when exact likelihood factorization is disabled.

Does NOT cover: R bridge behavior, ordinary sparse REML, AI-REML, genomic
matrix-free routes, sparse validation outside the matrix-free engine,
factor-analytic fitting, genetic GLLVM, interval calibration, GPU execution,
public capability promotion, CI, or release readiness.

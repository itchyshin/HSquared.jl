# After-task: FA foundation review fixes

## 1. Goal

Close the small source and wording findings from the Gaussian FA foundation
review without changing the fitted model or promoting the capability.

## 2. Implemented

Updated the Ledermann description to distinguish nominal parameter count from
actual covariance-image codimension. Added a finite-difference check through
the fitter's production loading and log-uniqueness map. Corrected the fitted
FA descriptor to say the covariance is estimated and communality depends on
the fitted decomposition. Reconciled the old formula-grammar freeze with the
bounded current R expert-control route. A2 remains HOLD.

## 3a. Decisions and Rejected Alternatives

- Kept the nominal dimension formula and existing T4K1 gate values.
- Kept the sparse-loading rank-7 counterexample; positive Ledermann slack and
  fixed factor count do not imply local identification at every point.
- Kept raw-loading inference and uniqueness information unclaimed.
- Kept formula `cov = fa()` and broad FA routes planned.
- Did not start the 200-seed run. Totoro is available, but the estimated run is
  about 8.1 hours and still needs explicit approval after the pre-run evidence.

## 4. Files Touched

- `src/multivariate.jl`
- `src/genetic_gllvm.jl`
- `test/test_fa_uniqueness_interior.jl`
- `docs/design/54-fa-grammar-freeze.md`
- `GATES.md`
- `docs/dev-log/check-log.d/2026-09-29-fa-foundation-review-fix.md`
- `docs/dev-log/after-task/2026-09-29-fa-foundation-review-fix.md`

## 5. Checks Run

- Focused Julia FA test: 29/29 assertions passed.
- Command: `julia --project=. -e 'using HSquared, Test; include("test/test_fa_uniqueness_interior.jl")'`.
- The new finite-difference check found numerical rank 8 at generic nonzero
  loadings and rank 7 at the registered sparse-loading example.
- Julia source SHA-256 after docstring edits: `fe63bae61907c13faf593868608f8a514ac70274a5fccd4690ca952a3fd90d4e`.
- Full package tests, R checks, and documentation build were not repeated.
- After-task structure check passed; the prose check returned 0 findings;
  `git diff --check` passed.
- Acceptance ledger status: A2, E1, and V3 remain unmet; 8 other gates are met.

## 6. Tests of the Tests

The derivative is calculated by central finite differences of
`_structured_genetic_params_to_cov`, including the production uniqueness floor
and exponential transform. The test retains both a generic full-rank point and
the known rank-deficient point. The threshold is relative to the largest
singular value. It covers the covariance map; likelihood information remains
unassessed.

## 7a. Issue Ledger

- Fixed: Ledermann slack prose implied nonnegative covariance codimension for
  every accepted `(t, K)`.
- Fixed: no executable test tied the written Jacobian calculation to the
  production covariance parameter map.
- Fixed: fitted-result descriptor called `G` identified and omitted the
  decomposition dependence of communality.
- Fixed: the old grammar freeze still said the bounded R bridge rejected FA.
- Open: fitted likelihood information, ordinary-start recovery, floor
  sensitivity, inference calibration, and broader cells.

## 8. Consistency Audit

The engine equations remain `G = ΛΛ' + diag(ψ)` with separate unstructured
residual covariance. The test's coordinates match the optimizer representation
used by the fitted FA route. Documentation now separates the current partial
expert-control R route from the still-planned formula parser. Capability count,
release state, public status, and optimizer behavior were not changed.

## 9. What Did Not Go Smoothly

The lane preflight surfaced historical cross-branch edits to the FA engine and
grammar document. The active candidate coordination board assigns this bounded
FA work to the current lane; a scoped lease was obtained before editing. No
other lane's edits were reverted.

## 10. Known Residuals

- The panel's FA engine disposition remains HOLD. Current reviews support only
  conditional T4K1 algebra and point-estimate interpretation.
- A finite-difference covariance-map rank does not establish local information
  in the REML fit.
- Ordinary-start recovery and the held primary study remain unresolved.
- This slice did not run full Julia/R checks or change any release candidate.

## 11. Team Learning

Noether's estimand review and Kirkpatrick's G-matrix review both distinguish a
nominal factor parameter count from pointwise covariance decomposition
identification. Binding the written Jacobian to the production map makes that
distinction executable while preserving the explicit inference limit.

## 12. Cross-Product Coverage

Covers the Julia T4K1 FA covariance map and the current R expert-control versus
formula-parser documentation boundary. Does not cover wider FA/GLLVM cells,
R-Julia parity for these wording-only changes, uncertainty calibration,
source-wave completion, GPU work, or any submission, tag, or release.

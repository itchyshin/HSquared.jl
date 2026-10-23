## 1. Goal

Restore validation of dense Gaussian relationship precision and fit-method inputs, add regressions, and obtain independent review of the exact changed source and tests.

## 2. Implemented

`_dense_relationship_covariance` now rejects non-finite and asymmetric input before Cholesky. `fit_variance_components` again rejects methods other than ML and REML. Tests cover invalid methods, indefinite precision despite a positive-definite marginal covariance, asymmetry, and non-finite precision. The previously validated inverse operation was preserved after a solve-based alternative perturbed the near-boundary #350 fixture.

## 3a. Decisions and Rejected Alternatives

Kept exact symmetry validation, matching the existing genomic-input contract; the function does not silently average or repair an asymmetric precision. Retained the original inverse calculation because the earlier factor-solve substitution changed a near-boundary quickstart result. No public syntax or capability status changed.

## 4. Files Touched

- `src/likelihood.jl`
- `test/wave1_numerical_contracts.jl`
- `docs/dev-log/source-review/2026-09-29-dense-relationship-precision.md`
- `docs/dev-log/check-log.d/2026-09-29-dense-relationship-precision.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-09-29-dense-relationship-precision.md`
- `docs/dev-log/coordination-board.md`

Other dirty files in this worktree pre-date this slice and were left untouched.

## 5. Checks Run

- Focused `wave1_numerical_contracts.jl` run with Julia 1.10 and the task-local depot: passed. The main numerical contract set reported 126/126; the added precision sets reported 4/4 each. Existing genomic relationship, APY finite/scale, and APY partial-core sets reported 16/16, 8/8, and 5/5.
- Full `Pkg.test()`: exit 0; output ended `Testing HSquared tests passed`.
- `git diff --check -- src/likelihood.jl test/wave1_numerical_contracts.jl test/runtests.jl`: passed.
- Exact-hash source reviews: Gauss PASS and Noether PASS. Both reviews were static and did not run tests or fits.

## 6. Tests of the Tests

Before the implementation change, the focused test run failed because the fitter accepted an invalid method and `gaussian_loglik` accepted asymmetric precision. After the fix, both regressions passed. The non-finite precision and indefinite-precision tests also pass.

## 7a. Issue Ledger

- Fixed: unsupported method could flow through the fitter's non-ML branch.
- Fixed: asymmetric dense relationship precision could be silently interpreted through `Symmetric`.
- Fixed: non-finite values are now explicitly rejected before factorization.
- Deferred: direct asymmetric/non-finite fitter assertions and error-message assertions; shared helper coverage is present, but these would improve direct route coverage.
- Carried: FA A2, Julia source-review E1, and GLLVM V3 acceptance remain open.

## 8. Consistency Audit

Checked both dense Gaussian entry points and their shared helper, preserving the positive-definiteness guard and the existing quickstart boundary behavior. No R bridge, multivariate FA path, sparse optimizer contract, or public docs were changed. The nearby dense conditioning limitation remains documented in `V1-DENSE-COND`.

## 9. What Did Not Go Smoothly

The first test launch attempted to write into the protected default Julia depot; rerunning with the task-local depot worked. The full suite then exposed its expected long FA fixture, which completed successfully. The generic closeout generator resolves its output root from its own installation under the brain, so it could not write this repository report in the sandbox; this report was created directly in the authorized worktree. Extending the central lane lease also returned a filesystem permission error, although the existing exact source/test lease remained live and preflight showed no other live Julia lane.

## 10. Known Residuals

No direct fitter assertion covers asymmetric or non-finite precision, although the fitter uses the same tested helper. This does not complete a source-review wave, FA/GLLVM acceptance, R–Julia parity, broad recovery, or any release gate. The worktree remains broadly dirty from earlier slices; those changes were preserved. No GPU work or release action was performed.

## 11. Team Learning

When converting a relationship precision into a covariance, validate the raw matrix before applying a wrapper that can select one triangle. Preserve established numerical operations around boundary-sensitive fixtures unless an alternative is proven equivalent there. Memory receipt: the brain search was run in `shinichi-brain`, but returned no directly relevant HSquared lane note; repository `GATES.md`, `docs/dev-log/coordination-board.md`, and the existing source-review receipts were used as the technical record. The temporary-worktree route command had no LOAD-FIRST manifest. Golden Set: not run; no mapped Golden Set case was identified for this narrow dense Gaussian input guard.

## 12. Cross-Product Coverage

Covers: dense Gaussian `gaussian_loglik` and `fit_variance_components`, with ML and REML method validation and relationship precision domain checks.

This does NOT cover: sparse Gaussian optimizers; multivariate FA uniqueness or rank selection; non-Gaussian GLLVM; R formula or bridge behavior; general recovery, calibration, or inference; GPU; releases or tags.

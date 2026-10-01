## 1. Goal

Close the reproduced optimizer underflow failure across bounded Gaussian covariance and log-variance fitters, including the result contracts that require genetic correlations or positive variance ratios.

## 2. Implemented

- Multivariate REML now rejects nonfinite residual covariance and inadmissible genetic covariance at both objective evaluation and fit-attempt selection. Unstructured, diagonal, and FA genetic covariance must be positive definite. Pure low-rank covariance may be singular when every trait has positive marginal genetic variance.
- Multivariate repeatability, direct-maternal, random-regression, scalar repeatability, two-effect, and K-effect dense fits now reject underflowed/overflowed covariance or variance proposals, nonfinite objective minima, and invalid decoded variances before final solves or ratio construction.
- Explicit initial variances on the covered scalar routes are required to be finite and positive. Total-variance ratios reject a nonfinite total.
- Added focused helper, objective, and initial-value regressions. No capability row, covered count, release, or public feature claim changed.

## 3a. Decisions and Rejected Alternatives

- Kept shared raw transforms available and enforced numerical validity at the owning optimizer and post-fit boundaries.
- Rejected allowing zero marginal genetic variance in a multivariate returned fit because `genetic_correlation` requires positive trait variances. Preserved singular positive-diagonal G for the pure low-rank route.
- Did not extend this slice to all likelihood optimizers, inference calibration, or experimental feature promotion.

## 4. Files Touched

- `src/multivariate.jl`
- `src/likelihood.jl`
- `src/random_regression.jl`
- `test/test_multivariate_repeatability.jl`
- `GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-09-29-optimizer-covariance-boundaries.md`
- `docs/dev-log/source-review/2026-09-29-optimizer-covariance-boundaries.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-optimizer-covariance-boundaries.md`

## 5. Checks Run

- Focused repeatability and covariance-boundary tests: 89 assertions passed, including underflowed residual covariance, underflowed unstructured genetic covariance, invalid low-rank marginal variance, scalar exp underflow/overflow, infinite initial variances, and the known-truth repeatability fixture.
- Final Julia 1.10 `Pkg.test()` exited 0 and printed `Testing HSquared tests passed` and `PKG_TEST_DONE` on the source hashes below.
- `git diff --check` passed on the four source/test files.
- Gauss, Karpinski, and Noether reviewed the exact final numerical candidate. Their scoped reviews passed; none ran tests or fits. Rose's refreshed evidence and public-claim audit was clean with limitations.
- Julia reported that project dependencies or compat differ from the resolved manifest. No resolve or update was run.

## 6. Tests of the Tests

The residual underflow regression constructs singular `R0` from `exp(-1000)` and requires an infinite objective. The genetic underflow regression sets both unstructured Cholesky log-diagonals to `-1000` and requires an infinite objective. Transform tests verify zero and infinite exponentials return `nothing`; initial-value tests require an `ArgumentError` before optimization. The full suite also exercises ordinary successful repeatability and multi-effect fits.

## 7a. Issue Ledger

- Fixed: a singular residual covariance could yield a finite multivariate REML objective.
- Fixed: underflowed scalar variances and neighboring covariance blocks could proceed to final solves or return invalid ratios.
- Fixed: a zero genetic marginal variance could pass fit-attempt selection and fail later when genetic correlations were built.
- Open: direct targeted execution of every fitter's optimizer/post-fit failure branch; the current tests combine transform-level tests, the multivariate objective regression, invalid-initial checks, and full normal-path regression coverage.
- Open: other optimizers outside these named covariance/log-variance paths, broader source-review waves, and all FA/GLLVM recovery and inference gates.

## 8. Consistency Audit

The prior `2026-09-29-fa-residual-boundary.md` records the earlier residual-only source snapshot and must not be read as the final cross-fitter candidate. This follow-up records the exact final source and test hashes used by the integrated test run. Rose verified the hashes and their link to focused/full test evidence, and found no relevant public claim or capability promotion. Capability status, validation-debt rows, and `public_covered_count` remain unchanged; A2, E1, and V3 remain open.

## 9. What Did Not Go Smoothly

Review found neighboring finite-exponential gaps after the first residual-only repair, so the guard was extended to related fitters. Noether then found that zero genetic variance could pass candidate selection but fail during correlation extraction; the objective and selection predicate now share the same admissibility rule. The first objective-level regression attempt used `nothing` where the internal API requires an integer rank; the fixture was corrected, and the focused test then passed.

## 10. Known Residuals

The package still reports a project/manifest mismatch warning. The focused test does not force every fitter's optimizer to terminate at each invalid post-fit value; those checks are statically reviewed and complemented by helper/objective and successful-fit coverage. This slice does not establish FA likelihood identification, ordinary-start population recovery, interval coverage, GLLVM recovery, or full Julia source-review signoff.

## 11. Team Learning

Screen optimizer proposals where the likelihood contract is owned, then validate decoded estimates before result construction. For covariance structures whose results expose correlations, test the marginal-variance contract before selecting a fit. Review sibling transform callers before changing a shared conversion routine.

## 12. Cross-Product Coverage

Covers only Julia numerical boundaries in the named Gaussian covariance and log-variance fitters. It does NOT cover or validate the R bridge, add a capability, close A2/E1/V3, run GPU work, or authorize CRAN/Julia registry submission, merge, or a release tag.

Final SHA-256 values:

- `src/likelihood.jl`: `cd36e0c21802c9f4c71e9a0980ece50e926b7bb3337a3efc9442ef88365b8f11`
- `src/multivariate.jl`: `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670`
- `src/random_regression.jl`: `761151eb0297bece4c859db8a504a244a26510d320f123f85a9a9295621e7a5c`
- `test/test_multivariate_repeatability.jl`: `276017e88ebf8b266d3b613166cf43ed81f7ae31144c73e79c35a7a8e13a6d87`

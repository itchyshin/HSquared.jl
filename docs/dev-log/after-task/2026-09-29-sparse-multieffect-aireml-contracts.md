# After-task: sparse multi-effect AI-REML contracts

## 1. Goal

Close the reviewed input and numeric-control gaps in `fit_sparse_multi_effect_aireml` and its shared multi-effect REML workspace without changing the model for valid inputs.

## 2. Implemented

- Validate iteration count, EM warmup, tolerance, and initial variance values before fitting. Numeric values must remain finite and usable after conversion to `Float64`.
- Reject nonfinite converted `y`, `X`, `Z`, and relationship precision inputs. Reject nonfinite or nonpositive EM/AI variance updates and an invalid final variance total.
- Validate each converted sparse relationship precision for symmetry and positive definiteness. Average only accepted roundoff asymmetry and store that canonical sparse matrix before constructing MME, log-determinant, score, or quadratic state.
- Add regression checks for invalid controls, overflowing starts, nonfinite model inputs, materially asymmetric precision, and roundoff canonicalization.

## 3a. Decisions and Rejected Alternatives

- Reuse `_validate_matrix_free_precision`, which already checks and canonicalizes sparse precision without densifying it. This makes the workspace use one precision consistently for factorization and quadratic calculations.
- Do not accept arbitrary asymmetry by relying on `Symmetric(Ainv)`, because it can select one triangle while other expressions consume the full matrix.
- Retain the existing finite positive starting values and default controls; validation only rejects unusable inputs and updates.

## 4. Files Touched

- `src/likelihood.jl`
- `test/test_aireml_workspace_reuse.jl`
- `docs/dev-log/source-review/2026-09-29-errors-planned-terms.md`
- `docs/dev-log/check-log.d/2026-09-29-errors-planned-terms.md`
- `docs/dev-log/after-task/2026-09-29-sparse-multieffect-aireml-contracts.md`
- `docs/dev-log/source-review/2026-09-29-sparse-multieffect-aireml-contracts.md`
- `docs/dev-log/check-log.d/2026-09-29-sparse-multieffect-aireml-contracts.md`

## 5. Checks Run

- Before the implementation, the new invalid-control, overflow, and nonfinite-input assertions failed against the old behavior.
- Focused registered workspace test passes 51/51.
- Full Julia `Pkg.test()` passes and ends with `Testing HSquared tests passed` after the final source and test changes.
- `git diff --check` passes for the changed source and test files.
- Gauss and Noether reviewed the exact final source/test hashes and both passed. Their review confirmed sparse canonicalization and consistent downstream use.
- Scoped exact-current reviews passed for `src/errors.jl` and `src/planned_terms.jl`; their two low-severity test/documentation mismatches are recorded as carried findings in the source-review packet. Full E1 signoff remains open.
- The repository's existing Project/Manifest mismatch warning remains; no resolve or update was run.
- The integrated after-task acceptance checker still reports open programme gates, documented as such in the report. This slice does not close those gates.

## 6. Tests of the Tests

The added assertions were checked against the pre-fix implementation and reproduced missing validation. The final tests exercise invalid controls and starts, nonfinite converted inputs, early rejection of material asymmetry, and storage of the arithmetic average for tolerated roundoff. The full suite executes the registered test file.

## 7a. Issue Ledger

- Fixed: invalid optimization controls and unrepresentable starts could be accepted; nonfinite converted workspace inputs lacked early rejection; an asymmetric precision could make the factorization and quadratic terms represent different effective matrices.
- Open: FA likelihood-information and broad ordinary-start evidence, public R opt-in usability, GLLVM acceptance and bridge parity, remaining source-review spans, and twin closeout remain outside this slice.
- Carried in exact-current source review: test that `Phase0NotImplementedError.showerror` retains its operation string, and align the `formula_status()` table prose with the exact status values. Foreign-ref differences prevented safely editing the relevant files in this slice.

## 8. Consistency Audit

The workspace now stores only the validated canonical sparse precision. MME assembly, log determinant, selected-inverse score terms, random-effect quadratic terms, and later AI steps all consume that stored matrix. The focused and full suites pass. No capability, validation-debt, public-claim, or covered-count row changed.

## 9. What Did Not Go Smoothly

The first exact-hash review identified a pre-existing asymmetry gap in the multi-effect precision contract. I addressed it with the existing sparse validator and reran the focused and full suites. The Graft index does not have a readable sync lock in this checkout; its returned spans were verified against current source. Lane preflight showed existing foreign-ref differences in shared aggregate logs, so this slice did not edit `docs/dev-log/check-log.md` or `docs/dev-log/coordination-board.md`.

## 10. Known Residuals

This closes only the scoped sparse multi-effect AI-REML input contract. The full approved HSquared twin programme remains active. FA and GLLVM public R routes, their full validation gates, the remaining Julia engine and bridge review, cross-twin closeout, and their acceptance ledgers remain open. No GPU work, release or registry submission, merge, or tag occurred.

## 11. Team Learning

When a sparse precision is accepted with floating-point asymmetry tolerance, canonicalize it once and pass that exact sparse matrix to every factorization, MME, score, and quadratic operation.

## 12. Cross-Product Coverage

This slice covers Julia's sparse multi-effect Gaussian REML workspace and its AI-REML fitter. It does NOT cover the Gaussian FA or Poisson genetic GLLVM public R routes, all Julia source-review waves, broad inferential coverage, or release status.

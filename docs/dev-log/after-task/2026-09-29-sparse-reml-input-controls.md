# After-task: sparse REML input controls

## 1. Goal

Repair direct sparse REML and AI-REML input validation exposed by the integrated Julia test suite, while preserving the established likelihood for valid inputs.

## 2. Implemented

Direct sparse likelihood and sparse AI-REML now validate the relationship precision with the existing sparse symmetry and positive-definiteness checker. They use one canonical precision for the prior determinant and mixed-model equations. If tolerated roundoff asymmetry is averaged, stale `relationship_diag` metadata is cleared. Already-canonical inputs retain their original spec object. Sparse, matrix-free, and AI-REML optimization routes now reject unusable iteration counts; sparse and AI-REML starts also reject variances whose converted precision is not representable.

## 3a. Decisions and Rejected Alternatives

- Use the existing sparse precision validator so the direct REML route shares the same symmetry and positive-definiteness contract as the matrix-free route.
- Clear cached relationship-diagonal metadata when the supplied precision is averaged. Do not carry forward a diagonal that may describe a different matrix.
- Keep the exact-input identity path so canonical inputs retain the original model spec.

## 4. Files Touched

- `src/likelihood.jl`
- `src/iterative_solve.jl`
- `test/test_sparse_aireml_input_contracts.jl`
- `docs/dev-log/check-log.d/2026-09-29-sparse-reml-input-controls.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-sparse-reml-input-controls.md`

## 5. Checks Run

- Regression checks failed before the relevant fixes: eight relationship-precision assertions failed first; after that repair, two sparse optimizer iteration assertions failed; the added sparse-fit checks then exercised missing iteration and variance-precision guards.
- Focused sparse REML contract tests pass 26/26.
- Full Julia 1.10 `Pkg.test()` exits successfully and ends with `Testing HSquared tests passed`.
- `git diff --check` passes for the changed source and regression test files.
- The existing Project/Manifest mismatch warning remains. No resolve or update was run.
- The after-task structure validator passes. Its acceptance-ledger check remains unmet because the overall A2, E1, and V3 gates are open, with linked W105 and Wave 2 bridge G4 gates also open; the GLLVM foundation ledger has two runnable checks that are marked but not executed.

### Review lenses

Gauss reviewed sparse numerical behavior and Noether reviewed the likelihood contract. Both passed the exact final source and test hashes recorded in the check-log receipt. No public capability changed, so no public-claim audit or Rose review was needed for this repair.

## 6. Tests of the Tests

The regression suite reproduced failures for malformed precision, zero or negative optimizer iterations, and unrepresentable starting variance precision before the corresponding repairs. The end-to-end direct likelihood check confirms tolerated roundoff asymmetry agrees with an explicitly averaged precision for both log-likelihood and fixed effects. It also checks stale diagonal metadata is removed and canonical inputs preserve spec identity.

## 7a. Issue Ledger

- Fixed: direct sparse REML and sparse AI-REML did not reject malformed relationship precision as `ArgumentError`; sparse, matrix-free, and AI-REML optimizer routes accepted unusable iteration counts; sparse starts did not reject unrepresentable Float64 precisions.
- Open: FA likelihood-information and routine-start evidence, whole-source review, and cross-twin closeout remain outside this repair.

## 8. Consistency Audit

Confirmed that direct sparse likelihood uses the same canonical precision for the prior log determinant and MME. Confirmed canonical input preserves spec identity, roundoff asymmetry clears derived diagonal metadata, and invalid controls fail before optimization. The full test suite exercises the regression file alongside existing FA, GLLVM, bridge, and pedigree checks. No capability, validation-debt, or covered-count row changed.

## 9. What Did Not Go Smoothly

The first focused Julia invocation could not write to the protected home cache. Using the existing Julia cache with the approved test command resolved that environment issue. The first full package run exposed a sparse input-contract failure; the next found an object-identity regression in the repair. Both were corrected before the final passing run. The candidate is the existing Codex worktree at HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`. Lane preflight found no live lease overlapping `src/likelihood.jl` or the sparse contract test; `src/iterative_solve.jl` was already owned by this goal lane. Older remote branch differences were inspected. The separate 200-seed FA study remains held for approval and was not run.

## 10. Known Residuals

The scoped sparse REML validation issue is closed. This does not close Gaussian FA inference, Poisson GLLVM acceptance, the remaining Julia source review, or cross-twin closeout. A2, E1, and V3 remain open. No simulation, GPU work, R bridge change, release submission, registry submission, merge, or tag occurred. No capability status, validation-debt row, public wording, version, or covered count changed.

## 11. Team Learning

When a symmetric precision is canonicalized, use that same matrix for both the mixed-model equations and prior determinant, and invalidate metadata derived from the pre-canonicalized matrix. Preserve the original spec when canonicalization makes no change.

## 12. Cross-Product Coverage

This change covers Julia Gaussian direct sparse REML, AI-REML, and related optimizer input validation. It does NOT cover R bridge parity, FA or GLLVM model acceptance, the remaining Julia source-review waves, unusual inheritance, GPU computation, or release readiness.

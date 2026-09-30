# After-task report: iterative-solver E1 repair

## 1. Goal

Repair the exact-current PCG/REML contract findings for rank-deficient fixed effects, invalid likelihood iteration budgets, and misleading uncertainty wording.

## 2. Implemented

Added sparse-QR fixed-effect rank validation to the iterative solve, trace, fit, likelihood, and information routes, with an explicit valid `p = 0` path. The matrix-free likelihood rejects `pcg_maxiter < 1` before solving. Its docstring now separates exact determinant terms, SLQ approximation error, PCG solve error, and the between-probe MCSE limitation.

## 3. Active lenses and agents

Gauss/Astra reviewed the implementation before the final two documentation-only edits. Noether confirmed the current source hash and resolved math wording. Rose reviewed the current exact hash and returned clean-with-limitations. Karpinski found no sparse dispatch/densification issue, but flagged repeated QR cost inside iterative fits. Other current pedigree findings remain separate and open.

## 3a. Decisions and Rejected Alternatives

Kept full-column-rank validation because the MME is singular when fixed-effect columns are linearly dependent under the stated positive variance and precision assumptions. Kept the valid `p = 0` case. Did not interpret positive rank of the covariance map or a low MCSE as evidence of likelihood identifiability or total likelihood accuracy. No capability or release status changed.

## 4. Files Touched

- `src/iterative_solve.jl`
- `test/wave1_numerical_contracts.jl`
- `docs/dev-log/source-review/2026-09-30-iterative-solver-e1-repair.md`
- `docs/dev-log/check-log.d/2026-09-30-iterative-solver-e1-repair.md`
- `docs/dev-log/after-task/2026-09-30-iterative-solver-e1-repair.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `GATES.md`

No capability-status or validation-debt row changed.

## 5. Checks Run

- Final focused command: `julia --project=. test/wave1_numerical_contracts.jl`; 152/152 Wave 1 assertions passed.
- Full command: `julia --project=. -e 'using Pkg; Pkg.test()'`; exit 0, final output `Testing HSquared tests passed`.
- Documentation command: `julia --project=docs docs/make.jl`; exit 0, local rendering completed. Documenter reported 47 docstrings not included in the manual and Vitepress reported a large bundle chunk; no build failure occurred.
- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: passed, 11,024 bytes under the 14,000-byte cap.
- `bash tools/build_check_log.sh --check`: all 250 check-log shards well-formed.
- Full package testing emitted a warning that Project dependency/compatibility requirements differ from the last resolved Manifest. No package resolve or update was performed.

## 6. Tests of the Tests

Before the source fix, the regressions failed because duplicate/zero fixed-effect columns passed the affected routes and zero-response likelihoods accepted zero or negative PCG budgets. The Lanczos regression uses a three-dimensional diagonal covariance: two steps produce a different likelihood from the exact three-step/reference result despite an effectively zero between-probe MCSE. The reference includes the full Gaussian normalizing constant. Final focused and package suites pass.

## 7a. Issue Ledger

- Closed in this slice: sparse fixed-effect rank validation bypass; nonpositive PCG likelihood budget bypass; docstring implication that MCSE captures total likelihood error.
- Carried: all unreviewed portions of the Julia engine and bridge; separate pedigree wrapper keyword, group-label alignment, mutable-state, and pedigree/ID-order findings; broad FA recovery and inference gates.

## 8. Consistency Audit

The bounded Gauss/Astra, Noether, Karpinski, and Rose reviews found no blocking defect in this component. The final source hash is `41f50393dd75dfca942f8b53b06ad1a7b50419cdecf3d7d74e3e34605ee06ef2`; focused tests were rerun and pass 152/152. The full package test and docs build passed just before the final two documentation-only edits, so they are not exact-current-source attestations. A warm guard-only timing check at n=5000 measured 0.000166 s / 0.74 MB for p=20 and 0.00840 s / 15.3 MB for p=200, five calls each. Full-fit impact, peak memory and near-collinear rank behavior remain unmeasured. No capability status, covered count, API route, or release claim changed. E1, A2, and V3 remain open; this report is not whole-wave signoff.

## 9. What Did Not Go Smoothly

The first analytic likelihood assertion omitted the Gaussian normalizing constant and failed. I corrected the independent reference to include `3*log(2π)` and reran the focused suite successfully. The first documentation-build attempt could not write generated output inside the managed worktree; the approved rerun completed the local build. No source or generated files were reverted.

## 10. Known Residuals

Sparse QR adds a fixed-effect rank check at the covered routes. The measured guard-only benchmark does not establish full-fit cost, peak memory, or near-collinear rank decisions. The component review does not cover every span in `iterative_solve.jl`, other Julia source files, the entire R bridge, FA likelihood identification, or population recovery. The docs build does not establish deployment. No long simulation was run.

## 11. Team Learning

Precondition checks can be mathematically required yet still become repeated work inside an iterative algorithm. Source-level sparsity is not enough to establish acceptable performance; measure the real fit path at representative fixed-effect widths. Keep that performance question separate from the rank-correctness result. Next, continue the remaining Wave 1 and pedigree source spans, measure full-fit cost for repeated rank QR, and update E1's coverage ledger. Keep A2 and V3 acceptance gates open.

## 12. Cross-Product Coverage

Continue the remaining Wave 1 and pedigree source spans, including a measured full-fit cost check for repeated rank QR, and update E1's coverage ledger. Keep A2 and V3 gates open until their full acceptance criteria pass.

This slice covers the Julia experimental matrix-free REML solver, trace, fit, likelihood, and information paths and the corresponding focused numerical tests. It does NOT cover the R Gaussian FA or Poisson genetic GLLVM routes, other Julia engine surfaces, missing-data behavior, or the full twin programme. No cross-product API or capability status changed.

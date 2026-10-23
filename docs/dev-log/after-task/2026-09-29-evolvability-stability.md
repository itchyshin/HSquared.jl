# After-task: evolvability numerical stability

## 1. Goal

Close the numerical findings in the exact-current review of G-matrix evolvability utilities without promoting the experimental capability.

## 2. Implemented

Added scale-normalized Cholesky for inverse metrics, a maximum condition-number bound of `1/sqrt(eps(Float64))`, scale-safe covariance summaries, representability checks, and max-absolute-value normalization for finite selection-gradient vectors. Made trait-coordinate and trait-unit dependence visible in documentation. The `V4-EVOLVE` row remains partial.

## 3a. Decisions and Rejected Alternatives

The accepted condition threshold is an explicit input boundary. It is not evidence that all positive-definite matrices at arbitrary scales are safe. We did not claim trait-unit invariance, add raw-loading claims, or promote capability status.

## 4. Files Touched

`src/evolvability.jl`, `test/test_evolvability_stability.jl`, `test/runtests.jl`, `docs/src/multivariate-models.md`, `docs/design/validation-debt-register.md`, `docs/dev-log/source-review/2026-09-29-evolvability-current-review.md`, `docs/dev-log/check-log.d/2026-09-29-evolvability-stability.md`, `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`, and this report.

## 5. Checks Run

- Focused stability test: 18/18 passed.
- Full Julia 1.10 `Pkg.test()`: exit 0, ended `Testing HSquared tests passed`.
- `git diff --check`: passed.
- Docs build passed earlier on unchanged manual bytes; not repeated after ledger/report-only edits. Existing generated-document warnings are recorded in the source-review receipt.
- Exact source and test hashes are in `docs/dev-log/check-log.d/2026-09-29-evolvability-stability.md`.

## 6. Tests of the Tests

Regressions first failed for ill-conditioned autonomy, extreme finite covariance scales, unrepresentable eigenvalues, and overflow/underflow in finite gradient norms. Final assertions compare regular, huge, and subnormal vectors in the same non-isotropic direction, including autonomy.

## 7a. Issue Ledger

Numerical defects identified in the bounded source review are repaired and covered. The external comparator and wider conditioning campaign remain open; no campaign was run.

## 8. Consistency Audit

The source-review receipt, debt register, check-log, manual, and coordination board agree that this remains a descriptive partial capability with trait-coordinate dependence. No version, covered count, or fitted-capability claim changed. The wide candidate checkout contains other work in progress; no unrelated changes were staged, committed, pushed, merged, or reverted.

## 9. What Did Not Go Smoothly

The repo-local preflight script is absent from this worktree. The hub preflight surfaced an old handover naming Claude; the existing Codex lane lease was live, and this closeout retained its explicit identity and added the required paths. An initial lease attempt used a fallback identity and was immediately released before the correct explicit lane ID was claimed. The first report-validation attempt also revealed the required heading schema, which is now applied.

## 10. Known Residuals

The condition ceiling does not establish broad conditioning performance or trait-unit invariance. External comparator evidence, fitted-FA inference, uncertainty calibration, whole Wave 4 signoff, and full E1 remain open. No GPU work or release action was performed.

## 11. Team Learning

Testing the same direction under non-isotropic `G` is needed to verify that extreme-vector normalization preserves direction, not merely unit norm. Keep this as a reusable check for future scale-sensitive directional metrics.

## 12. Cross-Product Coverage

This closeout covers Julia descriptive utility numerics, Julia tests, and the Julia manual. It does NOT cover the R formula/API, R-Julia bridge payload or parity, Gaussian FA fitting acceptance, genetic GLLVM fitting acceptance, other providers, or any release surface.

# PR 496 signed-design selected-inverse correction

## 1. Goal

Handle valid signed design matrices when sparse Hessian entries cancel.

## 2. Implemented

For record rows or prior-precision columns requiring values outside the
selected-inverse pattern, solve with the existing sparse factor. Entries in the
selected pattern retain the existing fast path. No dense inverse is formed by
the fit path. Worst-case work includes one additional sparse solve per affected record row
and per affected precision column; runtime can increase substantially.

## 3a. Decisions and Rejected Alternatives

A missing selected entry cannot be treated as zero: an inverse may be nonzero
through indirect paths. Factor solves preserve the contribution without a dense
inverse. Assumption: rare cancellation makes selective solves suitable; large
signed-design performance has not been measured.

## 4. Files Touched

`src/nongaussian.jl`, `test/test_issue_421_sparse_laplace.jl`, this report,
and `docs/dev-log/check-log.d/2026-11-04-pr496-signed-design.md`.

## 5. Checks Run

On Julia 1.12.6 with one BLAS thread and two Julia threads, the complete
`test/test_issue_421_sparse_laplace.jl` file passed 194 assertions. This includes
existing dense-reference and q=2000 allocation/time checks. `git diff --check`,
`bash tools/build_check_log.sh --check`, and `bash tools/preamble_cap.sh` are
recorded separately in the check shard. Full package CI remains required.

## 6. Tests of the Tests

Before the fix, the signed-design regression raised the missing-pattern
`ArgumentError`. A second red test confirmed an explicit stored zero could
incorrectly trigger a fallback solve. Afterward it agrees with the dense reference. A second fixture
has an inverse entry outside the selected pattern that is explicitly nonzero;
both row quadratic and trace match dense linear algebra.

## 7a. Issue Ledger

The new cases address PR #496's sparse variational path. Issue #421 remains open.

## 8. Consistency Audit

Reviewed both selected-inverse consumers: record quadratics and precision
trace. Their fallback solves use the same factor as the covariance. Project
routing and path leases were checked. The Golden Set was not run because no
hub guard changed. Independent review checked factor permutations against
dense inverses and identified an explicit-zero fast-path test, now added.

## 9. What Did Not Go Smoothly

The former assertion that every pair sharing a design row remains in the
Hessian pattern fails when signed terms cancel.

## 10. Known Residuals

The repo-root after-task validator reports existing unmet `GATES.md` entries;
these were not changed. Large signed-design runtime, native Windows execution
and full package CI are not yet verified. The existing broad non-interrupt factorization fallback and
changing factor patterns are separate review questions.

## 11. Team Learning

Selected inverse entries outside a factor pattern require an exact alternative;
structural zeros in a matrix do not imply zero entries in its inverse.

## 12. Cross-Product Coverage

The new tests cover a Gaussian signed-design public call, its sparse fit path,
and direct helper cases. It does NOT cover every response family, large signed matrices, calibration,
performance claims, or scientific validation gates.

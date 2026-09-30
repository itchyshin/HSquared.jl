## 1. Goal

Review two open Julia numerical components against exact source pins and their direct tests.

## 2. Implemented

Completed read-only exact-current reviews of `src/takahashi_selinv.jl` and `src/iterative_solve.jl`; recorded findings, evidence, and validation limits.

## 3a. Decisions and Rejected Alternatives

- Keep the two component verdicts separate from whole-wave E1 signoff.
- Carry performance and severe-conditioning evidence gaps explicitly; do not imply performance guarantees from small correctness fixtures.
- Do not change source code or capability claims in this review-only slice.

## 4. Files Touched

- `docs/dev-log/source-review/2026-09-29-selected-inverse-and-pcg-review.md`
- `docs/dev-log/check-log.d/2026-09-29-selected-inverse-and-pcg-review.md`
- `docs/dev-log/after-task/2026-09-29-selected-inverse-and-pcg-review.md`
- `GATES.md`

## 5. Checks Run

- Full Julia 1.10 `Pkg.test()` passed on the reviewed source/test pins and ended `Testing HSquared tests passed`.
- `git diff --check`, after-task structure, prose scan, and preamble cap were run for this work period.
- Reviewers did not run tests or benchmarks; the full package suite was run after their source review.

## 6. Tests of the Tests

Existing tests inspected for sparse selected-inverse dense-reference and permutation parity, support validation, PCG direct-solve agreement, assembled/matrix-free parity, control handling, and iteration starvation. The current suite executes these fixtures but does not test severe conditioning, invalid factor diagonals, peak memory, warmed allocations, or type stability.

## 7a. Issue Ledger

- Open: explicit finite-positive Cholesky-factor precondition at `_selinv_zvals`; validate caller/API guarantee before deciding on a code guard.
- Open: selected-inverse support errors are detected after recursion.
- Open: severe-conditioning/factor-finiteness tests, PCG overflow-breakdown behavior, sparse fill/RSS, allocations, and type stability.
- Open: remaining source spans and public bridge review; A2 and V3 programme gates.

## 8. Consistency Audit

Reviewed exact source hashes are recorded in the source-review packet. The complete package suite passed after those hashes were confirmed unchanged. No implementation source, capability-status row, validation-debt row, or covered count changed.

## 9. What Did Not Go Smoothly

No source or test edits were required for this review slice. The package test run retained the existing Project/Manifest mismatch warning; no dependency resolution was run.

## 10. Known Residuals

This does NOT cover all `src/` files, caller-side guarantees for every factor path, performance at large scale, GPU execution, FA/GLLVM R parity, or release readiness. E1, A2, and V3 remain open. No simulation campaign, release submission, registry submission, merge, or tag occurred.

## 11. Team Learning

Matrix-free assembly savings do not imply low factor-fill memory, and allocation or type-stability claims need measurements separate from small-case numerical parity.

## 12. Cross-Product Coverage

This covers Julia selected-inverse and iterative-solver source review. It does NOT cover the R bridge, R package behavior, genetic GLLVM acceptance, unusual inheritance, CUDA runtime, or publication readiness.

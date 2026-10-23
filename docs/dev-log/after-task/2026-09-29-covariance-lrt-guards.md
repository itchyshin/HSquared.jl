## 1. Goal

Add fail-closed input prerequisites to `covariance_structure_lrt` and verify the bounded Julia slice without claiming a converged fitted FA comparison or valid nonstandard reference law.

## 2. Implemented

- Require converged input fits, finite log likelihoods, nonempty square genetic covariance matrices, equal trait dimensions, and supported nested covariance structures.
- Correct the multivariate REML initialization documentation to describe the balanced start and floor-clamping accurately.
- Correct low-rank boundary wording to say that the relevant nonstandard limit is not derived here and that the naive chi-square tail has unknown direction.
- Add positive-df unsupported-pair coverage and supported diagonal-to-unstructured and low-rank-to-unstructured controls with covariance matrices consistent with their declared ranks.
- Record the narrow closeout in the Wave 2 source review, check log, and coordination board.

## 3a. Decisions and Rejected Alternatives

- The T5/K2 real optimizer fits in the structured-LRT test did not converge. The helper rejects them, so they are not used as fitted LRT evidence.
- Synthetic converged positive-definite fit-shaped records are retained only for parameter-count and nominal-tail arithmetic checks. They do not establish optimizer behavior or inference validity.
- The low-rank test checks the helper's naive arithmetic while leaving the boundary reference law unspecified. No chi-bar-square mixture is asserted.
- Totoro is available, but this guard slice does not require a simulation. The separate 200-seed FA recovery campaign remains held because its estimated runtime is about 8.5 hours and requires explicit approval.

## 4. Files Touched

- `src/multivariate.jl`
- `test/test_331_structured_lrt_df.jl`
- `test/runtests.jl`
- `GATES.md`
- `docs/dev-log/source-review/2026-09-27-wave2.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-covariance-lrt-guards.md`

## 5. Checks Run

- Full Julia `Pkg.test()` passed on Julia 1.10.0 with four Julia threads and one OpenBLAS thread. The final package output ended `Testing HSquared tests passed`.
- The structured-LRT suite passed 34/34 assertions.
- The docs build passed from a synchronized writable copy of the worktree. It emitted existing missing-docstring, deployment auto-detection, default config/theme, favicon, and large-chunk warnings; see `docs/dev-log/check-log.md`.
- `git diff --check` and `bash tools/preamble_cap.sh` passed before closeout documentation. The preamble measured 11,024/14,000 bytes.
- Final `git diff --check` passed after all report and GATES edits. The final synchronized docs build completed in 4.69 seconds with the warnings listed above.
- After-task structure validation passed. The integrated acceptance-ledger check remains nonzero because the larger active FA/GLLVM/source-review GATES are still open; this report closes only the bounded LRT prerequisite subfinding.
- No GPU, hosted CI, R package, or release checks were run in this Julia helper slice.

## 6. Tests of the Tests

- Earlier full-suite runs exposed two useful mismatches: a synthetic legacy result lacked convergence metadata, and the T5/K2 optimizer fits were nonconverged. The fixture was updated to satisfy the helper contract, while the real nonconverged fits now explicitly test rejection.
- Noether's independent review found missing positive-df rejection coverage, inconsistent synthetic covariance ranks, and an overclaim about the low-rank reference law. Those findings were corrected; Noether re-read the revised spans and passed them.
- The synthetic arithmetic controls do not test that a real fitted FA pair converges or that the nominal reference distribution is valid.

## 7a. Issue Ledger

- Fixed: covariance LRT accepted records without convergence, finite-likelihood, covariance-dimension, or supported-nesting prerequisites.
- Fixed: unsupported structure-pair coverage now includes a positive nominal degree-of-freedom difference.
- Fixed: synthetic low-rank test covariance rank and boundary-law wording.
- Open: fitted FA convergence, local identifiability, and the appropriate finite-sample or boundary reference law.
- Open: other Wave 2 helper convergence and provenance requirements, and GATES A2/E1/V3.

## 8. Consistency Audit

- Reviewed the helper docstring, checks, supported structure pairs, focused tests, and GATES wording together.
- Confirmed that the test's real T5/K2 optimizer records are nonconverged and refused, while arithmetic-only stubs are labeled and structurally consistent.
- Noether passed the revised guard/test spans. Rose passed the pinned-snapshot comparator wording and low-rank claim review after the current-source hash was corrected in GATES.
- This work does not alter the covariance optimizer; the comparator remains tied to its recorded pinned fitter snapshot rather than being represented as a current-source fit.

## 9. What Did Not Go Smoothly

- The first full test run found a legacy synthetic record that did not satisfy the new convergence contract. The next run confirmed that the real small FA fits themselves did not converge. The tests were separated into explicit rejection evidence and arithmetic-only controls rather than treating those fits as valid LRT inputs.
- The docs generator could not write generated status content into the managed worktree. A content-matched temporary copy was used, and the build succeeded there with warnings retained in the check log.

## 10. Known Residuals

- The helper reports a nominal chi-square tail. Local regularity and the low-rank boundary law are not established by this slice.
- No converged fitted FA LRT was demonstrated. The helper's caller remains responsible for same-data, fixed-effects, and relationship-matrix provenance.
- The broader FA evidence gate remains HOLD. The 200-seed run is estimated at about 8.5 hours and has not been started.
- A2, E1, V3, full source-review signoff, R-Julia parity for this helper contract, and hosted CI remain outside this bounded closeout.
- The unlazy acceptance ledger still lists open FA-closeout, GLLVM-foundation, Wave 1.05, Wave 2 bridge, and top-level programme gates. They are carried forward, not abandoned.

## 11. Team Learning

Noether's review improved the guard coverage and prevented impossible synthetic metadata and an unsupported reference-law claim. Rose's claim audit identified comparator wording that needed to remain pinned to the fitter snapshot. The exact narrow review findings and dispositions are recorded in the Wave 2 source review. No new memory decision was needed.

## 12. Cross-Product Coverage

Covers: Julia covariance-structure LRT record prerequisites, supported nesting pairs, nominal parameter-count arithmetic, tests, and local package/docs checks.

Does NOT cover: a converged fitted FA LRT, reference-law validity, broad FA inference, GLLVM, R bridge parity, a simulation campaign, GPU work, capability promotion, CI, merge, release submission, registry submission, or a public tag.

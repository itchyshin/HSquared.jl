# After-task: Wave 2 random-regression contracts

## 1. Goal

Repair the remaining random-regression input-contract findings identified in
Wave 2 and align nearby status wording with the existing Julia and R capability
records.

## 2. Implemented

Both Julia random-regression fit routes now reject wrong-length animal IDs,
nonfinite dense or sparse incidence values, and nonfinite or nonpositive
residual variances before numerical work. Heritability descriptors apply the
same finite-positive rule to scalar and vector residual inputs. A source-header
and roadmap correction distinguishes experimental descriptors/MME from the
covered Julia k=2 dense REML cell and covered opt-in R k=2 `rr()` surface.

## 3a. Decisions and Rejected Alternatives

- Kept all existing model routes, covariance structures, and capability rows.
- Did not change the covered status of the Julia or R k=2 cells.
- Did not claim broader random-regression coverage, sparse scaling, or
  optimizer reliability.

## 4. Files Touched

- `src/random_regression.jl`
- `test/wave2_precision_contracts.jl`
- `ROADMAP.md`
- `GATES.md`
- `docs/dev-log/source-review/2026-09-29-wave2-random-regression-followup.md`
- `docs/dev-log/check-log.d/2026-09-29-wave2-random-regression.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-wave2-random-regression-contracts.md`

## 5. Checks Run

- Focused `test/wave2_precision_contracts.jl`: 105/105 passed after final
  source/docstring edits.
- Full Julia `Pkg.test()`: completed with `Testing HSquared tests passed`.
  The existing Project/Manifest mismatch warning remains; no resolve/update was
  run.
- `git diff --check` passed for the changed code and review packet.
- `slop_check.py` passed the source-review packet with zero findings.
- Gauss and Astra independently reviewed the final source/test hashes. Rose
  checked status and public-claim wording against the corresponding ledgers.

## 6. Tests of the Tests

Before implementation, wrong-length IDs produced no error in supplied MME;
nonfinite `Z` reached a singular solve or was accepted by REML; infinite
residual inputs passed positivity-only checks or produced nonfinite optimizer
state. The regressions now require clear `ArgumentError` failures for both
entry points, dense and sparse `Z`, and scalar/vector residual inputs.

## 7a. Issue Ledger

- Fixed for random regression: the W2-03 precision/covariance checks and W2-07
  ID-length mismatch.
- Fixed adjacent contracts: finite incidence matrices and finite-positive
  residual values.
- Still open: other W2 findings, remaining source spans and whole-wave review,
  broad RR recovery, and the larger FA/GLLVM acceptance gates.

## 8. Consistency Audit

Rose found adjacent status sentences that understated the existing covered
cells. The source header, REML docstring, and roadmap now agree with the public
claim and capability rows. No capability status or covered count changed.

## 9. What Did Not Go Smoothly

The first Rose pass inspected the primary checkout rather than the candidate
worktree. The audit was rerun against the exact candidate path and final source
hash. A second pass then identified and closed an additional adjacent R-route
wording mismatch. `closeout.py check` still exits nonzero because the full
programme ledgers have unmet gates for FA, GLLVM, W1/W2 bridge work, and E1.
Those remain active goal work, so they were not abandoned to force a local
closeout pass.

## 10. Known Residuals

- Random-regression descriptors and supplied-covariance MME remain
  experimental and dense; broader RR validation remains owed.
- This closes only the RR portions of W2-03/W2-07. Wave 2 and E1 remain open.
- Programme gates A2, E1, and V3 remain unmet. The FA campaign remains
  approval-gated; Totoro availability does not approve it.
- The repository-wide after-task gate remains unmet while the active programme
  ledgers above are open.
- No GPU execution, release submission, Julia registry submission, or tag.

## 11. Team Learning

Validate labels and finite numeric inputs before constructing dense designs or
starting an optimizer. Review exact candidate paths when multiple checkouts
exist. Check nearby status prose against the claim ledger before finishing a
source review.

Memory receipt: The `route.py HSquared.jl` LOAD-FIRST manifest shaped the
capability boundaries, candidate-path checks, and approval fence for long
compute. I searched the brain's WHAT-WORKS note for invalid-prior test
practice, and required red-before-green regressions. Golden Set:
`memory_regression.py --selftest` passed; `refusal-assumed-bug`,
`completion-overclaim`, `partial-arc-negative-space`, and `worktree-is-a-branch`
were considered. No new case was added.

## 12. Cross-Product Coverage

This slice changes only Julia input validation and internal status prose. It
does not change the R interface or parity evidence, and it does not advance the
Gaussian FA or genetic GLLVM acceptance cells. It does NOT cover whole Wave 2,
E1, broad random-regression validation, or the remaining twin programme.

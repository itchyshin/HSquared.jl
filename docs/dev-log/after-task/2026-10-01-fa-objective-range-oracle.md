# After-task: FA multistart diagnostic oracle

## 1. Goal

Repair the single assertion that failed in both latest-runtime Julia CI jobs and verify the bounded HSquared candidate on the corrected test bytes.

## 2. Implemented

The expected objective range now compares the optimizer's default fit with the fit from its internally constructed balanced start. This is a one-line test correction. Numerical source and model behavior are unchanged.

## 3a. Decisions and Rejected Alternatives

Kept the assertion tied to the exact initializer used by production. The previous hand-built start was algebraically equivalent but had different floating-point arithmetic. No optimizer tolerance or production objective was changed.

## 4. Files Touched

The numerical test change is in `test/test_multivariate_fa_multistart.jl`. Exact-current package, documentation, bridge outputs, and input freeze are in `docs/dev-log/check-log.d/2026-09-30-final-integrated/`. The independent technical and Rose reviews are in `docs/dev-log/prepared-fixes/2026-09-30-fa-objective-range-oracle/independent.md`. This report, `GATES.md`, the current receipt pointer, check-log slice, coordination board, and goal checkpoint record the disposition. Protected platform settings remain unstaged.

## 5. Checks Run

- Both Julia 1.13 hosted jobs failed the same assertion; the other 45 assertions in that testset passed.
- An exact focused invocation was interrupted after its trait-unit testset passed in 103.7 seconds while a later fit continued. This invocation is recorded as incomplete.
- Full Julia 1.13.1 `Pkg.test()` passed in 476.04 seconds with one Julia and one BLAS thread.
- Julia 1.10.0 documentation build passed in 49.00 seconds.
- Live R to Julia FA/GLLVM bridge tests passed in 24.87 seconds with the bridge required.
- Installed exact-source evidence validators passed in Julia, docs, and R bridge modes.
- `git diff --check` passed on the test correction.

## 6. Tests of the Tests

The Linux and Windows failures independently reproduce a 2.84e-14 discrepancy. The diagnostic implementation uses valid attempts from the production default and balanced starts. The helper named `reported_alternative` uses the same balanced initializer arithmetic, while the old expected value used a separately constructed start. Independent review confirms the oracle correction. The fresh complete package suite passes.

## 7a. Issue Ledger

This closes the shared latest-runtime assertion failure only. V1 and V2 local verification pass on the refreshed inputs. V3 remains open for exact-current hosted CI and landing. Programme gates A2 and E1 remain open.

## 8. Consistency Audit

No capability row, covered count, release status, or primary campaign result changed. The public covered count remains seven. Fixed-rank FA and the bounded GLLVM cell remain experimental. No broad calibration or automatic rank claim is made.

## 9. What Did Not Go Smoothly

The direct focused file invocation took longer than its initial estimate because it entered a later optimizer fit. It was stopped and reported as incomplete. The full suite then passed within its timeout. GitHub API access repeatedly failed with a connection error, so the approved push and new hosted checks have not yet run.

## 10. Known Residuals

Exact-current hosted Julia CI and merge remain unverified. The wider programme's A2, E1, and V3 gates remain open. This slice adds no evidence for broad inference, general recovery, unusual inheritance, GPU work, or release readiness.

## 11. Team Learning

When a diagnostic summarizes internal optimizer attempts, its test oracle should use the exact reported attempts. Algebraic equivalence does not guarantee the same floating-point result.

## 12. Cross-Product Coverage

This arc corrects one Julia FA diagnostic assertion and reruns local package, documentation, and R-to-Julia bridge checks. It does NOT cover other Julia runtime versions beyond the pending hosted matrix, any change to the R formula or result contract, automatic FA rank, broader GLLVM families, broad simulation calibration, GPU execution, unusual inheritance, a release, submission, or tag.

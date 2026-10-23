## 1. Goal

Verify pedigree ordering on a reverse-listed chain deep enough to test the recursive topological sort, and retain a regression for the checked depth.

## 2. Implemented

- Added a 12,000-animal sire-only chain test to the Phase 1 pedigree testset.
- Asserted sorted IDs, original input row mapping, parent-before-offspring order, sparse inverse dimensions, and finite inverse entries.
- Updated the Wave 3 review packet, acceptance ledger, and check log with the bounded result.

## 3a. Decisions and Rejected Alternatives

Kept the existing recursive ordering implementation because it passed the 12,000-deep probe. The result is specific to this tested depth and does not establish behavior at arbitrary depth.

## 4. Files Touched

- `test/runtests.jl`
- `docs/dev-log/source-review/2026-09-27-wave3.md`
- `docs/dev-log/check-log.md`
- `GATES.md`
- `docs/dev-log/after-task/2026-09-27-w3-deep-pedigree-check.md`

## 5. Checks Run

- A focused Julia probe passed with `DEEP_REVERSE_CHAIN_REGRESSION_OK n=12000 nnz=35998`, exit status 0.
- The probe used one Julia thread and one OpenBLAS thread, and completed in under one minute after startup.
- The complete package suite passed in `/private/tmp/hsq-fa-gllvm-wave3-deep-chain-copy` after `diff -qr` confirmed the `src/` and `test/` trees and `Project.toml` matched the candidate. Exit status was 0 and output ended `Testing HSquared tests passed`.
- The copy had no `.git` directory, so two ancillary commands printed `fatal: not a git repository`; the test process still exited 0. The source and regression assertions do not depend on Git metadata.
- CI for the earlier source fix commit `6988af4f` was queued at this check. It does not include the newly added regression; CI for the updated candidate remains pending a push.

## 6. Tests of the Tests

The probe asserts the expected sorted identifiers and original-order mapping, checks every known parent index is lower than its offspring index, and confirms the sparse `Ainv` has the requested dimensions and only finite stored values. The new test is load-bearing for those properties at 12,000 depth.

## 7a. Issue Ledger

- **Resolved at tested depth:** reverse-listed 12,000-generation normalization and sparse inverse construction.
- **Carried:** arbitrary-depth behavior, remaining unreviewed Wave 3 spans, and whole-wave signoff.

## 8. Consistency Audit

The existing broad 12,000-animal inbreeding test does not create a 12,000-deep chain. The new fixture is reverse-listed and maximally deep, so the first visit follows parent links through the full chain. The test checks ordering and sparse inverse output without constructing a dense relationship matrix.

## 9. What Did Not Go Smoothly

The first direct Julia invocation could not write the default depot's precompile lock in this sandbox. Re-running with a writable temporary depot and the installed depot as fallback succeeded.

## 10. Known Residuals

This check covers one pedigree structure and depth. It does not prove arbitrary-depth safety, validate every pedigree edge case, or close Wave 3. CI for this follow-up remains outstanding.

## 11. Team Learning

A large pedigree test can be broad but shallow. A reverse-listed chain isolates recursion depth and makes parent-before-offspring and original-order expectations explicit.

## 12. Cross-Product Coverage

Covers: Julia pedigree normalization and sparse inverse construction for a reverse-listed 12,000-deep sire-only chain.

Does NOT cover: R behavior, other pedigree structures, arbitrary depth, general A/Ainv correctness, non-standard inheritance, full Wave 3 signoff, GPU execution, automatic rank selection, release submission, or public capability promotion.
